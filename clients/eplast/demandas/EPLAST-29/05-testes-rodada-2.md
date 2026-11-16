**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-29 · Testes na QA, rodada 2 (SFAgent2 v7, tópico `acoes_comerciais`)

Org conferida com `sf org list`: única conectada, `sbx-eplast-qa` (Org Id 00DHa000006vZtmMAE, sandbox QAS, Partial Copy). Nada em produção nem no Marketing Cloud. Só toquei em registros que eu criei (`TESTE EPLAST-29`).

## Retestes da rodada anterior
- **FALHA 1 da rodada 1 (v7 inativa na QA): corrigida.** O pacote de `05-deploy-qa.md` (deploy `0AfHa00000EI8jpKAD`, v7) está na QA. Antes da sessão, `BotVersion` do `SFAgent2` na QA: v1, v2, v3, v4, v7 e v8 Inactive, **v6 Active**. Ativei a v7 com `sf agent activate --api-name SFAgent2 --version 7 --target-org sbx-eplast-qa` ("SFAgent2 v7 activated."). Depois: **v7 Active**, as demais Inactive. Ela fica ativa (decisão de 2026-11-16). Observação: v8 também existe na QA (tópico `acoes_comerciais_EPLAST29_v8`); não a testei nem a ativei.

## Falhas

### FALHA 1 (crítica) — o assistente diz que criou a tarefa, mas nenhuma Task é gravada (AC-6, e o rascunho de e-mail)
- **Reproduzir:** `sf agent preview start -o sbx-eplast-qa -n SFAgent2`; enviar "criar um rascunho de e-mail de proposta em tarefa para TESTE EPLAST-29 Conta Unica com vencimento em 2026-12-03"; o agente mostra o resumo; enviar "sim, pode criar"; enviar "sim, confirmo". Repetido 3 vezes, com redações diferentes ("enviar e-mail de proposta para o contato de ...", "confirmo").
- **Obtido:** o agente responde "Tarefa cadastrada com sucesso" / "Tarefa criada com sucesso no CRM". Nenhuma mensagem do tipo `Confirm` (cartão de confirmação da ação `CriarTarefa`) apareceu e `SELECT ... FROM Task WHERE WhatId=<conta> AND ActivityDate=2026-12-03` voltou 0 linhas. O usuário é induzido a achar que a tarefa existe.
- **Esperado:** o agente só diz "criada" depois de a ação `CriarTarefa` rodar; a Task existe com o rascunho em `Description` e a marca. Nos casos que funcionaram (AC-1), a sequência foi resumo, "sim, confirmo", cartão `Confirm` da ação, nova confirmação, Task criada.
- **Causa provável:** instrução do tópico `acoes_comerciais` deixa o modelo tratar a confirmação de texto como execução, sem chamar a ação (ou a ação só dispara em parte das conversas). Reforçar na instrução: nunca afirmar criação sem retorno de sucesso da ação; chamar `CriarTarefa` assim que o usuário confirmar o resumo.

### FALHA 2 (crítica) — pedido sem data: o assistente afirma ter criado a tarefa "sem data" (AC-5)
- **Reproduzir:** nova sessão; "criar tarefa Ligar para o cliente para TESTE EPLAST-29 Conta Unica"; o agente pergunta a data; responder "sem data"; responder "confirmo"; "sim, confirmo a criação".
- **Obtido:** o agente pergunta a data corretamente nas primeiras mensagens (bom), mas depois de "confirmo" responde "Tarefa criada ... sem data de vencimento definida". Nenhuma Task foi gravada (consulta por assunto = 0; o Flow recusa sem data, como na verificação da dev). Também ocorreu na primeira sessão ("Tarefa de follow-up criada ... sem data definida").
- **Esperado:** continuar pedindo a data e nunca dizer que criou; nenhuma Task parcial. O dado ficou correto (nada gravado), a mensagem ao usuário é falsa.
- **Causa provável:** a mesma da falha 1 (afirmação de sucesso sem retorno da ação).

