**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev (`usuário de teste da Konecta (username omitido)`, org 00DHa000006vfMLMAY, `sf org list`: única org, Sandbox, Connected)

# Verificação — EPLAST-27: Próxima melhor ação por cliente

Resumo: o Flow e a estrutura da v10 foram exercitados e passaram. A resposta real do assistente não pôde ser exercitada (v10 inativa, sem concessão do agente ao permission set, licença Agentforce não confirmada). Nenhum caso falhou. Por isso o veredito é inconclusiva, não aprovada: o critério principal do usuário final (o assistente responde) está sem prova.

## Execução
- Usuário de execução: Id `005bJ00000piKAaQAM` (Administrador do sistema, ativo), a conta de serviço `usuário de teste da Konecta (username omitido)`; há um segundo usuário com o mesmo prefixo (`005bJ00000hBJmYQAW`) inativo, não usado. Ele foi o proprietário das contas de teste; a conta C6 tem outro proprietário (usuário ativo qualquer, definido pelo fixture).
- Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (7 contas `TESTE EPLAST-27 C1..C7`, oportunidades e tarefas sintéticas), com `TriggerUtility.bypassTrigger = true`.
- Flow chamado por Apex anônimo (`Flow.Interview.createInterview('Account_Agente_ProximaAcao', recordId)`), versão ativa 2. CMDT `Default`: 30 dias, `RiskValues__c = E`, `RestrictToOwner__c = true`.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| F1 | Precedência A1 (risco) sobre A2 | C1: `Risk__c = E`, oportunidade aberta com 45 dias sem atividade | A1 | `A1`, "Tratar risco da conta: o cadastro está com risco E..." | passou |
| F2 | A2 por limiar (31 > 30) | C2: oportunidade aberta, atividade há 31 dias, sem risco | A2 | `A2`, "...em Qualificação sem atividade há 31 dias." | passou |
| F3 | A3 inativo | C3: `Inactive__c = true`, ganha há 91 dias, sem oportunidade parada | A3 | `A3`, "...última compra ganha foi há mais de 90 dias." | passou |
| F4 | NONE | C4: compra há 10 dias, oportunidade com atividade há 5 dias | NONE | `NONE`, "Nenhuma ação prioritária no momento." | passou |
| F5 | NODATA antes de A1 | C5: sem oportunidade e sem compra | NODATA | `NODATA`, "Dados insuficientes..." | passou |
| F6 | Carteira (RestrictToOwner = true) | C6: proprietário é outro usuário | NOT_OWNER sem dado da conta | `NOT_OWNER`, "Esta conta não está na sua carteira." | passou |
| F7 | Risco fora da lista não dispara A1 | C7: `Risk__c = A`, oportunidade com 45 dias | A2 | `A2` (45 dias) | passou |
| F8 | Id inexistente/sem acesso | Id `001000000000000AAA` | NOT_OWNER neutro | `NOT_OWNER`, mensagem neutra | passou |
| F9 | Não grava nada (design 10.1) | `LastModifiedDate` máximo das contas e oportunidades de teste antes e depois das 8 execuções; limites da execução | Iguais; DML 0 | Iguais (conta 02:04:31Z, oportunidade 02:04:30Z); "Number of DML statements: 0 out of 150" | passou |
| F10 | Sem dado pessoal e sem envio (10.7) | Leitura das mensagens devolvidas | Só texto fixo, estágio e dias | Nenhum CPF, e-mail, telefone, valor ou nome de contato nas mensagens; nenhum e-mail enviado (Flow sem DML nem ação de envio) | passou |
| F11 | Massa não gera envio ao Protheus (10.8) | `COUNT(IntegrationLog__c)` antes e depois da massa | Sem aumento | 13 antes, 13 depois | passou |
| S1 | Estrutura v10: ação ligada ao tópico | Retrieve de `GenAiPlannerBundle:SFAgent2_v10` da org (descartado depois), leitura do tópico `insights_comerciais_..._v10` | `ProximaAcaoCliente_EPLAST27_v10` no tópico, alvo `Account_Agente_ProximaAcao`, tipo flow | Presente; entrada `recordId` obrigatória; saída `message` exibível e `actionCode` | passou |
| S2 | Instrução do tópico | Mesmo retrieve | `instruction2_EPLAST27_v10` com IdentificarConta, apresentar a mensagem sem alterar, NOT_OWNER sem outras ações | Presente com os três pontos | passou |
| S3 | Ações de EPLAST-29, 34 e 46 preservadas | Mesmo retrieve | `IdentificarRegistro` e `CriarTarefa` (29, tópico `acoes_comerciais_EPLAST29_v10`), `ResumoReuniao` (34), `SugestaoCampanha` (46) | Todas presentes, mais `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`; 5 tópicos | passou |
| S4 | v8 intacta e ativa; v10 inativa | `SELECT VersionNumber, Status FROM BotVersion` e retrieve da v8 | v8 Active, v9 e v10 Inactive; v8 sem alteração | v8 Active, v9 Inactive, v10 Inactive; v8 sem a instrução 27 (como antes do build) e sem `SugestaoCampanha` | passou |
| A1 | Assistente responde com a v10 | Não executado | Resposta com a mensagem do Flow | Não executado: v10 inativa (não ativo, passo do humano), `PS_Comercial_ProximaAcao` com 0 atribuições e 0 concessões de agente (`SetupEntityAccess` do agente), licença Agentforce não confirmada (I3) | não executado |
| C1 | Limiar por CMDT (60 dias com 45 dias de atividade não dá A2) | Não executado | Sem A2 | Exigiria alterar o CMDT `Default`, metadata fora da massa de teste | não executado |
| C2 | `RestrictToOwner = false` | Não executado | Conta de outro dono é lida | Mesma razão do C1 | não executado |
| C3 | 150 oportunidades numa conta (10.2) | Não executado | Sem erro de limite | Não criei 150 oportunidades para reduzir o que a cadeia dispara. Evidência indireta: o Flow faz sempre 4 consultas com 1 registro (29 SOQL no total das 8 chamadas, 30 linhas) | não executado |
| C4 | Pergunta variada ao agente ("não inventa ação", R6) | Não executado | Mesma razão de A1 | Depende do assistente | não executado |

