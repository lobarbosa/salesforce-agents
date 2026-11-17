**Resultado do build:** concluído

# EPLAST-33 — Plano de build (rodada 17/11, `dev-apex`)

**Org de build:** `sbx-eplast-dev` (conta de serviço da Konecta, sandbox `eplast--qa` da Eplast, dev da esteira pela regra 5 da conta). QA não foi tocada.
**Branch:** `feature/EPLAST-33` · **Commit do código:** `2ad8bb0e` (o commit deste plano vem logo depois).
**Escopo:** o do gate de 2026-11-17 ("aprovado sem a consulta pelo assistente"). Nada de `CommercialSignalAgentAction`, ação do agente, versão do `SFAgent2` nem `classAccess`.

## 1. O que foi construído (implantado na dev)

### Metadata
| Componente | Tipo | Mudança |
|---|---|---|
| `CommercialSignal__c.ProductFamily__c` | Campo Text(40) | novo |
| `CommercialSignal__c.CurrentPeriodQuantity__c` | Campo Number(16,2) | novo |
| `CommercialSignal__c.BasePeriodQuantity__c` | Campo Number(16,2) | novo |
| `CommercialSignal__c.UnitOfMeasure__c` | Campo Text(20) | novo |
| `CommercialSignal__c.Type__c` | Picklist restrita | valor `HistoricoInsuficiente` acrescentado |
| `CommercialSignal__c` `BasePeriodAmount__c`, `CurrentPeriodAmount__c`, `VariationPercent__c`, `SignalKey__c` | Campos | só descrição atualizada ao novo significado |
| `CommercialSignalSetting__mdt`: `PurchaseDateField__c`, `FamilyField__c`, `VolumeMinBaseMonths__c`, `VolumeMetric__c`, `CrossSellLevel__c`, `CrossSellExcludedFamilies__c` | 6 campos CMDT | novos, todos com descrição |
| `CommercialSignalSetting__mdt` `RecoveryDays__c`, `VolumeThresholdPercent__c`, `VolumeWindowMonths__c`, `CrossSellGroupField__c` | Campos | só descrição |
| `CommercialSignalSetting.Default` | Registro CMDT | `RecoveryDays__c` 90; `VolumeThresholdPercent__c` 20; `VolumeDirections__c` `Queda`; `CrossSellGroupField__c` `Sector__c`; `VolumeWindowMonths__c` 3; `PurchaseDateField__c` `EffectiveDate`; `FamilyField__c` `Group__c`; `VolumeMinBaseMonths__c` 2; `VolumeMetric__c` `Valor`; `CrossSellLevel__c` `Familia`; `CrossSellExcludedFamilies__c` vazio. `PurchaseStatuses__c` ficou `Faturamento;Concluido` |
| `Accounts_with_CommercialSignals` | Tipo de relatório | + `Account.Sector__c`, `Account.BillingState`, 4 campos novos do sinal |
| `CommercialSignals_ByAccount` (pasta `EPLAST33_SinaisComerciais`) | Relatório | + colunas `Sector__c`, `BillingState`, `ProductFamily__c`, quantidades atual/base e unidade. Filtro por segmento e UF fica na tela |
| `PS_Comercial_SinaisComerciais` | Permission set | FLS de leitura dos 4 campos novos (sem edição) |

