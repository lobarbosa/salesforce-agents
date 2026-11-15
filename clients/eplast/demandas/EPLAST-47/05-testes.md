**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-15 21:00 UTC

# EPLAST-47 — Testes (rodada 3, fase 1: armar)

## Org
`sf org list`: só `sbx-eplast-qa` (Sandbox, Connected, Org ID `00DHa000006vZtmMAE`). É a QA. Nenhum deploy do build por mim; o pacote é o da esteira (`05-deploy-qa.md`, deploy `0AfHa00000EHrSrKAL`, Succeeded). Fuso da org: America/Sao_Paulo.

## Retorno da rodada 2
A FALHA 1 (Flow não exercitado) segue aberta: o Flow é agendado e não dispara por API. Nesta rodada ele é exercitado pela autorização do card de 15/11 01:13 (Leonardo Barbosa): dia de execução alterado para o dia do teste, job roda sobre as contas e oportunidades existentes, conferência só por contagens agregadas, dia volta para 14 ao final. Fica para a fase 2 (sessão depois do horário). Os casos de configuração 1 a 9 da rodada 2 não foram refeitos; o pacote é o mesmo.

## O que foi alterado para armar
- Registro `ScheduledFlowOpportunitySetting__mdt` `Default`: `RunDayOfMonth__c` de **14** para **15**, deploy `0AfHa00000EHrUTKA1` (Succeeded) só desse registro, `--target-org sbx-eplast-qa`. Conferido por query: `Default`, 15. Não commitado; a esteira descarta a alteração.
- Próxima execução do job (`CronTrigger` `ScheduledFlowOpportunity-3`, WAITING): **2026-11-15T18:47Z** (15:47 em São Paulo; dia 15 no fuso da org). Conferir depois das 21:00 UTC.
- **Como desfazer:** reimplantar `ScheduledFlowOpportunitySetting.Default` com `RunDayOfMonth__c` = 14 (a esteira reimplanta a configuração original no início da fase 2). Se o job não rodar às 18:47Z, o dia 15 vence à meia-noite de São Paulo (03:00Z de 16/11) e o job do dia 16 não executa a classificação; nesse caso é falha, não espera.

## Estado de antes (contagens agregadas, QA, 15/11 01:3xZ)
| Medida | Valor |
|---|---|
| Contas | 1.217 |
| Contas por `Ranking__c` | vazio 851; PP 136; P 180; M 27; G 5; GG 18; MP 0; 3G 0 |
| `AccountHistory` (linhas) | 0 |
| Oportunidades ganhas (`IsWon`), todas | 7.454 |
| Oportunidades ganhas do ano com conta (Fechado/Ganho, `ThisYear__c`) | 2.764, em 341 contas |
| Contas elegíveis (com ao menos 1 ganha) | 563; 8 com média vazia (Ranking não muda) |
| Elegíveis com valor de compras vazio | 457 |
| Soma de `LastMonthPurchaseValue__c` nas elegíveis | 12.468.370,41 |
| `IntegrationLog__c` total / com ação `ScheduledFlowOpportunity` | 52 / 0 |
| Pedidos (Order) | 10.320 |

## Resultado esperado depois da execução
Regra do Flow: por conta com ganha, soma das ganhas do ano em `LastMonthPurchaseValue__c`; classificação pela média (`AveragePurchasesThisYear__c`), até o limite inclusive; média vazia mantém.
- Faixa pela média, entre as 555 elegíveis com média: MP 207; PP 138; P 107; M 73; G 30; GG 0; 3G 0.
- Contas que mudam de classificação (entram em `AccountHistory`): MP 207 + PP 96 + P 62 + M 59 + G 27 = **451** linhas de histórico (Ranking anterior diferente ou vazio).
- Distribuição final de `Ranking__c` na org: MP 207; PP 138 + (136 não elegíveis ou inalteradas, a recalcular na fase 2 a partir da query das elegíveis); GG das elegíveis deixa de existir. Na fase 2 conferir por query: elegíveis com média por faixa (valores acima) e Ranking igual à faixa em 100% delas.
- Soma de `LastMonthPurchaseValue__c` nas 563 elegíveis: **183.408.613,36** (soma das ganhas do ano; contas sem ganha no ano ficam com o valor configurado, zero).
- `IntegrationLog__c` com ação `ScheduledFlowOpportunity`: 0 esperado (sem falha); se houver, ler só contagem e mensagem agregada.
- Nenhum `UNABLE_TO_LOCK_ROW` nos logs do job; cada conta atualizada uma vez (451 linhas de histórico, não mais; mais de uma linha por conta indica atualização repetida).
- Pode ter saído da org: sincronização com o Protheus pelos updates de conta (autorizado); listar na fase 2 o que a cadeia criou (IntegrationLog, pedidos, cotações).

## Casos
| Caso | Critério | Status nesta fase |
|---|---|---|
| 4 (1 atualização por conta) | 4 | aguardando execução (451 linhas de histórico, nenhuma conta com 2) |
| 6 (sem lock) | 6 | aguardando execução |
| 8, 9 (soma e vazio) | 8, 9 | aguardando execução (soma total 183.408.613,36; contas sem ganha no ano = valor configurado) |
| 10, 11 (faixas) | 10, 11 | aguardando execução (por faixa nas contagens acima) |
| 14 (relatório de mudanças) | 14 | aguardando execução (relatório mostra 451 mudanças) |
| 16 (falha com destinatário) | 16 | não executado: falha forçada exige alterar registro existente; só se o job gerar log |
| 17, 18 | volume P10 | não executado: P10 sem número do cliente |
| 7 | período configurável | fora de escopo (D3) |
| 1 a 3 | documentação | não reavaliado |
