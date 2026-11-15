# EPLAST-29 · Recon da org — Ações por linguagem natural no assistente de IA

**Coleta:** 2026-11-15 · **Org:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY, `IsSandbox = true`, instância BRA8S, status Connected). Confirmada com `sf org list`; foi a única org listada. Nenhuma org de produção foi tocada.
**Método:** só leitura. Metadata por `sf project retrieve` (pasta temporária dentro do projeto e apagada ao fim; o `sf` recusa `--output-dir /tmp/recon` por "OutputDirOutsideProjectError") e contagens por `COUNT()`. Nenhum registro foi lido. Nada foi escrito em `force-app/`.
**Escopo lido de:** `01-analise.md` (Task-only, estende `SFAgent2`, e-mail e mensagem não saem do CRM) e `comentarios-do-card.md`.

---

## 1. O que já cobre o pedido

| Item | Status | Prova |
|---|---|---|
| Agente `SFAgent2` (`AgentType = AgentforceEmployeeAgent`, `Type = InternalCopilot`) | confirmado, único agente da org | `sf data query "SELECT DeveloperName, AgentType, Type FROM BotDefinition"` retornou 1 linha |
| Planner `SFAgent2_v4`, referenciado pela versão `v4` do bot | confirmado | `sf project retrieve start -m Bot:SFAgent2 -m GenAiPlannerBundle:SFAgent2_v4`; `v4.botVersion-meta.xml` aponta `genAiPlannerName = SFAgent2_v4` |
| Tópicos locais do planner: `ambiguous_question`, `insights_comerciais` ("Insights Comerciais e Acompanhamento"), `off_topic` | confirmado (3 `localTopics` no bundle) | retrieve acima |
| Ações do `insights_comerciais`: `AgregacaoPedidos` (`queryRecordsWithAggregate`), `IdentificarConta` (`identifyRecordByName`), `ConsultarPedidos` (`queryRecords`), todas `standardInvocableAction` | confirmado | `invocationTarget` e `invocationTargetType` no `.genAiPlannerBundle` |
| Ação de escrita ou de criação de Task no agente | **não encontrado**: nenhuma das 3 ações grava | mesmo retrieve |
| Ação de envio de e-mail ou mensagem no agente | **não encontrado** | mesmo retrieve |
| Agente `agent_router` citado na análise como subagente | **não confirmado como `localTopic`** neste retrieve: só 3 `localTopics` apareceram. A contagem "4 tópicos" do CLAUDE.md pode incluir o roteador, que não vi declarado como tópico local | retrieve acima |
| Versões do bot | **todas `Inactive`** (v1 a v4), inclusive a v4 | `sf data query "SELECT DeveloperName, Status, VersionNumber FROM BotVersion"` |
| Permission set `PS_Comercial_ResumoClienteAgente` | confirmado, mas **não cobre o pedido**: concede só `classAccesses` de `CustomerSummaryService`. A descrição diz "Sem acesso a objeto/campo. Falta Flow de busca + licenca do agente" | retrieve `PermissionSet:PS_Comercial_ResumoClienteAgente` |
| Atribuições desse permission set | 0 | `SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetId = ...` |
| Atribuição de qualquer licença de permission set com "Agentforce" no nome | 0 | `SELECT COUNT() FROM PermissionSetLicenseAssign WHERE PermissionSetLicense.DeveloperName LIKE '%Agentforce%'` |
| Flow de criação de tarefa por comando, relatório ou painel de Task | não procurado em relatório e painel nesta etapa (ver seção 7) | n/d |

Leitura para o design: o ponto de partida é o `SFAgent2`, como manda a regra 3 da conta. Não existe hoje nenhuma ação de escrita para reaproveitar. Também não há agente ativo na dev (todas as versões inativas), o que muda o que o verificador consegue exercitar.

## 2. O que será tocado

| Objeto ou componente | Detalhe confirmado | Prova |
|---|---|---|
| `Task` | `createable = true`. Campos padrão úteis: `Subject` (combobox), `ActivityDate` (date), `WhatId`, `WhoId`, `OwnerId`, `Description` (textarea), `Status`, `Priority`. O describe não marca nenhum deles como obrigatório sem default. Campos custom: nenhum do cliente. Só 3 do namespace `maps` (`maps__BaseObjectId__c`, `maps__LayerId__c`, `maps__WA_AdvRouteWaypoint__c`) | `sf sobject describe --sobject Task` |
| Descrição dos campos de Task usados | campos padrão, sem campo custom do cliente a descrever. A marca "Origem: assistente de IA" (P8) vai em `Description`, sem campo novo | mesmo describe |
| `Account.AccountHasCheckInTask__c` | boolean, label "Conta possui tarefa de Check-In?", **sem help text**. É escrito pelo Flow de Task (seção 3). Entra no escopo só se a Task criada tiver `Subject` começando com `Check In @` | `sf sobject describe --sobject Account` |
| `SFAgent2_v4` (planner) | receberá a nova ação de escrita | seção 1 |
| `EmailMessage` | 0 registros. Alvo do AC-6 (contagem não muda) | `SELECT COUNT() FROM EmailMessage` |

