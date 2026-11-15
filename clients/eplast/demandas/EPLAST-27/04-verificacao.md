**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (alias confirmado com `sf org list`: única org, Sandbox, Connected; Org Id 00DHa000006vfMLMAY)

# Verificação — EPLAST-27 (Próxima melhor ação, v6 com BotVersion)

Resumo: a lógica do Flow (A1, A2, A3, NONE, NODATA, NOT_OWNER, risco fora da lista) foi executada na dev e passou, e a estrutura da v6 está correta. Ficou sem prova a resposta real do assistente, que exige a v6 ativa. Eu não ativo versão, e a licença Agentforce (I3) e a concessão do agente ao permission set não estão confirmadas.

## Massa e usuário
- Fixture: `fixtures/conta-oportunidade-proxima-acao.apex` (7 contas `TESTE EPLAST-27 C1..C7`, oportunidades e tasks sintéticas, `TriggerUtility.bypassTrigger = true`).
- Usuário de execução: `005bJ00000piKAaQAM` (ativo, Administrador do sistema). O usuário de serviço da Konecta (conta de teste indicada na regra 6, buscada por username), Id `005bJ00000hBJmYQAW`, está inativo e não foi usado. O dono das contas é o usuário de execução, e C6 pertence a outro usuário ativo da org.
- Campo temporário: `User.ProtheusSellerId__c` do usuário de execução. Antes: `null`. Durante: `TESTE27` (exigido pela validation rule para criar a massa). Depois: `null` (confirmado por query).
- Permission set da demanda e Marketing User: não foram necessários e não foram alterados. O Flow foi chamado por Apex anônimo (`Flow.Interview`, variável de entrada `recordId`).

## Critérios exercitados
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | A1 risco na lista (`E`), com histórico e oportunidade parada | `Flow.Interview` `Account_Agente_ProximaAcao` com `recordId` = conta C1 | `A1` (vence A2, P9) | `A1`: "Tratar risco da conta: o cadastro está com risco E…" | passou |
| C2 | A2 oportunidade aberta parada (31 dias, limiar 30) | idem, conta C2 | `A2` | `A2`: "…oportunidade em Qualificação sem atividade há 31 dias." | passou |
| C3 | A3 inativo (última compra ganha há 91 dias, sem parada) | idem, conta C3 | `A3` | `A3`: "…a última compra ganha foi há mais de 90 dias." | passou |
| C4 | Nenhuma ação (compra há 10 dias, oportunidade com atividade há 5 dias) | idem, conta C4 | `NONE` | `NONE`: "Nenhuma ação prioritária no momento." | passou |
| C5 | Dados insuficientes (sem oportunidade e sem compra) | idem, conta C5 | `NODATA` | `NODATA`: "Dados insuficientes: …" | passou |
| C6 | Carteira: conta de outro dono (design 10.3) | idem, conta C6 | `NOT_OWNER`, sem outras informações | `NOT_OWNER`: "Esta conta não está na sua carteira." | passou |
| C7 | Risco fora da lista (`A`) não dispara A1 | idem, conta C7 | `A2` (45 dias parada), não A1 | `A2`: "…sem atividade há 45 dias." | passou |
| G1 | Não grava nada (design 10.1), nível de dado | `LastModifiedDate` das 7 contas antes e depois das execuções do Flow | igual | `diff` idêntico | passou |
| G2 | Flow em versão ativa, sem edição da ativa | Tooling API `Flow` | v1 Obsolete, v2 Active | v1 Obsolete, v2 Active | passou |
| G3 | Sem envio ao Protheus pela massa (design 10.8, R2) | `COUNT(Id)` de `IntegrationLog__c` antes e depois da massa e do Flow | sem aumento | 4 antes, 4 depois | passou |
| V1 | BotVersion v6 inativa, ligada ao planner `SFAgent2_v6`; v5 ativa | `SELECT DeveloperName, VersionNumber, Status FROM BotVersion` (`SFAgent2`) | v1 a v4 Inactive, v5 Active, v6 Inactive | v1 a v4 Inactive, v5 Active, v6 Inactive. `genAiPlannerName` = `SFAgent2_v6` em `v6.botVersion-meta.xml`. Tooling `GenAiPlannerDefinition` lista `SFAgent2_v1` a `v6` | passou |
| V2 | Planner v6 com 4 tópicos, ação e instrução da 27, sem 29/34 | Leitura do `SFAgent2_v6.genAiPlannerBundle` do repositório | 4 tópicos, `ProximaAcaoCliente_EPLAST27_v6`, `instruction2_EPLAST27_v6`, nada de 29/34 | 4 tópicos de topo (ambiguous_question, insights_comerciais, off_topic, agent_router). Ação e instrução presentes. `grep` por EPLAST-29/34: 0 ocorrências. As ações `ConsultarPedidos`, `AgregacaoPedidos` e `IdentificarConta` seguem no tópico. Conferido só no arquivo versionado, não por retrieve da org. | passou |
| T1 | Resposta real do assistente (ação chamada pelo agente, saída sem dado pessoal) | não executado | Resposta com a ação sugerida, sem CPF, e-mail, telefone ou valor | v6 inativa; não ativo versão (a ativação é passo separado e desativaria a v5). Licença Agentforce (I3) e concessão do agente ao permission set não confirmadas | não executado |
| T2 | Log de depuração do vendedor sem `AccountTrigger`, `OpportunityTrigger`, `AccountTriggered`, `OpportunityFlow` (design 10.1, parte de execução) | não executado | — | Só provei que `LastModifiedDate` não mudou (G1). Não capturei o log de execução do Flow | não executado |
| T3 | 150 oportunidades numa conta (10.2), A2 por limiar com CMDT em 60 (10.5), carteira com 2º vendedor sem permissão (10.3, parte de usuário comum), 10 consultas | não executado | — | Fora do escopo desta rodada, que cobre a BotVersion. O Flow v2 já havia sido provado na rodada anterior (plano de build) | não executado |

