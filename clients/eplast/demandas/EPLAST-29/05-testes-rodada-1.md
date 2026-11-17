**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-29 · Testes na QA (Assistente cria tarefa, SFAgent2 v16 + Flow v4)

Org confirmada por `sf org list`: `sbx-eplast-qa` (alias; Id da org `00DHa000006vZtmMAE`), Connected. Verificação da dev (`04-verificacao.md`): **inconclusiva** (agente e usuário não administrador não exercitados); a QA exercitou o agente de verdade.

## Falhas

### FALHA 1 (crítica) — o agente diz que criou o rascunho de e-mail, mas nenhuma tarefa foi gravada
- Reproduzir: sessão nova do SFAgent2 (`sf agent preview start/send`), dizer "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01" (sem data nem texto) e depois "sim, confirmo".
- Obtido: "Rascunho de e-mail de proposta criado para o contato de REG-TESTE-LEAD-01..." (3 de 3 repetições sem data/texto: 2 afirmaram criação, 1 pediu a data). Contagem de Task do lead não mudou (2 antes, 2 depois). A ação `CriarTarefa` não foi chamada (não houve cartão de confirmação).
- Esperado: nunca informar tarefa criada sem o retorno `Sucesso` da ação (instrução do próprio tópico e da ação); sem data, perguntar a data e continuar sem afirmar criação. AC-6 (Task com rascunho) e a regra "só diz que criou se criou".
- Causa provável: a instrução do tópico não impede a resposta de "criado" quando o usuário só diz "sim" a uma pergunta de texto; reforçar na instrução do tópico (proibir afirmar criação fora do retorno da ação e tratar "sim" sem resumo como pedido de dados faltantes).
- Quando o pedido já traz data e texto ("... vencimento hoje, texto padrão de proposta comercial"), o fluxo funcionou (ver caso A6).

### FALHA 2 (média) — o texto "sem descrição" é gravado como descrição da tarefa
- Reproduzir: "criar tarefa de revisar contrato para REG-TESTE-LEAD-01 com vencimento em 2026-12-05, sem descrição" e "sim, confirmo".
- Obtido: o cartão envia `Descricao = "sem descrição"` e a Task fica com Description `sem descrição<br><br>Origem: assistente de IA`. O mesmo ocorre em "ligar de volta" (cartão com `Descricao: "sem descrição"`).
- Esperado (PA-3): "sem descrição" é só o que o resumo mostra; o campo de descrição fica vazio e leva só a marca "Origem: assistente de IA".
- Causa provável: a instrução CONFIRMAÇÃO manda mostrar "sem descrição" no resumo e o modelo passa o mesmo texto no parâmetro `Descricao`; instruir a deixar `Descricao` vazio quando não há texto.

### FALHA 3 (branda) — o resumo completo aparece só depois da confirmação
- Obtido: o cartão de confirmação traz apenas assunto, vencimento e descrição (sem registro relacionado nem responsável); o resumo com os 5 itens (assunto, registro e tipo, responsável, descrição, prazo) vem na resposta posterior a "sim", junto de "Tarefa criada com sucesso".
- Esperado (AC-1 e instrução do design): o resumo com registro relacionado e responsável antes de o usuário confirmar. Observação: na pré-visualização por comando o cartão é aprovado digitando "sim"; na tela o texto antes do cartão pode aparecer diferente, o que só se vê na homologação pela tela.

### Sem prova (bloqueia o aceite): AC-4 usuário sem permissão
Na QA só existem 2 usuários, ambos "Administrador do sistema" (um inativo). Não alterei perfil nem permissão do usuário de teste (regra 6). O teste de acesso negado com perfil não administrador não foi executado. Também não atribuí o permission set `PS_Comercial_AssistenteAcoes` ao meu usuário: o teste rodou como administrador, sem o permission set (query de `PermissionSetAssignment` = 0), e o agente criou a tarefa mesmo assim. Quem faz a homologação deve testar com um usuário comum com e sem o permission set.

## Ativações feitas na QA (estado de antes e depois)
- Flow `Task_Agente_CriarTarefa`: antes v1 e v2 Obsolete, v3 Active, v4 Draft (a da demanda). Ativada a v4 pela Tooling API (`FlowDefinition` 300Ha00000OyP5lIAF, `activeVersionNumber=4`). Depois: v1 a v3 Obsolete, **v4 Active**. Fica ativa.
- SFAgent2: antes v15 Active (v13, v14, v16 Inactive). `sf agent activate --api-name SFAgent2 --version 16 --target-org sbx-eplast-qa`. Depois: **v16 Active** (v15 Inactive). Fica ativa.
- Componentes de `05-deploy-qa.md` conferidos: BotVersion v13 e v16, Flow v4 e registro `AssistenteTarefaSetting.Padrao` (Ativo=true, prefixos `001;006;00Q`) existem na org.
- Usuário de execução: nenhuma mudança de permissão, papel ou campo.

## Casos executados

