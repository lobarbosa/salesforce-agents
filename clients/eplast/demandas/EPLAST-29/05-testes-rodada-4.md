**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (eplast--qas, Partial Copy; Id da org 00DHa000006vZtmMAE, Connected em `sf org list`)

# EPLAST-29 · Testes na QA, rodada 4 (SFAgent2 v17 + Flow v5)

Existem `05-testes-rodada-1.md`, `-2.md` e `-3.md` (todas reprovadas). Desta vez a v17 chegou à QA (deploy `0AfHa00000EJYIrKAP`, Succeeded), foi ativada e o agente foi exercitado de verdade por `sf agent preview start/send/end`. Três defeitos das rodadas anteriores continuam.

## Falhas

### FALHA 6 (crítica) — o agente afirma "criado" sem chamar a ação (repete a FALHA 1 da rodada 1)
- Reproduzir: sessão nova do SFAgent2, dizer "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01" (sem data nem texto); o agente pergunta a data; responder "sim, confirmo".
- Obtido (execução 1 de 2): "Rascunho de e-mail de proposta criado como tarefa para o contato REG-TESTE-LEAD-01, com vencimento hoje (17/11/2026)...". Contagem de Task do lead: 3 antes, 3 depois (query `COUNT()` em Task por `WhoId`). Nenhum cartão de confirmação, nenhuma gravação. Na execução 2, o agente pediu a data e mostrou o cartão de confirmação (comportamento correto, sem "criado").
- Esperado: só dizer "criada" quando a ação volta com `Sucesso = true`; "sim" sem resumo é pedido de dados faltantes.
- Causa provável: a instrução do tópico `acoes_comerciais_EPLAST29_v17` não impede a resposta "criado" fora do retorno da ação; o texto de proibição não está pegando quando a conversa só tem a pergunta da data.

### FALHA 7 (média) — o agente monta o cartão sem identificar o registro e a criação falha (não gravou nada)
- Reproduzir: "criar tarefa de revisar contrato para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-05" (com ou sem "sem descrição"); depois "sim, confirmo".
- Obtido (4 de 4 execuções): o cartão `Confirm` traz `RegistroRelacionadoId = "REG-TESTE-LEAD-01"` (o nome, não o Id 00Q...): a ação `IdentificarRegistro` não foi chamada. Após o "sim", a resposta é "não consegui identificar o registro...". Nenhuma Task criada. Em contraste, "criar tarefa de follow-up para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-01" (e 2026-12-06) identificou o lead e gravou (caso A1).
- Esperado: sempre identificar o registro (AC-1 e AC-3) antes de mostrar o cartão; o cartão leva o Id de lead, conta ou oportunidade.
- Causa provável: instrução do tópico deixa o modelo pular a busca quando o pedido já traz nome completo; reforçar "chame `IdentificarRegistro_EPLAST29_v17` antes de `CriarTarefa`, sempre". Efeito: o pedido do cliente (tarefa de lead com a descrição) falha conforme a redação.

### FALHA 8 (branda) — o resumo antes da confirmação não traz registro relacionado nem responsável (repete a FALHA 3)
- Obtido (A1, A12, A6): a mensagem do cartão diz apenas "Você está prestes a criar uma tarefa com assunto 'Follow-up' e data de vencimento em 01/12/2026." (às vezes com descrição). Sem nome e tipo do registro, sem "responsável: você".
- Esperado (AC-1 e design 4.2, item 3): resumo com os quatro itens pedidos pelo cliente (registro e tipo, responsável, descrição ou "sem descrição", prazo) antes de gravar. Em A6/B2 o resumo completo só aparece depois do "sim", junto do "criada".
- Observação: na tela da Lightning o texto antes do cartão pode aparecer diferente; só a homologação pela tela confirma.

### Sem prova (bloqueia o aceite): AC-4 usuário sem permissão
A QA só tem usuários Administrador do sistema (005bJ00000piKAaQAM ativo, 005bJ00000hBJmYQAW inativo); a regra 6 do cliente proíbe alterar perfil ou permissão. O teste rodou como administrador sem `PS_Comercial_AssistenteAcoes` (0 atribuições). Fica para a homologação com usuário comum, com e sem o permission set.

