# EPLAST-28 — Recon da org (alertas de oportunidade parada)

**Data:** 2026-11-15
**Org conectada (`sf org list`):** `sbx-eplast-dev`, Sandbox, Connected, Org Id `00DHa000006vfMLMAY`
**Instância (`sf org display --json`):** `https://eplast--qa.sandbox.my.salesforce.com`, API 68.0
**Atenção:** o alias de dev aponta para uma instância cujo nome é `eplast--qa`. A análise já registrava isso (achado 6 do assessment). Não consegui provar que dev e QA são sandboxes distintas (ver lacunas).
**Escopo da leitura:** só metadata e contagens (`COUNT()`). Nenhuma escrita. Nenhum registro lido.

## 1. O que já cobre o pedido

| Item | Tipo | Evidência | O que faz hoje |
|---|---|---|---|
| `Neglected Open Opportunities` | Relatório | `sf data query -q "SELECT Name FROM Report WHERE Name LIKE '%Opp%' OR ... LIMIT 10"` (retornou 10, no teto do LIMIT) | Pelo nome, lista oportunidades abertas negligenciadas. **Filtros e colunas não lidos**. Provável relatório padrão da Salesforce. É relatório, não alerta: não notifica ninguém. |
| `Activities Logged on Opportunities` | Relatório | mesma consulta | Pelo nome, atividades registradas em oportunidades. Filtros não lidos. |
| `ES: Open Opportunities`, `ES: FYTD Open Opportunities by Acct` | Relatórios | mesma consulta | Oportunidades abertas. Filtros não lidos. |
| Painéis com "Opp" ou "Oportunidade" no título | Dashboard | `SELECT COUNT() FROM Dashboard WHERE Title LIKE '%Opp%' OR Title LIKE '%Oportunidade%'` = 1 | Existe 1 painel. Título e conteúdo não lidos. |
| Flows `agentic_feed` (`Custom_Stale_Opp`, `Custom_Stale_Opp_Action`, `Custom_Rcmd_Cleanup`) | Flow | `SELECT COUNT() FROM FlowDefinition WHERE NamespacePrefix='agentic_feed'` (Tooling) = 0 | **Não existem na dev.** A rodada anterior os registrou; não consegui reconfirmar. Não os trate como existentes. Falta checar a QA. |
| `SFAgent2` | `GenAiPlannerDefinition` | `SELECT DeveloperName, MasterLabel FROM GenAiPlannerDefinition` (Tooling) | Existe como `SFAgent2_v1` a `SFAgent2_v4`. |
| Tópicos de agente | `GenAiPluginDefinition` | `SELECT DeveloperName, MasterLabel FROM GenAiPluginDefinition LIMIT 20` (Tooling) | Há rótulos `Insights Comerciais e Acompanhamento` (2 registros) e `Insights Comerciais sobre Pedidos` (2), além de Agent Router, Ambiguous Question, Off Topic e General FAQ. **Não consegui ligar cada tópico à versão do SFAgent2**, nem ler instruções ou ações. O rótulo "Acompanhamento" sugere sobreposição conceitual com o pedido. |
| Ações de agente | `GenAiFunctionDefinition` | `SELECT DeveloperName, MasterLabel FROM GenAiFunctionDefinition LIMIT 20` (Tooling) | Há `ConsultarPedidos`, `AgregacaoPedidos` e `IdentificarConta` em várias versões, e `QueryRecords`. Nenhuma ação nomeada para oportunidade. |
| Notificação interna | `CustomNotificationType` | `SELECT DeveloperName, CustomNotifTypeName FROM CustomNotificationType` (Tooling) | Existe 1 tipo: `Novo_Pedido`. Nenhum tipo de alerta de oportunidade. |
| Tipo de notificação para oportunidade parada | n/a | mesma consulta | Não existe. Seria componente novo. |

## 2. O que será tocado (leitura)

| Objeto.campo | Evidência | Observação |
|---|---|---|
| `Opportunity.LastActivityDate` | `sf sobject describe -s Opportunity` | Campo padrão, existe. |
| `Opportunity.LastStageChangeDate` | idem | Campo padrão, existe. |
| `Opportunity.IsClosed`, `StageName`, `OwnerId`, `CreatedDate`, `AccountId` | idem | Campos padrão, existem. |
| `Opportunity.CampaignId`, `LeadSource` | idem | Existem. Não são usados pelo alerta. |
| `Task` | contagem | Alimenta `LastActivityDate`. |

Não foi criado nem proposto nenhum campo custom. O tipo, a descrição e a obrigatoriedade dos campos acima não foram lidos, porque são padrão.

## 3. Automação concorrente

