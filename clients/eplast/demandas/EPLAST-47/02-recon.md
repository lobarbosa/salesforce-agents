# EPLAST-47 — Recon da org (etapa 2, redesenho pela oportunidade)

**Coleta:** 2026-11-17. **Org:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`), única conectada em `sf org list` (Status Connected). Só leitura: metadata, contagens agregadas e retrieve para pasta temporária descartada (`/tmp/recon47`). Nenhum deploy, DML ou toque no Marketing Cloud.
**Contexto lido:** `01-analise.md`, `comentarios-do-card.md` (decisão de 17/11: Flow novo disparado ao salvar a oportunidade, classifica só a conta dela, sem Apex, sem `AccountRanking__c`, `Ranking__c` segue vigente; fluxo agendado sai), regras 1 a 6 da conta, `assessment.md` (só os achados 1, 2, 3, 4, 6, 9, 10).
**Atenção:** a dev já tem o build das rodadas anteriores (Flow `ScheduledFlowOpportunity` v2 Active, dois Custom Metadata Types, relatório provisório, histórico em `Ranking__c`). O redesenho parte disso. Este recon refaz o de 16/11. **Reconferido em 17/11 (nova sessão, `sf data query`):** versões e status dos 4 Flows (ScheduledFlowOpportunity v1 Obsolete e v2 Active; OpportunityFlow v1 Obsolete e v2 Active; AccountTriggered v1 Obsolete e v2 Active; UpdateParentAccountUsedLimit v1 Active), os 7 registros de `RankingRange__mdt`, o `Default` de `ScheduledFlowOpportunitySetting__mdt` (dia 14), contagens de Account, Opportunity e `IntegrationLog__c`, os 68 relatórios da pasta MARKETING CLOUD e o usuário de teste. O restante vem da leitura de metadata da sessão anterior de 17/11.

## 1. O que já cobre o pedido

| Item | Estado confirmado | Cobre? | Comando |
|---|---|---|---|
| Flow `ScheduledFlowOpportunity` | Versões: v1 Obsolete, v2 Active. v2: agendado (`triggerType` Scheduled), objeto `Opportunity`, soma `Fechado/Ganho` do ano em `LastMonthPurchaseValue__c`, classifica `Ranking__c` pela média `AveragePurchasesThisYear__c` percorrendo `RankingRange__mdt`, falha vira `IntegrationLog__c` | Parcial. É o desenho que a decisão de 17/11 tira; grava em Account em lote | `sf data query -t` em `Flow` (Definition.DeveloperName); `sf project retrieve start -r /tmp/recon47/out -m Flow:...` |
| `RankingRange__mdt` | 7 registros: MP 10.000, PP 35.000, P 80.000, M 160.000, G 500.000, GG 1.000.000 e 3G sem teto (`UpperLimit__c` nulo). Campos `Ranking__c`, `SortOrder__c`, `UpperLimit__c` | Sim, faixas já configuráveis; reaproveitável pelo Flow novo | `sf data query -q "SELECT Ranking__c, SortOrder__c, UpperLimit__c FROM RankingRange__mdt ORDER BY SortOrder__c"` (reconfirmado 17/11) |
| `ScheduledFlowOpportunitySetting__mdt` | Registro `Default`, `RunDayOfMonth__c` 14 (reconfirmado 17/11) e `FaultRecipient__c`, **vazio na dev** (`COUNT() ... WHERE FaultRecipient__c != null` = 0). Com a saída do agendado, o dia deixa de ter uso; o destinatário da falha continua | Parcial | idem; o Flow v2 referencia o objeto (retrieve de hoje) |
| `Account.Ranking__c` | Picklist, 7 valores ativos (MP, PP, P, M, G, GG, 3G), histórico ligado | Sim | recon de 16/11 (retrieve do campo) |
| Relatório `AccountRankingChanges` (id `00OHa000002z8ifMAA`) | Tipo `AccountAuditHistory`, colunas `ACCOUNT.NAME`, `CREATED_DATE`, `field_key`, `OLDVAL`, `NEWVAL`. **`reportFilters` vazio**: lista toda mudança de campo rastreado em Account, não só `Ranking__c`. Pasta provisória "EPLAST-47 Relatorios (provisorio, P12)" | Parcial: falta filtrar por `Ranking__c` | `sf api request rest /services/data/v62.0/analytics/reports/00OHa000002z8ifMAA/describe` |
| Relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` (id `00OHa000002zGY9MAM`) | Tipo `AccountList`, lê `Account.Ranking__c` como coluna, agrupa por `RelationshipClass__c` e `TYPE` | Não é o pedido, mas é consumidor confirmado de `Ranking__c` | idem, `describe` |
| Pasta "MARKETING CLOUD" | **68 relatórios** (o recon de 16/11 dizia 7). Só descrevi 1 (acima); os outros 67 não foram checados para `Ranking__c` | Consumidores prováveis, não conferidos | `sf data query -q "SELECT COUNT() FROM Report WHERE FolderName = 'MARKETING CLOUD'"` |
| Painel sobre Ranking/compras | 0 por título (recon de 16/11) | Não | consulta `Dashboard` por título |
| Objeto de classificação ligado à conta | Não existe; fora do desenho de 17/11 | n/a | recon de 16/11 |
| Agente `SFAgent2` | Existe (`GenAiPlannerBundle`); demanda não é de assistente; referência aos campos não verificada | n/a | recon de 16/11 |

