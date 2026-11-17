# EPLAST-33 — Recon da org (rodada de 17/11, após as respostas do cliente)

Substitui o recon de 15/11 (guardado no histórico do git). Foco: o que as respostas do cliente de 17/11 mudam (compra faturada, 90 dias, volume por família com mês fechado e 20%, cruzada por segmento, assistente) contra o que a rodada anterior já construiu na dev. Só metadata e contagens agregadas; nenhum registro lido. Data da coleta: 2026-11-17.

## Org conectada

| Alias | Tipo | Status | Comando |
|---|---|---|---|
| `sbx-eplast-dev` | Sandbox | Connected (única org listada) | `sf org list` |

Todas as consultas abaixo usaram `--target-org sbx-eplast-dev`. A regra 5 da conta resolve o "qa" no username do alias (dev da esteira = `eplast--qa` da Eplast).

## O que já existe

### Construído na rodada anterior (está na dev e no repositório em `force-app/`)

| Item | Confirmação | Cobre | Falta |
|---|---|---|---|
| `CommercialSignal__c` (campos: `Account__c`, `Product__c`, `Type__c`, `Reason__c`, `SignalKey__c`, `CalculationDate__c`, `LastPurchaseDate__c`, `DaysWithoutPurchase__c`, `CurrentPeriodAmount__c`, `BasePeriodAmount__c`, `VariationPercent__c`) | `sf sobject describe`; `SELECT COUNT()` = 0 linhas | Saída por conta, tipo, motivo, métrica e datas | Nenhum campo para família de produto, quantidade, histórico insuficiente. Nenhum campo tem descrição. OWD `ControlledByParent` (`EntityDefinition`) |
| `CommercialSignalSetting__mdt` (registro `Default`: `RecoveryDays__c`=60, `VolumeWindowMonths__c`=3, `VolumeThresholdPercent__c`=30) | describe e `SELECT ... FROM CommercialSignalSetting__mdt`; 1 registro | Parâmetros sem deploy de código. Também tem `PurchaseStatuses__c`, `VolumeDirections__c`, `CrossSellGroupField__c`, `CrossSellMinGroupSize__c`, `CrossSellMinSharePercent__c`, `CrossSellLookbackMonths__c`, `CrossSellRecentDays__c`, `CrossSellMaxPerAccount__c`, `IncludeNeverPurchased__c`, `BatchSize__c` | Faltam parâmetros de: campo de data de compra, mês fechado, quantidade de meses da média, limiar mínimo de histórico, campo de família, campo de região |
| Apex: `CommercialSignalBatch`, `CommercialSignalGroupStatsBatch`, `CommercialSignalScheduler`, `CommercialSignalService` e `<Classe>Test` de cada uma, mais `CommercialSignalTestFactory` | `SELECT Name, Status FROM ApexClass` (tooling): 9 classes Active | Batch agendado. Lê `Order.Status IN :statuses`, `MAX(EffectiveDate)`, `SUM(TotalAmount)` e janela móvel (`currentFrom`/`baseFrom`) | Código lido por Grep em `force-app/.../classes`. Janela atual é "3 meses até hoje", não mês fechado. Soma por conta, não por família. `crossSellGroupField` cai para `Industry` se o campo configurado não existir em `Account` (`resolveGroupField`): `Sector__c` existe, então vale por configuração. Batches são `without sharing` (comentário no código); o serviço de leitura é `with sharing` |
| Relatório `CommercialSignals_ByAccount` (pasta "EPLAST33 Sinais Comerciais") | `SELECT ... FROM Report` | Relatório para gestão sobre `CommercialSignal__c` | Colunas e filtros não lidos hoje |
| Acesso a `CommercialSignal__c` | `SELECT ... FROM ObjectPermissions` | Permission sets `PS_Comercial_SinaisComerciais` (R) e `PS_Marketing_SugestaoCampanha` (R) leem o objeto; só 1 perfil tem Create | Quem enxerga é decidido pelo pai (`Account`) |
| Job agendado da dev | `CronTrigger` não é consultável nesta org | Não confirmado | Ver lacunas. A nota do card de 15/11 diz "não deixe job agendado na dev" |

### Assistente e relatórios de "sem compra" (regra 3 da conta)

