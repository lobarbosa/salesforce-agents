# EPLAST-35 — Recon da org (rodada 2, redesenho com as respostas de 17/11)

Só leitura (metadata e contagens agregadas), em 2026-11-17. Não decide solução. Substitui o recon de 2026-11-15.

**Org conferida:** alias `sbx-eplast-dev` (única org listada por `sf org list`, status Connected), sandbox da Eplast `eplast--qa`, que a regra 5 do CLAUDE.md do cliente define como a DEV da esteira. Retrieve feito em diretório temporário fora do repositório, já descartado.

**Foco desta rodada** (respostas do cliente no fim de `03-design.md`): regionais com RJ+ES juntas, rodízio dentro da região, respeitar conta com proprietário, e não construir aprovação nem encaminhamento interno.

## 1. O que já cobre o pedido

A DEV já tem o build da rodada anterior (distribuição regional). O recon não distingue, na org, o que veio da EPLAST-35 do que veio da EPLAST-38 (ver seção 5).

| Item | Status | Fato confirmado | Comando |
|---|---|---|---|
| 3 Approval Processes | Existem, ativos | `Opportunity.FinancialAnalysis`, `Quote.AssignPricing`, `Order.LiberationFinancial` | `sf org list metadata -m ApprovalProcess` |
| Relatórios `Histrico_de_Aprovao_XNR` e `Aprovacoes_Pendentes_Por_Processo` (pasta Geral) | Existem | os dois aparecem na org | `SELECT DeveloperName, FolderName FROM Report WHERE ...` |
| Regra de atribuição de Lead `Distribuicao_Regional_Leads` | Existe, ativa | 8 entradas por `Lead.State` igual a: SP; RJ; MG; ES; PR,SC,RS; GO,DF,MT,MS,TO; AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE; sem critério (Triagem). **Diverge da resposta:** RJ e ES estão em entradas e filas separadas | `sf project retrieve start -m AssignmentRules:Lead` |
| Filas de Lead | Existem 8 | `Leads_SP`, `Leads_RJ`, `Leads_MG`, `Leads_ES`, `Leads_Sul`, `Leads_CO`, `Leads_NO_NE`, `Leads_Triagem`. Existe também `PosVendas`, fora desta demanda. **0 membros em qualquer fila** | `SELECT DeveloperName FROM Group WHERE Type='Queue'`; `SELECT COUNT() FROM GroupMember WHERE Group.Type='Queue'` |
| Fila para RJ+ES juntas | Não existe | só `Leads_RJ` e `Leads_ES` | idem |
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Existe, ativo | record-triggered, after save, Create, chama a ação `LeadAssignmentService`, API 68.0, versão ativa modificada em 2026-11-15 | Tooling `FlowDefinition`; retrieve |
| Classe `LeadAssignmentService` e `LeadAssignmentServiceTest` | Existem, Active | `without sharing`, `useDefaultRule = true`, um `Database.update(leads, options)`; sem trigger em Lead | Tooling `ApexClass`; leitura do `.cls` |
| Custom permission `Lead_DistribuicaoAutomaticaViaApi` e permission set `PS_Integracao_DistribuicaoLead` | Existem | PS habilita a classe e a custom permission; **1 atribuição** do PS | retrieve; `COUNT()` em `PermissionSetAssignment` |
| Layout `Lead-Lead Layout` | Existe | `runAssignmentRulesDefault = true` (já alterado) | retrieve |
| Histórico de campo em Lead | Existe | `OwnerId` e `Status` com `IsFieldHistoryTracked = true`; `CompanyDocument__c` false | Tooling `FieldDefinition` |
| Rodízio (round robin) | Não existe | nenhuma classe custom com nome Round/Rodizio/Distrib (só `LeadAssignmentService*`); regra de atribuição nativa só atribui a fila ou usuário fixo; sem objeto ou metadata de rodízio na lista de objetos custom | Tooling `ApexClass LIKE`; `sf org list metadata -m CustomObject` |
| Configuração de elegíveis por região (nomes, lista) | Não existe | não há objeto custom nem custom metadata type de região ou elegíveis. Existem `__mdt` de outras demandas (`CampaignSuggestionSetting__mdt`, `NextBestActionSetting__mdt`, `RankingRange__mdt`, `CommercialSignalSetting__mdt`, `AlertaOportunidadeParadaSetting__mdt`, `ScheduledFlowOpportunitySetting__mdt`, `AssistenteTarefaSetting__mdt`) e `TriggerUtility__mdt`, `Protheus__mdt`; nenhum é de região | `sf org list metadata -m CustomObject` |
| Territory Management (`Territory2`) | Não habilitado | `Territory2Model` "not supported" | `sf data query` |
| Omni-Channel | Não confirmado | consulta de `ServiceChannel` não retornou saída utilizável | ver seção 6 |
| Salesforce Maps (`maps__AssignmentRule__c`) | Existe o pacote, 0 registros (recon anterior) | não reconfirmado | — |
| Agente `SFAgent2` | Existe | `Bot` e planners `SFAgent2_v14` e `SFAgent2_v16` listados (era v4 no recon anterior). A demanda não pede assistente; nada a estender | `sf org list metadata -m Bot`, `-m GenAiPlannerBundle` |

