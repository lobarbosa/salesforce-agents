# EPLAST-29 · Recon da org (refeito após as respostas do cliente de 17/11)

**Data:** 2026-11-17. **Org:** `sbx-eplast-dev`, sandbox (Org ID 00DHa000006vfMLMAY), status Connected. Confirmada com `sf org list`; foi a única org listada. O username termina em `.qa`, o que é esperado pela regra 5 da conta (dev da esteira = `eplast--qa` da Eplast). Produção não foi tocada.
**Método:** só leitura. `sf data query` (metadata e `COUNT()`), `sf project retrieve` numa pasta temporária dentro do projeto (apagada ao fim; nada ficou em `force-app/`). Nenhum registro foi lido.
**Entrada:** `comentarios-do-card.md` e o fim do `03-design.md` (respostas do cliente de 17/11): tarefas vinculadas a **lead**, cliente ou oportunidade; confirmação mostrando registro relacionado, responsável, descrição e prazo; e-mail e mensagem só como rascunho; acesso para SDR, vendedores, pós-vendas e gestão comercial.
**Aviso:** o `02-recon.md` anterior (coleta de 15/11) estava defasado (dizia v4 e 3 tópicos). Este o substitui.

## 1. O que já cobre o pedido

| Item | Status | Prova |
|---|---|---|
| Agente `SFAgent2`, tópico `acoes_comerciais_EPLAST29` (9 instruções) com ações `IdentificarRegistro` (`identifyRecordByName`, standardInvocableAction) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`) | confirmado no planner v15 (e v13/v14) | retrieve `GenAiPlannerBundle:SFAgent2_v13/v14/v15` |
| Planner v15 (o mais novo) tem 5 tópicos: `insights_comerciais`, `agent_router`, `acoes_comerciais_EPLAST29`, `ambiguous_question`, `off_topic`. Ações de outras demandas em `insights_comerciais`: `ProximaAcaoCliente_EPLAST27`, `ResumoReuniao_EPLAST34` (`MeetingSummaryService`), `SugestaoCampanha_EPLAST46` (`Account_Agente_SugestaoCampanha`), mais as 3 originais | confirmado | retrieve v15, `invocationTarget` |
| Versões do bot na dev: v1 a v15. **Só a v13 está `Active`**; v1 a v12, v14 e v15 `Inactive` | confirmado | `SELECT DeveloperName, Status, VersionNumber FROM BotVersion` |
| Planners existentes: `SFAgent2_v1` a `SFAgent2_v15` (15) | confirmado | `SELECT DeveloperName FROM GenAiPlannerDefinition` |
| Flow `Task_Agente_CriarTarefa`: `AutoLaunchedFlow`, API 67.0, `Active`, `runInMode = DefaultMode`, versão ativa = última | confirmado | `FlowDefinition` + retrieve |
| Entradas da ação `CriarTarefa` (v15): `Assunto`, `DataVencimento`, `RegistroRelacionadoId` obrigatórias; `Descricao` e `Prioridade` opcionais. **Não há entrada de responsável**: o Flow grava `OwnerId = $User.Id` | confirmado | `input/schema.json` e XML do Flow |
| Guardas do Flow: assunto vazio, assunto `Check In @`, data vazia, prefixo do Id só `001` (Account) ou `006` (Opportunity), registro não achado. Mensagem de falha cita "conta ou oportunidade". O Flow grava o Id recebido em `WhatId` e **não preenche `WhoId`** | confirmado | XML do Flow (guarda `DecRegistroValido`, `FalhaRegistro`, campo `WhatId`) |
| Instrução do tópico: "só cria tarefas... ligadas a uma conta ou a uma oportunidade"; busca com `objectApiName = Account ou Opportunity`; "criar tarefa para outra pessoa" listado como não disponível; resumo antes de `CriarTarefa` cita assunto, registro, responsável (o próprio usuário), vencimento e texto do rascunho | confirmado | XML do planner v15 (`acoes_comerciais_EPLAST29_v15`) |
| Permission set `PS_Comercial_AssistenteAcoes`: concede só o Flow `Task_Agente_CriarTarefa`, sem objeto nem campo. **0 atribuições** na dev | confirmado | retrieve do PS e `COUNT()` em `PermissionSetAssignment` |
| Ação de e-mail ou envio no agente | não existe nas ações do tópico; as instruções mandam recusar envio | planner v15 |

Leitura para o design: o pedido de lead exige mudar três pontos já construídos: a guarda de prefixo do Flow (hoje recusa `00Q`), o campo gravado (lead vai em `WhoId`, não em `WhatId`) e as instruções do tópico, a descrição da ação e do schema de `RegistroRelacionadoId` (todos citam só conta e oportunidade). O agente não tem ação que grave por outro responsável.

## 2. O que será tocado

| Componente | Detalhe confirmado | Prova |
|---|---|---|
| `Task.WhoId` | referência a `Contact` e `Lead`, polimórfico, não obrigatório | `sf sobject describe --sobject Task` |
| `Task.WhatId` | referência a Account, Opportunity, Order, Quote, Campaign, Case e muitos outros; **Lead não está na lista** | idem |
| `Task.Subject` (combobox), `ActivityDate` (date), `Description` (textarea), `OwnerId` (User ou Group) | existem; nenhum é obrigatório sem default no describe | idem |
| Objeto `Lead` | existe; 0 registros | `COUNT()` |
| Flow `Task_Agente_CriarTarefa` (ativo) | alvo de ajuste; versão ativa não se edita no lugar (nova versão) | seção 1 |
| Planner e versão do bot | a v15 é a mais nova e é inativa; v13 ativa | seção 1 |
| `PS_Comercial_AssistenteAcoes` | existe, sem atribuição | seção 1 |

## 3. Automação concorrente

| Componente | Detalhe | Prova |
|---|---|---|
| Trigger Apex em `Task` | 0 | `SELECT Name FROM ApexTrigger WHERE TableEnumOrId='Task'` (tooling) |
| Trigger Apex em `Lead` | 0 | idem, `Lead` |
| Validation rules em `Task` | 0 | `SELECT ... FROM ValidationRule WHERE EntityDefinition.QualifiedApiName IN ('Lead','Task')` (tooling) retornou só 2 linhas, ambas de Lead |
| Validation rules ativas em `Lead` | 2: `Celular` e `Telefone` (formato). Rodam ao salvar Lead, não ao criar Task com `WhoId` | mesma query; `Celular.validationRule-meta.xml` (mensagem de formato) |
| Flow `TaskCreatedOrUpdated` (ativo, `RecordAfterSave`, create e update) | só age se `WhatId` começa com `001` e o assunto começa com `Check In @`; então marca `Account.AccountHasCheckInTask__c`. Com `WhoId` de lead e sem `Check In @` não grava nada | retrieve do Flow |
| Flows record-triggered de Lead | nenhum encontrado no repositório da linha de base (`grep` de `<object>Lead</object>` em `force-app/.../flows`: 0). Não consultei a org diretamente (ver seção 8) | grep |
| Outros Flows que criam `Task` (não disparam em Task): `AccountTriggered` (after-save em Account), `Oportunidade_Industria` e `OpportunityFlow` (after-save em Opportunity) | existem na linha de base | grep em `force-app` |
| Flows ativos na org | 52 | `COUNT()` em `FlowDefinition` com `ActiveVersionId != null` |

### Ordem de execução

| Evento | O que roda | Ordem |
|---|---|---|
| Task create pelo Flow do agente | só `TaskCreatedOrUpdated` (after-save), sem trigger, sem validation rule | determinística (um único componente) |
| Account (só se um dia entrar `Check In @`) | `AccountBefore` (SBQQ), `AccountTrigger` (custom) e Flows de Account | não mapeada agora. O Flow do agente bloqueia `Check In @`, então o caminho não é acionado; Opportunity e Order fora do escopo e não relidos |

Para lead: nada na Account é disparado (`WhoId` de Lead, `WhatId` vazio). Se a tarefa de lead for vinculada também a Account ou Opportunity por `WhatId`, a regra acima vale igual.

## 4. Marketing Cloud Connect (`et4ae5`)

A demanda não dispara e-mail; só rascunho em Task. A análise já mantém isso fora do conector. Sem levantamento novo nesta rodada.

| Item | Status | Prova |
|---|---|---|
| Conector instalado | `WhatId` de Task aceita `et4ae5__Triggered_Send_Execution__c` (objeto do pacote presente) | describe de Task |
| Campos do conector em Task, Lead e Contact, e consentimento/opt-out | **não levantado** | n/d |

## 5. Volume e dados de teste

| Objeto | Contagem | Prova |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Task | 0 | idem |
| Account | 0 | idem |
| Opportunity | 0 | idem |
| Campaign / CampaignMember | 0 / 0 | idem |

A dev não tem dado. Lead, Account e Opportunity de teste saem dos scripts de `fixtures/` (regra 6 da conta). Conta criada pela tela passa pela `AccountTrigger` (Protheus); use o desvio `TriggerUtility.bypassTrigger` das fixtures. Lead não tem trigger (seção 3).

## 6. Permissões

| Item | Status | Prova |
|---|---|---|
| OWD: Lead interno `ReadWriteTransfer`, externo `Private`; Task `Private`/`Private`; Account `ReadWrite`/`Private`; Opportunity `Read`/`Private` | confirmado | `SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition` (tooling) |
| `PS_Comercial_AssistenteAcoes`: só acesso ao Flow; sem acesso a objeto, Task, Lead ou ao agente; atribuições: 0 | confirmado | retrieve do PS |
| Permission sets `PS_*` da org (15), entre eles `PS_PosVendas_Atendimento`, `PS_Comercial_ProximaAcao`, `PS_Comercial_ResumoReuniao`, `PS_Comercial_RascunhoIA`, `PSG_Comercial_RascunhoIA` | existem; conteúdo não lido | `SELECT Name FROM PermissionSet WHERE Name LIKE 'PS_%'` |
| Quem hoje cria Task e vê Lead, por perfil dos 4 públicos (SDR, vendedores/executivos, pós-vendas, gestão comercial) | **não levantado** | n/d |
| Licença de Agentforce atribuída a usuário | não reconsultado nesta rodada | n/d |

Como Task é `Private`, o dono vê só as próprias tarefas; o Flow grava `OwnerId = $User.Id`, então o responsável da tarefa é quem pediu.

## 7. Outras demandas que tocam o SFAgent2

| Demanda | O que consta no planner v15 | Estado |
|---|---|---|
| EPLAST-27 | `ProximaAcaoCliente_EPLAST27` (Flow `Account_Agente_ProximaAcao`), instrução `instruction2_EPLAST27` em `insights_comerciais` | aguardando_homologacao (preflight) |
| EPLAST-34 | `ResumoReuniao_EPLAST34` (`MeetingSummaryService`), `instruction1_EPLAST34` | idem |
| EPLAST-46 | `SugestaoCampanha_EPLAST46` (`Account_Agente_SugestaoCampanha`), `instruction1_EPLAST46` | idem |

- A v15 é composta (traz as ações das quatro demandas); a v13 ativa também tem as quatro e a EPLAST-29 com `CriarTarefa`. A v14 não foi aberta em detalhe além de existir com `acoes_comerciais`.
- Qualquer mudança nesta demanda vira versão nova do planner e do `botVersion` (v16 ou a numeração que a esteira indicar), partindo da última versão e sem tocar a ativa (v13). A decisão de estratégia de versões é do arquiteto; o histórico de 16/11 (pacote só com a v12) está em `03-design.md`.
- Também existem `GenAiFunction` por versão (ex.: `CriarTarefa_EPLAST29`, `_v7`, `_v8`), então cada versão nova acarreta funções novas.

## 8. O que não consegui confirmar

1. Se há Flow record-triggered de Lead ativo na org. O `FlowDefinitionView` não aceitou o filtro por objeto e `Flow` não tem `TriggerType` na consulta; só o `grep` do repositório (0 resultados) vale.
2. Quem entre os 4 públicos já tem criar Task, ler Lead e Opportunity: não levantei `ObjectPermissions` por perfil e permission set.
3. O que o `PS_Comercial_AssistenteAcoes` e os outros `PS_*` concedem além do Flow; e como o acesso ao agente SFAgent2 é dado (o PS atual não tem objeto nem referência explícita ao agente).
4. Licença de Agentforce disponível e atribuída aos usuários de teste.
5. Conteúdo da v14 e a causa de a v13, e não a v15, estar ativa na dev.
6. Campos e consentimento do conector `et4ae5` em Lead, Contact e Task.
7. Comportamento real do `identifyRecordByName` com `objectApiName = Lead` (a ação é padrão; não exercitei, a dev não tem Lead).
8. Se a resposta do cliente exige mostrar o responsável com opção de escolha: hoje o responsável é sempre o usuário, e o Flow não aceita outro. Isso é decisão do design.
9. Ordem entre `AccountBefore`, `AccountTrigger` e Flows de Account; Opportunity e Order não relidos, pois o caminho `Check In @` está bloqueado.
10. Usuário de teste da conta de serviço (regra 6): não consultei o Id nesta rodada.
