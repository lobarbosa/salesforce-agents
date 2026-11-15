# EPLAST-33 — Recon da org

**Org consultada:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY, sandbox, API 68.0, instância `eplast--qa.sandbox.my.salesforce.com`). Confirmada por `sf org list` (única org conectada) e `sf org display`. **Data da coleta:** 2026-11-15. Só metadata e contagens agregadas; nenhum registro lido. Flows retirados com retrieve para `/tmp/reconproj/recon` (fora do repositório).

**Alerta de ambiente:** o alias de dev aponta para uma instância cujo host e username se identificam como `qa`. `sf org list` mostra só este alias; a sandbox `sbx-eplast-qa` não está conectada nesta sessão, então não foi possível comparar as duas. Dev e QA podem ser a mesma org (não confirmado).

## 1. O que já cobre o pedido

| Item | O que existe (confirmado) | Cobre | Comando |
|---|---|---|---|
| Agente `SFAgent2` | `GenAiPlannerDefinition` `SFAgent2_v1` a `v4`. Ações (`GenAiFunctionDefinition`): `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta` e também `QueryRecords`. Tópicos (`GenAiPluginDefinition`): `agent_router`, `ambiguous_question`, `insights_comerciais`, `off_topic`, e `GeneralFAQ` em versões antigas. Há várias versões de cada. Régua de 60 dias e de 30% **não relida** (só vem da recon anterior) | Parcial, por conversa, conta a conta. Não lista carteira | Tooling `GenAiPlannerDefinition`, `GenAiFunctionDefinition`, `GenAiPluginDefinition` |
| Flow `ScheduledFlowOpportunity` | Agendado diário (início 2024-01-23). Filtra `Opportunity.IsWon = true`, lê `GetOpportunities`, `RankingRange__mdt` (7 registros) e `ScheduledFlowOpportunitySetting__mdt`. **Escreve em `Account`: `LastMonthPurchaseValue__c` e `Ranking__c`**; lê `Opportunity.ThisYear__c`. Também referencia `IntegrationLog__c` | Parcial: ranking e valor do último mês por conta, **a partir de Opportunity, não de Order** | retrieve do Flow e leitura do XML |
| Flow `OrderScheduledFlow` | Agendado diário, 06:00Z, em `Order` com `Status = 'Liberação Financeira'` (com acento). Faz lookup em `OrderHistory` e atualiza `Order` (`Status`, `ReasonCancellation__c`). Não calcula compra | Não cobre. Escreve em Order | retrieve do Flow |
| Relatórios de pedido por conta | 18 relatórios com nome ligado a pedido/cliente, entre eles `PEDIDOS POR CLIENTE`, `CONTAS COM PEDIDOS - EM CRIAÇÃO`, `ARI F (OPORTUDNIDADES COM PEDIDOS)`, `Clientes Recorrentes`, `Pedidos Concluídos HOJE`, `PEDIDOS FATURADOS - GARRAFA`. Total na org: 380 relatórios e 20 painéis. **Filtros e colunas não lidos** | Desconhecido se algum entrega a lista de recuperação | `SELECT Name, FolderName FROM Report WHERE ...` |
| Permission sets de negócio | `PS_Comercial_ResumoClienteAgente`, `PS_Marketing_AnaliseCampanhas` existem. Conteúdo não lido | Podem ser a base de acesso (ver seção 5) | `SELECT Name FROM PermissionSet` |
| Apex de cruzada, recuperação ou sugestão | Nenhuma classe própria com nome `Cross`, `Recup`, `Sugest`, `Oportun`. Classes próprias de Order/Account são de integração Protheus e de trigger (`OrderAdapter`, `OrderUtility`, `OrderTriggerHandler`, `OrderTriggerHelper`, `AccountTriggerHandler`, `AccountTriggerHelper`, `SendOrderToProtheus` e afins) | Nada reaproveitável | Tooling `ApexClass` (56 classes sem namespace; 523 do pacote `et4ae5`) |

## 2. O que será tocado (leitura)

