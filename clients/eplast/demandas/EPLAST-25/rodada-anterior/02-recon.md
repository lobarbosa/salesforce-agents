# EPLAST-25 — Recon da org

**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`) · `Organization.IsSandbox = true` · Enterprise Edition · API 68.0
**Data da coleta:** 2026-11-11 · **Validade:** 7 dias (vence em 2026-11-18, antes da semana 9)
**Modo:** só leitura. Metadata e contagens agregadas. Nenhum registro de negócio ou de usuário foi lido (guardrail #2). Nada foi retrieved para `force-app/`.

Única org conectada no runner: `sbx-eplast-dev`. **`sbx-eplast-qa` não está conectada nesta sessão**, então não houve comparação dev × qa.

---

## 1. Identidade da org (achado #6 do assessment, reconfirmado)

| Item | Resultado | Comando |
|---|---|---|
| Alias conectado | só `sbx-eplast-dev` | `sf org list` |
| Instância | `eplast--qa.sandbox.my.salesforce.com` | `sf org display --target-org sbx-eplast-dev` |
| É sandbox? | `IsSandbox = true` | `SELECT IsSandbox, OrganizationType FROM Organization` |

O alias de dev segue apontando para uma sandbox cujo nome de instância é "qa". Não existe outra org conectada para provar que dev e qa são ambientes distintos. **Achado #6 continua aberto e bloqueia qualquer build ou homologação desta demanda em sandbox.**

## 2. Correção do que a análise registrou sobre relatórios e Agentforce

A análise (seção 6, Q10) registrou `Report`, `Dashboard` e `GenAiPlugin` como vazios. Dois desses resultados eram artefato do comando, não da org:

- `sf org list metadata --metadata-type Report|Dashboard` sem `--folder` devolve 0 para esses tipos, que são organizados por pasta. Reproduzido nesta sessão: 0 pelo `list metadata`, e **374 relatórios e 19 painéis** por `SELECT COUNT() FROM Report` / `Dashboard`.
- `GenAiPlugin` está de fato vazio, mas o Agentforce existe na org por outros tipos de metadata (seção 3).

## 3. Agentforce e IA

| Item | Resultado | Comando |
|---|---|---|
| `Bot` / `BotDefinition` | 1: `SFAgent2`, `Type = InternalCopilot`, `AgentType = AgentforceEmployeeAgent`, criado em 2026-11-10 | `sf org list metadata --metadata-type Bot`; `SELECT ... FROM BotDefinition` |
| `BotVersion` | 4 versões (1 a 4), **todas `Inactive`** | `SELECT BotDefinition.DeveloperName, VersionNumber, Status FROM BotVersion` |
| `GenAiPlannerBundle` | 4: `SFAgent2_v1` a `SFAgent2_v4` | `sf org list metadata --metadata-type GenAiPlannerBundle` |
| `GenAiPlugin`, `GenAiFunction`, `GenAiPromptTemplate` | 0 cada | `sf org list metadata` |
| Entidades de IA consultáveis | `AiAgent`, `AIAgentStatusEvent`, `GenAiPlannerDefinition`, `GenAiPluginDefinition`, `GenAiFunctionDefinition` e correlatas | `SELECT QualifiedApiName FROM EntityDefinition WHERE ...` |
| `DataSpace` | 1 | `SELECT COUNT() FROM DataSpace` |
| Licenças de IA (PSL) | 23 ativas, entre elas `Agentforce Coworker`, `Einstein Prompt Templates`, `Data Cloud`, `Agentforce Sales Coach`, `Einstein Conversation Insights Standard`, `Standard Einstein Activity Capture User` (14 usadas de 100). As demais com 0 usadas | `SELECT ... FROM PermissionSetLicense WHERE ...` |
| Permission set custom ligado a agente | `PS_Comercial_ResumoClienteAgente` (custom, sem namespace) | `SELECT ... FROM PermissionSet WHERE ...` |

Leitura:
- Na sandbox há **um** agente de colaborador, sem versão ativa. Não dá para atribuir esse agente ao `eplast-ent-09` ou ao `eplast-ent-10`, que o contrato registra como construídos fora da esteira. O nome não diz qual é.
- Não confirmei se o rastreamento de sessão de agente (Agentforce analytics) está ligado. Esse recurso depende de Data Cloud. A presença de 1 `DataSpace` e da PSL `Data Cloud` é só indício de que o Data Cloud foi provisionado, não prova de que a telemetria de agente está ativa. Mesmo se estiver, a telemetria que vale para a medição é a de **produção**, que o agente não consulta (guardrail #1).
- Contagem de `PermissionSetAssignment` agregada para `PS_Comercial_ResumoClienteAgente`, `UseSetupWithAgentforce`, `AgentPlatformBuilder`, `EinsteinGPTPromptTemplateUser` e `AgentforceDeveloperAndAdminTools`: **0** em todos. Ninguém nesta sandbox tem acesso atribuído ao agente pelos conjuntos custom ou padrão consultados.

## 4. Relatórios, painéis e tipos de relatório

| Item | Resultado | Comando |
|---|---|---|
| Relatórios | 374 | `SELECT COUNT() FROM Report` |
| Painéis | 19 (16 `SpecifiedUser`, 3 `LoggedInUser`) | `SELECT DeveloperName, Title, FolderName, Type FROM Dashboard` |
| Painéis do cliente (pasta `Eplast`) | `Pedidos`, `Leads & Oportunidades` (ambos `SpecifiedUser`) | idem |
| Painéis padrão potencialmente úteis | `AdoptionDashboard` ("Adoption Dashboard"), `NonA360EacDashboard` ("Activities Dashboard"), `sfdw_..._Digital_Wallet_Consumption_Insights_By_Tags` (consumo de créditos) | idem |
| Relatórios do comercial | pastas `ANALISTAS` e `Geral`: carteira por região, clientes recorrentes, fechado/perdido, efetividade, média de dias para fechamento, OTIF, entre outros | `SELECT DeveloperName, Name, FolderName FROM Report WHERE ...` (só nome e pasta) |
| Tipos de relatório custom | 33, entre eles `AP_User_Activities_2024_07_02`, `AP_Opportunities_with_Activities_2024_07_02`, `AP_Accounts_with_Activities_2024_07_02`, `Oportunidades_com_tend_ncia_do_hist_rico`, `GestaoDeVisitas`, `Pedidos_customizados` | `sf org list metadata --metadata-type ReportType` |
| `EventLogFile` (Event Monitoring) | 0 | `SELECT COUNT() FROM EventLogFile` |

Não abri a definição de nenhum relatório (filtros, colunas, agrupamentos). A lista acima diz o que existe, não o que cada relatório mede. Se algum indicador do baseline (Q2) bater com um desses relatórios, a reutilização precisa ser confirmada no build, abrindo a definição em `/tmp/recon`.

Sem Event Monitoring (0 `EventLogFile`), não há trilha nativa de uso por usuário nesta sandbox além de LoginHistory e dos dados de atividade.

## 5. Automação nos objetos que a medição poderia tocar

Só importa se a medição **gravar** dado (cenário C do design). Leitura não dispara nada disso.

Triggers custom ativos (`SELECT Name, TableEnumOrId, Status, ApiVersion FROM ApexTrigger WHERE NamespacePrefix = null`, Tooling):

| Trigger | Objeto | API |
|---|---|---|
| `AccountTrigger` | Account | 58 |
| `OpportunityTrigger` | Opportunity | 59 |
| `OrderTrigger` | Order | 59 |

Flows record-triggered custom ativos nos mesmos objetos (`FlowDefinitionView`, `NamespacePrefix = null`, `IsActive = true`):

| Objeto | Flows | Evento |
|---|---|---|
| Account | `AccountTriggered`, `UpdateParentAccountUsedLimit` | after save, create e update |
| Opportunity | `OpportunityFlow` (create e update), `Oportunidade_Industria` (update) | after save |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` (before save), `Order` (after save) | create e update |
| Task | `TaskCreatedOrUpdated` | after save, create e update |

