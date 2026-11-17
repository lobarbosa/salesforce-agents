# EPLAST-28 — Recon da org (redesenho com as respostas do cliente de 2026-11-17)

**Data:** 2026-11-17
**Org (`sf org list`):** alias `sbx-eplast-dev`, Sandbox, Connected, Org Id `00DHa000006vfMLMAY`. É a sandbox "QA" da Eplast (`eplast--qa`), dev da esteira (regra 5 da conta; não é risco).
**Escopo:** só metadata e contagens. Nenhuma escrita na org. Retrieve de 5 Flows para pasta temporária, descartada. Marketing Cloud não consultado nem tocado.
**Substitui** o recon de 2026-11-15 (preservado em `rodada-anterior/02-recon.md`). Só reconfirmei o que o redesenho precisa; o resto vale como estava.

## 1. O que já cobre o pedido (reaproveitar)

A rodada anterior já construiu o alerta, e ele está na dev. O redesenho é ajuste, não criação.

| Componente | Estado na dev | Comando que provou |
|---|---|---|
| Flow `Opportunity_Scheduled_AlertaParada` | v1 **Active**, v2 **Draft** (AutoLaunched, agendado). Job `Opportunity_Scheduled_AlertaParada-1`, cron `0 0 7 ? * * *`, WAITING. | `SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName LIKE '%AlertaParada%'` (Tooling); `SELECT CronJobDetail.Name, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name LIKE '%AlertaParada%'` |
| CMDT `AlertaOportunidadeParadaSetting__mdt` | Existe no repositório (campos `Ativo__c`, `DiasSemAcompanhamento__c`, `RegraParada__c`, `NotificarGestor__c`, `DataCargaInicial__c`). Registro `Default` no repositório. **Não reconferi os valores na org.** | `git ls-files` (repositório); lista de campos não lida na org |
| Notificação `Oportunidade_Parada` | Existe. Descrição "Aviso interno (desktop e mobile) ... EPLAST-28". `Novo_Pedido` é de outro propósito. | `SELECT DeveloperName, Description FROM CustomNotificationType` (Tooling) |
| Lógica de parada na v1 (repositório e org) | Usa `LastActivityDate` (nulo cai para `CreatedDate`) **e** `LastStageChangeDate` (nulo cai para `CreatedDate`). É a parte que o cliente mandou mudar (estágio não reinicia). | Retrieve do Flow (expressões nas linhas 216 e 228 do XML) |
| `IntegrationLog__c` | Existe (recon anterior). Sem trigger nem Flow disparado por gravação. Não reconferido hoje. | Recon de 2026-11-15 |
| Agente `SFAgent2` e tópico "Insights Comerciais e Acompanhamento" | Existem (recon anterior). A descrição do tópico fala em identificar oportunidades paradas sob demanda, sem prazo nem critério. Não reconferido hoje. A solução não cria agente (regra 3 e CA-10). | Complemento do arquiteto de 2026-11-15 |
| Flows `agentic_feed` (`Custom_Stale_Opp` etc.) | **Não existem na dev**: 0 em `FlowDefinition` com namespace `agentic_feed` e 0 com nome `%Stale%` ou `%Rcmd%`. Pode haver só na QAS; não conectada aqui. | `SELECT COUNT() FROM FlowDefinition WHERE NamespacePrefix='agentic_feed'` (Tooling); `... WHERE DeveloperName LIKE '%Stale%' OR DeveloperName LIKE '%Rcmd%'` |

## 2. O que será tocado

| Item | Achado | Comando |
|---|---|---|
| `Opportunity.LastActivityDate` (Data), `CreatedDate` (Data/Hora), `IsClosed`, `OwnerId` | Existem, padrão | Recon anterior (`FieldDefinition`) |
| `Opportunity.LastStageChangeDate` | Existe. **Sai do critério** pela resposta do cliente. | idem |
| `Task.Status` | Existe. Valor padrão do picklist: `Open`. | `sf sobject describe -s Task` |
| `Task.TaskSubtype`, `Task.IsClosed`, `Task.CreatedById`, `Task.Subject` | Existem | idem |
| `Task.Type` | **Não existe** na org | idem (campo ausente) |
| Campos custom em Task | Só 3 do pacote `maps__` (`maps__BaseObjectId__c`, `maps__LayerId__c`, `maps__WA_AdvRouteWaypoint__c`). **Nenhum marca origem automática.** | `sf sobject describe -s Task` (filtro `custom`) |

