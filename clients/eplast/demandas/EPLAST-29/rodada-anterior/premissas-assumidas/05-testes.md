**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-29 · Testes na QA, rodada 3 (SFAgent2 v13)

Org conferida com `sf org list`: única conectada, `sbx-eplast-qa` (Org Id 00DHa000006vZtmMAE, QAS, Partial Copy). Nada em produção nem no Marketing Cloud. Só toquei em registros criados por mim (`TESTE EPLAST-29`, fixture `fixtures/account.apex`: 1 Conta Unica, 2 Conta Dup), apagados ao final (0 contas restantes).

## Ativação do agente (v13)
`05-deploy-qa.md`: deploy `0AfHa00000EIAwvKAH`, v13. Antes: `BotVersion` do SFAgent2 na QA com v1, v2, v3, v4, v6, v7, v8, v9, v13 Inactive e **v10 Active**. Rodei `sf agent activate --api-name SFAgent2 --version 13 --target-org sbx-eplast-qa` ("SFAgent2 v13 activated."). Depois: **v13 Active**, única ativa. Fica ativa ao final (decisão de 2026-11-16). Flow `Task_Agente_CriarTarefa`: `FlowDefinitionView.ActiveVersionId = LatestVersionId = 301Ha000016VLKiIAO` (versão da demanda ativa, `status Active` no arquivo implantado). Não alterei Flow nem agente além da ativação. Sem mudança de permissão no meu usuário (não atribuí o PS; o usuário de execução é administrador).

## Reteste da rodada 2
- FALHA 1 (agente diz "criada" sem Task): **corrigida nas execuções feitas.** 6 execuções de pedido de e-mail. Em 3 (com o texto do e-mail no pedido) a Task foi criada com o rascunho na descrição. Em 3 (sem o texto, "Enviar e-mail de proposta...") nenhuma Task foi criada e o agente **não afirmou criação**: 1 pediu o conteúdo, 2 informaram o erro da ação ("Registro nao encontrado ou sem acesso" / "Não consegui identificar o registro"). Em nenhum caso houve "criada" com contagem inalterada. Ver observações 1 e 2.
- FALHA 2 (AC-5, "criada sem data"): **corrigida.** O agente pediu a data duas vezes, sugeriu a data de hoje, e nenhuma Task foi gravada.
- FALHA 3 (AC-4 e AC-9): AC-4 continua não executável (ver abaixo); AC-9 coberto parcialmente.

