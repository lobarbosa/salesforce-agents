**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (00DHa000006vfMLMAY)

# EPLAST-29 · Verificação (rodada 4: Flow v2 e SFAgent2 v16)

## Resumo
O Flow `Task_Agente_CriarTarefa` v2 foi exercitado de verdade na dev (8 chamadas) e todos os casos passaram. A parte do agente (SFAgent2 v16: busca de Lead, conversa, resumo de confirmação) e o usuário não administrador (R4) não puderam ser exercitados. Por isso a verificação é inconclusiva, não reprovada: nenhum caso executado falhou.

## Alterações de estado na dev (registro e restauração)
- Antes: Flow v1 Active, v2 Draft; SFAgent2 v13 Active, v14 a v16 Inactive.
- Ativei a v2 do Flow (Tooling API, `FlowDefinition` 300Ha00000OxgbiIAB, `activeVersionNumber=2`). A v1 virou Obsolete. Chamei o Flow pelo endpoint REST `actions/custom/flow` (sem Apex anônimo).
- Ao final reativei a v1: v1 Active, v2 **Obsolete** (não voltou a Draft; a plataforma não permite). A v2 continua implantável e ativável. A ativação da v2 segue como passo separado, como diz o plano.
- SFAgent2 não foi alterado (v13 Active, v16 Inactive). Nada em QA, produção ou Marketing Cloud.
- Dados: as 2 Tasks criadas no teste foram apagadas (contagem de Task `REG-TESTE%` = 0). Ficam os dados sintéticos da fixture `lead.apex` (4 leads `REG-TESTE%`, contas `REG-TESTE-DUP` e `REG-TESTE Empresa Conv`), para a próxima etapa.

## Casos executados (Flow v2, usuário de execução 005bJ00000piKAaQAM, administrador)
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| F1 | AC-1, AC-8 (lead) | Flow com Id do lead `REG-TESTE-LEAD-01`, data 2026-12-01, descrição, prioridade High | Task com WhoId = lead, WhatId vazio, dono = usuário, Open, marca de origem | Sucesso=true; Task com Priority High, Open, ActivityDate 2026-12-01, OwnerId = CreatedById = 005bJ00000piKAaQAM, WhoId = lead, WhatId nulo, Description "rascunho" + "Origem: assistente de IA" | passou |
| F2 | AC-1, AC-8 (conta) e prioridade inválida | Flow com Id da conta `REG-TESTE-DUP`, prioridade "xyz", sem descrição | WhatId = conta, prioridade vira Normal, marca na descrição | Sucesso=true; Priority Normal, WhatId = conta, WhoId nulo, Description "Origem: assistente de IA" | passou |
| F3 | Lead convertido | Flow com `REG-TESTE-LEAD-CONV` (IsConverted=true) | Recusa orientando pedir na conta ou oportunidade, sem Task | Sucesso=false; "Este lead já foi convertido. Peça a tarefa na conta ou na oportunidade dele." | passou |
| F4 | AC-5 (assunto vazio) | Assunto vazio | Recusa, sem Task | Sucesso=false; "Informe o assunto da tarefa." | passou |
| F5 | AC-7 / regra Check In | Assunto "Check In @ x" | Recusa | Sucesso=false; mensagem de check-in não permitido pelo assistente | passou |
| F6 | Prefixo não permitido | Id de usuário (005) como registro | Recusa por prefixo | Sucesso=false; "Só é possível criar tarefa ligada a lead, cliente (conta) ou oportunidade..." | passou |
| F7 | AC-5 (data vazia) | Sem data de vencimento | Recusa, sem Task | Sucesso=false; "Informe a data de vencimento da tarefa." | passou |
| F8 | AC-4 parcial (sem acesso/inexistente) | Id de lead inexistente | Mensagem genérica, sem vazar dado | Sucesso=false; "Registro não encontrado ou sem acesso." | passou |

Prova da leitura do custom metadata: com `AssistenteTarefaSetting.Padrao` (Ativo, prefixos `001;006;00Q`, prioridade Normal, marca "Origem: assistente de IA"), os casos F1 e F2 aplicaram prefixo, prioridade padrão e marca. Contagem final: nenhuma Task `REG-TESTE%` restante. Nenhuma Task foi criada nos casos de recusa (F3 a F8, TarefaId nulo).

## Critérios de aceite do 01-analise.md
| Critério | Resultado | Evidência / o que falta |
|---|---|---|
| AC-1 criar com confirmação | Parcial: parte do Flow passou (F1, F2); resumo e confirmação do agente sem prova | Resumo e N antes/depois dependem de conversa com o agente |
| AC-2 recusa do resumo não grava | Sem prova | Só ocorre na conversa com o agente |
| AC-3 ambiguidade (REG-TESTE-DUP) | Sem prova | Dois leads e uma conta `REG-TESTE-DUP` existem, mas a listagem é da busca do agente (R3) |
| AC-4 sem permissão | Sem prova (R4) | Só há usuários administradores na dev (005bJ00000hBJmYQAW inativo, 005bJ00000piKAaQAM ativo, ambos Administrador do sistema). Não alterei perfil nem permissão. F8 cobre só "não encontrado" |
| AC-5 campo obrigatório | Flow passou (F4, F7); pergunta do campo pelo agente sem prova | |
| AC-6 e-mail não enviado, rascunho na descrição | Descrição gravada pelo Flow (F1); comportamento do agente sem prova | Não testado contagem de EmailMessage |
| AC-7 fora do escopo | Flow recusa check-in e prefixo (F5, F6); recusa de "criar oportunidade" pelo agente sem prova | |
| AC-8 rastreabilidade | Passou no Flow (F1, F2) | CreatedById = OwnerId = usuário; marca "Origem: assistente de IA" |
| AC-9 não quebra o existente | Sem prova | Exige a v16 ativa e conversa; só conferido por query que v13 segue Active e v16 Inactive |

## O que ficou sem prova e o que fazer
- **R3 (busca de Lead por `identifyRecordByName` com `objectApiName = Lead`):** não exercitada. Não consegui conversar com o agente nesta sessão (a prévia do agente é interativa e a v16 está Inactive; ativar a v16 na dev trocaria o agente em uso, e não há como conversar com ele por comando não interativo). Uma pessoa deve ativar a v16 na dev e, na prévia do agente, pedir "criar tarefa para REG-TESTE-LEAD-01" e "criar tarefa para REG-TESTE-DUP" (esperado: lista de candidatos com tipo e Id, sem gravar). Se a busca não aceitar Lead, volta ao gate de design, conforme o plano.
- **R4 / AC-4 (usuário não administrador):** não há usuário não administrador na dev. Falta um usuário de teste com o permission set `PS_Comercial_AssistenteAcoes` e outro sem ele.
- **Q-13 (ações de EPLAST-27, 34 e 46 intactas na v16):** só conferido pelo plano (grep), não exercitado.
- **Chaves do custom metadata (Ativo=false, DescricaoObrigatoria=true, prefixo restrito):** não exercitadas, pois exigiriam alterar o registro de configuração entregue pelo build. O ramo "Padrao" ativo foi coberto.

## O que pode ter saído da org
Nada. A cadeia do Flow só gravou Task (apagadas). Nenhum e-mail, integração ou chamada externa. Os leads, contas e contato sintéticos criados pela fixture anterior não acionaram o Protheus (bypass de trigger).
