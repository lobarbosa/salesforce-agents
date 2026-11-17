**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, Org ID `00DHa000006vfMLMAY`)

# EPLAST-47 — Verificação (rodada 2: Flow `Opportunity_AfterSave_ClassificaConta` e agendado inativo)

`sf org list` mostrou só `sbx-eplast-dev`, conectada. Usuário de execução: `005bJ00000piKAaQAM` (conta de serviço Konecta, ativa). Nada na QA, em produção ou no Marketing Cloud. Todo dado sintético, "TESTE EPLAST-47", pelas fixtures `eplast47-base.apex` e `eplast47-cotacao.apex`. Cada oportunidade foi levada a Fechado/Ganho em execução de Apex própria (uma transação por coisa).

## Mudanças temporárias no usuário de execução (desfeitas)
| Campo | Antes | Durante | Depois |
|---|---|---|---|
| `User.ProtheusSellerId__c` (`005bJ00000piKAaQAM`) | vazio | `TESTE47` (exigido pela VR do proprietário) | vazio (conferido) |

Sem permission set nem Marketing User alterados.

## Rodada 1: falhas anteriores
- FALHA 1 (faixas fora de `SortOrder__c`, 3.000 virava G): **corrigida**. Casos C1 e C10 abaixo.
- FALHA 2 (filtro do relatório): **corrigida**. Caso C14 (valor do filtro `Ranking`, 13 linhas = 13 mudanças feitas).

## Estado dos Flows na dev
- `Opportunity_AfterSave_ClassificaConta`: Tooling API `Flow` v1 e v2 Obsolete, **v3 Active**; `FlowDefinition.ActiveVersionId` = `301Ha000016aVfiIAE`. (O plano cita v2 como a mais recente; a ativa hoje é a v3. Observação, não defeito.)
- `ScheduledFlowOpportunity`: v1 e v2 Obsolete, nenhuma Active; `FlowDefinition.ActiveVersionId` = null; `CronTrigger` com nome `ScheduledFlowOpportunity%` = 0 linhas. `flowDefinition` do repositório com `activeVersionNumber` 0 e `flows/ScheduledFlowOpportunity.flow-meta.xml` sem diferença contra a `main` (fora do pacote).

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C0 | 16 (agendado) / design | Consulta de `FlowDefinition`, `Flow` (Tooling) e `CronTrigger` | Agendado sem versão ativa e sem job | ActiveVersionId null, 0 Active, 0 CronTrigger | passou |
| C1 | 8, 10 (faixa), FALHA 1 | Conta A, Opp 1 (3.000) para Ganho | `LastMonthPurchaseValue__c`=3.000, `Ranking__c`=MP | 3.000 e MP; média 3.000 | passou |
| C8 | 8 | Conta A: Opp 2 (7.000) ganha e Opp 3 (9.000) perdida | Compras = 10.000 (perdida fora); ranking MP (média 5.000) | Depois da perdida: 3.000 (sem mudança). Depois da ganha: 10.000, média 5.000, MP | passou |
| C10 | 10 | 12 contas "Borda 1..12", cada uma com 1 oportunidade ganha de 10.000; 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000; 1.000.000,01 | MP/PP/PP/P/P/M/M/G/G/GG/GG/3G | MP/PP/PP/P/P/M/M/G/G/GG/GG/3G, nessa ordem; soma e média iguais ao valor | passou |
| C12/C15 | 12, 15 | Grep no XML do Flow novo por limites antigos/novos (10000, 35000, 70000, 80000, 150000, 160000, 500000, 1000000) e por e-mail | 0 ocorrências | 0 ocorrências; limites vêm de `RankingRange__mdt` (7 faixas por SOQL: UpperLimit 10.000, 35.000, 80.000, 160.000, 500.000, 1.000.000, vazio) | passou |
| C14 | 14 | Analytics API (só contagem) no relatório `AccountRankingChanges` | N mudanças = N | 13 (Conta A + 12 bordas, todas passaram de vazio para uma classe), filtro `field_key` = `Ranking` | passou |
| C4 | 4 | Contas distintas, cada uma ganha uma vez; Conta A com 2 ganhas em saves separados | Uma atualização de classificação por salvamento, sem erro | 14 saves de ganha sem erro; sem "Too many queueable"; 13 linhas de histórico para 13 mudanças | passou (ver nota) |
| C5 ordem | design R1/V2 | Verificado na rodada 1 (Flow novo depois de `OpportunityFlow`, média já recalculada) e confirmado agora pelo resultado: o Flow classifica pela média recém-gravada (C8 e C10) | Classe da média do save | Correta em todos | passou |
| C11 | 11 | Média vazia mantém; média 0 vira MP | — | Não exercitado: exigiria forçar média vazia/0 na conta, o que `OpportunityFlow` recalcula | não executado |
| V3 | design 1.3 | Mudar só `Description` da Opp 1 e conferir que o Flow novo não inicia | Flow novo ausente | O log de Apex anônimo não trouxe eventos de Flow (0 linhas `FLOW_START_INTERVIEW_BEGIN`), então não há prova | não executado |
| V6/C16 | 16 | Falha forçada de `UpdateAccount` | `IntegrationLog__c` e sem e-mail | Não executado: as VRs de telefone impedem gravar dado inválido e não há dado legado inválido na dev. Pelo design (2026-11-17) fica para a homologação; destinatário vazio = só log (`FaultRecipient__c` vazio) | não executado |
| C13 | 13 | Picklist `Ranking__c` com 7 valores ativos | — | Os 7 valores (MP a 3G) foram gravados nos casos C10 sem erro; contagem do picklist não consultada à parte | passou (indireto) |
| C17, C18 | 17, 18 | Execução em QA e volume | — | QA e números de volume não são da dev (P10 em aberto) | não executado |

