# EPLAST-35 — Recon da org

Levantamento só de leitura (metadata e `COUNT()`), em 2026-11-15. Não decide solução.
Fontes: `sf org list`, `sf org list metadata`, `sf data query` (com e sem `-t`), `sf sobject describe`, `sf project retrieve start` num diretório temporário fora do repositório. O pedido é de aprovação, distribuição de Leads e encaminhamento (ver `01-analise.md`). Nenhuma resposta às dúvidas D1 a D12 chegou nos comentários do card.

## 0. Org confirmada

| Item | Valor | Comando |
|---|---|---|
| Alias | `sbx-eplast-dev` (única org listada; `sbx-eplast-qa` NÃO aparece) | `sf org list` |
| Tipo | Sandbox (`IsSandbox = true`), instância BRA8S | `sf data query ... FROM Organization` |
| URL | `https://eplast--qa.sandbox.my.salesforce.com` (o nome da sandbox é `qa`) | `sf org display` |
| API da org | 68.0 (o briefing dizia v67) | `sf org display` |

## 1. O que já cobre o pedido

| Frente | O que existe | Cobre? | Prova |
|---|---|---|---|
| Aprovação | 3 Approval Processes ativos: `Opportunity.FinancialAnalysis`, `Order.LiberationFinancial`, `Quote.AssignPricing` | Parcial, no motor nativo | `sf org list metadata -t ApprovalProcess`; retrieve |
| Aprovação, `Opportunity.FinancialAnalysis` | Entrada: `StageName = Análise Financeira`. 1 etapa, aprovadores são usuários nomeados (2). Ações finais: alertas e field updates (`Atualizar_Fase_Fechado_Perdido`, `Atualizar_Motivo_de_Perda`). `allowRecall=false` | Aprova por etapa do funil, não por desconto | retrieve do XML |
| Aprovação, `Order.LiberationFinancial` | 1 etapa, mesmos 2 aprovadores, cria Task `FinancialBlock`, field updates `ChangeStatusStock` e `ChangeStatusReview` | Liberação financeira de pedido | retrieve do XML |
| Aprovação, `Quote.AssignPricing` | 1 etapa, 1 aprovador usuário. Field updates `SubmittedApproval` e `SubmittedApproval2`. Último ajuste 2026-08-31 | Aprovação do Pricing na cotação CPQ | retrieve do XML |
| Alçada por desconto | Nenhum processo, validation rule ou Flow com critério de desconto encontrado. Existem campos de desconto do CPQ (`SBQQ__QuoteLine__c.SBQQ__Discount__c`, `SBQQ__Quote__c.SBQQ__CustomerDiscount__c`, entre outros). `Opportunity` não tem campo de desconto, aprovação ou margem | Não | describe; retrieve |
| Distribuição de Lead | `AssignmentRules` de Lead existe, mas o XML recuperado é um conjunto **vazio** (sem `ruleEntry`). A de Case não foi inspecionada | Não (sem regra) | `sf org list metadata -t AssignmentRules`; retrieve |
| Distribuição de Lead, automação | Nenhum trigger custom, nenhum Flow custom ativo e nenhuma validation rule de automação em Lead. Só as VRs `Lead.Celular` e `Lead.Telefone` (formato de telefone) | Não | Tooling `ApexTrigger`, `Flow`; `list metadata -t ValidationRule` |
| Filas | 0 Groups `Type='Queue'`. Groups existentes: 2 Regular, 2 Role, 2 RoleAndSubordinatesInternal, 1 Organization, 18 ManagedContentSpaceRole. Agora confirmado: não há filas na dev | Não | `SELECT Type, COUNT(Id) FROM Group GROUP BY Type` |
| Encaminhamento | Nada identificado. O termo "demanda" continua indefinido (D6). `Case` tem `AssignmentRules` e 0 registros | Não | Idem |
| Agente `SFAgent2` | Existe `Bot SFAgent2` (v4) com o planner `SFAgent2_v4`. Tópicos encontrados: `insights_comerciais`, `agent_router`, `ambiguous_question`, `off_topic`. Ações: `ConsultarPedidos` (`queryRecords`), `AgregacaoPedidos` (`queryRecordsWithAggregate`), `IdentificarConta` (`identifyRecordByName`). Só consulta de pedidos e conta. Não toca aprovação, Lead nem encaminhamento | Não (consulta apenas) | retrieve `Bot`, `GenAiPlannerBundle` |
| Relatórios e painéis | **Não levantados** (ver seção final) | ? | — |

