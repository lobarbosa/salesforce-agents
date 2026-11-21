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

---

# Adendo (2026-11-17, após a decisão do gate: sem Apex, rodízio por Flow com Auto Number)

Só leitura, `sbx-eplast-dev` (única org do `sf org list`, Sandbox, Connected, a `eplast--qa` da Eplast = DEV da esteira, regra 5). Retrieve em diretório temporário fora do repositório, já apagado. Complementa as seções acima; onde divergir, vale este adendo.

## A. O que a decisão do gate precisa e a org mostra

| Item | Fato confirmado | Comando |
|---|---|---|
| Campo Auto Number em Lead | **Não existe.** Nenhum campo Auto Number em Lead (nem reaproveitável). Campos custom de Lead hoje: `CNAE__c`, `CompanyDocument__c`, `CompanyName__c`, `Facebook__c`, `Instagram__c`, `LinkedIn__c`, `Subsector__c`, `WhatsApp__c`, `Sector__c`, `PriorityScore__c` (fórmula), `PriorityBand__c` (fórmula), `MKT_MC_EngajamentoData__c`, `MKT_MC_Engajamento__c`, `MKT_Nutricao_Elegivel__c` (fórmula), `MKT_Nutricao_ProntoAbordagem__c` (fórmula), mais `et4ae5__*` (2) e `maps__AssignmentRule__c` | `sf sobject describe -s Lead` filtrando custom/autoNumber/calculated; `FieldDefinition DataType LIKE 'Auto%'` (0) |
| Convenção de nome de campo em Lead | Sem prefixo único: campos antigos sem prefixo (`CompanyDocument__c`), os de marketing com `MKT_`. Não há regra de prefixo no CLAUDE.md do cliente (campo vazio). O arquiteto escolhe o nome | describe; CLAUDE.md do cliente |
| Fórmula que normaliza CNPJ (só dígitos) em Lead ou Account | **Não existe.** Nenhum campo de fórmula de CNPJ nos dois objetos | describe de Lead e Account (`calculated`, nome com CNPJ/CompanyDocument) |
| `Lead.CompanyDocument__c` | string 18, não único, não externalId, sem máscara de entrada (`inputMask` ausente no metadata) | retrieve `CustomField:Lead.CompanyDocument__c` |
| `Account.CompanyDocument__c` | string 18, externalId = true, unique = false, sem `inputMask` | retrieve `CustomField:Account.CompanyDocument__c` |
| Validation rule que force formato de CNPJ | **Nenhuma.** Account tem 6 VRs ativas (`Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk`); nenhuma cita CNPJ no nome. Lead tem `Celular` e `Telefone`. **Não li as fórmulas das VRs de Account** | Tooling `ValidationRule` (nome); busca de `CompanyDocument__c` em VRs no retrieve falhou (VR por objeto não recuperável com esse seletor) |
| Formato real do CNPJ | **Não confirmável na DEV:** 0 Leads e 0 Accounts com CNPJ preenchido (e 0 hoje em `Account` com qualquer valor relevante: Account = 2). Length 18 admite a máscara, sem nada que a imponha; os dois formatos podem coexistir. Verificação na QAS (Partial Copy) exigiria agregado por padrão de formato, e esta etapa só tocou a DEV | `SELECT COUNT()` (Lead 4, Account 2, ambos 0 com CNPJ) |
| `DistribuicaoLeadSetting__mdt` | **Não existe** na DEV (nenhum `CustomObject` com Distribuicao/Rodizio). Pode nascer no build | `sf org list metadata -m CustomObject` + filtro |
| Classe de rodízio | **Não existe** (só `LeadAssignmentService` e `LeadAssignmentServiceTest`, Active, API 68). Sem classe nova, nenhum `LeadRodizioService` a considerar | Tooling `ApexClass LIKE 'LeadAssignment%'` |

## B. Flows de Lead e ordem de execução (revalidado)

