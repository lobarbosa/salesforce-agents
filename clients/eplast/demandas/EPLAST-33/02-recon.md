# EPLAST-33 — Recon da org

**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`) · **IsSandbox:** true · Enterprise Edition · API v68.0
**Data da coleta:** 2026-11-11 · válido até 2026-11-18 (recon com mais de 7 dias está vencido)
**Método:** `sf org display`, `sf sobject describe`, `sf data query` (só metadata e `COUNT()`), Tooling API, `sf org list metadata`, `sf project retrieve start` para `/tmp/recon/e33` (nada foi trazido para `force-app/`).
**Nenhum dado de negócio foi lido.** Só contagens, definições de campo, picklists, metadata de automação e permissões. Relatórios foram contados e listados por tipo, nunca executados.

`sbx-eplast-qa` **não está autenticada** neste runner (`sf org list` mostra só `sbx-eplast-dev`). Não houve comparação dev × qa. A instância de `sbx-eplast-dev` continua com sufixo "qa" no host e no usuário (achado 6 do assessment, **ainda aberto**).

---

## 1. Volume (`COUNT()` em dev)

| Objeto | Registros |
|---|---|
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| OrderItem | 0 |
| Task | 0 |
| Asset / Contract | 0 / 0 |
| `SBQQ__Quote__c` / `SBQQ__QuoteLine__c` / `SBQQ__Subscription__c` | 0 / 0 / 0 |
| **Product2** | **1042** |
| **Pricebook2** | **3723** |
| **PricebookEntry** | **35681** |

Leitura: a dev não tem nenhuma transação. O catálogo de produtos e preços está carregado. O volume de pedidos e itens por conta em produção **não é conhecido** e não pode ser inferido daqui. Produção não é consultada (guardrail #1).

## 2. Compartilhamento (OWD, `EntityDefinition.InternalSharingModel`)

| Objeto | Interno | Externo |
|---|---|---|
| Account | ReadWrite | Private |
| Order | ReadWrite | Private |
| OrderItem | ReadWrite (segue Order) | ReadWrite |
| Opportunity | Read | Private |
| Product2 | ReadWrite | ReadWrite |
| Task | Private | Private |

**Fato que pesa no design:** Account e Order são públicos para leitura e escrita internamente. A "carteira" (RN-4) **não** pode ser garantida por compartilhamento. Na prática ela é um **filtro** ("minhas contas", por `OwnerId` ou outro critério), não uma barreira de segurança. Isso é uma decisão de negócio (Q10), não algo que este design possa endurecer sem mudar OWD (fora de escopo).

## 3. Campos relevantes às três regras (`sf sobject describe` + Tooling `CustomField`)

Account 136 campos (90 custom), Order 111 (64), OrderItem 62 (41), Product2 100 (79). Nenhum dos campos abaixo tem `Description` (achado 4 do assessment, reconfirmado para estes).

### 3.1 Recuperação ("sem compra")

| Campo | Tipo | Definição confirmada na org |
|---|---|---|
| `Account.LastPurchase__c` ("Última Compra") | **Roll-up summary** | `MAX(Opportunity.CloseDate)` com filtro `Opportunity.StageName = 'Fechado/Ganho'`. **Vem de Opportunity ganha, não de Order.** |
| `Account.Inactive__c` ("Inativo") | Fórmula checkbox | `IF((today() - LastPurchase__c) > 90, true, false)` |
| `Order.EffectiveDate` ("Data de emissão") | Date | padrão |
| `Order.IssuanceDate__c` ("Data emissão") | Date | custom, sem descrição. Duas "datas de emissão" coexistem. |
| `Order.Status` | Picklist | valores ativos: `Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`, `Faturamento`, `Cancelado`, `Concluido` |
| `Order.StatusCode` | Picklist (sistema) | `Draft`, `Activated`, `Canceled`, `Expired`, `Superseded` |

**A org já tem uma regra de recuperação pronta, em configuração:** `Inactive__c` = 90 dias sem Opportunity ganha. Ela não é a mesma regra que o agente `SFAgent2` usa (seção 5).

### 3.2 Volume

| Campo | Tipo | Observação |
|---|---|---|
| `Order.TotalAmount` | Currency | padrão |
| `Order.Total_com_Desconto__c` ("Total com Indenização") | Fórmula currency | rótulo e API name divergem |
| `Order.Volume1__c` ("Volume 1") | Text | texto, não número. Provavelmente volume de embalagem/expedição, **não confirmado** |
| `OrderItem.Quantity`, `OrderItem.TotalPrice`, `OrderItem.Product2Id` | padrão | |
| `Product2.QuantityConverter__c` ("Conversor") | Number | possivelmente conversão de unidade, **não confirmado** |
| `Account.TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c` | Currency | campos simples (não fórmula, não roll-up) |
| `Account.VolumeByMonth__c` ("Volume/Mês") | **Text** | pode ser volume potencial declarado do cliente, **não confirmado** |
| `Account.Deleted2__c` | Currency | rótulo "Média de compras este ano", duplicado de `AveragePurchasesThisYear__c` pelo rótulo |

Os quatro campos de compra/volume em Account só são **editáveis** pelo permission set `Protheus` (único PS não-perfil com edição, via `FieldPermissions`). É indício, **não prova**, de que o ERP os preenche.

`SalesReturn__c` (devoluções) existe como objeto custom, com report type `Devolucoes`. Se volume for líquido de devolução, entra na regra (pergunta nova, seção 9).

### 3.3 Venda cruzada

| Campo | Observação |
|---|---|
| `Product2.Family` | **1 valor ativo** no picklist. Não serve para agrupar produtos |
| `Product2.Group__c` ("Grupo") | Text, sem descrição. Candidato a agrupamento, a confirmar |
| `Product2.ProtheusId__c` | código do produto no ERP |
| `Product2.IsActive` | padrão |
| `Account.Sector__c` (9 valores ativos), `Industry` (32), `Subsector__c` multipicklist (18), `Subcategoria__c` (7), `Type` (9), `EconomicGroup__c` (lookup `EconomicGroup__c`) | candidatos a "grupo de referência" (Q8) |
| `Account.Products__c` ("Produtos"), `CustomerPurchasesBlownBottle__c` | texto livre e flag. Não estruturados |

### 3.4 Carteira

| Campo | Observação |
|---|---|
| `Account.OwnerId`, `Order.OwnerId` (User ou Group) | padrão |
| `Order.Salesperson1__c`, `Salesperson2__c` ("Vendedor 1/2") | **texto livre**, não lookup |

## 4. Automação nos objetos da demanda

### 4.1 Triggers ativos (Tooling `ApexTrigger`)

| Objeto | Trigger | Namespace | Eventos |
|---|---|---|---|
| Account | `AccountBefore` | SBQQ | before insert/update |
| Account | `AccountTrigger` | — | before+after insert/update |
| Opportunity | `OpportunityBefore` / `OpportunityAfter` | SBQQ | before / after insert/update |
| Opportunity | `OpportunityTrigger` | — | after insert/update |
| Order | `OrderTrigger` | SBQQ | before+after insert/update |
| Order | `OrderTrigger` | — | before+after update |
| OrderItem | `OrderProductTrigger` | SBQQ | before+after insert/update |
| Product2 | `ProductBefore` / `ProductAfter` | SBQQ | before / after insert/update |

### 4.2 Flows record-triggered ativos (`FlowDefinitionView`)

| Objeto | Flow | Tipo |
|---|---|---|
| Account | `AccountTriggered`, `UpdateParentAccountUsedLimit` | RecordAfterSave |
| Account | `AccountUpdateEconomicGroup` | Scheduled |
| Opportunity | `Oportunidade_Industria`, `OpportunityFlow` | RecordAfterSave |
| Opportunity | `ScheduledFlowOpportunity` | Scheduled |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | RecordBeforeSave |
| Order | `Order` | RecordAfterSave |
| Order | `OrderScheduledFlow` | Scheduled |
| Product2 | `ProductFlowNewOrUpdated` | RecordAfterSave |
| Task | `TaskCreatedOrUpdated` | RecordAfterSave |

OrderItem não tem Flow record-triggered custom.

### 4.3 Efeito colateral de qualquer escrita em Account (confirmado lendo `AccountTriggerHelper`, retrieve em `/tmp/recon/e33`)

`updateAccountInfoFromCNPJ` roda em todo update de Account e, para **cada conta**, faz `System.enqueueJob` de `UpdateAccountCompanyInfo` (se o CNPJ mudou) ou de `SendAccountToProtheus` (em qualquer outro caso). Não há filtro de campo. Gravar qualquer campo em Account reenvia a conta ao ERP. Em lote síncrono acima de 50 contas, isso estoura o limite de 50 `enqueueJob` por transação. Isso confirma, nesta data, o que o design da EPLAST-27 já registrava [RAG: `demandas/EPLAST-27/03-design.md`, D1].

### 4.4 Integração Protheus (o que pesa para criar fixture de teste)

- Classes custom: `ProtheusAPI`, `ProtheusOrderAPI`, `ProtheusRequest`, `SendAccountToProtheus`, `SendOrderToProtheus`, `UpdateAccountWithProtheusInfo`, `GetClientFromProtheusTDF`, `OrderAdapter`, entre outras.
- O endpoint vem do custom metadata `Protheus__mdt` (registro `Credentials`, campo `BaseURL__c`). O valor **não foi lido**.
- **As duas Remote Site Settings `ProtheusProd` e `ProtheusQA` estão ativas nesta sandbox.** Não há Named Credential.
- `TriggerUtility__mdt.TriggerExecution.BypassTrigger__c = false`, então os triggers custom estão ligados.
- Existe `SendOrderToProtheus`: pedido também **sai** do Salesforce para o ERP. O contrato diz que os pedidos "vêm do Protheus". O sentido real (ou os dois) **não foi confirmado**. Isso importa: se parte dos pedidos nasce só no ERP e nunca chega ao Salesforce, a regra de recuperação sobre Order fica incompleta.

**Consequência:** criar Account ou Order de fixture na dev, pela UI ou por carga, aciona callout ao ERP configurado em `Protheus__mdt`. Com `ProtheusProd` liberado na Remote Site, não dá para afirmar que esse ERP não é o de produção.

## 5. Agentforce: o que já existe sobre o tema

`BotDefinition`: **`SFAgent2`** (tipo `InternalCopilot`, template Agentforce Employee Agent). `BotVersion` 1 a 4, **todas `Inactive`** na dev. `GenAiPlannerBundle`: `SFAgent2_v1` a `SFAgent2_v4`. **Não existe `SFAgent2_v5`** na org (o RAG cita uma v5 no design da EPLAST-29: é proposta, não metadata). `GenAiPlugin`, `GenAiFunction` e `GenAiPromptTemplate`: 0.

Retrieve de `SFAgent2_v4` em `/tmp/recon/e33/agent` (Agent Script decodificado). Subagentes: `agent_router`, `off_topic`, `ambiguous_question`, **`insights_comerciais`**. As ações usam só ações padrão de leitura: `identifyRecordByName`, `queryRecords`, `queryRecordsWithAggregate`. As instruções dizem "Never modify any records; only read data".

**O `insights_comerciais` já cobre boa parte desta demanda:**

| Pedido da EPLAST-33 | O que o `SFAgent2_v4` já faz | Regra que ele usa |
|---|---|---|
| Recuperação | CENÁRIO 4 "clientes há mais tempo sem comprar": ranking por `MAX(Order.EffectiveDate)` na carteira, separando quem nunca comprou | sem limiar, ranking |
| Recuperação | CENÁRIO 9 (passo 3): clientes sem compra há mais de **60 dias** | `HAVING MAX(EffectiveDate) < LAST_N_DAYS:60` |
| Aumento de volume (só o lado da **queda**) | CENÁRIO 3 "clientes que reduziram as compras" e STEP 7D: queda maior que **30%** comparando 3 meses com os 3 anteriores | `SUM(TotalAmount)` e `COUNT` por conta |
| Venda cruzada (só **recompra** da própria conta) | STEP 5(d): produtos presentes em pedidos antigos e ausentes nos recentes | não compara com outras contas |
| Venda cruzada **por grupo de referência** (RN-3) | **não existe** | — |
| Aumento de volume **para cima** (potencial) | **não existe** | — |

**Defeito latente confirmado no agente (fora do escopo desta demanda, registrado):** os filtros usam `Order.Status NOT IN ('Cancelled','Draft')` e `Status = 'Activated'` / `'Completed'`. **Nenhum desses valores existe** no picklist `Order.Status` desta org (seção 3.1). Na prática, pedidos `Cancelado` contam como compra, e o cálculo de "realizado" por pedido volta vazio. Mesmo `StatusCode` usa `Canceled`, não `Cancelled`. É território de `eplast-ent-09/10/11` (construídos fora da esteira).

**Três definições de "sem compra" já coexistem na org:** `Inactive__c` (90 dias, Opportunity ganha), CENÁRIO 9 do agente (60 dias, Order) e CENÁRIO 4 do agente (ranking, Order, sem limiar). `eplast-ent-11` ainda vai definir a sua. O risco que a análise previu ("duas listas de clientes sem compra com regras diferentes") **já está acontecendo**.

## 6. Relatórios e report types

- 374 relatórios na org. Pelo nome, 18 tratam de pedidos, produtos por região, produtos por conta ou catálogo. Nenhum, pelo nome, trata de inatividade ou recuperação. Não foram executados. Pastas não são citadas aqui porque várias têm nome de pessoa.
- Report types custom relevantes: `Pedidos_customizados` (base Order, sem filho, 119 campos) e `Gestao` (base Opportunity com Activities). Também existem `Devolucoes` e `PricebookEntries`. Para Order com itens, os report types padrão da plataforma atendem. Não há report type custom com OrderItem.

## 7. Apex, objetos e licenças

- 56 classes custom (sem namespace), API v58 a v67. Nenhuma trata de recomendação, venda cruzada ou recuperação. `CustomerSummaryService` (v67) é o scaffold da EPLAST-23 [RAG: `demandas/EPLAST-27/02-recon.md`]. Não foi relido aqui.
- Cobertura org-wide: **11%** (`ApexOrgWideCoverage`). O assessment registrou 10%.
- Objetos custom próprios: `Branch__c`, `EconomicGroup__c`, `FormPayment__c`, `In_App_Checklist_Settings__c`, `IntegrationLog__c`, `PaymentTerms__c`, `RelationshipAccountsPaymentTerm__c`, `SalesReturn__c`, `ShippingCompany__c`, `TypeOperation__c`. **Nenhum guarda oportunidade, recomendação ou score.**
- `PermissionSetLicense` presentes (sandbox): Einstein Prompt Templates, Agentforce Platform Developer and Admin, Data Cloud (starter), Agentforce Sales Coach, Einstein AI Skills, entre outras. **Não há licença de CRM Analytics.** Licenciamento de produção não foi verificado (fora de alcance).

## 8. Permissões

- Perfis comerciais: `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`. Só **`Comercial - Analista` tem usuário ativo (4)**.
- `Comercial - Analista` lê Account, Order e Product2 e tem "Run Reports" e "Create and Customize Reports". OrderItem segue a permissão de Order.
- `Comercial Padrão` não lê Order. `Comercial - Analistas` não lê Product2. Os dois não têm usuário ativo hoje.
- Permission sets custom: `PS_Comercial_ResumoClienteAgente`, `Protheus`. Permission set groups: 15, incluindo `SetupWithAgentforceUserPsg`, `SalesCloudSeller` e `SalesUsers`.

## 9. O que não pôde ser medido nesta coleta

- Volume de pedidos e itens por conta em produção, e quantos itens tem a maior conta (dev vazia, produção proibida). Sem isso, não há como dimensionar a agregação de venda cruzada contra o limite de 50.000 linhas por transação.
- Qual ERP `Protheus__mdt.BaseURL__c` aponta nesta sandbox. O valor não foi lido de propósito.
- Quem preenche `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c` e `VolumeByMonth__c`, e o que `VolumeByMonth__c` significa.
- Se os pedidos que nascem só no Protheus chegam ao Salesforce.
- Ordem real de execução entre os triggers `SBQQ` e os custom no mesmo evento. Isso não se mede por metadata.
- Comparação de metadata dev × QA (alias de QA ausente).
- Se o `SFAgent2` está ativo em **produção** e é o mesmo da v4 da dev.
