**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-29 · Verificação do build (rodada 5: SFAgent2 v18, PrepararTarefa, CriarTarefa v3)

`sf org list`: só `sbx-eplast-dev` (sandbox, 00DHa000006vfMLMAY, Connected). Nada em QA, produção ou Marketing Cloud. Só dado sintético (`REG-TESTE-*` e `TESTE EPLAST-29 *`). Usuário de execução e dono das tarefas: `005bJ00000piKAaQAM` (ativo, Administrador do sistema); nada alterado nele (perfil, papel, PS, Marketing User). Existe também `005bJ00000hBJmYQAW`, inativo.

## Como foi exercitado
`sf agent preview start/send/end` (CLI 2.158.7), agente publicado `SFAgent2`, ações reais, **uma sessão nova por execução**. Os traces em `.sfdx/agents/` mostram cada chamada de ação. Task conferida por `COUNT()` e por Id (só registros de teste).

Ativado na dev só para a verificação (ordem do plano): `Task_Agente_PrepararTarefa` v1, `Task_Agente_CriarTarefa` v3 (via FlowDefinition, Tooling API) e `SFAgent2` v18 (`sf agent activate --version 18`). **Revertido ao final e conferido por query:** `CriarTarefa` v1 Active, `PrepararTarefa` sem versão ativa, `SFAgent2` v13 Active e v14 a v18 Inactive.

## Resultado por caso
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| Q-2 (identificação) | Diretriz 1: identificar antes do cartão | "criar tarefa de revisar contrato para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-05"; 5 sessões + trace da 1ª | `IdentificarRegistro` e `PrepararTarefa` antes do cartão; cartão com Id `00Q` | Trace: `IdentificarRegistro` (success) → `PrepararTarefa` (`Pronto=true`) → `CriarTarefa` com `RegistroRelacionadoId` `00Q…`. Cartão com Id lead nas 5 | passou (5/5, 1 redação). As outras 2 redações do design (lembrete e follow-up) só foram feitas como Q-3 (5/5) |
| Q-2 (criação) | Criada só com sucesso da ação; texto e `Código da tarefa` | Mesmas 5 sessões, "sim" no 2º turno | +1 Task e mensagem com código | 5 Tasks novas (conferido por contagem); 5 de 5 com `Tarefa criada: "…" para … (lead), prazo 05/12/2026, responsável: você.` e `Código da tarefa: 00TH…`. O "sim" no chat confirmou o cartão (a plataforma tratou como aceite) | passou (5/5) |
| Q-4 / diretriz 3 | Resumo completo antes da confirmação | Mesmas sessões; leitura das mensagens do turno 1 e do trace | Os 5 itens do `Resumo` (assunto, registro e tipo, "você", descrição ou "sem descrição", prazo) visíveis antes de confirmar | **Não aparece.** `PrepararTarefa` devolve o `Resumo` correto, mas o modelo chama `CriarTarefa` no mesmo passo com texto vazio; a mensagem do cartão é uma legenda de uma frase gerada pela plataforma ("Você está prestes a criar uma tarefa com o assunto … e vencimento …"), sem registro/tipo, responsável nem descrição. 0 de 5 mostraram o resumo antes do cartão. Em 3 de 5 a legenda saiu em inglês | **falhou (0/5)** |
| Q-2 (coerência) | Resposta pós-"sim" sem contradição | Idem | Só a mensagem de sucesso | Em 2 de 5 (runs 1 e 5) a resposta após o aceite traz o `Resumo` ("Nada foi criado ainda. A tarefa só é gravada depois que você aprovar") **seguido** de "Tarefa criada … Código da tarefa". Texto contraditório; Task criada de verdade | falhou (2/5) |
| Q-1* | Pedido sem data, depois "sim, confirmo" | "enviar e-mail de proposta para o lead REG-TESTE-LEAD-01" + "sim, confirmo"; 5 sessões (+1 antes) | Diz que falta o prazo e que nada foi criado; Task inalterada | Nenhuma Task criada e nenhuma afirmação falsa de criação (5/5, contagem inalterada). Mas o agente pergunta a data no 1º turno e, após "sim", em 3 de 5 apresenta cartão com a data inventada de hoje (17/11/2026), uma delas com descrição inventada e em inglês; nas outras 2 responde "Vou criar uma tarefa…" sem cartão nem recusa. Nunca declara "nada foi criado" | falhou (critério literal; sem dano: 0 Task) |
| Q-3* | Recusa do resumo | "lembrete para ligar para o lead REG-TESTE-LEAD-01 dia 2026-12-10" + "não, cancela"; 5 sessões | Nenhuma Task | 5/5 cancelado ("a tarefa não foi criada"), 0 Task | passou (5/5) |
| Q-5 | Ambiguidade (FALHA 1 da rodada anterior) | "…para o lead REG-TESTE-DUP…"; 3 sessões | Lista com tipo e Id; nada gravado | 3/3 lista de 2 leads com tipo e Id; 0 Task. **FALHA 1 da rodada anterior: corrigida** | passou (3/3) |
| Q-6 | Lead convertido | "…lead REG-TESTE-LEAD-CONV…"; 2 sessões | Recusa; nada gravado | 2/2 "não encontrei nenhum lead"; 0 Task | passou (2/2) |
| Q-7 | Conta (regressão) | "criar tarefa de enviar contrato para a conta TESTE EPLAST-29 Conta Unica…" + "sim" | `WhatId` e mensagem com código | 1ª tentativa: conta não localizada (conta recém-criada; provável atraso de índice de busca, não confirmado). 2ª: cartão, "sim", `Tarefa criada … (cliente) … Código da tarefa: 00TH…`, 1 Task | passou (1 de 2 tentativas; não repetido 5x) |
| Q-9 | Descrição "sem descrição" (FALHA 2 não volta) | Pedido com "descrição: sem descrição" + "sim" | `Description` só com a marca de origem | Task com `Description = "Origem: assistente de IA"` | passou (1/1) |
| Q-10 | `Check In @` | "criar tarefa Check In @ visita para o lead…" | Recusa; nada gravado | "Não é possível criar tarefa de check-in… Nada foi criado." | passou (1/1) |
| Q-8, Q-11, Q-13 | Rascunho de e-mail, parâmetros do custom metadata, regressão de 27/34/46 | Não exercitados | | | não executado |
| Q-12 / AC-4 | Usuário comum sem PS | Só há administradores; regra da conta proíbe mudar perfil | | | não executado (vai à homologação) |

