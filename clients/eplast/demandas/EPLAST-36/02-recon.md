# EPLAST-36 — Recon da org (segmentação da base e públicos)

**Org:** alias `sbx-eplast-dev` (`sf org list`: Sandbox, Connected). **Data:** 2026-11-15. Só leitura; só metadata e contagens agregadas.
**Aviso (assessment achado 6):** o assessment registra que esta sandbox se identifica como `qa` (usuário e instância). Não reconfirmei dev x qa fisicamente; ver "O que não consegui confirmar".
**Nota sobre a análise:** `01-analise.md` trata escopo contratual e "onda não contratada" como bloqueio. Pela regra 1 do CLAUDE.md do cliente isso não bloqueia; o recon não trata como pendência.

## 1. O que já cobre o pedido (reaproveitar antes de criar)

| Item | O que é | Confirmado | Cobre | Comando |
|---|---|---|---|---|
| Agente `SFAgent2` (Bot, 4 versões `SFAgent2_v1` a `_v4`) | Agentforce, criado 2026-11-10 | sim | Consulta/agregação de Pedidos e identificação de Conta; base para qualquer pedido em linguagem natural | `sf org list metadata --metadata-type Bot` / `GenAiPlannerBundle` |
| Tópicos (GenAiPluginDefinition) | `Insights Comerciais sobre Pedidos` (versões antigas: `Insights Comerciais e Acompanhamento`), `Agent Router`, `Ambiguous Question`, `Off Topic`, `General FAQ` (listagem mistura versões) | sim | Segmentação por histórico de compra via agregação de Pedidos | Tooling `GenAiPluginDefinition` |
| Ações (GenAiFunctionDefinition) | `ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta` (+ `QueryRecords` em versões antigas) | sim | Consulta/agregação só sobre Order/Account; não tocam Lead, Contact nem Campaign | Tooling `GenAiFunctionDefinition` |
| Relatórios de região/carteira (pasta ANALISTAS) | `REGIÃO COM PRODUTOS - CONTAS`, `REGIÃO COM PRODUTOS - PRODUTO`, `Número Total da Carteira` por CO/MG/NO-NE/RJ-ES/SP/SUL/DIRETA, `ANÁLISE MENSAL DA CARTEIRA` | sim (nome, pasta, formato) | Já há segmentação por região e produto como relatório. Colunas e filtros NÃO lidos | `SELECT Name, FolderName, Format FROM Report WHERE Name LIKE ...` |
| Relatórios de campanha (pasta Origem e Retorno de Campanhas) | `MKT Desempenho de Campanhas`, `MKT Resposta de Membros de Campanha` | sim | Origem/retorno de campanha (EPLAST-39) | idem |
| Painéis | `Marketing - Origem e Retorno de Campanhas`, `Leads & Oportunidades` e `Pedidos` (pasta Eplast), `Marketing Dashboard` | sim | Visão agregada, não público | `SELECT Title, FolderName FROM Dashboard` |
| Conector Marketing Cloud Connect (`et4ae5`) | ver seção 5 | sim | Canal de disparo/sincronização de públicos | EntityDefinition |
| List views de Account/Contact/Lead/Campaign | 16 no total (nomes não listados) | sim (contagem) | Público simples por filtro | `SELECT COUNT() FROM ListView WHERE SobjectType IN (...)` |
| Total na org | 380 Reports, 20 Dashboards | sim | — | `SELECT COUNT() FROM Report/Dashboard` |

Reaproveitável: SFAgent2 (estender tópico/ação, não criar agente), relatórios de região/produto e campanha, e o conector `et4ae5`. Não encontrei relatório ou lista chamado "público" ou "segmento".

## 2. O que será tocado: campos candidatos (confirmados por `sf sobject describe`)

