**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-27: Próxima melhor ação por cliente (QA)

Org confirmada com `sf org list`: `sbx-eplast-qa`, Sandbox, Connected (Org Id 00DHa000006vZtmMAE, a QAS da Eplast, Partial Copy). Pacote do `05-deploy-qa.md` (deploy `0AfHa00000EI6tJKAT`) conferido na org. Só registros criados por mim (`TESTE EPLAST-27`); nenhum registro existente lido ou alterado.

**Resumo:** a regra (Flow `Account_Agente_ProximaAcao`) passou em todos os casos executados (12 de 12). Reprovado porque o critério principal dos cenários, "o vendedor pergunta ao assistente e recebe a sugestão", não pôde ser executado: a BotVersion v6 está Inactive na QA.

## Falhas

### FALHA 1 (crítica) — Resposta real do assistente não comprovada (v6 inativa na QA)
- Reproduzir: `SELECT DeveloperName, VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName='SFAgent2'` na QA.
- Obtido: v1 a v3 Inactive, **v4 Active**, **v6 Inactive**. A ação `ProximaAcaoCliente_EPLAST27_v6` só existe na v6. Nenhuma pergunta ao assistente pôde ser feita, e a tela de configuração do agente não abriu na sessão de navegador (página em branco, só o logotipo).
- Esperado: assistente (v6 ativa, com licença Agentforce e o agente concedido ao `PS_Comercial_ProximaAcao`) responde com a mensagem do Flow, sem acrescentar ação, sem dado pessoal.
- Causa provável: ativar a v6 desativa a v4 (uma versão ativa por vez) e é passo humano autorizado no card (plano de build). Não ativo versão. Não é defeito de código; é pré-condição de teste. Para a rodada seguinte: alguém autorizado ativa a v6 na QA (ou autoriza no card), confirma a licença e concede o agente ao permission set; o QA então executa os cenários de pergunta (inclusive 6 perguntas variadas para "não inventa ação", R6) e o 10.7 pela resposta do assistente. Observação: a v5 existe na dev mas não na QA (QA tem v1–v4 e v6); confirmar que a v6 não perde capacidade da v4 ativa antes de ativar.

## Componentes do deploy conferidos na QA
| Componente | Evidência | Status |
|---|---|---|
| Flow `Account_Agente_ProximaAcao` | Tooling `Flow`: versão 1, Active, AutoLaunchedFlow (conteúdo do build) | ok |
| `NextBestActionSetting__mdt` + registro `Default` | Query: RiskValues=`E`, StaleOpportunityDays=30, RestrictToOwner=true | ok |
| Permission set `PS_Comercial_ProximaAcao` | Query em `PermissionSet`: existe; 0 atribuições | ok |
| Planner `SFAgent2_v6` | Tooling `GenAiPlannerDefinition`: existe | ok |
| BotVersion v6 | Existe, Inactive (ver FALHA 1) | ok (existe) |

## Casos executados
Execução por Apex anônimo (`Flow.Interview`, entrada `recordId`) na QA, com massa `fixtures/conta-oportunidade-proxima-acao.apex` (7 contas, C1 a C7) mais a conta C8. Usuário de execução `005bJ00000piKAaQAM` (Administrador do sistema, dono das contas, exceto C6 de outro usuário ativo). Usuário de serviço da Konecta `005bJ00000hBJmYQAW`: inativo na QA, não usado.

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| C1 A1 | Flow na C1 (risco `E`, oportunidade parada 45 dias) | A1, vence A2 | `A1`: "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." | passou |
| C2 A2 | Flow na C2 (31 dias sem atividade) | A2 com estágio | `A2`: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." | passou |
| C3 A3 | Flow na C3 (compra ganha há 91 dias) | A3 | `A3`: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias." | passou |
| C4 NONE | Flow na C4 (compra há 10 dias, atividade há 5) | Nenhuma ação | `NONE`: "Nenhuma ação prioritária no momento." | passou |
| C5 NODATA | Flow na C5 (sem oportunidade nem compra) | Dados insuficientes, sem erro técnico | `NODATA`: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| C6 carteira | Flow na C6 (dono é outro usuário) | Nenhum dado da conta | `NOT_OWNER`: "Esta conta não está na sua carteira." | passou |
| C7 risco fora da lista | Flow na C7 (risco `A`, parada 45 dias) | A2, não A1 | `A2`: "...sem atividade há 45 dias." | passou |
| G1 não grava | `LastModifiedDate` de 7 contas antes e depois de 8 execuções + 10 consultas à C2 | igual | `LMD_IGUAL true` | passou |
| G2 sem execução de automação | Log do Apex anônimo (8 consultas + 10) buscado por `AccountTrigger`, `OpportunityTrigger`, `AccountTriggered`, `OpportunityFlow`; DML e e-mail | 0 ocorrências | 0 ocorrências; sem evento de DML nem de e-mail no log da consulta | passou |
| G3 volume | C8 com 150 oportunidades abertas (40 dias sem atividade), Flow | Resposta sem erro de limite | `A2`, "...sem atividade há 40 dias.", CPU 957 ms (inclui a criação da massa) | passou |
| G4 Protheus (R2) | `COUNT(Id)` de `IntegrationLog__c` antes e depois da massa e dos Flows | sem aumento | 831 antes, 831 depois | passou |
| G5 sem dado pessoal e sem envio | Leitura das mensagens de saída acima; desenho sem e-mail alert, Apex de e-mail ou Marketing Cloud | só texto fixo, estágio e dias | nenhuma saída contém CPF, e-mail, telefone ou valor; sem e-mail no log | passou |
| T1 assistente | Perguntar a próxima ação ao `SFAgent2` v6 | Mensagem do Flow, sem acréscimo | não executado (FALHA 1) | não executado |
| T2 limiar no CMDT (60 dias) | Alterar `StaleOpportunityDays__c` | A2 some com 45 dias | não executado: exigiria implantar o registro na QA, o que o QA não faz fora de automação agendada. | não executado |
| T3 vendedor comum sem permissão | Usuário sem o permission set pergunta | Acesso negado ao agente | não executado (usuário de serviço inativo; sem v6 ativa) | não executado |

## Mudanças em usuário de execução (e desfeitas)
- `User.ProtheusSellerId__c` de `005bJ00000piKAaQAM`: antes `null`, durante `TESTE27` (exigido pela validation rule para criar a massa), depois `null` (confirmado por query).
- Permission set, Marketing User, perfil e papel: não alterados.

## Observação sobre a fixture
A QAS (Partial Copy) tem regra de duplicidade em Account: o primeiro script falhou com `DUPLICATES_DETECTED` e foi revertido por inteiro. Reexecutei com `allowSave` no insert das contas e atualizei `fixtures/conta-oportunidade-proxima-acao.apex`.

## O que pode ter saído da org
Nada. Massa criada com `TriggerUtility.bypassTrigger = true`; `IntegrationLog__c` ficou em 831; sem e-mail, sem callout, sem Marketing Cloud.

## Limpeza
Apagados Task, Opportunity, Account (inclui C8), `Branch__c` e `PaymentTerms__c` com `TESTE EPLAST-27`: contagem final 0 em cada. Sem job agendado, sem deploy feito por mim, sem versão ativada.
