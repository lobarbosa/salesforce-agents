**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-47 — Verificação do build (nova rodada, depois da rodada 4 de QA)

`sf org list` mostrou só `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, a "QA" da Eplast, regra 5 da conta), conectada. Todo comando com `--target-org` explícito. Nada na QA, em produção ou no Marketing Cloud. Sem deploy. Casos derivados dos critérios da análise e do design (V1 a V7), não do plano de build.

## Resultado

Aprovada. As duas falhas da rodada 1 estão corrigidas, o agendado antigo está desativado na dev e as 14 classificações (12 bordas do critério 10 mais 3.000 e 5.000) saíram certas. Critério 16 (falha forçada) segue **sem prova**, por decisão do design de 2026-11-17: fica para a homologação.

## Falhas da rodada 1 (`04-verificacao-rodada-1.md`)

- **FALHA 1 (faixas fora de ordem): corrigida.** Média 3.000 e 5.000 agora dão `MP` (antes `G`); as 12 bordas passam (tabela).
- **FALHA 2 (filtro do relatório): corrigida.** `AccountRankingChanges` tem o filtro `field_key` igual a `Ranking` e a Analytics API devolve 14 linhas com 14 históricos de `Ranking__c` das contas de teste.

## Casos

Dados sintéticos "TESTE EPLAST-47": 14 contas (criadas com `TriggerUtility.bypassTrigger`), 14 oportunidades Indústria, cada uma com cotação padrão `Approved` e `SBQQ__Quote__c` primária. Scripts em `fixtures/eplast47-base.apex` (base) e `fixtures/eplast47-cotacao.apex` (cotação, novo). Cada oportunidade foi salva para `Fechado/Ganho` em execução de Apex anônimo própria (uma transação por conta). Primeira tentativa sem cotação: média não é calculada pelo `OpportunityFlow`, nada classificado; apaguei tudo e refiz com cotação.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| D1 estado | 15 e design | `Flow` por Tooling API; `CronTrigger` `ScheduledFlowOpportunity%` | Flow novo v2 Active; agendado sem versão ativa e sem agendamento | `Opportunity_AfterSave_ClassificaConta` v1 Obsolete, v2 Active; `ScheduledFlowOpportunity` v1 e v2 Obsolete; `CronTrigger`: 0 | passou |
| C10 bordas | 10 | Ganha única com valor 10.000; 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000; 1.000.000,01 | MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G | SOQL em `Account.Ranking__c`: MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G | passou |
| FALHA 1 reteste | 10 | Ganha única de 3.000 e de 5.000 | MP | MP e MP; `LastMonthPurchaseValue__c` 3000 e 5000, média igual | passou |
| V1 soma e histórico | 8, 14 | Mesma massa | Soma = valor ganho; 1 linha de histórico por conta | Somas iguais aos valores; `AccountHistory` `Field='Ranking__c'` das contas de teste: 14 | passou |
| V2 ordem/média (R1) | design R1 | Média gravada pelo `OpportunityFlow` já visível ao Flow novo, pois a classificação bate com a média da própria venda em todas as 14 contas | Flow novo depois do `OpportunityFlow` | Classificação correta nas 14 (só possível com a média nova). Log de ordem não refeito; a rodada 1 já provou (linhas 182 e 776 do log) e o Flow novo não mudou de ordem | passou |
| C11 média vazia | 11 | Conta 0 (3.000): oportunidade passou a `Fechado/Perdido` | Soma 0; média vazia mantém o ranking, sem cair em GG | `LastMonthPurchaseValue__c` 0; média vazia; Ranking `MP` mantido; histórico segue 1 linha | passou |
| C11 média 0 | 11 | Não provocado: o `OpportunityFlow` não grava média 0 neste cenário | MP | — | não executado (já registrado em QA; PA3) |
| C14 relatório | 14 | `GET /analytics/reports/00OHa000002z8ifMAA?includeDetails=true` (só contagem e filtro) | Filtro `Ranking`; 1 linha por mudança | Filtro `field_key equals Ranking`; 14 linhas com 14 mudanças de teste | passou |
| V3 só `Description` | design 1.3 | Não repetido nesta rodada | — | A rodada 1 passou; o Flow novo não mudou | não executado (coberto na rodada 1) |
| V5 20 ganhas | design 3.2 | Não repetido | — | Rodada 1: 20 interviews, CPU 3%, sem "Duplicate id". Lógica de soma não mudou | não executado (coberto na rodada 1) |
| Limites de fila | 6 | Contagem de `IntegrationLog__c` de hoje por ação | 0 da ação `Opportunity_AfterSave_ClassificaConta`; 14 saves sem erro | 0 da ação nova; 14 saves completos sem exceção | passou |
| V7 XML | 12, 15 | Rodada 1 (grep sem faixa nem e-mail); faixas só em `RankingRange__mdt` (7 faixas, `SortOrder__c` 1 a 7) | Sem limites nem e-mail fixos | Conforme na rodada 1; XML da v2 muda só a seleção de faixa | passou (rodada 1) |
| V6 / 16 | 16 | Falha forçada de `UpdateAccount` | `IntegrationLog__c`, venda salva, e-mail só com destinatário | Não exercitável pela esteira (decisão 2026-11-17: validation rules impedem conta inválida; leitura do Flow mostra fault, `LogFault`, `HasRecipient`; `FaultRecipient__c` vazio) | não executado — validar na homologação |

Critérios 5, 7, 17 e 18 não se aplicam a esta etapa (design, seção 8, e QA).

## Alterações no usuário de execução (revertidas)

- `User` `005bJ00000piKAaQAM` (conta de serviço, identificado só pelo Id): `ProtheusSellerId__c` de vazio para `T47` (necessário para a validation rule `CheckAccountOwnerHasProtheusSellerId`). **Devolvido a vazio** e conferido por SOQL (nulo). Sem mudança de perfil, permission set, papel ou "Marketing User". Usuário `005bJ00000hBJmYQAW` inativo, não usado.

## O que pode ter saído da org

- A cadeia do save de ganha criou, ligados às contas de teste: 14 pedidos, 14 cotações padrão (as que criei), 14 casos, 14 tarefas. Todos apagados.
- `IntegrationLog__c` de hoje: 105, todos `Send Client To Protheus` com `Erro(Unauthorized)`: o Protheus recusou, nada foi aceito do outro lado. **Não apaguei**: não separo os meus dos de outras execuções do dia (só apago o que criei).
- Nenhum e-mail enviado (destinatário de falha vazio). Nada no Marketing Cloud.

## Limpeza

Contagem final por SOQL: 0 conta, 0 oportunidade, 0 cotação, 0 pedido, 0 caso de teste; filial e condição de pagamento de teste apagadas. Ficaram na dev só os `IntegrationLog__c` acima. Nenhum job agendado a remover (`CronTrigger` 0).