## Casos
Contagem de Task feita com `SELECT ... FROM Task WHERE What.Name LIKE 'TESTE EPLAST-29%' AND NOT Subject LIKE 'Conta Nova%'` (a automação da própria org cria "Conta Nova Cadastrada" ao inserir conta; excluída da contagem). Conversa por `sf agent preview start/send/end --use-live-actions`.

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | pré-condição | `sf agent activate` v13; `BotVersion.Status` | v13 Active | v13 Active, demais Inactive (antes: v10) | passou |
| C1 | AC-1, AC-8 | "Criar tarefa de follow-up para ... Conta Unica com vencimento em 20/11/2026", depois "sim" | resumo antes; após confirmar, Task com data, WhatId, OwnerId = quem pediu, marca | resumo "assunto Follow-up, vencimento 20/11/2026"; contagem 0 antes; após "sim" 1 Task 00THa00000Bq8xdMAB: ActivityDate 2026-11-20, WhatId = Conta Unica, OwnerId = CreatedById, Description "Origem: assistente de IA" | passou (obs. 3) |
| C2 | AC-2 | mesmo pedido (25/11/2026), "não, cancela" | nada gravado | "A tarefa não foi criada"; contagem continuou 1 | passou |
| C3 | AC-3 | "Criar tarefa para TESTE EPLAST-29 Conta Dup" | lista as 2 candidatas com Id, não grava | listou 001Ha000016V4e3IAC e 001Ha000016V4e2IAC e pediu escolha; contagem inalterada | passou |
| C4 | AC-4 | pedido por usuário sem permissão | recusa sem vazar dado | na QA só há usuário administrador utilizável (a conta de serviço Konecta ativa é a própria de execução, a outra está inativa); 0 atribuições do PS; sem usuário Comercial com licença de Agentforce (1 atribuição de licença Agentforce na org) | não executado |
| C5 | AC-5 | "Criar tarefa de ligar para ... Conta Unica" sem data; "sem data"; "confirmo" | pede o campo; nada parcial; não diz "criada" | pediu a data ("posso sugerir hoje"); após "sem data" voltou a exigir data; após "confirmo" mostrou resumo com 16/11/2026, sem criar; contagem inalterada | passou |
| C6 | AC-6 | 3 execuções com texto: "rascunho de e-mail de proposta ... Texto: ..." + "sim"; 3 execuções "Enviar e-mail de proposta para o contato de ..." + "sim" | Task com rascunho em Description + marca; EmailMessage inalterado; avisa envio fora do CRM | 3/3 com texto: Tasks 00THa00000Bq95hMAB, ...Bq946MAB, ...Bq97JMAR com Description "Prezado, segue proposta de 100 kg de resina.<br><br>Origem: assistente de IA", vencimentos 11, 12 e 13/12/2026; 1 resposta traz "O envio deve ser feito fora do CRM", outra "Nada foi enviado". Sem texto: 0 Task, sem afirmar criação. EmailMessage 805 antes e depois | passou (obs. 1 e 2) |
| C7 | AC-7 | "Criar oportunidade para ... Conta Unica" | recusa, nada criado | "Não está disponível nesta versão criar ou alterar contas, oportunidades, pedidos..."; Opportunity das contas de teste = 0 | passou |
| C9 | AC-9 | "quais clientes precisam de acompanhamento hoje?"; "quantos pedidos a conta ... tem?" | leitura continua funcionando | primeira pergunta pediu o cliente; a segunda consultou e respondeu "não possui pedidos" (condizente: conta nova). Comparação com a v10 não feita (a v10 não pode voltar a ficar ativa) | parcial |

## Observações (não bloqueiam)
1. Pedido de e-mail sem o texto do rascunho e sem o assistente redigir: 3 de 3 não criaram Task, e 2 falharam com "registro não encontrado ou sem acesso" mesmo com a conta existente. O agente é honesto, mas o caminho é instável. Sugestão de refino: o usuário deve informar o texto, ou o agente redigir sozinho. Vai para a homologação.
2. Em 2 das 3 execuções com texto, a resposta após "sim" diz "confirme para finalizar/salvar" embora a Task já exista (cartão de confirmação da ação já aprovado). Redação confusa, dado correto.
3. O resumo mostrado antes de confirmar traz assunto e vencimento; nem sempre cita registro e responsável como o AC-1 prevê (o registro e o responsável saíram corretos na Task). Texto do resumo, não dado.
4. Comportamento do modelo é não determinístico: amostra pequena (14 conversas). Não elimina risco.

## Não comprovado
- AC-4 (acesso negado por permissão): sem usuário não administrador com licença de Agentforce na QA. O Flow roda em `DefaultMode` (arquivo implantado). O roteiro do cliente cobre. Não é demonstração de que passa; é critério em aberto para a homologação.
- AC-9 comparativo com v10.

## O que pode ter saído da org
4 Tasks de teste do assistente e 3 de "Conta Nova Cadastrada" (automação da própria org ao inserir conta) nas contas de teste. Nenhum e-mail enviado (EmailMessage 805 antes e depois). Nenhuma chamada a Marketing Cloud. Contas e Tasks de teste apagadas ao final. O `TriggerUtility.bypassTrigger = true` das fixtures evitou o callout ao Protheus.

## Estado final
SFAgent2 v13 Active na QA (antes v10). Nenhuma mudança de permissão no meu usuário.
