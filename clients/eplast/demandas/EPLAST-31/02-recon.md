# EPLAST-31 — Recon da org (rodada 2)

**Data da coleta:** 2026-11-15. Só leitura: metadata, contagens agregadas e retrieve para pasta temporária (removida ao final; `force-app/` não foi tocado).

## 0. Org confirmada

| Item | Resultado | Comando |
|---|---|---|
| Org conectada | Alias `sbx-eplast-dev`, sandbox, status Connected, Org ID `00DHa000006vfMLMAY`. Única org listada. | `sf org list` |
| É sandbox | `Organization.IsSandbox = true` | `sf data query -q "SELECT IsSandbox FROM Organization"` |
| Identidade dev x qa | O username e a URL da instância trazem a marca `qa` (achado 6 do assessment). Não escrevi o identificador aqui. Não consigo provar por `sf` se é a dev ou a QA. | `sf org list` |

## 1. O que já cobre o pedido

| Item | Existe? | O que faz hoje | Prova |
|---|---|---|---|
| Relatório `Previsão de Imputados Período` (DeveloperName `Previso_de_Pedidos_Perodo_Yko`, pasta `RELATÓRIOS DIÁRIOS - ADV`) | Sim | Tipo `OrderList`, Summary. Colunas: conta, dono da conta (`ACCOUNT_OWNER`), nº do pedido, `Order.ExternalNumber__c`, `ORDER_TOTAL_AMOUNT`, `Order.ExpectedSaleDate__c`, `Order.DeliveryDate__c`, `Order.Volume1__c`, `Order.Total_com_Desconto__c`. Filtros: `ExpectedSaleDate__c` de 01/09/2026 a 30/09/2026 (datas fixas, não relativas); `ORDER_STATUS` em Liberacao Financeiro, Liberacao Estoque, Faturamento; `Account.Sector__c` em lista de 9 setores mais vazio; `Order.TypeOperation__c` diferente de 04,05,07,11,13,27,31,45. Agrupamento: só por `ORDER_STATUS`. Não agrupa por dono, estado nem mês. | `sf data query` em `Report`; retrieve do `.report-meta.xml` |
| Relatório `Previsão de Pedidos HOJE` (`Previso_de_Pedidos_Q4W`, mesma pasta) | Sim | Também `OrderList`. Filtro `ExpectedSaleDate__c = TODAY`; status inclui também `Concluido`; mesmos filtros de setor e tipo de operação; usa `Total_com_Desconto__c` como coluna de valor. Agrupa só por `ORDER_STATUS`. | idem |
| Relatório `Previsão de Imputados Período - ANA` (pasta pessoal `ANA PEREIRA`) | Sim (cópia pessoal) | Não retrieved. Só a existência é confirmada. | `sf data query` em `Report` |
| Relatório `Previsão de Amostras - HOJE` | Sim | Não retrieved. Só a existência é confirmada. | idem |
| Relatórios de carteira e vendedor | Sim, só nome e pasta confirmados: `ANÁLISE MENSAL DA CARTEIRA`, `Número Total da Carteira` por região (CO, MG, NO/NE, RJ/ES, SP, SUL; pasta `ANALISTAS`), `Faturamento por Vendedor AF/M`, `Oportunidades ganhas por Vendedor AF/T`, `RITMO DE VENDAS` e outros. Conteúdo interno não lido. | `sf data query` em `Report` (`LIMIT 15`, pode haver mais) |
| Volume de relatórios e dashboards | 380 relatórios, 20 dashboards, 44 pastas de relatório. A análise citava 374 e 19; a diferença é de coleta. | `SELECT COUNT()` em `Report`, `Dashboard`, `Folder` |
| Dashboard de previsão ou forecast | Não achei. A busca por título com Previs, Forecast e Vend retornou 0 linhas. | `sf data query` em `Dashboard` |
| Forecasting nativo | Ligado, 10 tipos cadastrados, só `Opportunity Amount` ativo. 0 `ForecastingQuota`. 2 `UserRole`; 20 usuários ativos sem papel. | `ForecastingType`, `ForecastingQuota`, `UserRole`, `User` (só `COUNT()`) |
| Agente `SFAgent2` | Sim. Bot `SFAgent2` com 4 versões de planner (`SFAgent2_v1` a `v4`). Versão `v4` retrieved: 4 tópicos locais (`agent_router`, `ambiguous_question`, `insights_comerciais` "Insights Comerciais e Acompanhamento", `off_topic`). As 3 ações são `standardInvocableAction`, todas dentro do tópico `insights_comerciais`: `AgregacaoPedidos` (agregação count/sum/avg), `ConsultarPedidos` (consulta SOQL) e `IdentificarConta` (busca por nome). Não sei qual versão está ativa. | `BotDefinition`, `GenAiPlannerDefinition`, retrieve de `GenAiPlannerBundle:SFAgent2_v4` |
| Permission set de previsão ou forecast | Não existe (0 com Label `%Previs%` ou `%Forecast%`) | `sf data query` em `PermissionSet` |
| Campo de meta, cota ou realizado | Não reconfirmado nesta rodada. `ForecastingQuota` = 0. | contagem |

