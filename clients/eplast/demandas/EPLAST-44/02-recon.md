# EPLAST-44 — Recon da org (Jornadas automáticas de comunicação)

**Data:** 2026-11-15
**Org confirmada:** alias `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast), status Connected, `sf org list`. Única org listada. Id da org `00DHa000006vfMLMAY`.
**Modo:** só leitura (SOQL agregado, Tooling API, `sf org list metadata`). Um `sf project retrieve` de 3 relatórios foi feito em pasta temporária para ler filtros; a pasta foi apagada. Nenhum deploy, DML ou Apex.
**Fontes:** `01-analise.md`, `demanda.md`, `comentarios-do-card.md`, `CLAUDE.md` da conta, consultas `sf`. `assessment.md` não foi usado (tudo que é afirmado foi conferido na org).

## 0. Correções à análise (01-analise.md)

| Ponto da análise | O que a org mostra | Prova |
|---|---|---|
| `PriorityScore__c` e `PriorityBand__c` "não confirmados" | **Existem** em Lead e Opportunity (`PriorityBand__c`, `PriorityScore__c`); `IsPriorityRecord` em Lead, Contact e Opportunity | FieldDefinition por `LIKE '%Priority%'` |
| `MKT_Origem_Agrupada` "não confirmado" | Continua **não existe** (nenhum campo `MKT%` em Lead, Contact, Opportunity) | FieldDefinition `LIKE 'MKT%'` = 0 |
| 409 relatórios | **414** hoje | `SELECT COUNT() FROM Report` |
| 35 relatórios na pasta de marketing (EPLAST-36) | **63** com `FolderName='MARKETING CLOUD'` | `SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'` |
| Flows `MCC_*` "dezenas, não confirmado" | **13** ativos | Tooling `Flow` ativo, `Definition.DeveloperName LIKE 'MCC%'` |

## 1. O que já cobre o pedido (reaproveitar)

Relatórios na pasta `MARKETING CLOUD` (Report, `FolderName='MARKETING CLOUD'`). Filtros lidos por retrieve temporário.

| Item | Existe? | Filtros relevantes (metadata) | Reaproveitamento |
|---|---|---|---|
| `LEADS_PROSPECCAO_PRIORIDADE` (LeadList) | Sim | `PriorityBand__c <> 'Sem dados suficientes'`, `EMAIL_OPT_OUT = 0`, `et4ae5__HasOptedOutOfMobile__c = 0`, `CONVERTED = 0` | Cobre prospecção com opt-out de e-mail e mensagem e lead convertido (CA-01 a CA-03 para Lead). Candidato direto a público de jornada de lead |
| `MSG_LEADS_CELULAR_APTOS` (LeadList) | Sim | `et4ae5__HasOptedOutOfMobile__c = 0`, `CONVERTED = 0`, `MOBILE_PHONE` preenchido | Público de mensagem para Lead. Não filtra `EMAIL_OPT_OUT` (coerente com canal mensagem) |
| `MSG_CONTATOS_CELULAR_APTOS` (ContactList) | Sim | `et4ae5__HasOptedOutOfMobile__c = 0`, `PHONE3` preenchido | Público de mensagem para Contact |
| Outros na mesma pasta (nomes) | Sim | Filtros **não lidos** | `INATIVOS_GERAL`, `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`, `COMPRA_ULTIMOS_90_DIAS`, `POTENCIAIS_SEM_COMPRA`, `LEADS_SEGMENTO_*`, `SEGMENTO_*`, `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO`, `CLASSIFICACAO_CONTAS_POR_CLASSE`. Sugerem público de reativação e relacionamento |
| Relatórios de e-mail de Contact | Não confirmado | Nenhum relatório de Contact com `HasOptedOutOfEmail` foi lido | O arquiteto deve checar se os públicos de Contact (SEM_COMPRA, INATIVOS) excluem `HasOptedOutOfEmail` |
| Dashboards | 21 | `SELECT COUNT() FROM Dashboard` | Conteúdo não inspecionado |
| Agente `SFAgent2` | Sim (Bot `SFAgent2`; `GenAiPlannerBundle` v1 a v8, últimas em 2026-11-15) | `sf org list metadata -m Bot` e `-m GenAiPlannerBundle` | Demanda não pede assistente, resumo nem linguagem natural: não se aplica. Se passar a pedir, estender `SFAgent2` |
| Tópicos e ações do `SFAgent2` | Não verificados | Retrieve do bundle não feito | Ver "Não confirmado" |

## 2. O que será tocado (campos)