Observação: `CLAUDE.md` do cliente diz 4 tópicos. O planner traz 4 (`insights_comerciais`, `agent_router`, `ambiguous_question`, `off_topic`) e 3 ações. Coincide.

## 2. O que será tocado

| Objeto | Campos e fatos relevantes confirmados | Prova |
|---|---|---|
| `Lead` | Standard: `OwnerId`, `Status`, `LeadSource`, `Rating`. Custom: `CNAE__c`, `CompanyDocument__c`, `CompanyName__c`, `Sector__c`, `Subsector__c`, `WhatsApp__c`, `Facebook__c`, `Instagram__c`, `LinkedIn__c`. Conector: `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`. Pacote Maps: `maps__AssignmentRule__c`. OWD interno `ReadWriteTransfer` | describe; consulta de `InternalSharingModel` |
| `Lead.Status` (ativos) | `Aberto - Não contatado`, `Contatado`, `Fechado - Convertido`, `Fechado - Não convertido` | describe |
| `Lead.LeadSource` (ativos) | Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR | describe |
| `Lead.Rating` | AA, A, B, C, D | describe |
| Território, região, produto, capacidade no `Lead` | **Nenhum campo com esse nome**; só `Sector__c` e `Subsector__c`. Não inferi equivalência | describe |
| `Opportunity` | Etapas ativas: Qualificação, Análise Técnica, Precificação, Qualificado, Cotação, Execução técnica do projeto, Envio Cotação, Amostra, Análise Fiscal, Análise Financeira, Negociação Comercial, Fechado/Ganho, Fechado/Perdido. OWD `Read` | describe |
| `SBQQ__Quote__c` e `SBQQ__QuoteLine__c` | Campos de desconto do CPQ (ver seção 1). OWD da cotação `ReadWrite` | describe |
| `Order` | OWD `ReadWrite` | consulta |

Descrição dos campos custom: não levantada campo a campo (assessment cita 68% sem descrição em Account, Order e Opportunity). Lead não foi medido.

## 3. Automação concorrente e ordem de execução

Custom (sem namespace):

| Objeto | Trigger custom | Eventos | API | Prova |
|---|---|---|---|---|
| Account | `AccountTrigger` | before e after insert, before e after update | 58 | Tooling `ApexTrigger` |
| Opportunity | `OpportunityTrigger` | after insert, after update | 59 | idem |
| Order | `OrderTrigger` | before update, after update | 59 | idem |
| Lead | nenhum | — | — | idem |

Triggers do pacote SBQQ nos mesmos objetos: `AccountBefore` (Account), `OpportunityBefore` e `OpportunityAfter` (Opportunity), `OrderTrigger` (Order, mesmo nome do custom em outro namespace), `QuoteBefore` e `QuoteAfter` (Quote). Nenhum trigger de pacote encontrado em Lead.

Flows custom ativos por objeto de disparo (retrieve; status Active):

| Objeto | Flow | Tipo de disparo |
|---|---|---|
| Account | `PaymentTermAccount` | before delete |
| Account | `SetPaymentTermsChangesinAccount` | after save, create |
| Account | `TaskCreatedOrUpdated` | after save, create e update |
| Account | `UpdateParentAccountUsedLimit` | after save, create e update |
| Opportunity | `Order` (o nome engana: o objeto é Opportunity) | after save, create e update |
| Opportunity | `Opportunity_PromptFlow_DadosOportunidade` | Capability (agente) |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | before save, create e update |
| Quote (CPQ) | `Quote_AfterUpdate_SyncToCPQ` | after save, update |
| Quote | `OpportunityFlow`, `CPQQuoteFlow` | after save (objeto exibido como `Quote`; não confirmei se é `SBQQ__Quote__c` ou a Quote standard) |
| Quote | `EventQuoteUpdated` | Platform Event |
| Task | `Oportunidade_Industria` | after save |
| `SBQQ__Quote__c` | `Opportunity_PromptFlow_CotacaoPrimaria` | Capability (agente) |

