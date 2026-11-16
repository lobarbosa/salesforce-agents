# EPLAST-30 · Recon da org (rodada 2, 2026-11-15)

**Org confirmada:** `sbx-eplast-dev` (Sandbox, Connected, Org Id `00DHa000006vfMLMAY`), por `sf org list`. Só leitura, só metadata e contagens agregadas. Nada em produção, nada no Marketing Cloud.
**Insumos:** `01-analise.md` (PA-01 a PA-16), `comentarios-do-card.md`, `rodada-anterior/02-recon.md` (só a seção de ordem de execução, reaproveitada como referência, não como fato novo).

Legenda: **C** = confirmado nesta sessão, com o comando. **NC** = não confirmado.

## 1. O que já cobre o pedido (reaproveitar)

| Item | Estado | Prova |
|---|---|---|
| PromptFlow `Opportunity_PromptFlow_DadosOportunidade` (ativo) | **C**, existe na dev. Customizado, sem namespace. Conteúdo/saídas não lidos | `sf data query -q "SELECT ApiName,ProcessType,IsActive FROM FlowDefinitionView WHERE ApiName LIKE 'Opportunity_%'"` |
| PromptFlow `Opportunity_PromptFlow_CotacaoPrimaria` (ativo) | **C**, existe na dev. É o que falhou na rodada anterior (erro de parâmetro de saída, segundo `01-analise.md` R1; não reproduzido aqui) | mesma query |
| Flow `Opportunity_Screen_RascunhoComercial` | **C: NÃO está na dev.** Existe só no código local (`force-app/.../flows/`) | a query acima não o retorna; `find force-app` o lista |
| Templates `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade` | **C: NÃO estão na dev** (0). Existem só no código local | `sf org list metadata --metadata-type GenAiPromptTemplate` (nenhum); `find force-app` |
| Permission set `PS_Comercial_RascunhoIA` e grupo `PSG_Comercial_RascunhoIA` | **C: NÃO estão na dev**. Só no código local | `SELECT Name FROM PermissionSet WHERE Name LIKE 'PS_Comercial%'` retorna só `PS_Comercial_ResumoClienteAgente` |
| Custom Permission `IA_Rascunho_Comercial` | **C**, existe na dev | `SELECT DeveloperName FROM CustomPermission WHERE DeveloperName LIKE 'IA_%'` |
| Agente `SFAgent2` | **C** existe (BotDefinition) e 4 planners `SFAgent2_v1` a `v4`, todos criados em 2026-11-10 | `SELECT DeveloperName FROM BotDefinition`; `sf org list metadata --metadata-type GenAiPlannerBundle` |
| Tópicos e ações do `SFAgent2` (`ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`) | **NC** nesta sessão. `GenAiPlugin` e `GenAiFunction` voltam vazios na listagem; não abri o planner | `sf org list metadata --metadata-type GenAiPlugin` / `GenAiFunction` |
| Permission sets de Prompt Builder da plataforma | **C**: `EinsteinGPTPromptTemplateManager`, `EinsteinGPTPromptTemplateUser`, `PromptTemplatePermSet` | `SELECT Name FROM PermissionSet WHERE Name LIKE '%Prompt%'` |
| PromptFlows de pacote (`GetBriefGroundingData`, `GenPreWorkBrief`, etc.) | **C** existem; são de pacote gerenciado, não pertencem à Eplast | `FlowDefinitionView WHERE ProcessType IN ('Flow','PromptFlow')` |
| Relatório, painel, campo de IA que já gere rascunho comercial | **NC**: não procurei relatórios/painéis/campos além do que está acima | n/a |

**Leitura para o design:** a dev tem hoje só 2 dos ~10 componentes que o build anterior desenhou (2 PromptFlows e a Custom Permission). O resto está no código local da branch, não na org. Isso muda o ponto de partida do arquiteto: não é retomar um build implantado.

## 2. O que será tocado

| Objeto / campo | Estado | Prova |
|---|---|---|
| `Opportunity`: 77 campos, 28 custom | **C**. Contém `AccountId`, `StageName`, `Amount`, `CloseDate`, `SBQQ__PrimaryQuote__c` | `sf sobject describe -s Opportunity` (só nomes e contagem) |
| `SBQQ__Quote__c`: 107 campos, 94 custom. Contém `SBQQ__NetAmount__c` | **C** | `sf sobject describe -s SBQQ__Quote__c` |
| `SBQQ__QuoteLine__c` (objeto) | **C** existe (COUNT roda); campos não descritos | `SELECT COUNT() FROM SBQQ__QuoteLine__c` |
| Descrição preenchida dos campos custom | **NC** nesta sessão. Assessment (achado 4) diz 19 de 28 sem descrição em Opportunity (contexto, não conferido) | n/a |
| Contact, Task, Order | Somente leitura/nenhuma escrita por PA-07. **C** que existem | COUNT |

