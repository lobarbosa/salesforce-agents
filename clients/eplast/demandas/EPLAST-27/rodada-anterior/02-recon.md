# Recon da org — EPLAST-27: Próxima melhor ação por cliente

**Data da coleta:** 2026-11-10 · **Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`) ·
**Organization.IsSandbox:** `true` · Enterprise Edition · **API da org:** v68.0
**Validade:** 7 dias (vence em 2026-11-17).

Tudo abaixo veio de comando `sf` rodado nesta sessão. Os retrieves foram para `/tmp/recon`,
nunca para `force-app/`. Nenhuma query trouxe dado de registro. Só metadata e `COUNT()`.

Comandos usados: `sf org display`, `sf data query` (Organization, ApexTrigger,
FlowDefinitionView, BotVersion, PermissionSetLicense, PermissionSet, Profile, `COUNT()` por
objeto), `sf data query --use-tooling-api` (CustomField, ApexCodeCoverageAggregate,
ApexOrgWideCoverage), `sf org list metadata` (GenAiPlannerBundle, GenAiPlugin,
GenAiFunction, GenAiPromptTemplate, Bot, BotVersion, RecommendationStrategy,
LightningComponentBundle, FlexiPage, CustomObject), `sf sobject describe` (Account,
Opportunity, Task) e `sf project retrieve start` em `/tmp/recon` (ApexClass, ApexTrigger,
os Flows citados, GenAiPlannerBundle `SFAgent2_v4`, Bot `SFAgent2`).

---

## 1. Volume (sandbox de dev)

| Objeto | `COUNT()` |
|---|---|
| Account, Contact, Opportunity, Order, OrderItem, Task, Event | 0 |
| Quote, `SBQQ__Quote__c`, ActionPlan | 0 |

A dev está vazia, como o assessment já apontava. **O volume real não tem como ser medido
aqui.** Não sabemos quantas contas um vendedor tem nem quantos pedidos e itens uma conta
acumula. Produção não pode ser consultada (guardrail #1). O alias `sbx-eplast-qa` **não
está configurado** neste runner (`sf alias list` só lista `sbx-eplast-dev`), então também
não deu para comparar com QA.

## 2. Automação nos objetos candidatos a fonte de dado

### 2.1 Triggers

| Objeto | Trigger custom (eventos) | Trigger de pacote |
|---|---|---|
| Account | `AccountTrigger` (api 58): before insert/update, after insert/update | `SBQQ.AccountBefore` |
| Opportunity | `OpportunityTrigger` (api 59): after insert/update | `SBQQ.OpportunityBefore`, `SBQQ.OpportunityAfter` |
| Order | `OrderTrigger` (api 59): before/after update | `SBQQ.OrderTrigger` |
| OrderItem | — | `SBQQ.OrderProductTrigger` |
| Event | — | `maps.AdvRouteEvents` |
| Task | — | — |

### 2.2 Flows custom ativos, gatilho de registro ou agendados

| Flow | Objeto | Tipo | Critério de entrada |
|---|---|---|---|
| `AccountTriggered` | Account | RecordAfterSave, create+update | **nenhum** |
| `UpdateParentAccountUsedLimit` | Account | RecordAfterSave, create+update | **nenhum** |
| `AccountUpdateEconomicGroup` | Account | Scheduled (Once) | nenhum |
| `Account` | Account | Scheduled | **inativo** |
| `OpportunityFlow` | Opportunity | RecordAfterSave, create+update | **nenhum** (12 recordCreates, 10 recordUpdates; grava em Account, Order, Quote, Task, entre outros) |
| `Oportunidade_Industria` | Opportunity | RecordAfterSave | (não inspecionado em detalhe) |
| `ScheduledFlowOpportunity` | Opportunity | Scheduled, diário | `IsWon = …`. Atualiza Account (`AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`) |
| `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | Order | RecordBeforeSave | (não inspecionado) |
| `Order` | Order | RecordAfterSave, create+update | **nenhum** |
| `OrderScheduledFlow` | Order | Scheduled, diário | `Status = …` |
| `TaskCreatedOrUpdated` | Task | RecordAfterSave, create+update | **nenhum**. Atualiza Account (`AccountHasCheckInTask__c`) |

### 2.3 O que acontece quando uma Account é atualizada (lido do código em `/tmp/recon`)

Este é o achado que mais pesa no design.

