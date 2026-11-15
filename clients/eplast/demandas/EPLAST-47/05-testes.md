**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`)
**Conferir depois de:** 2026-11-15 20:40 UTC

# EPLAST-47 — Testes (rodada 3, fase 1: armar de novo)

## Org
`sf org list`: só `sbx-eplast-qa` (Sandbox, Connected). É a QA. Pacote do build: `05-deploy-qa.md`, deploy `0AfHa00000EI0cbKAD` (Succeeded, 19:33Z). Flow `ScheduledFlowOpportunity`: v4 Active, criada 19:33:12Z (v1 a v3 Obsolete). Fuso da org: America/Sao_Paulo. Nenhum DML meu em registro; nada criado.

## Por que armei de novo
A armação anterior (job das 18:47Z) executou **antes** do novo build: o job rodou com a v3 e a esteira implantou a v4 só às 19:33Z. Esse resultado não vale para o build atual (veredito não emitido a partir dele). Como ainda não passou do horário de `Conferir depois de` e o build mudou, armei o job para a v4.

Observação para o builder, caso a execução da v4 repita o quadro (só como alerta, não é falha desta rodada): a execução da v3 deixou 391 linhas de `AccountHistory`, 396 contas em G (370 delas com média <= 160.000), soma de `LastMonthPurchaseValue__c` de 108.525.004,97 nas elegíveis (esperado 183.408.613,36), 162 `IntegrationLog__c` de ação `ScheduledFlowOpportunity` e 460 de `Send Client To Protheus` (saída externa autorizada).

## O que foi alterado para armar
- Deploy `0AfHa00000EI0fpKAD` (Succeeded, 19:37Z, `--target-org sbx-eplast-qa`), só dois itens, nada commitado:
  - Flow `ScheduledFlowOpportunity`: horário de início de 15:47 para **17:10** (fuso da org) = 20:10Z; o resto idêntico à v4. Cria versão nova ativa.
  - `ScheduledFlowOpportunitySetting.Default`: `RunDayOfMonth__c` de 14 para **15** (confirmado por query: 15).
- Próxima execução (`CronTrigger` `ScheduledFlowOpportunity-5`, WAITING): **2026-11-15T20:10:00Z**, conferido na org.
- **Como desfazer:** reimplantar o Flow original (início 15:47) e `Default` com `RunDayOfMonth__c` = 14; a esteira faz isso antes da fase 2. Se o job não rodar às 20:10Z, é falha (o dia 15 acaba às 03:00Z de 16/11).

## Estado de antes (contagens agregadas, QA, 15/11 19:4xZ, depois da execução da v3)
| Medida | Valor |
|---|---|
| Contas | 1.217 |
| Contas por `Ranking__c` | vazio 615; PP 54; P 116; M 23; G 396; GG 13; MP 0; 3G 0 |
| `AccountHistory` (linhas) | 391 (todas de 18:47Z) |
| Contas elegíveis (com ao menos 1 ganha) | 563; 8 com média vazia |
| Elegíveis por faixa da média (limite inclusive) | MP 207; PP 138; P 107; M 73; G 30; GG 0; 3G 0 |
| Dessas, já com o Ranking da faixa | MP 0; PP 11; P 29; M 11; G 26 |
| Soma de `LastMonthPurchaseValue__c` nas elegíveis | 108.525.004,97 |
| Soma das ganhas do ano com conta (`Amount`) | 183.408.613,36 |
| `IntegrationLog__c` total / ação `ScheduledFlowOpportunity` | 665 / 162 |

## Resultado esperado depois da execução da v4
- 100% das 555 elegíveis com média têm `Ranking__c` igual à faixa: MP 207; PP 138; P 107; M 73; G 30; GG 0; 3G 0 (faixa de cada conta por `AveragePurchasesThisYear__c`, limite inclusive). As 8 sem média mantêm o ranking.
- Soma de `LastMonthPurchaseValue__c` nas elegíveis: 183.408.613,36.
- `AccountHistory` novas linhas = contas cujo Ranking mudou: 207 + (138-11) + (107-29) + (73-11) + (30-26) = 478, no máximo, descontadas as que já estavam na faixa e as com Ranking anterior igual; nenhuma conta com mais de 1 linha nova.
- `IntegrationLog__c` de ação `ScheduledFlowOpportunity` novos: 0.
- Nenhum `UNABLE_TO_LOCK_ROW`.
- Pode ter saído da org: sincronização com o Protheus pelos updates de conta (autorizado); listar na fase 2.

## Casos
| Caso | Critério | Status nesta fase |
|---|---|---|
| 4 (1 atualização por conta) | 4 | aguardando execução |
| 6 (sem lock) | 6 | aguardando execução |
| 8, 9 (soma e vazio) | 8, 9 | aguardando execução |
| 10, 11 (faixas) | 10, 11 | aguardando execução |
| 14 (relatório de mudanças) | 14 | aguardando execução |
| 16 (falha com destinatário) | 16 | não executado: exige falha forçada em registro existente |
| 17, 18 | volume | não executado: sem número do cliente (P10) |
| 1 a 3, 5, 12, 13, 15 | configuração/documentação | comprovados nas rodadas anteriores (mesmo pacote); reconferir na fase 2 |
| 7 | período configurável | fora de escopo (D3) |