Nota C4: o critério 4 original (dia 14, lote por conta) pertence ao Flow agendado, agora inativo; o caminho novo atualiza a conta por salvamento de oportunidade e só grava se mudou (HasChanges). A contagem exata de updates por save foi medida na rodada 1 (V2/V4/V5), e o Flow novo não mudou de lógica além das faixas.

## O que pode ter saído da org
Cadeia de salvar a oportunidade como ganha na dev (CPQ, Pedido, Caso, Tarefa, Protheus). Registros criados pela cadeia, todos ligados às contas de teste: 14 Casos, 14 Pedidos, 13 Tarefas, 15 Cotações (`Quote`) e 15 `SBQQ__Quote__c` (estas duas são do fixture). Todos apagados. Chamadas externas: `AccountTrigger` foi desviada com `TriggerUtility.bypassTrigger` na criação das contas, mas o save de oportunidade ganha roda a cadeia normal; **não conferi o resultado de chamada ao Protheus** nem logs de `IntegrationLog__c` gerados (a org tem 179 registros do dia, de origem não atribuída por mim; não consultei seus conteúdos). Se for preciso desfazer do outro lado, procure no Protheus pedidos de contas "TESTE EPLAST-47 Conta A" e "TESTE EPLAST-47 Borda 1..12".

## Limpeza
Apagados: Casos, Tarefas, Pedidos, `SBQQ__Quote__c`, `Quote`, 15 Oportunidades, 13 Contas, `Branch__c` e `PaymentTerms__c` com "TESTE EPLAST-47". Conferido: 0 contas e 0 filhos restantes. Usuário revertido (ver acima). Nenhum job agendado criado nem pendente. Nada ficou.

## Sem prova
V3 (Flow não dispara em salvamento sem mudança relevante), C11 (média vazia/0), V6/C16 (falha forçada, destinatário), C17/C18 (QA e volume), resultado das chamadas externas ao Protheus. Os critérios principais (classificação por faixa, bordas, soma sem perdida, relatório, agendado inativo) foram executados e passaram.
