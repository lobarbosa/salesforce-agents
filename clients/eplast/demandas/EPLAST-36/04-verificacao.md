**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-36 — Verificação do build (reverificação, 2026-11-15)

`sf org list` mostrou uma única org, `sbx-eplast-dev` (Sandbox, Connected), que é a "QA" da Eplast usada como dev da esteira (regra 5 da conta). QA da esteira e produção não tocadas. Nada feito no Marketing Cloud. `force-app/` não alterado.

Diferença para a rodada anterior: desta vez criei massa sintética `TESTE EPLAST-36` e executei os relatórios de verdade (Analytics REST, `includeDetails=true`). A dev tinha 0 Accounts, então os resultados dos relatórios vêm só da massa de teste.

## Resultado em uma frase
Região, segmento (Conta e Lead), Inativos, Sazonais e opt-out foram provados com dados e passaram. Histórico de compra (faixas de recência), relatório de produto e acesso negado **não foram provados**: ficam sem prova pelo motivo abaixo.

## Por que inconclusiva
`Account.LastPurchase__c` é um roll-up (max de `Opportunity.CloseDate` com `StageName = Fechado/Ganho`), não é gravável. Para ter data de última compra é preciso criar Oportunidade ganha. A validação da Oportunidade exige, em cadeia, Filial com código ERP, condição de pagamento, endereço, CNAE, razão social, e-mail da Conta e **"ID Usuário Protheus" no registro do Proprietário da Conta**. Os quatro primeiros eu satisfiz com dados sintéticos. O último é campo do usuário proprietário (registro que não criei); não o alterei (regra de não alterar o que não é meu) e não há licença livre para criar usuário de teste (14 de 14, segundo o assessment). A criação das Oportunidades falhou nesse ponto. Order/OrderItem para o relatório de produto dependem de Pricebook, Produto e Oportunidade, e têm trigger com envio ao Protheus na atualização, por isso não foram montados.

## O que uma pessoa precisa fazer para provar o restante
1. Na dev, preencher `ProtheusSellerId__c` de um usuário de teste (ou liberar o uso do proprietário atual) e criar Oportunidades `Fechado/Ganho` com `CloseDate` em hoje-90, -91, -180, -181, -365, -366 e uma Conta sem compra. Esperado: cada Conta cai em exatamente uma faixa (`COMPRA - ÚLTIMOS 90 DIAS`, `SEM COMPRA - 91 A 180`, `181 A 365`, `MAIS DE 365`); Conta sem data não aparece em nenhuma.
2. Criar Order e OrderItem sintéticos e rodar `PRODUTO - CONTAS POR PRODUTO COMPRADO`.
3. Atribuir `PS_Marketing_Publicos` a um usuário de teste e conferir o acesso; usar um usuário sem o PS para o cenário negativo.

## Massa criada (toda com `TESTE EPLAST-36` no nome)
7 Contas A1..A7, cada uma com 1 Contato; 3 Leads L1..L3; 1 Filial, 1 Condição de pagamento e 7 vínculos Conta x Condição (só para tentar a Oportunidade).

| Conta | Type | UF | Setor | Opt-out do Contato |
|---|---|---|---|---|
| A1 | Recorrente | SP | Alimentos | não |
| A2 | Recorrente | SP | Alimentos | **sim** |
| A3 | Recorrente | PR | PET | não |
| A4 | Inativo | MG | Bebidas | não |
| A5 | Recorrente | RJ | Alimentos | não |
| A6 | Sazonal | SP | Bebidas | não |
| A7 | Recorrente | SP | Alimentos | não |