Outros ativos, sem relação direta: `ScheduledFlowOpportunity` (objeto `IntegrationLog__c`, agendado), `OrderScheduledFlow` (agendado), `Logs_Delete_Records`, `CreationPriceBook`, `ProductFlowNewOrUpdated`, `QuoteLineCPQFlow`, `QuoteLineItemFlowCreatedOrUpdated`, `EventQuoteLineItemUpdated`, `DeleteLineItemCPQFlow`, `AccountUpdateEconomicGroup`, `AccountTriggered`. Foram classificados só pelo `ProcessType` e pelo objeto inicial quando lido. O `Flow` chamado `Account` está `Obsolete` e `DefaultQuote` também.

Validation rules custom por objeto (nomes confirmados):
- `Order`: 14 ou mais regras `Check*` (por exemplo `CheckOrderHasDeliveryDate`, `CheckAccountHasProtheusId`, `CheckOrderCanHaveSecondStatus` a `...SixthStatus`), `ChangeOrderToCanceled`, `MotivoPerda`. A contagem exata e quantas estão ativas **não foram confirmadas** (a lista de metadata não traz o campo `Active`).
- `Opportunity`: `CheckAccountHasEmail`, `CheckAccountHasCNAE`, `CheckAccountHasStore`, `CheckAccountHasBillingAddress`, `CheckAccountOwnerHasProtheusSellerId`, `CheckOppHasPaymentTermId`, `CheckOppHasBranch`, `FinancialAnalysis`, `TaxAnalysis`, `LossReason`, `PriceBook`. Algumas se ligam à etapa e podem interagir com `Opportunity.FinancialAnalysis`.
- `Account`: `Contato_Fiscal`, `WhatsApp`, `Telefone`, `CheckUserCanSetLimitDueDate` (modificadas em 2026-11-14).
- `Lead`: `Celular`, `Telefone`.

**Ordem de execução (pré-requisito do assessment): NÃO foi mapeada além do inventário acima.** Não consegui determinar a ordem relativa entre `OpportunityTrigger`, `OpportunityBefore` e `OpportunityAfter` do SBQQ e os Flows after save. Pela plataforma, before triggers e before-save flows rodam antes das validation rules, e after triggers e after-save flows depois, mas a ordem entre vários after-save flows no mesmo objeto não é garantida. Dependências lidas do corpo dos triggers e das classes não foram verificadas.

Lead, a frente de distribuição, **não** tem concorrência de trigger ou Flow custom hoje. Aprovação em Opportunity, Quote e Order concorre com o descrito acima.

## 4. Volume e dados de teste

| Objeto | `COUNT()` | Prova |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Opportunity | 0 | idem |
| Order | 0 | idem |
| Account | 0 | idem |
| `SBQQ__Quote__c` | 0 | idem |
| Case | 0 | idem |
| Queue (Group) | 0 | `Group WHERE Type='Queue'` |

A sandbox não tem dado de teste. O QA e o build precisarão criar registros sintéticos. Sem dado, o comportamento real das aprovações e das regras de Lead não pode ser observado.

## 5. Marketing Cloud Connect (`et4ae5`)