| Componente | Objeto | Estado confirmado | Evidência | O que faz hoje |
|---|---|---|---|---|
| `OpportunityTrigger` (custom) | Opportunity | `Status=Active`, **`IsValid=false`** | `SELECT Name, TableEnumOrId, IsValid, Status, NamespacePrefix FROM ApexTrigger WHERE TableEnumOrId IN ('Opportunity','Task')` (Tooling) | Chama `OpportunityTriggerHandler` e `OpportunityTriggerHelper` (classes existem, ver abaixo). Com `IsValid=false` pode não estar compilando. Não li o código. |
| `OpportunityBefore` (SBQQ) | Opportunity | Active, IsValid=true | mesma consulta | Trigger do pacote CPQ. |
| `OpportunityAfter` (SBQQ) | Opportunity | Active, **IsValid=false** | mesma consulta | Trigger do pacote CPQ. Inválido também. |
| Triggers em Task | Task | Nenhum retornou | mesma consulta | Sem trigger Apex em Task, só Flow. |
| `OpportunityFlow` | Opportunity | Ativo, v2, AutoLaunched | `SELECT Definition.DeveloperName, ProcessType, VersionNumber FROM Flow WHERE Status='Active' AND Definition.DeveloperName IN (...)` (Tooling) | Cria Task (segundo a rodada anterior; não reli o corpo). |
| `Oportunidade_Industria` | Opportunity | Ativo, v1, AutoLaunched | idem | Cria Tasks automáticas (segundo a rodada anterior; não reli o corpo). |
| `ScheduledFlowOpportunity` | Opportunity | Ativo, v2, AutoLaunched | idem | Agendado, lê Opportunity e grava em Account (segundo a rodada anterior; não reli o corpo). |
| `TaskCreatedOrUpdated` | Task | Ativo, v1, AutoLaunched | idem | Atualiza Account a cada Task (segundo a rodada anterior; não reli o corpo). |
| `PaymentTermsOpportunity` | Opportunity | Ativo, v1, tipo `Flow` (tela) | idem | Fluxo de tela. |
| `Opportunity_PromptFlow_DadosOportunidade`, `Opportunity_PromptFlow_CotacaoPrimaria` | Opportunity | Têm versão ativa | `SELECT DeveloperName, ActiveVersionId FROM FlowDefinition WHERE DeveloperName LIKE '%Opp%' ...` (Tooling) | Pelo nome, prompt flows (IA). Finalidade não lida. |
| `FlowOpportunityController` e `FlowOpportunityControllerTest` | ApexClass | Existem | `SELECT Name FROM ApexClass WHERE NamespacePrefix=null AND (Name LIKE '%Opportunity%' ...)` (Tooling) | Finalidade não lida. |
| `OpportunityTriggerHandler`, `OpportunityTriggerHelper` | ApexClass | Existem | idem | Lógica do trigger custom. Não lida. |

**Ordem de execução:** o alerta proposto não grava em Opportunity, Account, Order nem Task. Por isso a ordem de execução entre trigger custom, SBQQ e Flows não é exercitada pelo alerta. **Não mapeei a ordem relativa entre eles**: não li o corpo dos Flows nem das classes. Se o design gravar em qualquer um desses objetos, esse mapa precisa ser feito antes.

Validation rules de Opportunity (16, todas ativas): `SELECT ValidationName, Active FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Opportunity' LIMIT 40` (Tooling). Nomes: `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`. Elas barram a criação de Opportunity de teste, não o alerta.

## 4. Marketing Cloud Connect (`et4ae5`)

| Item | Evidência | Achado |
|---|---|---|
| Pacote instalado | `SELECT SubscriberPackage.NamespacePrefix, SubscriberPackage.Name FROM InstalledSubscriberPackage` (Tooling) | `et4ae5` ("Marketing Cloud") e `MCCA5PROD` ("MarketingCloudConnectedApp") instalados. |
| Classes | `SELECT COUNT() FROM ApexClass WHERE NamespacePrefix='et4ae5'` | 523. |
| Objetos | `SELECT COUNT() FROM CustomObject WHERE NamespacePrefix='et4ae5'` | 28. |
| Objetos vistos | `SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName LIKE 'et4ae5%' LIMIT 20` | `AggregateLink__c`, `Automated_Send__c`, `Business_Unit__c`, `Campaign_Member_Configuration__c`, `Configuration__c`. A consulta parou no LIMIT 20, então a lista é parcial. |

O alerta de EPLAST-28 é interno e fica fora de marketing, então a demanda não usa nenhum objeto do `et4ae5`. Não li uso de campos do conector em Opportunity. Não toquei nada no Marketing Cloud.

