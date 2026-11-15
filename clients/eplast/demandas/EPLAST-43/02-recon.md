# EPLAST-43 — Recon da org

**Etapa:** recon · **Data:** 2026-11-15 · só leitura, só metadata e contagens agregadas (nenhum registro lido).

## 1. Org conectada

Comando: `sf org list`

| Alias | Tipo | Org Id | Status |
|---|---|---|---|
| `sbx-eplast-dev` | Sandbox | `00DHa000006vfMLMAY` | Connected |

É a sandbox de dev da esteira (na Eplast, `eplast--qa`; regra 5 do briefing). O nome "qa" não é risco. Preflight (`00-preflight.md`): sem bloqueios e sem outras demandas nos mesmos componentes.

## 2. Pedido

Deixar o CRM pronto para o Marketing Cloud personalizar conteúdo, e-mail e mensagem por cliente e segmento: dados, públicos, status e opt-out no CRM. Nada é enviado pelo CRM e nada é feito no Marketing Cloud (`01-analise.md`, regra 2).

## 3. O que já cobre o pedido (seção principal)

### 3.1 Relatórios e pasta de públicos

Comandos: `sf data query "SELECT DeveloperName, FolderName FROM Report WHERE FolderName LIKE '%MARKETING%'"`, `SELECT ... FROM Folder`, `sf project retrieve start -m Report:MARKETINGCLOUD/<nome>` (descartado após leitura).

| Item | Estado | Prova |
|---|---|---|
| Pasta de relatórios `MARKETING CLOUD` (DeveloperName `MARKETINGCLOUD`) | Existe | query em `Folder` |
| 25 relatórios na pasta | Existem (lista abaixo) | query em `Report` |
| Segmento por setor, Contact: `SEGMENTO_ALIMENTOS`, `_BEBIDAS`, `_DISTRIBUIDOR_VAREJO`, `_FARMACEUTICO`, `_HIGIENE_LIMPEZA`, `_INDUSTRIAL`, `_INDUSTRIA_DE_SOPRO`, `_INDUSTRIA_DE_TRANSFORMACAO`, `_PET_BEM_ESTAR_ANIMAL` | Existem (9) | query em `Report` |
| Segmento por setor, Lead: `LEADS_SEGMENTO_ALIMENTOS`, `_BEBIDAS`, `_DISTRIBUIDOR_VAREJO`, `_FARMACEUTICO`, `_HIGIENE_LIMPEZA`, `_INDUSTRIAL`, `_INDUSTRIA_DE_SOPRO`, `_INDUSTRIA_DE_TRANSFORMACAO` | Existem (8) | query em `Report` |
| Recência: `COMPRA_ULTIMOS_90_DIAS`, `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`, `INATIVOS_GERAL`, `POTENCIAIS_SEM_COMPRA` | Existem (6) | query em `Report` |
| Produto e classe: `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO`, `CLASSIFICACAO_CONTAS_POR_CLASSE` | Existem (2) | query em `Report` |
| Opt-out de e-mail nos filtros | Confirmado em `LEADS_SEGMENTO_ALIMENTOS` e `SEGMENTO_ALIMENTOS`: filtro `EMAIL_OPT_OUT equals 0`. Os outros 8 relatórios lidos (retrieve de 10 dos 25) não foram conferidos um a um: a contagem de `OptedOut` no texto deu 0, mas o filtro padrão se chama `EMAIL_OPT_OUT`, então não prova nada | retrieve + leitura de `<filter>` |
| Opt-out de celular (`et4ae5__HasOptedOutOfMobile__c`) em algum filtro | Não encontrado nos 2 relatórios lidos em detalhe; demais não conferidos | idem |
| Tipos de relatório dos 10 lidos | `ContactList`, `LeadList`, `AccountList`, `OrderItemList` | `<reportType>` |
| Relatório de segmentação por `LeadSource`, `PriorityBand__c` ou "origem agrupada" | Não encontrado entre os 10 lidos; os 15 restantes não foram abertos | retrieve parcial |

