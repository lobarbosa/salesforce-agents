# EPLAST-29 · Recon da org (refeito em 2026-11-17 para o redesenho da v18)

**Data:** 2026-11-17. **Org:** `sbx-eplast-dev`, sandbox (Org ID 00DHa000006vfMLMAY), status Connected. Confirmada com `sf org list`; foi a única org listada. O username termina em `.qa`, esperado pela regra 5 da conta (dev da esteira = `eplast--qa` da Eplast). Produção não foi tocada.
**Método:** só leitura. `sf data query` (metadata e `COUNT()`) e `sf project retrieve` numa pasta temporária dentro do projeto (a CLI recusa `--output-dir` fora do projeto, então não foi `/tmp/recon`; a pasta foi apagada ao fim e nada ficou em `force-app/`). Nenhum registro foi lido.
**Entrada:** `01-analise.md`, `comentarios-do-card.md` (respostas do cliente de 17/11 e diretriz do responsável das 18:02 para a v18) e o fim do `03-design.md`.
**O que mudou desde o recon anterior do mesmo dia:** a dev passou a ter a v16 e a v17 do bot e o Flow v2; o Flow ativo é a v1; e a dev já não está vazia (seção 5).

## 1. O que já cobre o pedido

| Item | Status | Prova |
|---|---|---|
| Agente `SFAgent2`, tópico `acoes_comerciais_EPLAST29_v17` (9 instruções) com ações `IdentificarRegistro_EPLAST29_v17` (`identifyRecordByName`) e `CriarTarefa_EPLAST29_v17` (Flow `Task_Agente_CriarTarefa`) | confirmado | retrieve `GenAiPlannerBundle:SFAgent2_v17` |
| Confirmação: `CriarTarefa` tem `isConfirmationRequired = true`; `IdentificarRegistro` tem `false`. A confirmação é da plataforma na ação; o resumo completo depende só da instrução do tópico | confirmado | `SFAgent2_v17.genAiPlannerBundle` |
| Versões do bot: v1 a v17. **Só a v13 está `Active`**; v14 a v17 `Inactive` | confirmado | `SELECT DeveloperName, VersionNumber, Status FROM BotVersion` |
| Planners existentes: `SFAgent2_v1` a `SFAgent2_v17` (a consulta ordenada por nome mostra v9 no topo; v17 foi retrieved diretamente) | confirmado | `SELECT DeveloperName FROM GenAiPlannerDefinition`, retrieve da v17 |
| v17 tem 5 tópicos: `insights_comerciais`, `agent_router`, `acoes_comerciais_EPLAST29`, `ambiguous_question`, `off_topic`. Em `insights_comerciais`: as 3 ações originais mais `ProximaAcaoCliente_EPLAST27`, `ResumoReuniao_EPLAST34`, `SugestaoCampanha_EPLAST46` | confirmado | `invocationTarget` no bundle v17 |
| Flow `Task_Agente_CriarTarefa`: `AutoLaunchedFlow`, API 67.0, `runInMode = DefaultMode`. **Versão 1 `Active`; versão 2 `Obsolete`** (a v2 é a que tem ramo de lead, leitura de parâmetros e guardas novas). Hoje o Flow ativo na dev é a v1 | confirmado | `SELECT VersionNumber, Status FROM Flow WHERE Definition.DeveloperName='Task_Agente_CriarTarefa'` (tooling); retrieve trouxe a v2 |
| Flow v2 (retrieve): dois `recordCreates` em `Task` (ramo conta/oportunidade grava `WhatId`; ramo lead grava `WhoId` e deixa `WhatId` vazio), `OwnerId` = usuário que pediu, guardas `FalhaAssunto`, `FalhaCheckIn`, `FalhaData`, `FalhaDescricao`, `FalhaDesligado`, `FalhaLeadConvertido`, `FalhaNaoEncontrado`, `FalhaGravacao`, `FalhaRegistro`; lê `AssistenteTarefaSetting__mdt` | confirmado | XML do Flow v2 |
| Entrada da ação `CriarTarefa` (v17): `Assunto`, `DataVencimento`, `RegistroRelacionadoId` obrigatórias; `Descricao` e `Prioridade` opcionais; sem entrada de responsável. A descrição de `RegistroRelacionadoId` já cita lead (00Q), conta (001), oportunidade (006) | confirmado | `CriarTarefa_EPLAST29_v17/input/schema.json` |
| Custom metadata `AssistenteTarefaSetting__mdt` (descrição preenchida), campos `Ativo__c`, `DescricaoObrigatoria__c`, `MarcaOrigem__c`, `PrefixosPermitidos__c`, `PrioridadePadrao__c`; **1 registro** | confirmado | retrieve do objeto; `SELECT COUNT() FROM AssistenteTarefaSetting__mdt` |
| Permission set `PS_Comercial_AssistenteAcoes`: `agentAccesses` do `SFAgent2`, acesso ao Flow e leitura do `AssistenteTarefaSetting__mdt`; sem objeto nem campo. **0 atribuições** | confirmado | retrieve do PS; `COUNT()` em `PermissionSetAssignment` (nome `PS_Comercial_Assistente%`) |
| Ação de e-mail ou envio no agente | não existe; o desenho é rascunho em Task | bundle v17 |

