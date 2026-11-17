# EPLAST-26 — Recon da org

**Data da coleta:** 2026-11-10 · **Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, Enterprise Edition,
`Organization.IsSandbox = true`, API v68.0) · **Validade:** 7 dias (vence em 2026-11-17)

Escopo do recon: **Lead** e **Opportunity** (PA-1 da análise). Account entra só como objeto pai lido por
fórmula e como alvo de cascata da automação de Opportunity. Order ficou fora. Todo retrieve foi para
`/tmp/recon`, nada em `force-app/`. Nenhuma query trouxe registro de negócio: só `COUNT()`, metadata e
configuração.

---

## 0. Ambiente (achado 6 do assessment, ainda aberto)

| Item | Resultado | Comando |
|---|---|---|
| Orgs autenticadas no runner | Só uma: alias `sbx-eplast-dev`. **Não existe** `sbx-eplast-qa` autenticada | `sf org list --json` |
| Instance URL da `sbx-eplast-dev` | `https://eplast--qa.sandbox.my.salesforce.com`, o mesmo que o assessment registrou | `sf org display` |
| API da org | v68.0 (o assessment registrou v67 em 2026-09-30, houve release desde então) | idem |

Consequência: a comparação dev × qa que a skill de recon pede quando a demanda depende de validation rule e
automação **não pôde ser feita**. O alias de dev continua apontando para uma sandbox com nome de qa. Isso não
bloqueia o design, mas **bloqueia o build** (P14).

## 1. Volume

| Objeto | `SELECT COUNT()` |
|---|---|
| Lead | 0 |
| Opportunity | 0 |
| Account | 0 |
| Contact | 0 |
| Task | 0 |

A sandbox está vazia. Não dá para inferir volume de produção, distribuição de estágios nem taxa de conversão
histórica a partir daqui. Isso pesa direto na viabilidade de qualquer modelo preditivo (P1, P10).

## 2. Lead

### Automação
| Tipo | Encontrado | Comando |
|---|---|---|
| Apex Trigger | **nenhum** (nem custom, nem gerenciado) | Tooling `ApexTrigger WHERE TableEnumOrId IN (...)` |
| Flow record-triggered | **nenhum** | `FlowDefinitionView` (TriggerType não nulo, todos os objetos) |
| Classes Apex custom que referenciam `Lead` | **nenhuma** (grep nas 56 classes custom retrieved) | `sf project retrieve start --metadata ApexClass` |
| Validation rules | 2 ativas: `Celular` e `Telefone` (formato de telefone por REGEX, só disparam quando o campo está preenchido fora do padrão) | Tooling `ValidationRule` + retrieve |

Resultado consistente com o recon de outra demanda deste cliente, `[demandas/EPLAST-39/03-design.md]`, que
também não achou trigger nem Flow em Lead.

### Modelo de dados
- 63 campos, 12 custom: `CNAE__c`, `CompanyDocument__c` (CNPJ), `CompanyName__c`, `Facebook__c`,
  `Instagram__c`, `LinkedIn__c`, `Subsector__c` (multipicklist), `WhatsApp__c`, `Sector__c` (picklist),
  `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`, `maps__AssignmentRule__c`.
- **12 de 12 campos custom sem `Description`** (o assessment não mediu Lead; o padrão é o mesmo de
  Opportunity/Account).
- Record type: só `Mestre`.
- Picklists relevantes (valores ativos, todas **não restritas**):
  - `Status`: `Aberto - Não contatado`, `Contatado`, `Fechado - Convertido`, `Fechado - Não convertido`.
  - `LeadSource`: `Campanha`, `WhatsApp`, `Indicação`, `Evento`, `Google Ads`, `Google Orgânico`,
    `Instagram`, `Facebook`, `Prospecção ativa`, `Prospecção passiva`, `Econodata`, `E-mail MKT`, `SDR`.
  - `Rating` (padrão): `AA`, `A`, `B`, `C`, `D`. Já existe um campo de classificação no Lead, e não sei se é
    usado hoje.
- Nenhum campo de score já existente (`describe` não mostra campo com score ou pontuação no nome).

### UI
- Layout: `Lead-Lead Layout` (único).
- Lightning pages: `Lead_Record_Page`, `Lead_Record_Page_Three_Column`. Não confirmei qual está ativa
  (atribuição por app/perfil). Fica para o build.