### Tarefas automáticas: o que distingue uma tarefa do Flow de uma do vendedor

Retrieve de `Oportunidade_Industria`, `OpportunityFlow`, `TaskCreatedOrUpdated`, lidos por script (campos gravados e `Subject`):

| Flow | Cria Task? | Campos gravados | Subject |
|---|---|---|---|
| `Oportunidade_Industria` | 5 Tasks | `Description`, `IsReminderSet`, `OwnerId`, `Priority`, `ReminderDateTime`, `Subject`, `WhatId` | `Amostra`; `Cotação/Negociação` (2x); `Execução técnica do projeto`; `Precificação` |
| `OpportunityFlow` | 1 Task | `Description`, `Subject`, `WhatId` | Não extraído (valor vem de variável) |
| `TaskCreatedOrUpdated` | Não cria; atualiza `Account.AccountHasCheckInTask__c` quando a Task é criada ou atualizada | n/a | Condição de entrada inclui o texto `Check In @` |

Conclusões para o design, sem decidir:
- Nenhum Flow grava `Type`, `TaskSubtype` nem `Status`. Não há marca de origem. O que existe é o `Subject` (lista fixa de 4 valores em `Oportunidade_Industria`) e o `CreatedById` (usuário de execução do Flow; não confirmei qual usuário aparece como criador). Filtrar por `Subject` ou por `CreatedById` é possível por Flow declarativo (Get Records em Task) mas é frágil: o vendedor pode usar o mesmo assunto, e o Flow pode mudar.
- Essas Tasks nascem sem `Status` informado, logo com o padrão `Open`. Pela documentação padrão do Salesforce, `LastActivityDate` considera tarefa **fechada** e evento passado; isso **não foi provado nesta org** (0 Tasks na dev). Se for verdade, tarefa automática aberta não reinicia o prazo até ser concluída. Medir em QA.
- Cada Task criada dispara `TaskCreatedOrUpdated` e grava em Account (cadeia do `AccountTrigger`/Protheus). Reforça que o alerta não cria Task.
- "Notificações automáticas não reiniciam": a notificação do alerta (`CustomNotification`) não cria Task nem Event, então não toca `LastActivityDate`. Não li outros fluxos de notificação.

## 3. Automação concorrente

Mudança em relação a 2026-11-15: os três triggers de Opportunity agora aparecem **válidos**.

| Componente | Estado | Comando |
|---|---|---|
| `OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter` | Todos `Active` e `IsValid=true` (antes, dois apareciam `IsValid=false`) | `SELECT Name, IsValid, Status FROM ApexTrigger WHERE TableEnumOrId='Opportunity'` (Tooling) |
| Flows `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity`, `TaskCreatedOrUpdated` | Existem e foram retornados no retrieve. `ScheduledFlowOpportunity` alterado em 2026-11-17 pelo usuário da esteira (não investiguei o motivo). | `sf project retrieve start -m Flow:<nome>` |
| Jobs agendados (Flow) | `Logs_Delete_Records` 02:00, `OrderScheduledFlow` 06:00, alerta 07:00, `ScheduledFlowOpportunity` 15:47, `CreationPriceBook` 17:36 | Recon anterior, e `CronTrigger` hoje para o alerta |

**Ordem de execução:** o alerta (inclusive ajustado) lê Opportunity e grava só `IntegrationLog__c` e notificação. Não grava em Opportunity, Account, Order nem Task, então não entra na cadeia `OpportunityTrigger`/SBQQ/Flows. Não mapeei a ordem relativa entre essas automações: nenhuma delas é exercitada pelo alerta. Se o design passar a gravar em Opportunity, o mapa é pré-requisito.
Validation rules de Opportunity (16 ativas) continuam as do recon anterior; só afetam a criação de dado de teste.

## 4. Hierarquia e gestor (limiar de 14 dias)

