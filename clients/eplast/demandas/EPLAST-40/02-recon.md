# EPLAST-40 — Recon da org

**Data da coleta:** 2026-11-15 (vence em 7 dias).
**Org:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`), tipo Sandbox, status Connected, única org listada por `sf org list`. Só leitura. Metadata baixada para `/tmp/recon-proj/recon`, fora de `force-app/`. Só metadata e contagens agregadas; nenhum registro de negócio foi lido.
**Preflight:** sem bloqueios e sem outra demanda nos mesmos componentes (`00-preflight.md`).

---

## 1. O que já cobre o pedido

Nenhum componente cobre o ciclo inteiro. Não existe estágio SDR, nem campo de data de passagem, nem fila de Pós-vendas, nem Flow de passagem para Case. Cobrem partes do pedido:

| Peça existente | Cobre | Prova |
|---|---|---|
| `Lead.Status`: `Aberto - Não contatado`, `Contatado`, `Fechado - Convertido`, `Fechado - Não convertido` | Estágios do SDR (parcial) | `sf sobject describe Lead` |
| `Lead.LeadSource`: 13 valores, incluindo `E-mail MKT`, `Campanha`, `Evento`, `Google Ads`, `Google Orgânico`, `Instagram`, `Facebook`, `WhatsApp`, `SDR` | Origem de marketing e SDR | `describe Lead` |
| `Opportunity.StageName`: 13 valores, de `Qualificação` a `Fechado/Ganho` e `Fechado/Perdido` | Estágios da Comercial | `describe Opportunity` |
| `Opportunity.Discovery_Completed__c`, `Budget_Confirmed__c`, `ROI_Analysis_Completed__c` (checkbox) | Critério de qualificação (P4) | `describe Opportunity` |
| `PriorityScore__c` (double) e `PriorityBand__c` (string) em Lead e Opportunity | Priorização do SDR | `describe` das duas |
| Regra de atribuição `Distribuicao_Regional_Leads` mais Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (Lead, RecordAfterSave, Create, ativo) que chama a ação Apex `LeadAssignmentService` | Distribuição de Lead por região | `FlowDefinitionView`, retrieve do Flow e da classe |
| 8 filas de Lead (`Leads_CO`, `_ES`, `_MG`, `_NO_NE`, `_RJ`, `_SP`, `_Sul`, `_Triagem`), todas só para `Lead` | Dono de Lead | `Group` (Queue), `QueueSobject` |
| `Case` padrão: `Status` = `New`, `On Hold`, `Escalated`, `Closed`; `Origin` = `Email`, `Phone`, `Web`; 0 campos custom; 1 record type (`Mestre`) | Objeto de Pós-vendas | `describe Case` |
| Flow `Order` (Order, RecordAfterSave, CreateAndUpdate, ativo) atualiza `Opportunity.StageName` para `Fechado/Ganho` ou `Fechado/Perdido` conforme `Order.Status` | O que leva a Oportunidade a ganha | retrieve do Flow, lido por XML |
| Flow `OpportunityFlow` (Opportunity, RecordAfterSave, CreateAndUpdate, ativo) cria Quote, Order e Task, e atualiza Account | A Order nasce de Flow sobre a Oportunidade | retrieve do Flow |
| `SFAgent2` (`BotDefinition`) | Não se aplica: a demanda não fala em assistente, resumo, recomendação ou linguagem natural | `SELECT DeveloperName FROM BotDefinition` |

**Flows de Case: não são da Eplast.** `CreateCase`, `CloseCase` e `AddCaseComment` pertencem ao pacote `SvcCopilotTmpl` e `Create_Case` ao `setup_service_experience` (`FlowDefinitionView`, `ManageableState=installed`). O retrieve devolveu "cannot be found" para `CreateCase`, `CloseCase` e `Create_Case`, então o corpo e o objeto-alvo não foram lidos. Não há Flow record-triggered ativo em Case (`TriggerObjectOrEventLabel='Caso'` retornou 0).

Resposta ao ponto da análise (P5): a **Order é criada por Flow, não por trigger**. `OpportunityFlow` tem 6 elementos `recordCreates` de Order (com e sem remessa, padrão e não padrão). A decisão do Flow usa `StageName` com os valores `Cotação`, `Envio Cotação` e `Análise Fiscal` e o campo `NomeTipoRegistro__c = Industria`. **Qual estágio dispara a criação da Order não foi confirmado.** Depois, o Flow `Order` devolve `Fechado/Ganho` à Oportunidade quando `Order.Status` = `Concluido` (ou `Liberacao Financeiro` com `Formas_de_Pagamento__c` = `AV`; a leitura do XML mostra essas condições, não foi testada na execução).

## 2. O que será tocado

| Objeto.campo | Tipo | Estado | Prova |
|---|---|---|---|
| `Lead.Status`, `Lead.LeadSource` | picklist | existem, sem alteração prevista | `describe Lead` |
| `Lead.HasOptedOutOfEmail` | boolean | existe, padrão; não deve ser alterado | `describe Lead` |
| `Lead.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__Mobile_Country_Code__c` | do conector | existem; só leitura | `describe Lead` |
| `Lead.Sector__c` | picklist (8 valores) | existe | `describe Lead` |
| `Opportunity.StageName`, `Type`, `LeadSource` | picklist | existem | `describe Opportunity` |
| `Opportunity` com 6 record types: `Amostra`, `Bonificação`, `Indústria`, `Venda`, `Venda com remessa`, `Mestre` | | existem | `describe Opportunity` |
| `Case.Status`, `Case.Origin` | picklist | existem | `describe Case` |
| Campo de data de passagem SDR→Comercial em Opportunity | a criar | **não existe**: nenhum campo custom de Opportunity tem nome de passagem | lista de custom em `describe Opportunity` |
| Campo de data de passagem Comercial→Pós-vendas em Case | a criar | **não existe**: Case tem 0 campos custom | `describe Case` |
| Campo que ligue o Case à Oportunidade | a decidir | **não existe** em Case. Existe `Case.OpportunityId__c`? Não: o describe não o retornou. Standard `Case` não tem lookup de Opportunity. | `describe Case` |
| Fila `Pós-vendas` | a criar | **não existe** (8 filas, todas de Lead) | `Group` (Queue) |

Descrição de campo (`Description`) não aparece no `describe`. Para os campos de Opportunity usados em P4, a existência de descrição **não foi verificada**. O `inlineHelpText` está vazio em `Discovery_Completed__c`, `Budget_Confirmed__c` e `ROI_Analysis_Completed__c`, mas isso é outro atributo.

## 3. Automação concorrente

### Opportunity (maior risco)

| Componente | Evento | Detalhe confirmado | Prova |
|---|---|---|---|
| `SBQQ.OpportunityBefore` (trigger do CPQ) | before insert, before update | ativo | `ApexTrigger` |
| `OpportunityTrigger` (custom) | after insert, after update | chama `OpportunityTriggerHandler`, que apenas faz `System.enqueueJob(new OpportunityTriggerHelper(...))`. Pula quando `TriggerUtility.bypassTrigger`; no update também pula quando já está em Queueable. | retrieve do trigger e da classe |
| `SBQQ.OpportunityAfter` (trigger do CPQ) | after insert, after update | ativo | `ApexTrigger` |
| `OpportunityFlow` | after save, create e update | ver seção 1: cria Quote, Order e Task; atualiza Account | retrieve do Flow |
| `Oportunidade_Industria` | after save, update | chama a ação Apex `FlowOpportunityController` e cria Task | retrieve do Flow |
| `Order` (Flow no objeto Order) | after save em Order | atualiza `Opportunity.StageName` de volta | retrieve do Flow |
| `Opportunity_Scheduled_AlertaParada`, `ScheduledFlowOpportunity` | agendados | ativos | `FlowDefinitionView` |
| `PaymentTermsOpportunity`, `Opportunity_Screen_RascunhoComercial` | Flow de tela | ativos, não são por registro | `FlowDefinitionView` |

Consequências para a regra P4 (promover para `Qualificado`): um update de `StageName` por Flow dispara de novo `OpportunityFlow`, `Oportunidade_Industria`, `OpportunityTrigger` (que enfileira Queueable) e os triggers `SBQQ`. A ordem entre os Flows e o `OpportunityTrigger` não foi determinada na execução. `OpportunityTriggerHelper` (Queueable) **não foi lido**.

Validation rules ativas em Opportunity: **16** (`ValidationRule` via Tooling). Nomes: `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`. A fórmula de cada uma **não foi lida**; quais bloqueiam o avanço para `Qualificado` ou a conversão do Lead é incerteza (ver fim).

### Lead

| Componente | Evento | Detalhe | Prova |
|---|---|---|---|
| Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | after save, create | ação Apex `LeadAssignmentService` (`without sharing`, reaplica a regra ativa via `Database.DMLOptions`; ignora Lead convertido, segundo o comentário da classe) | retrieve |
| Trigger de Lead | n/a | nenhum (consulta de `ApexTrigger` para `Lead` retornou 0 linhas) | `ApexTrigger` |
| Validation rules ativas | n/a | 2: `Celular`, `Telefone` | `ValidationRule` |

Não há Flow de passagem de Lead na conversão. A conversão padrão cria a Oportunidade e dispara os mesmos triggers e Flows de Opportunity listados acima. O mapeamento de campos do Lead para a Oportunidade na conversão **não foi verificado**.

### Order (tocada só pela verificação "Order não muda")

| Componente | Detalhe | Prova |
|---|---|---|
| `SBQQ.OrderTrigger` | before e after, insert e update | `ApexTrigger` (NamespacePrefix `SBQQ`) |
| `OrderTrigger` (custom, sem namespace) | before update, after update; só o after update tem código: chama `sendOrderToProtheus`, exceto quando está em Queueable ou o usuário começa por `integracao` | retrieve |
| Flows ativos: `Order` (after save), `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p…` (before save), `OrderScheduledFlow` (agendado) | | `FlowDefinitionView` |
| Validation rules ativas | **17** (o assessment fala em 23; a dev tem 17 ativas hoje) | `ValidationRule` |

### Case

Sem trigger (0 linhas), sem Flow record-triggered ativo, 0 validation rules ativas. Um Flow novo em Case não concorre com automação existente na dev. Os Flows de pacote listados na seção 1 são acionados por agente ou ação, não por evento de registro.

## 4. Volume e dados de teste

| Objeto | Registros na dev | Prova |
|---|---|---|
| Lead | 0 | `SELECT COUNT() FROM Lead` |
| Opportunity | 0 | idem |
| Order | 0 | idem |
| Case | 0 | idem |
| Campaign | 0 | idem |
| CampaignMember | 0 | idem |
| Fila de Lead, membros | 0 (`GroupMember` com `Group.Type='Queue'` retornou 0) | `COUNT()` |

A dev não tem dado para testar: todo teste usa massa sintética criada por `fixtures/`. Filas de Lead sem membro significam que Lead atribuído a fila não chega a ninguém.

Usuário de teste (consulta em `User` pelo prefixo de username da conta de serviço da Konecta, conforme a regra 6 da conta): a consulta retornou **dois** usuários, ambos com perfil `Administrador do sistema`:
- `005bJ00000hBJmY`: inativo.
- `005bJ00000piKAa`: ativo. É o usuário a usar como proprietário de registro de teste e caso de acesso negado. Como é administrador do sistema, **acesso negado por perfil não se prova com ele**; o caso de acesso negado só funciona com perfil de campo restrito, que não foi mapeado aqui.

## 5. Permissões

| Item | Resultado | Prova |
|---|---|---|
| OWD (interno / externo) | Lead `ReadWriteTransfer` / `Private`; Opportunity `Read` / `Private`; Case `ReadWriteTransfer` / `Private`; Order `ReadWrite` / `Private`; Campaign `FullAccess` / `Private` | `EntityDefinition` |
| Perfis com edição de Lead | 10 (inclui `Comercial`, `Comercial - Analista`, `Comercial - Analistas`, `Comercial Padrão`, `Pricing`, `Marketing`, `Financeiro`, `Engenharia de Produtos`, integrações). Criação de Lead: `Comercial`, `Pricing`, `Comercial - Analista`, `Comercial - Analistas`, `Sales Insights Integration User`. | `ObjectPermissions` (só perfis) |
| Perfis com criação de Case | 8: `Gerente de soluções`, `Administrador do sistema`, `Executive Sponsor`, `Gerente do contrato`, `Usuário do Marketing`, `Usuário Padrão`, `End User`, `Comercial - Analistas` | `ObjectPermissions` |
| Usuários ativos por perfil (contagem) | `Administrador do sistema` 9, `Comercial - Analista` 4, `Financeiro` 1, mais 5 de integração/analytics com 1 cada | `COUNT(Id) GROUP BY Profile.Name` |
| Permission sets não ligados a perfil | 189 | `COUNT()` em `PermissionSet`; **não analisados** |
| Quem é o SDR | **Não há perfil, papel ou fila "SDR"** na org. A origem `SDR` existe só em `LeadSource`. | `describe Lead`, lista de filas, perfis acima |

Owner `Opportunity` com OWD `Read` e Lead/Case com `Private` externo: um Case criado para a fila de Pós-vendas só é visível a membros da fila (e a quem a hierarquia alcança). A fila ainda não existe.

## 6. Marketing Cloud Connect (`et4ae5`)

| Item | Confirmado | Prova |
|---|---|---|
| `Lead.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__Mobile_Country_Code__c` | existem | `describe Lead` |
| `Contact.et4ae5__HasOptedOutOfMobile__c`, `Contact.et4ae5__Mobile_Country_Code__c` | existem | `describe Contact` |
| `CampaignMember.et4ae5__Activity__c` | existe | `describe CampaignMember` |
| `Campaign`: nenhum campo `et4ae5` | confirmado | `describe Campaign` |
| `Opportunity`, `Case`: nenhum campo `et4ae5` | confirmado | `describe` das duas |
| Objetos do pacote | `et4ae5__Business_Unit__c` (só `ChangeEvent` apareceu na amostra), `et4ae5__Campaign_Member_Configuration__c`, `et4ae5__Configuration__c`, `et4ae5__ET4AEConfig__c`, `et4ae5__ET4AE_Config__c`, `et4ae5__ET4AE_Int_Creds__c`, `et4ae5__ET4AE_JWT__c`, `et4ae5__ET4AE_Private_Settings__c`, `et4ae5__ET4AE_User_Information__c`, `et4ae5__Email_Linkage__c` (amostra de 40 linhas com `LIMIT 40`, lista incompleta) | `EntityDefinition WHERE NamespacePrefix='et4ae5'` |
| Flows `MCC_*` ativos | 11 (`MCC_BackupWorkflow`, `MCC_ScheduledSend`, `MCC_SendComplete`, `MCC_SendFailed`, etc.), em objetos do pacote (Envio de email, Envio acionado, Resultado de email individual) e `MCC_NewSupportRequest` | `FlowDefinitionView` |
| Conexão com o Marketing Cloud | **não consultada nem alterada** (regra 2 da conta) | n/a |

Nenhum campo do conector está em Opportunity ou Case, então a passagem SDR→Comercial→Pós-vendas não colide com eles. O Flow `Lead_AfterInsert_AplicaRegraAtribuicao` e o design não devem alterar os dois campos de opt-out do Lead.

## O que não consegui confirmar

1. **Qual estágio de `Opportunity.StageName` dispara a criação da Order em `OpportunityFlow`.** A decisão `OpportunityStage` compara `Cotação`, `Envio Cotação` e `Análise Fiscal` e `NomeTipoRegistro__c`; o encadeamento até os 6 `recordCreates` de Order não foi percorrido.
2. **Ordem de execução entre `OpportunityTrigger`, os Flows e os triggers `SBQQ` em Opportunity**, e o que faz `OpportunityTriggerHelper` (Queueable). Não foi lido nem executado.
3. **Fórmula das 16 validation rules de Opportunity** e se alguma bloqueia `Qualificado` ou a conversão do Lead; fórmula das 2 de Lead (`Celular`, `Telefone`).
4. **Corpo e objeto-alvo de `CreateCase`, `CloseCase`, `Create_Case`**: pacotes instalados, retrieve não os encontrou. Não afirmo que gerem Case; o nome sugere, mas é inferência.
5. **Mapeamento de campos na conversão Lead→Opportunity** e se há record type padrão de Oportunidade na conversão.
6. **Descrição (`Description`) dos campos de Opportunity** de P4: o `describe` não a expõe.
7. **Perfis e permission sets reais do SDR e do Pós-vendas.** Não há SDR identificável; os 189 permission sets não foram analisados. Também não há perfil restrito mapeado para o caso de acesso negado (o usuário de teste ativo é administrador).
8. **Lista completa de objetos `et4ae5`** (consulta limitada a 40) e **como `CampaignMember.et4ae5__Activity__c` é preenchido.**
9. **QAS (`sbx-eplast-qa`)**: não foi consultada nesta etapa; divergência de metadata entre dev e QA (validation rules, Flows) não foi comparada. O assessment cita 23 validation rules em Order; a dev tem 17 ativas.
10. **Existência de relatório ou painel de funil** que já cubra Marketing→Pós-vendas: não consultei `Report` nem `Dashboard`. Não afirmo que não existam.
