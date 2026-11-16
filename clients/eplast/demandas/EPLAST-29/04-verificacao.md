**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (Org Id 00DHa000006vfMLMAY, única org em `sf org list`, sandbox, Connected)

# EPLAST-29 · Verificação do build (dev)

## Resumo
O Flow `Task_Agente_CriarTarefa` foi exercitado de verdade na dev e se comportou como o design manda. O comportamento conversacional do agente (resumo, confirmação, recusa, ambiguidade, e as correções da v11) **não foi exercitado**: a v11 está Inactive na dev e eu não ativo versão (é mudança de estado do que o builder construiu). Nenhuma falha encontrada nos casos executados.

## Versões do SFAgent2 na dev (consulta a BotVersion)
- v1 a v7 Inactive, **v8 Active**, v9 e v10 Inactive, **v11 Inactive** (a versão nova desta demanda, correção da rodada 2).
- Confirma o plano: v11 existe e nasceu inativa; o design dizia "v5", a numeração real é outra. O que está ativo na dev é a v8, que não é a versão com as instruções reforçadas da v11.
- Observação sobre o plano: ele abre como rodada 2 de QA e cita falhas da QA; isso vem de rodadas de QA anteriores já arquivadas (`05-testes-rodada-1/2.md`), não é evidência desta verificação. Não herdei o veredito.

## Dados de teste e usuário
- Fixture `fixtures/account.apex` (bypass de trigger, sem Protheus): 1 Account `TESTE EPLAST-29 Conta Unica` e 2 `TESTE EPLAST-29 Conta Dup`. Não há Opportunity de teste nem fixture dela; os casos usaram Account.
- Usuário de execução: 005bJ00000piKAaQAM (Administrador do sistema, ativo). Nada foi alterado nele (sem permission set, sem Marketing User, sem campo Protheus).
- Usuário de teste da regra 6 (conta de serviço Konecta, busca por LIKE no prefixo do username, sem citar o username) na dev: 2 usuários, 005bJ00000hBJmYQAW (inativo) e 005bJ00000piKAaQAM (ativo, é o próprio usuário do job). Ambos administradores; não serve como "usuário sem permissão". Nenhum usuário de `Comercial - Analista` sem o PS foi usado.
- PS `PS_Comercial_AssistenteAcoes`: 0 atribuições na dev.

## Casos executados (Apex anônimo chamando o Flow ativo `Task_Agente_CriarTarefa` com `Flow.Interview`)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 (gravação), AC-8 | Flow com Assunto, vencimento hoje+3, conta única, descrição | Task com ActivityDate informada, WhatId = conta, OwnerId = usuário, descrição com "Origem: assistente de IA" | Sucesso=true; Task com ActivityDate correta, WhatId correto, Owner e CreatedBy = usuário de execução, `TaskSubtype=Task`, Status Open, descrição termina com "Origem: assistente de IA" | passou |
| C2 | AC-5 | Flow sem DataVencimento | Recusa pedindo a data, sem gravar | Sucesso=false, "Informe a data de vencimento da tarefa."; nenhuma Task | passou |
| C3 | AC-5 | Flow sem Assunto | Recusa, sem gravar | Sucesso=false, "Informe o assunto da tarefa." | passou |
| C4 | Check In (design) | Assunto "Check In @ x" | Recusa | Sucesso=false, mensagem de que check-in não é criado pelo assistente | passou |
| C5 | AC-4 (parcial) | Id de Account inexistente | Mensagem genérica, sem vazar dado | Sucesso=false, "Registro nao encontrado ou sem acesso." | passou |
| C6 | AC-7 (parcial) | RegistroRelacionadoId de um User | Recusa: só Account ou Opportunity | Sucesso=false, "...so pode ser ligada a uma conta ou a uma oportunidade." | passou |
| C7 | AC-6 (parcial) | Assunto "Rascunho de e-mail - ...", descrição com texto | Task com texto em Description; nenhum EmailMessage | Sucesso=true; Description com o texto + marca; delta de EmailMessage = 0 | passou |
| C8 | AC-7 | Contagem de Opportunity antes/depois dos casos | Sem criação | delta Opportunity = 0 | passou |

Contagem: o Flow gravou exatamente 2 Tasks (C1 e C7); C2 a C6 não gravaram. Uma Task pré-existente na conta (criada pela automação da própria org ao inserir a Account, assunto de análise de crédito, N0=1) não é do Flow.

## Critérios de aceite sem prova
| AC | Status | Motivo |
|---|---|---|
| AC-1 (resumo antes de gravar, confirmação) | não executado | Depende da conversa com o agente; a v11 está inativa e a v8 ativa não é a versão a testar. `sf agent preview` só roda agente ativo e é interativo. Só a gravação pelo Flow foi provada (C1). |
| AC-2 (recusa do resumo) | não executado | Conversacional. |
| AC-3 (registro ambíguo) | não executado | Conversacional; os 2 `Conta Dup` foram criados, mas o agente não foi acionado. |
| AC-4 (usuário sem permissão) | não executado | Só há administradores na dev; o Flow roda em `DefaultMode` e o contexto de execução pelo agente (R5) segue não provado. C5 prova só a mensagem genérica. |
| AC-5 (pergunta o campo faltante) | parcial | O Flow recusa sem data/assunto sem gravar (C2, C3); a pergunta pelo agente não foi provada. |
| AC-6 (informa que o envio é fora do CRM) | parcial | Rascunho na Task e zero EmailMessage provados (C7); a fala do agente não. |
| AC-7 (recusa de criar Opportunity/Order pelo agente) | parcial | Flow não cria Opportunity (C6, C8); a recusa do agente não foi provada. |
| AC-9 (insights_comerciais com as mesmas ações; respostas iguais) | não executado | Não abri bundles v8/v11 item a item nem conversei com o agente. |

Os defeitos que a QA apontou (agente diz "tarefa criada" sem chamar `CriarTarefa`; "criada sem data") eram comportamento de LLM e a correção está só em instrução da v11. **Segue sem prova** na dev.

## O que fica para uma pessoa provar
1. Ativar a v11 do `SFAgent2` na dev (ou conversar com ela por Agent Builder/preview após ativar) e rodar AC-1 a AC-3, AC-5 a AC-7 e AC-9, em especial: confirmar e ver a ação `CriarTarefa` rodar antes de qualquer "criada"; pedido "sem data" não termina em criação.
2. AC-4: um usuário comum (`Comercial - Analista`) sem o PS e outro com o PS e licença Agentforce; e fechar o risco R5 (contexto do Flow).

## O que pode ter saído da org
Nada: nenhuma chamada externa (Account criada com `TriggerUtility.bypassTrigger = true`; sem e-mail, sem Marketing Cloud, sem Protheus).

## Limpeza
Apagadas as 3 Accounts `TESTE EPLAST-29*` e as Tasks ligadas a elas (consulta final: 0 Accounts e 0 Tasks com `TESTE EPLAST-29`). Nada ficou. Nenhuma metadata alterada, nenhuma versão ativada, nenhum job Apex agendado. A pasta temporária de retrieve do Flow foi descartada.