## 3. Opportunity

### Automação (achado 1 do assessment, confirmado e detalhado)

| Componente | Tipo | Evento | Critério de entrada | O que faz |
|---|---|---|---|---|
| `SBQQ.OpportunityBefore` | Trigger gerenciado (CPQ, api 57) | before insert/update/delete | n/a (código gerenciado, não legível) | n/a |
| `SBQQ.OpportunityAfter` | Trigger gerenciado (CPQ, api 57) | after insert/update | n/a | n/a |
| `OpportunityTrigger` | Trigger custom (api 59) | after insert/update | bypass via `TriggerUtility.bypassTrigger` (CMDT `TriggerUtility__mdt.TriggerExecution`, hoje `false`). After update também é pulado se `System.isQueueable()` | Chama `OpportunityTriggerHandler`, que **enfileira um Queueable (`OpportunityTriggerHelper`) em todo insert e em todo update**. O Queueable faz **callout ao Protheus por Account** (`ProtheusAPI.getClientByCNPJ`) e atualiza a Account com o retorno |
| `OpportunityFlow` | Flow RecordAfterSave (api 59) | create e update | **nenhum: roda em todo save** | 10 recordUpdates: atualiza o próprio `$Record` (`FinancialAnalysis__c`, `Type`, `TaxAnalysis__c`), atualiza **Account** (`TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`), cria Quote, Order, OrderItem e Task, chama Apex `CreateQuoteCPQController` e envia para aprovação |
| `Oportunidade_Industria` | Flow RecordAfterSave (api 64) | update | `NomeTipoRegistro__c = 'Industria'` | Decide por `StageName` e cria Task. Chama Apex `FlowOpportunityController` (criar cotação) |
| `ScheduledFlowOpportunity` | Flow agendado diário | n/a | `IsWon = true` | Atualiza Account (`LastMonthPurchaseValue__c`, `Ranking__c`). Não escreve em Opportunity |

Nenhum dos dois Flows after-save tem `triggerOrder` definido (grep no XML retrieved).

**Ordem de execução de um save de Opportunity, pela análise estática do metadata** (cruzada com a ordem
documentada na skill `salesforce-doutrina`):

1. Validação de sistema. Não há Flow before-save em Opportunity.
2. Before trigger: `SBQQ.OpportunityBefore`.
3. 16 validation rules custom (ver abaixo).
4. Gravação sem commit.
5. After triggers: `SBQQ.OpportunityAfter` e `OpportunityTrigger`. **A plataforma não garante a ordem entre
   dois triggers no mesmo objeto e evento.**
6. After-save Flows: `OpportunityFlow` e `Oportunidade_Industria`, **sem `triggerOrder`, então a ordem entre
   eles não é controlada pelo cliente.**
7. Quando `OpportunityFlow` atualiza o próprio `$Record`, o registro passa por um novo ciclo de save: before
   trigger do CPQ, validation rules e after triggers rodam de novo. Com isso, **`OpportunityTrigger` pode
   enfileirar um segundo Queueable na mesma transação.**
8. Quando `OpportunityFlow` atualiza Account, a cascata aciona a automação de Account do achado 1 do
   assessment: `AccountTrigger`, `SBQQ.AccountBefore`, Flows `AccountTriggered` e
   `UpdateParentAccountUsedLimit`, todos confirmados agora.
9. Commit. Depois, assíncrono: `OpportunityTriggerHelper` faz o callout ao Protheus.

**Limite desta foto:** é análise estática do metadata. Não confirmei por debug log, porque a sandbox não tem
dado e o recon não cria registro. A ordem empírica (passos 5 a 7) precisa ser registrada no build/QA com debug
log, como já exige o cenário de regressão da análise.

**Consequência direta para esta demanda:** qualquer DML em Opportunity, inclusive um update que só grave um
campo de score, aciona o CPQ, 16 validation rules, um callout ao ERP por Account e uma cascata de update em
Account com mais quatro automações.

### Validation rules (16 ativas)
- **7 testam campos da Account em todo save, sem `ISCHANGED` nem filtro de estágio**:
  `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`,
  `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`,
  `CheckAccountOwnerHasProtheusSellerId`. Mais `CheckHasAccount` (`AccountId` em branco).
