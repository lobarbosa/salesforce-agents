**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA, rodada 2)

Org confirmada com `sf org list`: `sbx-eplast-qa`, Sandbox, Connected (Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Deploy conferido: `0AfHa00000EI8iDKAT` (Succeeded). Só registros criados por mim (`TESTE EPLAST-27`), todos apagados ao final. Nenhum registro existente foi lido ou alterado.

**Resumo:** a regra (Flow `Account_Agente_ProximaAcao`, versão 2 Active) passou em 8 de 8 verificações repetidas. A v6 do agente foi ativada na QA (FALHA 1 da rodada 1 corrigida na pré-condição). Reprovado porque a **resposta do assistente em linguagem natural continua sem prova**: não consegui conversar com o agente por nenhum caminho disponível na sessão (FALHA 1 abaixo). Critério principal não executado é reprovação.

## Falhas

### FALHA 1 (crítica) — Resposta real do assistente (v6) ainda não comprovada
- Reproduzir: abrir conversa com o agente `SFAgent2` na QA (v6 Active), com usuário que tenha `PS_Comercial_ProximaAcao`, e perguntar "Qual a próxima ação para a conta TESTE EPLAST-27 C2 A2 parada?".
- Tentativas desta rodada, todas sem resposta do agente:
  1. `sf agent preview -n SFAgent2 --use-live-actions`: exige terminal interativo; falhou com "Raw mode is not supported on the current process.stdin".
  2. API de agentes (`api.salesforce.com/einstein/ai-agent/v1/.../sessions`, com o token da sessão): HTTP 404; `test.api.salesforce.com`: sem conexão (HTTP 000).
  3. `qa_browser_open` na conta de teste: a página Lightning ficou só com o esqueleto (sem cabeçalho nem painel do assistente), como na rodada 1. Screenshot sem dado real, só o esqueleto.
- Esperado: o assistente responde com a mensagem do Flow, sem acrescentar ação e sem dado pessoal; em conta de outro dono, não revela dados; 6 perguntas variadas sem inventar ação.
- Causa provável: limitação de ambiente da sessão de CI (sem terminal interativo, sem acesso à API de agentes, sem Lightning renderizando), não defeito de código. Para fechar: executar os Testes 1 a 8 do `05-roteiro-cliente.md` pela tela do assistente (um vendedor de teste com `PS_Comercial_ProximaAcao`, licença Agentforce e o agente concedido ao permission set), ou fornecer à esteira um meio de conversar com o agente (External Client App com credenciais da QA).
- Pendências adicionais sem prova: `PS_Comercial_ProximaAcao` tem 0 atribuições na QA (conferido por `COUNT` em `PermissionSetAssignment`); a concessão do agente ao permission set não pôde ser confirmada por query (`SetupEntityAccess` com `AgentforceAgent` retornou 0); isso precisa ser verificado por quem tem acesso à tela de permission set.

## Retestes da rodada anterior
| Falha da rodada 1 | Situação |
|---|---|
| FALHA 1 — v6 Inactive na QA | **Parcialmente corrigida.** Eu a ativei: `sf agent activate --api-name SFAgent2 --version 6 --target-org sbx-eplast-qa` ("SFAgent2 v6 activated"). Antes: v8 Active, v1 a v4, v6 e v7 Inactive. Depois: **v6 Active**, v8 e demais Inactive (query `BotVersion`). A conversa com o agente, porém, não foi executada (FALHA 1 acima). |

## Impacto em outras demandas (preflight)
A ativação da v6 desligou a v8 na QA (uma versão ativa por vez), a versão que trazia o trabalho de EPLAST-29, EPLAST-34 e EPLAST-46, todas mexendo no `SFAgent2`. Não testei nem alterei o trabalho delas. Quem testar essas demandas na QA precisa saber que a v8 está Inactive; a versão mais nova a chegar na QA é a que responde (decisão de 2026-11-16). Observação para o time: a v6 tem número menor que a v8, então sua ativação pode retirar da QA capacidades de v7/v8 que a v6 não tem.

## Componentes do deploy conferidos na QA
| Componente | Evidência | Status |
|---|---|---|
| Flow `Account_Agente_ProximaAcao` | Query `Flow`: v1 Obsolete, v2 Active | ok |
| `NextBestActionSetting__mdt` Default | conferido na rodada 1 (RiskValues=`E`, 30 dias, RestrictToOwner=true); não alterado | ok |
| Permission set `PS_Comercial_ProximaAcao` | existe; 0 atribuições | ok |
| Ação `ProximaAcaoCliente_EPLAST27_v6` | `GenAiFunctionDefinition` existe (também v7 e v8) | ok |
| BotVersion v6 | Active após ativação | ok |

## Casos executados (Flow, por Apex anônimo na QA)
Massa: `fixtures/conta-oportunidade-proxima-acao.apex` (7 contas C1 a C7), executada em duas etapas. Usuário de execução `005bJ00000piKAaQAM` (Administrador, dono das contas, exceto C6). Usuário de serviço Konecta `005bJ00000hBJmYQAW`: inativo na QA, não usado. Chamada: `Flow.Interview.createInterview('Account_Agente_ProximaAcao', {recordId})`.

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C1 A1 | Flow na C1 (risco E, parada 45 dias) | A1 vence A2 | `A1`: "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| C2 A2 | Flow na C2 (31 dias) | A2 | `A2`: "Retomar oportunidade parada: ... Qualificação sem atividade há 31 dias." | passou |
| C3 A3 | Flow na C3 (compra ganha há 91 dias) | A3 | `A3`: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| C4 NONE | Flow na C4 | nenhuma ação | `NONE`: "Nenhuma ação prioritária no momento." | passou |
| C5 NODATA | Flow na C5 | dados insuficientes | `NODATA`: "Dados insuficientes: ..." | passou |
| C6 carteira | Flow na C6 (outro dono) | sem dado | `NOT_OWNER`: "Esta conta não está na sua carteira." | passou |
| C7 risco fora da lista | Flow na C7 (risco A) | A2, não A1 | `A2` (45 dias) | passou |
| G1 não grava | `LastModifiedDate` das 7 contas antes e depois das 7 execuções | igual | `LMD_IGUAL true` | passou |
| Volume, Protheus, e-mail, limiar configurável (rodada 1) | não repetidos nesta rodada; a rodada 1 (`05-testes-rodada-1.md`) os passou com o mesmo Flow v2 | — | evidência na rodada 1 | herdado, não reexecutado |
| Conversa com o assistente (cenários 1 a 6, não expõe dado pessoal na resposta, não inventa ação) | ver FALHA 1 | resposta do agente | não executado | **não executado** |

## Mudanças feitas e desfeitas
- Usuário `005bJ00000piKAaQAM`, campo `ProtheusSellerId__c`: antes `null`, durante `TESTE27` (exigido pela validation rule para criar a massa), depois `null` (confirmado por query).
- Não atribuí `PS_Comercial_ProximaAcao` a mim; não liguei Marketing User.
- Ativação da BotVersion v6: permanece ativa (regra da esteira).

## O que pode ter saído da org
- A massa criou 7 Account, 4 Opportunity abertas, 2 ganhas, Tasks, Branch e PaymentTerms de teste. A automação existente da org ao ganhar oportunidade criou 2 Cases "Pós-vendas: TESTE EPLAST-27 ganha C3/C4" (00001008 e 00001009), que impediram a exclusão das contas; apaguei os Cases e depois toda a massa. Contagem final de `TESTE EPLAST-27` em Account, Opportunity e Case: 0.
- Nenhum e-mail ou chamada externa observado nesta rodada (não repeti a conferência de `IntegrationLog__c`; rodada 1: 831 antes, 831 depois).