## 3. Automação concorrente

### 3.1 Em Task (objeto gravado por este build)

| Componente | Status | Detalhe | Prova |
|---|---|---|---|
| Trigger Apex em Task | nenhuma | 0 linhas | `sf data query -t "SELECT Name, Status FROM ApexTrigger WHERE TableEnumOrId='Task'"` |
| Validation rules em Task | 0 | | `sf data query -t "SELECT COUNT() FROM ValidationRule WHERE EntityDefinition.QualifiedApiName='Task'"` |
| Flow `TaskCreatedOrUpdated` ("[Tarefa] - Criado ou Atualizado") | **ativo**, `RecordAfterSave`, `CreateAndUpdate`, API 61.0, `AutoLaunchedFlow` | retrieve `Flow:TaskCreatedOrUpdated` |

O que o Flow faz, lido do XML:
1. Decisão `TaskRelatedToAnAccount`: `$Record.WhatId` começa com `001` (prefixo de Account).
2. Decisão `CheckInTask`: `$Record.Subject` começa com `Check In @`.
3. Se as duas forem verdadeiras, atualiza a Account de `WhatId`: `AccountHasCheckInTask__c = true`.

Consequência: uma Task criada pelo assistente só dispara esse efeito se o assunto começar com `Check In @` **e** o `WhatId` for uma Account. Fora disso o Flow roda e não grava nada. Em caso afirmativo, o Flow faz DML em Account e entra a cadeia da seção 3.2.

### 3.2 Em Account (gravada indiretamente pelo Flow acima)

| Componente | Status | Prova |
|---|---|---|
| Triggers ativos: `AccountBefore` (SBQQ) e `AccountTrigger` (custom) | confirmado, 2 triggers | `sf data query -t "SELECT Name FROM ApexTrigger WHERE TableEnumOrId='Account' AND Status='Active'"` |
| Flows record-triggered de Account (`AccountTriggered`, `UpdateParentAccountUsedLimit`) | **não reconfirmados nesta etapa**; vêm da análise (seção 5) | n/d |

### 3.3 Ordem de execução

| Evento | O que roda, até onde provei | Ordem |
|---|---|---|
| Task create ou update | só o Flow after-save `TaskCreatedOrUpdated`. Sem trigger, sem validation rule | determinística (um único componente) |
| Account update disparado pelo Flow (só caso `Check In @`) | `AccountBefore` e `AccountTrigger` (before, mesmo objeto) e Flows after-save de Account | **não provada**. Ordem entre os dois triggers não é garantida pela plataforma, e a sandbox não tem dado para traçar |

Opportunity e Order: fora do escopo (P2) e **não foram reconfirmados** nesta etapa. O mapa fica o da análise.

## 4. Marketing Cloud Connect (`et4ae5`)

A demanda cria texto de e-mail e mensagem como rascunho em Task, sem disparar. Por isso a regra 2 da conta pede o levantamento do conector.

| Item | Status | Prova |
|---|---|---|
| Conector instalado | confirmado: 523 `ApexClass` com `NamespacePrefix = et4ae5` | `sf data query -t "SELECT NamespacePrefix, COUNT(Id) FROM ApexClass WHERE NamespacePrefix='et4ae5' GROUP BY NamespacePrefix"` |
| Objetos do pacote | confirmado, 13 itens retornados de `CustomObject` do namespace. Primeira linha da lista, entre os 27 nomes impressos pelo describe do tooling: `SendDefinition`, `SendJunction`, `IndividualEmailResult`, `IndividualLink`, `Automated_Send`, `Triggered_Send_Execution`, `SMSDefinition`, `SMSJunction`, `Campaign_Member_Configuration`, `Business_Unit`, `Email_Linkage`, `JB_Event`, `JB_Flow_Event` e config (`ET4AE_*`). A query retornou um total de 13 mas imprimiu mais nomes: **não confio na contagem, só na lista** | `sf data query -t "SELECT DeveloperName FROM CustomObject WHERE NamespacePrefix='et4ae5'"` |
| Flows `MCC_*` com versão ativa | 13 | `sf data query -t "SELECT COUNT() FROM FlowDefinition WHERE DeveloperName LIKE 'MCC%' AND ActiveVersionId != null"` |
| Campos que o conector usa em Task, Account ou Contact | **não levantado** | n/d |
| Consentimento e opt-out (campo e objeto no CRM) | **não levantado** | n/d |