## 2. O que será tocado

| Objeto / campo | Tipo | Fato | Comando |
|---|---|---|---|
| `Lead.State` | string 80, texto livre (sem picklist de estado) | Hoje é o critério da régua. Valor por extenso, minúsculo ou vazio cai na Triagem. Dos 4 Leads da DEV, os 4 têm `State` nulo | describe; `SELECT State, COUNT(Id) FROM Lead GROUP BY State` |
| `Lead.Country` | string 80, texto livre | Sem picklist | describe |
| `Lead.CompanyDocument__c` (CNPJ) | string 18, não único, não externalId | Sem descrição verificada (não medi). Histórico de campo desligado | describe |
| `Lead.CompanyName__c` (Razão Social), `Lead.Company` | string 255 | Existem | describe |
| `Account.CompanyDocument__c` (CNPJ) | string 18, **externalId = true, unique = false** | Pode haver mais de uma conta com o mesmo CNPJ | describe |
| `Account.OwnerId`, `Account.BillingState` | reference; string 80 | Existem | describe |
| Campo de região/território em Lead ou Account | Não existe | só `State`/`BillingState`; não inferi equivalência | describe |
| Formato do CNPJ (com ou sem máscara) | Desconhecido | Account tem 0 CNPJ preenchido; Lead tem 0. Sem amostra para ver o formato. Length 18 sugere máscara `00.000.000/0000-00`, mas é só o tamanho do campo | `SELECT COUNT() ... WHERE CompanyDocument__c != null` (0 e 0) |
| `Lead.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__Mobile_Country_Code__c` | Existem (conector Marketing Cloud Connect) | Só esses 2 campos `et4ae5` em Lead. Não há mudança de Marketing nesta rodada | Tooling `FieldDefinition LIKE 'et4ae5%'` |
| Validation rules de Lead | 2 ativas: `Celular`, `Telefone` | Exigem formato de telefone na criação de Lead de teste | Tooling `ValidationRule` |
| Record types de Lead | 0 | Sem record type | `SELECT COUNT() FROM RecordType WHERE SobjectType='Lead'` |

## 3. Automação concorrente e ordem de execução

| Objeto | Automação | Fato | Comando |
|---|---|---|---|
| Lead | Trigger custom | Nenhum | Tooling `ApexTrigger` |
| Lead | Flow | Só `Lead_AfterInsert_AplicaRegraAtribuicao` encontrado. Os demais Flows com "Lead" no nome são do pacote `trailheadapp`. **Flows de Lead com outro nome não foram descartados** (a consulta ao tipo de gatilho do Flow não é suportada) | `sf org list metadata -m Flow` (55 Flows) |
| Lead | Regra de atribuição | `Distribuicao_Regional_Leads` ativa; roda quando o salvamento pede (caixa do layout agora marcada por padrão, ou cabeçalho da API) | retrieve |
| Lead | Validation rules | `Celular`, `Telefone` | Tooling |
| Account | Trigger custom `AccountTrigger` | before/after insert e update, Active. Integração Protheus (regra do CLAUDE.md do cliente): conta inserida ou atualizada enfileira `UpdateAccountCompanyInfo` ou `SendAccountToProtheus`, um job por conta | Tooling `ApexTrigger`; CLAUDE.md do cliente |
| Account | Trigger do pacote `AccountBefore` (SBQQ) | Existe (recon anterior) | não reconfirmado hoje |

Consequência para esta rodada: ler `Account` (por CNPJ, para achar o dono) não dispara a `AccountTrigger`; só gravar dispara. Nenhuma gravação em `Account` é necessária para os pedidos de 17/11. Ordem de execução de Opportunity, Order e Quote não importa mais (não serão tocados).