Leads: L1 Alimentos sem opt-out; L2 Alimentos com opt-out; L3 Bebidas sem opt-out.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V01 | Público por região | Executei `RECORRENTES (ATIVOS) - SP` | A1 e A7. Fora: A2 (opt-out), A3, A4, A5, A6 (Sazonal) | 2 linhas: A1, A7 | passou |
| V02 | Público por região | Executei `RECORRENTES (ATIVOS) - SUL` e `- RJ` | SUL: A3 (PR). RJ: A5 | SUL: A3 (1). RJ: A5 (1) | passou |
| V03 | Região, geral | Executei `RECORRENTES (ATIVOS) - GERAL` | Recorrentes sem opt-out: A1, A3, A5, A7 | 4 linhas: A1, A3, A5, A7 (A2 fora, Sazonal e Inativo fora) | passou |
| V04 | Segmento | Executei `SEGMENTO - ALIMENTOS`, `- BEBIDAS`, `- PET (BEM-ESTAR ANIMAL)`, `- INDUSTRIAL` | ALIM: A1, A5, A7 (A2 fora por opt-out). BEB: A4, A6. PET: A3. INDUSTRIAL: vazio | ALIM: A1, A5, A7. BEB: A4, A6. PET: A3. INDUSTRIAL: 0 | passou |
| V05 | Segmento de Lead | Executei `LEADS - SEGMENTO - ALIMENTOS`, `- BEBIDAS`, `- INDUSTRIAL` | ALIM: L1 (L2 fora por opt-out). BEB: L3. IND: vazio | ALIM: L1. BEB: L3. IND: 0 | passou |
| V06 | Inativos | Executei `INATIVOS - GERAL` | A4 | A4 (1) | passou |
| V07 | Sazonais (relatório pré-existente, região SP) | Executei `SAZONAIS - SP` | A6 | A6 (1) | passou |
| V08 | Opt-out respeitado | A2 e L2 têm opt-out; conferidos em V01, V03, V04, V05 | A2 e L2 nunca aparecem | Ausentes em todos os relatórios acima | passou |
| V09 | Combinar critérios (região E segmento) | Provado pela interseção dos resultados de V01 e V04 (A1 e A7 estão em SP e Alimentos; A2 por opt-out; A5 só em Alimentos RJ). Não rodei um relatório com os dois filtros juntos | Pares distintos não se misturam | Consistente, sem relatório combinado | passou (indireto) |
| V10 | Histórico de compra, faixas | Tentei criar Oportunidades ganhas nas fronteiras 90/91/180/181/365/366. `COMPRA - ÚLTIMOS 90 DIAS` e `SEM COMPRA - MAIS DE 365 DIAS` rodaram vazios | Cada Conta em uma faixa | Oportunidade bloqueada pela validação (ID Usuário Protheus do proprietário). Relatórios rodam sem erro, mas sem dado de compra | não executado |
| V11 | Produto por Conta | `PRODUTO - CONTAS POR PRODUTO COMPRADO` rodou sem erro e vazio; sem Order/OrderItem | Contas por produto, sem valores | Sem massa de pedido | não executado |
| V12 | Acesso negado sem PS/pasta | Sem usuário de teste e sem PS atribuído | Usuário sem permissão não vê | Não executado | não executado |
| V13 | Público não grava em registro | Antes e depois das execuções, Account/Contact/Lead não receberam campo novo; build é só relatório e permission set (sem Flow, Apex ou campo novo) | Nada gravado | Nenhuma diferença nos registros de teste; relatórios só leem | passou |
| V14 | Sem erro nos 58 relatórios | Já verificado na rodada anterior (metadata, descrição, duplicado, PS). Não repeti, e nada mudou no build | 58 com descrição, PS sem ViewAll/ModifyAll/Export | Rodada anterior: conforme | passou (herdado da rodada anterior) |

Falhas da rodada anterior: a rodada anterior era inconclusiva por falta de massa, sem falhas abertas. Os casos C10 (contagem com dados), antes não executado, agora estão cobertos por V01 a V08; C11 e C12 seguem sem prova (V12, V11).

## Efeitos colaterais da ordem de execução (assessment)
A demanda não grava em Account/Opportunity/Order; só relatórios. Mesmo assim a inserção da massa passou pelo `AccountTrigger` e pelos Flows da org. Anotado: a tentativa de Oportunidade expôs 5 validações em cadeia (Filial/ERP, condição de pagamento, endereço, CNAE/razão social/e-mail, ID Protheus do proprietário), útil para o QA montar massa.

## Observações (não são reprovação)
1. `PRODUTO - CONTAS POR PRODUTO COMPRADO` não tem filtro de opt-out (`OrderItemList` não expõe `EMAIL_OPT_OUT`). Se alimentar envio, aplicar opt-out em outro ponto. Confirmar com o arquiteto.
2. `ObjectPermissions` de `PS_Marketing_Publicos` não lista `OrderItem`, apesar do plano. Conferir na homologação com usuário real.
3. `LEADS - NO/NE` não existe (lacuna já declarada pelo builder); Leads têm 8 setores, não 9.

## O que pode ter saído da org
- Para não disparar a consulta de CNPJ (callout do `AccountTrigger` após insert/update) e o handler de Oportunidade, as inserções e atualizações da massa rodaram em Apex anônimo com `TriggerUtility.bypassTrigger = true` (variável estática, só vale naquela execução; a configuração `TriggerUtility__mdt` não foi alterada, segue `false`). Os Flows record-triggered continuaram ativos.
- Nenhuma Order foi criada ou atualizada, então não houve envio ao Protheus (o `OrderTrigger` só age em update). Nenhuma Oportunidade foi criada (todas falharam na validação). Nenhum envio de e-mail, nenhum envio ao Marketing Cloud. Não consultei o log de integração; nenhum registro de Task, Quote ou Order apareceu (contagens 0).
- Obs.: os 3 Leads passaram pelo Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (regra de atribuição interna).

## Limpeza
Apaguei toda a massa por Apex anônimo (Leads, vínculos de condição de pagamento, Contatos, Contas, Condição de pagamento, Filial). Contagens agregadas depois: Account 0, Contact 0, Lead 0, Opportunity 0, Order 0, Quote 0, Task 0, PaymentTerms__c 0, Branch__c 0, RelationshipAccountsPaymentTerm__c 0 (a dev estava toda zerada antes). Nada ficou. Nenhum job Apex agendado criado (CronTrigger = 0).