| Item | Fato | Comando |
|---|---|---|
| Flows com Lead como objeto de gatilho | Dos 35 Flows custom recuperados (de 52 com versão ativa; o restante é de pacote gerenciado), só `Lead_AfterInsert_AplicaRegraAtribuicao` é gatilho em Lead: `RecordAfterSave`, `Create`, API 68.0, **Active**, chama a ação `LeadAssignmentService`. `Task_Agente_CriarTarefa` cita Lead só como leitura e está **Obsolete** (gatilho em Task). Flow de pacote em Lead não foi inspecionado | retrieve `Flow` + grep em `<object>Lead</object>`; `SELECT ... FROM Flow WHERE Status='Active' AND MasterLabel LIKE '%Lead%'` (1) |
| Trigger Apex em Lead | Nenhum | Tooling `ApexTrigger` (recon acima) |
| Efeito em cadeia a observar (fato, não solução) | O Flow ativo chama `LeadAssignmentService`, que grava o Lead (`Database.update` com a regra padrão). Essa gravação muda `OwnerId` dentro da transação de criação; um Flow novo em "criação e atualização" com `ISCHANGED(OwnerId)` entraria de novo nessa mesma transação. Ordem entre dois Flows after-save do mesmo objeto não é garantida pela plataforma (ordem configurável só para Flows `before-save`/`after-save` com a opção "Trigger Order" da API recente, **não conferi se está disponível/usada nesta org**) | leitura do Flow e do `.cls` |
| Limites em lote de 200 | Não testável com 0 membros de fila e sem Auto Number. Cada Lead recebe um número diferente, então não há estado a ler por interview; porém a contagem de membros e a escolha do N-ésimo membro num Flow em lote dependem de loop/coleção. Não medi consultas ou DML por transação | sem comando (exige build) |
| Leitura de membros de fila por Flow | **Não confirmado** que `GroupMember` fica disponível em "Get Records" na org nem que o Flow consegue ordenar e indexar o N-ésimo membro. Nenhum Flow atual da org lê `GroupMember` (grep por `<object>GroupMember</object>` nos 35 Flows: 0) — sem precedente local | grep nos Flows recuperados |

## C. Dados e usuário de teste (revalidado)

| Item | Fato | Comando |
|---|---|---|
| Lead / Account / membros de fila | 4 / 2 / 0 | `SELECT COUNT()` |
| OWD Lead | `ReadEditTransfer` | `SELECT DefaultLeadAccess FROM Organization` |
| Usuário de teste da Konecta | Ativo: `005bJ00000piKAaQAM` (Administrador do sistema); o outro, `005bJ00000hBJmYQAW`, está inativo. Não alterei perfil, permissão nem papel | `SELECT Id, IsActive, Profile.Name FROM User WHERE Username LIKE <filtro da regra 6 do CLAUDE.md do cliente>` (seção 4 acima) |
| Fixtures | `fixtures/` do cliente não existe no repositório (seção 4 acima); a EPLAST-38 cria `lead_roteamento_regional.apex` no branch dela (informação do design) | não reconfirmado hoje |

## D. Sobreposição com outras demandas (do preflight, sem mudança)

| Demanda | Componentes comuns | Consequência para esta rodada |
|---|---|---|
| EPLAST-38 (aguardando_homologacao) | `assignmentRules/Lead`, `LeadAssignmentService`, `LeadAssignmentServiceTest`, `Lead_DistribuicaoAutomaticaViaApi`, `Lead_AfterInsert_AplicaRegraAtribuicao`, layout `Lead-Lead Layout`, `PS_Integracao_DistribuicaoLead`, filas `Leads_*` | Nenhum desses pode ser alterado no lugar. A regra v2 é versão nova (inativa), a fila `Leads_RJ_ES` é nova, o Flow de rodízio é novo e não substitui o ativo. Membros em `Leads_*` e o `Lead-Lead Layout` seguem de outra demanda |
| EPLAST-26 (aguardando_gate_build) | `layouts/Lead-Lead Layout` | O campo Auto Number novo não precisa ir ao layout (campo técnico); se o arquiteto o puser no layout, colide com 26 e 38 |

## E. Itens do assessment que tocam esta rodada

