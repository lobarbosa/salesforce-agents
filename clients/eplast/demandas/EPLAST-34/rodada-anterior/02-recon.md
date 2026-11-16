# EPLAST-34 — Recon da org

**Data da coleta:** 2026-11-11 (vence em 2026-11-18, ver skill `org-recon`)
**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`), `Organization.IsSandbox = true`, Enterprise Edition, API 68.0, `Connected`.
**Org de QA:** `sbx-eplast-qa` **não está autenticada neste runner** (`sf org list` lista só `sbx-eplast-dev`). Não foi possível comparar dev com QA.
**Método:** `sf data query` (metadata e `COUNT()`), Tooling API, `sf org list metadata` e `sf project retrieve start` para um projeto temporário em `/tmp/recon/e34/` (nunca para `force-app/`). Nenhum registro de negócio foi lido.

Escopo: a demanda não define fontes (pergunta 7 da análise, em aberto). O recon cobre os objetos que a análise cita como prováveis fontes (Account, Contact, Opportunity, Order, OrderItem, Case, Task) e o que já existe na org para "resumo" e "relatório de reunião": Agentforce, prompt templates, relatórios, painéis e forecast.

---

## 0. Ambiente (achado 6 do assessment, ainda aberto)

| Item | Resultado | Comando |
|---|---|---|
| Orgs autenticadas | Só `sbx-eplast-dev` | `sf org list` |
| Instance URL de `sbx-eplast-dev` | `https://eplast--qa.sandbox.my.salesforce.com`. Mesmo host que o assessment registrou: o alias de dev aponta para uma instância com "qa" no nome | `sf org display --json` |
| API | 68.0 (assessment registrou v67 em 2026-09-30) | idem |

## 1. Volume (sandbox vazia)

`SELECT COUNT()` em cada objeto: **Account 0, Contact 0, Opportunity 0, Order 0, OrderItem 0, Case 0, Task 0, Event 0, Lead 0, SBQQ__Quote__c 0.**