## 3. Automação concorrente (relevante só se houver DML; a feature é somente leitura)

Triggers (Tooling API, `SELECT NamespacePrefix,TableEnumOrId,Name,Usage... FROM ApexTrigger`), **C**:

| Objeto | Trigger | Namespace | Eventos |
|---|---|---|---|
| Account | `AccountBefore` | SBQQ | before ins/upd |
| Account | `AccountTrigger` | custom | before e after ins/upd |
| Opportunity | `OpportunityBefore` | SBQQ | before ins/upd |
| Opportunity | `OpportunityAfter` | SBQQ | after ins/upd |
| Opportunity | `OpportunityTrigger` | custom | after ins/upd |
| Order | `OrderTrigger` | SBQQ | before e after ins/upd |
| Order | `OrderTrigger` | custom | before upd, after upd |

Há dois `OrderTrigger` com o mesmo nome (um SBQQ, um custom). **C**.

Flows record-triggered ativos na dev (`FlowDefinitionView WHERE TriggerType IN (...)`), **C** quanto à existência e ao tipo: `OpportunityFlow` e `Oportunidade_Industria` (after-save), `AccountTriggered`, `SetPaymentTermsChangesinAccount`, `UpdateParentAccountUsedLimit`, `Order`, `TaskCreatedOrUpdated`, `CPQQuoteFlow`, `Quote_AfterUpdate_SyncToCPQ`, além dos `MCC_*` do conector. **NC** nesta sessão: o objeto de disparo de cada Flow (a view não o expõe e a leitura do XML local foi ambígua; não infiro).

Ordem de execução em Opportunity: não reconstruída aqui. A `rodada-anterior/02-recon.md`, seção 4.3, a documenta (before trigger SBQQ, validation rules, after triggers `OpportunityTrigger` e `SBQQ.OpportunityAfter` sem ordem garantida, after-save Flows `OpportunityFlow` e `Oportunidade_Industria` sem `triggerOrder`). **NC** nesta sessão; tratar como referência a revalidar se o desenho passar a gravar algo. Para Account e Order, mesmo estado.

Validation rules: contagem por objeto **NC** (a consulta Tooling falhou com erro interno da plataforma, ErrorId 1533958995-261479).

## 4. Marketing Cloud Connect (`et4ae5`)

**C**: 28 objetos custom do namespace `et4ae5` (`SELECT DeveloperName FROM CustomObject WHERE NamespacePrefix='et4ae5'`, Tooling). Entre eles: `SendDefinition`, `IndividualEmailResult`, `Triggered_Send_Execution`, `Automated_Send`, `Campaign_Member_Configuration`, `Business_Unit`, `SMSDefinition`, `ET4AE_Int_Creds`, `JB_Event`, `MC_CDC_Journey`.
**C**: flows `MCC_*` ativos (envio agendado, falha, status, tracking).
**C**: `et4ae5__SendDefinition__c` tem 0 registros na dev.
**Relação com EPLAST-30:** nenhuma. A feature é somente leitura e não envia nada (PA-03, PA-07). Nenhum objeto ou campo de MC Connect é lido, escrito ou proposto. Não toquei o Marketing Cloud. Quais campos de Opportunity/Account o MC Connect usa: **NC**. Esta demanda não é de marketing, então a seção "Preparação do Sales Cloud para o Marketing Cloud" não se aplica ao recon; o follow-up por e-mail é passo de quem opera o MC (PA-03).

## 5. Volume e dados de teste

| Objeto | COUNT() na dev | Prova |
|---|---|---|
| Opportunity | 0 | `SELECT COUNT() FROM Opportunity` |
| Account | 0 | idem |
| Contact | 0 | idem |
| Order | 0 | idem |
| SBQQ__Quote__c | 0 | idem |
| SBQQ__QuoteLine__c | 0 | idem |
| Task | 0 | idem |
| Opportunity com cotação primária | 0 | `COUNT() WHERE SBQQ__PrimaryQuote__c != null` |