## 5. Volume e dados de teste

| Objeto | Contagem na dev | Comando |
|---|---|---|
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |
| Opportunity abertas | 0 | `... WHERE IsClosed = false` |
| Task | 0 | `SELECT COUNT() FROM Task` |
| Campaign / CampaignMember / Lead | 0 / 0 / 0 | `SELECT COUNT() FROM <objeto>` |
| User ativos | 22 | `SELECT COUNT() FROM User WHERE IsActive=true` |

A dev não tem dado para testar o alerta. O teste precisa de carga sintética, respeitando as 16 validation rules de Opportunity. Existem 7 jobs agendados em estado WAITING/EXECUTING (`SELECT COUNT() FROM CronTrigger WHERE State IN ('WAITING','EXECUTING')`); não identifiquei quais.

## 6. Permissões

Não consultei perfis, permission sets nem OWD. Para a notificação interna, o destinatário precisa ter acesso ao tipo de notificação (permission set ou perfil) e acesso de leitura ao registro; isso fica para o design.

## O que não consegui confirmar

- **Flows `agentic_feed`**: 0 na dev. Não sei se existem só na QA ou se foram removidos. Não consultei a QA, porque ela não está conectada nesta sessão.
- **Dev e QA distintas**: a instância do alias de dev se chama `eplast--qa`. Org Id da dev conhecido; o da QA só vem do histórico (EPLAST-31) e não foi reconferido.
- **Corpo dos Flows e das classes de Opportunity/Task**: não li. Descrições da coluna "o que faz" que citam a rodada anterior não foram reconfirmadas.
- **Ordem de execução** entre `OpportunityTrigger`, triggers SBQQ e Flows: não mapeada. `OpportunityTrigger` e `OpportunityAfter` estão `IsValid=false`; não sei se isso significa inativo na prática ou erro de compilação.
- **Tópicos e ações do SFAgent2**: os rótulos existem, mas não os vinculei à versão do agente nem li as instruções. Não confirmei se algum tópico já faz alerta ou resumo de oportunidade parada; também não encontrei `eplast-ent-09` na org.
- **Relatório `Neglected Open Opportunities`**: filtros e colunas não lidos. A consulta de relatórios parou no LIMIT 10, então podem existir outros.
- **Painel** que casou com "Opp/Oportunidade": título e componentes não lidos.
- **Permissões e OWD**: não consultados.
- **Jobs agendados** (7): não identificados.

## Complemento do arquiteto (2026-11-15, `sbx-eplast-dev`, só metadata e contagens)

| Ponto | Evidência | Achado |
|---|---|---|
| Tópico "Insights Comerciais e Acompanhamento" | `SELECT DeveloperName, Description FROM GenAiPluginDefinition WHERE MasterLabel LIKE '%Acompanhamento%'` (Tooling) | 2 registros. A descrição diz que o tópico "identifica oportunidades paradas" sob demanda. A instrução lida (`GenAiPluginInstructionDef`, 1 registro) só injeta contexto de página; não define prazo nem critério de "parada". |
| Parâmetros por CMDT (precedente) | `SELECT DeveloperName, Description FROM CustomObject WHERE NamespacePrefix = null ...` (Tooling) | Existe `ScheduledFlowOpportunitySetting` (EPLAST-47, registro Default) e `TriggerUtility`. Nenhum CMDT de alerta de oportunidade. |
| Log de automação (precedente) | idem; `FieldDefinition` de `IntegrationLog__c` | `IntegrationLog__c` ("Log de Integração") existe, com `IntegrationAction__c`, `ResponseStatus__c`, `ExecutionDate__c`, `RequestBody__c` (texto). `ScheduledFlowOpportunity` v2 grava nele as falhas (descrição do Flow). 0 registros na dev. |
| Automação em `IntegrationLog__c` | `ApexTrigger WHERE TableEnumOrId='IntegrationLog__c'`; `FlowDefinitionView WHERE IsActive = true AND TriggerObjectOrEventId = 'IntegrationLog__c'` | 0 triggers e 0 Flows disparados por gravação. |
| Jobs agendados (Flow) | `SELECT CronJobDetail.Name, CronExpression FROM CronTrigger WHERE CronJobDetail.JobType='6'` | `Logs_Delete_Records` 02:00, `OrderScheduledFlow` 06:00, `ScheduledFlowOpportunity` 15:47, `CreationPriceBook` 17:36 (horário da org). |
| Tipos de data em Opportunity | `FieldDefinition` | `LastActivityDate` Data; `LastStageChangeDate` e `CreatedDate` Data/Hora. |
| Usuários | `COUNT()` em User | 0 ativos com `ManagerId`; 25 inativos. |