| Item | Confirmação | Cobre | Observação |
|---|---|---|---|
| `SFAgent2` | `GenAiPlannerDefinition`: `SFAgent2_v1` a `SFAgent2_v10` listados (query com LIMIT 10: pode haver mais) | Agente único, já estendido por outras demandas | A análise dizia "v1 a v4": está defasada. Versão ativa não confirmada |
| Tópicos | `GenAiPluginDefinition`: `insights_comerciais_<id>` (versões até `_v13` listadas) e `acoes_comerciais_EPLAST29` (até `_v12`) | Tópico `insights_comerciais` é o ponto de extensão para consulta | Instruções do tópico não lidas hoje |
| Ações | `GenAiFunctionDefinition`: `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`, `QueryRecords`, `IdentificarRegistro_EPLAST29` (standard `queryRecords`/`queryRecordsWithAggregate`/`identifyRecordByName`); `ProximaAcaoCliente_EPLAST27` e `CriarTarefa_EPLAST29` (Flow); `ResumoReuniao_EPLAST34` (Apex) | `ConsultarPedidos` com `queryRecords` pode ler `CommercialSignal__c` se o objeto for incluído na ação | Nenhuma ação lê `CommercialSignal__c` hoje (não verificado no corpo das versões; só pelos nomes e tipos) |
| Relatórios Marketing Cloud | `Report` na pasta "MARKETING CLOUD": `SEM COMPRA - 91 A 180 DIAS`, `SEM COMPRA - 181 A 365 DIAS`, `SEM COMPRA - MAIS DE 365 DIAS`, `POTENCIAIS - SEM COMPRA` | Já existem faixas de "sem compra" para o Marketing | Filtros e colunas não lidos. Sobreposição com o corte de 90 dias a decidir no design |
| Flow `ScheduledFlowOpportunity` | `FlowDefinitionView`: `IsActive=false` | Estava citado como cálculo de ranking | **Inativo** hoje. Não concorre |
| Flow `OrderScheduledFlow` | `FlowDefinitionView`: ativo, Scheduled, objeto Pedido | Função não lida | Não escreve em `CommercialSignal__c` pelo que o nome indica (não verificado) |

## O que será tocado (campos das respostas do cliente)

| Pedido do cliente | O que a org tem (confirmado) | Veredito |
|---|---|---|
| Data de faturamento | `Order` não tem campo de data de faturamento nem de nota fiscal. Datas existentes: `EffectiveDate` (label "Data de emissão", padrão), `IssuanceDate__c` (custom, date, "Data emissão"), `ExpectedSaleDate__c`, `DeliveryDate__c`, `ActivatedDate` (padrão). Texto `MessageNote__c` ("Mensagem para Nota"). Nenhum com descrição | Não há campo que se declare "faturamento". Usar o que existe e declarar premissa (ordem do design). Não inferir pelo nome |
| Status "faturado" | `Order.Status`: `Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`, `Faturamento`, `Cancelado`, `Concluido`. `StatusCode`: Draft, Activated, Canceled, Expired, Superseded | O valor `Faturamento` existe. Se "Concluido" é posterior a faturado não está na org |
| Devoluções | Objeto custom `SalesReturn__c` (campos: `AccountId__c`, `OrderId__c`, `DtEmissao__c`, `Invoice__c`, `VlTotal__c`, `Quant1UM__c`, `Quant2UM__c`, `Item__c`, `Lucro__c` e outros), 0 linhas | Existe, mas o cliente pediu que fique fora e que a integração seja corrigida à parte |
| Segmento | `Account.Sector__c` (picklist, label "Setor", 9 valores). `Account.Industry` (padrão, label "Setor", 32 valores). `Account.Subsector__c` (multipicklist, 18 valores). Sem descrição em nenhum | `Sector__c` é o candidato que o design indicou, mas o rótulo é igual ao de `Industry`. Que ele é "segmento da Eplast" **não está confirmado na org** |
| Região | Campo custom de região em `Account`: nenhum encontrado (busca por nome/label). Padrão: `BillingState`, `ShippingState` (strings). `Territory2`: não suportado nesta org | Só estado de cobrança/entrega. "Região" como agrupamento não existe |
| Família de produto | `Product2.Family` é picklist com um único valor (`None`). `Product2.Group__c` (string, "Grupo") tem códigos: `PREF` 680, `TAMP` 202, `RESI` 16, `ALCA` 7, `GPET` 5, nulo 132 (`GROUP BY`, total de produtos 1042). Sem descrição | `Family` não serve. `Group__c` é o único agrupador de produto visível, mas o significado dos códigos (pré-forma, tampa, resina, ...) é inferência por nome, **não confirmada** |
| Quantidade sem somar unidades diferentes | `OrderItem.Quantity`, `OrderItem.TotalPrice`, `OrderItem.UnitPrice`. `Product2.QuantityConverter__c` (Conversor), `Product2.SecondUnitOfMeasure__c` (picklist), `Product2.SecondUnitBalance__c` | Existem campos de segunda unidade e conversor; a unidade principal por produto e a regra de conversão não foram confirmadas |
| Compatibilidade técnica (pré-forma, tampa, garrafa) | Busca em campos custom de `Product2` por compat, gargalo, rosca, diâmetro, tampa, pré-forma, tipo: **nenhum campo** | Não há campo que represente compatibilidade. Depende de tabela da Eplast (conforme o próprio texto do cliente) |
| Histórico insuficiente | Sem campo para isso em `CommercialSignal__c` | Criar (ou marcar no `Reason__c`) |