## Retestes da rodada 3
| Falha | Situação |
|---|---|
| FALHA 5 (v17 ausente na QA) | **corrigida**: v17 implantada inativa e ativada nesta sessão |
| FALHA 1 (crítica, "criado" sem a ação) | **não corrigida** (FALHA 6, 1 de 2 execuções) |
| FALHA 2 (média, "sem descrição" gravado) | **corrigida**: Task de B2 com Description só `Origem: assistente de IA`; o resumo mostra "sem descrição" |
| FALHA 3 (branda, resumo incompleto antes do "sim") | **não corrigida** (FALHA 8) |
| AC-4 | não executado (sem usuário comum) |

## Ativações feitas na QA (antes e depois)
- SFAgent2: antes todas as versões Inativas (v10, v13 a v17; v16 era a ativa antes do deploy, desativada pela esteira). `sf agent activate --api-name SFAgent2 --version 17 --target-org sbx-eplast-qa`. Depois: **v17 Active**, v16 Inactive (query `BotVersion`). Fica ativa.
- Flow `Task_Agente_CriarTarefa`: antes v1 a v3 Obsolete, v4 Active, v5 Draft. Reimplantado só esse Flow (`<status>Active</status>`, deploy `0AfHa00000EJTfmKAH`, sem alterar conteúdo). Depois (query Tooling `Flow`): v1 a v4 Obsolete, **v5 Active**. Fica ativa.
- Usuário de execução (005bJ00000piKAaQAM): nenhuma mudança de permissão, papel ou campo; nenhum permission set atribuído.
- Componentes do `05-deploy-qa.md` conferidos: BotVersion v13 e v17, Flow v5, `AssistenteTarefaSetting.Padrao` (Ativo=true, prefixos `001;006;00Q`, descrição obrigatória false, marca `Origem: assistente de IA`) existem. v17 contém as ações de EPLAST-27, 34 e 46 (9 referências no planner).

## Casos executados

