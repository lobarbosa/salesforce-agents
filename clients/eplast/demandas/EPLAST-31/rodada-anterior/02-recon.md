# EPLAST-31 — Recon da org

**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`) · **IsSandbox:** true · Enterprise Edition · API v68.0
**Data da coleta:** 2026-11-10 · válido até 2026-11-17 (recon com mais de 7 dias está vencido)
**Método:** `sf org display`, `sf sobject describe`, `sf data query` (só metadata e `COUNT()`), Tooling API, `sf project retrieve start` para `/tmp/recon` (nada foi trazido para `force-app/`).
**Nenhum dado de negócio foi lido.** Os relatórios foram lidos só na definição (tipo, colunas, filtros); nenhum foi executado.

`sbx-eplast-qa` **não está autenticada** neste runner (`sf org list` mostra só `sbx-eplast-dev`). Não houve comparação dev × qa. A instância de `sbx-eplast-dev` continua com sufixo "qa" no nome (achado 6 do assessment, ainda aberto).

---

## 1. Volume

| Objeto | `COUNT()` em dev |
|---|---|
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| ForecastingItem | 0 |
| ForecastingQuota | 0 |
| OpportunityFieldHistory | 0 |

Igual ao assessment: a sandbox está vazia. Volume de produção não pode ser inferido daqui. Mesmo assim, os relatórios abaixo foram executados entre agosto e setembro de 2026 (`Report.LastRunDate`). Ou a sandbox foi copiada de um ambiente com uso, ou ela já foi usada de verdade. Isso reforça a dúvida do achado 6.

## 2. Previsão nativa (Forecasting) já está ligada, mas sem estrutura

| Item | Estado na org | Fonte |
|---|---|---|
| `ForecastingSettings.enableForecasts` | **true** | retrieve `Settings:Forecasting` |
| Tipos de previsão ativos | **1**: `Opportunity_Amount` (receita de oportunidade, `RoleType = R`, hierarquia por **papel**) | `ForecastingType WHERE IsActive = true` |
| Tipos por território (`ManagementAccount*`, 8 variações) | existem, **todos inativos** | `ForecastingType` |
| Mapeamento de categorias | padrão (Pipeline, Best Case, Commit, Closed, Omitted) | retrieve `Settings:Forecasting` |
| Usuários com `ForecastEnabled = true` | **1** de 22 ativos | `COUNT` agrupado |
| Hierarquia de papéis | **2 papéis**, ambos raiz, sem pai: `Coordination`, `Financeiro`. **17 usuários padrão ativos sem papel** | `UserRole`, `User GROUP BY UserRole` |
| Cotas (`ForecastingQuota`) | 0 registros | `COUNT()` |
| Licença `Salesforce Forecasting` (PSL) | 14 disponíveis, 0 usadas | `PermissionSetLicense` |
| Pipeline Inspection | ligado (`enablePipelineInspection`, `enableForecastCategoryMetrics`, `enablePipelineChangesMetrics` = true). PSL `Pipeline Inspection`: 14, 0 usadas | retrieve `Settings:Opportunity`, `PermissionSetLicense` |
| Histórico de campo de Opportunity | **desligado** (`enableOpportunityFieldHistoryTracking = false`) | retrieve `Settings:Opportunity` |
| Opportunity Teams | desligado | idem |

**Leitura:** o recurso nativo existe e está ligado, mas a previsão por papel depende de uma hierarquia de papéis que, nesta org, praticamente não existe. Montar essa hierarquia muda o modelo de compartilhamento: não é configuração neutra.

## 3. Território (Enterprise Territory Management)

| Item | Estado |
|---|---|
| `Territory2Settings.enableTerritoryManagement2` | **true** |
| `Territory2Model` | 1, `ManagementAccount`, **State = Active** |
| `Territory2` (territórios) | **0** |
| Acesso padrão concedido por território | Account Edit, Opportunity Read, Contact Edit, Case Read, Forecast Read |
| Filtro de atribuição de território em Opportunity | desligado |
| Campo `Opportunity.Territory2Id` | existe (padrão) |

Há um modelo ativo vazio. Popular territórios abre acesso a registros pelas regras acima, o que também é decisão de compartilhamento.

## 4. Campos relevantes

### Opportunity (77 campos, 28 custom)

| Campo | Tipo | Observação |
|---|---|---|
| `Amount`, `CloseDate`, `Probability`, `StageName`, `ForecastCategoryName`, `OwnerId`, `IsClosed`, `Territory2Id` | padrão | `StageName` tem fases próprias (Qualificação … Negociação Comercial, Fechado/Ganho) |
| `Previs_o_Eintein__c` ("Previsão Einstein") | número (double) | **Sem descrição. Não editável pelo usuário da sessão. Não é referenciado** em `OpportunityFlow`, `Oportunidade_Industria`, `ScheduledFlowOpportunity` nem em `OpportunityTrigger`. Origem e uso desconhecidos |
| `Branch__c` ("Filial") | lookup → `Branch__c` | sem descrição. `Branch__c` tem endereço, CNPJ e código ERP |
| `LastMonth__c` / `LastMoth__c` ("Mês Passado") | fórmula booleana | duplicados (mesma fórmula, um com erro de digitação no nome). Usam `CloseDate` |
| `CurrentYear__c` / `ThisYear__c` | fórmula booleana | duplicados. Usam `CreatedDate` |

**Não existe** em Opportunity campo de região, carteira ou meta.

### Account (136 campos, 90 custom)

Nenhum campo de região, carteira, território ou meta. O que existe e é usado nos relatórios atuais: `OwnerId` (padrão), `BillingState` (padrão), `EconomicGroup__c` (lookup), `Sector__c` (picklist), `TotalPurchasesThisYear__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c`, `LastPurchase__c`. Todos sem descrição nos que foram conferidos.

### Order (111 campos, 64 custom)

| Campo | Rótulo | Tipo |
|---|---|---|
| `ExpectedSaleDate__c` | Data previsão de vendas | date, sem descrição |
| `Salesperson1__c`, `Salesperson2__c` | Vendedor 1 / Vendedor 2 | **texto livre** (não é lookup para User), sem descrição |
| `Branch__c` | Filial | texto (em Opportunity é lookup) |
| `TotalAmount` | Valor do pedido | currency (padrão) |
| `TypeOperation__c` | Tipo de Operação | lookup → `TypeOperation__c` |

### User

`ProtheusSellerId__c` (Id do usuário no Protheus). Nenhum campo de meta, região ou carteira.

### Meta

Nenhum objeto ou campo custom de meta em Account, Opportunity, Order ou User. `ForecastingQuota` com 0 registros. **A fonte da meta não está na org de dev.** EPLAST-32 diz que "a pergunta do agente sobre o gap da meta mensal já foi entregue": se isso é verdade, a meta vive em outro lugar (outro ambiente, planilha ou fora da esteira) e precisa ser localizada.

### Objetos custom sem namespace

`Branch__c`, `EconomicGroup__c`, `FormPayment__c`, `In_App_Checklist_Settings__c`, `IntegrationLog__c`, `PaymentTerms__c`, `RelationshipAccountsPaymentTerm__c`, `SalesReturn__c`, `ShippingCompany__c`, `TypeOperation__c`. Nenhum de meta, carteira ou região.

## 5. Como o comercial já enxerga "carteira", "região" e "previsão" hoje

Relatórios existentes (definição lida, nenhum executado). 374 relatórios na org, 19 dashboards.

| Relatório (pasta) | Tipo | O que a definição mostra |
|---|---|---|
| `Nmero_Total_das_Carteiras_oSx` (ANALISTAS) | `AccountList` | **Carteira = contas agrupadas pelo proprietário** (`USERS.NAME`) |
| `Nmero_Total_da_Carteira_SP_mjh` (ANALISTAS) + variações CO, MG, RJ, SUL, NONE | `AccountList` | **Região = UF de cobrança da conta** (`ADDRESS1_STATE`, filtro `SP`). "SUL" e "CO" sugerem agrupamento de UFs em regiões |
| `ANLISE_DA_CARTEIRA_MENSAL_Kkj` (ANALISTAS) | MultiBlock: `AccountList` + `Opportunity` | conta, UF, grupo econômico, última compra + oportunidades do mês por fase, valor e motivo de perda |
| `Previso_de_Pedidos_Perodo_Yko` (RELATÓRIOS DIÁRIOS - ADV) | `OrderList` | **"Previsão" = pedidos com `ExpectedSaleDate__c` no período**, agrupados por status, por proprietário da conta, setor, tipo de operação |
| `Previs_o_de_Imputados_Per_odo_ANA`, `Previso_de_Pedidos_Q4W` | (não lidos, nomes sugerem o mesmo padrão em Order) | — |
| `Sales_Exec_Open_Pipeline`, `Sales_Manager_Open_Pipeline`, `Pipeline_Report_This_Q` | relatórios padrão de pipeline de Opportunity | — |

Isso é evidência de **prática atual**, não de requisito. Mas mostra uma quarta leitura de "previsão" que a análise não listou: previsão de **pedido** (Order, data de previsão de venda), não de oportunidade.

## 6. Automação nos objetos candidatos

### Triggers (ativos)

| Objeto | Trigger | Namespace | Eventos |
|---|---|---|---|
| Opportunity | `OpportunityTrigger` | custom | after insert, after update. Chama `OpportunityTriggerHandler`, respeita `TriggerUtility.bypassTrigger`, pula after update em contexto Queueable |
| Opportunity | `OpportunityBefore` | SBQQ | before insert/update/delete |
| Opportunity | `OpportunityAfter` | SBQQ | after insert/update |
| OpportunityLineItem | `OpportunityLineItemTrigger` | SBQQ | todos |
| Account | `AccountTrigger` | custom | before/after insert/update |
| Account | `AccountBefore` | SBQQ | before insert/update |
| Order | `OrderTrigger` | custom | before/after update |
| Order | `OrderTrigger` | SBQQ | todos |
| OrderItem | `OrderProductTrigger` | SBQQ | todos |

### Flows custom (ativos) nos mesmos objetos

| Objeto | Flow | Tipo | Observação |
|---|---|---|---|
| Opportunity | `OpportunityFlow` | RecordAfterSave, create+update | **Sem critério de entrada** no start. 10 updates, 12 creates, 10 lookups, 4 action calls. Escreve em Opportunity, Account, Order, Quote, QuoteLineItem, Task, PermissionSetLicenseAssign |
| Opportunity | `Oportunidade_Industria` | RecordAfterSave, update | entra só com fase alterada e tipo de registro Indústria. Cria Task |
| Opportunity | `ScheduledFlowOpportunity` | Scheduled, diário | oportunidades ganhas. Atualiza Opportunity e Account |
| Account | `AccountTriggered`, `UpdateParentAccountUsedLimit` | RecordAfterSave | — |
| Account | `AccountUpdateEconomicGroup` | Scheduled | — |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | RecordBeforeSave | — |
| Order | `Order` | RecordAfterSave | — |
| Order | `OrderScheduledFlow` | Scheduled | — |

**Qualquer escrita em Opportunity dispara 3 triggers (1 custom + 2 CPQ) e até 2 Flows after-save, um deles sem critério de entrada e que grava em Order.** Achado 1 do assessment confirmado em 2026-11-10.

## 7. Permissões

| Item | Estado |
|---|---|
| Perfis comerciais | `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas` (achado 8, ainda aberto) |
| Permission sets custom ligados ao comercial | `PS_Comercial_ResumoClienteAgente`, `Sales_User` |
| Permission set de previsão | nenhum custom |
| PSLs de IA/vendas disponíveis e sem uso | Salesforce Forecasting (14), Pipeline Inspection (14), Agentforce Sales Coach, Einstein Prompt Templates, Einstein AI Skills, Tableau Next Limited Consumer, entre outras. **Nenhuma PSL de "Sales Cloud Einstein" / Einstein Forecasting** apareceu na lista de PSLs ativas |

## 8. Apex

56 classes custom sem namespace (eram 54 no assessment). Cobertura org-wide continua sendo a do achado 2 (não recalculada nesta coleta). Nenhuma classe foi lida nesta etapa: não há decisão de código para apoiar.

## 9. O que não foi verificado

- Sandbox de QA (não autenticada): sem comparação de metadata.
- OWD de Account e Opportunity (mesma lacuna do assessment).
- Origem de `Previs_o_Eintein__c` (Einstein Discovery, integração ou campo manual abandonado). Não há classe ou Flow, entre os lidos, que o escreva.
- Conteúdo dos 19 dashboards e dos relatórios além dos 4 lidos.
- Onde está a meta citada na EPLAST-32.