| Objeto.campo | Tipo | Confirmado | Observação |
|---|---|---|---|
| `Order.Status` | picklist | sim | Valores: `Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`, `Faturamento`, `Cancelado`, `Concluido`. Sem acento. O `OrderScheduledFlow` filtra por `'Liberação Financeira'` (com acento): grafia diferente da picklist, a investigar |
| `Order.EffectiveDate` | date | sim | padrão |
| `Order.TotalAmount` | currency | sim | padrão |
| `Order.AccountId` | reference | sim | padrão |
| `Order.ProtheusId__c` | string | sim | vínculo com o ERP |
| `OrderItem.Product2Id`, `OrderId`, `Quantity`, `TotalPrice` | | sim | |
| `Account.Industry` | picklist | sim | 0 contas, preenchimento não verificável |
| `Account.TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c` (currency), `LastPurchase__c` (date) | custom | sim | Sem texto de ajuda (`inlineHelpText` vazio); `Description` não verificada. `LastMonthPurchaseValue__c` é escrito pelo `ScheduledFlowOpportunity` com base em Opportunity. Quem escreve os outros três não foi investigado |
| `Account.Ranking__c` | custom | sim (via Flow) | Não descrito com `sf sobject describe` |
| `Product2` | padrão | sim | 1.042 registros |

Faltaria criar (sem decidir): armazenamento de parâmetros (janelas, limiares, status). Já existem `RankingRange__mdt` e `ScheduledFlowOpportunitySetting__mdt` como padrão de custom metadata na org, e o conteúdo delas não foi lido. Nada na org representa "tipo de oportunidade" por conta.

## 3. Automação concorrente

