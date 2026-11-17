**Verificação:** reprovada
**Org de teste:** sbx-eplast-dev

# EPLAST-29 · Verificação do build (dev)

`sf org list` mostrou só `sbx-eplast-dev` (sandbox, 00DHa000006vfMLMAY, Connected). Nada tocado em QA, produção ou Marketing Cloud. Só dado sintético; nenhum registro real lido.

## Versões e estados encontrados na org (resolve a divergência título × relato)
- `SFAgent2`: v1 a v17 existem. Antes: v13 Active, v14 a v17 Inactive. v16 e v17 são desta demanda (v17 é a correção das rodadas 1 a 3; a v16 do título do plano é a versão da primeira construção). O título "rodada 4: Flow v2 e v16" está desatualizado: o que vale é a v17.
- Flow `Task_Agente_CriarTarefa`: v1 Active (versão antiga, só conta e oportunidade); v2 estava **Obsolete** (o conteúdo da v2 no repositório e na org tem lead, custom metadata e demais guardas).
- Ativações feitas por mim, necessidade declarada em "Versões e ativação" e "Para a verificação na dev" do plano: Flow v2 (via FlowDefinition) e `SFAgent2` v17 (`sf agent activate`). **Revertidas ao final:** Flow v1 Active (v2 Obsolete de novo), `SFAgent2` v13 Active, v14 a v17 Inactive (conferido por query).
- Usuário de execução: usuário de teste da regra 6 (Id 005bJ00000piKAaQAM), perfil Administrador do sistema. Nada alterado nele (perfil, papel, permission sets, Marketing User). Existe também o Id 005bJ00000hBJmYQAW, inativo.

## Dados usados
Leads e contas sintéticos já existentes da `fixtures/lead.apex` (`REG-TESTE-LEAD-01`, 2x `REG-TESTE-DUP`, `REG-TESTE-LEAD-CONV` convertido, conta `REG-TESTE-DUP`); não os recriei nem alterei. Tarefas que criei: 2, apagadas (contagem final de Task `TESTE EPLAST-29%` = 0). Uma transação por chamada do Flow (8 execuções de Apex anônimo separadas).

## Flow v2 (Apex anônimo, `Flow.Interview`, 1 por execução)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| F1 | Tarefa para lead (WhoId) | Lead `REG-TESTE-LEAD-01`, data +3, descrição, prioridade High | Task com WhoId, WhatId vazio, Open, dono = usuário, marca de origem | Sucesso=true; Task com WhoId do lead, WhatId nulo, High, Open, Owner 005bJ…KAa, Task, descrição "desc teste" + "Origem: assistente de IA" | passou |
| F2 | Tarefa para conta + prioridade inválida | Conta `REG-TESTE-DUP`, prioridade "xyz", sem descrição | WhatId = conta, prioridade padrão Normal | Sucesso=true; WhatId da conta, Normal, descrição só "Origem: assistente de IA" | passou |
| F3 | Lead convertido recusado | `REG-TESTE-LEAD-CONV` | Recusa orientando pedir na conta/oportunidade | Sucesso=false, "Este lead ja foi convertido. Peca a tarefa na conta ou na oportunidade dele." | passou |
| F4 | Prefixo fora do permitido | Id com prefixo 003 | Recusa | Sucesso=false, "So e possivel criar tarefa ligada a lead, cliente (conta) ou oportunidade..." | passou |
| F5 | Assunto vazio | assunto '' | Recusa | "Informe o assunto da tarefa." | passou |
| F6 | `Check In @` | assunto "Check In @ teste" | Recusa | "Nao e possivel criar tarefa de check-in pelo assistente..." | passou |
| F7 | Data vazia | data null | Recusa | "Informe a data de vencimento da tarefa." | passou |
| F8 | Lead inexistente | Id 00Q inexistente | Mensagem genérica, sem DML | "Registro nao encontrado ou sem acesso." | passou |

Não exercitado no Flow: oportunidade (006) e `DescricaoObrigatoria__c` = true / `Ativo__c` = false (alterar o custom metadata seria mexer no que o build construiu).