Todos conferidos por FieldDefinition (`sbx-eplast-dev`).

| Objeto | Campo | Existe? | Observação |
|---|---|---|---|
| Lead, Contact | `HasOptedOutOfEmail` | Sim | Padrão |
| Lead, Contact | `et4ae5__HasOptedOutOfMobile__c` | Sim | Do conector |
| Lead, Contact | `et4ae5__Mobile_Country_Code__c` | Sim | Do conector, usado nos relatórios de mensagem |
| Lead | `PriorityScore__c`, `PriorityBand__c`, `IsPriorityRecord` | Sim | Usados em `LEADS_PROSPECCAO_PRIORIDADE` |
| Opportunity | `PriorityScore__c`, `PriorityBand__c`, `IsPriorityRecord` | Sim | Sem relatório de público conhecido |
| Contact | `IsPriorityRecord` | Sim | — |
| CampaignMember | `et4ae5__Activity__c` | Sim | Único campo `et4ae5` em CampaignMember; retorno do conector |
| Lead, Contact, Opportunity | `Status`, `IsConverted`, `LeadSource`, `CampaignId`, `StageName`, `LastActivityDate` | Confirmados na análise (FieldDefinition de 2026-11-15) | Não reconsultados item a item nesta sessão, exceto os acima |
| Descrição dos campos | Não verificada | — | Não consultei descrição de campo |

## 3. Automação concorrente

| Objeto | Item | Ativo? | Prova |
|---|---|---|---|
| Lead | Trigger Apex | Nenhum | `ApexTrigger WHERE TableEnumOrId='Lead'` retornou 0 |
| Lead | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (AutoLaunched) | Sim | Tooling `Flow` ativo |
| Lead, Contact | Validation rules `Telefone`, `Celular` (Lead); `Telefone`, `WhatsApp` (Contact) | Ativas | Tooling `ValidationRule` |
| Contact | Trigger Apex | Nenhum | `ApexTrigger WHERE TableEnumOrId='Contact'` retornou 0 |
| Account | Triggers `AccountBefore`, `AccountTrigger` | Ativos | `ApexTrigger` |
| Account | Flows `AccountTriggered`, `AccountUpdateEconomicGroup`, `PaymentTermAccount`, `SetPaymentTermsChangesinAccount`, `Account_Agente_ProximaAcao`, `UpdateParentAccountUsedLimit` | Ativos | Tooling `Flow`, nome por LIKE |
| Opportunity | Triggers `OpportunityBefore`, `OpportunityAfter`, `OpportunityTrigger` | Ativos | `ApexTrigger` |
| Opportunity | Flows `OpportunityFlow`, `Opportunity_BeforeSave_QualificaOportunidade`, `Opportunity_AfterSave_CriaCasoPosVendas`, `Opportunity_Scheduled_AlertaParada`, `ScheduledFlowOpportunity`, `PaymentTermsOpportunity`, `Opportunity_Screen_RascunhoComercial` | Ativos | Tooling `Flow` |
| Order | Trigger `OrderTrigger` (2 linhas com o mesmo nome) | Ativo | `ApexTrigger`, 2 registros |
| Order | Flows `Order`, `OrderScheduledFlow` | Ativos | Tooling `Flow` |
| CampaignMember | Trigger não gerenciado | Nenhum | `ApexTrigger WHERE TableEnumOrId='CampaignMember'` retornou 0 |
| Pacote SBQQ | Triggers de CPQ | Não confirmado | Minha consulta de triggers não incluiu o namespace `SBQQ` |
| Total Flows ativos | 51 (13 `MCC_*`) | Sim | `COUNT()` em `Flow` |

Leitura para o arquiteto: o público desta demanda é Lead e Contact. Não há trigger Apex próprio neles, só o Flow de atribuição de Lead e validation rules de telefone. A ordem de execução em Account, Opportunity e Order só vira risco se o gatilho gravar nesses objetos. Não mapeei a ordem entre triggers e Flows (corpo não lido).

## 4. Marketing Cloud Connect (`et4ae5`)