Leitura para o design: o pedido de lead, o ramo de lead no Flow, o custom metadata e o acesso ao agente pelo PS já existem em metadata na dev (v17 e Flow v2). O redesenho da v18 (identificar antes de confirmar, "criada" só com retorno de sucesso, travas na ação ou no Flow, resumo completo) é ajuste sobre isso, não construção nova. A única trava que hoje sustenta a confirmação é `isConfirmationRequired` na ação mais a instrução do tópico; não há nada na v17 que impeça o modelo de afirmar criação sem chamar a ação. Esta é leitura do que está no bundle, não teste de comportamento.

## 2. O que será tocado

| Componente | Detalhe confirmado | Prova |
|---|---|---|
| `Task.WhoId` | referência a `Contact` e `Lead`, polimórfico, não obrigatório | `sf sobject describe --sobject Task` (recon anterior de hoje) |
| `Task.WhatId` | referência a Account, Opportunity, Order, Quote, Campaign, Case e outros; Lead não está na lista | idem |
| `Task.Subject`, `ActivityDate`, `Description`, `OwnerId` | existem; nenhum obrigatório sem default | idem |
| Flow `Task_Agente_CriarTarefa` | v1 ativa, v2 obsoleta; versão ativa não se edita no lugar (nova versão) | seção 1 |
| `SFAgent2` planner e botVersion | v17 é a mais nova, inativa; v13 ativa; v18 parte da v17 | seção 1 |
| `GenAiFunction` por versão (ex.: `CriarTarefa_EPLAST29`) | existem; cada versão do planner acarreta funções novas | recon anterior de hoje (nomes `_v7`, `_v8`); não reconsultado |
| `AssistenteTarefaSetting__mdt` | existe, 1 registro; alterar parâmetro não exige versão de Flow | seção 1 |

## 3. Automação concorrente

| Componente | Detalhe | Prova |
|---|---|---|
| Trigger Apex em `Task` e em `Lead` | 0 / 0 | `SELECT Name FROM ApexTrigger WHERE TableEnumOrId IN ('Task','Lead')` (tooling), recon anterior de hoje; não repetido |
| Validation rules em `Task` | 0 | `ValidationRule` (tooling), recon anterior de hoje |
| Validation rules ativas em `Lead` | 2 (`Celular` e `Telefone`, formato); rodam ao salvar Lead, não ao criar Task com `WhoId` | idem |
| Flow `TaskCreatedOrUpdated` (ativo, after-save, create e update) | só age com `WhatId` iniciando em `001` e assunto iniciando em `Check In @`; marca `Account.AccountHasCheckInTask__c`. Com `WhoId` de lead e sem `Check In @` não grava | retrieve em recon anterior de hoje; não repetido |
| Flows record-triggered em Lead | nenhum no repositório da linha de base (`grep` 0). **Não confirmado na org** (seção 8) | grep |
| Outras Tasks criadas por Flow (não disparam em Task): `AccountTriggered`, `Oportunidade_Industria`, `OpportunityFlow` | existem na linha de base | grep em `force-app` |
| Flows ativos na org | 52 | `COUNT()` em `FlowDefinition` com `ActiveVersionId != null`, recon anterior de hoje |