Também existem relatórios padrão em `Sales and Marketing Reports` (ex.: `LeadsbySource`, `Leads_by_Industry`, `CampaignsbyROI`) e 3 dashboards em pasta com "MARKETING" no nome (nomes não levantados).

### 3.2 Permission sets

Comando: `SELECT Name, Label FROM PermissionSet WHERE Name LIKE '%Marketing%' OR Name LIKE '%Publico%'`

| Permission set | Estado |
|---|---|
| `PS_Marketing_Publicos` | Existe |
| `PS_Marketing_AnaliseCampanhas` | Existe |
| Do conector: `Marketing_Cloud_System_User`, `Marketing_Cloud_Connected_App`, `MarketingCloudPublishingC2CPermSet` | Existem (pacote) |
| `MarketingUsers`, `UnifiedMarketingStarterUserPermSet` ("Gerente de marketing") | Existem (padrão) |

FLS de `PS_Marketing_Publicos` sobre os campos de Lead e Contact: **não consegui confirmar** (`FieldPermissions` não é consultável por `sf data query` nesta org).

### 3.3 Campanhas

`SELECT COUNT() FROM Campaign WHERE Name LIKE 'PUB -%'` = **0**. As campanhas `PUB -` citadas na EPLAST-36 não existem na dev (alinha com PA-06: sem `Campaign` na v1).

### 3.4 Agente Agentforce

| Item | Estado | Prova |
|---|---|---|
| Bot `SFAgent2` | Existe (único) | `SELECT DeveloperName FROM BotDefinition` |
| Versões de planner `SFAgent2_v2` a `_v5` | Existem | `GenAiPlannerDefinition` |
| Funções (ações) `ConsultarPedidos_*`, `AgregacaoPedidos_*`, `IdentificarConta_*`, `QueryRecords_*` | Existem (vários sufixos de versão) | `GenAiFunctionDefinition` |
| Plugins (tópicos) `insights_comerciais_*`, `GeneralFAQ_*`, `off_topic_*`, `ambiguous_question_*`, `agent_router_*` | Existem (vários sufixos de versão) | `GenAiPluginDefinition` |

O número exato de tópicos e ações da versão ativa não foi reconciliado (a lista traz várias versões). A PA-07 da análise (SFAgent2 fora desta demanda) não exige isso.

## 4. O que será tocado: objetos e campos

Comando: `sf sobject describe -s Lead|Contact` filtrado por nome (sem dados). Coluna "Descrição" refere-se a `inlineHelpText`; o campo `description` não aparece no describe.

| Objeto.Campo | Tipo | Estado |
|---|---|---|
| `Lead.Email`, `Contact.Email` | email | Existem |
| `Lead.HasOptedOutOfEmail`, `Contact.HasOptedOutOfEmail` | boolean | Existem (os dois) |
| `Lead.et4ae5__HasOptedOutOfMobile__c`, `Contact.et4ae5__HasOptedOutOfMobile__c` | boolean | Existem (pacote) |
| `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.et4ae5__Mobile_Country_Code__c` | picklist | Existem (pacote) |
| `Lead.LeadSource`, `Lead.Status`, `Lead.IsConverted` | picklist, picklist, boolean | Existem |
| `Contact.LeadSource` | picklist | Existe |
| `Lead.Sector__c` | picklist | Existe |
| `Lead.Subsector__c` | multipicklist | Existe |
| `Lead.PriorityScore__c` (double) e `Lead.PriorityBand__c` (string) | calculados | Existem, ambos com texto de ajuda |
| `Lead.WhatsApp__c`, `Contact.WhatsApp__c` | phone | Existem (telefone; **não** são campo de opt-out) |
| `Lead.State`, `Contact.MailingState` | string | Existem |
| `Lead.MKT_Origem_Agrupada` (ou `__c`) | — | **Não existe no describe de Lead** (filtro por nome contendo "rigem" e "MKT" voltou vazio). A análise o cita como "origem agrupada" do histórico: pode ser fórmula de relatório (bucket), não campo |
| Campo de opt-out de WhatsApp | — | Não encontrado entre campos de Lead e Contact com "opt"/"whats" no nome (só `WhatsApp__c`, telefone). Não reconferido em outros objetos |
| `Account.Sector__c` | — | Usado em filtro de relatório (`SEGMENTO_ALIMENTOS`); não descrito por `describe` nesta sessão |
| Campos de última compra/atividade (`LastActivityDate` etc.) | — | **Não confirmados** |