| Objeto.Campo | Tipo | Observação |
|---|---|---|
| Account.`Type` ("Categoria") | picklist, 9 valores: Inativo, Novo, Prospect, Prospect Indústria, Reativo, Recorrente, Sazonal, Stand-by, Encerrou atividades | Já é um estágio de relacionamento; evidência para "comportamento" |
| Account.`Sector__c` ("Setor") | picklist, 9 valores: Alimentos, Bebidas, Distribuidor & Varejo, Farmacêutico, Higiene & Limpeza, Indústria de Sopro, Indústria de Transformação, Industrial, PET (Bem-estar animal) | Candidato a "segmento" |
| Account.`Industry` | picklist, 32 valores | Padrão; relação com `Sector__c` não confirmada |
| Account.`Subsector__c` | multipicklist | Candidato a refinamento de segmento |
| Account.`Ranking__c` | picklist: MP, PP, P, M, G, GG, 3G | Porte; significado NÃO confirmado |
| Account.`Risk__c` | picklist A a E | Risco de crédito (rótulo "Risco") |
| Account.`BillingState` / `BillingCity` | padrão | Única base de "região" por UF/cidade confirmada. NÃO achei campo "Região" em Account |
| Account.`Products__c` | textarea | Texto livre; ruim para filtro |
| Account.`LastPurchase__c` | date | Candidato a "última compra" |
| Account.`TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c` | currency | Métricas agregadas de compra já existem (quem as calcula: não confirmado) |
| Account.`Inactive__c`, `Overdue__c` | boolean | Estados de relacionamento |
| Account.`ProtheusId__c` | string | Chave com o ERP |
| Lead.`LeadSource`, `Status`, `State`, `Sector__c`, `Subsector__c`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | vários | Origem, status e opt-out já existem |
| Contact.`LeadSource`, `HasOptedOutOfEmail`, `MailingState`, `et4ae5__HasOptedOutOfMobile__c` | vários | idem |
| Campaign.`Type`, `Status`; CampaignMember.`Status`, `HasResponded`, `et4ae5__Activity__c` | padrão e `et4ae5` | Mecanismo de público já nativo (membro de campanha) |

Descrição (`Description`) dos campos: não lida por campo. O assessment diz que 78 de 90 campos custom de Account não têm descrição (achado 4). Não infiro significado por nome.

## 3. Automação concorrente (mapa por objeto e evento)

Triggers (Tooling `ApexTrigger`, só Status Active):

| Objeto | Trigger | Namespace | Eventos |
|---|---|---|---|
| Account | `AccountBefore` | SBQQ | BI, BU |
| Account | `AccountTrigger` | custom | BI, AI, BU, AU |
| Opportunity | `OpportunityBefore` | SBQQ | BI, BU, BD |
| Opportunity | `OpportunityAfter` | SBQQ | AI, AU |
| Opportunity | `OpportunityTrigger` | custom | AI, AU |
| Order | `OrderTrigger` | SBQQ | BI, AI, BU, AU, BD, AD |
| Order | `OrderTrigger` (mesmo nome) | custom | BU, AU |
| OrderItem | `OrderProductTrigger` | SBQQ | BI, AI, BU, AU, BD, AD |
| Lead, Contact, Campaign, CampaignMember | nenhum trigger | — | — |

Flows ativos sem namespace (`FlowDefinitionView`, 25 no total; só os relevantes):

