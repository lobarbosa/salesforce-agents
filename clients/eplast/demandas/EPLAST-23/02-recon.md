# Recon da org — EPLAST-23: Resumo inteligente de cliente (Agentforce)

**Data da coleta:** 2026-10-06 (vale até 2026-10-13; depois disso, refazer)
**Org:** `sbx-eplast-dev`, Org Id `00DHa000006vfMLMAY`, `https://eplast--qa.sandbox.my.salesforce.com`, API v67.0
**Confirmação de sandbox:** `SELECT IsSandbox, OrganizationType FROM Organization` retornou `true | Enterprise Edition` (instância BRA8S)
**Natureza:** somente leitura. Nenhum deploy, nenhuma DML. Só metadata e contagens (`COUNT()`), sem nenhum dado de registro de cliente lido.

> Atenção (herdada do assessment, achado 6): o alias `sbx-eplast-dev` aponta para uma sandbox cujo usuário e URL se identificam como **qa** (`projetos@konectabr.com.eplast2.qa`). Este recon vale para essa sandbox, seja ela qual for.

---

## 1. Agentforce / Einstein Generative AI — o que existe

| Item | Resultado | Comando |
|---|---|---|
| Einstein Generative AI (plataforma) | **Habilitado** (`enableEinsteinGptPlatform=true`). Nenhum provedor de LLM desabilitado | `sf project retrieve start --metadata Settings:EinsteinGpt` |
| Agentes (`Bot` / `BotDefinition`) | **0**. O tipo de metadata é reconhecido, mas não existe nenhum registro | `sf org list metadata --metadata-type Bot`; `SELECT COUNT() FROM BotDefinition` |
| Planners (`GenAiPlannerBundle` / `GenAiPlannerDefinition`) | **0** | idem |
| Topics (`GenAiPlugin` / `GenAiPluginDefinition`) | **0** | idem |
| Actions custom (`GenAiFunction` / `GenAiFunctionDefinition`) | **0** | idem |
| Prompt Templates (`GenAiPromptTemplate`) | **0** | `sf org list metadata --metadata-type GenAiPromptTemplate` |
| `AiAuthoringBundle` | 0 | idem |
| `GenAiPlanner` (tipo legado) | Tipo inválido em v67 (`INVALID_TYPE`). Usar `GenAiPlannerBundle` | idem |

**Licenças de permission set (PSL) relacionadas, todas `Active` e com 0 em uso**, exceto Activity Capture:

| PSL (DeveloperName) | Rótulo | Total | Usadas |
|---|---|---|---|
| `AgentforcePlatformDeveloperAndAdminPsl` | Agentforce Platform Developer and Admin | 100000 | 0 |
| `AgentPlatformBuilderPsl` | Agent platform builder | 2000 | 0 |
| `AgentforceServiceAgentBuilderPsl` | Agentforce Service Agent Builder | 10000 | 0 |
| `AgentforceServiceAgentUserPsl` | Agentforce Service Agent User | 200 | 0 |
| `AISearchAdminPsl` / `AISearchUserPsl` | Agentforce Coworker Setup / Agentforce Coworker | 100000 | 0 |
| `EinsteinGPTPromptTemplatesPsl` | Einstein Prompt Templates | 100000 | 0 |
| `EinsteinGPTAiSkillsManagerPsl` / `EinsteinGPTAiSkillsUserPsl` | Einstein AI Skills Manager / Einstein AI Skills | 100000 / **1** | 0 |
| `EinsteinGPTGroundingStructuredDataPsl` | Einstein GPT Metadata Studio | 50 | 0 |
| `GenieDataPlatformStarterPsl` | Data Cloud | 200000 | 0 |
| `EinsteinSdrAgentPsl`, `EinsteinCoachAgentPsl`, `InboundLeadGenAgentPsl`, `TaskBasedAgentsPsl` | agentes SDR / Coach / Lead / Task-based | — | 0 |

Comando: `SELECT DeveloperName, MasterLabel, TotalLicenses, UsedLicenses, Status FROM PermissionSetLicense`