## 2. O que será tocado (campos confirmados)

| Objeto.Campo | Tipo | Descrição no metadata | Observação |
|---|---|---|---|
| `Order.ExpectedSaleDate__c` | Data | vazia | Campo-chave dos relatórios existentes. Significado não documentado. |
| `Order.TotalAmount` | Moeda(16,2) | vazia | Padrão |
| `Order.Total_com_Desconto__c` | Fórmula (Moeda) | não consultada | É o valor que o relatório `HOJE` usa. Não li a fórmula. |
| `Order.Salesperson1__c` | Texto(255) | vazia | Texto livre |
| `Order.OwnerId` | Pesquisa(Usuário,Grupo) | vazia | Padrão |
| `Order.AccountId` | Pesquisa(Conta) | vazia | Padrão |
| `Order.Status`, `Order.EffectiveDate`, `Order.DeliveryDate__c` | Lista de opções, Data, Data | não consultada | Usados pelos relatórios existentes |
| `Order.TypeOperation__c` | Pesquisa(Tipo de Operação) | não consultada | Filtro dos relatórios existentes (exclui 8 códigos) |
| `Account.Sector__c` | Lista de opções | vazia | Filtro dos relatórios existentes. A análise não o citava. |
| `Account.Subsector__c` | Lista de opções (múltipla) | vazia | Existe |
| `Account.BillingAddress` | Endereço padrão | n/a | Não consultei se `BillingState` é populado em registros (a dev está sem registros) |
| Campo custom de região, UF ou carteira em Account | Não achei. A busca por `%Region%`, `%Regi%`, `%Carteira%`, `%UF%` e `%State%` só retornou `StateRegistration__c` (inscrição estadual) e `CityRegistration__c`. | n/a | `FieldDefinition` |
| Territory2 | Existe o objeto, 0 registros | n/a | contagem |

## 3. Automação concorrente

Só relevante se a solução gravar em algo. Mapa do que existe hoje (ordem de execução do Salesforce: before-save Flow, triggers before, validation rules, triggers after, Flows after-save).

| Objeto | Triggers Apex (todos ativos) | Flows ativos | Validation rules |
|---|---|---|---|
| Account | `AccountBefore` (`SBQQ`; before insert/update); `AccountTrigger` (custom; before e after, insert e update) | `AccountTriggered` (RecordAfterSave); `AccountUpdateEconomicGroup` (Scheduled); `UpdateParentAccountUsedLimit` (RecordAfterSave, o `TriggerObject` não foi conferido por mim) | 6 (6 ativas) |
| Opportunity | `OpportunityBefore` (`SBQQ`; before); `OpportunityAfter` (`SBQQ`; after); `OpportunityTrigger` (custom; after insert/update) | `OpportunityFlow`, `Oportunidade_Industria` (RecordAfterSave); `ScheduledFlowOpportunity` (Scheduled) | 16 (16 ativas) |
| Order | `OrderTrigger` (`SBQQ`; before e after, insert e update); `OrderTrigger` (custom, sem namespace; before update e after update) | `Order` (RecordAfterSave); `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` (RecordBeforeSave); `OrderScheduledFlow` (Scheduled) | 23 no total, 17 ativas |

Provas: `ApexTrigger` via Tooling API por `TableEnumOrId`; `FlowDefinitionView` (filtro por rótulo do objeto de disparo; a lista pode não incluir Flows com objeto de rótulo diferente); `ValidationRule` via Tooling API. Não li o corpo de nenhum trigger, Flow ou regra, então não afirmo o que fazem nem a ordem relativa entre os dois `OrderTrigger`.

