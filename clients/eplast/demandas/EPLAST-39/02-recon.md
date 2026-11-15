# EPLAST-39 — Recon da org

**Data:** 2026-11-15 · **Org consultada:** alias `sbx-eplast-dev` (`sf org list`: Sandbox, Connected; `Organization.IsSandbox = true`). API v68.0.
**Alerta de ambiente:** `sf org display` retorna instanceUrl `https://eplast--qa.sandbox.my.salesforce.com`. `sf org list` mostra um único alias conectado (`sbx-eplast-dev`); não existe alias `sbx-eplast-qa` nesta sessão, então não foi possível comparar as duas instâncias (CA-14 e PC-1 da análise seguem sem resolução). Tudo abaixo vale para essa instância, só leitura, só metadata e `COUNT()`.

## 1. O que já cobre o pedido

| Item | Status | Prova |
|---|---|---|
| Pasta de relatórios `Marketing_Origem_Retorno` ("Origem e Retorno de Campanhas") | Confirmado | `SELECT Name, DeveloperName, Type FROM Folder WHERE DeveloperName LIKE 'Marketing%'` |
| Pasta de dashboard `Marketing_Origem_Retorno_Dash` ("Origem e Retorno - Paineis") | Confirmado | mesma query |
| Pasta `MARKETINGCLOUD` (Report) | Confirmado; conteúdo não inspecionado | mesma query |
| `MKT_Leads_por_Origem` | Confirmado, formato **Summary** | `SELECT ... Format FROM Report WHERE FolderName='Origem e Retorno de Campanhas'` |
| `MKT_Conversao_Leads_por_Origem` | Confirmado, **Summary** | idem |
| `MKT_Oportunidades_por_Origem` | Confirmado, **Summary** | idem |
| `MKT_Resposta_Membros_Campanha` | Confirmado, **Summary** | idem |
| `MKT_Desempenho_Campanhas` | Confirmado, formato **Tabular** (lista). Candidato forte à causa de F1 (painel não aceita relatório de lista) | idem |
| Dashboard `MKT_Origem_e_Retorno_Campanhas` | Confirmado (1 na pasta). Qual relatório cada componente usa **não** foi verificado | `SELECT Title, DeveloperName FROM Dashboard WHERE FolderName='Origem e Retorno - Paineis'` |
| Total de relatórios e dashboards | 380 e 20 | `SELECT COUNT() FROM Report` / `FROM Dashboard` |
| Agente `SFAgent2` | Confirmado (1 `BotDefinition`). Tópicos e ações não reexaminados; a demanda não envolve assistente, então não se estende | `SELECT DeveloperName FROM BotDefinition` |

Leitura para o design: os 5 relatórios já existem. O reaproveitamento é a base (regra 3). O único em formato incompatível com painel é o `MKT_Desempenho_Campanhas`. Isso é hipótese, não confirmada contra o dashboard.

## 2. O que será tocado (campos)

| Objeto.Campo | Tipo | Status | Prova |
|---|---|---|---|
| `Lead.LeadSource` | picklist, **não restrita**, anulável, 13 valores ativos: Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR | Confirmado | `sf sobject describe -s Lead` (filtrado) |
| `Opportunity.LeadSource`, `CampaignId`, `Amount`, `IsWon`, `CloseDate` | picklist, reference, currency, boolean, date | Confirmado | describe Opportunity (filtrado) |
| `Campaign.ActualCost`, `BudgetedCost`, `ExpectedRevenue` | currency | Confirmado | describe Campaign (filtrado) |
| `Campaign.NumberOfConvertedLeads`, `NumberOfWonOpportunities`, `AmountWonOpportunities` | int, int, currency (padrão, roll-up) | Confirmado | idem |
| `Campaign.Type`, `Status` | picklist | Confirmado | idem |
| Campos custom em Campaign | Nenhum | Confirmado | describe Campaign (filtro `custom`) |
| Campos do conector em Lead (`et4ae5__HasOptedOutOfMobile__c` boolean, `et4ae5__Mobile_Country_Code__c` picklist) | Existem | Confirmado | describe Lead (filtro de prefixo) |
| Campo UTM custom em Lead | Não encontrado pelo filtro `utm*`; busca limitada a esse prefixo e a `et4ae5` | Parcial | describe Lead |
| `CampaignInfluence` | **Não suportado** nesta org (`sObject type not supported`) | Confirmado | `SELECT COUNT() FROM CampaignInfluence` |

Descrição dos campos: não conferida (todos os usados são padrão).

## 3. Automação concorrente