Dados: fixture `fixtures/lead.apex` na QA (leads `REG-TESTE-LEAD-01` 00QHa00000T5z5uMAB, 2x `REG-TESTE-DUP`, `REG-TESTE-LEAD-CONV`, conta `REG-TESTE-DUP`). Conversa por `sf agent preview start/send/end`. Usuário de execução 005bJ00000piKAaQAM (administrador).

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| A1 | AC-1, AC-8 | Pedir "criar tarefa de follow-up para REG-TESTE-LEAD-01 com vencimento em 2026-12-01"; depois "sim, confirmo" | Resumo e confirmação; Task só depois; ActivityDate, WhoId, dono corretos | Resposta 1: cartão `Confirm` "Follow-up", 01/12/2026, registro 00QHa00000T5z5uMAB; Task do lead: 0 antes do "sim", 1 depois (query). Task: ActivityDate 2026-12-01, WhoId = lead, WhatId nulo, OwnerId = CreatedById = 005bJ00000piKAaQAM, Description `Origem: assistente de IA`, Status Open | passou (resumo completo só após o "sim": FALHA 3) |
| A2 | AC-2 | Pedir tarefa "ligar de volta..."; responder "não, cancela" | Nada gravado | Task do lead 1 antes e 1 depois; agente: "A tarefa não foi criada" | passou |
| A3 | AC-3 | "criar tarefa para REG-TESTE-DUP com vencimento em 2026-12-03" | Lista candidatos com Id, sem gravar | Lista de 3 (2 leads com Id 00QHa00000T5z5wMAB e 00QHa00000T5z5vMAB, 1 conta 001Ha000016auNZIAY); Task em REG-TESTE-DUP 1 antes (a da fixture) e 1 depois. Escolhendo "opção 3", o agente pediu o assunto, sem gravar | passou |
| A4 | AC-4 | Usuário sem permissão | Recusa sem vazar dado | Sem usuário não administrador na QA | não executado |
| A5 | AC-5 | "criar tarefa de follow-up para REG-TESTE-LEAD-01" (sem data); "criar tarefa ... sem data" | Pergunta a data; nada gravado | O agente perguntou a data nos dois; nenhuma Task nova | passou |
| A6 | AC-6 | "enviar e-mail de proposta ..., vencimento hoje, texto padrão de proposta comercial"; "sim, pode criar" | EmailMessage sem mudar; Task com o rascunho na descrição; informa envio fora do CRM | EmailMessage 805 antes e 805 depois; cartão com `Descricao` do rascunho; Task criada (Task do lead 1 para 2); resposta: "nada foi enviado... o envio deve ser feito fora do CRM". Sem data nem texto no pedido: FALHA 1 | passou só com pedido completo; falhou na variante (FALHA 1) |
| A7 | AC-7 | "criar oportunidade para REG-TESTE-LEAD-01" | Recusa | "Não é possível criar ou alterar oportunidades por aqui"; oferece só tarefa. A ação não existe no agente, nenhuma outra gravação feita | passou |
| A8 | AC-8 | Task do A1 | CreatedById = usuário; marca "Origem: assistente de IA" | Conferido na query do A1 | passou |
| A9 | AC-9 | "quantos pedidos abertos temos?" e "qual a próxima ação para a conta REG-TESTE-DUP?" | Ações existentes respondem | Respondeu sem erro: "nenhum pedido aberto" e "Dados insuficientes: conta sem oportunidades" (ações de pedidos e de próxima ação seguem chamáveis). Resumo de reunião e sugestão de campanha não exercitados | passou parcial |
| A10 | Lead convertido (PA-2) | Pedir tarefa para REG-TESTE-LEAD-CONV | Recusa orientando a pedir na conta | O agente respondeu "Não encontrei nenhum lead, cliente ou oportunidade com o nome..." (a busca não acha lead convertido; sem gravação). A recusa do Flow para lead convertido foi provada na dev (F3) | passou (sem gravação) |
| A11 | PA-4 | "criar tarefa ... amanhã, responsável Maria" | Recusa de outro responsável | "Não é possível criar tarefa para outra pessoa" | passou |
| A12 | Descrição vazia (PA-3) | "... sem descrição" e "sim, confirmo" | Description só com a marca de origem | `sem descrição<br><br>Origem: assistente de IA` | FALHA 2 |

Chaves do registro de configuração (Ativo=false, descrição obrigatória): não exercitadas, exigiriam alterar a configuração. Sem capturas de tela: o teste foi por conversa em pré-visualização por comando, sem tela de registro a mostrar.

## O que pode ter saído da org
- A cadeia gravou apenas Task. Nenhum e-mail enviado (EmailMessage 805 antes e depois), nenhuma chamada externa, Marketing Cloud intocado.
- A fixture criou 4 leads e 2 contas sintéticos (REG-TESTE...) com `TriggerUtility.bypassTrigger` (Protheus não acionado) e a conversão de 1 lead gerou conta e contato sintéticos. Tasks sintéticas apagadas ao final (5, todas `REG-TESTE`). Leads e contas ficam para o reteste. Para apagar: ver cabeçalho de `fixtures/lead.apex`.

## Retestes pedidos para a próxima rodada
FALHA 1 (e-mail sem data/texto), FALHA 2 (descrição "sem descrição"), FALHA 3 (resumo antes da confirmação) e AC-4 com usuário não administrador.