Somam-se as triggers do CPQ (namespace `SBQQ`) nos mesmos objetos, já registradas no assessment (achado #1) e não reconsultadas uma a uma aqui. Também há Flows agendados em Account, Opportunity e Order (`AccountUpdateEconomicGroup`, `ScheduledFlowOpportunity`, `OrderScheduledFlow`).

**User:** nenhum trigger custom e nenhum Flow record-triggered custom ativo. Os 40 campos custom de `User` retornados pela Tooling são todos de pacotes (Marketing Cloud Connect, Maps, CPQ e outros) ou de integração (`ProtheusSellerId`). Não há campo que marque "usuário do piloto".

**Objetos custom próprios:** `Branch__c`, `EconomicGroup__c`, `FormPayment__c`, `In_App_Checklist_Settings__c`, `IntegrationLog__c`, `PaymentTerms__c`, `RelationshipAccountsPaymentTerm__c`, `SalesReturn__c`, `ShippingCompany__c`, `TypeOperation__c`. Nenhum guarda indicador, medição ou uso de IA.

## 6. Usuários (só contagem agregada)

`SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive = true AND UserType = 'Standard' GROUP BY Profile.Name`:

| Perfil | Ativos |
|---|---|
| Administrador do sistema | 9 |
| Comercial - Analista | 4 |
| Financeiro | 1 |
| Perfis de integração (5 perfis) | 1 cada |

É a sandbox, não produção. Não diz nada sobre quem são os 10 usuários do piloto (Q4).

## 7. Repositório

`clients/eplast/force-app` tem só o baseline retrieve (`eplast: baseline retrieve (#88)`). Nenhum componente ligado ao piloto de IA, a medição ou a Agentforce está versionado.

## 8. O que não foi verificado

- Definição (filtros e colunas) dos relatórios e painéis existentes.
- Se o rastreamento de sessão do Agentforce está ligado, e em que org rodam os agentes do piloto (Q10).
- OWD e regras de compartilhamento (também ausentes do assessment).
- Metadata da `sbx-eplast-qa`: não conectada nesta sessão.
- Qualquer dado de produção: proibido ao agente (guardrail #1).