## 4. Volume e dados de teste

| Objeto | Contagem | Comando |
|---|---|---|
| Lead | 4 (todos com `State` nulo, nenhum com CNPJ, nenhum em fila; donos são usuários) | `SELECT COUNT() FROM Lead` e variações |
| Account | 2 (nenhuma com `CompanyDocument__c`) | `SELECT COUNT() FROM Account` |
| Membros de fila (Lead) | 0 | `SELECT COUNT() FROM GroupMember WHERE Group.Type='Queue'` |
| Usuários ativos Standard | 19: Administrador do sistema 9, Comercial - Analista 4, Financeiro 1, 5 de integração/analytics | `SELECT Profile.Name, COUNT(Id) FROM User ... GROUP BY Profile.Name` |
| Usuário de teste da Konecta (conta de serviço, filtro por username conforme regra 6 do CLAUDE.md do cliente) | 2 linhas: `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo, perfil Administrador do sistema). Usar o ativo | `SELECT Id, IsActive, Profile.Name FROM User WHERE Username LIKE <filtro da regra 6>` |

A DEV tem dado para testar a casagem lead x conta só se o build criar fixtures (`clients/eplast/fixtures/` **não existe** no repositório; o README citado na regra 6 não está lá). Conta de teste criada pela tela passa pela `AccountTrigger`; o desvio é `TriggerUtility.bypassTrigger` (CLAUDE.md do cliente).

## 5. Permissões e conflitos com outras demandas

| Item | Fato | Comando |
|---|---|---|
| OWD Lead | `ReadEditTransfer` (público leitura/gravação/transferência) | `SELECT DefaultLeadAccess FROM Organization` |
| OWD Account | `Edit` (público leitura/gravação) | idem |
| `PS_Integracao_DistribuicaoLead` | habilita `LeadAssignmentService` e a custom permission; 1 atribuição | retrieve; `COUNT()` |
| Perfil comercial | `Comercial - Analista` (4 usuários ativos) | `GROUP BY Profile.Name` |

**Conflitos declarados pelo preflight (não alterei nada):**

| Demanda | Componentes em comum | Observação |
|---|---|---|
| EPLAST-38 (aguardando_homologacao) | `assignmentRules/Lead`, `LeadAssignmentService`, `LeadAssignmentServiceTest`, `Lead_DistribuicaoAutomaticaViaApi`, `Lead_AfterInsert_AplicaRegraAtribuicao`, `PS_Integracao_DistribuicaoLead`, layout `Lead-Lead Layout`, filas `Leads_*` e `Leads_Triagem` | É praticamente toda a distribuição de Lead que a org tem. Qualquer mudança na regra, nas filas ou no Flow nesta rodada colide com o que a EPLAST-38 está homologando. O arquiteto precisa decidir a quem pertencem e como sequenciar (versão nova antes de editar o que está ativo) |
| EPLAST-26 (aguardando_gate_design) | `layouts/Lead-Lead Layout` | Só o layout. Esta rodada não precisa mexer nele (a caixa de atribuição já está marcada) |

## O que não consegui confirmar

1. **Quem é o dono de cada componente na org** (EPLAST-35 da rodada anterior ou EPLAST-38). Nomes e datas coincidem com o design anterior da 35, e o preflight lista os mesmos na 38. A org não registra a demanda de origem.
2. **Outros Flows de Lead.** Só filtrei os 55 Flows por nome; um Flow de Lead com outro nome ficaria de fora. Tipo de gatilho do Flow não é consultável por `sf data query` nesta versão.
3. **Formato do CNPJ** em Lead e Account (máscara ou só dígitos), e se há CNPJ repetido entre contas: 0 registros com CNPJ na DEV, e não leio o valor (guardrail #2). A QAS (Partial Copy) tem dado real; só contagem agregada lá, e nesta etapa só toquei a DEV.
4. **Omni-Channel** (consulta de `ServiceChannel` sem retorno utilizável) e **Salesforce Maps** (`maps__AssignmentRule__c` não recontado hoje). Não sei se há licença ou configuração que sirva a rodízio.
5. **Quem são os elegíveis por região**: nenhuma fila tem membro, e a Eplast ainda vai informar os nomes.
6. **Descrição dos campos custom de Lead** (assessment cita 68% sem descrição em Account, Order e Opportunity; Lead não foi medido).
7. **Trigger `AccountBefore` do SBQQ** em Account: vem do recon anterior, não reconfirmado hoje.
