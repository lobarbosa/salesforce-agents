**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`)

# EPLAST-47 — Verificação do build, rodada 2 (classificar a conta ao salvar a oportunidade)

`sf org list` mostrou só `sbx-eplast-dev` (sandbox, a "QA" da Eplast, regra 5 da conta), conectada, usuário de teste da conta (Id `005bJ00000piKAaQAM`). Todo comando passou `--target-org` explícito. Nada na QA, em produção ou no Marketing Cloud. Sem deploy e sem alteração na metadata do builder.

## Resultado

Tudo o que dá para exercitar na dev passou: as duas falhas da rodada 1 estão corrigidas, as 12 bordas do critério 10 e a média 0 do critério 11 deram o esperado, e o relatório mostra as mudanças. Fica **sem prova**: (a) a falha forçada (V6, critério 16), que o builder já remeteu à QA; (b) o ramo "média vazia mantém o ranking" do critério 11, que não consegui provocar na dev (ver abaixo). Por isso o veredito é inconclusiva, não reprovada: nenhum caso executado falhou.

## Falhas da rodada 1

| Falha | Corrigida? | Evidência |
|---|---|---|
| FALHA 1 (faixas fora de ordem, 3.000 virava G) | Sim | Conta com ganha de 3.000 ficou `MP`; as 12 bordas abaixo deram a faixa certa |
| FALHA 2 (filtro do relatório) | Sim | Analytics API: filtro `field_key` = `Ranking`, contagem 15 para 15 contas de teste |

## Casos

Dados: contas e oportunidades Indústria "TESTE EPLAST-47 ..." (15 de cada), cada conta com 1 oportunidade, 1 `Quote` com `Status` = `Approved` e `SyncedQuoteId` na oportunidade (exigência do `OpportunityFlow`, `GetPrimeQuote`). Conta criada com `TriggerUtility.bypassTrigger` e com `DuplicateRuleHeader.allowSave` (a regra de duplicidade recusava contas parecidas). Setup e o save para `Fechado/Ganho` em execuções de Apex anônimo separadas. Fixture base: `clients/eplast/fixtures/eplast47-base.apex` (sem alteração; a variante com cotação e várias contas foi montada em arquivo temporário).

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | 8, 10, 14 | Conta 1, ganha de 3.000, save para `Fechado/Ganho` | `Ranking__c` MP, `LastMonthPurchaseValue__c` 3.000, 1 linha de histórico | `Ranking__c`=MP, `LastMonthPurchaseValue__c`=3000, `AveragePurchasesThisYear__c`=3000; `AccountHistory` com 1 linha de `Ranking__c` (null para MP) | passou |
| C10-1 | 10 | Média 10.000 | MP | MP | passou |
| C10-2 | 10 | Média 10.000,01 | PP | PP | passou |
| C10-3 | 10 | Média 35.000 | PP | PP | passou |
| C10-4 | 10 | Média 35.000,01 | P | P | passou |
| C10-5 | 10 | Média 80.000 | P | P | passou |
| C10-6 | 10 | Média 80.000,01 | M | M | passou |
| C10-7 | 10 | Média 160.000 | M | M | passou |
| C10-8 | 10 | Média 160.000,01 | G | G | passou |
| C10-9 | 10 | Média 500.000 | G | G | passou |
| C10-10 | 10 | Média 500.000,01 | GG | GG | passou |
| C10-11 | 10 | Média 1.000.000 | GG | GG | passou |
| C10-12 | 10 | Média 1.000.000,01 | 3G | 3G | passou |
| C11a | 11 | Contas 14 e 15 criadas com `Ranking__c`=GG; ganha com valor 0 (conta 14) e com `Amount` nulo (conta 15) | Média 0 vira MP, não GG; soma gravada 0 | Ambas: `Ranking__c` GG para MP (histórico GG para MP), `LastMonthPurchaseValue__c`=0, média 0 | passou |
| C11b | 11 | Média vazia mantém o ranking | Ranking não muda | Não consegui provocar: o `OpportunityFlow` grava a média em toda ganha (nulo vira 0), então o Flow novo nunca recebe média vazia por um save de oportunidade | não executado |
| C14 | 14 | Analytics API do relatório `AccountRankingChanges` (id `00OHa000002z8ifMAA`), com detalhe | N linhas para N contas, com valor anterior e novo | 15 linhas para as 15 contas; colunas `field_key`=Ranking, `OLDVAL`, `NEWVAL` (ex.: GG e MP); filtro `field_key` igual a `Ranking` | passou |
| V6 | 16 | Falha forçada de `UpdateAccount` | `IntegrationLog__c` do Flow, venda salva, sem e-mail | Não executado: as validation rules de telefone impedem gravar conta inválida e não há dado legado inválido na dev. `IntegrationLog__c` com ação `Opportunity_AfterSave_ClassificaConta`: 0 | não executado |
| D1 | estado | `FlowDefinition` (Tooling) | Estado do Flow novo e do agendado | `Opportunity_AfterSave_ClassificaConta`: versão ativa 2, última 2. `ScheduledFlowOpportunity`: versão ativa 2, última 2 (ativo, intocado). `OpportunityFlow`: ativa 2. Não alterei nada | passou |

Não reexecutados nesta rodada (o que o builder mudou foi só a seleção de faixa e o filtro do relatório): V2 (ordem e média), V3, V4, V5 e V7 da rodada 1 seguem como estavam, todos passados. Critério 13 (picklist de 7 valores) não repetido; as 7 classificações apareceram nos resultados acima. Critérios 4 a 7, 9, 17 e 18 dependem da QA ou foram redefinidos no design.

## Observação sobre a ativação (sem ação minha)

A v2 de `Opportunity_AfterSave_ClassificaConta` está ativa na dev, como o builder disse. Os dois Flows (novo e agendado) coexistem; a desativação do `ScheduledFlowOpportunity` segue passo separado, depois de V6 provado na QA.

## Alterações no usuário de execução (revertidas)

- `User` `005bJ00000piKAaQAM`: `ProtheusSellerId__c` de vazio para `T47` (validation rule `CheckAccountOwnerHasProtheusSellerId`). Devolvido a vazio, conferido por SOQL (nulo).
- Nenhuma alteração de perfil, permission set ou papel. Nenhum debug level criado nesta rodada.

## O que pode ter saído da org

A cadeia do save de ganha chama o Protheus (`OpportunityTrigger`/`AccountTrigger`). Pelas contagens agregadas, a cadeia criou 63 `IntegrationLog__c` durante a verificação (48 nos saves, 15 na exclusão dos registros de teste), todos com ação `Send Client To Protheus` e resposta `Erro(Unauthorized)`: o Protheus recusou todas as chamadas, nada foi aceito do outro lado. Não houve e-mail (destinatário de falha vazio) nem nada no Marketing Cloud. Pedidos, casos e tarefas criados pela cadeia: 15 de cada, todos ligados às contas de teste, apagados. Nenhum log do Flow novo (falha) foi gerado.

## Limpeza

Apagados: 15 contas, 15 oportunidades, 15 cotações, 15 pedidos, 15 casos, 15 tarefas, filial e condição de pagamento de teste (contagem por SOQL: 0 de cada) e os 63 `IntegrationLog__c` gerados por esta verificação (identificados pela janela de horário e pela diferença de contagem: 33 antes, 33 depois). Ficam na dev os 33 `IntegrationLog__c` anteriores, que não são meus. Nenhum job Apex agendado criado.

## O que falta para provar

1. V6 (critério 16): na QA, com conta de dado legado que faça o `UpdateAccount` falhar, conferir o `IntegrationLog__c` e que a oportunidade foi salva.
2. C11b: média vazia. Só se prova na QA com conta cuja média esteja realmente vazia ao salvar, ou aceitar que o `OpportunityFlow` torna o caso inalcançável.