### Ordem de execução

| Evento | O que roda | Ordem |
|---|---|---|
| Task criada pelo Flow do agente | só `TaskCreatedOrUpdated` (after-save), sem trigger nem validation rule | determinística (um componente) |
| Task com `WhatId` de conta e assunto `Check In @` | Flow de Task marca Account, que dispara `AccountBefore` (SBQQ), `AccountTrigger` (custom, Protheus) e Flows de Account | não mapeada. O Flow do agente recusa `Check In @`, então o caminho não é acionado |

Para lead, nada em Account é disparado. Opportunity e Order não são gravados por esta demanda. A `AccountTrigger` (um job por conta, envio ao Protheus) não é tocada: nenhuma gravação em `Account`.

## 4. Marketing Cloud Connect (`et4ae5`)

A demanda não dispara e-mail: só rascunho em Task. Nada foi feito no Marketing Cloud.

| Item | Status | Prova |
|---|---|---|
| Conector instalado | `Task.WhatId` aceita `et4ae5__Triggered_Send_Execution__c` | describe de Task |
| Campos `et4ae5__*` em Lead | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | `sf sobject describe --sobject Lead --json` |
| Campos `et4ae5__*` em Task | nenhum encontrado no describe | `sf sobject describe --sobject Task --json` |
| `CampaignMember` | 0 registros | `SELECT COUNT() FROM CampaignMember` |
| Campos do conector em Contact, outros campos de opt-out de e-mail em Lead | não levantado | n/d |

## 5. Volume e dados de teste

| Objeto | Contagem | Prova |
|---|---|---|
| Lead | 4 | `SELECT COUNT() FROM Lead` |
| Task | 2 | `SELECT COUNT() FROM Task` |
| Account | 2 | `SELECT COUNT() FROM Account` |
| Contact | 1 | `SELECT COUNT() FROM Contact` |
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |
| CampaignMember | 0 | idem |

A dev não está mais vazia: há registros que não li e cuja origem não sei (o recon anterior de hoje contava 0 em Lead, Task e Account; pode ser dado criado pela verificação do build). Não assumir que são sintéticos sem conferir nas fixtures. Dado de teste sai dos scripts de `fixtures/` (regra 6). Conta criada pela tela passa pela `AccountTrigger`; use o desvio `TriggerUtility.bypassTrigger`.

Usuário de teste da regra 6: a consulta por username da conta de serviço da Konecta (regra 6) retornou **dois** usuários, ambos com perfil Administrador do sistema: `005bJ00000piKAaQAM` (ativo) e `005bJ00000hBJmYQAW` (inativo). Não há usuário não administrador identificado para o caso de acesso negado (ver seção 8).

## 6. Permissões