**Permission sets padrão (namespace `force`) presentes:** `AgentforceDeveloperAndAdminTools`, `AgentPlatformBuilder`, `AgentforceServiceAgentBuilder`, `AgentforceServiceAgentUser`, `AgentforceServiceAgentBase`, `AgentforceServiceAgentSecureBase`, `AgentforceServiceAgentUserPsg`, `AISearchAdmin`, `AISearchUser`, `EinsteinGPTPromptTemplateManager`, `EinsteinGPTPromptTemplateUser`, `PromptTemplatePermSet`, `UseSetupWithAgentforce`, `EinsteinServiceInnovations`.

**Conclusões objetivas (resolvem parte de P1/A1 da análise):**
- A org está provisionada para Agentforce: plataforma de IA generativa ligada, licenças presentes e tipos de metadata reconhecidos. O que existe aqui é **greenfield**: nenhum agente, topic, action ou prompt template foi criado ainda.
- As "opções A/B/C" da análise (Custom Action, Einstein Copilot, Agentforce Skills) não são produtos distintos na v67. Hoje é tudo o mesmo Agentforce: **Agent → Topic → Actions**, e cada Action pode ser Flow, Apex invocável ou Prompt Template. A pergunta real que sobra é **qual tipo de agente** (funcionário ou Service Agent) e **qual implementação de action**. Ambas são tratadas no design.
- **Não foi possível confirmar via CLI:**
  - se o Agentforce (agentes de funcionário) está ligado no Setup. O tipo `Settings:Bot` / `Settings:EinsteinAgent` não voltou no retrieve.
  - se o Data Cloud foi de fato configurado. Existe a PSL, mas configuração não é a mesma coisa que licença.
  - quais **ações padrão** (ex.: identificar registro por nome, consultar registros, resumir registro) aparecem no catálogo do Agent Builder. Elas não aparecem como metadata listável.
  - o modelo de consumo/crédito contratado.

## 2. Objetos de negócio-alvo

Contagens agregadas (`SELECT COUNT() FROM <obj>`): **todos com 0 registros** nesta sandbox. Account, Contact, Opportunity, Order, Quote, `SBQQ__Quote__c`, Case, AccountContactRelation, `SalesReturn__c` e Task. Volume de produção **não pode** ser inferido daqui.

| Objeto | Rótulo | Campos (total / custom) | Record Types ativos | Vínculo com Account |
|---|---|---|---|---|
| `Account` | Conta | 136 / 90 | Mestre | `ParentId`, `BlowerCustomer__c`, `DeliveryCustomer__c` (auto-referências) |
| `Contact` | Contato | 54 / 3 | Mestre | `AccountId` |
| `Opportunity` | Oportunidade | 76 / 28 | Sample, Bonus, Industria, Sale, SellWithShipping | `AccountId` |
| `Order` | Pedido | 111 / 64 | Mestre | `AccountId`, `DeliveryCustomer__c`, `OpportunityId` |
| `Case` | Caso | 35 / **0** | Mestre | `AccountId`, `ContactId` |
| `Quote` (padrão) | Cotação | 82 / 9 | Mestre | `AccountId`, `OpportunityId` |
| `SBQQ__Quote__c` (CPQ) | Cotação | 107 / 94 | Mestre | `SBQQ__Account__c`, `SBQQ__Opportunity2__c` |
| `SalesReturn__c` | Devolução de Vendas | — | — | `AccountId__c`, `OrderId__c` |

Comando: `sf sobject describe --sobject <obj> --target-org sbx-eplast-dev`

### Campos relevantes confirmados (só existência e tipo; nenhum valor lido)

**Account:** `Name`, `Type` (picklist: Inativo, Novo, Prospect, Prospect Indústria, Reativo, Recorrente, Sazonal, Stand-by, Encerrou atividades), `Industry`, `Rating` (AA, A, B, C, D), `Phone`, `OwnerId`, `ParentId`, `LastActivityDate`, `CurrencyIsoCode` (a org é **multimoeda**).
- Identificação alternativa: `CompanyDocument__c` (CNPJ, string, **External ID**, não único), `ProtheusId__c` (ID da Conta no Protheus, string, **External ID**, não único), `Inactive__c` (boolean).
- Crédito: `LimitAmount__c`, `LimitUsed__c`, `LimitAmountDueDate__c`, `ChildAccountsUsedLimit__c`. **Existem dois campos com o mesmo rótulo "Limite de Crédito Disponível": `AvailableCreditLimit__c` e `AvailableCreditLimitt__c` (com dois "t").** Qual dos dois vale é desconhecido. Ver achado 4 do assessment.
- Não há Person Account (`IsPersonAccount` não existe).

