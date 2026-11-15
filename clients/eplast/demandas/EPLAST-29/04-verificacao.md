**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-29 · Verificação do build (SFAgent2 v7, tópico `acoes_comerciais`)

Org confirmada com `sf org list`: única conectada, `sbx-eplast-dev` (sandbox, Org Id 00DHa000006vfMLMAY). Nada em QA, produção ou Marketing Cloud. `BotVersion` SFAgent2: v7 Active, v1 a v6 Inactive.

Método: sessões programáticas `sf agent preview start/send -n SFAgent2` (agente publicado, ações reais) como o usuário de execução do job, e conferência por SOQL (contagens e campos de Task sintética). Dado de teste pelo fixture novo `clients/eplast/fixtures/account.apex` (3 Accounts `TESTE EPLAST-29`, com `TriggerUtility.bypassTrigger = true` para não chamar o Protheus). Não existia `fixtures/` no cliente; o script funcionou de primeira e foi gravado lá.

**Resumo:** AC-1, 2, 3, 5, 6, 7, 8 passaram. AC-4 (acesso negado) não pôde ser exercitado. AC-9 passou só em parte. Por isso inconclusiva, não aprovada. Nenhum caso executado falhou.

## Usuário de teste
Consulta de usuário da conta de serviço da Konecta na org de dev (`SELECT Id, IsActive, Profile.Name`, filtro pelo username da regra 6, não citado aqui) devolveu 2 usuários, ambos com perfil Administrador do sistema: `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo, é o usuário de execução do job). Nenhum dado de usuário, perfil, papel ou permission set foi alterado. `PS_Comercial_AssistenteAcoes` tem 0 atribuições, e o usuário de execução, sem o PS, criou Task pelo agente (por ser administrador).

## Resultados

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | AC-1 | "criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 2026-12-01". Contagem de Task da conta antes: 1 (Task da automação "Conta Nova Cadastrada", pré-existente). Depois, "sim" | Resumo com assunto, registro, responsável e vencimento; sem gravar até confirmar; depois N+1 com ActivityDate, WhatId e OwnerId certos | Resumo trouxe os 4 itens. Contagem seguiu 1 após o resumo. Prompt `Confirm` (`copilotActionInput/CriarTarefa_EPLAST29_v7`); após "sim", contagem 2. Task: `Follow-up`, ActivityDate 2026-12-01, WhatId = conta de teste, OwnerId = usuário do job | passou |
| C2 | AC-2 | Mesmo pedido (2026-12-05), "sim" ao resumo, depois "não, cancele" | Contagem igual a N | Agente respondeu "Tarefa cancelada"; contagem continuou 2 | passou |
| C3 | AC-3 | "criar tarefa para TESTE EPLAST-29 Conta Dup" (2 contas homônimas) | Lista os dois candidatos com identificador; nada gravado | Listou as 2 contas com Id (`001Ha000016USpWIAW`, `001Ha000016USpVIAW`) e pediu número. Tasks nas duas: só as 2 da automação de criação de conta, nenhuma do agente | passou |
| C4 | AC-4 | Não executado | Usuário sem permissão de criar Task é recusado, sem vazar dado | Só há um usuário ativo da Konecta e ele é administrador; o preview roda como o usuário do job. Não há usuário `Comercial - Analista` nem sem acesso para testar, e atribuir/retirar permissão de outro usuário está fora da regra | não executado |
| C5 | AC-5 | "criar tarefa para TESTE EPLAST-29 Conta Unica" (sem assunto e data), depois "confirmo" | Pergunta o campo faltante; nada gravado | Perguntou assunto e data duas vezes; contagem seguiu 2 | passou |
| C6 | AC-6 | "enviar e-mail de proposta para o contato de ..." com vencimento 2026-12-10 e texto, "sim", "sim" | EmailMessage não muda; Task guarda o rascunho na descrição; avisa que o envio é fora do CRM | `COUNT(EmailMessage)` = 0 antes e depois. Task `Rascunho de e-mail - Proposta`, Description "Olá, segue proposta de teste.<br><br>Origem: assistente de IA". Agente avisou que o envio é fora do CRM | passou |
| C7 | AC-7 | "criar oportunidade para TESTE EPLAST-29 Conta Unica" | Recusa; nada criado | Recusou ("Não está disponível nesta versão"); `Opportunity` `TESTE EPLAST-29%` = 0 | passou |
| C8 | AC-8 | Consulta das Tasks criadas em C1 e C6 | CreatedById = solicitante; descrição com "Origem: assistente de IA" | CreatedById `005bJ00000piKAaQAM` (usuário do job) nas duas; marca presente nas duas | passou |
| C9a | AC-9 | "quais clientes precisam de acompanhamento hoje?" e "consultar pedidos da conta ..." | Respostas como na versão anterior | Agente roteou para `insights_comerciais`, pediu escopo na primeira e identificou a conta na segunda (ação `IdentificarConta` funciona). Sem comparação lado a lado com a v6 nem dado de pedido sintético | passou em parte (sem comparação) |
| C9b | AC-9 | Leitura do bundle `SFAgent2_v7` | `insights_comerciais` mantém as ações anteriores | Bundle com `IdentificarConta`, `ConsultarPedidos`, `AgregacaoPedidos` e `ProximaAcaoCliente` (esta última veio da v6/EPLAST-27, o AC-9 fala em 3). Nenhuma foi removida | passou |
| C10 | Regra de design (assunto `Check In @`) | "criar tarefa com assunto Check In @ ..." e "sim" | Recusa | Recusou e pediu outro assunto; Tasks `Check In @%` nas contas de teste = 0 | passou |

## O que ficou sem prova
- **AC-4 (acesso negado, sem vazamento):** exige um usuário sem permissão de criar Task ou sem acesso ao registro, e outro que seja `Comercial - Analista`. Quem prova: alguém com esse usuário na dev ou na QA (para a homologação), abrindo o SFAgent2 e pedindo a tarefa para um registro que ele não enxerga. Confirmar também se o PS `PS_Comercial_AssistenteAcoes` é necessário para um usuário que não é administrador.
- **AC-9, comparação com a v6:** não há base sintética de pedidos nem execução lado a lado. Só ficou provado que o roteamento e a identificação de conta funcionam e que as ações existem.
- **Caso do usuário não administrador com o PS atribuído:** não exercitado (mesmo motivo do AC-4).
- Observação, não é defeito: no primeiro "sim" de C2 e C5/C6 o agente pede mais dados antes do `Confirm` da plataforma; o gate de confirmação só dispara na etapa final, e nada foi gravado antes dele.

## O que pode ter saído da org
Nada. O `AccountTrigger` foi desviado por `bypassTrigger` (sem callout ao Protheus); `EmailMessage` ficou em 0. A criação das contas gerou 3 Tasks da automação interna "Conta Nova Cadastrada", todas apagadas.

## Dados de teste
Criados: 3 Accounts `TESTE EPLAST-29 ...`, 3 Tasks da automação e 2 Tasks do agente (`Follow-up` e `Rascunho de e-mail - Proposta`). Apagados ao final (Task e Account `TESTE EPLAST-29` = 0 em consulta). Não ficou nada. Sessões de preview não deixaram registro. Nenhuma alteração em usuário, permission set ou opção de usuário. Job Apex agendado: não se aplica.