Dados: `fixtures/lead.apex` na QA. Já havia leads `REG-TESTE` da rodada 1 (`REG-TESTE-LEAD-01` 00QHa00000T5z5uMAB, 2x `REG-TESTE-DUP`, `REG-TESTE-LEAD-CONV` convertido, contas `REG-TESTE`); a primeira execução da fixture criou um segundo conjunto, que apaguei (leads e contas criados por mim, com `TriggerUtility.bypassTrigger`). Conversas por `sf agent preview start/send/end`. Sem captura de tela: o teste foi por pré-visualização de comando, sem tela de registro a mostrar.

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| A1 | AC-1, AC-8 | "criar tarefa de follow-up para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-01"; "sim, confirmo" | cartão; Task só depois; campos corretos | Task do lead: 0 antes do "sim", 1 depois. Subject Follow-up, ActivityDate 2026-12-01, WhoId = lead, WhatId nulo, OwnerId = CreatedById = 005bJ00000piKAaQAM, Status Open, Description `Origem: assistente de IA` | passou na gravação; resumo incompleto (FALHA 8) |
| A2 | AC-2 | pedir tarefa e responder "não, cancela" | nada gravado | as duas chamadas da sessão falharam com erro da ferramenta (resposta sem corpo); contagem de Task do lead permaneceu 1 (a do A1) | não executado (reexecutar) |
| A3 | AC-3 | "criar tarefa para REG-TESTE-DUP com vencimento em 2026-12-03" | lista candidatos com tipo e Id, nada gravado | lista de 3 (2 leads, 1 cliente, com Id); Tasks `REG-TESTE` 2 antes, 2 depois | passou |
| A4 | AC-4 | usuário sem permissão | recusa sem vazar dado | sem usuário comum | não executado |
| A5 | AC-5 | "criar tarefa de follow-up para o lead REG-TESTE-LEAD-01" (sem data) | pergunta a data; nada gravado | "Qual a data de vencimento desejada?"; Tasks 2 antes, 2 depois | passou |
| A6 | AC-6 | "enviar e-mail de proposta ... vencimento 2026-12-07, texto padrão de proposta comercial"; "sim, pode criar" | Task com rascunho; EmailMessage não muda | EmailMessage 805 antes e 805 depois; Task `Rascunho de e-mail - proposta comercial`, 2026-12-07, Description com o texto e a marca; resposta "nada foi enviado... revise o texto antes de enviar" | passou |
| A6b | AC-6, FALHA 1 | e-mail sem data nem texto; "sim, confirmo" | não afirmar criação | execução 1: "criado" sem Task (3 antes, 3 depois) | FALHA 6 |
| A7 | AC-7 | "criar oportunidade para REG-TESTE-LEAD-01" | recusa | "Não é possível criar ou alterar oportunidades nesta etapa"; oferece só tarefa | passou |
| A8 | AC-8 | Task do A1 | autor = usuário; marca na descrição | conferido na query do A1 | passou |
| A9 | AC-9 | "quantos pedidos abertos temos?"; "qual a próxima ação para a conta REG-TESTE-DUP?"; "quais clientes precisam de acompanhamento hoje?"; "sugira uma campanha..." | ações existentes respondem | "não há pedidos abertos"; "Dados insuficientes: conta sem oportunidades"; pede filtro; campanha: "peça o permission set PS Marketing Sugestão de Campanha" (esperado, usuário sem esse PS). Resumo de reunião (EPLAST-34) não exercitado | passou parcial |
| A10 | lead convertido | tarefa para REG-TESTE-LEAD-CONV | recusa | "Não encontrei nenhum lead com o nome..." (a busca não acha lead convertido; sem gravação). Recusa do Flow provada na dev | passou, sem gravação |
| A11 | outro responsável | "...amanhã, responsável Maria" | recusa | o agente mostrou o cartão de criação (assunto "ligar para o lead", 18/11/2026), sem recusar nem citar a Maria; não confirmei (a Task teria dono = usuário). Na rodada 1 recusou | divergente: tarefa iria para o próprio usuário. Achado, não bloqueia |
| A12 | PA-3 | tarefa "revisar contrato", "sem descrição" | só a marca na descrição | 3 de 3: cartão sem Id e criação falhou (FALHA 7). Reteste com "follow-up" 2026-12-06 (B2): Description só `Origem: assistente de IA` | FALHA 7; PA-3 passou em B2 |
| A13 | Check In | assunto "Check In @ cliente" | recusa | "Não posso criar tarefas com assunto que começa com 'Check In @'" | passou |

Parâmetros do registro de configuração (Ativo=false, descrição obrigatória, tirar prefixo): não exercitados, exigiriam alterar a configuração na QA, e as recusas do Flow para esses casos passaram na dev.

## O que pode ter saído da org
- A cadeia gravou apenas Task (3 sintéticas: Follow-up 2026-12-01, Follow-up 2026-12-06, Rascunho de e-mail), todas apagadas ao final (0 Task no lead). Nenhum e-mail (EmailMessage 805 antes e depois), nenhuma chamada externa, Marketing Cloud intocado, Protheus não acionado (contas criadas com o desvio).
- Permanecem na QA os leads e contas `REG-TESTE` da rodada 1 (limpeza no cabeçalho de `fixtures/lead.apex`).

## Para a próxima rodada
1. Build: corrigir FALHA 6 e FALHA 7 (instrução do tópico: sempre chamar `IdentificarRegistro` antes de `CriarTarefa`; nunca dizer "criado" fora do retorno da ação), e FALHA 8 (texto do resumo com registro, responsável, descrição, prazo). Avaliar recusa de responsável diferente (A11).
2. QA: repetir A2, A6b, A12 e A9 (resumo de reunião) após o novo build.
3. Homologação: AC-4 com usuário comum com e sem o permission set, e o texto do resumo pela tela.