Não há volume para dimensionar governador nem para validar resumo com dado realista. Volume de produção não foi e não será consultado (guardrail #1).

## 2. Compartilhamento (lacuna do assessment, fechada aqui)

`SELECT DefaultAccountAccess, DefaultOpportunityAccess, DefaultContactAccess, DefaultCaseAccess, DefaultLeadAccess FROM Organization`:

| Objeto | OWD interno |
|---|---|
| Account | **Edit** (público leitura/gravação) |
| Opportunity | **Read** (público somente leitura) |
| Contact | Controlado pelo pai |
| Case | ReadEditTransfer |
| Lead | ReadEditTransfer |

Leitura: para usuário interno, Account e Opportunity já são visíveis para todos. A diferença de visibilidade entre usuários vem de **FLS e de permissão de objeto** (perfis, permission sets), não de compartilhamento de registro. Order não aparece no `Organization` (segue Account por padrão na plataforma; não confirmei a configuração específica). Regras de compartilhamento não foram lidas.

## 3. Automação nos objetos-fonte (achado 1 do assessment, reconfirmado)

### 3.1 Triggers (`ApexTrigger`, Tooling)

| Objeto | Trigger | Namespace | Eventos |
|---|---|---|---|
| Account | `AccountBefore` | SBQQ | before insert/update |
| Account | `AccountTrigger` | — | before/after insert/update |
| Opportunity | `OpportunityBefore` | SBQQ | before insert/update |
| Opportunity | `OpportunityAfter` | SBQQ | after insert/update |
| Opportunity | `OpportunityTrigger` | — | after insert/update |
| Order | `OrderTrigger` | SBQQ | before/after insert/update |
| Order | `OrderTrigger` | — | before/after update |
| OrderItem | `OrderProductTrigger` | SBQQ | before/after insert/update |
| Event | `AdvRouteEvents` | maps | before/after insert/update |

Contact, Case e Task: nenhum trigger.

### 3.2 Flows record-triggered próprios (`FlowDefinitionView`, sem namespace, ativos)

| Objeto | Flow | Tipo |
|---|---|---|
| Account | `AccountTriggered` | RecordAfterSave, create+update |
| Account | `UpdateParentAccountUsedLimit` | RecordAfterSave, create+update |
| Opportunity | `OpportunityFlow` | RecordAfterSave, create+update |
| Opportunity | `Oportunidade_Industria` | RecordAfterSave, update |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | RecordBeforeSave, create+update |
| Order | `Order` | RecordAfterSave, create+update |
| Task | `TaskCreatedOrUpdated` | RecordAfterSave, create+update |

Agendados nos mesmos objetos: `AccountUpdateEconomicGroup`, `ScheduledFlowOpportunity`, `OrderScheduledFlow` (ativos); `Account` (agendado, inativo).

### 3.3 Integração com o Protheus disparada por update de Account

Retrieve de `AccountTriggerHelper` (em `/tmp/recon`): `updateAccountInfoFromCNPJ` faz, **para cada Account atualizada**, um `System.enqueueJob`. Se `CompanyDocument__c` mudou, enfileira `UpdateAccountCompanyInfo`; **caso contrário, enfileira `SendAccountToProtheus`**. Não há filtro por campo alterado.

Consequência: qualquer gravação em Account, de qualquer campo, reenvia a conta ao ERP. Em lote síncrono, cada conta consome um `enqueueJob` (limite de 50 por transação). Isso confirma, nesta data, o que o design da EPLAST-27 já tinha registrado [RAG: demandas/EPLAST-27/03-design.md, D1].

## 4. O que já existe na org para "resumo" e IA generativa

### 4.1 Plataforma

- `EinsteinGptSettings` (retrieve): `enableEinsteinGptPlatform = true`. Os provedores externos de modelo **não estão desligados**: `disableAIProvOpenAI`, `disableAIProvAzureOpenAI`, `disableAIProvAWSBedrock` e `disableAIProvVertexGemini` estão todos `false`. Relevante para a pergunta 10 (LGPD): se houver texto gerado, o conteúdo pode ser processado por um desses provedores através da camada da Salesforce. A decisão sobre isso não é técnica.
- Licenças de permission set ativas (`PermissionSetLicense`), todas com 0 em uso nesta sandbox: Einstein Prompt Templates, Agentforce Coworker, Agentforce Platform Developer and Admin, Einstein AI Skills, Agentforce Sales Coach, entre outras. A quantidade reflete a sandbox, não produção.
- Permission sets padrão presentes: `EinsteinGPTPromptTemplateUser`, `EinsteinGPTPromptTemplateManager`, `PromptTemplatePermSet`, `AgentPlatformBuilder`.

### 4.2 Agente existente

- `Bot` `SFAgent2` (Agentforce Employee Agent), 4 versões de `GenAiPlannerBundle` (`SFAgent2_v1` a `_v4`). **As 4 `BotVersion` estão `Inactive`.**
- `SFAgent2_v4` (Agent Script, retrieve decodificado em `/tmp/recon/e34/agent.txt`): roteador com 3 subagentes (`off_topic`, `ambiguous_question`, `insights_comerciais`). O `insights_comerciais` **já gera um "resumo de cliente"** com seções fixas ("Cliente e período analisado", "Histórico de compras", "Pontos de atenção e acompanhamento"), oportunidades paradas, pedidos pendentes, comparação de períodos e sugestões ao vendedor. As ações são de leitura (`IdentificarConta`, `ConsultarPedidos`, `AgregacaoPedidos`, reaproveitadas com outros nomes para Opportunity e Task). A instrução diz "Never modify any records; only read data".
- É o território dos entregáveis contratados `eplast-ent-09` e `eplast-ent-10` (`contrato.md`), construídos fora da esteira.
- `GenAiPromptTemplate`, `GenAiPlugin`, `GenAiFunction`: **nenhum custom na org**.

### 4.3 Apex de resumo

- `CustomerSummaryService` e `CustomerSummaryServiceTest` (API 67, sem namespace). Retrieve: **scaffold bloqueado** da EPLAST-23. A arquitetura foi aprovada, mas as decisões de negócio e LGPD (D2–D6: objeto de ocorrência, campos, janelas, limiares, mascaramento de contato) nunca foram respondidas. A classe só lança erro explicando a pendência.
- Permission set `PS_Comercial_ResumoClienteAgente` (custom): concede só acesso à classe `CustomerSummaryService`. **0 atribuições.**

## 5. Relatórios, painéis e forecast

- `Report`: 374. `Dashboard`: 19.
- Relatórios do cliente com nome ligado a carteira (pasta `ANALISTAS`): `ANÁLISE MENSAL DA CARTEIRA`, `ANÁLISE MENSAL DA CARTEIRA RECO_SAZONAL`, `Número Total das Carteiras` e um por região (CO, MG, NO/NE, RJ/ES, SP, SUL, DIRETA). Não li a definição deles.
- Painéis na pasta `Eplast`: `Leads & Oportunidades` e `Pedidos`. Os demais são padrão (Sales/Service, Trailhead, Einstein Conversation Insights).
- **Nenhum relatório ou painel com S&OP, GDD, Board, Reunião ou Resumo no nome.** "Leaderboard" aparece em relatórios padrão, sem relação com Board.
- `ForecastingType`: `Opportunity_Amount` **ativo** (forecast colaborativo por valor de oportunidade). Os demais tipos estão inativos.

## 6. Modelo de dados

- Objetos custom próprios (sem namespace, `__c`): `Branch__c`, `ShippingCompany__c`, `SalesReturn__c`, `TypeOperation__c`, `PaymentTerms__c`, `EconomicGroup__c`, `In_App_Checklist_Settings__c`, `IntegrationLog__c`, `FormPayment__c`, `RelationshipAccountsPaymentTerm__c`. **Nenhum objeto de meta, orçamento ou plano de vendas.** "Meta", conceito citado na análise (pergunta 7), não tem fonte identificável na org de dev.
- Campos custom em Account, Opportunity, Order e OrderItem: 223, dos quais **153 sem descrição**. Reconfirma o achado 4 do assessment, com os mesmos números.

## 7. Perfis e permissões

Não li FLS campo a campo, porque as fontes do resumo não estão definidas. O achado 8 do assessment (quatro variações de perfil comercial) continua sem resposta.

## 8. Lacunas deste recon

- `sbx-eplast-qa` não autenticada: não comparei dev com QA.
- Definição dos relatórios de carteira e dos dois painéis da pasta `Eplast` não lida. Só vale ler depois que a pergunta 7 disser se eles são a fonte.
- Regras de compartilhamento e configuração de OWD de Order não lidas.
- Prompt templates padrão (não custom) que a Salesforce entrega não foram listados. `sf org list metadata` retorna só os custom.
- FLS das fontes não lida (depende da pergunta 7).