| Item | Status | Prova |
|---|---|---|
| OWD: Lead interno `ReadWriteTransfer`, externo `Private`; Task `Private`/`Private`; Account `ReadWrite`/`Private`; Opportunity `Read`/`Private` | confirmado | `EntityDefinition` (tooling), recon anterior de hoje |
| `PS_Comercial_AssistenteAcoes`: acesso ao agente `SFAgent2`, ao Flow e ao custom metadata; sem acesso a objeto; 0 atribuições | confirmado | retrieve do PS |
| Perfis com `Create` e `Read` em Lead (20 linhas lidas): Comercial, Comercial - Analista, Comercial - Analistas, Gerente de soluções, Gerente do contrato, Executive Sponsor, Pricing, Usuário Padrão, End User, Usuário do Marketing, Administrador do sistema e outros; `Read` sem `Create`: Comercial Padrão, Marketing, Financeiro, Read Only e outros | confirmado | `SELECT ... FROM ObjectPermissions WHERE SobjectType IN ('Task','Lead') AND Parent.IsOwnedByProfile = true` (a consulta não devolveu linhas de Task) |
| Permission sets com `Read` em Lead: `PS_Marketing_AnaliseCampanhas`, `PS_Marketing_Publicos` (sem `Create`) | confirmado | mesma consulta, `IsOwnedByProfile = false` |
| Licença de Agentforce atribuída | 0 atribuições de PSL com nome `Agentforce%` | `COUNT()` em `PermissionSetLicenseAssign` |
| Mapeamento dos 4 públicos (SDR, vendedores, pós-vendas, gestão comercial) para perfis | **não levantado** | n/d |

Como Task é `Private`, o dono vê só as próprias tarefas; o Flow grava `OwnerId = $User.Id`.

## 7. Outras demandas que tocam o SFAgent2

| Demanda | O que consta no planner v17 | Estado |
|---|---|---|
| EPLAST-27 | `ProximaAcaoCliente_EPLAST27` (Flow `Account_Agente_ProximaAcao`), `instruction2_EPLAST27` em `insights_comerciais` | aguardando_homologacao (preflight) |
| EPLAST-34 | `ResumoReuniao_EPLAST34` (`MeetingSummaryService`), `instruction1_EPLAST34` | idem |
| EPLAST-46 | `SugestaoCampanha_EPLAST46` (Flow `Account_Agente_SugestaoCampanha`), `instruction1_EPLAST46` | idem |

- Preflight: sem bloqueios; as três demandas mexem no mesmo agente. A v17 e a v16 são acumuladas e carregam as ações dessas demandas; a v18 deve mantê-las (diretriz do responsável).
- A versão ativa (v13) não é alterada no lugar. Toda mudança é versão nova (v18) a partir da v17.
- A causa de a v13 seguir ativa na dev e de a v17 estar inativa está no passo de deploy e ativação da esteira (comentários do card); aqui só o estado foi confirmado.

## 8. O que não consegui confirmar

1. Flow record-triggered em Lead ativo na org: `FlowDefinitionView` não é suportado nesta org via `sf data query`; vale só o `grep` do repositório (0).
2. Por que o Flow v2 está `Obsolete` e a v1 `Active` na dev, e se isso é efeito de deploy da esteira ou de desativação manual. Só o estado foi lido.
3. Quais registros de Lead (4), Task (2), Account (2) e Contact (1) existem na dev e quem os criou; não os li (guardrail 2).
4. `ObjectPermissions` de Task por perfil (a consulta não devolveu linha) e, portanto, quem entre os 4 públicos pode criar Task.
5. Usuário não administrador na dev para o caso de acesso negado: os dois usuários da conta de serviço são administradores.
6. Licença de Agentforce disponível para usuário de teste (a contagem de atribuição é 0; a disponibilidade no catálogo não foi reconsultada hoje).
7. Conteúdo dos 15 outros `PS_*` e como cada público recebe acesso ao agente na prática.
8. Comportamento real do `identifyRecordByName` com `Lead` e se a v17 afirma "criada" sem retorno da ação: só li a configuração, não executei o agente.
9. Ordem entre `AccountBefore`, `AccountTrigger` e Flows de Account; Opportunity e Order não foram relidos (fora do escopo).
10. Campos do conector `et4ae5` em Contact e demais campos de consentimento e opt-out em Lead.
11. Triggers, validation rules, OWD e `TaskCreatedOrUpdated` de Task e Lead: reaproveitados do recon anterior de hoje, não reexecutados nesta rodada.