| Objeto | Flow | Tipo |
|---|---|---|
| Account | `AccountTriggered` | RecordAfterSave |
| Account | `UpdateParentAccountUsedLimit` | RecordAfterSave (o nome consta no assessment; na listagem desta sessão o limite de 50 devolveu 25 e ele não apareceu; ver incertezas) |
| Account | `AccountUpdateEconomicGroup` | Scheduled |
| Opportunity | `Oportunidade_Industria`, `OpportunityFlow` | RecordAfterSave |
| Opportunity | `ScheduledFlowOpportunity` | Scheduled |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p...` | RecordBeforeSave |
| Order | `Order` ("Pedido") | RecordAfterSave |
| Order | `OrderScheduledFlow` | Scheduled |
| Lead/Contact/Campaign/CampaignMember | nenhum Flow custom | — |

Ordem de execução (padrão da plataforma, não testada na org): before-save Flow, depois triggers before (SBQQ e custom, ordem entre triggers do mesmo evento NÃO garantida), validation rules, triggers after, Flows after-save. Para Order em update, SBQQ `OrderTrigger` e o custom `OrderTrigger` disputam BU/AU; o nome duplicado atrapalha leitura de log (achado 10). Para Lead, Contact, Campaign e CampaignMember não há automação custom concorrente: gravar nesses objetos é a rota de menor risco. Gravar em Account/Order cai no achado 1.
Validation rules: Order tem 23 (assessment; não recontadas). Não levantei VRs de Account, Lead e Campaign.

## 4. Volume e dados de teste

| Objeto | COUNT() | Comando |
|---|---|---|
| Account, Contact, Lead, Campaign, CampaignMember, Order, OrderItem, Opportunity | 0 em todos | `sf data query -q "SELECT COUNT() FROM <obj>"` |

A sandbox não tem massa. Qualquer validação de público exige massa sintética criada no build, sem dado real (guardrail #2).

## 5. Marketing Cloud Connect (`et4ae5`) já instalado

Confirmado por `EntityDefinition` (NamespacePrefix `et4ae5`, 28 objetos customizáveis). Relevantes:

| Componente | Uso provável (pelo nome; função real NÃO confirmada) |
|---|---|
| `et4ae5__Campaign_Member_Configuration__c` | Configuração de membro de campanha para envio |
| `et4ae5__SendDefinition__c`, `et4ae5__SendJunction__c`, `et4ae5__SMSDefinition__c`, `et4ae5__SMSJunction__c` | Envio de e-mail e SMS |
| `et4ae5__IndividualEmailResult__c`, `et4ae5__IndividualLink__c`, `et4ae5__AggregateLink__c` | Retorno de e-mail (envio, clique) no CRM |
| `et4ae5__Automated_Send__c`, `et4ae5__Triggered_Send_Execution__c` | Envio acionado |
| `et4ae5__MC_CDC_Journey__c`, eventos `et4ae5__JB_Event__e`, `JB_CDC_Event__e`, `JB_Flow_Event__e` | Journey Builder |
| `et4ae5__Business_Unit__c`, `UEBU__c`, `ET4AE_Config__c`, `ET4AE_Int_Creds__c`, `MCOAuthClientDetail__mdt` | Conexão e credenciais (NÃO tocar, regra 2) |
| Lead/Contact `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | Opt-out e DDI móvel |
| CampaignMember `et4ae5__Activity__c` (picklist) | Atividade de e-mail |
| Permission set `Marketing_Cloud_Connected_App`, Workflow Rules (17, 100% `et4ae5` segundo o assessment) | Conexão e regras do pacote |

Não verifiquei: se a conexão está ativa, quais Business Units existem, quais campos o MCC sincroniza (não há leitura do conteúdo de configuração) e qual plataforma `eplast-ent-05` decidiu. A conexão não foi nem será tocada.

## 6. Permissões e acesso