### Apex (API 67.0)
| Classe | Mudança |
|---|---|
| `CommercialSignalService` | Recuperação `dias > RecoveryDays__c` (91 entra com 90). Volume por conta x família: último mês fechado contra a **média mensal** dos N meses completos anteriores (mês sem compra conta zero); queda com variação **>= 20%** (inclusivo); alta só se `VolumeDirections__c` ligar. `HistoricoInsuficiente` quando a conta comprou a família em menos de `VolumeMinBaseMonths__c` meses da base. Métrica `Valor`/`Quantidade`/`ValorOuQuantidade`; família com unidades mistas grava `MISTA` e não soma quantidade. Conta em `Recuperacao` ou `NuncaComprou` não recebe sinal de volume (PA-27). Cruzada por segmento com sugestão de **família** (ou produto, por parâmetro), com famílias excluídas e "Sem familia" nunca sugerida. `SignalKey__c` = `Conta-Tipo-<família ou Id do produto>`. Valores do CMDT para campo de data e de família só valem se estiverem na lista permitida (`EffectiveDate`/`IssuanceDate__c`/`ActivatedDate`; `Group__c`/`Family`); fora dela volta ao padrão e registra aviso no log do job |
| `CommercialSignalBatch` | Três agregações (última compra por conta; valor e quantidade por conta x família x unidade x mês em `OrderItem`; itens recentes da cruzada). SOQL dinâmico com `Database.queryWithBinds`, nomes de campo só da lista permitida. Upsert, exclusão de obsoletos e `allOrNone=false` iguais à versão anterior |
| `CommercialSignalGroupStatsBatch` | Estatística por (segmento, família) ou (segmento, produto) |
| `CommercialSignalScheduler` | Sem mudança |
| `CommercialSignalTestFactory` | Segmento (`Sector__c`) no lugar de `Industry`; produto com família e unidade; quantidade no `OrderSpec` |
| 3 classes de teste reescritas aos novos limites | `CommercialSignalServiceTest`, `CommercialSignalBatchTest`, `CommercialSignalGroupStatsBatchTest`; `CommercialSignalSchedulerTest` inalterada |

Nenhuma escrita em Account, Opportunity, Order ou OrderItem (o teste `doesNotWriteToCommercialObjects` prova); nada no Marketing Cloud.

## 2. Versões e ativação

- **Classes `CommercialSignal*`: editadas no lugar, não versionadas como `V2`.** Justificativa (a regra "classe nova" vale para classe em uso): nenhuma é chamada por trigger, Flow, ação de agente ou job. Conferido na dev: 0 `CronTrigger` `EPLAST33%` e 0 `AsyncApexJob` pendente das classes `CommercialSignal*`. A demanda ainda não foi entregue. Isto segue a decisão do design (seção 1, "Versões e ativação"). **Condição para o deploy na QA:** conferir 0 job agendado de `CommercialSignalScheduler` antes; se houver, a esteira/`qa` desagenda, implanta e reagenda, e registra (achado EPLAST-33 de 15/11).
- Flow: nenhum criado ou alterado. `SFAgent2`: **não tocado** (nenhuma versão nova; v13 continua a ativa, v14 e v15 ficam como estão).
- Nada a ativar neste build. Job agendado: **nenhum criado** na dev (o agendamento é do `qa`, em duas fases).
- Desfazer: reimplantar as classes e o `Default` da rodada anterior (commit `580b59ed` ou anterior no histórico). Campos novos podem ficar (vazios não atrapalham).

## 3. Desvios em relação ao design (registrados)

1. **`PS_Marketing_SugestaoCampanha` não foi alterado.** O design (seção 2.4) previa FLS dos campos novos nos dois permission sets. Esse é da EPLAST-46 ("aditivo só leitura" do agente: lê só `CalculationDate__c` e `Product__c`, não está no repositório) e quem o usa não lê os campos novos. Mexer nele exigiria trazer para esta branch componente de outra demanda. Se a Eplast quiser os campos novos lá, é ajuste de uma linha de FLS, em demanda própria.
2. **Rise (`AltaVolume`) também ficou inclusivo (>= limiar)**, por coerência com a resposta do cliente para a queda. No `Default` a alta está desligada (`VolumeDirections__c` = `Queda`).
3. **Código de família "Sem familia"** (produto sem `Group__c`) gera sinal de volume, mas **nunca** é sugerido na cruzada. Decisão do builder dentro de PA-26/PA-28 (não faz sentido sugerir "Sem familia").
4. **Sem `05-testes.md` do build:** esse arquivo é do QA; o resultado dos testes do build está na seção 5 abaixo.

## 4. Premissas usadas (do design, seção 5, sem mudança)

