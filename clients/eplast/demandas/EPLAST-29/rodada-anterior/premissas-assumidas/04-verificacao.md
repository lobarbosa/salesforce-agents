**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (sandbox, org 00DHa000006vfMLMAY, única conectada em `sf org list`)

# EPLAST-29 · Verificação do build (SFAgent2 v13), rodada 2

Método: `sf agent preview start/send/end --use-live-actions` com o `SFAgent2` publicado (v13 Active, única ativa; v12 Inactive, conferido por `BotVersion`). Dados: `fixtures/account.apex` (1 conta `TESTE EPLAST-29 Conta Unica`, 2 `TESTE EPLAST-29 Conta Dup`). Contagem de Task feita só sobre as contas de teste, excluindo as Tasks "Conta Nova Cadastrada" que a automação da própria org cria ao inserir conta.

Por que inconclusiva: a falha da rodada 1 (FALHA 1) foi corrigida e todos os casos executáveis passaram, mas AC-4 não pôde ser exercitado e AC-9 só parcialmente (ver "O que ficou sem prova"). Não há caso executado que tenha falhado.

## Reteste da rodada anterior
- **FALHA 1 (agente diz "tarefa criada" sem chamar `CriarTarefa`): corrigida nas execuções feitas.** Cenário de e-mail com data no 1º turno, 6 execuções (3 com "Enviar e-mail de proposta...", 3 com "Preciso enviar um e-mail..."), mais 1 follow-up e 1 caso de check-in. Em nenhuma o agente disse "criada" sem `CriarTarefa`; sempre que disse, o resultado trouxe `CriarTarefa_EPLAST29_v13` com "Tarefa criada com sucesso." e a contagem subiu. Em 1 execução o agente não avançou e pediu detalhes do e-mail, sem criar nem afirmar criação (contagem não mudou). Em 1 execução a Task foi criada e a mensagem de "sim" veio sem a ação no `result` daquela mensagem, mas a contagem subiu (5 para 6) e o texto não afirma falsamente. Como o comportamento é não determinístico, 7 execuções reduzem o risco, mas não o eliminam.
- Observação anterior (o "sim" tratado como pedido de alteração): não reproduzida em 7 execuções.

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 e AC-8 | "Criar tarefa de follow-up para ... Conta Unica com vencimento em 20/11/2026", depois "sim" | Resumo, só cria após confirmação; ActivityDate, WhatId e OwnerId corretos; marca de origem | Resumo "prestes a criar... Follow-up... 20/11/2026"; após "sim" 1 Task: ActivityDate 2026-11-20, WhatId = conta de teste, OwnerId = CreatedById = 005bJ00000piKAaQAM, Description "Origem: assistente de IA" | passou |
| C2 | AC-2 | Mesmo pedido (25/11/2026), depois "não, cancela" | Nada gravado | "Tarefa cancelada, nenhuma ação foi realizada"; contagem inalterada | passou |
| C3 | AC-3 | "Criar tarefa para TESTE EPLAST-29 Conta Dup" | Lista as duas candidatas, não grava | Listou as duas com Id e pediu a escolha; contagem inalterada | passou |
| C4 | AC-4 | Não executado: único usuário utilizável é administrador, o outro (da Konecta) está inativo | Recusa por permissão sem vazar dado | Sem caso de acesso negado real | não executado |
| C5 | AC-5 | "Criar tarefa de ligar para ... Conta Unica" (sem data), depois "sem data" | Pede o campo, nada parcial | Perguntou a data e sugeriu hoje. Após "sem data" disse que "será criada sem data de vencimento" e ofereceu observação, sem chamar a ação; nenhuma Task gravada | passou (ver observação 1) |
| C6 | AC-6 | 6 execuções de pedido de e-mail com vencimento e "sim" | Task com rascunho na descrição, EmailMessage não muda, informa envio fora do CRM, só diz "criada" após `Sucesso` | 5 execuções: Task criada com rascunho na Description e "Origem: assistente de IA", aviso de que o envio é fora do CRM, ação com Sucesso. 1 execução sem avanço (pediu detalhes), sem criar. EmailMessage criadas hoje: 0 | passou |
| C7 | AC-7 | "Criar oportunidade para ... Conta Unica" | Recusa | "Não é possível criar ou alterar oportunidades nesta versão"; Opportunity e Order criadas hoje: 0 | passou |
| C8 | Regra `Check In @` | Assunto "Check In @ visita" e "sim" | Recusa | A ação voltou com recusa ("Nao e possivel criar tarefa de check-in pelo assistente"), nada gravado | passou |
| C9 | "sim" solto sem ação chamada | "sim, confirmo a criação da tarefa" numa sessão nova | Não cria nem afirma | Pediu assunto, registro e data; nada gravado | passou |
| C10 | AC-9 (parcial) | Perguntas "quais clientes precisam de acompanhamento hoje?" e "quantos pedidos existem no total?"; conferência do bundle `SFAgent2_v13` na branch | Sem erro; `insights_comerciais` com as ações existentes | Sem erro de licença ou de execução: o agente pediu critério na 1ª e disse não achar a tabela de pedidos na 2ª. Bundle v13 tem as 6 ações do tópico (`AgregacaoPedidos`, `IdentificarConta`, `ConsultarPedidos`, `ProximaAcaoCliente` EPLAST-27, `ResumoReuniao` EPLAST-34, `SugestaoCampanha` EPLAST-46). Não comparado com a versão anterior | não executado (parcial) |
| C11 | R9 licença Agentforce | Todas as sessões de preview | Sem erro de licença | Sem erro em todas as sessões | passou |

## Observações (não bloqueantes)
1. Em C5 a resposta "será criada sem data de vencimento" sugere que a criação seguiria sem data, enquanto o design manda sugerir uma data e continuar pedindo. Nada foi gravado e o agente não disse que criou, então não é falha de AC-5; vale revisar o texto da instrução `DATA`.
2. Em C10, "quantos pedidos existem no total?" respondeu que não localizou a tabela de pedidos. Pode ser falta de pedidos sintéticos na dev; não foi investigado nem comparado com a versão anterior.

## O que pode ter saído da org
Nenhum e-mail ou mensagem (EmailMessage criadas hoje: 0). Nenhuma chamada externa: a cadeia só grava Task, e o `TriggerUtility.bypassTrigger` da fixture evitou o callout do Protheus. Nada no Marketing Cloud, nada na QA.

## Mudanças temporárias no usuário de execução (005bJ00000piKAaQAM) e limpeza
- Atribuído o PS `PS_Comercial_AssistenteAcoes` (antes: sem atribuição). Removido ao final (contagem de atribuições do PS: 0). Nenhum outro campo, perfil ou papel foi alterado, e a opção Marketing User não foi tocada.
- Dados de teste: 3 contas `TESTE EPLAST-29` e as Tasks ligadas (6 criadas pelo agente e 3 da automação) apagadas. Contagem final de contas TESTE: 0. Nada ficou.

## O que ficou sem prova
- **AC-4 (acesso negado):** não há na dev usuário ativo e não administrador. Para provar, uma pessoa precisa fornecer na dev (ou na QA) um usuário ativo com acesso ao agente e sem permissão de criar Task, ou ativar o usuário de teste da Konecta com perfil não administrador.
- **AC-9:** comparação das respostas com a versão anterior na mesma base sintética, e execução de `ConsultarPedidos` com dado. Só foi conferido que o bundle mantém as 6 ações e que as perguntas respondem sem erro.
- Leitura do bundle: feita no arquivo da branch, não baixado de novo da org. O comportamento do agente foi conferido na execução, na v13 ativa.
