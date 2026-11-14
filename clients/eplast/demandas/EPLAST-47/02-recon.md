# EPLAST-47 — Recon da org

**Data da coleta:** 2026-11-14 (válido até 2026-11-21)
**Org consultada:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`), a única conectada (`sf org list`). Só leitura. Retrieves em `/tmp/reconproj` (fora do `force-app/`).
**Não consultada:** sandbox de QA (não conectada nesta sessão).
**Dados:** nenhuma consulta retornou registro; só metadata e `COUNT()`.
**Decisões do card (14/11) usadas aqui:** P2 (data de criação, `ThisYear__c` não muda), P3 (classifica pela média, grava a soma), P4 (`LastMonthPurchaseValue__c` mantém o nome), P7 (faixas novas, mesma comparação de hoje). Alerta do ex-parceiro fora do escopo: não procurei esse destinatário.

## 1. O que já cobre o pedido

| Item | Existe? | Cobre | Comando |
|---|---|---|---|
| Flow `ScheduledFlowOpportunity`, versão ativa 1, `AutoLaunchedFlow`, API 59.0, `Scheduled`, objeto de início `Opportunity`, filtro `IsWon = true`, `Daily` com início 2024-01-23 | Sim | Parcial. É o componente a ajustar (regra 3 do cliente). | `sf data query --use-tooling-api` em `Flow` + `sf project retrieve start --metadata Flow:ScheduledFlowOpportunity` |
| No mesmo fluxo: lookup `GetOpportunities` (filtra `AccountId`, `StageName = Fechado/Ganho`, `ThisYear__c = true`) | Sim | Soma anual por conta | leitura do XML retrieved |
| No mesmo fluxo: lookup `GetOpportunities2` (filtra só `LastMonth__c = true`, sem conta) e update `LastMonthPurchaseValue` (grava `LastMonthPurchaseValue__c` com `SumAmount`) | Sim | Confirma pontos 2 e 3 do diagnóstico | leitura do XML retrieved |
| 5 `recordUpdates` que gravam `Ranking__c` com valor fixo (o XML tem 5 ocorrências do campo) | Sim | Só 5 classes (PP, P, M, G, GG) | `grep` no XML retrieved |
| Flow `OpportunityFlow` (versão ativa 2, `RecordAfterSave`, `Opportunity` `CreateAndUpdate`): grava `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c` em `Account` (2 ocorrências de cada) | Sim | Parcial. Escreve o campo que o fluxo agendado lê para classificar. | idem |
| Elemento de e-mail (`emailSimple`/`emailAlert`) em `ScheduledFlowOpportunity` | Não encontrado no XML | Não há alerta a remover no fluxo. | leitura do XML (a análise já registrou) |
| Relatório ou painel de "contas que mudaram de classificação" (P12) | **Não confirmado** | Busca por nome em `Report` (379 reports; filtro por `Name LIKE` "anking", "lassifica", "ompra", "onta") não retornou nenhum com nome de ranking/classificação. Nome não prova conteúdo. | `sf data query -q "SELECT ... FROM Report WHERE Name LIKE ..."` |
| Relatórios/painéis que usam os 4 campos | **Não confirmado** | O retrieve de `Report` e `Dashboard` estourou 120 s e terminou sem retornar nada ("Nothing retrieved"). Não há como afirmar nem que existem nem que não. | `sf project retrieve start --metadata Report Dashboard` |
| Agente Agentforce `SFAgent2` | Sim (`BotDefinition` com `DeveloperName = SFAgent2`) | A demanda não toca assistente. Não será estendido nem alterado. Tópicos e ações não foram conferidos nesta sessão (o briefing da conta cita 4 tópicos e 3 ações, conferido em 10/11). | `sf data query -q "SELECT DeveloperName FROM BotDefinition"` |
| Custom metadata types da org (candidatos a configuração) | `Protheus__mdt`, `TriggerUtility__mdt` | Nenhum existe para período, faixas ou destinatário. A lista veio de `EntityDefinition` filtrado por `__mdt` (LIMIT 30, retornou 2). | `sf data query -q "SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName LIKE '%__mdt'"` |

## 2. O que será tocado

| Objeto / campo | Tipo | Existe | Descrição preenchida |
|---|---|---|---|
| `Account.Ranking__c` | picklist, label "Ranking" | Sim. Valores ativos: PP, P, M, G, GG (5). **MP e 3G não existem.** | Sem `inlineHelpText`. Descrição não lida (a tooling API não aceitou a coluna na consulta). |
| `Account.LastMonthPurchaseValue__c` | currency (18,2), editável | Sim | idem |
| `Account.AveragePurchasesThisYear__c` | currency (18,2), editável | Sim | idem |
| `Account.TotalPurchasesThisYear__c` | currency (18,2), editável | Sim | idem |
| `Opportunity.ThisYear__c` | boolean, fórmula | Sim | n/c |
| `Opportunity.LastMonth__c` | boolean, fórmula | Sim | n/c |
| `Opportunity.Amount`, `Opportunity.IsWon` | currency, boolean | Sim | n/c |

Comando: `sf sobject describe --sobject Account|Opportunity --json` filtrado por `jq` nesses nomes.
A fórmula de `ThisYear__c` já consta na análise (data de criação). Não a reli.

## 3. Automação concorrente

Fonte da lista: `Flow` (Status Active, 45 versões ativas) e `ApexTrigger` filtrado por `Account`, `Opportunity` e `Order`.

**Triggers (todos ativos):**

| Objeto | Trigger | Origem | Eventos / efeito sobre os campos da demanda |
|---|---|---|---|
| Account | `AccountBefore` | pacote SBQQ | Não lido |
| Account | `AccountTrigger` | custom | before insert/update (valida CNPJ), after insert (preenche dados do CNPJ), after update (atualiza dados do CNPJ, fora de `Queueable`). Respeita `TriggerUtility.bypassTrigger`. |
| Opportunity | `OpportunityBefore`, `OpportunityAfter` | pacote SBQQ | Não lido |
| Opportunity | `OpportunityTrigger` | custom | after insert, after update (fora de `Queueable`). Chama `OpportunityTriggerHandler`. |
| Order | `OrderTrigger` | SBQQ **e** custom (dois ativos, mesmo nome) | Não lido. A demanda não grava em Order. |

Em `AccountTriggerHandler`, `AccountTriggerHelper`, `OpportunityTriggerHandler`, `OpportunityTriggerHelper` e `FlowOpportunityController` (retrieved) não há referência a `Ranking__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c`, `TotalPurchasesThisYear__c` nem a `ScheduledFlowOpportunity` (`grep`). Não li as classes inteiras e não retrieved as demais classes custom. Ausência confirmada só nessas 5 classes e nos 2 triggers.

**Flows de Account/Opportunity (retrieved e lidos por tipo, objeto e campos):**

| Flow | Tipo | Objeto | Toca os 4 campos? |
|---|---|---|---|
| `ScheduledFlowOpportunity` | Scheduled | Opportunity (grava Account) | Sim, grava `LastMonthPurchaseValue__c` e `Ranking__c` |
| `OpportunityFlow` | RecordAfterSave, CreateAndUpdate | Opportunity (grava Account, Order, Quote, Task e outros) | Sim, grava `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c` |
| `Oportunidade_Industria` | RecordAfterSave, Update | Opportunity (Task) | Não |
| `AccountTriggered` | RecordAfterSave, CreateAndUpdate | Account (EconomicGroup, Task, User, Profile) | Não |
| `UpdateParentAccountUsedLimit` | RecordAfterSave, CreateAndUpdate | Account | Não |
| `SetPaymentTermsChangesinAccount` | RecordAfterSave, Create | Account | Não |
| `PaymentTermAccount` | RecordBeforeDelete | Account | Não |
| `AccountUpdateEconomicGroup` | Scheduled | Account (EconomicGroup__c) | Não |
| `PaymentTermsOpportunity` | Screen Flow (`Flow`) | Opportunity | Não |

Outros fluxos ativos de Quote, Order, Product e CPQ (por exemplo `CPQQuoteFlow`, `Order`, `OrderScheduledFlow`, `QuoteLineItemFlowCreatedOrUpdated`) **não foram retrieved**. Não sei se algum grava os 4 campos.

**Ordem de execução relevante (o que se confirma e o que não):**
- O `ScheduledFlowOpportunity` roda em execução própria (agendada), não no mesmo evento de salvar do usuário. Cada `recordUpdate` em `Account` no job dispara `AccountBefore` (SBQQ), `AccountTrigger` (validação de CNPJ no before update e atualização de dados do CNPJ no after update, fora de `Queueable`) e os flows `RecordAfterSave` de Account (`AccountTriggered`, `UpdateParentAccountUsedLimit`).
- Dado que hoje há uma atualização de Account por oportunidade ganha, a mudança para por conta reduz essas execuções. Isso é inferência da estrutura, não medi.
- O `OpportunityFlow` grava `AveragePurchasesThisYear__c` a cada criação ou edição de Opportunity. O fluxo agendado só lê esse campo. A concorrência de escrita que a análise registrou (dois fluxos no mesmo campo) **não se confirma**: o `ScheduledFlowOpportunity` não grava `AveragePurchasesThisYear__c` (só o lê, na decisão de faixas). Corrige o item 3.3 da análise. Existe dependência de leitura: a classificação depende de a média estar atualizada pelo `OpportunityFlow`.
- Ordem exata entre triggers do SBQQ, trigger custom e flows no mesmo registro: **não determinei**. Não executei nem li o código do pacote.

**Validation rules:** 22 em Account+Opportunity (consulta retornou 22; vi só as de Opportunity: `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`, todas ativas, mais as de Account que a saída cortou). Não li as fórmulas. Em Order: 23 (`COUNT`), não aplicável se a demanda não gravar em Order. Workflow field updates em Account/Opportunity: 2 (`COUNT`), campos que alteram não verificados.
Risco: as regras de Opportunity mencionam Protheus, filial e condições de pagamento. Como o fluxo grava só em Account, não afetam o update de Account, mas não li as de Account.

## 4. Volume e dados de teste

| Objeto | Contagem na `sbx-eplast-dev` | Comando |
|---|---|---|
| Account | 0 | `sf data query -q "SELECT COUNT() FROM Account"` |
| Opportunity | 0 (ganhas: 0) | `SELECT COUNT() FROM Opportunity` e `... WHERE IsWon = true` |
| Order | 0 | `SELECT COUNT() FROM Order` |

A sandbox de dev **não tem dado para testar**. O teste exige criar dados sintéticos (sem dado real). Volume de produção não consultado (proibido); números do teste de volume dependem de P10.

## 5. Permissões

| Quem | Acesso aos 4 campos de Account | Comando |
|---|---|---|
| Permission set `Protheus` | Leitura e edição nos 4 | `FieldPermissions` com `Parent.IsOwnedByProfile = false` |
| Permission set `AncCrmIntegrationUser` | Só leitura nos 4 | idem |
| Permission set `sfdc_a360_sfcrm_data_extract` | Só leitura nos 4 | idem |
| 16 perfis (`FieldPermissions` de `Ranking__c`, `IsOwnedByProfile = true`): Administrador do sistema, Comercial, Comercial - Analista, Financeiro, Marketing, Pricing, Engenharia de Produtos, Usuário Padrão, Einstein Agent User, entre outros | Leitura e edição em `Ranking__c`. Para os outros 3 campos, só consultei permission sets. | `FieldPermissions` |

Um novo valor de picklist (MP, 3G) não exige permissão nova, mas o Protheus lê o campo (P8, ver abaixo).
OWD: a consulta a `Organization` retornou os campos vazios para `DefaultAccountAccess` e `DefaultOpportunityAccess`. **OWD não confirmado.** Não importa para um fluxo agendado (roda no contexto do sistema, a confirmar).

## O que não consegui confirmar

1. **Relatórios e painéis que usam `Ranking__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c`** (H1, critério 1). O retrieve de `Report`/`Dashboard` não retornou. Também não confirmei se existe relatório de mudança de classificação (P12). Precisa de retrieve por pasta ou de consulta específica.
2. **Layouts, páginas Lightning e quickActions** que exibem os 4 campos: não consultei.
3. **Outros flows** (Order, Quote, CPQ, Product, `Logs_Delete_Records`) e demais classes Apex custom: não retrieved. Não sei se gravam os 4 campos. Também não li `AccountBefore`, `OpportunityBefore`, `OpportunityAfter` nem `OrderTrigger` do SBQQ.
4. **Ordem de execução** entre triggers do SBQQ, triggers custom e flows no mesmo registro: não determinada.
5. **O Protheus consome `Ranking__c` e aceita MP e 3G** (P8). O permission set `Protheus` permite leitura e edição, mas isso não prova o fluxo de integração. Classes `ProtheusAPI`, `SendAccountToProtheus` e afins existem; não as li.
6. **Descrição dos campos** (`Description`) e a fórmula de `Opportunity.ThisYear__c`/`LastMonth__c`: a consulta de `CustomField` falhou na coluna e não repeti. A fórmula de `ThisYear__c` vem da análise, não desta coleta.
7. **Agendamento ativo do fluxo agendado** (`ScheduledFlow`/`CronTrigger`): a consulta não retornou linha. Não sei se o job está de fato agendado na dev.
8. **Dev × QA**: só a dev está conectada, com Org ID `00DHa000006vfMLMAY`. O username da conexão contém o texto "eplast2.qa", mesmo sendo a dev, o que mantém a suspeita do assessment. O Org ID da QA (`00DHa000006vZtmMAE`) vem do histórico do RAG, não foi confirmado. Divergência de metadata dev × QA: não comparei.
9. **OWD** de Account e Opportunity: a consulta retornou vazio.
10. **Alerta (`WorkflowAlert`) de ex-parceiro**: fora do escopo por decisão do card. Não pesquisei.
11. **Validation rules de Account** (nomes e fórmulas) e as 2 field updates de workflow: contagens apenas.
12. **`SFAgent2`**: confirmei só a existência na dev. Tópicos e ações não conferidos. Não está no escopo.
