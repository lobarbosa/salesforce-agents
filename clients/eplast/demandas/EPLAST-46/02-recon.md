# EPLAST-46 — Recon da org

**Org conectada:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected, Org Id `00DHa000006vfMLMAY`). É a sandbox "qa" da Eplast, que é o dev da esteira (regra 5 do CLAUDE.md do cliente; não é bloqueio).
**Só leitura:** metadata e `COUNT()`. Nenhum registro de cliente lido, nenhum DML. Nada consultado no Marketing Cloud.
**Entradas lidas:** `01-analise.md`, `00-preflight.md` (sem bloqueios, sem outras demandas em conflito), `comentarios-do-card.md`.

## 1. O que já cobre o pedido (reaproveita) e o que não existe

| Item | Estado confirmado | Comando |
|---|---|---|
| Agente `SFAgent2` | 1 `BotDefinition`. 8 `BotVersion`: v1 a v7 Inactive, **v8 Active**. 8 `GenAiPlannerDefinition` (`SFAgent2_v1`..`_v8`) | `SELECT ... FROM BotDefinition`, `BotVersion`, `GenAiPlannerDefinition` |
| Ação de recomendação `ProximaAcaoCliente_EPLAST27` (+ `_v5`..`_v8`) | `GenAiFunctionDefinition`, alvo tipo `flow`. Descrição: "proxima melhor acao para uma conta pela regra fixa (risco, oportunidade parada, cliente inativo)" | `SELECT ... InvocationTargetType FROM GenAiFunctionDefinition WHERE DeveloperName LIKE 'ProximaAcao%'` |
| Flow `Account_Agente_ProximaAcao` | AutoLaunchedFlow, **v2 Active** (v1 Obsolete). Sem gatilho e sem DML. Entrada `recordId`; saídas `actionCode`, `message`. Códigos: NODATA, A1 (risco), A2 (oportunidade parada), A3 (cliente inativo, `Account.Inactive__c`), NONE. Lê `Account`, `Opportunity` e `NextBestActionSetting__mdt` | Tooling: `SELECT Metadata FROM Flow WHERE Id='301Ha000016Tf9hIAC'` |
| `NextBestActionSetting__mdt` | 1 registro; campos `RestrictToOwner__c`, `RiskValues__c`, `StaleOpportunityDays__c`. **Não há campo para limite de reativação nem catálogo de campanha** | `FieldDefinition` + `COUNT()` |
| Outros CMDTs na org | `TriggerUtility__mdt`, `RankingRange__mdt`, `ScheduledFlowOpportunitySetting__mdt`, `AlertaOportunidadeParadaSetting__mdt`, `NextBestActionSetting__mdt`, `CommercialSignalSetting__mdt` (lista cortada em 7, 6 vistas) | `EntityDefinition WHERE QualifiedApiName LIKE '%__mdt'` |
| Ações `ConsultarPedidos_*`, `AgregacaoPedidos_*`, `IdentificarConta_*` | Existem, várias versões (`_v5`..`_v8`) | `GenAiFunctionDefinition` |
| Outras ações do agente | `CriarTarefa_EPLAST29`, `IdentificarRegistro_EPLAST29`, `ResumoReuniao_EPLAST34_v5/_v8` | idem |
| Tópicos (`GenAiPluginDefinition`) | `insights_comerciais_*` ("Insights Comerciais e Acompanhamento", até `_v8`), "Insights Comerciais sobre Pedidos", `agent_router`, `ambiguous_question`, `GeneralFAQ`, `off_topic`. Lista cortada em 37, 30 vistas | `GenAiPluginDefinition LIMIT 40` |
| Campos de Account | `Inactive__c` (fórmula checkbox), `LastPurchase__c` (resumo MAX de Oportunidade), `LastMonthPurchaseValue__c` (moeda), `Sector__c` (picklist), `Subsector__c` (multipicklist) | `FieldDefinition` |
| Campos de Contact | `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `LeadSource` | `FieldDefinition` |
| Campos de Lead | `PriorityScore__c` (fórmula número), `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `Status`, `LeadSource`, `Sector__c`, `Subsector__c` | `FieldDefinition` |
| Campo de sugestão, campanha, necessidade ou interesse em `Account` | **Não existe** (busca por `%Suggest%`, `%Campan%`, `%Necess%`, `%Interest%` retornou 0) | `FieldDefinition WHERE ... LIKE` |
| Relatórios, pasta `MARKETING CLOUD` | Existem, entre outros: `SEM COMPRA - 91 A 180 DIAS`, `SEM COMPRA - 181 A 365 DIAS`, `SEM COMPRA - MAIS DE 365 DIAS`, `POTENCIAIS - SEM COMPRA`, `PRODUTO - CONTAS POR PRODUTO COMPRADO` (Summary), `CLASSIFICAÇÃO - CONTAS POR CLASSE`, `SEGMENTO - *` (vários), `LEADS - SEGMENTO - *`, `LEADS - PROSPECÇÃO PRIORIZADA`, `MSG - CONTATOS - CELULAR APTOS`, `MSG - LEADS - CELULAR APTOS`. Total de relatórios na org: **414** (a análise dizia 409). Lista cortada em 30; filtros dos relatórios não foram lidos | `SELECT Name, FolderName, Format FROM Report WHERE FolderName LIKE '%MARKETING%' LIMIT 30` |
| Permission sets customizados | `PS_Marketing_AnaliseCampanhas`, `PS_Marketing_Publicos`, `PS_Comercial_ProximaAcao`, `PS_Comercial_AssistenteAcoes`, `PS_Comercial_SinaisComerciais`, `PS_Comercial_ScorePrioridade` (e outros `PS_*`) | `PermissionSet WHERE IsCustom=true AND Name LIKE 'PS_%'` |