**Contact:** `Name`, `Title`, `Phone`, `MobilePhone`, `Email`, `WhatsApp__c`, `AccountId`, `ReportsToId`, `LastActivityDate`. Os campos de contato são **dado pessoal (LGPD)**.

**Opportunity:** `StageName` (Qualificação, Análise Técnica, Precificação, Qualificado, Cotação, Execução técnica do projeto, Envio Cotação, Amostra, Análise Fiscal, Análise Financeira, Negociação Comercial, Fechado/Ganho, Fechado/Perdido), `Amount`, `CloseDate`, `Probability`, `IsClosed`, `IsWon`, `Type` (Compra Recorrente, Reativação, Nova Compra), `Loss_Reason__c`, `DescricaoPerda__c`, `Branch__c`, `SBQQ__PrimaryQuote__c`, `LastActivityDate`.

**Order:** `OrderNumber`, `Status` (Revisao de Pedido, Liberacao Financeiro, Liberacao Estoque, Faturamento, Cancelado, Concluido), `TotalAmount`, `Total_com_Desconto__c`, `EffectiveDate`, `IssuanceDate__c`, `DeliveryDate__c`, `ExpectedSaleDate__c`, `ProtheusId__c`, `ExternalNumber__c`, `ReasonCancellation__c`, `OpportunityId`, `SBQQ__Quote__c`. Orders habilitados (`enableOrders=true`), Enhanced Commerce Orders desligado.

**Case:** `CaseNumber`, `Subject`, `Status`, `Priority` (High, Medium, Low), `Origin` (Email, Phone, Web), `Type`, `IsClosed`, `AccountId`. `CaseStatus`: New (padrão, aberto), On Hold (aberto), Escalated (aberto), Closed (fechado). Não existe status "Working". Email-to-Case e Web-to-Case estão **desligados**, e Case tem 0 campos custom. Há indício de que Case é pouco ou nada usado na Eplast, mas isso não está confirmado: a sandbox está vazia.

**SalesReturn__c (Devolução de Vendas):** objeto custom unmanaged ligado a Account e Order (`AccountId__c`, `OrderId__c`, `Invoice__c`, `VlTotal__c`, `DtEmissao__c`, `ProtheusId__c`). Pode ser o que a Eplast chama de "ocorrência". Isso é **hipótese a validar**, não premissa.

Outros objetos custom unmanaged (via `sf org list metadata --metadata-type CustomObject`): `Branch__c`, `EconomicGroup__c`, `FormPayment__c`, `In_App_Checklist_Settings__c`, `IntegrationLog__c`, `PaymentTerms__c`, `RelationshipAccountsPaymentTerm__c`, `SalesReturn__c`, `ShippingCompany__c`, `TypeOperation__c`.

## 3. Segurança e acesso (resolve parte de P5/A4)

### OWD (Organization-Wide Default)
Comando: `SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition`

| Objeto | Interno | Externo |
|---|---|---|
| Account | ReadWrite | Private |
| Contact | ReadWrite | Private |
| Opportunity | **Read** | Private |
| Order | ReadWrite | Private |
| Case | ReadWriteTransfer | Private |
| Quote | ControlledByParent | ControlledByParent |

- Enterprise Territory Management: 1 modelo (`ManagementAccount`, **Active**), mas **0 territórios** (`SELECT COUNT() FROM Territory2`).
- `UserRole`: 2 papéis. `AccountTeamMember`: 0.
- **Leitura:** para usuários internos, **não há segregação por registro** nesta sandbox, porque todo usuário interno vê todo Account/Contact/Opportunity/Order/Case. O controle efetivo é de **objeto e campo (OLS/FLS)**. Se produção estiver configurada diferente (a sandbox herda a config no refresh, mas pode ter divergido), isso precisa ser confirmado.

