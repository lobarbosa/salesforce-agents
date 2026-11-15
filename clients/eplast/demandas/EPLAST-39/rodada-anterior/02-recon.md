# EPLAST-39 — Recon da org

**Data da coleta:** 2026-11-10 (vence em 2026-11-17, ver skill `org-recon`)
**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`), sandbox, Enterprise Edition, API 68.0, `Connected`.
**Org de QA:** `sbx-eplast-qa` **não está autenticada nesta sessão**. Não foi possível comparar dev x QA (ver "Lacunas").
**Método:** `sf sobject describe`, `sf data query` (metadata e `COUNT()` apenas), Tooling API, e `sf project retrieve start` para `/tmp/recon/proj/md` (nunca para `force-app/`). Nenhum registro de cliente lido.

> Nota do achado 6 do assessment, reconfirmado hoje: a instance do alias `sbx-eplast-dev` tem "qa" no nome. Não dá para afirmar daqui se dev e QA são a mesma sandbox física.

---

## 1. Objetos e campos envolvidos

### Lead
- 63 campos, 12 custom: `CNAE__c`, `CompanyDocument__c`, `CompanyName__c`, `Facebook__c`, `Instagram__c`, `LinkedIn__c`, `Subsector__c`, `WhatsApp__c`, `Sector__c`, `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`, `maps__AssignmentRule__c`. **Nenhum campo de UTM nem de origem custom.**
- `LeadSource` (picklist, **não restrita**): Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR (13 valores ativos).
- `Status`: Aberto - Não contatado, Contatado, Fechado - Convertido, Fechado - Não convertido.
- `IsConverted`, `ConvertedDate`, `ConvertedOpportunityId` (padrão) existem.
- Record type: só `Mestre`.
- Validation rules: `Celular` e `Telefone` (ativas). Nenhuma em Campaign ou CampaignMember.
- OWD interno: `ReadWriteTransfer`.

### Campaign
- 34 campos, **0 custom**.
- `Type` (picklist): Event, Demo Signup / Trial, Email, Referral Program, Search, Social Media, Thought Leadership, Website Direct, Other — **valores padrão em inglês, sem relação com a taxonomia de `Lead.LeadSource`**.
- `Status`: In Progress, Completed, Aborted, Planned.
- Campos de custo e roll-up padrão confirmados: `ActualCost`, `BudgetedCost`, `ExpectedRevenue`, `NumberSent`, `NumberOfLeads`, `NumberOfConvertedLeads`, `NumberOfContacts`, `NumberOfResponses`, `NumberOfOpportunities`, `NumberOfWonOpportunities`, `AmountAllOpportunities`, `AmountWonOpportunities`, `ParentId`.
- Os campos `Hierarchy*` (roll-up de hierarquia de campanhas) **não aparecem no describe** com o usuário da conexão. Não cito como disponíveis.
- OWD interno: `FullAccess`.

### CampaignMember
- 1 campo custom: `et4ae5__Activity__c` (Marketing Cloud Connect).
- `Status`: Responded, Sent. `HasResponded`, `FirstRespondedDate`, `LeadSource` (mesma lista de Lead, não restrita).

### Opportunity
- 77 campos, 28 custom (lista no describe). Nenhum de origem/campanha custom. `LeadSource` (mesma lista, não restrita), `CampaignId`, `Amount`, `IsWon` padrão.
- Record types: Amostra, Bonificação, Indústria, Venda, Venda com remessa, Mestre.
- OWD interno: `Read`.

### Influência de campanha (Customizable Campaign Influence)
- `CampaignSettings` (retrieve): `enableCampaignInfluence2 = true`, `enableAutoCampInfluenceDisabled = false` (associação automática **ligada**), `aiAttributionTimeframe = 6`.
- `CampaignInfluenceModel`: 1 modelo, `primaryModel` ("Salesforce Model"), `IsActive = true`, `IsDefaultModel = true`, `IsModelLocked = true`.
- O sObject `CampaignInfluence` **não é consultável** pelo usuário da conexão (`sObject type 'CampaignInfluence' is not supported`). Pode ser permissão ou exposição de API; não confirmei qual.

### Conversão de lead
- `LeadConvertSettings` (retrieve): `allowOwnerChange = true`; mapeamentos custom de Lead para conta/oportunidade incluem `CNAE__c`, `CompanyDocument__c`, `Facebook__c`, `Instagram__c`, `LinkedIn__c`, `CompanyName__c`, `Sector__c`, `Subsector__c`, `WhatsApp__c`. `LeadSource` é mapeado pela plataforma (campo padrão).

## 2. Volume (contagens agregadas)

| Objeto | `COUNT()` em `sbx-eplast-dev` |
|---|---|
| Lead | 0 |
| Campaign | 0 |
| CampaignMember | 0 |
| Opportunity | 0 |
| CampaignInfluenceModel | 1 |

A sandbox não tem dado de negócio. Volume de produção **não é conhecido** e não pode ser consultado pelo agente.

## 3. Automação nos objetos tocados

### Apex Triggers (Tooling, `TableEnumOrId IN (Lead, Campaign, CampaignMember, Opportunity, CampaignInfluence, OpportunityContactRole)`)
| Trigger | Objeto | Namespace | Eventos |
|---|---|---|---|
| `OpportunityTrigger` | Opportunity | (custom) | after insert, after update |
| `OpportunityAfter` | Opportunity | SBQQ | after insert, after update |
| `OpportunityBefore` | Opportunity | SBQQ | before insert, before update |

**Lead, Campaign, CampaignMember: nenhum trigger.**

### Flows ativos (`FlowDefinitionView`, `TriggerType != null`, `IsActive = true`)
- Opportunity: `Oportunidade_Industria` (RecordAfterSave), `OpportunityFlow` (RecordAfterSave), `ScheduledFlowOpportunity` (Scheduled). Os dois after-save chamam Apex invocável (`CreateQuoteCPQController`, `FlowOpportunityController`) e um `submit` de aprovação (baseline do repo).
- **Lead, Campaign, CampaignMember: nenhum Flow record-triggered nem agendado.** A ressalva da análise sobre o filtro por rótulo foi resolvida: a consulta acima listou todos os 45 Flows ativos com gatilho, sem filtro de objeto, e nenhum é de Lead, Campanha ou Membro de campanha.
- Flows do Marketing Cloud Connect (`et4ae5`): 13 `MCC_*`, todos em objetos do pacote (Envio de email, Envio acionado, Resultado de email individual, Solicitação de suporte). Nenhum em Lead/Campaign/CampaignMember.

### Código custom que lê ou escreve origem/campanha
- Das 56 classes Apex sem namespace, **nenhuma** referencia `Lead`, `Campaign`, `CampaignMember`, `CampaignId`, `LeadSource`, `CampaignInfluence`, `convertLead` ou `et4ae5__`.
- Nenhum Flow custom do baseline referencia `LeadSource`, `CampaignId`, Lead, Campaign ou `et4ae5__`.

### Efeito colateral relevante para teste (Opportunity)
- `OpportunityTrigger` → `OpportunityTriggerHandler.afterInsert/afterUpdate` → `System.enqueueJob(new OpportunityTriggerHelper(...))`.
- `OpportunityTriggerHelper` (`Queueable, Database.AllowsCallouts`): para cada Account das oportunidades, chama `ProtheusAPI.getClientByCNPJ(...)` e atualiza a conta com o retorno (`UpdateAccountWithProtheusInfo`). Callout dentro de loop (dívida existente, fora do escopo).
- Bypass existente: `TriggerUtility.bypassTrigger` lê `TriggerUtility__mdt.TriggerExecution.BypassTrigger__c` (hoje `false` na org). É **global para a org**, não por usuário.
- Consequência: qualquer Opportunity sintética criada para testar esta demanda (direto ou por conversão de Lead) dispara callout para o endpoint do Protheus configurado na sandbox.

## 4. Relatórios e dashboards existentes

- 374 relatórios e 19 dashboards na org; 109 relatórios com nome/pasta ligados a lead, campanha, origem, conversão ou ROI.
- Inspecionados por retrieve (`/tmp/recon/proj/md`):

| Relatório | Pasta | Tipo | Agrupamento / fórmula | Observação |
|---|---|---|---|---|
| `LeadsbySource` ("Marketing Exec Leads by Source") | Sales_and_Marketing_Reports | LeadList | `LEAD_SOURCE`, `CREATED_MONTH` | relatório de amostra da Salesforce |
| `CampaignROIbyCampaignType` | Sales_and_Marketing_Reports | CampaignList | `CAMPAIGN_TYPE` | sem fórmula de ROI própria; usa `Type` em inglês |
| `CampaignsbyROI` | Sales_and_Marketing_Reports | CampaignList | `CAMPAIGN_NAME` | idem; última execução registrada 2015 |
| `Marketing_Exec_Leads_by_Campaigns` | Sales_and_Marketing_Reports | CampaignLead | `CAMPAIGN_NAME`, `LEAD_OWNER` | — |
| `Marketing_Exec_Converted_Amount` ("Leads para Contas com Vendas") | Sales_and_Marketing_Reports | OpportunityLead | `CONVERTED_DATE` | filtra `Lead.Sector__c`/`Lead.Subsector__c` — já adaptado pela Eplast |
| `Marketing_Exec_Conversion_Rate` ("Taxa de Conversão de Leads") | General | OpportunityLead | `CREATED_DATE`; fórmula `CONVERTED:SUM / RowCount` | usado no dashboard da pasta Eplast |
| `Marketing_Exec_Converted_and_Won_Amount` ("Leads Convertidos e Ganhos") | General | OpportunityLead | `CONVERTED_DATE`; filtros convertido + fase | usado no dashboard da pasta Eplast |
| `LEADS_OlB` ("LEADS - GERAL") | MARKETINGCLOUD | LeadList | `OWNER`, `COMPANY` | lista operacional, não métrica |

- Dashboards:
  - `NhOdYqGFEXVWsiQHpYIWRuilgCgMfy` ("Leads & Oportunidades", pasta `Eplast`): 12 componentes, majoritariamente de vendas; usa `Marketing_Exec_Conversion_Rate` e `Marketing_Exec_Converted_and_Won_Amount`. Tipo `SpecifiedUser`.
  - `Best_Practice_Leads_Dashboard` ("Marketing Dashboard", pasta Sales_and_Marketing_Dashboards): pacote de amostra da Salesforce. Tipo `SpecifiedUser`.
- Tipos de dashboard na org: 16 `SpecifiedUser`, 3 `LoggedInUser` (dinâmicos).
- Nenhum relatório na pasta `Eplast` (0).
- Report types custom (33): **nenhum** sobre Lead, Campaign, CampaignMember ou influência de campanha. Os relatórios acima usam tipos padrão (`LeadList`, `CampaignList`, `CampaignLead`, `OpportunityLead`).

## 5. Permissões

### Acesso a Campaign por perfil (`ObjectPermissions`, `PermissionsRead = true`)
- Leitura + criação + edição: `Administrador do sistema`, `Usuário do Marketing`, `Sales Insights Integration User`.
- Só leitura: `Gerente de soluções`, `Read Only`, `Executive Sponsor`, `Gerente do contrato`, `Usuário Padrão`, `End User`, perfis de integração Analytics.
- **Sem leitura em Campaign:** `Comercial - Analista`, `Comercial`, `Comercial - Analistas`, `Comercial Padrão`, `Marketing`, `Financeiro`, entre outros.

### Acesso a Lead por perfil
- Leitura confirmada em 21 perfis, incluindo `Comercial - Analista`, `Marketing` (edição sem criação) e `Usuário do Marketing`.

### Permission sets
- Nenhum permission set custom de negócio concede Campaign. Os que concedem são de sistema (`force`, `sfdcInternalInt`) ou `Modify_All`.
- `UnifiedMarketingStarterUserPermSet` / `UnifiedMarketingUserPermSet` ("Gerente de marketing") existem, **0 atribuições ativas**.
- Custom existentes com prefixo `PS_`: `PS_Comercial_ResumoClienteAgente` (de outra demanda; não será tocado).

### Usuários (contagens, sandbox)
- 22 usuários ativos; **1** com `UserPermissionsMarketingUser = true`.
- Ativos padrão por perfil: Administrador do sistema 9, Comercial - Analista 4, Financeiro 1, demais de integração.
- Contagens refletem a sandbox, não produção.

## 6. Lacunas declaradas (não confirmado)

1. `sbx-eplast-qa` não autenticada: sem comparação de metadata dev x QA.
2. Se dev e QA são a mesma sandbox física (achado 6).
3. Disponibilidade do report type padrão de influência de campanha para o usuário que vai construir (o sObject `CampaignInfluence` não respondeu à API com o usuário da conexão).
4. Limite de dashboards dinâmicos da edição: a org tem 3; o teto da Enterprise Edition precisa ser conferido na documentação oficial no build antes de criar mais um.
5. Uso real dos relatórios existentes em produção (`LastRunDate` é da sandbox).
6. Qual perfil o time de Marketing da Eplast usa em produção (a sandbox só tem 1 usuário com Marketing User).
7. Endpoint do Protheus configurado na sandbox de QA (homologação ou produtivo). Não foi lido.
