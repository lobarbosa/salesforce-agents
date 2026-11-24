**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-47 — Verificação do build (rodada 3: classificar a conta ao salvar a oportunidade)

`sf org list` mostrou só `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, a "QA" da Eplast, regra 5 da conta), conectada. Nada foi feito na QA, em produção ou no Marketing Cloud. Sem deploy. Todo comando passou `--target-org` explícito. Os casos foram derivados do design (V1 a V7) e dos critérios de aceite da análise, não do plano de build.

## Resultado

Reprovada por duas falhas no que o builder entregou (abaixo). A prova de ordem exigida pelo design (R1) **passou**: o Flow novo roda depois do `OpportunityFlow` e lê a média já recalculada. O design não precisa voltar; o build precisa de correção.

## Falhas para o builder

### FALHA 1 — `GetRanges` devolve as faixas fora de `SortOrder__c`, e a conta recebe a classificação errada
- **Reproduzir:** conta com 1 oportunidade ganha de 3.000 (média 3.000) e cotação aprovada; salvar a oportunidade em `Fechado/Ganho` com `Opportunity_AfterSave_ClassificaConta` ativo.
- **Obtido:** `Ranking__c` = `G`. No debug log, `GetRanges` devolve as 7 faixas na ordem `G, GG, M, MP, ...` (ordem alfabética do `DeveloperName`, com `X3G` por último), e `LoopRanges` para na primeira que contém a média (`G`, limite 500.000). Repetido com média 5.000 e 3.333,33: continuou `G`.
- **Esperado:** `MP` (média até 10.000, critério 10). Faixas lidas por `SortOrder__c` ascendente (1 a 7).
- **Causa provável:** o XML tem `sortField` = `SortOrder__c` e `sortOrder` = `Asc` no Get Records de `RankingRange__mdt`, mas o Flow não aplicou a ordenação nessa consulta de metadado customizado em runtime (o log mostra a ordem do `DeveloperName`). A correção é ordenar no próprio Flow, não depender do sort do Get: por exemplo, comparar cada faixa pelo limite e escolher a de menor `UpperLimit__c` que contém a média, ou percorrer a coleção só depois de ordená-la.
- **Reflexo:** todos os casos de borda do critério 10 e 11 (média 0 vira MP) ficam errados enquanto isso não for corrigido. Os 12 valores de borda não foram executados por causa disso: só dá para provar depois da correção.

### FALHA 2 — filtro do relatório `AccountRankingChanges` não casa com o histórico
- **Reproduzir:** Analytics API, `GET /analytics/reports/00OHa000002z8ifMAA` (só contagem de agregados), com a conta de teste com 1 linha de `AccountHistory` para `Ranking__c`.
- **Obtido:** com o filtro do build (`field_key` igual a `Ranking__c`), a contagem é 0. Sem filtro, 2 linhas (`Criado` e `Ranking`).
- **Esperado:** 1 linha de mudança de classificação (critério 14).
- **Causa provável:** a coluna `field_key` guarda o **rótulo** do campo. Rodando em execução avulsa (sem salvar) com o valor `Ranking` (rótulo de `Account.Ranking__c`) a contagem foi 1. O plano de build já previa essa troca; agora está provada. Trocar o valor do filtro para `Ranking`.

## Casos

Dados sintéticos "TESTE EPLAST-47": 1 conta (criada com `TriggerUtility.bypassTrigger`), 3 oportunidades Indústria de 3.000, 7.000 e 0 com cotação padrão aprovada sincronizada, e 20 oportunidades de 100 já ganhas. Script em `clients/eplast/fixtures/eplast47-base.apex`. Cada save de oportunidade foi uma execução de Apex anônimo própria, com debug log (Workflow FINER).

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | 8, 10 (faixa), 14 | Opp 1 (3.000) para `Fechado/Ganho` | `Ranking__c` da faixa da média (MP), `LastMonthPurchaseValue__c` = soma, 1 linha em `AccountHistory` | Soma 3.000 correta; 1 linha de histórico; ranking `G` em vez de `MP` | falhou (FALHA 1) |
| V2 ordem | design R1 | Opp 2 (7.000) para `Fechado/Ganho`, debug log | `Opportunity_AfterSave_ClassificaConta` depois de `OpportunityFlow` | `Fluxo Oportunidade` inicia na linha 182 do log e o Flow novo na 776 (sem `triggerOrder` no primeiro, 1500 no segundo, conferido em `FlowDefinitionView`) | passou |
| V2 média | design R1 | Mesmo save; média antes do save 3.000 | `GetAccount` com a média já recalculada | `GetAccount` devolveu `AveragePurchasesThisYear__c=5000.00` (e `LastMonthPurchaseValue__c=3000.00` ainda antigo); conta gravada depois com soma 10.000 | passou |
| V2 contagens | design 5 | Mesmo save, contagem no log | updates de Account e jobs dentro do limite | 3 rodadas de `AccountTrigger BeforeUpdate`: 1 do `OpportunityFlow` (`UpdateAccount`, antes do Flow novo), 1 do Flow novo, 1 posterior que não consegui atribuir a um Flow. Jobs em fila: 4 de 50. SOQL do save: 17 de 100 | passou (a 3a origem fica sem atribuição) |
| V3 | design 1.3 | Salvar Opp 2 só mudando `Description` | Flow novo não aparece | Só `Oportunidade Indústria` e `Fluxo Oportunidade` iniciaram; Flow novo ausente | passou |
| V4 | design 1.2 `HasChanges` | Opp 3 (valor 0) para ganha: soma e ranking iguais | `HasChanges` falso, Flow novo não grava | `HasChanges` avaliado; o único `UpdateAccount` do log é do `OpportunityFlow` (outra interview); `GetAccount` Last=10.000, Ranking=G, média 3.333,33 | passou |
| V5 | design 3.2 | 20 oportunidades ganhas da mesma conta numa inserção | Sem "Duplicate id in list"; CPU < 70% | Executou sem erro, 20 interviews do Flow novo, CPU máxima 482 ms de 15.000 (3%), SOQL 11 de 100; soma da conta 12.000 | passou |
| V6 | 16 | Falha forçada de `UpdateAccount` | `IntegrationLog__c` criado, oportunidade salva, sem e-mail | Não executado: as 4 validation rules de telefone impedem gravar a conta com telefone inválido, e o `TriggerUtility.bypassTrigger` não as desliga. Sem dado legado inválido na dev | não executado |
| V7 | 12, 15 | Grep no XML do Flow novo por 10000, 35000, 70000, 80000, 150000, 160000, 500000, 1000000 e por e-mail | Nenhum limite nem e-mail fixo | Nenhuma ocorrência; limites vêm de `RankingRange__mdt` (7 faixas conferidas por SOQL) | passou |
| C13 | 13 | Não repetido (já coberto pelo recon) | 7 valores ativos | Não executado nesta verificação | não executado |
| C14 | 14 | Analytics API, só contagem | 1 mudança | 0 com `Ranking__c`, 1 com o rótulo `Ranking` | falhou (FALHA 2) |
| D1 | estado | `FlowDefinitionView` e `FieldDefinition` | Flow novo Active/1500; `ScheduledFlowOpportunity` ativo (de propósito); descrição de `RunDayOfMonth__c` nova | Conforme | passou |
| C11 | 11 | Média vazia mantém o ranking; média 0 vira MP | — | Não executado: depende de a FALHA 1 estar corrigida; o ramo `AverageEmpty=false` foi visto no log | não executado |

Critérios 4 a 7, 9, 16 (parcial), 17 e 18 dependem de QA (sandbox de QA) ou foram redefinidos no design; não se aplicam a esta etapa.

## Alterações no usuário de execução (revertidas)

- `User` `005bJ00000piKAaQAM` (usuário de teste da conta, conta de serviço da Konecta; identificado só pelo Id): `ProtheusSellerId__c` de vazio para `T47`, necessário para a validation rule `CheckAccountOwnerHasProtheusSellerId`. **Devolvido a vazio** ao final (conferido por SOQL).
- Debug level `T47` e trace flag criados na dev para ver os Flows no log; **ambos apagados**.
- Nenhuma alteração de perfil, permission set ou papel.

## O que pode ter saído da org

A cadeia do save de oportunidade ganha chama o Protheus pela `OpportunityTrigger` e pela `AccountTrigger`. Registros criados pela cadeia e pelos scripts:

- Pedidos: 5; Cotações: 3; Casos: 23; Tarefas: 1; todos ligados à conta de teste. Todos apagados.
- `IntegrationLog__c` de hoje: 16, todos com ação `Send Client To Protheus` e resposta `Erro(Unauthorized)`. O Protheus recusou todas as chamadas, nada foi aceito do outro lado. **Não apaguei:** não consegui separar os meus dos de outras execuções do dia por filtro de nome, e só devo apagar o que criei.
- Nenhum e-mail enviado (destinatário de falha vazio; nada no Marketing Cloud).

## Limpeza

Apagados: conta, 23 oportunidades, 3 cotações, 5 pedidos, 23 casos, 1 tarefa, filial e condição de pagamento de teste (contagem por SOQL: 0 de cada). Histórico de campo da conta apagado junto com ela. Ficaram na dev apenas os 16 `IntegrationLog__c` acima. Fixture gravada em `clients/eplast/fixtures/eplast47-base.apex`.

## Para a nova rodada (builder)

1. Corrigir a ordem das faixas (FALHA 1) e reexecutar V1, C10 (12 bordas) e C11.
2. Trocar o valor do filtro do relatório para o rótulo `Ranking` (FALHA 2).
3. V6 segue sem prova na dev; fica para a QA, onde há conta com dado legado, ou para alguém forçar a falha por outro meio.
