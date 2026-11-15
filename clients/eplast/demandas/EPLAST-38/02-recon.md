# EPLAST-38 — Recon da org

**Data da coleta:** 2026-11-15 · **Org:** `sbx-eplast-dev` (Org ID 00DHa000006vfMLMAY, sandbox "eplast--qa" da Eplast, API v68.0). Confirmada com `sf org list` (única org conectada, Connected) e `sf org display`. Só leitura; retrieves em `/tmp/recon` (nada em `force-app/`). Nenhum registro lido, só metadata e `COUNT()`.

## 1. O que já cobre o pedido

| Item | Estado confirmado | Comando |
|---|---|---|
| Regra de atribuição `Distribuicao_Regional_Leads` (Lead) | `active=true`. Entradas por `Lead.State` igual a: SP -> `Leads_SP`; RJ -> `Leads_RJ`; MG -> `Leads_MG`; ES -> `Leads_ES`; PR,SC,RS -> `Leads_Sul`; GO,DF,MT,MS,TO -> `Leads_CO`; AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE -> `Leads_NO_NE`; última entrada **sem critério** -> `Leads_Triagem` (pega o resto, inclusive State vazio) | `sf project retrieve start -m AssignmentRules:Lead` e leitura do XML |
| 8 filas de Lead | `Leads_CO`, `Leads_ES`, `Leads_MG`, `Leads_NO_NE`, `Leads_RJ`, `Leads_SP`, `Leads_Sul`, `Leads_Triagem` | `SELECT DeveloperName, Type FROM Group WHERE Type='Queue' AND DeveloperName LIKE 'Leads%'` |
| Membros das filas | **0** (`COUNT()` de GroupMember das filas Leads%) | `SELECT COUNT() FROM GroupMember WHERE Group.Type='Queue' AND Group.DeveloperName LIKE 'Leads%'` |
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Ativo, versão 1 (única), AutoLaunched, record-triggered `RecordAfterSave`, Create, caminho `AsyncAfterCommit`. **Filtro de entrada:** `$Permission.Lead_DistribuicaoAutomaticaViaApi` verdadeira E `OwnerId` começa com `005` (dono usuário). Chama a ação Apex `LeadAssignmentService`. Sem e-mail. | `SELECT ... FROM Flow WHERE Definition.DeveloperName LIKE 'Lead%'` e retrieve do Flow |
| Classe `LeadAssignmentService` (API 68, `without sharing`) | `@InvocableMethod aplicarRegraPadrao(List<Id>)`: 1 SOQL e 1 DML em lote, `Database.DMLOptions` com `useDefaultRule=true`, `optAllOrNone=false`, ignora convertidos. Só `System.debug` em erro. Teste `LeadAssignmentServiceTest` existe (API 68) | `SELECT Name, ApiVersion FROM ApexClass WHERE Name LIKE 'LeadAssign%'` e retrieve da classe |
| Custom permission `Lead_DistribuicaoAutomaticaViaApi` | Existe. Concedida pelo permission set `PS_Integracao_DistribuicaoLead` (Label "PS Integracao Distribuicao Lead"), com **1** atribuição de usuário | `SetupEntityAccess` por CustomPermission; `COUNT()` de `PermissionSetAssignment` |
| Layout de Lead (`Lead-Lead Layout`) | `runAssignmentRulesDefault = true`: usuário de tela já roda a regra pela opção padrão do layout. Só há esse layout recuperado; outros layouts de Lead não foram checados | retrieve `Layout:Lead-Lead Layout` |
| `PriorityScore__c` (Lead) | Existe, fórmula de leitura. Descrição: score 0 a 100 = Setor (30) + Origem (30) + Status Contatado ou convertido (40). Somente leitura. EPLAST-26 | `SELECT DeveloperName, Description FROM CustomField` (Tooling) |
| `MKT_Origem_Agrupada__c` (Lead) | Existe, descrição cita EPLAST-39 (agrupa `LeadSource`, "Sem origem" / "Fora da lista") | idem |
| Campos Marketing Cloud em Lead | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` (só esses dois com prefixo `et4ae5`) | `FieldDefinition` com `QualifiedApiName LIKE 'et4ae5%'` |
| Objetos do conector `et4ae5` | 57 entradas na org (ex.: `et4ae5__Automated_Send__c`, `et4ae5__Business_Unit__c`, `et4ae5__Campaign_Member_Configuration__c`, `et4ae5__AggregateLink__c`). Uso de cada um por Lead não levantado | `sf sobject list` filtrado |
| List views de Lead | Existem `Leads abertos por prioridade`, `Leads Triagem`, `Leads SP`, `Leads RJ`, `Leads MG`, `Leads ES`, `Leads Centro-Oeste`, `Leads Norte e Nordeste`, `Leads Sul (PR, SC, RS)`, `Todos os leads Abertos` e outras | `SELECT Name, SobjectType FROM ListView WHERE SobjectType='Lead'` |
| Relatórios e painel | Pasta "MARKETING CLOUD" tem relatórios de Lead por região (`LEADS - CO`, `- ES`, `- MG`, `- RJ`, `- GERAL`, `- NÃO CONVERTIDOS`, `- SEGMENTO - ALIMENTOS`). Painel `Leads & Oportunidades`. Conteúdo e filtros não lidos | `SELECT Name, FolderName FROM Report WHERE Name LIKE '%Lead%'` / `Dashboard` |
| Agente Agentforce `SFAgent2` | Existem as versões `SFAgent2_v1` a `v6` (GenAiPlannerDefinition). Retrieve da v6: tópicos Off Topic, Agent Router, Ambiguous Question e `insights_comerciais`; ações locais incluem `IdentificarConta`, `AgregacaoPedidos` (rótulo "Query records with aggregate") e `ProximaAcaoCliente_EPLAST27`. Nenhuma ocorrência de "lead" nos arquivos da v6. A demanda não pede assistente | `SELECT MasterLabel, DeveloperName FROM GenAiPlannerDefinition`; retrieve `GenAiPlannerBundle:SFAgent2_v6`; `grep -ril lead` |

Conclusão do levantamento: roteamento por UF, filas, Flow, ponte Apex, score e list views já existem. O que falta na org é membro nas filas.

## 2. O que será tocado

| Objeto / campo | Tipo e situação | Comando |
|---|---|---|
| `Lead.State` | Campo padrão, critério da regra. Se a org usa State/Country picklist (valores `SP`, `RJ`) ou texto livre **não foi confirmado** | não confirmado, ver seção 6 |
| `Lead.OwnerId` | Resultado do roteamento (fila `00G` ou usuário `005`) | leitura do Flow e da classe |
| `Lead.PriorityScore__c` | Fórmula, tem descrição | seção 1 |
| `Lead.Sector__c` | Existe, **sem descrição** (campo de entrada do score) | `CustomField` Tooling, `DeveloperName='Sector'` |
| `Lead.MKT_Origem_Agrupada__c`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | Leitura pelo Marketing Cloud (seção 6 da análise). Nenhum campo novo identificado como necessário | seção 1 |

## 3. Automação concorrente em Lead

| Item | Achado | Comando |
|---|---|---|
| Triggers de Lead | **Nenhum** | `SELECT Name FROM ApexTrigger WHERE TableEnumOrId='Lead'` |
| Flows com objeto Lead | 1 ativo: `Lead_AfterInsert_AplicaRegraAtribuicao`. Os demais Flows ativos AutoLaunched listados (Opportunity, Order, Quote, Account, Task, `MCC_*`) não têm prefixo Lead. **Não abri o objeto de cada `MCC_*`** (ver seção 6) | `SELECT Definition.DeveloperName FROM Flow WHERE Status='Active' AND ProcessType='AutoLaunchedFlow'` |
| Validation rules de Lead | 2 ativas: `Celular` ("O formato do Celular deve ser: (xx)xxxxxxxx ou (xx)xxxxxxxxx") e `Telefone` ("O formato do telefone deve ser: (xx)xxxxxxxx"). Podem barrar Lead de teste com telefone fora do formato; o design e o dado de teste devem respeitar | retrieve `ValidationRule:Lead.Celular` e `Lead.Telefone` |
| Regra de atribuição | 1 ativa (`Distribuicao_Regional_Leads`) | seção 1 |
| **Ordem de execução (leitura do metadata, não executada)** | (a) Criação por tela, ou API com cabeçalho de atribuição: a regra roda na própria transação, o dono já nasce fila; o Flow **não entra** (usuário de tela não tem a custom permission, e o dono não é `005`). (b) Criação por integração com a permission e sem cabeçalho: o Lead nasce com dono usuário, o Flow dispara no caminho assíncrono pós-commit, a classe faz `update` com a regra e o dono muda para a fila. **A regra, portanto, é a única fonte do dono; o Flow só pede que ela rode.** O risco "duas fontes de dono" levantado na análise não aparece no metadata. Também não há automação de Lead que dispare e-mail (CA-07 sem ocorrência no Flow e na classe lidos) | leitura do XML do Flow e da classe |
| Account / Opportunity / Order com CPQ (SBQQ) | Não tocados por esta demanda; triggers de Account: `AccountBefore`, `AccountTrigger`. Fora do escopo do pedido, não mapeei a ordem entre eles | `SELECT Name FROM ApexTrigger WHERE TableEnumOrId IN (...)` |

## 4. Volume e dados de teste

| Objeto | Registros na dev | Comando |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Account, Contact, Opportunity, Order | 0 em todos | `SELECT COUNT() FROM <objeto>` |
| Campaign, CampaignMember | 0 | idem |
| Membros das filas de Lead | 0 | seção 1 |

A dev não tem dado: todo teste usa Lead criado pelo agente (`fixtures/`, regra 6). Teste de 200 Leads (CA-06) é viável só com dado criado. Usuário de teste da regra 6 (conta de serviço da Konecta): o Id **não foi resolvido nesta sessão** (ver seção 6).

## 5. Permissões

| Item | Achado | Comando |
|---|---|---|
| OWD de Lead | Interno `ReadWriteTransfer`, externo `Private` | `SELECT ExternalSharingModel, InternalSharingModel FROM EntityDefinition WHERE QualifiedApiName='Lead'` (Tooling) |
| Quem recebe a custom permission | Só o permission set `PS_Integracao_DistribuicaoLead`, 1 atribuição | seção 1 |
| Perfis e permission sets com acesso ao objeto Lead (CRUD/FLS) | **Não levantado** | ver seção 6 |

## 6. O que não consegui confirmar

- **Id do usuário de teste** (da conta de serviço da Konecta, regra 6): não rodei a consulta de User nesta sessão. O verificador resolve na org do job.
- **Cobertura Apex real** de `LeadAssignmentService`: não medida. Só confirmei que a classe de teste existe.
- **Tipo do campo `State`** (picklist de estado ou texto) e quais valores aceita: a regra compara com siglas, mas não verifiquei se a org aceita essas siglas na criação.
- **Quem criou a regra, as filas, o Flow e a classe**: o texto cita EPLAST-35, mas não confirmei contra o histórico da demanda. Esses componentes seguem sem versão no repositório (não conferi `force-app` nesta sessão; a análise afirma que não estão).
- **Se `MCC_*` ou outros Flows ativos têm objeto Lead**: filtrei só por nome. Flows com outro prefixo podem tocar Lead.
- **Versão ativa do `SFAgent2`**: há v1 a v6, não confirmei qual está ativa. A v6 traz a ação `ProximaAcaoCliente_EPLAST27` além das 3 do `CLAUDE.md` (diferença registrada, não analisada).
- **Estado da QAS (`sbx-eplast-qa`)**: não comparei metadata entre dev e QA (só `sbx-eplast-dev` conectada); divergência desconhecida.
- **Perfis e permission sets com acesso a Lead** e conteúdo dos relatórios `LEADS - <região>`: não levantados.
- **Comportamento em execução** (CA-04, dono informado não sobrescrito; CA-06, 200 Leads): só li o metadata, nenhum teste rodou. O layout com `runAssignmentRulesDefault=true` e a regra sem critério de dono indicam que a regra **pode** sobrescrever dono informado em criação por tela; precisa ser provado no teste.
- **Outros layouts de Lead** e o `runAssignmentRulesDefault` neles.
