---
name: salesforce-doutrina
description: Critérios de decisão da plataforma Salesforce — quando usar configuração, Flow ou Apex, limites de governador, ordem de execução e armadilhas comuns. Use em todo desenho de solução e code review.
---

# Doutrina de plataforma

## Ordem de preferência
1. **Configuração nativa** (campo fórmula, roll-up, validation rule, aprovação padrão)
2. **Declarativo** (Flow)
3. **Código** (Apex, LWC)

Só desça de nível com justificativa escrita. Descer sem motivo é a principal fonte de
custo de manutenção em projeto Salesforce.

## Quando Flow não resolve e vira Apex
- Lógica que precisa de rollback transacional complexo
- Callout com tratamento de erro elaborado / integração assíncrona
- Volume alto com risco de limite de elementos por transação
- Recursão que exige controle de estado
- Necessidade de teste unitário determinístico sobre a regra

## Armadilhas frequentes
- Flow record-triggered sem critério de entrada → roda em todo update, mata performance
- Múltiplas automações no mesmo objeto/evento → ordem de execução imprevisível
- SOQL/DML em loop → estoura governador com 200 registros
- Trigger sem framework → lógica duplicada e recursão
- `SeeAllData=true` em teste → quebra em outra org
- Roll-up summary só existe em relacionamento master-detail; lookup exige Flow ou Apex
- Formula field tem limite de caracteres compilados — cheque antes de prometer

- Picklist **não restrita** aceita qualquer texto via API: integração que manda o rótulo
  ("Web Site Agility") em vez do API name ("Web Site Agility Networks") grava valor solto,
  que parece certo na tela mas não agrupa em relatório nem dispara automação que compara o
  valor (achado SOMOSAGILITY-21). Em diagnóstico de integração, teste payload com e sem o
  campo, e com rótulo vs. API name.
- Validation rule ativa numa sandbox e não na outra: teste unitário que passa em dev quebra
  em QA (achado SOMOSAGILITY-10, `ValidaJOB`). Fixture de teste preenche todo campo exigido
  por validation rule do objeto, não só os que a regra da demanda usa.

## Relatórios e painéis por metadata
Achado EPLAST-39 (2026-11-12): 5 relatórios e 1 painel custaram quatro vezes um build
normal, porque o formato foi descoberto deployando e lendo o erro — e o QA ainda reprovou
o painel. XML de relatório e painel não tem validação local; o que segue foi confirmado
por erro real de deploy ou por execução na org (API 68.0, Enterprise Edition). Vale como
ponto de partida, não como referência completa.

**Antes de escrever o XML**
- Parta de um exemplo da própria org: faça retrieve de um relatório que já use o recurso
  (filtro relativo de data, bucket, fórmula) e copie a sintaxe dele. Não adivinhe valor de
  enum: `INTERVAL_THISFISCALQUARTER` e `INTERVAL_THIS_FISCAL_QUARTER` foram os dois
  recusados em `<timeFrameFilter>` (`UserDateInterval`). Duas tentativas recusadas no
  mesmo campo → pare, tire o item e registre como pendência no plano de build.
- Confira o tipo de relatório pelo describe
  (`/services/data/vNN.0/analytics/report-types/<Tipo>`) antes de desenhar: ele diz as
  colunas que existem (o `ROI` nativo de `CampaignList` dispensou fórmula própria e já
  não divide por custo zero) e se o usuário da esteira tem acesso — `CampaignInfluence`
  existe, mas respondeu "sem permissão aos objetos" e o relatório saiu do escopo.
- `scope` depende do tipo de relatório: `Opportunity` recusou `org` e aceitou `team`;
  `OpportunityLead` aceita `org`. Copie o `scope` de um relatório existente do mesmo tipo.
- `ReportFolder` e `DashboardFolder` não aceitam `<description>`; `Group` aceita.

**Bucket sobre picklist**
- `bucketType` tem de casar com o tipo da coluna de origem: `text` sobre picklist é
  recusado.