## Agente SFAgent2 v17 (`sf agent test`, definição de teste temporária; resposta do modelo, 1 turno por caso)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| A1 | R3: busca padrão `identifyRecordByName` aceita Lead | "Crie uma tarefa para o lead REG-TESTE-LEAD-01 ..." | Tópico `acoes_comerciais`, ação `IdentificarRegistro` acha o lead | Execução 1: ação `IdentificarRegistro_EPLAST29_v17` chamada e o resumo traz "REG-TESTE-LEAD-01 (lead)". Execução 2: tópico certo, mas nenhuma ação registrada (`[]`), embora o resumo cite o lead | passou na execução 1, instável na 2 |
| A2 | FALHA 3: resumo completo antes da ação | mesmo pedido | Resumo com assunto, registro e tipo, responsável, descrição, prazo | Resumo completo: assunto, registro (lead), "você", "sem descrição", prazo 2026-11-20. Nas duas execuções fechou com "Vou prosseguir/criar a tarefa agora", sem afirmar que já criou; nenhuma Task foi gravada pelo agente | passou (a confirmação final por cartão da ação não é visível em 1 turno) |
| A3 | FALHA 1 e 2 (criado sem ação; "sem descrição" gravado) | só 1 turno; nenhuma Task criada | Sem afirmar criação sem a ação | Nenhuma Task gravada; o texto "sem descrição" só no resumo. Reteste com "sim" em turno 2 e a descrição gravada não foi possível (teste de 1 turno) | não executado |
| A4 | Ambiguidade: dois leads com mesmo nome | "Crie uma tarefa TESTE EPLAST-29 retorno para REG-TESTE-DUP amanha" | Lista de candidatos com nome, tipo e identificador e pede escolha | Tópico certo, `IdentificarRegistro` chamada 3 vezes, mas a resposta final foi "Hi, I'm an AI assistant. How can I help you?", sem lista. Repetiu nas 2 execuções | falhou |

## Falhas
### FALHA 1 — v17 não lista candidatos quando o nome é ambíguo
Como reproduzir: dev com v17 ativa, fixture `lead.apex` (2 leads e 1 conta `REG-TESTE-DUP`), `sf agent test` com o pedido "Crie uma tarefa TESTE EPLAST-29 retorno para REG-TESTE-DUP amanha". Obtido (2 de 2 execuções): três chamadas de `IdentificarRegistro` e resposta genérica de saudação, sem lista. Esperado: lista com nome, tipo e identificador (instrução da v16/v17). Causa provável: o agente chama a busca em loop e cai na resposta padrão; pode ser instrução da v17 ou limite de chamadas por turno. Não confirmado no chat da tela (o teste é de 1 turno); recomendo o builder revisar a instrução de ambiguidade e o QA reconferir pela tela.

## Sem prova (não executado)
- R4 (Flow em contexto de usuário não administrador): só existe o usuário de execução, Administrador, e a regra 6 proíbe mudar perfil. Inconclusivo declarado, vai para a homologação (usuário comum com e sem `PS_Comercial_AssistenteAcoes`).
- Q-12 e Q-13 (ações de EPLAST-27, 34 e 46 na v17 em uso): não exercitadas.
- FALHAS 1 e 2 das rodadas anteriores (reteste com "sim" em dois turnos e descrição gravada pelo agente): não executadas, `sf agent test` só faz 1 turno e `sf agent preview` é interativo.
- Resposta do modelo é não determinística: A1 divergiu entre duas execuções.

## O que pode ter saído da org
Nada externo: o Flow só grava Task; nenhum e-mail, Protheus ou Marketing Cloud (leads e conta criados antes pela fixture com `bypassTrigger`).

## Resíduos
- Definição de teste `TESTE_EPLAST29_Verif` (AiEvaluationDefinition) ficou deployada na dev; o deploy destrutivo não está disponível nesta versão de API e não consegui confirmar a remoção. É metadata inerte, não faz parte do build; arquivo local removido (a branch não foi alterada). Apagar pela tela do Testing Center.
- Leads e contas da fixture continuam na dev (reuso). Apagar com o comando do cabeçalho de `fixtures/lead.apex`.