### Perfis com usuários ativos
`SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive=true GROUP BY Profile.Name`: Administrador do sistema (9), **Comercial - Analista (4)**, Financeiro (1), além de perfis técnicos de integração (1 cada) e 3 sem perfil retornado.

### Permissão de objeto nos perfis de negócio
Comando: `SELECT Parent.Profile.Name, SobjectType, PermissionsRead, PermissionsEdit FROM ObjectPermissions`. Ausência na tabela significa **sem Read**.

| Perfil | Account | Contact | Opportunity | Order | Case | Quote |
|---|---|---|---|---|---|---|
| **Comercial - Analista** (4 ativos) | R/W | R/W | R/W | R/W | **sem acesso** | R/W |
| Financeiro (1 ativo) | R/W | R | R/W | R | **sem acesso** | R |
| Comercial (0 ativos) | R/W | R/W | R/W | R/W | sem acesso | R/W |
| Comercial - Analistas (0 ativos) | R/W | R/W | R | R/W | R/W | sem acesso |
| Comercial Padrão (0 ativos) | R/W | R/W | R | sem acesso | sem acesso | sem acesso |

- Único permission set custom (sem namespace) que concede Read em Case: `Modify_All`.
- **Achado:** o público comercial ativo (`Comercial - Analista`) **não lê Case**. Para eles, a categoria "Ocorrências" sempre virá como "sem acesso". Não existe hoje perfil de "atendimento" com usuário ativo nesta sandbox.

## 4. Automação nos objetos-alvo (para avaliar conflito)

A demanda é **somente leitura**: nenhuma das automações abaixo dispara por consulta. Ficam registradas para provar que não há conflito de ordem de execução.

- **Triggers custom** (do assessment, não revalidados linha a linha): `AccountTrigger`, `OpportunityTrigger`, `OrderTrigger`, além dos triggers do CPQ (`SBQQ`) nos mesmos objetos.
- **Flows custom** (`SELECT ApiName, ProcessType, TriggerType, ... FROM FlowDefinitionView WHERE NamespacePrefix = null`, 25 no total):
  - Account: `AccountTriggered` (AfterSave, ativo), `UpdateParentAccountUsedLimit` (AfterSave, ativo), `AccountUpdateEconomicGroup` (Scheduled, ativo), `Account` (Scheduled, inativo)
  - Opportunity: `Oportunidade_Industria`, `OpportunityFlow` (AfterSave, ativos), `ScheduledFlowOpportunity` (Scheduled)
  - Order: `Order` (AfterSave), `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` (BeforeSave), `OrderScheduledFlow` (Scheduled)
  - Contact e Case: **nenhum Flow custom**
- **Classes Apex custom:** 54, todas com API entre v58 e v64. Não existe nenhuma classe de consulta/seletor reutilizável para "resumo de conta" (`AccountUtility`, `OrderUtility` e afins são ligadas a trigger/integração Protheus). Nenhuma será alterada.
- **Validation Rules:** só disparam em DML, então são irrelevantes para esta demanda (assessment registra 23 em Order).

## 5. Volume e escala
- Sandbox vazia: 0 registros em todos os objetos-alvo. **Volume por cliente em produção é desconhecido** e não foi (nem deve ser) consultado. A3/P7 ficam abertas.

## 6. O que não pôde ser confirmado (declarado, não presumido)
1. Se o Agentforce para funcionários está ligado no Setup e se há ações padrão disponíveis no catálogo do Agent Builder.
2. Se o Data Cloud está configurado (pré-requisito de plataforma do Agentforce). Só a licença foi confirmada.
3. Qual permission set concede ao usuário final **o uso** de um agente de funcionário nesta org. Os PS encontrados são de Service Agent, Coworker e Prompt Template. Nenhum foi identificado inequivocamente como "usar agente de funcionário".
4. Configuração de mascaramento de dados do Einstein Trust Layer. Não foi encontrado no `EinsteinGpt.settings` retornado.
5. Modelo de consumo (créditos/requests) contratado pela Eplast.
6. Se Case e/ou `SalesReturn__c` são usados em produção e qual dos dois é "ocorrência" para o negócio.
7. FLS campo a campo nos perfis. Só a permissão de objeto foi levantada. A FLS será tratada em tempo de execução (ver design).
