**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (alias da esteira; sandbox, org 00DHa000006vfMLMAY, única org em `sf org list`)

# EPLAST-29 · Verificação do build (v7 do SFAgent2 e Flow `Task_Agente_CriarTarefa`)

## Resumo
Os componentes determinísticos (Flow, guardas, gravação, rastreabilidade, ações do agente, confirmação obrigatória, PS) foram exercitados na dev e passaram. Não foi possível exercitar a camada conversacional do agente (resumo, recusa do resumo, ambiguidade, roteamento) nem o AC-4 com usuário comum. Por isso a verificação é inconclusiva, não reprovada: nenhum caso executado falhou.

## Ambiente
- Org conferida com `sf org list`: só `sbx-eplast-dev`. QA e produção não tocadas.
- Versão ativa do `SFAgent2` na dev: **v8** (v1 a v7 e v9 Inactive). A v7 (build desta demanda) está inativa, mas a v8 carrega o tópico `acoes_comerciais_EPLAST29_v8`. Nenhuma ativação feita por mim.
- Usuário de execução do job (Id `005bJ00000piKAaQAM`) é a conta de serviço da Konecta (regra 6), perfil Administrador do sistema. Há também um segundo usuário da mesma conta (`005bJ00000hBJmYQAW`, inativo, Administrador). Não há usuário comum disponível. Nada alterado em usuário, perfil, permission set ou opção de usuário.
- Estado inicial: Task 0, EmailMessage 0, Opportunity 0, atribuições do `PS_Comercial_AssistenteAcoes` 0.

## Como exercitei
Fixture `fixtures/account.apex` (já existente, funcionou sem mudança, com `TriggerUtility.bypassTrigger`) criou 1 Account `TESTE EPLAST-29 Conta Unica` e 2 `TESTE EPLAST-29 Conta Dup`. O Flow foi chamado por Apex anônimo (`Flow.Interview.createInterview('Task_Agente_CriarTarefa', ...)`), com a mesma interface que o agente usa, e as contagens foram feitas por SOQL. O Flow rodou como o usuário administrador; isso prova a lógica, não o contexto de execução do Agentforce (R5).

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 (gravação), AC-8 | Flow com assunto comum, vencimento hoje+3, Account sintética | Sucesso; 1 Task; `ActivityDate` informada, `WhatId` = Account, `OwnerId` = quem executa; `Description` com marca | Sucesso=true, delta +1; `ActivityDate` = hoje+3; `WhatId` = Conta Unica; `OwnerId` = `CreatedById` = `005bJ00000piKAaQAM`; Priority Normal, Status Open, TaskSubtype Task; `Description` = "Origem: assistente de IA" | passou |
| C2 | Guarda 2 (check-in, seção 5) | Assunto `Check In @ TESTE EPLAST-29`, Account sintética | Recusa; 0 Task | Sucesso=false, "Nao e possivel criar tarefa de check-in pelo assistente..."; delta 0; `AccountHasCheckInTask__c` das 3 contas continua false; 0 Account com `SystemModstamp` > `CreatedDate` depois dos casos | passou |
| C3 | AC-5 | Sem `DataVencimento` | Recusa pedindo a data; 0 Task | Sucesso=false, "Informe a data de vencimento da tarefa."; delta 0 | passou |
| C4 | AC-5 | Sem `Assunto` | Recusa; 0 Task | Sucesso=false, "Informe o assunto da tarefa."; delta 0 | passou |
| C5 | AC-7 (escopo) | `RegistroRelacionadoId` com prefixo `003` (Contact) | Recusa; 0 Task | Sucesso=false, "A tarefa so pode ser ligada a uma conta ou a uma oportunidade."; delta 0 | passou |
| C6 | AC-4 (parcial: registro não encontrado) | Id de Account inexistente (prefixo `001`) | Mensagem genérica sem nome nem campo; 0 Task | Sucesso=false, "Registro nao encontrado ou sem acesso."; delta 0 | passou |
| C7 | Guarda 3/5 para Opportunity | Id de Opportunity inexistente (prefixo `006`) | Mesma mensagem genérica; 0 Task | Sucesso=false, "Registro nao encontrado ou sem acesso."; delta 0 | passou |
| C8 | AC-6 (lado do Flow), PD-3 | Assunto `Rascunho de e-mail - ...`, `Descricao`, `Prioridade` High, vencimento hoje | Task Open, TaskSubtype Task, texto no `Description` + marca; sem EmailMessage | Sucesso=true; Priority High; `TaskSubtype` Task; `Description` = texto + "Origem: assistente de IA"; EmailMessage continuou 0 | passou |
| C9 | Contrato (prioridade inválida) | `Prioridade` = `Urgente` | Vira `Normal` | Task criada com Priority Normal | passou |
| C10 | AC-7 (nenhum registro de outro objeto) | Contagens após os casos | Opportunity e EmailMessage inalterados | Opportunity 0, EmailMessage 0; nenhuma Account alterada pelo Flow | passou |
| C11 | Confirmação obrigatória (P4, AC-1/AC-2) | `GenAiFunctionDefinition` das ações v8 | `CriarTarefa` com confirmação, alvo Flow; `IdentificarRegistro` só leitura | `CriarTarefa_EPLAST29_v8`: tipo `flow`, `IsConfirmationRequired = true`; `IdentificarRegistro_EPLAST29_v8`: `identifyRecordByName`, `IsConfirmationRequired = false` | passou (metadata; comportamento conversacional não exercitado) |
| C12 | AC-9 (estrutura) | `GenAiPluginFunctionDef` do `insights_comerciais` | Mantém `IdentificarConta`, `ConsultarPedidos`, `AgregacaoPedidos` | v7: 4 ações (3 originais + `ProximaAcaoCliente_EPLAST27`). v8 (ativa): 5 ações (as 3 originais + `ProximaAcaoCliente_EPLAST27` + `ResumoReuniao_EPLAST34`) | passou (estrutura; respostas não comparadas) |
| C13 | Tópico e PS | `GenAiPluginDefinition`, `PermissionSet`, `SetupEntityAccess` | Tópico presente; PS com Flow e agente | `acoes_comerciais_EPLAST29_v7`/`_v8` existem, com 2 ações (`CriarTarefa`, `IdentificarRegistro`); PS tem 1 `FlowDefinition` e 1 `BotDefinition`; Flow `Task_Agente_CriarTarefa` ativo (301Ha000016Tf4LIAS, AutoLaunchedFlow) | passou |
| C14 | AC-1 e AC-2 conversacionais | Pedido em linguagem natural, resumo, confirmar e recusar | Resumo antes de gravar; recusa não grava | Não há como conduzir conversa com o agente neste job (sem sessão de chat; licença de Agentforce não verificada, R9) | não executado |
| C15 | AC-3 ambiguidade | "criar tarefa para TESTE EPLAST-29 Conta Dup" (2 candidatos) | Lista os dois, não grava | Dados criados, mas o agente não pôde ser acionado. O Flow, chamado direto, não trata ambiguidade (isso é do tópico) | não executado |
| C16 | AC-4 (usuário sem o PS) | Pedido por usuário comum sem `PS_Comercial_AssistenteAcoes` | Recusa por permissão, sem vazar dado | Só existem usuários Administrador do sistema com o prefixo; não simulei. Também não provado o contexto de execução do Flow chamado pelo agente (R5, PD-8) | não executado |
| C17 | AC-6/AC-7 conversacionais, roteamento do `agent_router` | "enviar e-mail...", "criar oportunidade..." | Redige rascunho/recusa na conversa | Depende do agente | não executado |
| C18 | AC-9 (respostas iguais às da versão anterior) | Perguntas de leitura | Mesmas respostas | Depende do agente | não executado |