## 2. O que será tocado

| Componente | Detalhe confirmado | Descrição | Comando |
|---|---|---|---|
| `Account.Ranking__c` | Picklist 7 valores, histórico ligado | Tem | recon 16/11 |
| `Account.LastMonthPurchaseValue__c` | Currency; descrição explica que guarda a soma do ano | Tem | idem |
| `Account.AveragePurchasesThisYear__c` | Currency; é a base da classificação (P3) | Sem descrição | idem |
| `Account.TotalPurchasesThisYear__c` | Currency | Sem descrição | idem |
| `Opportunity.ThisYear__c` | Fórmula por `CreatedDate` (P2 mantém) | Não conferida | idem |
| `IntegrationLog__c` | Usado pelo `LogFault`; **16 registros na dev** (contagem) | Não conferida | `SELECT COUNT() FROM IntegrationLog__c` |
| Escritores dos campos de compra | `ScheduledFlowOpportunity` v2 (`LastMonthPurchaseValue__c`, `Ranking__c`); `OpportunityFlow` v2 (`AveragePurchasesThisYear__c`, `TotalPurchasesThisYear__c`) | n/a | grep nos XML retrievados |
| Leitores | Permission set `Protheus` (3 campos, recon 16/11) e relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` (`Ranking__c`) | n/a | retrieve; `describe` do relatório |

## 3. Automação concorrente

### Opportunity (o evento do Flow novo: after save, create e update)

| Automação | O que faz de relevante | Comando |
|---|---|---|
| `OpportunityFlow` v2 (Active), `RecordAfterSave`, create e update, **sem critério de entrada no `start`** | Roda em toda gravação de oportunidade. Atualiza Account **no mesmo evento**: `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c` (`recordUpdates` `UpdateAccountAverage`, `UpdateTotalAmountAccount` e um terceiro que grava os dois). Também cria Quote e Order (objetos `Quote` e `Order` no XML). Média calculada como `Account.TotalPurchasesThisYear__c / Count` | retrieve do Flow; leitura das linhas 1062 a 2118 |
| **Risco de ordem:** o Flow novo vai classificar pela média, e a média é gravada por `OpportunityFlow` no mesmo save. Nenhum dos Flows tem `triggerOrder` definido (grep sem resultado em 4 XML). Não há como garantir qual roda primeiro, então o novo pode ler a média anterior | grep `triggerOrder` em `flows/*.xml` |
| `OpportunityTrigger` (custom) e `OpportunityTriggerHandler` | after insert/update, enfileira `OpportunityTriggerHelper` (sem `isQueueable` nem bypass). Helper consulta Account por `AccountId` e, por conta, chama `ProtheusAPI.getClientByCNPJ` e `UpdateAccountWithProtheusInfo.execute`, que **também grava em Account** (corpo da classe de gravação não lido). Cada oportunidade salva leva, portanto, a pelo menos mais uma atualização de Account, assíncrona | retrieve de `OpportunityTriggerHelper` (50 linhas) |
| `OpportunityBefore`, `OpportunityAfter` (SBQQ) | Triggers do pacote CPQ; corpo não legível | recon 16/11 (`ApexTrigger` por `NamespacePrefix`) |
| `Oportunidade_Industria` (Active), `Opportunity_Scheduled_AlertaParada` (Draft) | Sem referência aos campos desta demanda | recon 16/11 |
| Validation rules ativas em Opportunity (16) | Só pesam se o Flow gravar em Opportunity, o que o desenho de 17/11 não faz. Várias exigem dado da conta (endereço, CNAE, e-mail, telefone, loja), então bloqueiam salvar oportunidade de teste sem esses dados | recon 16/11 |

### Account (o que cada gravação de `Ranking__c` dispara)

| Automação | Efeito por atualização de conta | Comando |
|---|---|---|
| `AccountTrigger` e `AccountTriggerHelper` | Para cada conta em after update, sem filtro de campo alterado: se `CompanyDocument__c` mudou, enfileira `UpdateAccountCompanyInfo`; senão enfileira `SendAccountToProtheus` (29 linhas lidas hoje). Um job por conta, limite de 50 por transação. Retorna se `TriggerUtility.bypassTrigger` | retrieve de `AccountTriggerHelper` |
| `SendAccountToProtheus.execute` | Só chama `ProtheusAPI.sendClientToProtheus` se Store, CompanyName, Billing (cidade, estado, rua, CEP, bairro), telefone, CNAE e `ProtheusSellerId__c` do dono estiverem preenchidos; senão não faz nada. Não vi `Ranking__c` no corpo da classe | retrieve da classe |
| `AccountTriggered` v2 (Flow, Active), `RecordAfterSave` create/update | **Sem critério de entrada no `start`**: roda em toda atualização de conta (opera em `EconomicGroup__c`, `Task`, `User`, `Profile`). Primeiro elemento `CheckRecord`, não lido a fundo | retrieve; leitura do `start` |
| `UpdateParentAccountUsedLimit` (Flow, v1 Active), `RecordAfterSave` create/update | **Sem critério de entrada**: roda em toda atualização de conta; primeiro elemento `AccountHasParent`. Se há `ParentId`, consulta as contas filhas e atualiza Account | retrieve |
| Validation rules ativas em Account (6) | Fórmulas lidas hoje: `Celular`, `Telefone`, `WhatsApp`, `Contato_Fiscal` são regex de telefone e só disparam se o campo está preenchido e fora do formato; `CheckUserCanSetRisk` e `CheckUserCanSetLimitDueDate` só disparam com `ISCHANGED` do campo e perfil diferente de API Only, Administrador do sistema e Financeiro. **Nenhuma olha `Ranking__c` ou campos de compra**; só bloqueiam atualização de conta já com telefone inválido | retrieve de `ValidationRule:Account.*` |
| `AccountBefore` (SBQQ) e Flows agendados em Account | Sem referência aos campos; `AccountBefore` não legível | recon 16/11 |

Cadeia por classificação de uma conta (confirmada na leitura): 1 update de Account do Flow novo, mais os de `OpportunityFlow` e do `OpportunityTriggerHelper`, cada um com um enqueue de `SendAccountToProtheus` e rodada de `AccountTriggered` e `UpdateParentAccountUsedLimit`. Uma oportunidade salva tende a gerar vários updates na mesma conta, não um. Se vários itens do mesmo lote de oportunidade pertencem a contas distintas, o teto de 50 enqueues volta a valer (ex.: carga ou integração que salve muitas oportunidades numa transação). Não medi isso.

### Order e Marketing Cloud Connect
- `OrderTrigger` existe duas vezes em Order, uma do SBQQ (por `NamespacePrefix`) e uma custom (recon 16/11). O desenho não grava em Order, mas `OpportunityFlow` cria `Order` e `Quote` quando a oportunidade é salva.
- `et4ae5` instalado: 523 classes Apex e 11 triggers ativos em objetos do próprio pacote e em `User` (recon 16/11). Nenhum em Account, Opportunity ou Order. Campos do `et4ae5` ligados a Account não levantados.

## 4. Volume e dados de teste

| Objeto | Contagem na dev | Comando |
|---|---|---|
| Account | 0 | `sf data query -q "SELECT COUNT() FROM Account" --json` |
| Opportunity | 0 (ganhas: 0) | idem, com `WHERE IsWon = true` |
| Order | 0 | idem |
| AccountHistory | 0 | idem |
| IntegrationLog__c | 16 | idem |
| Flows ativos / CronTrigger | 52 / 8 | `SELECT COUNT(Id) FROM Flow WHERE Status='Active'`; `SELECT COUNT() FROM CronTrigger` |

- A dev não tem dado de negócio: teste exige dados sintéticos (`fixtures/`, regra 6; autorização de 15/11 para "TESTE EPLAST-47"). Oportunidade salva dispara `OpportunityFlow`, CPQ e a cadeia do Protheus. Conta criada pela tela passa pelo `AccountTrigger`; o desvio `TriggerUtility.bypassTrigger` é chave global, que desliga também o trigger de Opportunity.
- Usuário de teste (regra 6): a consulta devolveu dois, ambos "Administrador do sistema": `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo). Usar o ativo; não alterar perfil, permissão ou papel.
- Quantas oportunidades por conta existem na QAS: não medi (a QAS não é a org conectada). O card cita 1.217 contas lá.

## 5. Permissões

| Item | Confirmado | Comando |
|---|---|---|
| Permission set `Protheus` | Acesso a `Ranking__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c` (recon 16/11) | retrieve de `PermissionSet:Protheus` |
| `PS_Comercial_*` | Existem; não abri o que concedem | `sf org list metadata -m PermissionSet` |
| OWD de Account e Opportunity; perfis com acesso aos campos | Não consultado | n/a |
| Flow novo (contexto de execução) | Flow record-triggered after save roda em contexto de sistema por padrão; não conferi se há perfil que não enxerga os campos de `Account` para o qual isso importe | n/a |

## Riscos do assessment (Account, Opportunity, Order) com a confirmação atual

| # | Risco (assessment) | Confirmação em 17/11 |
|---|---|---|
| 1 | Automação concorrente em Account, Opportunity e Order | Confirmado em Account (`AccountTrigger`, 2 Flows sem critério, `AccountBefore`) e Opportunity (`OpportunityTrigger`, `OpportunityFlow`, 2 triggers SBQQ). Ordem entre Flows e triggers não garantida; nenhum Flow tem `triggerOrder` |
| 2 | Cobertura Apex ~10% | Não medida hoje. O desenho de 17/11 não cria Apex, então não se aplica ao build; deploy de Apex futuro (correção do `UpdateAccountCompanyInfo`) fica fora |
| 3 | Validation rules de Order (23) | Não consultei hoje. O desenho não grava em Order; `OpportunityFlow` cria Order ao salvar oportunidade, o que é automação existente |
| 4 | Campos sem descrição | Confirmado para `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c`; campo novo deve nascer com descrição |
| 6 | Dúvida dev × qa | Resolvido pela regra 5 da conta (não é bloqueio) |
| 9 | API version das classes Apex | Não medida; sem Apex novo na demanda |
| 10 | `OrderTrigger` duplicado (SBQQ x custom) | Confirmado em 16/11; sem mudança hoje |
| 5, 7, 8 | Nome de classe de teste, perfil Financeiro, 33 perfis | Não tocam esta demanda; não verificados |

## O que não consegui confirmar

1. **Se `OpportunityFlow` e o Flow novo disputam a média na mesma gravação.** Vi que ambos ficam after save em Opportunity e que `OpportunityFlow` grava a média; não testei qual roda antes. O Flow novo pode ler a média anterior.
2. **Corpo de `UpdateAccountWithProtheusInfo`** (chamado por `OpportunityTriggerHelper`): se grava campo de conta e dispara `AccountTrigger`.
3. **O que `CheckRecord` (`AccountTriggered`) e `AccountHasParent` (`UpdateParentAccountUsedLimit`) fazem** quando só `Ranking__c` muda; sei que entram em toda atualização.
4. **Fórmula completa de cada Flow no caminho de "oportunidade ganha"** de `OpportunityFlow`: não mapeei em que condições grava Total e média (só os 3 `recordUpdates`).
5. **Se o Protheus aceita MP e 3G** (P8) e se `ProtheusAPI.sendClientToProtheus` serializa `Ranking__c`. Não li `ProtheusAPI`.
6. **Valor de `FaultRecipient__c` em QA e QAS** (vazio na dev; P11 sem endereço).
7. **Quais dos 68 relatórios de "MARKETING CLOUD" leem `Ranking__c`**, e quais campos e objetos do `et4ae5` ligam a Account (regra 2).
8. **OWD de Account e Opportunity, perfis com acesso aos campos, o que os `PS_Comercial_*` concedem.**
9. **Layouts, páginas Lightning e classes Apex fora das lidas** que usem os campos de compra.
10. **Estado da QA e da QAS** (Flow v4, dia 15, 1.217 contas): vem do card, não de consulta minha.
11. **Se `SFAgent2` referencia `Ranking__c` ou os campos de compra.**
12. **Limite de 51 enqueues em lote de oportunidades**: não medi se há carga ou integração que salve muitas oportunidades numa transação.

## Complemento do arquiteto (2026-11-17, etapa de design)

Pontos que mudavam a decisão, conferidos na `sbx-eplast-dev` só por metadata (retrieve em pasta temporária descartada).

| Ponto | Confirmado | Comando |
|---|---|---|
| Flows ativos disparados por registro em Opportunity | Quatro, todos sem `TriggerOrder`: `OpportunityFlow`, `Opportunity_AfterSave_CriaCasoPosVendas` (cria `Case`, filtro em `StageName`), `Oportunidade_Industria` (cria `Task`) e o before save `Opportunity_BeforeSave_QualificaOportunidade` (grava só o próprio registro). `Opportunity_Scheduled_AlertaParada` está **Active** (o recon de 16/11 dizia Draft) e cria `IntegrationLog__c`. Nenhum deles, fora o `OpportunityFlow`, grava em Account nem cita os campos da demanda | `SELECT ApiName, TriggerType, RecordTriggerType, TriggerOrder FROM FlowDefinitionView WHERE IsActive = true AND TriggerObjectOrEvent.QualifiedApiName IN ('Opportunity','Account')`; retrieve dos 4 Flows |
| Flows ativos em Account | `AccountTriggered`, `UpdateParentAccountUsedLimit` (after save, sem `TriggerOrder`) e o agendado `AccountUpdateEconomicGroup` | idem |
| Quando `OpportunityFlow` grava a média | Caminho `StageClosedWon` (`StageName` = Fechado/Ganho, sem checar mudança): só chega a `UpdateAccount` (média e total) se houver cotação aprovada (`QuoteFound`), depois de criar Pedido e itens. Caminho `StageClosedLost` (anterior Fechado/Ganho, atual Fechado/Perdido): `UpdateTotalAmountAccount` e `UpdateAccountAverage`, duas gravações; a média nova usa `{!$Record.Account.TotalPurchasesThisYear__c}/{!Count}`. Filtro do ano: `CurrentYear__c`, mesma fórmula de `ThisYear__c` | retrieve e leitura dos elementos do Flow |
| Fase ganha | Única fase ativa com `IsWon` = true: `Fechado/Ganho` | `SELECT ApiName, IsWon, IsActive FROM OpportunityStage` |
| `UpdateAccountWithProtheusInfo` | 37 linhas, `update this.acc` incondicional (dados de limite), sem `Ranking__c` nem campos de compra. `ProtheusAPI` e `AccountAdapter` também sem `Ranking__c` | retrieve das 3 classes; grep |
| Relatórios da pasta MARKETING CLOUD (`MARKETINGCLOUD`) | 68 retrievados; 1 cita `Ranking__c` (`CLASSIFICACAO_CONTAS_POR_CLASSE`, só como coluna); 0 citam os campos de compra | `sf org list metadata -m Report --folder MARKETINGCLOUD`; retrieve; grep |
| Campos `et4ae5__` em Account | 0 | `FieldDefinition` (Tooling) com `QualifiedApiName LIKE 'et4ae5__%'` |
| API da org | 68.0 | `sf org display` |