## Ordem de execução e concorrência

Comandos: `SELECT ... FROM ApexTrigger` (tooling), `FlowDefinitionView` (ativos, 142 no total), `ValidationRule` (tooling).

| Objeto | Automação ativa | Evento |
|---|---|---|
| `Order` | Trigger `OrderTrigger` do CPQ (namespace `SBQQ`): BU, AU | Atualização |
| `Order` | Trigger `OrderTrigger` custom (sem namespace): BI, AI, BU, AU, AD. Classes de apoio: `OrderTriggerHandler`, `OrderTriggerHelper`, `OrderUtility`, `OrderAdapter`, `OrderInfo` | Todos |
| `Order` | Flow before-save "Atribui Id externo para update..." (nome truncado na org); Flow after-save `Order`; Flow agendado `OrderScheduledFlow`; 17 validation rules ativas | Antes e depois de salvar |
| `OrderItem` | Trigger `OrderProductTrigger` do CPQ (`SBQQ`): BI, AI, BU, AU, AD. Nenhum Flow ativo de OrderItem; 4 validation rules ativas | Todos |
| `Account` | `AccountBefore` (`SBQQ`: BI, BU); `AccountTrigger` custom (BI, AI, BU, AU) que enfileira `UpdateAccountCompanyInfo`/`SendAccountToProtheus` (briefing da conta); Flows after-save `AccountTriggered`, `UpdateParentAccountUsedLimit`; agendado `AccountUpdateEconomicGroup` | Todos |
| `Product2` | Triggers `ProductBefore`, `ProductAfter`; Flow after-save `ProductFlowNewOrUpdated`; 6 validation rules | Todos |
| `CommercialSignal__c` | Nenhuma trigger, Flow ou validation rule (consulta por objeto: trigger não listada, regras = 0) | — |

Leitura do risco:
- A solução da rodada anterior **só lê** Order, OrderItem, Account e Product2 e escreve só em `CommercialSignal__c`. Nenhum dos itens acima dispara por esse DML.
- Qualquer proposta que **grave** em `Account` aciona `AccountTrigger` (job por conta, limite de 50 enfileiráveis, e envio ao Protheus). Isto está no briefing da conta e foi reconfirmado pela existência da trigger.
- Marketing Cloud Connect (`et4ae5`): 26 objetos custom do pacote na org (`et4ae5__Automated_Send__c`, `et4ae5__SendDefinition__c`, `et4ae5__IndividualEmailResult__c` e outros). Nenhum campo `et4ae5` em `Account`, `Order`, `OrderItem` ou `Product2` apareceu na amostra de 30 campos consultada (a consulta tinha LIMIT 30, então a ausência **não está provada** para todos os campos). Nenhum trigger do pacote apareceu nas listas de Account/Order/OrderItem/Product2.

## Volume, dados de teste e permissões

| Item | Resultado | Comando |
|---|---|---|
| Account | 0 | `SELECT COUNT() FROM Account` |
| Order, OrderItem, Opportunity | 0, 0, 0 | `SELECT COUNT()` |
| Product2 | 1042 | `SELECT COUNT()` e `GROUP BY Group__c` |
| `CommercialSignal__c` | 0 | `SELECT COUNT()` |
| `SalesReturn__c` | 0 | `SELECT COUNT()` |
| Usuário de teste da conta (regra 6) | Dois com o username pedido: `005bJ00000piKAaQAM` (ativo, Administrador do sistema) e `005bJ00000hBJmYQAW` (inativo, Administrador do sistema) | `SELECT Id, IsActive, Profile.Name FROM User WHERE Username LIKE ...` |
| OWD | `Account` Private externo, ReadWrite interno; `Order` idem; `OrderItem` e `Product2` ReadWrite/ReadWrite; `CommercialSignal__c` ControlledByParent | `EntityDefinition` |
| Permission sets sobre `CommercialSignal__c` | `PS_Comercial_SinaisComerciais`, `PS_Marketing_SugestaoCampanha`, `sfdc_a360_sfcrm_data_extract` (leitura) | `ObjectPermissions` |