| Item | Achado | Comando |
|---|---|---|
| Usuários ativos com `ManagerId` | **0** | `SELECT COUNT() FROM User WHERE IsActive=true AND ManagerId != null` |
| `UserRole` | 2 papéis, **0 com `ParentRoleId`** (sem hierarquia de papéis) | `SELECT COUNT() FROM UserRole`; `... WHERE ParentRoleId != null` |
| Usuários ativos com papel | 2 | `SELECT COUNT() FROM User WHERE IsActive=true AND UserRoleId != null` |

Confirma o dito pelo cliente: não há gestor cadastrado. Gestor fica desligado até alguém cadastrar `ManagerId` (ou papéis). A dev não prova o comportamento com gestor real; o teste de gestor precisa de usuário de teste com `ManagerId` ou ficar como limitação.

## 5. Marketing Cloud Connect (`et4ae5`)

Pacote `et4ae5` e `MCCA5PROD` instalados (recon anterior, não repetido). O alerta é notificação interna e não lê nem grava nenhum objeto do conector. Cliente confirmou: sem e-mail nesta etapa. Nada a preparar no Marketing Cloud.

## 6. Volume e dados de teste

| Objeto | Contagem na dev | Comando |
|---|---|---|
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |
| Task | 0 | `SELECT COUNT() FROM Task` |
| Event | 0 | `SELECT COUNT() FROM Event` |

Sem dado para testar na dev; teste exige carga sintética pelos scripts de `fixtures/` (regra 6), respeitando as 16 validation rules. Volume em produção: cliente disse que valida por levantamento fora da esteira; não consultei.

## 7. Permissões

| Item | Achado | Comando |
|---|---|---|
| OWD Opportunity | Interno `Read`, externo `Private` | `SELECT QualifiedApiName, ExternalSharingModel, InternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN ('Opportunity','Task','User')` |
| OWD Task | `Private` (interno e externo) | idem |
| OWD User | Interno `Read` | idem |
| Acesso de leitura a Opportunity | 44 permission sets (não de perfil) e 21 perfis | `SELECT COUNT() FROM PermissionSet WHERE Id IN (SELECT ParentId FROM ObjectPermissions WHERE SobjectType='Opportunity' AND PermissionsRead=true) AND IsOwnedByProfile=<false|true>` |

OWD de Opportunity é `Read` interno, então o link do aviso abre para qualquer usuário interno com perfil que lê Opportunity. Task `Private` importa se o design for ler Task no Flow: o Flow agendado roda no contexto do sistema na maioria dos casos, mas **não confirmei o contexto de execução do Flow agendado nem o acesso a Task**. Não consultei quem tem acesso ao tipo de notificação `Oportunidade_Parada`.

## O que não consegui confirmar

- **Valores do registro `Default` do CMDT na org** (14 dias etc.): não li na org, só o repositório. O build do redesenho altera para 7.
- **Qual usuário aparece como `CreatedById` das Tasks dos Flows** e o `Subject` da Task de `OpportunityFlow`: não extraí. Sem Tasks na dev para observar.
- **Se `LastActivityDate` ignora tarefa aberta nesta org**: vale a documentação padrão; 0 Tasks na dev. Medir em QA com carga sintética.
- **Se existe campo ou marca de "atividade comercial relevante"**: não existe campo de origem em Task (confirmado); a definição de "relevante" precisa de critério declarado pelo design (por exemplo `Subject` ou `CreatedById`) ou fica como limitação.
- **Flows `agentic_feed`**: 0 na dev; a QAS não foi consultada (não conectada).
- **Corpo de `OpportunityTrigger`/Handler/Helper e ordem entre trigger, SBQQ e Flows**: não lido nem mapeado; não é exercitado pelo alerta. Os triggers estão `IsValid=true` hoje, diferente do recon anterior; não sei o que mudou.
- **Por que `ScheduledFlowOpportunity` foi modificado em 2026-11-17**: não investiguei.
- **Contexto de execução do Flow agendado e acesso ao tipo de notificação**: não consultei.
- **Tópicos e ações do SFAgent2**: não relidos hoje; vale o recon de 2026-11-15.
- **Relatório `Neglected Open Opportunities`, painel e `eplast-ent-09`**: não relidos; vale o recon anterior (filtros nunca lidos).
