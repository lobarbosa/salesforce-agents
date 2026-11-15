**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-47 — Verificação na dev

`sf org list` mostrou só `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, conectada). `Organization.IsSandbox = true`. Nada em QA nem em produção. Nenhum metadata alterado, nenhum registro criado ou apagado (nada a limpar).

## Por que inconclusiva
O critério principal, o comportamento do Flow (1 update por conta, faixas, média vazia ou zero, log de falha), não foi exercitado. Motivos que o builder não resolve:
1. `ScheduledFlowOpportunity` é um Flow agendado (Daily 15:47 UTC, dia 14 pela configuração). Não há disparo por API ou Apex. A única saída seria mudar `RunDayOfMonth__c`, que é configuração construída, e esperar o job. Não fiz isso nesta sessão.
2. A dev tem 0 contas e 0 oportunidades. Uma oportunidade ganha exige satisfazer as validation rules de Opportunity (Filial com Código ERP, condição de pagamento, catálogo, fases financeira e fiscal, proprietário com ID Protheus), segundo o `04-plano-build.md`. A autorização de 15/11 (card, 00:59) cobre só dado sintético mínimo "TESTE EPLAST-47", sem bypass de regra. Não criei dados, para não disparar a cadeia Order/Quote/CPQ/Protheus (porta 8400, cadastrada como produção) sem ter uma base viável.

**O que uma pessoa precisa fazer para provar:** o responsável decide entre (a) autorizar bypass de validation rule só na dev, ou a base CPQ/Protheus sintética, mais um dia de execução igual ao dia do teste e o job rodar às 15:47Z, com nova sessão do verificador depois; ou (b) o caminho do card das 01:13 na QA (dia coincidente, conferência por contagens agregadas, incluindo `AccountHistory`). Em ambos, volta o dia de execução para 14 ao final.

## Casos executados (estáticos, por metadata)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | 13 | describe de `Account.Ranking__c` | Ativos MP, PP, P, M, G, GG, 3G | `['MP','PP','P','M','G','GG','3G']`, restrita = true | passou |
| V2 | 10, 12 (faixas) | Query em `RankingRange__mdt` ORDER BY `SortOrder__c` | 7 faixas com tetos novos | MP 10000, PP 35000, P 80000, M 160000, G 500000, GG 1000000, 3G sem teto, ordem 1 a 7 | passou |
| V3 | 12 | grep no XML do Flow no repo (`clients/eplast/force-app/.../ScheduledFlowOpportunity.flow-meta.xml`) por `10000`, `70000`, `150000`, `500000` como valor literal | 0 ocorrências | 0 (as faixas vêm do mdt). O XML do repo foi lido, não um retrieve da dev | passou (estático) |
| V4 | 15 | grep por `levora` e endereço de e-mail no XML | 0 | 0 | passou (estático) |
| V5 | 5 | Leitura do `GetOpportunities` no XML | Filtro por `AccountId` | Campo `AccountId` no filtro (linha 447); `GetOpportunities2` removido | passou (estático) |
| V6 | 7 (parcial) | Query de `Flow` na dev e leitura do XML | v2 Active; dia vem da configuração | v1 Obsolete, v2 Active; `CheckDayMonth` usa `GetSetting.RunDayOfMonth__c` | passou (estático). O critério 7 do analista saiu do escopo (D3) |
| V7 | 16 (parcial) | Contagem de `IntegrationLog__c` com `IntegrationAction__c = ScheduledFlowOpportunity` | Base zerada, sem execução prévia | 0 | só estado; caminho de falha não exercitado |
| V8 | 4 | Dar 3 ganhas à conta A e 1 à B e rodar o job | A e B atualizadas 1 vez cada | Não executado: sem disparo e sem base (ver acima) | não executado |
| V9 | 8, 9 | Soma ignora perdida; conta sem ganha | 5.000; valor configurado | Não executado | não executado |
| V10 | 10, 11, 17 | 12 valores de fronteira, zero e vazio | MP / PP / PP / P / P / M / M / G / G / GG / GG / 3G | Não executado | não executado |
| V11 | 14 | Relatório `AccountRankingChanges` mostra N mudanças | N contas, anterior e novo | Não executado (sem histórico gerado) | não executado |
| V12 | 16 | Falha forçada com e sem destinatário | Log sempre; e-mail só com destinatário | Não executado | não executado |
| V13 | 6, 18 | 50 contas sem `UNABLE_TO_LOCK_ROW`; volume | Zero erros | Não executado; P10 sem número do cliente | não executado |

Critérios 1 a 3 são de documentação (análise e recon), fora do escopo da verificação de build.

## O que pode ter saído da org
Nada. Nenhum registro foi criado, então a cadeia Order/Quote/CPQ/Protheus não foi acionada.
