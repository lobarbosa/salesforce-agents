# EPLAST-28 — Recon da org

**Data da coleta:** 2026-11-10 · **Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`), API v68.0
**Confirmação de ambiente:** `Organization.IsSandbox = true`, Enterprise Edition. Leitura apenas: nenhuma escrita,
nenhum DML, nenhum deploy. Retrieves feitos em `/tmp/recon28`, fora de `force-app/`.
**Dados:** só metadata e contagens agregadas (guardrail #2). Nenhum registro de cliente lido.

Recon de mais de 7 dias está vencido. Se o build começar depois de 2026-11-17, refaça.

---

## 1. Ambiente

| Item | Resultado | Comando |
|---|---|---|
| Orgs conectadas nesta sessão | só `sbx-eplast-dev`. `sbx-eplast-qa` **não está conectada** | `sf org list` |
| Tipo | Sandbox, Enterprise Edition | `SELECT IsSandbox, OrganizationType FROM Organization` |
| Identidade da sandbox | a URL da instância continua se identificando como "qa" (achado 6 do assessment segue válido) | `sf org display` |

Sem a sandbox de QA conectada, não deu para comparar metadata dev × QA (validation rules, Flows).
Isso fica como pendência de pré-build (ver design, risco R6).

## 2. Opportunity: campos candidatos a referência de "parada"

Todos confirmados com `sf sobject describe --sobject Opportunity`. São campos padrão e somente leitura;
nenhum precisa ser criado para a forma base da solução.

| Campo | Tipo | Filtrável | Uso possível |
|---|---|---|---|
| `LastActivityDate` | date | sim | "sem atividade há N dias" |
| `LastStageChangeDate` | datetime | sim | "sem mudar de estágio há N dias" |
| `LastStageChangeInDays` | int | sim | idem, já em dias |
| `LastModifiedDate` | datetime | sim | **não recomendado**: Flows e integração gravam em Opportunity (ver seção 4) |
| `AgeInDays` | int | sim | idade da oportunidade |
| `IsClosed` | boolean | sim | excluir fechadas |
| `OwnerId` | reference | sim | destinatário |
| `StageName` | picklist | sim | prazo por estágio, se for o caso |
| `RecordTypeId` | reference | sim | prazo por record type, se for o caso |
| `HasOpenActivity`, `HasOverdueTask` | boolean | **não** | não servem como filtro de Flow agendado nem de SOQL |

- Opportunity tem 77 campos, 28 custom. Nenhum campo custom tem papel de "data do último acompanhamento".
- Record Types de Opportunity: `Sample`, `Bonus`, `Industria`, `Sale`, `SellWithShipping`, `Mestre` (6).
- Estágios ativos (`OpportunityStage`): 11 abertos (`Qualificação` até `Negociação Comercial`) e 2 fechados
  (`Fechado/Ganho` ganho, `Fechado/Perdido` perdido).

## 3. Triggers nos objetos tocados ou vizinhos

`SELECT ... FROM ApexTrigger` (Tooling), filtrado por Opportunity, Task, Event, OpportunityLineItem, User.

| Trigger | Namespace | Objeto | Eventos |
|---|---|---|---|
| `OpportunityTrigger` | (custom) | Opportunity | after insert, after update. Delega a `OpportunityTriggerHandler`, respeita `TriggerUtility.bypassTrigger`, e em after update não roda em contexto Queueable |
| `OpportunityBefore` | SBQQ | Opportunity | before insert, before update, before delete |
| `OpportunityAfter` | SBQQ | Opportunity | after insert, after update |
| `OpportunityLineItemTrigger` | SBQQ | OpportunityLineItem | todos |
| `AdvRouteEvents` | maps | Event | todos |

Não há trigger em Task. Classes custom confirmadas na org: `OpportunityTriggerHandler`, `OpportunityTriggerHelper`,
`TriggerUtility`, `Logger` (todas em API 59). Custom Metadata `TriggerUtility__mdt` existe com o campo
`BypassTrigger__c`.

## 4. Flows ativos que tocam Opportunity ou Task

`SELECT ... FROM FlowDefinitionView WHERE IsActive = true AND NamespacePrefix = null`, seguido de retrieve dos
relevantes.

| Flow | Tipo | Objeto / evento | O que faz que importa aqui |
|---|---|---|---|
| `OpportunityFlow` | RecordAfterSave | Opportunity, create+update, **sem critério de entrada** | lê Account, Quote, QuoteLineItem; **atualiza a própria Opportunity**; cria Quote, Order, OrderItem e **cria Task** (`CreateTask`); chama a ação Apex `CreateQuoteCPQController`; submete aprovação |
| `Oportunidade_Industria` | RecordAfterSave | Opportunity, update, filtro `NomeTipoRegistro__c = Industria` | **cria até 5 Tasks automáticas** (Amostra, Cotação/Negociação x2, Execução técnica, Precificação), com lembrete; duas delas têm `OwnerId` fixo no Flow; chama a ação Apex `FlowOpportunityController` |
| `ScheduledFlowOpportunity` | **Scheduled** (diário) | Opportunity com `IsWon = true` | já existe um Flow agendado em Opportunity. Só lê Opportunity e grava em Account (`LastMonthPurchaseValue__c`, `Ranking__c`). Não grava em Opportunity |
| `TaskCreatedOrUpdated` | RecordAfterSave | Task, create+update, **sem critério de entrada** | atualiza a Account do `WhatId` (`AccountHasCheckInTask__c = true`). Roda em **toda** Task criada ou alterada |

Outros Flows agendados custom ativos (não tocam Opportunity): `AccountUpdateEconomicGroup`, `CreationPriceBook`,
`Logs_Delete_Records`, `OrderScheduledFlow`.

### 4.1 O que isso muda para a demanda

1. **Gravar em Opportunity entra numa cadeia já concorrida:** `OpportunityBefore` (SBQQ), `OpportunityTrigger`,
   `OpportunityAfter` (SBQQ), `OpportunityFlow` (sem critério de entrada, e que regrava a própria Opportunity) e
   `Oportunidade_Industria`. A foto do achado 1 do assessment continua valendo.
2. **Tasks automáticas contaminam "acompanhamento".** `Oportunidade_Industria` e `OpportunityFlow` criam Tasks
   por regra, não por ação do vendedor. Se "acompanhamento" for qualquer atividade, essas Tasks podem zerar a
   contagem de parada sem que ninguém tenha falado com o cliente. O efeito exato sobre `LastActivityDate`
   depende da data e do status da Task. Precisa ser medido em teste na sandbox, não suposto.
3. **Criar Task como ação do alerta dispara `TaskCreatedOrUpdated`**, que atualiza Account e com isso aciona a
   cadeia de Account do achado 1 (`AccountTrigger`, `AccountBefore` do SBQQ, `AccountTriggered`,
   `UpdateParentAccountUsedLimit`). Além disso, a Task nova realimenta o próprio critério de parada.
4. `LastModifiedDate` não mede acompanhamento: `OpportunityFlow` e a integração gravam na Opportunity.

## 5. Notificações, agentes e recursos de plataforma relacionados

| Item | Resultado | Comando |
|---|---|---|
| Custom Notification Types | 1: `Novo_Pedido` (desktop e mobile, sem Slack). Nenhum para oportunidade | retrieve `CustomNotificationType` |
| Agente Agentforce `SFAgent2` | existe, **4 versões, todas `Inactive`** | `sf org list metadata --metadata-type Bot`; `SELECT ... FROM BotVersion` |
| Tópico do `SFAgent2_v4` | "Insights Comerciais e Acompanhamento". A descrição diz que "identifica oportunidades paradas, pedidos pendentes e sinais de risco na carteira do vendedor". Ações locais: `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta` | retrieve `GenAiPlannerBundle` |
| Flows `agentic_feed` | `Custom_Stale_Opp` ("Create Custom Recommendations"), `Custom_Stale_Opp_Action`, `Custom_Rcmd_Cleanup`: agendados, **templates (`IsTemplate = true`), inativos**, `ManageableState = installed`. Não aparecem como pacote instalado (`sf package installed list`) e o retrieve do Flow falhou ("cannot be found"). O conteúdo não foi lido | `FlowDefinitionView WHERE NamespacePrefix = 'agentic_feed'` |
| Pacotes instalados relevantes | SBQQ (CPQ), et4ae5 (Marketing Cloud), MCCA5PROD, maps, OIQ (Sales Insights), entre outros | `sf package installed list` |

O que o agente `SFAgent2` faz é **consulta sob demanda** (o vendedor pergunta). O que a EPLAST-28 pede é **alerta
proativo** (o sistema avisa). Os dois se sobrepõem no conceito de "oportunidade parada", e o histórico já registrou
isso no design de EPLAST-27 (`[demandas/EPLAST-27/03-design.md]`). Confirmado na org nesta coleta.

## 6. Validation rules (para fixture de teste)

Opportunity tem **16 validation rules ativas**: `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`,
`CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`,
`CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`,
`CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`,
`Industria_Fase_Cotacao_Sem_Catalogo`. Task tem 0.

Uma solução somente-leitura não esbarra nelas em produção. O **teste**, porém, precisa criar Opportunity, e a
fixture precisa satisfazer as 16 (inclusive as que exigem dados na Account e no dono da Account).

## 7. Volume e escala (agregados)

| Métrica | Valor | Observação |
|---|---|---|
| Opportunity (total / abertas) | 0 / 0 | sandbox vazia; **volume de produção desconhecido** e não deve ser consultado |
| Task / Event | 0 / 0 | idem |
| Usuários ativos | 22 | |
| Usuários ativos com `ManagerId` preenchido | **0** | hierarquia de gestor não existe nesta sandbox |
| Usuários ativos com papel (Role) / papéis existentes | 2 / 2 | hierarquia de papéis quase vazia |
| Jobs agendados (`CronTrigger`) | 7, nenhum de Apex agendado (`JobType = 7`) | |

## 8. O que não foi possível confirmar

- Volume de oportunidades abertas e de donos em produção (proibido consultar).
- Metadata da sandbox de QA (alias não conectado nesta sessão).
- O comportamento exato dos templates `agentic_feed` (não deu para fazer retrieve) e se a licença permite ativá-los.
- O efeito das Tasks automáticas sobre `LastActivityDate`. Vai para o roteiro de teste.
- Se o entregável `eplast-ent-09` vai ganhar alguma forma de push no agente (está fora da esteira).