- Entrada de bucket para valor vazio (`<sourceValues/>`) com `bucketType` `picklist` deu
  erro interno opaco. Sem ela, o nulo aparece no relatório com rótulo `-`, não com o
  texto que o critério de aceite pedir. Se o critério exige um rótulo ("Sem origem"),
  diga no design que isso é ajuste manual na tela (renomear o grupo), não metadata.
- `otherBucketLabel` não consolidou valores fora da lista numa picklist não restrita:
  cada valor solto virou um grupo próprio. Não prometa a linha única "Fora da lista".

**Relatório que alimenta painel**
- Componente de gráfico exige relatório de **resumo ou matriz** (com `groupingsDown`), ou
  tabular com limite de linhas e "Configurações do Painel". Tabular puro dá erro 209
  permanente no componente, com qualquer volume de dado. Decida o formato de cada
  relatório no design já sabendo qual componente ele alimenta.
- O teto de painéis dinâmicos (`LoggedInUser`) presumido no design não se confirmou no
  deploy: confirme limite de edição pelo erro real, não por suposição.
- Deploy com sucesso não prova que o painel renderiza. Ainda no build, confira cada
  componente pela Analytics API (`/analytics/dashboards/<id>`): `errorCode` ou `NO_DATA`
  em todos os componentes é defeito de build, não achado para o QA.

**No QA**
- O navegador da esteira não clica dentro do iframe do visualizador de relatório e
  painel. Teste pela Analytics API (`/analytics/reports/<id>`), lendo só rótulos e
  contagens agregadas (guardrail #2).
- Sandbox sem registro no objeto não testa relatório: o recon conta os registros dos
  objetos envolvidos, e o design diz de onde vem o dado de teste (sintético, e quem o
  apaga depois).

## Ordem de execução (resumo operacional)
Validação de sistema → before-save Flows → before triggers → validation rules custom →
duplicate rules → gravação (sem commit) → after triggers → assignment/auto-response →
workflow (legado) → after-save Flows → entitlement → roll-up summary e cross-object →
sharing por critério → commit → pós-commit (e-mail, `@future`, Queueable, platform events).
Se a solução depende dessa ordem, isso é um risco: documente explicitamente no design.

## Governador (números que importam)
- 100 SOQL síncronos por transação
- 150 DML por transação
- 50.000 registros retornados
- 10.000 registros por DML
- 6 MB heap síncrono / 12 MB assíncrono
- 10s CPU síncrono / 60s assíncrono

Ao desenhar, estime contra esses números com o volume real do cliente (do recon).

### CPU: o limite que o teste de bulk não pega
Achado SOMOSAGILITY-10 (2026-10-30): SOQL e DML ficaram estáveis, mas uma **única
solicitação com 150 lançamentos** estourou os 10s de CPU — o teste unitário de "200
registros" usava 200 pais com 1 filho cada e passou. O custo vinha de um Flow que dispara
uma interview por filho, cada uma acionando ~19 Flows after-save do pai.

- Dimensione dois cenários, não um: **muitos registros** (carga em massa) e **um pai com
  muitos filhos** (o dia a dia de relatório de despesa, pedido com muitas linhas, etc.).
- Cada Flow record-triggered no objeto pai multiplica o custo de qualquer atualização
  em cascata vinda dos filhos. Conte-os no recon.
- Recalcular o pai uma vez por transação (agregando os filhos por pai), e não uma vez por
  filho, é o desenho padrão. Acima de um volume seguro, mova para assíncrono
  (Queueable) — e diga no design qual é esse volume.
- Critério de escalonamento: se a medição em sandbox passar de ~70% de um limite no
  volume realista, o design volta para revisão.

## Complemento
Esta skill é doutrina, não referência completa. Para detalhe de API ou release recente,
consulte a documentação oficial via WebFetch e cite a fonte — não responda de memória.