| Objeto | Item | Tipo | Evento | Fonte |
|---|---|---|---|---|
| Order | `OrderTrigger` (SBQQ) | trigger CPQ | ativo | Tooling `ApexTrigger` |
| Order | `OrderTrigger` (próprio, sem namespace) | trigger custom | ativo. Mesmo nome do CPQ, namespaces diferentes | idem |
| OrderItem | `OrderProductTrigger` (SBQQ) | trigger CPQ | ativo. Sem trigger próprio em OrderItem | idem |
| Account | `AccountBefore` (SBQQ) e `AccountTrigger` (próprio) | triggers | ativos | idem |
| Opportunity | `OpportunityBefore`, `OpportunityAfter` (SBQQ) e `OpportunityTrigger` (próprio) | triggers | ativos | idem |
| Order | Flow `Order` ("Pedido") | record-triggered after save, create e update, atualiza Opportunity | ativo | retrieve |
| Order | Flow `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | pelo nome, before update em Order | ativo; **XML não lido** | lista de Flows ativos |
| Order | `OrderScheduledFlow` | agendado, atualiza Order | ativo | retrieve |
| Account | `AccountTriggered` | record-triggered after save, create e update | ativo | retrieve |
| Account | `AccountUpdateEconomicGroup` | agendado, uma vez (2024-07-26), atualiza Account | ativo | retrieve |
| Account | `ScheduledFlowOpportunity` | agendado diário, atualiza Account | ativo | retrieve |
| Opportunity | `OpportunityFlow` | record-triggered after save, atualiza Order, Account e Quote | ativo | retrieve |
| Account (MC) | Flows `MCC_*` (14 Flows `AutoLaunched`, conector) | ativos. Objeto de disparo não lido | lista de Flows ativos |

| Validation rules | Total | Ativas | Fonte |
|---|---|---|---|
| Order | 23 | 17 ativas, 6 inativas | Tooling `ValidationRule` |
| Account | 6 | 6 ativas | idem |
| OrderItem | 4 | 4 ativas | idem |

Risco para o arquiteto: a v1 prevista é somente leitura, então não entra na cadeia de escrita de Order. O que escreve em Account hoje (`ScheduledFlowOpportunity` diário, `AccountTriggered`, `AccountUpdateEconomicGroup`) não foi mapeado por ordem de execução entre trigger próprio, trigger CPQ e Flow; só a lista foi levantada. A ordem relativa entre before-save Flow e trigger não foi testada.

## 4. Volume e dados de teste

| Objeto | `COUNT()` na dev |
|---|---|
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| OrderItem | 0 |
| Product2 | 1.042 |
| Contact, Lead, Campaign, CampaignMember | 0, 0, 0, 0 |
| Account com Industry preenchido | 0 |

A sandbox não tem dado de negócio para testar. Todo teste precisa de fixture sintética, e criar `Order` esbarra em 17 validation rules ativas. A lista de campos que essas regras exigem não foi levantada.

## 5. Permissões e compartilhamento

| Objeto | OWD interno | OWD externo | Fonte |
|---|---|---|---|
| Account | ReadWrite | Private | Tooling `EntityDefinition` |
| Order | ReadWrite | Private | idem |
| OrderItem | ReadWrite | ReadWrite | idem |
| Opportunity | Read | Private | idem |
| Product2 | ReadWrite | ReadWrite | idem |

- 33 perfis na org (`COUNT()` em `Profile`).
- Permission sets próprios com leitura de `Order`: `Protheus`, `Modify_All`, `Analista_Permissao`. Perfis e demais permission sets não foram enumerados.
- Existem `PS_Comercial_ResumoClienteAgente`, `PS_Marketing_AnaliseCampanhas`, `Sales_User`, `Marketing_Cloud_Connected_App`, `SteelBrickCPQStandardObjectsAccess` (nomes confirmados; permissões não lidas).
- Para o critério de acesso por compartilhamento (CA-13): o OWD é Account e Order privados para externos e leitura e escrita para internos, então o efeito do `WITH USER_MODE` para usuário interno é ampliado. Papéis e regras de compartilhamento não foram levantados.

## 6. Marketing Cloud Connect (`et4ae5`)

| Item | Achado | Fonte |
|---|---|---|
| Objetos | Pacote instalado, com objetos como `et4ae5__AggregateLink__c`, `et4ae5__Automated_Send__c`, `et4ae5__Business_Unit__c`, `et4ae5__Campaign_Member_Configuration__c`, `et4ae5__Configuration__c`, `et4ae5__ET4AEConfig__c`, `et4ae5__ET4AE_Config__c`, `et4ae5__Email_Linkage__c` (lista cortada pelo filtro, não exaustiva) | `sf sobject list --sobject custom` com filtro |
| Campos do pacote em `Account` | Nenhum retornado | Tooling `CustomField`, `NamespacePrefix = 'et4ae5'` |
| Campos do pacote em `Contact` e `Lead` | `HasOptedOutOfMobile` e `Mobile_Country_Code` retornados com esse filtro de namespace | idem |
| Flows | 14 Flows `MCC_*` ativos (backup, envio agendado, tracking) | lista de Flows ativos |
| `Campaign` e `CampaignMember` | existem e estão vazios | `COUNT()` |

Não foi lido o que o conector grava ou lê. Nada foi feito no Marketing Cloud. A demanda toca marketing só pela exportação da lista (ID e tipo da conta, PA-10), e a seção "Preparação do Sales Cloud para o Marketing Cloud" é do desenho.

## 7. O que não consegui confirmar

1. Se dev e QA são a mesma org: só uma org conectada, com instância e username `qa`.
2. A lógica de 60 dias e de 30% do `SFAgent2`: não li o metadata das instruções do planner/tópicos, só a existência.
3. Status ativo ou inativo de cada versão do `SFAgent2`: `BotDefinition` não é consultável aqui.
4. Filtros e colunas dos 18 relatórios candidatos; se algum entrega recuperação.
5. Conteúdo de `RankingRange__mdt` (7 registros) e de `ScheduledFlowOpportunitySetting__mdt`.
6. Quem escreve `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c` e `LastPurchase__c`, e se `Description` desses campos está vazia. Só confirmei ausência de texto de ajuda.
7. O que faz o Flow `Acionado_por_registro_Antes_de_atualizar_Pedido...` (XML não lido) e o objeto de disparo dos `MCC_*`.
8. Ordem de execução efetiva em Order e Account entre trigger próprio, trigger CPQ e Flows (só inventário).
9. Campos exigidos pelas 17 validation rules ativas de Order.
10. Grafia do status: picklist `Liberacao Financeiro` (sem acento) contra o filtro `Liberação Financeira` do `OrderScheduledFlow`.
11. Papéis, regras de compartilhamento, perfis e conteúdo dos permission sets de negócio.
12. Qualquer dado real: Account, Order, OrderItem e Opportunity estão vazios; distribuição de `Industry` e volume de produção não foram medidos.
