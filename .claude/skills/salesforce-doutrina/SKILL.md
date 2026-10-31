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