- `AccountTrigger` em **after update**, fora de contexto Queueable, chama
  `AccountTriggerHandler.updateAccountCNPJInfo` → `AccountTriggerHelper.updateAccountInfoFromCNPJ`.
  Esse método faz **um `System.enqueueJob` por conta atualizada**: `UpdateAccountCompanyInfo`
  se o CNPJ mudou, **`SendAccountToProtheus` em qualquer outro caso**. Não existe filtro
  por campo alterado.
- Na prática, **qualquer update em Account reenvia a conta ao ERP Protheus**, mesmo que a
  mudança seja um campo sem nenhuma relação com o ERP.
- Somam-se a isso `SBQQ.AccountBefore` e dois Flows after-save sem critério de entrada.
- Limite relevante: 50 `enqueueJob` por transação síncrona. Um update síncrono com mais de
  50 contas de uma vez estoura esse limite pelo caminho já existente.
- Caminhos indiretos que acabam em update de Account: `TaskCreatedOrUpdated` (todo
  create/update de Task), `OpportunityFlow` (todo save de Opportunity) e
  `ScheduledFlowOpportunity` (diário).

## 3. Campos de "situação comercial" que já existem

`sf sobject describe`. Descrição consultada via Tooling (`CustomField.Description`).

| Objeto.Campo | Rótulo | Tipo | Descrição | Quem escreve (busca em `/tmp/recon`) |
|---|---|---|---|---|
| `Account.LastPurchase__c` | Última Compra | date | vazia | **nenhum Apex ou Flow custom encontrado**. Provável carga externa ou integração de entrada, **não confirmado** |
| `Account.TotalPurchasesThisYear__c` | Total de compras este ano | currency | vazia | `OpportunityFlow` |
| `Account.AveragePurchasesThisYear__c` | Média de compras este ano | currency | vazia | `OpportunityFlow`, `ScheduledFlowOpportunity` |
| `Account.LastMonthPurchaseValue__c` | Valor de Compras Último Mês | currency | vazia | `ScheduledFlowOpportunity` |
| `Account.Risk__c` | Risco | picklist | vazia | lido por `AccountAdapter` (envio ao Protheus) e `OpportunityFlow` |
| `Account.LimitUsed__c` | Limite Utilizado da Conta | currency | vazia | (não rastreado) |
| `Account.Saldo_duplicatas_a_vencer__c` | Saldo duplicatas a vencer | currency | vazia | (não rastreado) |
| `Account.AccountHasCheckInTask__c` | Conta possui tarefa de Check-In? | checkbox | vazia | `TaskCreatedOrUpdated` |
| `Account.Deleted2__c` | Média de compras este ano | currency | vazia | rótulo duplicado de `AveragePurchasesThisYear__c`, ver risco R6 no design |
| `Account.LastActivityDate` | Última atividade | date (padrão) | — | plataforma |
| `Opportunity.NextStep` | Próxima etapa | string (padrão) | — | usuário |
| `Opportunity.LastStageChangeInDays`, `LastActivityInDays` | Dias em fase / Atividade recente | int (padrão) | — | plataforma |

Nenhum desses campos custom tem `Description`, o que confirma o achado 4 do assessment para
este subconjunto. O significado de cada um, inclusive a definição de "compra" (pedido?
oportunidade ganha?), **não pode ser inferido pelo nome**.

## 4. IA, Agentforce e recomendação já presentes