Objetos do conector `et4ae5` (`sf sobject list`): `et4ae5__IndividualEmailResult__c`, `__IndividualLink__c`, `__SendDefinition__c`, `__SMSDefinition__c`, `__SMSJunction__c`, `__SendJunction__c`, `__Automated_Send__c`, `__Triggered_Send_Execution__c`, `__Business_Unit__c`, `__Configuration__c`, `__ET4AE_Config__c`, `__ET4AEConfig__c`, `__Campaign_Member_Configuration__c`, `__AggregateLink__c`, `__Email_Linkage__c`, `__MC_CDC_Journey__c`, `__UEBU__c`, `__abTest__c`, `__SupportRequest__c`, eventos `__JB_Event__e`, `__JB_CDC_Event__e`, `__JB_Flow_Event__e`. `CampaignMember.et4ae5__Activity__c`: não reconfirmado nesta sessão (a análise o cita como confirmado; sem `describe` de `CampaignMember` aqui). Como o conector popula esses objetos: não verificado.

## 5. Automação concorrente

| Item | Resultado | Prova |
|---|---|---|
| Triggers Apex em `Lead`, `Contact`, `Campaign`, `CampaignMember` | **0** | `ApexTrigger` (Tooling) |
| Triggers Apex em `Account`, `Order`, `Opportunity` | **7** (nomes e eventos não levantados) | `COUNT()` em `ApexTrigger` (Tooling) |
| Validation rules em `Lead` | `Celular`, `Telefone` (ativas) | `ValidationRule` (Tooling) |
| Validation rules em `Contact` | `Telefone`, `WhatsApp` (ativas) | idem |
| Flows ativos relacionados a Lead | `Lead_AfterInsert_AplicaRegraAtribuicao` | `Flow` (Tooling), status Active |
| Flows ativos do conector (`MCC_*`: BackupWorkflow, ScheduledSend, SendComplete, SendFailed, TrackingAsOfIER/SD, NewSupportRequest, etc.) | Existem, ativos | idem |
| Flows ativos em Opportunity/Account/Order | `Opportunity_AfterSave_CriaCasoPosVendas`, `Opportunity_BeforeSave_QualificaOportunidade`, `Opportunity_Scheduled_AlertaParada`, `ScheduledFlowOpportunity`, `Account_Agente_ProximaAcao`, `UpdateParentAccountUsedLimit`, `Order` e flows CPQ (`QuoteLineCPQFlow`, `DeleteLineItemCPQFlow`) | idem (lista cortada em 60; objeto de cada Flow não confirmado) |

A ordem de execução entre trigger custom, trigger SBQQ e Flows em Account/Opportunity/Order **não foi mapeada**: a demanda não prevê automação nesses objetos (CA-07). Se o design quiser algo ali, falta levantar nome e evento dos 7 triggers. Em Lead e Contact não há trigger, e a única automação de Lead é o Flow de atribuição no insert. Workflow Rules: o assessment diz 17, todas do `et4ae5`; não reconferido.

## 6. Volume e dados de teste

Comando: `SELECT COUNT() FROM <objeto>`

| Objeto | Registros |
|---|---|
| Lead | 0 |
| Contact | 0 |
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| OrderItem | 0 |
| Campaign | 0 |
| CampaignMember | 0 |
| Product2 | 1042 |

A dev **não tem dado para testar** os públicos: o verificador precisa criar Lead/Contact/Account de teste pelos scripts de `fixtures/` (regra 6). Os validation rules de telefone (`Celular`, `Telefone`, `WhatsApp`) podem exigir formato válido nos dados de teste; o formato exigido não foi levantado.