Confirmado dos pontos do assessment:
- Trigger custom e trigger CPQ no mesmo objeto: confirmado em Account, Opportunity e Order.
- `OrderTrigger` com mesmo nome do pacote CPQ: confirmado (um com namespace `SBQQ`, outro sem).
- 23 validation rules de Order: confirmado como total; 17 ativas.
- Classes Apex sem namespace: 56. A cobertura de 10% não foi reconfirmada por mim.
- Perfis comerciais duplicados: não reconfirmado.

## 4. Marketing Cloud Connect (`et4ae5`)

A demanda não toca marketing. Confirmado só o que está instalado, para o caso de o arquiteto precisar.

| Item | Resultado | Prova |
|---|---|---|
| Classes Apex `et4ae5` | 523 | `ApexClass` (Tooling) |
| Triggers `et4ae5` | 14 | `ApexTrigger` (Tooling) |
| Objetos custom | `et4ae5__Configuration__c`, `__ET4AEConfig__c`, `__ET4AE_Config__c`, `__Email_Linkage__c`, `__IndividualEmailResult__c`, `__IndividualLink__c`, `__MC_CDC_Journey__c`, `__SMSDefinition__c`, `__SMSJunction__c`, `__SendDefinition__c` (lista cortada em 40 linhas, pode haver mais) | `EntityDefinition` |
| Campos `et4ae5` em Lead e Contact | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` (opt-out de SMS) | `FieldDefinition` |
| Campos `et4ae5` em Account, Opportunity, Order | Nenhum. Existe `et4ae5__Activity__c` numa das entidades consultadas (Account, Opportunity, Order, Campaign, CampaignMember); não identifiquei em qual. | `FieldDefinition` |

Conclusão factual: o `et4ae5` não usa Order nem os campos de previsão.

## 5. Volume e dados de teste (contagens, só `COUNT()`)

| Objeto | Registros |
|---|---|
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| Task | 0 |
| Territory2 | 0 |
| ForecastingQuota | 0 |

A sandbox não tem dado para testar. Qualquer teste precisa de dado sintético criado na etapa de build.

## 6. Permissões

| Item | Resultado | Prova |
|---|---|---|
| OWD interno, Account | `ReadWrite`; externo `Private` | `EntityDefinition` (`InternalSharingModel`, `ExternalSharingModel`) |
| OWD interno, Order | `ReadWrite`; externo `Private` | idem |
| OWD interno, Opportunity | `Read`; externo `Private` | idem |
| Permission set de previsão | Nenhum | `PermissionSet` |
| Perfis e permission sets que alcançam Order, Account e relatórios | Não levantado | n/a |
| Papéis | 2 `UserRole`; 20 usuários ativos sem papel | `COUNT()` |
| Acesso às pastas de relatório existentes | Não levantado | n/a |

## 7. O que não consegui confirmar

1. Se `sbx-eplast-dev` é a dev ou a QA. O alias, o username e a URL divergem, e `sf` não diz qual sandbox é.
2. O que `Order.ExpectedSaleDate__c` significa. Não tem descrição, e a leitura "data prevista de venda" vem só do nome e do uso nos relatórios.
3. Conteúdo, filtros e agrupamentos dos relatórios `Previsão de Amostras - HOJE`, `Previsão de Imputados Período - ANA` e dos de carteira e vendedor. Dos dois retrieved: nenhum agrupa por dono, região ou mês.
4. Se os relatórios existentes atendem sem alteração. Seus filtros de setor, tipo de operação e status são regras de negócio que não confirmei com o cliente.
5. A fórmula de `Order.Total_com_Desconto__c` e se difere de `TotalAmount`.
6. O corpo e a ordem de execução dos dois `OrderTrigger`, dos triggers de Account e Opportunity, dos Flows e das validation rules. Só nomes, eventos e contagens.
7. Em quais objetos os Flows `UpdateParentAccountUsedLimit` e `AccountTriggered` disparam, além do que o filtro por rótulo indica. Flows com objeto de rótulo diferente podem ter ficado de fora.
8. Em que entidade existe `et4ae5__Activity__c`, e se há mais objetos `et4ae5` além dos 40 listados.
9. Qual versão do planner do `SFAgent2` está ativa, e se a versão da QA é igual à da dev. Não comparei QA x DEV.
10. Perfis e permission sets que dão acesso a Order, Account e às pastas de relatório, e a duplicidade de perfis comerciais.
11. A cobertura de teste Apex (10%), que veio do assessment e não foi medida de novo.
12. Se `Account.BillingState` está preenchido nas contas reais. A dev está vazia.
13. A existência de campo de meta fora de Account, Opportunity, Order e User, e de objeto custom de meta. Não repeti essa busca.

## 8. Complemento do arquiteto (2026-11-15, etapa de design)

Pontos confirmados por `sf` porque mudavam a decisão. Só metadata e contagens; retrieve em pasta temporária, já removida.

| Item | Resultado | Prova |
|---|---|---|
| Como a org define "região" | Os relatórios `Número Total da Carteira <região>` (pasta `ANALISTAS`, tipo `AccountList`) filtram `ADDRESS1_STATE` (estado de cobrança da conta): CO = GO,DF,MT,MS,TO; MG = MG; NO/NE = AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE; RJ/ES = RJ,ES; SP = SP; SUL = PR,SC,RS (27 UFs, sem sobreposição). `Total da Carteira DIRETA` filtra por um proprietário específico (nome omitido), não por UF. `Número Total das Carteiras` agrupa por proprietário da conta (`USERS.NAME`). | Analytics API `/analytics/reports/<id>/describe`, só `reportFilters` e `groupingsDown` |
| Tipo `OrderList` | Expõe `ACCOUNT_OWNER`, `ORDER_TOTAL_AMOUNT`, `Order.ExpectedSaleDate__c` (rótulo "Data previsão de vendas"), `Order.Total_com_Desconto__c` (rótulo "Total com Indenização"), `Account.Sector__c` e o estado de cobrança **do pedido** (`ORDER_BILLING_STATE`). **Não expõe o estado de cobrança da conta.** | `/analytics/reportTypes/OrderList` |
| Tipo de relatório custom `Pedidos_customizados` | Existe (também em `force-app/` do baseline). Objeto base `Order`, sem objeto relacionado, 119 colunas, todas da tabela `Order` (inclui `ExpectedSaleDate__c`, `TotalAmount`, `Total_com_Desconto__c`, `Status`, `TypeOperation__c`, lookup `Account`). Nenhum campo da conta via lookup. Uso por relatórios: não consegui medir (`Report.ReportTypeApiName` não agrupou). | retrieve `ReportType:Pedidos_customizados` |
| Sintaxe de campo via lookup em tipo custom | Exemplo na org: `<field>Opportunity.Account.Owner</field>` (tipo `Gestao`) | retrieve `ReportType:Gestao` |
| `Account.BillingState` | Tipo `string`; não há `BillingStateCode` (picklist de estado/país desligado) | `sf sobject describe Account` filtrado |
| `Order.Total_com_Desconto__c` | Fórmula Moeda: `TotalAmount - Discount__c`; sem descrição | Tooling `CustomField.Metadata` |
| `Order.Status` (valores ativos) | Revisao de Pedido, Liberacao Financeiro, Liberacao Estoque, Faturamento, Cancelado, Concluido. Não há valor "Rascunho/Draft" | describe filtrado |
| Acesso amplo a relatórios | 14 usuários ativos distintos têm "Ver todos os dados" ou "Gerenciar relatórios em pastas públicas" (de 19 usuários ativos padrão). Eles enxergam qualquer pasta pública independentemente do compartilhamento. | `COUNT_DISTINCT(AssigneeId)` em `PermissionSetAssignment`; `COUNT()` em `User` |
| Grupo ou pasta de previsão/gestão comercial | Nenhum grupo público com Previs, Gest ou Comercial no nome; nenhuma pasta de relatório ou painel com esses nomes. No baseline só há o grupo `DEV`. | `Group`, `Folder` |
| Painéis dinâmicos | 4 `LoggedInUser` e 16 `SpecifiedUser`. Org é Enterprise Edition. | `Dashboard` agrupado por `Type`; `Organization.OrganizationType` |
| Automação em `OrderItem` | Trigger `OrderProductTrigger` (`SBQQ`; before/after insert/update), 4 validation rules ativas, nenhum Flow ativo achado pelo rótulo "Produto do pedido". | Tooling `ApexTrigger`, `ValidationRule`; `FlowDefinitionView` |
| Evento dos Flows de Order | `Order` e `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p`: ambos `CreateAndUpdate` | `FlowDefinitionView.RecordTriggerType` |
| Pré-requisitos de dado sintético | `Product2`: 1042; `Pricebook2` padrão: 1; `TypeOperation__c`: 0 registros | `COUNT()` |