## O que ficou sem prova e o que uma pessoa precisa fazer
1. Conversa real com o agente (C14, C15, C17, C18): abrir o Agent Builder ou o chat do SFAgent2 na dev (ou na QA, na sessão de QA) com um usuário com licença de Agentforce e o `PS_Comercial_AssistenteAcoes`, e rodar os cenários AC-1, AC-2, AC-3, AC-6, AC-7 e AC-9. Conferir também que o tópico `acoes_comerciais` aparece no builder (o graph da v7 não foi gerado).
2. AC-4 (C16): usuário comum (`Comercial - Analista`) sem o PS, ou usuário com o PS mas sem acesso ao registro, para confirmar o contexto de execução do Flow (R5). Com Administrador não há como provar.
3. A versão ativa na dev é a v8 (inclui ações de EPLAST-27 e EPLAST-34), não a v7 desta demanda. Quem ativar na QA deve conferir qual versão leva.

## O que pode ter saído da org
Nada. O Flow não chama sistema externo. As Accounts foram criadas com `TriggerUtility.bypassTrigger = true`, sem callout Protheus. A única automação que atuou foi uma Task de "Conta Nova Cadastrada" que a org gera por conta criada (3 Tasks de crédito ligadas às contas de teste, apagadas junto com elas). Nenhum e-mail, pedido, cotação ou log de integração foi criado (EmailMessage 0).

## Limpeza
Apagadas as 3 Accounts `TESTE EPLAST-29%` e todas as Tasks ligadas a elas. Conferido por consulta: Account `TESTE EPLAST-29%` = 0, Task = 0 (estado igual ao inicial). Nenhuma mudança em usuário, perfil, permission set ou opção de usuário; nada a devolver. Nenhum fixture novo gravado (`fixtures/account.apex` funcionou como está).