## Falhas

### FALHA 1 — O resumo completo não chega ao usuário antes da confirmação (diretriz 3, Q-4)
Reproduzir: ativar Flows e v18 na dev; `sf agent preview start -n SFAgent2`; enviar "criar tarefa de revisar contrato para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-05". Obtido (5/5): uma mensagem `Confirm` com legenda de uma frase ("Você está prestes a criar uma tarefa com o assunto "revisar contrato" e vencimento em 05/12/2026."), sem registro e tipo, responsável nem descrição ou "sem descrição". Esperado: os 5 itens do `Resumo` antes do cartão. Evidência de causa (trace, passos 16 a 20): `PrepararTarefa` retorna `Pronto=true` e `Resumo` correto; o passo seguinte do modelo tem `content` vazio e já chama `CriarTarefa`; a plataforma então gera a legenda do cartão com um prompt próprio ("one-sentence caption that introduces a confirmation prompt") e descarta o texto. Ou seja: a sequência "repetir o `Resumo` e, na mesma resposta, chamar `CriarTarefa`" (design 4.3, 1d) não funciona, porque uma ação com `isConfirmationRequired = true` suprime a mensagem do modelo. O texto do `Resumo` só apareceu em 2 de 5 execuções, depois do aceite e ao lado de "Tarefa criada" (contraditório). O plano já previa a alternativa D (variáveis e filtro de ação) para este caso, a levar ao arquiteto humano. Alternativa a avaliar: tirar `isConfirmationRequired` de `CriarTarefa` e fazer o assistente exibir o `Resumo` e esperar a resposta do usuário (a confirmação deixa de ser o cartão nativo, o que contraria a decisão de design); ou colocar o resumo nos próprios campos que o cartão mostra (ex.: entradas da ação).

### FALHA 2 — Q-1: após "sim" o agente monta cartão com data inventada em vez de recusar por falta de prazo
Obtido: em 3 de 5 execuções o agente, ao receber "sim, confirmo" para a pergunta sobre a data, propôs cartão com vencimento hoje (inclusive com descrição inventada e em inglês na run 3); em 2 de 5 respondeu "Vou criar uma tarefa…" sem chamar ação. Em nenhuma disse "nada foi criado". Nenhuma Task foi gravada em nenhuma execução e nenhum "criada" falso apareceu (o critério mais grave do design está atendido). Esperado: dizer que falta o prazo e que nada foi criado. Observação: o agente havia oferecido "hoje" no 1º turno, então o "sim" pode ser lido como aceite da data; cabe ao arquiteto decidir se isso é aceitável ou se o Flow deve exigir a data explícita.

## Retestes de rodada anterior
- FALHA 1 da rodada 1 (ambiguidade sem lista): corrigida na v18, 3 de 3.
- FALHA 2 ("sem descrição" gravado): não voltou (Q-9, 1 de 1).
- "Criada" sem tarefa real: não ocorreu em nenhuma das 28 sessões; toda mensagem `Tarefa criada` veio com `Código da tarefa` e Task correspondente (5+1+1+1 conferidas por contagem/Id).

## Sem prova
Q-8 (rascunho), Q-11 (parâmetros), Q-13 (regressão de 27, 34 e 46 e consulta de pedidos), AC-4 (usuário comum) e 5 de 5 nas redações "lembrete" e "follow-up" de Q-2 e em Q-7. A saída do modelo varia entre execuções (idioma da legenda, presença do resumo).

## O que pode ter saído da org
Nada externo. Tarefas e leads/contas por fixture com `TriggerUtility.bypassTrigger`; sem e-mail, Protheus ou Marketing Cloud. Uma Task automática de "ANEXAR" nasce na criação de conta (automação da org, não do agente); apagada junto.

## Resíduos e limpeza
- Apagados: todas as Tasks de teste (de `REG-TESTE-*` e `TESTE EPLAST-29*`), as 3 contas `TESTE EPLAST-29 *` criadas por mim e a segunda cópia dos leads e da conta `REG-TESTE-*` que o `lead.apex` duplicou (rodei a fixture sem notar que já havia a execução anterior).
- Ficaram: leads `REG-TESTE-LEAD-01`, 2x `REG-TESTE-DUP`, `REG-TESTE-LEAD-CONV` e contas `REG-TESTE-*` da fixture anterior (reuso). Apagar com o cabeçalho de `fixtures/lead.apex`.
- Sessões de preview encerradas; traces locais em `.sfdx/agents/` (descartáveis).