Usuário de teste (regra 6): a consulta de usuário da conta de serviço da Konecta (filtro por username, sem o username no artefato) retornou dois usuários, ambos com perfil "Administrador do sistema":
- `005bJ00000piKAaQAM`: ativo (usar este).
- `005bJ00000hBJmYQAW`: inativo.

Como esse usuário é administrador, **não serve para o caso de acesso negado**; para CA-05 é preciso outro usuário com o permission set e sem ele. Não verificado se existe.

## 7. Permissões

| Item | Estado |
|---|---|
| `PS_Marketing_Publicos` | Existe; FLS e acesso a pasta de relatórios não confirmados |
| Acesso à pasta `MARKETING CLOUD` (compartilhamento) | Não confirmado |
| OWD de Lead, Contact, Account | Não consultado |
| Perfil que alcança os objetos | Não levantado (só o do usuário de teste: Administrador do sistema) |

## 8. Riscos e incertezas ligados ao assessment

- **Achado 1** (ordem de execução em Account/Opportunity/Order): sem impacto enquanto a demanda for só leitura; nomes e eventos dos 7 triggers não levantados.
- **Achado 4** (campos sem descrição): `PriorityScore__c` e `PriorityBand__c` têm texto de ajuda; `description` de campo não aparece no describe, então CA-09 deve ser conferido no retrieve do build.
- **Achado 2** (cobertura Apex 10%): irrelevante se não houver Apex.
- **Conector `et4ae5`** (519 classes no assessment): objetos listados na seção 4; o uso real não foi verificado.
- Colisão de nome do `OrderTrigger` e 23 validation rules de Order: não levantadas aqui; só importam se houver escrita em Order.

## 9. O que não consegui confirmar

1. Se os outros 23 relatórios da pasta (e 8 dos 10 lidos) têm `EMAIL_OPT_OUT = 0` nos filtros e se algum exclui opt-out de celular.
2. Existência e definição de `MKT_Origem_Agrupada` (não é campo de Lead); como o público de prospecção usa `LeadSource`, `PriorityBand__c` e status.
3. FLS de `PS_Marketing_Publicos` e compartilhamento da pasta; OWD.
4. Campos de última compra e atividade usados pelos relatórios `SEM_COMPRA_*`; `Account.Sector__c` por `describe`.
5. `CampaignMember.et4ae5__Activity__c` (não reconferido) e como o conector grava nos objetos de resultado.
6. Nome, evento e ordem dos 7 triggers em Account/Order/Opportunity; objeto dos Flows ativos além de Lead.
7. Nomes dos 3 dashboards da pasta de marketing; conteúdo dos 15 relatórios não abertos.
8. Usuário de teste sem permissão (CA-05) e formato de telefone que passa nas validation rules.
9. Quantidade de tópicos e ações da versão ativa do `SFAgent2` (briefing diz 4 e 3; a org mostra várias versões).
10. Conexão do Marketing Cloud Connect e Business Unit: fora do escopo, a esteira não toca.

## 10. O que o arquiteto precisa decidir

1. Reaproveitar os 25 relatórios existentes como públicos (PA-02) e, nos que não filtram opt-out, ajustar o filtro. CA-08 exige declarar a mudança de contagem.
2. Como representar "origem agrupada" e "prioridade" no público: campo novo (justificar contra `LeadSource` e `PriorityBand__c`), fórmula de relatório ou filtro direto.
3. Como excluir opt-out de celular nos públicos de mensagem (`et4ae5__HasOptedOutOfMobile__c` em Contact e Lead).
4. Se `PS_Marketing_Publicos` cobre os campos novos ou é criado outro permission set, sem alterar perfil.
5. Como testar sem dados: scripts de `fixtures/` e usuário de teste não administrador para o caso de acesso negado.
6. Tratamento de WhatsApp: `WhatsApp__c` existe, sem campo de opt-out; manter a PA-04 (fora, EPLAST-34).