| Item | Achado | Prova |
|---|---|---|
| Pacote instalado | Sim. 28 objetos custom `et4ae5__` (por exemplo `Automated_Send`, `Business_Unit`, `Campaign_Member_Configuration`, `Configuration`, `IndividualEmailResult`, `SendDefinition`, `SMSDefinition`, `Triggered_Send_Execution`, `UEBU`, `JB_Event`) | Tooling `CustomObject` |
| Flows do conector | Ativos ou instalados: série `et4ae5__MCC_*` (envio, backup, tracking). Não toquei | `list metadata -t Flow` |
| Campos do conector em Lead e Contact | Só `et4ae5__HasOptedOutOfMobile__c` e `et4ae5__Mobile_Country_Code__c` | describe |
| Origem `E-mail MKT` | Existe em `Lead.LeadSource` | describe |
| Opt-out de e-mail | `HasOptedOutOfEmail` não consultado. Não afirmo | — |
| Conexão e jornadas do lado do Marketing Cloud | Fora do escopo do recon (regra 2 do cliente) | — |

Nada foi lido ou alterado no Marketing Cloud. Se a distribuição ou o encaminhamento de Lead tocar marketing, a seção "Preparação do Sales Cloud para o Marketing Cloud" é do arquiteto. Os campos de opt-out acima são os únicos do conector em Lead.

## 6. Permissões

Não levantei perfis e permission sets por objeto. Confirmado: OWD `Lead = ReadWriteTransfer`, `Opportunity = Read`, `Order = ReadWrite`, `Account = ReadWrite`, `SBQQ__Quote__c = ReadWrite`. O assessment cita 4 variações de perfil comercial; não reconferi.

## 7. Riscos do assessment que tocam a demanda (reconferidos)

| Risco | Reconferido? | Evidência |
|---|---|---|
| Concorrência de automação em Account, Opportunity e Order | Sim, inventário na seção 3 | Triggers custom e SBQQ nos mesmos objetos; Flows after save |
| `OrderTrigger` custom colide em nome com o do SBQQ | Sim | Mesmo nome, namespaces distintos |
| API desatualizada das classes e triggers | Parcial | Triggers custom em v58 e v59; a org está em v68. Contagem por versão de classes: consulta falhou, não obtida. Classes custom sem namespace: 56 |
| Cobertura Apex em 10% | Não reconferido | Só assessment |
| Dev vs QA | Parcial | Só `sbx-eplast-dev` conectada; a URL contém `--qa`. `sbx-eplast-qa` não aparece em `sf org list` |

## O que não consegui confirmar

1. **Ordem de execução** entre `OpportunityTrigger`, triggers SBQQ e Flows after save. Só o inventário foi feito.
2. **Relatórios e painéis** que cubram aprovação ou distribuição de Lead: não consultados.
3. **Quantas validation rules de Order estão ativas** e quais interagem com um novo status de aprovação (a listagem não traz `Active`).
4. **Permission sets e perfis** que alcançam Lead, Opportunity, Quote e Order, e quem pode submeter ou aprovar.
5. **`AssignmentRules` de Case**, e se a de Lead vazia reflete a org ou limitação do retrieve com o usuário técnico (a análise anterior notou o mesmo risco para filas).
6. **Se existe fila de Lead** em produção: aqui há 0 filas.
7. **Objeto de disparo de `OpportunityFlow` e `CPQQuoteFlow`**: exibido como `Quote`, sem distinguir `SBQQ__Quote__c` de `Quote`.
8. **Cobertura de teste** e distribuição de API version das classes (consulta falhou).
9. **`HasOptedOutOfEmail`** no Lead e o consentimento usado pelo Marketing Cloud.
10. **Respostas de negócio D1 a D12**: nenhuma nos comentários. A org só aponta caminhos de reaproveitamento (motor nativo, três aprovações existentes, `Lead.LeadSource` e `Status`); não decide critério de alçada, régua de distribuição, aprovadores nem o significado de "encaminhamento".
11. **Se dev e QA são sandboxes distintas**: só uma org é visível.

## Complemento do arquiteto (2026-11-15, `sbx-eplast-dev`, só leitura)

Linhas acrescentadas na etapa de design, porque mudam a decisão. Comandos: `FlowDefinitionView` com `TriggerObjectOrEvent.QualifiedApiName`, Tooling `ApexTrigger` e `ValidationRule`, `sf package installed list`, retrieve em diretório temporário fora do repositório, `COUNT()`.