- 7 só disparam em `Fechado/Ganho` ou `Fechado/Perdido`: `CheckOppHasBranch`, `CheckOppHasPaymentMethods`,
  `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `TaxAnalysis`, `LossReason`, mais
  `Industria_Fase_Cotacao_Sem_Catalogo` (mudança para `Cotação` em Indústria).
- `PriceBook`: compara o catálogo de preços com a Account em todo save quando `Pricebook2Id` está preenchido.

Implicação: um update em segundo plano numa oportunidade cuja Account esteja incompleta **falha**, mesmo que o
update só mexa num campo de score.

### Cobertura de teste do código de Opportunity (`ApexCodeCoverageAggregate`, Tooling)
| Componente | Linhas cobertas / não cobertas |
|---|---|
| `OpportunityTrigger` | 0 / 8 |
| `OpportunityTriggerHelper` | 0 / 17 |
| `OpportunityTriggerHandler` | 0 / 0 |
| `FlowOpportunityController` | 0 / 36 (a classe `FlowOpportunityControllerTest` existe, mas o agregado mostra 0) |
| `CreateQuoteCPQController` | 0 / 32 (a classe `CreateQuoteCPQControllerTest` existe, mas o agregado mostra 0) |
| Org-wide (`ApexOrgWideCoverage`) | **11%** (o assessment registrou 10%) |

Isso fecha um item da seção "não pôde ser medido" do assessment: o trigger custom de Opportunity tem 0% de
cobertura registrada. Não confirmei se as duas classes de teste existentes falham ou se o agregado está
desatualizado.

### Modelo de dados
- 77 campos, 28 custom. Sem `Description` nos que verifiquei (`Budget_Confirmed__c`,
  `Discovery_Completed__c`, `ROI_Analysis_Completed__c`, `Loss_Reason__c`, `CurrentYear__c`,
  `NomeTipoRegistro__c`, `Previs_o_Eintein__c`). O assessment registra 19 de 28 sem descrição.
- **`Previs_o_Eintein__c`** (Number, rótulo "Previsão Einstein"): criado em 2024-10-03, sem descrição, **sem
  nenhuma dependência de metadata** (`MetadataComponentDependency` vazio) e não referenciado por nenhuma
  classe custom. É sinal de uma tentativa anterior de previsão com Einstein. Não sei se é preenchido em
  produção.
- Fórmulas existentes: `CurrentYear__c`, `LastMonth__c`, `LastMoth__c` (duplicada com erro de grafia),
  `ThisYear__c`, `NomeTipoRegistro__c`.
- Record types ativos: `Sample`, `Bonus`, `Industria`, `Sale`, `SellWithShipping`, `Mestre`.
- `StageName` (não restrita): `Qualificação`, `Análise Técnica`, `Precificação`, `Qualificado`, `Cotação`,
  `Execução técnica do projeto`, `Envio Cotação`, `Amostra`, `Análise Fiscal`, `Análise Financeira`,
  `Negociação Comercial`, `Fechado/Ganho`, `Fechado/Perdido`.
- `Type`: `Compra Recorrente`, `Reativação`, `Nova Compra` (escrito pelo `OpportunityFlow`).
- `OpportunitySettings`: histórico de campo de Opportunity **desligado**
  (`enableOpportunityFieldHistoryTracking=false`), Pipeline Inspection ligado.

### UI
- Layouts: `Opportunity-Opportunity Layout`, `Opportunity-CPQ Opportunity Layout`.
- Lightning pages: `Opportunity_Record_Page`, `Opportunity_Record_Page_Three_Column`. Não confirmei qual está
  ativa.

## 4. Account (só como pai lido)
Campos que já são classificações e podem servir de entrada para um score de Opportunity, via fórmula
cross-object, se o cliente confirmar o significado:
- `Ranking__c` (picklist `PP`, `P`, `M`, `G`, `GG`), calculado todo dia pelo `ScheduledFlowOpportunity` a
  partir de compras ganhas.
- `Rating` (padrão, `AA` a `D`), `Risk__c` (`A` a `E`), `Overdue__c` (checkbox "Inadimplente"),
  `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`.

## 5. Compartilhamento e permissões
| Item | Resultado | Comando |
|---|---|---|
| OWD Lead | `ReadEditTransfer` (público leitura/escrita/transferência) | `SELECT DefaultLeadAccess, ... FROM Organization` |
| OWD Opportunity | `Read` (público somente leitura) | idem |
| OWD Account | `Edit` (público leitura/escrita) | idem |
| Usuários ativos por perfil (sandbox) | `Administrador do sistema` 9, `Comercial - Analista` 4, `Financeiro` 1, mais perfis de integração com 1 usuário cada, entre eles **`Sales Insights Integration User`** | `SELECT Profile.Name, COUNT(Id) FROM User WHERE IsActive = true GROUP BY Profile.Name` |
| Permission sets custom | `Analista_Permissao`, `Files_Connect`, `Marketing_Cloud_Connected_App`, `Modify_All`, `PS_Comercial_ResumoClienteAgente`, `Protheus`, `SteelBrickCPQStandardObjectsAccess` | `PermissionSet WHERE NamespacePrefix = null AND IsOwnedByProfile = false` |

Os OWDs da sandbox podem divergir de produção. Não confirmei produção, e não devo.

## 6. Licenças e recursos de IA na sandbox (para P1)
- Há licenças de Agentforce, Prompt Templates, Data Cloud (`GenieDataPlatformStarterPsl`), Sales Coach,
  Engagement Agent (SDR), Inbound Lead Generation, Pipeline Inspection e Forecasting
  (`PermissionSetLicense`, `Status = 'Active'`, 68 linhas).
- **Não há** permission set license nem permission set com "Sales Cloud Einstein" ou "Lead Scoring" no nome.
  Os permission sets com "Einstein" são de Prompt Templates, AI Skills, Activity Capture e Service.
- O retrieve de `Settings:OpportunityScore` voltou vazio, com warning. Não deu para confirmar pelo metadata se
  o Einstein Opportunity Scoring está disponível ou ligado.
- Existe um usuário ativo no perfil `Sales Insights Integration User` e o campo `Previs_o_Eintein__c`. Isso é
  indício, **não confirmação**, de que algum recurso Einstein de vendas já foi ativado. A avaliação de
  licenças da Onda 1 (`eplast-ent-04`) é a fonte certa, e ela continua fora do workspace.
- Licenças de sandbox não refletem a alocação de produção. O assessment já faz essa ressalva.

## 7. Outros pontos observados
- Pacote gerenciado `agentic_feed` com Flows agendados **inativos** `Custom_Stale_Opp` e
  `Custom_Stale_Opp_Action`. Parecem ligados a oportunidade parada (EPLAST-28), não a esta demanda.
- `TaskCreatedOrUpdated` (Flow after-save em Task, sem critério de entrada) atualiza a Account relacionada.
  Só importa se o score passar a depender de atividade gravada (P3).
- Não há classe Apex custom `Batchable` ou `Schedulable`. Há 7 `CronTrigger` em `WAITING`, contagem apenas.
- Nenhuma classe custom referencia `Rating` nem `Previs_o_Eintein__c`.

## 8. Comandos executados (resumo)
`sf org list --json` (só alias, Org ID e status extraídos) · `sf org display` (Org ID, API e instance) ·
`SELECT IsSandbox, OrganizationType FROM Organization` · Tooling `ApexTrigger`, `ValidationRule`,
`CustomField`, `MetadataComponentDependency`, `ApexCodeCoverageAggregate`, `ApexOrgWideCoverage` ·
`FlowDefinitionView` · `sf sobject describe` Lead/Opportunity/Account · `SELECT COUNT()` em Lead, Opportunity,
Account, Contact, Task e CronTrigger · `PermissionSetLicense`, `PermissionSet`, `User` agrupado por perfil,
`TriggerUtility__mdt` · `sf org list metadata` Layout/FlexiPage · `sf project retrieve start` para
`/tmp/recon`: Flows `Oportunidade_Industria`, `OpportunityFlow`, `ScheduledFlowOpportunity` e
`TaskCreatedOrUpdated`, trigger `OpportunityTrigger`, todas as ApexClass custom, 18 ValidationRules de
Lead/Opportunity e `Settings:Opportunity`/`OpportunityScore`/`LeadConvert`.
