# EPLAST-30 — Recon da org

**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`) · `Organization.IsSandbox = true` · Enterprise Edition · API v68.0
**Data da coleta:** 2026-11-11 · válido até 2026-11-18. Recon com mais de 7 dias está vencido; refaça se o build começar depois disso.
**Método:** `sf org list`, `sf org display`, `sf sobject describe`, `sf org list metadata`, `sf data query` (só metadata e `COUNT()`), Tooling API e `sf project retrieve start` para `/tmp/recon30` (fora do repositório; nada foi trazido para `force-app/`).
**Escrita na org:** nenhuma. Nenhum deploy, DML ou Apex anônimo.
**Dados de negócio:** nenhum registro lido. Só contagens agregadas e definições de metadata (guardrail #2).

---

## 1. Ambiente e a suspeita dev = qa (achado 6 do assessment)

| Item | Resultado | Comando |
|---|---|---|
| Orgs autenticadas neste runner | só `sbx-eplast-dev`. `sbx-eplast-qa` **não está autenticada** | `sf org list` |
| Tipo | Sandbox, Enterprise Edition | `SELECT IsSandbox, OrganizationType FROM Organization` |
| Instância de `sbx-eplast-dev` | a URL de instância ainda tem o nome de sandbox **`qa`** (`eplast--qa`), e o usuário de conexão também termina em "qa" | `sf org display` |

**Conclusão: não confirmado e não refutado.** A evidência do assessment continua válida: o alias de **dev** aponta para uma sandbox que se chama **qa**. Sem `sbx-eplast-qa` autenticada, não há como comparar Org IDs. Se o Org ID de `sbx-eplast-qa` também for `00DHa000006vfMLMAY`, as duas são a mesma sandbox. Também não foi possível comparar a metadata de dev e qa (Flows, validation rules). **Pendência antes do QA** (design, risco R4).

---

## 2. Volume (contagem, sem ler registros)

| Objeto | `COUNT()` em dev |
|---|---|
| Opportunity | 0 |
| Account | 0 |
| Contact | 0 |
| OpportunityContactRole | 0 |
| Quote (padrão) | 0 |
| SBQQ__Quote__c | 0 |
| SBQQ__QuoteLine__c | 0 |
| Task / Event | 0 / 0 |
| Product2 | 1042 |

A dev está vazia de dados comerciais. O volume de produção não pode ser inferido daqui, e não se tentou inferir. A distribuição "linhas de cotação por oportunidade" (o cenário de um pai com muitos filhos) **não é mensurável** nesta org.

---

## 3. Compartilhamento (OWD), item "não medido" do assessment

| Objeto | OWD interno | Comando |
|---|---|---|
| Account | `Edit` (Public Read/Write) | `SELECT DefaultAccountAccess, DefaultOpportunityAccess, DefaultContactAccess FROM Organization` |
| Opportunity | `Read` (Public Read Only) | idem |
| Contact | `ControlledByParent` | idem |

Todo usuário interno lê toda Opportunity, Account e Contact (salvo restrição de perfil ou FLS, não medida aqui). O cenário "usuário sem acesso à oportunidade Y" da análise **tem pouca chance de acontecer** via compartilhamento nesta org. A restrição real fica em CRUD/FLS por perfil e permission set. Regras de compartilhamento por critério não foram lidas.

---

## 4. Automação nos objetos da demanda

### 4.1 Apex Triggers (Tooling `ApexTrigger`, todos `Active`)

| Objeto | Trigger | Namespace | API | Eventos |
|---|---|---|---|---|
| Opportunity | `OpportunityBefore` | SBQQ | 57 | before insert, before update, before delete |
| Opportunity | `OpportunityAfter` | SBQQ | 57 | after insert, after update |
| Opportunity | `OpportunityTrigger` | (custom) | 59 | after insert, after update |
| Account | `AccountBefore` | SBQQ | 57 | before insert, before update |
| Account | `AccountTrigger` | (custom) | 58 | before/after insert, before/after update |
| OpportunityLineItem | `OpportunityLineItemTrigger` | SBQQ | 57 | todos |
| SBQQ__Quote__c | `QuoteBefore` / `QuoteAfter` | SBQQ | 57 | before ins/upd/del · after ins/upd |
| SBQQ__QuoteLine__c | `QuoteLineBefore` / `QuoteLineAfter` | SBQQ | 57 | before ins/upd/del · after ins/upd/del |
| Event | `AdvRouteEvents` | maps | 66 | todos |
| Contact, Quote (padrão), QuoteLineItem, Task | nenhum | — | — | — |

O `OpportunityTrigger` (custom) só delega para `OpportunityTriggerHandler`, com bypass por `TriggerUtility.bypassTrigger`. O after update **não roda** dentro de Queueable (`!System.isQueueable()`). O `AccountTrigger` segue o mesmo padrão (`AccountTriggerHandler`: validação e enriquecimento de CNPJ).

### 4.2 Flows record-triggered e agendados (`FlowDefinitionView` + retrieve em `/tmp/recon30`)

| Objeto | Flow | Tipo | Evento | Critério de entrada | `triggerOrder` | O que faz (contagem de elementos) |
|---|---|---|---|---|---|---|
| Opportunity | `OpportunityFlow` | RecordAfterSave | Create+Update | **nenhum** | não definido | 10 updates, 12 creates, 10 lookups; chama `CreateQuoteCPQController` (3x) e `submit` (envio para aprovação) |
| Opportunity | `Oportunidade_Industria` | RecordAfterSave | Update | `NomeTipoRegistro__c` | não definido | 5 creates; chama `FlowOpportunityController` |
| Opportunity | `ScheduledFlowOpportunity` | Scheduled | — | `IsWon` | — | 6 updates |
| Account | `AccountTriggered` | RecordAfterSave | Create+Update | **nenhum** | não definido | 1 update, 4 creates |
| Account | `UpdateParentAccountUsedLimit` | RecordAfterSave | Create+Update | **nenhum** | não definido | 2 updates |
| SBQQ__Quote__c | `CPQQuoteFlow` | RecordAfterSave | Create+Update | OR em 16 campos SBQQ | não definido | 2 updates |
| SBQQ__QuoteLine__c | `QuoteLineCPQFlow` | RecordAfterSave | Create+Update | **nenhum** | não definido | 2 updates, 1 create |
| SBQQ__QuoteLine__c | `DeleteLineItemCPQFlow` | RecordBeforeDelete | Delete | (não lido) | — | — |
| Quote (padrão) | `Quote_AfterUpdate_SyncToCPQ` | RecordAfterSave | Update | `HasCPQ__c` E mudança de endereço/status/validade | não definido | 1 update |
| QuoteLineItem | `QuoteLineItemFlowCreatedOrUpdated` | RecordAfterSave | Create+Update | **nenhum** | não definido | 3 updates, 1 create, `submit` |
| Task | `TaskCreatedOrUpdated` | RecordAfterSave | Create+Update | **nenhum** | não definido | 1 update |
| Contact | nenhum | — | — | — | — | — |

Também existe o Flow de tela `PaymentTermsOpportunity`, embutido na página `Opportunity_Record_Page` (`flowruntime:interview`).

### 4.3 Ordem de execução real em Opportunity (o ponto mais forte da análise)

A ordem da plataforma (skill `salesforce-doutrina`) aplicada ao que existe hoje:

1. before-save Flows em Opportunity: **nenhum**
2. before triggers: `SBQQ.OpportunityBefore` (único)
3. validation rules custom: 16 ativas (seção 6)
4. gravação, sem commit
5. after triggers: `OpportunityTrigger` (custom) **e** `SBQQ.OpportunityAfter`. **Entre os dois, a plataforma não garante ordem.**
6. after-save Flows: `OpportunityFlow` **e** `Oportunidade_Industria`. **Nenhum dos dois tem `triggerOrder`**, então a ordem entre eles também não está fixada por configuração.
7. aprovação (`submit` dentro do `OpportunityFlow`, processo `Opportunity.FinancialAnalysis`), cross-object e commit

**Fato que pesa no design:** o `OpportunityFlow` roda em **todo** insert e update de Opportunity, **sem critério de entrada**. Ele faz até 22 DMLs, cria cotação CPQ por Apex e pode submeter aprovação. Qualquer escrita em Opportunity, mesmo um campo novo de rascunho, dispara essa cadeia, além de dois triggers after em ordem não garantida. Se a escrita ocorrer em Account, a cadeia é `AccountTrigger` + `SBQQ.AccountBefore` + dois Flows after-save sem critério. Se for em Task, `TaskCreatedOrUpdated` (sem critério; segundo o design da EPLAST-27 no RAG, atualiza `Account.AccountHasCheckInTask__c`, o que reabre a cadeia de Account. Não reconferido nesta coleta).

**Uma solução somente leitura não entra em nenhum desses passos**, porque nenhum deles roda sem DML.

### 4.4 Processos de aprovação
`Opportunity.FinancialAnalysis`, `Order.LiberationFinancial`, `Quote.AssignPricing` (`sf org list metadata --metadata-type ApprovalProcess`).

---

## 5. Campos disponíveis para grounding (`sf sobject describe`)

**Opportunity (padrão / CPQ), todos existem:** `AccountId`, `StageName`, `CloseDate`, `Amount`, `Probability`, `NextStep`, `Description`, `Type`, `LeadSource`, `OwnerId`, `RecordTypeId`, `Pricebook2Id`, `SyncedQuoteId`, `ContactId`, `IsWon`, `IsClosed`, `LastActivityDate`, `SBQQ__PrimaryQuote__c`, `SBQQ__Contracted__c`.

**Opportunity, campos custom sem namespace (19):** `Branch__c`, `Budget_Confirmed__c`, `CurrentYear__c`, `DescricaoPerda__c`, `Discovery_Completed__c`, `FinancialAnalysis__c`, `Formas_de_Pagamento__c`, `IsDivided__c`, `LastMonth__c`, `LastMoth__c`, `Loss_Reason__c`, `MessageForInvoice__c`, `NomeTipoRegistro__c`, `PaymentTermId__c`, `PaymentWay__c`, `Previs_o_Eintein__c`, `ROI_Analysis_Completed__c`, `TaxAnalysis__c`, `ThisYear__c`.

**Descrição dos campos custom sem namespace (Tooling `CustomField`, `Description = null`):**

| Objeto | Campos custom | Sem descrição |
|---|---|---|
| Opportunity | 19 | 19 |
| Account | 78 | 77 |
| Contact | 1 | 1 |

O número é pior que o do assessment (que contou também os campos gerenciados). **Nenhum** campo custom de Opportunity tem descrição. Há nomes ambíguos ou duplicados (`LastMonth__c` e `LastMoth__c`; `Loss_Reason__c` e `DescricaoPerda__c`; `PaymentWay__c`, `Formas_de_Pagamento__c` e `PaymentTermId__c`).

**Account:** `Name`, `Industry`, `Type`, `BillingCity`, `BillingState`, `ParentId`, `Description` existem.
**Contact:** `Name`, `Title`, `AccountId` existem. `Email`, `Phone` e `MobilePhone` também existem e são **dado pessoal**.
**SBQQ__Quote__c:** `SBQQ__Opportunity2__c`, `SBQQ__Primary__c`, `SBQQ__Status__c`, `SBQQ__NetAmount__c`, `SBQQ__PaymentTerms__c`, `SBQQ__ExpirationDate__c`, `SBQQ__CustomerDiscount__c`, `SBQQ__LineItemCount__c` existem.
**SBQQ__QuoteLine__c:** `SBQQ__Quote__c`, `SBQQ__Product__c`, `SBQQ__Quantity__c`, `SBQQ__NetPrice__c`, `SBQQ__NetTotal__c`, `SBQQ__Discount__c`, `SBQQ__Description__c` existem.
**Quote padrão:** habilitado (`QuoteSettings.enableQuote = true`), com 0 registros. A cotação de trabalho da Eplast é a do CPQ, como indicam os Flows de sincronização Quote → CPQ.

---

## 6. Validation rules ativas (Tooling `ValidationRule`, por nome)

Relevantes **só para a criação de dados sintéticos de teste**. A solução proposta não grava nesses objetos.

| Objeto | Ativas | Nomes |
|---|---|---|
| Opportunity | 16 | `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo` |
| Account | 6 | `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk` |
| Contact | 2 | `Telefone`, `WhatsApp` |
| SBQQ__Quote__c | 3 | `End_Date_Before_Start_Date`, `Invalid_Subscription_Term`, `CreateQuoteLineItemWithoutPaymentTerm` |
| SBQQ__QuoteLine__c | 6 | `Additional_discount_percent_or_amount`, `Invalid_Subscription_Term`, `Markup_percent_or_amount`, `RecurringChargeTypeMustHaveBillingType`, `Validate_billing_frequency`, `Validate_billing_type` |

As regras de Opportunity exigem conta completa (endereço, CNAE, e-mail, telefone, loja) e **vendedor com ID do Protheus**. Criar uma oportunidade sintética exige uma conta sintética completa e um owner configurado.

---

## 7. IA generativa na org

| Item | Resultado | Comando |
|---|---|---|
| Einstein generativo | **habilitado** (`EinsteinGptSettings.enableEinsteinGptPlatform = true`) | retrieve `Settings:EinsteinGpt` |
| Provedores de modelo | **nenhum desligado**: `disableAIProvOpenAI`, `disableAIProvAzureOpenAI`, `disableAIProvAWSBedrock` e `disableAIProvVertexGemini` estão todos `false`. `disableAIProviderRegionFallback = false` | idem |
| `enableEnhancedPromptSecurity` | `false` | idem |
| Prompt templates custom (`GenAiPromptTemplate`) | **0** | `sf org list metadata --metadata-type GenAiPromptTemplate` |
| Prompt flows (`ProcessType = PromptFlow`) | 5, **todos de pacote gerenciado** (`OfferMgmt`, `setup_service_plan`, `sfdc_fieldservice`). Isso mostra que o tipo de Flow existe nesta org | `FlowDefinitionView` |
| Agentes (`Bot`) | 1: `SFAgent2` (tipo `AgentforceEmployeeAgent`), com planner `SFAgent2_v1` a `v4` | `sf org list metadata --metadata-type Bot / GenAiPlannerBundle` |
| Tópicos de `SFAgent2_v4` | `agent_router`, `ambiguous_question`, `off_topic`, `insights_comerciais` (ações padrão `queryRecords`, `queryRecordsWithAggregate`, `identifyRecordByName`, todas de leitura) | retrieve `GenAiPlannerBundle:SFAgent2_v4` |
| `GenAiPlugin` / `GenAiFunction` custom | 0 / 0 | `sf org list metadata` |
| Licença Einstein Prompt Templates (`EinsteinGPTPromptTemplatesPsl`) | Active, 0 usadas | `PermissionSetLicense` |
| Outras PSL de IA ativas | Agentforce Coworker, Agent platform builder, Agentforce Platform Developer and Admin, Einstein AI Skills, Agentforce Sales Coach e outras, todas com 0 usadas | idem |
| Permission sets padrão de prompt | `EinsteinGPTPromptTemplateUser`, `EinsteinGPTPromptTemplateManager` existem. **0 atribuições** (somando `PS_Comercial_ResumoClienteAgente`) | `PermissionSet`, `PermissionSetAssignment` (`COUNT()`) |
| Named Credential / External Credential | **0 / 0** | `sf org list metadata` |

Esses números de licença são **desta sandbox**. Licença e habilitação em produção não foram e não serão consultadas (guardrail #1).

---

## 8. Interface de Opportunity

| Item | Resultado |
|---|---|
| Lightning pages de Opportunity | `Opportunity_Record_Page` e `Opportunity_Record_Page_Three_Column` (Tooling `FlexiPage`). **Qual está ativa para qual app ou perfil não foi lido** |
| Componentes em `Opportunity_Record_Page` | highlights panel, path, activity panel, tabsets, `opportunityLostReason` (LWC custom) e um `flowruntime:interview` (`PaymentTermsOpportunity`) |
| Page layouts | `Opportunity-Opportunity Layout`, `Opportunity-CPQ Opportunity Layout` |
| Record types ativos | 5: `Bonus`, `Sale`, `Sample`, `SellWithShipping`, `Industria` |
| LWC custom na org | `opportunityLostReason`, `opportunityLostReasonModal` (fora os do SBQQ) |

---

## 9. Segurança e usuários (contagens)

| Item | Resultado |
|---|---|
| Perfis comerciais | `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas` (achado 8 do assessment segue aberto) |
| Usuários ativos por perfil | `Administrador do sistema` 9 · `Comercial - Analista` 4 · `Financeiro` 1 · perfis de integração 1 cada · 3 sem perfil retornado |
| Licença `Salesforce` | 14 de 14 usadas. **Não há licença livre para criar usuário de teste** |
| Permission sets custom ligados a IA | `PS_Comercial_ResumoClienteAgente` (existe, 0 atribuições) |

---

## 10. Apex relacionado (só leitura de nome e versão)

| Classe | API |
|---|---|
| `OpportunityTriggerHandler` | 59 |
| `TriggerUtility` | 59 (há também `triggerUtility`, v46, com outro casing) |
| `CreateQuoteCPQController` | 61 |
| `FlowOpportunityController` | 64 |

O design desta demanda não toca nenhuma delas.

---

## 11. O que não foi medido

- Qual Lightning page de Opportunity está ativada, e para qual app, perfil ou record type.
- FLS dos campos-fonte por perfil comercial.
- Regras de compartilhamento por critério (o OWD foi medido).
- Se o Einstein Trust Layer tem mascaramento de dados e auditoria (Data Cloud) configurados. Não há comando `sf` simples para isso nesta rodada.
- Metadata de `sbx-eplast-qa` (não autenticada).
- Qualquer coisa de produção (proibido).