| Item | Instalado? | Prova |
|---|---|---|
| Classes `et4ae5` | Sim, 523 | `ApexClass WHERE NamespacePrefix='et4ae5'` |
| Objetos custom `et4ae5` | Sim, 28 | Tooling `CustomObject` |
| Campos custom `et4ae5` | Sim, 455 | Tooling `CustomField` |
| Triggers `et4ae5` | Sim, 14 | Incluem `updateCampaignMemberStatusForIER` e `LinkIERActivityLog` (em `et4ae5__IndividualEmailResult__c`), `sendDefChange`, `smsDefChange`, `assignETPermission` (em User) |
| Campos `et4ae5` em Lead e Contact | `HasOptedOutOfMobile__c`, `Mobile_Country_Code__c` | FieldDefinition |
| Campo `et4ae5` em CampaignMember | `Activity__c` | FieldDefinition |
| Flows `MCC_*` ativos | 13 | Entre eles `MCC_ScheduledSend`, `MCC_SendComplete`, `MCC_SendFailed`, `MCC_TrackingAsOfIER` |
| Conexão com o Marketing Cloud (credencial, BU) | Não verificada | Fora do escopo: a esteira não conecta |

Retorno do Marketing Cloud no CRM: resultado de envio em `et4ae5__IndividualEmailResult__c` e status de membro de campanha via trigger do pacote. Opt-out de mensagem em `et4ae5__HasOptedOutOfMobile__c`. Não foi verificado o que o conector lê de Lead e Contact além disso. Não há campo `et4ae5` de público ou jornada em Lead e Contact.

## 5. Volume e dados de teste

| Objeto | Registros | Prova |
|---|---|---|
| Lead | 0 | `COUNT()` |
| Contact | 0 | `COUNT()` |
| Account | 0 | `COUNT()` |
| Opportunity | 0 | `COUNT()` |
| Order | 0 | `COUNT()` |
| Campaign | 0 | `COUNT()` |
| CampaignMember | 0 | `COUNT()` |
| Report | 414 | `COUNT()` |

A dev não tem dado de negócio: teste só com dado sintético (prefixo `EPLAST44 TESTE`, scripts de `fixtures/`). Volume real não pode ser inferido.

**Usuário de teste** (consulta por `User` com username da conta de serviço da Konecta, sem citar o username): dois usuários, ambos perfil "Administrador do sistema".
- `005bJ00000piKAaQAM`: ativo. Usar como proprietário de registro de teste. É também o usuário que a esteira usa na org conectada, o que impede usá-lo sozinho como caso de acesso negado (admin).
- `005bJ00000hBJmYQAW`: inativo.

## 6. Permissões

| Item | Achado | Prova |
|---|---|---|
| OWD externo | Private em Lead, Contact, Account, Opportunity, Campaign | `EntityDefinition.ExternalSharingModel` |
| OWD interno | Lead `ReadWriteTransfer`, Contact `ReadWrite`, Account `ReadWrite`, Opportunity `Read`, Campaign `FullAccess` | `EntityDefinition.InternalSharingModel` |
| Perfis / permission sets não gerenciados | 33 perfis; 21 permission sets sem perfil e sem namespace | `COUNT()` |
| Acesso por perfil/PS aos relatórios e à pasta `MARKETING CLOUD` | Não verificado | — |
| Quem lê os relatórios pelo Marketing Cloud (usuário de integração) | Não verificado | — |

## Não confirmado

1. Tópicos e ações de `SFAgent2` (4 tópicos, 3 ações). Só confirmei Bot e `GenAiPlannerBundle` v1 a v8. A versão ativa e o conteúdo não foram lidos. Não é necessário se a demanda continuar sem assistente.
2. Filtros dos demais 60 relatórios da pasta `MARKETING CLOUD`. Só 3 foram lidos. Falta checar se os públicos de Contact (`SEM_COMPRA_*`, `INATIVOS_GERAL`, `COMPRA_ULTIMOS_90_DIAS`) excluem `HasOptedOutOfEmail`.
3. Se `LEADS_PROSPECCAO_PRIORIDADE` já é consumido pelo Marketing Cloud hoje (a conexão não é verificada).
4. Ordem de execução entre triggers e Flows de Account, Opportunity e Order, e triggers do pacote SBQQ. Não foi mapeada.
5. Descrição e significado dos campos `PriorityScore__c` e `PriorityBand__c` (descrição não consultada, e o critério de "Sem dados suficientes" não foi investigado).
6. Perfis e permission sets com acesso a Lead, Contact e à pasta de relatórios.
7. O que o conector `et4ae5` lê de Lead e Contact além dos campos listados, e o que ele grava além de `IndividualEmailResult` e `CampaignMember.et4ae5__Activity__c`.
8. Caso de acesso negado: o único usuário ativo de teste é admin. O arquiteto ou o verificador precisam de outro usuário se o caso for exigido.
9. Quais jornadas, público e gatilho (PEND-01 e PEND-02 da análise): a org não responde a isso.