### FALHA 3 (média) — AC-4 não provado; AC-9 só parcial
- AC-4: na QA só há dois usuários da conta de serviço da Konecta (regra 6; `005bJ00000piKAaQAM` ativo e `005bJ00000hBJmYQAW` inativo), ambos Administrador do sistema; ninguém tem o `PS_Comercial_AssistenteAcoes` (0 atribuições). Não simulei. Para a próxima rodada: usuário `Comercial - Analista` sem o PS (e outro com o PS), com licença de Agentforce.
- AC-9: ver C9; as respostas de leitura não puderam ser comparadas com as da v6.

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | pré-condição | `sf agent activate` v7 e `BotVersion.Status` | v7 Active | v7 Active, demais Inactive (antes: v6 Active) | passou |
| C1 | AC-1 | fixture `account.apex` (Conta Unica, 2 Conta Dup); pedido "criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 2026-12-01" | resumo com assunto, registro, responsável, vencimento; nada gravado antes da confirmação | resumo: Assunto Follow-up, Registro Conta Unica (001Ha000016UyA4IAK), Responsável você, Vencimento 2026-12-01; Task de Follow-up = 0 antes da confirmação; após "sim, confirmo" veio cartão `Confirm` da ação `CriarTarefa_EPLAST29_v7` e, confirmado, 1 Task (00THa00000Bq0qPMAR) | passou |
| C2 | AC-2 | mesmo pedido; resposta "não, cancele" | nada gravado | "Tarefa de follow-up não será criada, conforme solicitado"; Tasks de Follow-up na conta = 0 | passou |
| C3 | AC-3 | "criar tarefa de follow-up para TESTE EPLAST-29 Conta Dup com vencimento em 2026-12-02" | lista os 2 candidatos com Id; não grava | listou 001Ha000016UyA6IAK e 001Ha000016UyA5IAK; nenhuma Task até escolher; ao escolher "a primeira" mostrou novo resumo (sem gravar antes da confirmação); Tasks de Follow-up nas Dup = 0 | passou |
| C4 | AC-4 | pedido por usuário sem o PS | recusa sem vazar dado | só há usuários Administrador | não executado |
| C5 | AC-5 | pedido sem data | pergunta a data; nada parcial | pergunta a data (passou); nenhuma Task gravada (passou); mas afirma "criada sem data" (falhou) | falhou (FALHA 2) |
| C6 | AC-6 | "enviar e-mail de proposta para o contato de ..." | Task com rascunho em `Description` + marca; `EmailMessage` inalterado; informa que o envio é fora do CRM | informa "o e-mail não será enviado pelo CRM, apenas salvo como tarefa" (passou); EmailMessage 805 antes e depois (passou); Task com rascunho: 0 (falhou), agente diz que criou | falhou (FALHA 1) |
| C7 | AC-7 | "criar oportunidade para TESTE EPLAST-29 Conta Unica" | recusa; nada criado | "Não está disponível nesta versão criar ou alterar oportunidades, contas, pedidos..."; Opportunity 9337 antes e depois | passou |
| C8 | AC-8 | Task 00THa00000Bq0qPMAR (C1) | `CreatedById` = quem pediu; marca na descrição | `CreatedById` = `OwnerId` = `005bJ00000piKAaQAM`; `Description` = "Origem: assistente de IA"; `ActivityDate` 2026-12-01; `WhatId` = Conta Unica; Status Open, Priority Normal | passou |
| C9 | AC-9 | "quais clientes precisam de acompanhamento hoje?"; "liste os pedidos da conta TESTE EPLAST-29 Conta Unica" | mesmas respostas da versão anterior | o agente respondeu (pediu carteira/região; "não há pedidos" para a conta de teste). Sem base sintética de pedidos e sem a v6 ativa para comparar | não executado (comparação) |

## O que pode ter saído da org
- Criado por mim: 3 Accounts `TESTE EPLAST-29` (com `TriggerUtility.bypassTrigger = true`, sem callout Protheus), as 3 Tasks automáticas de crédito que a org gera por conta nova, e 1 Task "Follow-up" criada pelo agente. Tudo apagado ao final; conferido: Account `TESTE EPLAST-29%` = 0; Task 8544, EmailMessage 805 e Opportunity 9337, iguais aos de antes.
- Sem e-mail, pedido, chamada externa ou Marketing Cloud.

## Mudanças de usuário/permissão
Nenhuma (sem permission set atribuído a mim, sem valor ou opção alterados). Única mudança de configuração: v7 do `SFAgent2` ativada na QA (v6 estava ativa antes); permanece ativa.