**Conclusão:** a dev não tem nenhum dado. Todos os cenários do `01-analise.md` exigem massa sintética criada na própria dev. Criar essa massa dispara a cadeia de automação de Opportunity/Account/Order (seção 3), o que é risco de build, não desta etapa.

## 6. Permissões

| Item | Estado | Prova |
|---|---|---|
| OWD: Opportunity = Read, Account = Edit | **C** (da análise, `Organization.DefaultOpportunityAccess` / `DefaultAccountAccess`) | consulta registrada em `01-analise.md`; não repeti |
| Permission sets de Prompt Builder (3, seção 1) | **C** | query acima |
| `PS_Comercial_RascunhoIA` | **C: ausente** na dev | query acima |
| Custom Permission `IA_Rascunho_Comercial` | **C** presente | query acima |
| Perfis que alcançam Opportunity/SBQQ__Quote__c | **NC** | não consultado |
| Licença e créditos de IA generativa | **NC** | n/a (PA-13) |

## O que não consegui confirmar

1. Tópicos e ações do `SFAgent2` nesta sessão (`GenAiPlugin`/`GenAiFunction` vazios na listagem; planner não aberto). A regra 3 da conta cita 4 tópicos e 3 ações, mas isso não foi reconferido aqui.
2. O conteúdo e as saídas dos dois PromptFlows implantados, e se o erro de parâmetro de saída da rodada anterior persiste.
3. O objeto de disparo de cada Flow record-triggered e a ordem atual de execução em Account, Opportunity e Order (só a referência da rodada anterior).
4. Contagem de validation rules por objeto (a Tooling API devolveu erro interno).
5. Quais campos de Opportunity/Account o MC Connect (`et4ae5`) lê ou grava.
6. Descrição preenchida dos campos candidatos à lista permitida (PA-04).
7. Perfis com acesso a Opportunity e às cotações, e licença/créditos de IA generativa.
8. Se existe relatório, painel ou campo de IA já cobrindo parte do pedido (não procurei).
9. Se o código local da branch (templates, Screen Flow, permission set) corresponde ao que se pretende construir; não foi comparado com a org.

## Complemento do arquiteto (2026-11-15, etapa de design)

Confirmações pontuais que mudam ou firmam a decisão do design. Só metadata e contagens.

| Item | Estado | Prova |
|---|---|---|
| Tópicos e ações do `SFAgent2` (planner `SFAgent2_v4`) | **C**: 4 tópicos (`agent_router`, `ambiguous_question`, `insights_comerciais`, `off_topic`); 3 ações locais no tópico `insights_comerciais` (`ConsultarPedidos`, `AgregacaoPedidos`, `IdentificarConta`). Fecha o item 1 de "O que não consegui confirmar" | `sf project retrieve start -m GenAiPlannerBundle:SFAgent2_v4 --target-metadata-dir <pasta temporária>` (fora do `force-app`, apagada depois) |
| Campos da lista permitida | **C**: Opportunity `Name`, `StageName`, `CloseDate`, `Amount`, `Probability`, `Type`, `LeadSource`, `IsClosed`, `IsWon`, `LastActivityDate`, `AccountId`, `SBQQ__PrimaryQuote__c`; Account `Name`, `Industry`, `Type`, `BillingCity`, `BillingState`; `SBQQ__Quote__c` `SBQQ__Status__c`, `SBQQ__NetAmount__c`, `SBQQ__PaymentTerms__c`, `SBQQ__ExpirationDate__c`, `SBQQ__CustomerDiscount__c`, `SBQQ__LineItemCount__c`, `SBQQ__Primary__c`, `SBQQ__Opportunity2__c`; `SBQQ__QuoteLine__c` `SBQQ__Quote__c`, `SBQQ__Product__c`, `SBQQ__ProductName__c`, `SBQQ__Quantity__c`, `SBQQ__NetPrice__c`, `SBQQ__NetTotal__c`, `SBQQ__Discount__c` | `sf sobject describe` filtrado por nome (só nome e tipo) |
| Multimoeda | **C**: `CurrencyType` consultável, 1 moeda ativa ou cadastrada | `SELECT COUNT() FROM CurrencyType` = 1 |
| PromptFlows da demanda | **C**: os 2 continuam ativos; nenhum Flow com "Rascunho" no nome na dev | `FlowDefinitionView WHERE ApiName LIKE 'Opportunity_PromptFlow%' OR ...Rascunho%` |