| Item | Achado | Comando |
|---|---|---|
| OWD interno / externo | Account ReadWrite/Private; Contact ReadWrite/Private; Lead ReadWriteTransfer/Private; Opportunity Read/Private; Order ReadWrite/Private; Campaign FullAccess/Private; CampaignMember ControlledByCampaign | Tooling `EntityDefinition` |
| Perfis relacionados | `Marketing`, `Usuário do Marketing`, `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, Administrador do sistema | `SELECT Name FROM Profile` |
| `PS_Marketing_AnaliseCampanhas` | Read em Campaign e Lead (sem create/edit); nada em Account, Contact, CampaignMember, Order | `ObjectPermissions` |
| `PS_Comercial_ResumoClienteAgente` | Nenhuma permissão nos objetos consultados (Account, Contact, Lead, Campaign, CampaignMember, Order, OrderItem). Acesso do agente pode vir por outro meio, NÃO confirmado | idem |
| Outros PS custom | `Protheus`, `Marketing_Cloud_Connected_App`, `Analista_Permissao`, `Modify_All`, `Sales_User` | Tooling `PermissionSet` |

Perfil de usuário de Marketing com acesso a Account/Contact para filtrar público: NÃO confirmado.

## 7. Riscos do assessment que tocam a demanda (com o que a org mostra hoje)

| Achado | O que a org mostra hoje |
|---|---|
| 1 Automação concorrente (alta) | Confirmado em Account (SBQQ + custom + Flows), Opportunity e Order (dois `OrderTrigger`). Lead/Contact/Campaign/CampaignMember sem automação custom |
| 2 Cobertura Apex 10% | Não recontado. Cadeia Protheus (`SendAccountToProtheus`, `SendOrderToProtheus`, etc.) não tocar |
| 4 Campos sem descrição | Persiste (não recontado). Região não existe como campo próprio; segmento tem `Sector__c` e `Industry` coexistindo |
| 6 Alias dev aponta para sandbox "qa" | Exibido no `sf org list` (usuário termina em `.qa`). Não resolvido |
| Dev vazia | Confirmado: 0 registros em todos os objetos |

## 8. Lacunas de negócio e evidência da org (regra 4: premissa, não bloqueio)

| Lacuna (da análise) | O que a org oferece |
|---|---|
| "Região" | Sem campo dedicado. Há `BillingState`/`BillingCity` e relatórios de carteira por CO, MG, NO/NE, RJ/ES, SP, SUL, DIRETA, que revelam o agrupamento regional que a Eplast usa. Regra de mapeamento UF para região: não lida do relatório |
| "Segmento" | `Sector__c` (9 valores) e `Subsector__c`; `Industry` padrão |
| "Produto" | `Products__c` (texto livre) e relatório `REGIÃO COM PRODUTOS`; produto estruturado só via OrderItem/Product2 (não consultado) |
| "Comportamento / histórico de compra" | `Type` (Novo, Recorrente, Reativo, Inativo, Sazonal), `LastPurchase__c`, `TotalPurchasesThisYear__c`, `Inactive__c`; agregação de Pedidos via `SFAgent2` |
| Destino do público | CampaignMember (nativo) e `et4ae5` instalado; conexão ativa não confirmada |
| Opt-out | `HasOptedOutOfEmail` (Lead, Contact), `et4ae5__HasOptedOutOfMobile__c`; opt-out de WhatsApp não encontrado |

## O que não consegui confirmar

1. Se `sbx-eplast-dev` é fisicamente distinta da QA (usuário e instância dizem `qa`; achado 6).
2. Colunas e filtros dos relatórios `REGIÃO COM PRODUTOS` e `Número Total da Carteira`; o `sf` não devolveu o detalhe e não abri.
3. Quem calcula `LastPurchase__c`, `TotalPurchasesThisYear__c` e os demais campos de compra (a busca em corpo de classe Apex falhou na Tooling API; não li Flows nem classes). Sem isso não se sabe se são confiáveis nem se dependem do Protheus.
4. Significado de `Ranking__c`, `Risk__c`, `Type` e `Subcategoria__c`; só valores de picklist, sem descrição.
5. Se `UpdateParentAccountUsedLimit` segue ativo (consta no assessment; não apareceu na listagem de 25 desta sessão).
6. Validation rules de Account, Lead e Contact (não levantadas).
7. Status da conexão MCC, Business Units e campos sincronizados; plataforma decidida em `eplast-ent-05`.
8. Licenças e perfil do usuário de Marketing para list view, relatório e membro de campanha; nomes das 16 list views.
9. Se o Data Cloud ou Einstein segmentação estão habilitados (não consultei).
10. Product2/OrderItem: não levantei campos de produto estruturado.
