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
- Filtro "começa com" (`StartsWith`) em campo de Id é inválido em Get Records de Flow: o
  Flow salva e falha ao rodar (achado Eplast, 2026-11-17). Compare Id por igualdade; para
  reconhecer um Id pelo prefixo, teste o texto numa fórmula antes da consulta.
- Entrada de ação de agente chamada `recordId` recebe o que o modelo mandar, não só Id:
  já chegou o código da conta (`000682`). Valide a forma (15 ou 18 caracteres, prefixo do
  objeto) antes do Get Records e trate o resto como outro tipo de busca.
- Dois caminhos de busca que reaproveitam o mesmo laço: confira de qual coleção o laço lê.
  Um laço ligado à coleção do outro caminho não itera, o contador fica em zero e a decisão
  seguinte cai no ramo padrão (achado EPLAST-27, QA rodada 7). Um laço por coleção, ou uma
  coleção comum alimentada pelos dois.
- Processos de aprovação do mesmo objeto têm ordem (`processOrder`), e o deploy de um
  arquivo regrava a ordem dele. Duas demandas no mesmo objeto: a segunda confere e corrige
  a ordem das duas (achado SOMOSAGILITY-17 e 22).
- Quem decide se o Flow chega ativo é o `<status>` do arquivo. Em sandbox, implantar um
  Flow com `<status>Active</status>` por cima de um Flow ativo cria **na hora** uma versão nova
  já ativa, que substitui a de quem está usando; em produção isso só acontece com a
  preferência "Deploy processes and flows as active" ligada. Com `Draft` ou `Obsolete` a
  versão nova chega inativa e a ativa continua. Para a sandbox de QA o pacote leva `Active`
  só quando a QA não tem versão ativa anterior; em produção a ativação continua passo
  separado. Fonte: Metadata API, tipo Flow
  (https://developer.salesforce.com/docs/platform/api-metadata/references/meta-types/metadata-flow.html,
  lida em 2026-11-28).