## Premissas assumidas exercitadas
- P9: `NODATA` antes de A1, e A1 vence A2. C5 deu `NODATA` mesmo com o `Risk__c` padrão `E` zerado pela fixture. C1 deu `A1` apesar da oportunidade parada.
- P2: limiar de 30 dias para A2 e A3 via `Inactive__c` (90 dias). C2 (31 dias) e C3 (91 dias) deram A2 e A3.
- Restrição à carteira (`RestrictToOwner__c` = verdadeiro): C6.
- Valor de risco `E` no CMDT: C1 contra C7 (`A`).

## O que ficou sem prova
- T1: o assistente (v6) responde e chama a ação. Para provar, uma pessoa precisa ativar a `SFAgent2.v6` na dev (isso desativa a v5), confirmar a licença Agentforce e conceder o agente ao `PS_Comercial_ProximaAcao`. Depois deve perguntar pela próxima ação de uma conta de teste.
- T2 e T3, como descritos acima.

## O que pode ter saído da org
Nada. A cadeia da massa rodou com `TriggerUtility.bypassTrigger = true`. `IntegrationLog__c` ficou em 4 (sem criação), e não há e-mail nem Marketing Cloud envolvido.

## Defeitos encontrados
Nenhum. Observação: a variável de entrada do Flow se chama `recordId` (não `accountId`). Minha primeira tentativa usou o nome errado e todas as contas voltaram `NOT_OWNER`. Foi erro de teste, não defeito do build.

## Limpeza
- Apagados: Task, Opportunity, Account, `Branch__c` e `PaymentTerms__c` com `TESTE EPLAST-27%`. Contagem final: 0 em cada objeto.
- `ProtheusSellerId__c` do usuário de execução devolvido a `null`.
- Nada alterado em metadata, nada ativado, sem commit. Sem job Apex agendado.