Dev está sem dado comercial: todo teste precisa de fixture (`fixtures/` do cliente). Criar `Order` na fixture esbarra nas 17 regras ativas do objeto.

## Lacunas e incertezas

1. **Data de faturamento:** nenhum campo de `Order` se identifica como tal. Qual entre `EffectiveDate`, `IssuanceDate__c` e `ActivatedDate` representa o faturamento não é confirmável pela org.
2. **Status faturado:** se `Faturamento` sozinho ou `Faturamento` + `Concluido` equivalem a "faturado" não está confirmado. Nenhum valor de status tem descrição.
3. **Segmento:** `Sector__c` é citado pelo design como segmento, mas o único sinal na org é o nome do campo e o rótulo "Setor" (igual ao de `Industry`). Preenchimento e distribuição não verificados (0 contas).
4. **Família de produto:** `Group__c` existe e tem códigos; o significado deles (e se separa pré-forma, tampa e garrafa) é inferência por nome. `GPET`, `ALCA` e `RESI` não foram interpretados.
5. **Unidades de medida:** unidade principal por produto e uso de `QuantityConverter__c` não verificados.
6. **Região:** não existe campo próprio. Se a Eplast usa estado, filial (`Product2.Branch__c` existe, mas é do produto), ou outra coisa, não é verificável.
7. **Compatibilidade técnica:** inexistente na org, conforme busca por nome. Não verifiquei outros objetos (`SBQQ__` ou tabelas do Protheus) por esse conceito.
8. **Job agendado:** `CronTrigger` não é suportado nesta org; não confirmei se `CommercialSignalScheduler` está agendado na dev. Também não li o conteúdo de `OrderScheduledFlow`, do relatório `CommercialSignals_ByAccount` e dos relatórios "SEM COMPRA".
9. **SFAgent2:** a versão ativa e o texto das instruções do tópico não foram lidos. `BotDefinition` não é consultável nesta org (informação da análise), então a ativação não pôde ser conferida.
10. **Validation rules de Order:** 17 ativas hoje. A análise citava 23; não verifiquei a diferença (pode ser total, com inativas).
11. **Marketing Cloud Connect:** consulta de campos limitada a 30; ausência de campos `et4ae5` nos objetos tocados não provada.
12. **Volume real e dados do Protheus:** dev vazia; a QAS não foi consultada nesta sessão (só a dev está conectada).

## Pontos para o arquiteto

- Reaproveitar `CommercialSignal__c`, `CommercialSignalSetting__mdt`, as 4 classes + testes, o relatório e os permission sets; o delta é de janela (mês fechado + média de 3), limiar (20%), dias (90), agrupamento por família (`Group__c` ou outro) e campo de grupo (`Sector__c` já suportado por configuração).
- A "data de faturamento" não existe: o design precisa nomear o campo escolhido e registrar como premissa a validar (regra 4).
- Compatibilidade técnica não tem fonte na org: limitar a complementar por família e declarar dependência de tabela da Eplast. Não criar regra.
- `Product2.Family` está vazia (valor `None`): família depende de `Group__c`, cujos códigos não foram confirmados.
- Assistente: `ConsultarPedidos` (`queryRecords`) é a via mais curta para ler `CommercialSignal__c` no `SFAgent2` (nova versão, não edição da ativa). O Agentforce lê com o usuário da conversa, então o acesso passa pelo OWD `ControlledByParent` e pelos permission sets listados.
- Os batches da rodada anterior são `without sharing`; avaliar se isso continua aceitável diante de "relatório respeita o compartilhamento do usuário" (a leitura do relatório é pelo pai, `Account`).
- Os relatórios "SEM COMPRA - ..." do Marketing Cloud usam faixas de 91 a 180/181 a 365 dias: o corte de 90 dias da nova régua deve ser conciliado, sem criar uma segunda lista divergente.
- Sem escrita em `Account`/`Order`/`OrderItem` (trigger `AccountTrigger` e CPQ no mesmo evento); dev vazia exige fixture e as regras de validação de Order.