PA-23 (data = `Order.EffectiveDate`, troca por `PurchaseDateField__c` = `IssuanceDate__c` sem deploy), PA-24 (`Faturamento;Concluido`), PA-25 (alerta pelo valor; quantidade ao lado, `MISTA` quando mistura unidades), PA-26 (família = `Product2.Group__c`; mínimo de 2 de 3 meses da base), PA-27, PA-28 (sugere família), PA-29 (região = `BillingState`, só filtro de relatório), PA-30 (91 dias). PA-31 e PA-1/PA-12 (assistente) ficam fora desta rodada pelo gate. O que o QA repete no roteiro do cliente: ver seção "Aprovado como desenhado" do design e o corte do assistente.

## 5. Testes na dev (`sf apex run test --target-org sbx-eplast-dev --code-coverage`)

Classes: `CommercialSignalServiceTest`, `CommercialSignalBatchTest`, `CommercialSignalGroupStatsBatchTest`, `CommercialSignalSchedulerTest`.

```
Tests Ran            66
Pass Rate            100%
Fail Rate            0%
Skip Rate            0%

Apex Code Coverage by Class
CommercialSignalService          100%
CommercialSignalScheduler        100%
CommercialSignalBatch             98%   (linhas não cobertas: 85, 94)
CommercialSignalGroupStatsBatch   96%   (linhas não cobertas: 21, 22)
```
Todas acima de 85%. Cenários cobertos com assert: 91/90/89 dias; queda de 20,0% entra e 19,99% não; média com mês sem compra; último mês fechado (mês corrente e mês antigo ficam de fora); histórico com 1 e 2 meses da base; famílias independentes e "Sem familia"; unidades mistas (`MISTA`, sem somar quantidade); métrica `Quantidade`; cruzada por família e por produto, exclusão de família, segmento pequeno (< 5), conta sem segmento, compra recente; troca de `PurchaseDateField__c` (`IssuanceDate__c` e `ActivatedDate`) mudando o resultado sem deploy; valor inválido do CMDT voltando ao padrão com aviso; bulk de 200 contas; idempotência; sinal obsoleto removido; permission set só leitura; não escreve em Account/Order/OrderItem/Opportunity.
Achado do teste: `Date` passa em `instanceof Datetime` em Apex e o `MAX(Order.EffectiveDate)` voltava um dia antes; `asDate` testa `Date` primeiro (coberto por teste).
Cobertura geral da org (48%) não é desta demanda.

## 6. O que a verificação precisa exercitar

1. Ler `CommercialSignalSetting.Default` na dev e conferir os valores acima.
2. Montar dados **só por fixtures** (`CommercialSignalTestFactory`; a dev está sem pedidos) ou por script em `fixtures/`, e rodar `CommercialSignalGroupStatsBatch` (que encadeia o `CommercialSignalBatch`) com a data fixada: conta com último pedido faturado há 91 e 90 dias; família com queda de 20,0% e 19,99% no último mês fechado; conta com 1 e com 2 meses da base; família com `UN` e `KG`; segmento de 10 contas com 4 compradores da família.
3. Abrir o relatório `Sinais Comerciais por Conta`: aparecem `Sector__c`, `BillingState`, `ProductFamily__c`, quantidades e unidade; filtrar por segmento e UF; abrir com o permission set `PS_Comercial_SinaisComerciais` (usuário de teste: conta de serviço da Konecta, Id na org) e conferir que um usuário sem o PS não vê o objeto.
4. Trocar `PurchaseDateField__c` no `Default` por `IssuanceDate__c` e conferir que o resultado muda sem deploy (e voltar para `EffectiveDate`).
5. Volume/CPU (design, seção 3): 1 conta com ~5 mil itens; acima de 70% de qualquer limite, voltar ao gate. **Não medido neste build** (dev vazia; os testes rodam com poucos registros).
6. Não deixar job agendado na dev (nenhum foi criado).
7. Fora de escopo para a verificação: consulta pelo assistente (`SFAgent2` não foi tocado).

## 7. Dívidas identificadas (fora do escopo, não corrigidas)

- `PS_Marketing_SugestaoCampanha` (EPLAST-46) não está no repositório; só existe na org.
- `CommercialSignalBatch` e `CommercialSignalGroupStatsBatch` são `without sharing` (justificativa no cabeçalho de cada classe, mantida da rodada anterior).
- Medição de CPU/linhas com volume real (item 5 acima) continua pendente para a QAS.