- `FlowDefinition` (arquivo `.flowDefinition-meta.xml`): a documentação diz que o
  `activeVersionNumber` dela **sobrepõe** o `<status>` dos Flows no deploy e recomenda, desde a
  API 44.0, ativar e desativar pelo `<status>` do Flow, não pela definição
  (https://developer.salesforce.com/docs/platform/api-metadata/references/meta-types/metadata-flowdefinition.html).
  Na esteira o contrário já aconteceu (EPLAST-47: `activeVersionNumber` 0 não prevaleceu
  sobre `Active`, e o `coerencia_ativacao_flows.py` corrige isso). Não confie em nenhum dos
  dois sozinho: deixe `<status>` e definição dizendo a mesma coisa, e confira a versão ativa
  na org depois do deploy (`FlowDefinitionView.ActiveVersionId`).
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

## Alterar o que já existe: nova versão primeiro, ativação depois

Regra do responsável (2026-11-15). Flow, agente Agentforce e classe Apex que já existem na
org nunca são editados no lugar. Primeiro se cria uma versão nova; ela é implantada sem
substituir a que está em uso; a troca para a versão nova (ativação) é um passo separado,
declarado no plano, que só acontece depois de a versão nova ser provada.

Achados que motivaram (EPLAST-27 e EPLAST-33, 2026-11-15): o deploy na QA recusou alterar
`SFAgent2_v4` porque a versão estava ativa lá, e a validação recusou reimplantar classes
Apex com job agendado em andamento. Editar o que está ativo trava o deploy ou troca o
comportamento de quem usa a org sem ninguém ter decidido.

- **Flow.** Implante como versão nova do mesmo Flow com `<status>Draft</status>` (ou
  Obsolete), não como Active. A ativação é o passo seguinte, depois da verificação, e fica
  escrita no plano com a versão que entra e a que sai. Para desfazer: reativar a anterior.
  Flow novo (que não existia) pode nascer Active, porque não substitui nada.
- **Agente Agentforce.** Nunca altere uma `BotVersion` nem o `GenAiPlannerBundle` de uma
  versão existente: crie a versão seguinte (`vN+1`) a partir da última, com o tópico ou a
  ação novos, e implante-a **inativa**. Ativar a versão nova (e desativar a anterior) é um
  passo separado. Na sandbox de QA o `qa` pode ativá-la para testar (autorizado para toda a
  esteira desde 2026-11-15) e registra em `05-testes.md` qual versão entrou e qual saiu,
  porque isso troca o assistente de quem está testando. Demandas que mexem no mesmo agente partem da versão
  deixada pela anterior e criam a próxima; nunca duas demandas na mesma versão.
- **Classe Apex.** Classe em uso (chamada por trigger, Flow, ação de agente ou job
  agendado) não é reescrita no lugar quando a mudança altera comportamento: crie a classe
  nova (`<Nome>V2` ou nome que diga a mudança), com sua `<Classe>Test`, e troque quem a
  chama num passo separado. Correção pequena que não muda contrato pode editar a classe,
  desde que nenhum job agendado ou em andamento a use; se houver, o plano diz quem
  desagenda e reagenda, e quando.
- **No plano de build** (`04-plano-build.md`), uma seção "Versões e ativação": o que foi
  criado como versão nova, o que continua ativo, o passo de ativação (quem, onde, quando)
  e como desfazer.

## Ordem de execução

Conferida no Apex Developer Guide, "Triggers and Order of Execution"
(https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-triggers-order-of-execution.html,
lida em 2026-11-28; vale para a versão de API da página):

1. Carrega o registro e sobrepõe os valores novos; validações de sistema (na tela: layout,
   obrigatórios, formato e tamanho; por API/Apex: chaves, formato, tamanho e picklist restrita).
2. Flows record-triggered **before-save**.
3. Triggers **before**.
4. Validações de sistema de novo e **validation rules** custom.
5. **Regras de duplicidade**: com ação de bloqueio, o registro não é gravado e nada adiante roda.
6. Gravação, sem commit.
7. Triggers **after**.
8. Regras de atribuição, depois de resposta automática.
9. Workflow rules (legado); field update de workflow regrava o registro e roda os triggers
   before e after update mais uma vez (e só mais uma).
10. Regras de escalonamento.
11. Process Builder e Flows disparados por workflow, **sem ordem garantida** entre eles.
12. Flows record-triggered **after-save**.
13. Regras de direito (entitlement).
14. Roll-up summary e workflow entre objetos no pai, e no avô; cada um passa pela gravação.
15. Compartilhamento por critério.
16. Commit.
17. Pós-commit, sem ordem entre si: e-mail, jobs assíncronos (Queueable, `@future`) e os
    **caminhos assíncronos** dos Flows record-triggered.

Dois triggers no mesmo objeto e evento não têm ordem garantida entre si. Na regravação
recursiva, os passos de atribuição até o roll-up do avô não rodam de novo. Se a solução
depende dessa ordem, isso é um risco: documente explicitamente no design. A ordem entre
Flows record-triggered do mesmo objeto se controla pela ordem de disparo do próprio Flow
(a documentação remete à ajuda "Manage Record-Triggered Flows", não conferida: o
help.salesforce.com não abriu nesta revisão).

## Governador (números que importam)

Por transação, síncrono / assíncrono (Batch, `@future`, Queueable). Fonte: Apex Developer
Guide, "Execution Governors and Limits"
(https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-gov-limits.html,
lida em 2026-11-28). Exceder um limite lança exceção que **não** se trata com `catch`.

| Limite | Síncrono | Assíncrono |
| --- | --- | --- |
| Consultas SOQL | 100 | 200 |
| Registros retornados por SOQL | 50.000 | 50.000 |
| Comandos DML | 150 | 150 |
| Registros processados por DML | 10.000 | 10.000 |
| Heap | 10 MB | 25 MB |
| CPU | 10.000 ms | 60.000 ms |
| Chamadas externas (callouts) | 100, somando no máximo 120 s | igual |
| Jobs com `System.enqueueJob` | 50 | 1 |
| Métodos `@future` | 50 | 0 em Batch e `@future`; 50 em Queueable |
| Profundidade de triggers recursivos | 16 | 16 |

- **Apex agendado usa os limites síncronos**, mesmo sendo assíncrono.
- Trigger recebe os registros em lotes de **200**; evento de plataforma e Change Data
  Capture, em lotes de 2.000.
- Subconsulta pai-filho conta como consulta a mais.
- Limites valem por método de teste, e cada lote do `execute` de um Batch recomeça a conta.
- Pacote gerenciado **certificado** tem limites próprios para a maioria dos contadores, mas
  heap e CPU são da transação inteira: o pacote come do mesmo CPU que a sua automação.
- Até a revisão de 2026-11-28 esta skill dizia heap de 6 MB / 12 MB; a página oficial diz
  10 MB / 25 MB.

Ao desenhar, estime contra esses números com o volume real do cliente (do recon). Os limites
próprios de Flow (elementos executados, interviews) estão no help.salesforce.com, que não
abriu nesta revisão: **não conferidos**; até lá, meça na sandbox.

## Acesso a dado no Apex: modo de usuário é o padrão desde a API 67.0

Fonte: Apex Developer Guide, "Set an Access Mode for Database Operations"
(https://developer.salesforce.com/docs/platform/apex-dev/references/apex-dev/apex-classes-enforce-usermode.html,
lida em 2026-11-28): **na API 67.0 em diante, o Apex roda em contexto de usuário por padrão**
(permissão de objeto, de campo e compartilhamento de quem executa); na 66.0 e anteriores o
padrão é o modo de sistema. Vale a `<apiVersion>` do `-meta.xml` de cada classe: os projetos
dos clientes estão em `sourceApiVersion` 67.0, e no repositório (2026-11-28) há 31 classes na
67.0 e as demais entre 13.0 e 66.0. Duas consequências:

- Classe nova (67.0) chamada por trigger, job ou ação de agente que grava campo que o usuário
  não edita falha, a menos que a operação diga `AccessLevel.SYSTEM_MODE`, `WITH SYSTEM_MODE`
  ou `as system`, de propósito e com o motivo (skill `revisar-apex`).
- **Subir a `<apiVersion>` de uma classe antiga para 67.0 muda o comportamento dela**: é
  mudança de contrato, com teste do usuário que de fato executa, não ajuste de rotina.

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