| Item | Achado | Prova |
|---|---|---|
| Objeto real dos Flows record-triggered (corrige a seção 3) | `Order` (Flow chamado `Order`) e `Acionado_por_registro_..._Pedido_...` disparam em **Order**; `OpportunityFlow` e `Oportunidade_Industria` (update) em **Opportunity**; `CPQQuoteFlow` em **`SBQQ__Quote__c`**; `Quote_AfterUpdate_SyncToCPQ` em **Quote** padrão (update); `QuoteLineItemFlowCreatedOrUpdated` em `QuoteLineItem`; `QuoteLineCPQFlow` e `DeleteLineItemCPQFlow` em `SBQQ__QuoteLine__c`; `TaskCreatedOrUpdated` em Task; `PaymentTermAccount` e `SetPaymentTermsChangesinAccount` em `RelationshipAccountsPaymentTerm__c`; `AccountTriggered` e `UpdateParentAccountUsedLimit` em Account. Nenhum Flow ativo em Lead | `FlowDefinitionView` |
| Triggers SBQQ `QuoteBefore`/`QuoteAfter` | Estão em `SBQQ__Quote__c`, não na Quote padrão. A Quote padrão não tem trigger | Tooling `ApexTrigger.TableEnumOrId` |
| Validation rules ativas | Order 17 ativas + 6 inativas (23); Opportunity 16 ativas; `SBQQ__Quote__c` 3 ativas + 1 inativa; Quote 1 ativa; Lead 2 ativas | Tooling `ValidationRule` (`COUNT` por objeto e `Active`) |
| Critério de entrada das aprovações | `Quote.AssignPricing` e `Order.LiberationFinancial`: **sem critério de entrada** (todo registro submetido entra). `Opportunity.FinancialAnalysis`: `StageName = Análise Financeira`. Aprovador: usuário nomeado nos três. `recordEditability = AdminOrCurrentApprover` nos três | retrieve `ApprovalProcess` |
| Gestor dos usuários | 0 de 19 usuários padrão ativos têm `ManagerId` | `COUNT()` em User |
| Pacotes | CPQ (`SBQQ`), Marketing Cloud (`et4ae5`), Salesforce Maps (`maps`); **sem** Advanced Approvals (`sbaa`). `maps__AssignmentRule__c`: 0 registros | `sf package installed list`; `COUNT()` |
| Regra de atribuição de Lead e layout | Regra vazia confirmada. Layout `Lead-Lead Layout`: `showRunAssignmentRulesCheckbox = true`, `runAssignmentRulesDefault = false`; `HasOptedOutOfEmail` está no layout | retrieve |
| Régua regional já usada pela Eplast | Pasta `MARKETING CLOUD`: relatórios `LEADS - SP/RJ/MG/SUL/GERAL` (Lead, filtro `STATE`) e `RECORRENTES (ATIVOS)` por região de conta: SP; RJ; MG; ES; SUL = PR,SC,RS; CO = GO,DF,MT,MS,TO; NO/NE = AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE | retrieve `Report` (só filtros) |
| Estado no Lead | `State` texto livre; picklists de estado/país **não** habilitadas (`StateCode` ausente) | describe |
| Histórico de campo em Lead | Nenhum campo rastreado (`OwnerId`, `Status`, `LeadSource` com `IsFieldHistoryTracked = false`) | `FieldDefinition` |
| Relatório de aprovação existente | `Histrico_de_Aprovao_XNR` (pasta Geral, tabular), tipo custom `Inst_ncias_do_processo_de_aprova_o__c`, filtrado em "Análise financeira" | retrieve |
| Papéis, grupos, custom permissions, CMDT | 2 papéis (`Coordination`, `Financeiro`); grupos Regular `DEV` e `Marketing_Origem_Retorno`; 1 custom permission (`IA_Rascunho_Comercial`); nenhum CMDT custom | SOQL de metadata |
| Volume | Quote 0, Campaign 0, CampaignMember 0; 380 relatórios e 20 painéis na org | `COUNT()` |