| Item | Encontrado |
|---|---|
| Bot `SFAgent2` | `AgentforceEmployeeAgent`, tipo `InternalCopilot`. **As 4 versões (`BotVersion` 1–4) estão `Inactive` nesta sandbox** |
| GenAiPlannerBundle | `SFAgent2_v1` … `SFAgent2_v4` |
| Tópicos do `SFAgent2_v4` | `agent_router`, `off_topic`, `ambiguous_question`, **`insights_comerciais`** ("Insights Comerciais e Acompanhamento") |
| Descrição de `insights_comerciais` (metadata) | "Responde perguntas sobre produtos, políticas e procedimentos da empresa, analisa o histórico de pedidos e oportunidades de uma conta, **gera insights para negociação** e identifica oportunidades paradas, pedidos pendentes e **sinais de risco na carteira do vendedor**." |
| Ações de `insights_comerciais` | só ações padrão: `identifyRecordByName`, `queryRecords`, `queryRecordsWithAggregate` |
| GenAiPlugin / GenAiFunction / GenAiPromptTemplate custom | 0 / 0 / 0 |
| RecommendationStrategy (Einstein Next Best Action) | 0 |
| Apex `CustomerSummaryService` (api 67, `with sharing`, `@InvocableMethod` "Resumir Cliente") | existe como **scaffold bloqueado**. O comentário da classe diz que a arquitetura de EPLAST-23 foi aprovada em 2026-10-06, mas que as decisões de negócio D2–D6 (inclusive o mascaramento LGPD de contato antes do LLM) seguem sem resposta. Hoje a classe só lança `CustomerSummaryPendingDecisionException`. Cobertura: 10/10 linhas |
| Permission set `PS_Comercial_ResumoClienteAgente` | existe (custom) |
| Permission set `sfdc_aiplanner_service_permset` | existe |
| LWC custom | `opportunityLostReason`, `opportunityLostReasonModal`, ambos sem relação com o tema |
| FlexiPages de Account | `Account_Record_Page`, `Account_Record_Page_Three_Column` |

Permission Set Licenses de IA ativas **nesta sandbox**, todas com 0 ou poucas usadas:
Einstein Prompt Templates, Agentforce Platform Developer and Admin, Agent platform builder,
Agentforce Sales Coach (e User), Engagement Agent (e Access), Task-Based Agents, Einstein AI
Skills, entre outras. **Isso não prova licença em produção.** O resultado do entregável
`eplast-ent-04` (licenças e créditos de IA) não está no workspace.

## 5. Código e cobertura

- `ApexOrgWideCoverage.PercentCovered` = **11** (o assessment de 2026-09-30 registrava 10).
- `ApexCodeCoverageAggregate` das classes do caminho de automação dos três objetos:
  `AccountTrigger` 0/13, `AccountTriggerHelper` 0/17, `OpportunityTrigger` 0/8,
  `OpportunityTriggerHelper` 0/17, `OrderTrigger` 0/5, `OrderTriggerHandler` 0/82.
  **Zero linha coberta** no caminho de automação dos três objetos.
- `OpportunityTriggerHelper` é `Queueable, Database.AllowsCallouts` e chama
  `ProtheusAPI.getClientByCNPJ` dentro de um loop por conta. É a mesma dívida de "callout em
  loop" já registrada no design de EPLAST-39 [RAG: demandas/EPLAST-39/03-design.md].
- 54 classes custom em `/tmp/recon`, com a convenção `Test<Classe>` predominando.
  `CustomerSummaryServiceTest`, `CreateQuoteCPQControllerTest` e
  `FlowOpportunityControllerTest` seguem `<Classe>Test`.

## 6. Perfis e permissões

- Perfis comerciais: `Comercial`, `Comercial Padrão`, `Comercial - Analista`,
  `Comercial - Analistas` (achado 8 do assessment, confirmado).
- Permission sets custom ligados a IA: `PS_Comercial_ResumoClienteAgente`.

## 7. Divergências em relação ao assessment (2026-09-30)

| Item | Assessment | Hoje |
|---|---|---|
| API da org | v67 | **v68** |
| Cobertura org-wide | 10% | **11%** |
| Triggers e Flows em Account/Opportunity/Order | como listado no achado 1 | **confirmado**, e agora com o detalhe de que os Flows after-save não têm critério de entrada e que o update de Account reenfileira o envio ao Protheus |
| Achado 6 (alias dev aponta para instância "qa") | aberto | **segue aberto**: o host da instância de `sbx-eplast-dev` continua indicando "qa". `sbx-eplast-qa` não está configurado neste runner |

## 8. O que não foi possível medir

- Volume real de contas por vendedor e de pedidos ou itens por conta (dev vazia, prod proibida).
- Quem preenche `Account.LastPurchase__c`. Não há Apex nem Flow custom que escreva nele, e
  integração de entrada (API externa) não aparece em metadata da org.
- Detalhe interno de `Oportunidade_Industria`, `AccountTriggered`, `UpdateParentAccountUsedLimit`
  e do before-save de Order. O critério de entrada foi lido, a lógica completa não.
- Ordem de execução real entre `SBQQ.*` e os triggers custom no mesmo evento. A plataforma
  não garante ordem entre triggers do mesmo objeto, e isso não se mede por metadata.
- Licenciamento de IA em produção.
- Comparação de metadata dev × QA (alias de QA ausente).