**Sobreposição a decidir pelo arquiteto:** o caso A3 (cliente inativo) da ação `ProximaAcaoCliente_EPLAST27` já devolve recomendação de reativação por `Inactive__c`. A regra "reativação" desta demanda coincide com ele. Os relatórios `SEM COMPRA - *` já cobrem o público de reativação por faixa.

**Não existe (a criar, se o design decidir):** catálogo de campanhas, limites de 90/180 dias em CMDT (o CMDT existente não tem esses campos), lógica de ampliação de mix por setor e família, filtro de opt-out por canal na ação, versão nova do planner/ação.

## 2. O que será tocado

| Objeto | Campos relevantes (confirmados) | Observação |
|---|---|---|
| Account | `Inactive__c`, `LastPurchase__c`, `LastMonthPurchaseValue__c`, `Sector__c`, `Subsector__c` | Só leitura na v1 (PA-03) |
| Contact | `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | Filtro de opt-out |
| Lead | `PriorityScore__c`, opt-outs, `Status`, `Sector__c` | Nutrição opcional |
| Order / OrderItem / Product2 | Não consultei campos de `Family`, `Group__c`, `Status` nesta sessão | **Não confirmado**; ver seção 7 |
| Opportunity | `LastPurchase__c` é MAX de Oportunidade | Não confirmei qual campo/estágio entra no resumo |
| `et4ae5` (conector) | Ver seção 6 | |

Descrição dos campos (campo `Description`): não consultada.

## 3. Automação concorrente

Só importa se o design gravar em `Account`/`Order` (na v1 é leitura, PA-03).

| Objeto | Componente | Estado | Comando |
|---|---|---|---|
| Account | Triggers `AccountTrigger` (custom), `AccountBefore` (SBQQ) | Active | `SELECT Name, NamespacePrefix, TableEnumOrId FROM ApexTrigger` |
| Account | Flows autolançados ativos com nome `Account_%`: `Account_Agente_ProximaAcao`, `AccountUpdateEconomicGroup`, `AccountTriggered` | Active | Tooling `Flow WHERE Definition.DeveloperName LIKE 'Account_%'` (filtro por nome, não por objeto) |
| Opportunity | `OpportunityTrigger` (custom), `OpportunityBefore`, `OpportunityAfter` | Active | `ApexTrigger` |
| Order | `OrderTrigger` custom **e** `OrderTrigger` SBQQ, ambos ativos (colisão de nome confirmada) | Active | `ApexTrigger` com e sem `NamespacePrefix` |
| OrderItem | `OrderProductTrigger` | Active | `ApexTrigger` |
| Order | Flow `OrderScheduledFlow` | Active | Tooling `Flow` por nome |
| Order | 33 validation rules (Account, Contact, Lead e Order somadas); Order tem ao menos `CheckUserCanSetStatus`, `ChangeOrderToCanceled`, `MotivoPerda` e 10+ `CheckOrderHas*` | Active | Tooling `ValidationRule` (saída cortada) |
| Contact, Lead | Validation rules ativas vistas: `Telefone`, `WhatsApp` (Contact), `Celular`, `Telefone` (Lead) | Active | idem (saída cortada) |

Observações: a fixture precisa do desvio `TriggerUtility.bypassTrigger` por causa da `AccountTrigger` (CNPJ/BrasilAPI), conforme `fixtures/README.md`; não validei isso na org. Ordem de execução detalhada não foi levantada (a v1 não grava).

## 4. Volume e dados de teste

| Objeto | Contagem | Comando |
|---|---|---|
| Account, Contact, Lead, Opportunity, Order, OrderItem | **0** | `SELECT COUNT() FROM <obj>` |
| Campaign, CampaignMember | **0** | idem |
| Product2 | 1042 | idem |
| NextBestActionSetting__mdt | 1 | idem |
| ApexClass sem namespace | 69 | `COUNT() FROM ApexClass WHERE NamespacePrefix=null` |

A dev não tem dado de negócio: o teste exige fixture. `fixtures/` só tem `README.md` (nenhum script gravado ainda).
Usuário de teste (regra 6): a consulta pelo username da conta de serviço da regra 6 retornou **dois** usuários, ambos com perfil Administrador do sistema: `005bJ00000piKAaQAM` (ativo) e `005bJ00000hBJmYQAW` (**inativo**). Usar o ativo. Como é administrador, serve como proprietário de registro, **não** como caso de acesso negado (CA-09 da análise): para isso é preciso outro usuário sem permission set.

## 5. Permissões

| Item | Estado | Comando |
|---|---|---|
| Permission sets `PS_Marketing_AnaliseCampanhas`, `PS_Marketing_Publicos`, `PS_Comercial_ProximaAcao` | Existem | `PermissionSet` |
| Objetos, campos e ações cobertos por cada um | **Não confirmei** (`ObjectPermissions` e `SetupEntityAccess` não são consultáveis por `sf data query` nesta org/API) | tentativa falhou |
| Perfis e OWD | Não levantados | |

## 6. Marketing Cloud Connect (`et4ae5`)

| Item | Estado | Comando |
|---|---|---|
| Objetos do pacote | Instalados: `et4ae5__Configuration__c`, `et4ae5__ET4AEConfig__c`, `et4ae5__ET4AE_Config__c`, `et4ae5__Email_Linkage__c`, `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `et4ae5__MC_CDC_Journey__c`, `et4ae5__SMSDefinition__c`, `et4ae5__SMSJunction__c`, `et4ae5__SendDefinition__c` (e `Campaign_Member_Configuration__ChangeEvent`). Lista cortada em 40 | `EntityDefinition WHERE NamespacePrefix='et4ae5' LIMIT 40` |
| Campos em Contact e Lead | `et4ae5__HasOptedOutOfMobile__c` em ambos; em Lead também `et4ae5__Mobile_Country_Code__c` | `FieldDefinition` |
| Campos `et4ae5` em Account, Opportunity, Product2, Order | Nenhum (a consulta cobriu Account, Opportunity, Lead, Product2, Order; só Lead retornou) | `FieldDefinition LIKE 'et4ae5%'` |
| `CampaignMember.et4ae5__Activity__c` | Não verifiquei | |
| Configuração da conexão, jornadas, uso real | Não verifiquei, e não será feito (regra 2) | |