| Objeto | Achado | Prova |
|---|---|---|
| Lead, Campaign, CampaignMember | **0 triggers** | `SELECT ... FROM ApexTrigger WHERE TableEnumOrId IN (...)` (Tooling) |
| Lead, Campaign, CampaignMember | Validation rules ativas: Lead com `Celular` e `Telefone` (2 no total, objeto Lead/Campaign/CampaignMember); Campaign sem. A demanda não escreve em Lead | `SELECT ... FROM ValidationRule WHERE ...` (Tooling) |
| Account | Triggers `AccountBefore`, `AccountTrigger` | mesma query de ApexTrigger |
| Opportunity | Triggers `OpportunityBefore`, `OpportunityAfter`, `OpportunityTrigger` | idem |
| Order | `OrderTrigger` (aparece 2 vezes na saída) | idem |
| Opportunity | 8 validation rules ativas `CheckAccountHas...`, `CheckHasAccount`, `CheckOppHasBranch` (lista cortada a 30) | `SELECT ... FROM ValidationRule WHERE Active = true` |
| Account | Validation rules ativas: `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk` | idem |
| Flows ativos (AutoLaunched/Workflow) | 42 no total. Relevantes por nome: `Oportunidade_Industria`, `OpportunityFlow`, `ScheduledFlowOpportunity`, `AccountTriggered`, `Order`, `OrderScheduledFlow`, `CPQQuoteFlow`, vários `MCC_*` (conector MC) | `SELECT ... FROM Flow WHERE Status='Active'` (Tooling, LIMIT 60) |
| Ordem de execução trigger custom × SBQQ × Flow | **Não analisada**: a demanda só lê Opportunity, não escreve em Account, Opportunity nem Order. Não confirmei o objeto e o evento de cada Flow | n/a |

Não há automação em Lead nem em Campaign a sobrepor. O build só cria relatório, dashboard e permission set, então não gera risco de ordem de execução.

## 4. Marketing Cloud Connect (`et4ae5`)

| Item | Status | Prova |
|---|---|---|
| Classes Apex `et4ae5` | 523 | `SELECT COUNT() FROM ApexClass WHERE NamespacePrefix='et4ae5'` (Tooling) |
| Pacote `MarketingCloudConnectedApp` (`MCCA5PROD`) instalado | Confirmado | `SELECT ... FROM InstalledSubscriberPackage` (Tooling) |
| Pacote com namespace `et4ae5` em `InstalledSubscriberPackage` | Não apareceu nos 10 primeiros itens listados (saída cortada) | idem |
| Flows `MCC_*` ativos | Confirmado (backup, envio agendado, tracking, etc.) | query de Flow |
| Campos `et4ae5__*` em Lead | Confirmado (2, mobile/opt-out) | describe Lead |
| Objetos `et4ae5__` (envios, tracking) e seus campos | **Não levantados** | n/a |

Para a seção "Preparação do Sales Cloud para o Marketing Cloud": já há o opt-out de mobile em Lead (`et4ae5__HasOptedOutOfMobile__c`). Opt-out de e-mail por `HasOptedOutOfEmail` não foi conferido.

## 5. Volume e dados de teste

| Objeto | Contagem | Prova |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Campaign | 0 | `SELECT COUNT() FROM Campaign` |
| CampaignMember | 0 | idem |
| Opportunity | 0 | idem |
| Account | 0 | idem |
| Order | 0 | idem |

A org consultada não tem dado em nenhum objeto relevante. Os relatórios e o painel não podem ser exercitados aqui sem massa sintética. A premissa da análise de que "a QA tem a maior parte dos leads sem origem" (card, item 3) **não** pode ser confirmada nesta instância.

## 6. Permissões

| Item | Status | Prova |
|---|---|---|
| Permission set `PS_Marketing_AnaliseCampanhas` | Existe | `SELECT Name, Label FROM PermissionSet WHERE Name LIKE 'PS_Marketing%'` (1) |
| Objetos do PS | Campaign, Lead, Opportunity: Read = true, Edit = false | `SELECT ... FROM ObjectPermissions WHERE Parent.Name = 'PS_Marketing_AnaliseCampanhas'` (3 linhas) |
| Acesso à pasta de relatórios e dashboard (folder share) | Não verificado | n/a |
| Campo-nível (FLS) e OWD de Lead/Campaign/Opportunity | Não verificado | n/a |
| Perfis que alcançam os objetos | Não verificado | n/a |

## O que não consegui confirmar

1. **Dev × QA:** só um alias conectado, e ele aponta para `eplast--qa`. Não há como dizer se dev e QA são a mesma org ou se o alias está errado (R6, PC-1, CA-14).
2. **Quais relatórios cada componente do dashboard usa**, e se o `MKT_Desempenho_Campanhas` (Tabular) é o componente que quebrou o painel. A Dashboard API e os componentes não foram lidos.
3. **Buckets de `MKT_Leads_por_Origem`** ("Sem origem", "Fora da lista", rótulo "-"): o formato do relatório foi lido, a definição dos buckets não.
4. **Objeto e evento dos 42 Flows** e ordem de execução entre triggers custom, SBQQ e Flows em Account, Opportunity e Order. Fora do caminho de escrita desta demanda.
5. **Objetos custom do `et4ae5`** e se o pacote `et4ae5` aparece no `InstalledSubscriberPackage` (saída cortada em 10).
6. **Campo UTM ou de origem custom em Lead**: busca limitada ao prefixo `utm` e a `et4ae5`.
7. **Opt-out de e-mail** (`HasOptedOutOfEmail`) e consentimento no CRM.
8. **Compartilhamento da pasta, FLS, OWD e perfis** que alcançam Lead, Campaign e Opportunity.
9. **Tópicos e ações do `SFAgent2`** nesta sessão (a regra da conta cita 4 tópicos e 3 ações; só confirmei que o bot existe).
10. **Distribuição real de `LeadSource`** (valores fora da lista, vazios): a org tem 0 leads.