- Automação concorrente: só em Account/Opportunity/Order; esta rodada não grava nelas. Em Lead há um Flow (acima).
- Cobertura Apex 10%: motivo da decisão de não criar Apex; nada novo a testar em classe.
- 153 campos custom sem descrição: o campo Auto Number novo e os do CMDT saem com `Description`.
- Integração Protheus (`AccountTrigger`): ler Account não dispara; o Flow só pode **ler** Account (Get Records), nunca gravar. Defeito de `UpdateAccountCompanyInfo` não é desta demanda e não é tocado.
- Marketing Cloud Connect (`et4ae5`): em Lead só `et4ae5__HasOptedOutOfMobile__c` e `et4ae5__Mobile_Country_Code__c`; esta rodada não toca marketing e não usa nenhum campo `et4ae5`. Campos `MKT_*` de Lead existem (nutrição/engajamento) e não são lidos nem alterados aqui.

## Não consegui confirmar (adendo)

1. **Formato real do CNPJ** em Lead e Account: 0 preenchidos na DEV; QAS não consultada. Nada na org impõe máscara, então os dois formatos podem divergir.
2. **Fórmulas das 6 VRs de Account** (se alguma altera o CNPJ): só li os nomes.
3. **Se `GroupMember` é consultável em Get Records de Flow** e se o Flow consegue contar membros e escolher o N-ésimo em ordem fixa: sem precedente na org; exige protótipo no build.
4. **Limites do Flow em lote de 200 Leads** (SOQL/DML) com a leitura de fila, a busca de conta por CNPJ e a gravação do dono: não medi.
5. **Ordem entre Flows after-save de Lead** e re-disparo por `OwnerId` gravado pela regra/`LeadAssignmentService`: não testei; "Trigger Order" não conferido.
6. **Flows de pacote gerenciado em Lead**: não inspecionados.
7. **Se Auto Number permite numeração com início/formato que sirva ao resto da divisão** (campo Auto Number é texto no Salesforce; a conversão para número no Flow não foi testada).
8. Itens 1, 2, 4, 6 e 7 da lista anterior seguem em aberto (dono dos componentes entre 35 e 38, Omni-Channel e Maps, quem são os elegíveis, descrição dos campos de Lead, `AccountBefore`).

## Confirmações do arquiteto (2026-11-17, etapa de design)

Só os pontos que mudavam a decisão. `sbx-eplast-dev`, nada implantado (validação `--dry-run`, `checkOnly = true`), diretório temporário fora do repositório já apagado.

| Item | Fato | Comando |
|---|---|---|
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (v1, Active, API 68) | `RecordAfterSave`, `Create`, sem `triggerOrder`; entrada `AND($Permission.Lead_DistribuicaoAutomaticaViaApi, LEFT($Record.OwnerId,3)="005")`; parte síncrona vazia, ação `LeadAssignmentService` só no caminho `AsyncAfterCommit` | Tooling `SELECT ... Metadata FROM Flow WHERE Definition.DeveloperName=... AND Status='Active'` |
| Workflow Rules em Lead | **0.** As 17 Workflow Rules da org são de objetos `et4ae5__*` | Tooling `SELECT TableEnumOrId, COUNT(Id) FROM WorkflowRule GROUP BY TableEnumOrId` |
| Viabilidade declarativa (itens 3 e 7 do adendo) | A validação aceitou um campo Auto Number em Lead (`displayFormat {0}`) e um Flow record-triggered `RecordAfterSave` `CreateAndUpdate` com `triggerOrder` (nível do Flow), entrada `OR(ISNEW(), ISCHANGED(OwnerId))`, Get Records em `GroupMember` (filtro `GroupId`, `UserOrGroupId` começa com `005`, ordenado), Get Records em `User` com `Id In` coleção, Get Records em `Account` com `CompanyDocument__c = a OR = b`, fórmula `MOD(VALUE(<auto number>), n)` e Update de `$Record.OwnerId`. Compila; comportamento em execução (lote de 200, dono gravado pela regra) **não** foi exercitado | `sf project deploy start --dry-run` |