O build não toca o conector. O `et4ae5` não tem trigger em Task (seção 3.1, 0 triggers de qualquer origem).

## 5. Volume e dados de teste

| Objeto | Contagem | Prova |
|---|---|---|
| Task | 0 | `SELECT COUNT() FROM Task` |
| Event | 0 | idem |
| EmailMessage | 0 | idem |
| Account | 0 | idem |
| Contact | 0 | idem |
| Opportunity | 0 | idem |
| Order | 0 | idem |
| User ativo | 22 | `SELECT COUNT() FROM User WHERE IsActive = true` |

A sandbox de dev não tem dado para testar. Os registros sintéticos `REG-TESTE-01` e `REG-TESTE-DUP` (AC-1 a AC-9) precisam ser criados pelo build ou pelo QA.

## 6. Permissões

| Item | Status | Prova |
|---|---|---|
| OWD de Task | interno `Private`, externo `Private` (valor retornado pela API) | `sf data query -t "SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN ('Task','Account')"` |
| OWD de Account | interno `ReadWrite`, externo `Private` | idem |
| `PS_Comercial_ResumoClienteAgente` | só acesso à classe `CustomerSummaryService`, sem objeto, campo ou acesso ao agente. 0 atribuições | seção 1 |
| `SetupEntityAccess` ligado a esse permission set | 1 linha. Não identifiquei o que ela libera (a classe, provavelmente); não inferi | `SELECT COUNT() FROM SetupEntityAccess WHERE Parent.Name = ...` |
| Permissão de criar Task por perfil ou permission set | **não levantada** | n/d |
| Licença `Salesforce` completa 14 de 14 | vem da análise; não reconsultada | n/d |
| Licença de permission set de Agentforce atribuída | 0 atribuições | seção 1 |

Leitura: P5 da análise ("reaproveitar `PS_Comercial_ResumoClienteAgente` se cobrir o agente") **não se sustenta como está**. O permission set não cobre o agente nem Task, e não está atribuído a ninguém. O arquiteto decide entre estender esse permission set ou criar outro.

## 7. Riscos do assessment que tocam o escopo

| Risco | Estado confirmado agora |
|---|---|
| Automação concorrente em Account, Opportunity e Order | Account: 2 triggers ativos reconfirmados. Opportunity e Order não reconfirmados. Entra no escopo só pelo caminho `Check In @` (seção 3.1) |
| Alias `sbx-eplast-dev` com nome de QA | `sf org list` mostra só `sbx-eplast-dev`, e o username dele termina em `.qa` (não transcrevo o username). Não há alias de QA conectado nesta sessão, então **não comparei dev e QA** |
| Campos custom sem descrição | `AccountHasCheckInTask__c` sem help text. Os campos de Task usados são padrão |
| Cobertura Apex de 10% | não reconfirmada. Sem Apex novo previsto na análise |
| Sandbox sem registros | confirmado (seção 5) |

## 8. O que não consegui confirmar

1. **Qual versão do planner está ativa:** todas as versões do bot aparecem `Inactive` (inclusive a v4). Não sei se isso reflete o estado real de uso, nem se o agente responde na dev hoje.
2. **Se `agent_router` é um tópico:** só 3 `localTopics` aparecem no retrieve; a contagem de 4 tópicos do CLAUDE.md da conta não fechou com o que li.
3. **O que o `SetupEntityAccess` do permission set libera:** 1 linha, não detalhada.
4. **Quem tem permissão de criar Task e acesso ao agente:** não levantei perfis nem permission sets que alcançam Task. Precisa de leitura de `ObjectPermissions` agregada.
5. **Flows de Account, Opportunity e Order, e validation rules de Account:** não relidos. Valem os números da análise.
6. **Campos e consentimento do conector `et4ae5` em Task, Account e Contact, e a lista exata de objetos do pacote** (a query de contagem e a lista impressa não bateram).
7. **Relatórios e painéis de Task ou de atividade** que já cubram o acompanhamento do vendedor: não procurados.
8. **Diferença entre dev e QA:** a QA não está conectada nesta sessão.
9. **Ordem de execução real** entre `AccountBefore`, `AccountTrigger` e Flows de Account no caminho `Check In @`: não provável sem dado e sem trace.
10. **Licença de Agentforce disponível para o usuário de teste:** 0 atribuições; disponibilidade no catálogo vem da análise e não foi reconsultada.