## O que não consegui confirmar

- Campos de `Order`, `OrderItem` e `Product2` (`Status`, `Family`, `Group__c`) que a regra de mix e de "compra" usariam; também quais Order Status contam como compra.
- Qual objeto, estágio e filtro alimentam o resumo `Account.LastPurchase__c` (a análise o chama de MAX de Oportunidade; o histórico fala de pedido).
- Conteúdo das 33 validation rules (lista cortada) e das regras de `Account` e `Lead`; se há regra de Account ativa.
- Quais Flows ativos tocam Account/Order por gatilho: o filtro foi por nome, não por objeto. `AccountTriggered` e `AccountUpdateEconomicGroup` não foram abertos.
- Ordem de execução de Account/Opportunity/Order (não levantada; só relevante se houver gravação).
- Quais tópicos do planner v8 usam `ProximaAcaoCliente_EPLAST27` e quais versões de ação estão ligadas à v8 ativa.
- Filtros dos relatórios da pasta `MARKETING CLOUD`; se os de `SEM COMPRA` usam `Inactive__c` ou `LastPurchase__c`.
- Conteúdo de `PS_Marketing_*` e `PS_Comercial_ProximaAcao` (objetos, campos, acesso à ação); perfis e OWD.
- Usuário sem permissão para o caso de acesso negado: nenhum identificado.
- Existência de `CampaignMember.et4ae5__Activity__c` e demais objetos/campos do conector além da lista cortada.
- Divergências com a análise: bot tem 8 versões (v8 ativa; a análise dizia v1..v6) e a org tem 414 relatórios (a análise dizia 409).
- A tentativa de retrieve do Flow para disco falhou (workspace sem projeto DX no diretório temporário); a leitura do Flow veio pela Tooling API.

## Complemento do arquiteto (2026-11-15, `sbx-eplast-dev`, só metadata e contagens)

- `CommercialSignal__c` (EPLAST-33) existe: `Type__c` = `Recuperacao`, `NuncaComprou`, `QuedaVolume`, `AltaVolume`, `Cruzada`; `COUNT()` = 0. `CommercialSignalSetting__mdt` `Default`: grupo `Industry`, exclusão 180 dias, status `Faturamento;Concluido`. Classes `CommercialSignal*` e relatório `CommercialSignals_ByAccount` existem. `CronTrigger` `%Signal%` = 0.
- `Account.LastPurchase__c` = MAX `Opportunity.CloseDate` com `StageName = Fechado/Ganho` (`CustomField.Metadata`).
- `Product2.Family` preenchido em 118 de 1042; `Product2.Group__c` em 910 (5 códigos).
- `FlowDefinition` `Account_Agente_ProximaAcao`: ativa 2, última 2.