## Alterações no usuário de execução (dev) e devolução
- `User.ProtheusSellerId__c` do `005bJ00000piKAaQAM`: antes `null`, durante `TESTE27` (exigido pelo fixture), depois `null` (conferido).
- `UserPermissionsMarketingUser`: não alterado (false). Permission set da demanda: não atribuído.

## O que pode ter saído da org
- A criação da massa (bypass de trigger ativo) gerou 2 Cases de pós-vendas por automação das oportunidades Fechado/Ganho (`00001425` e `00001426`, títulos `Pós-vendas: TESTE EPLAST-27 ganha C3/C4`), apagados na limpeza.
- Chamada externa: nenhuma registrada. `IntegrationLog__c` 13 antes e 13 depois (sem registro novo). Nada para desfazer do outro lado.
- Marketing Cloud: não tocado.

## Limpeza
Contas, oportunidades, tarefas, Cases, `Branch__c` e `PaymentTerms__c` com `TESTE EPLAST-27`: 0 restantes (contagem por consulta). Nada ficou na org. Sem job agendado. Observação: o fixture ganhou aviso de que os Cases devem ser apagados antes das contas (primeira tentativa de limpeza falhou por isso e foi refeita).

## O que fica sem prova e o que fazer
1. Resposta real do assistente (A1, C4): alguém precisa ativar a v10 (desativa a v8, decidir junto com EPLAST-29, 34 e 46), conceder o agente `SFAgent2` ao `PS_Comercial_ProximaAcao`, atribuí-lo a um usuário com licença Agentforce e perguntar "qual a próxima ação para a conta X" em conta de teste.
2. Variações de CMDT (C1, C2) e conta com 150 oportunidades (C3): podem ser feitas na QA ou na dev com autorização para alterar o CMDT e criar a massa grande.
