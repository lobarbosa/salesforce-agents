# EPLAST-47 — Recon da org (etapa 2, redesenho só declarativo)

**Org:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`), única conectada em `sf org list` (Status Connected). Só leitura: consultas de metadata, contagens agregadas e retrieve para pasta temporária descartada. Nenhum deploy, DML ou toque no Marketing Cloud.
**Contexto lido:** `01-analise.md`, `comentarios-do-card.md` (última decisão, 16/11: sem gravação em massa em Account e sem Apex novo; alternativas Ranking como fórmula ou objeto de classificação ligado à conta, gravado pelo Flow agendado).
**Atenção:** a dev já contém o build da rodada anterior (Flow v2, dois Custom Metadata Types, relatório provisório, histórico em Ranking). A análise descrevia a v1. O redesenho parte do que está na dev hoje.

## 1. O que já cobre o pedido

| Item | Estado confirmado na dev | Cobre o pedido? | Comando |
|---|---|---|---|
| Flow `ScheduledFlowOpportunity` | v2 Active, v1 Obsolete. Agendado em `Opportunity` com filtro `IsWon = true`, Daily 15:47Z, decisão do dia lida de `GetSetting.RunDayOfMonth__c`. Atualiza `Account` (`UpdateAccount`: `LastMonthPurchaseValue__c` e `Ranking__c`) com `faultConnector` para `LogFault` (cria `IntegrationLog__c`) e ação `SendFaultEmail` para o destinatário configurado. Classifica por `AveragePurchasesThisYear__c` percorrendo `RankingRange__mdt` | Parcial. É o desenho que a QA reprovou: o update em Account dispara o `AccountTrigger` | `sf data query -t` em `Flow`; `sf project retrieve start -m Flow:ScheduledFlowOpportunity` (temp) |
| `RankingRange__mdt` | Existe, 7 registros: MP 10.000, PP 35.000, P 80.000, M 160.000, G 500.000, GG 1.000.000 (`SortOrder__c` 1 a 6) e `X3G` com `Ranking__c` = 3G, `UpperLimit__c` nulo (sem teto), ordem 7. Campos: `Ranking__c`, `SortOrder__c`, `UpperLimit__c` | Sim, as faixas já estão como configuração. Reaproveitável por qualquer desenho | `sf data query -q "SELECT ... FROM RankingRange__mdt"` |
| `ScheduledFlowOpportunitySetting__mdt` | Existe, registro `Default`, `RunDayOfMonth__c` = 14. Campo `FaultRecipient__c` existe; se está preenchido não foi confirmado (consulta com `IS NULL` não é aceita em SOQL de campo) | Sim, dia e destinatário já são configuráveis | idem; retrieve do objeto |
| `Account.Ranking__c` | Picklist, 7 valores ativos MP, PP, P, M, G, GG, 3G; `trackHistory` = true; tem descrição | Sim (critério 13 da análise já atendido na dev) | `sf project retrieve start -m CustomField:Account.Ranking__c` |
| Relatório `AccountRankingChanges` ("Mudancas de Classificacao de Contas") | Existe, pasta "EPLAST-47 Relatorios (provisorio, P12)", Tabular, tipo `AccountAuditHistory` (Histórico da conta), colunas `ACCOUNT.NAME`, `CREATED_DATE`, `field_key`, `OLDVAL`, `NEWVAL` | Sim para o critério 14, se o filtro estiver em Ranking (filtro não conferido) | `sf data query -q "... FROM Report ..."`; `sf api request rest .../analytics/reports/<id>/describe` |
| Relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE` e outros na pasta "MARKETING CLOUD" | 7 relatórios (classificação por classe, compra 90 dias, sem compra 91-180, 181-365, mais de 365, potenciais, produto). São de segmentação para o Marketing Cloud. Pré-existentes: não foi conferido se leem `Ranking__c` | Não é o pedido, mas é consumidor provável de `Ranking__c`. Não alterar sem checar | `sf data query -q "SELECT ... FROM Report WHERE Name LIKE ..."` |
| Painel sobre Ranking, compras ou classificação | 0 encontrados por título | Não | `sf data query -q "SELECT Id, Title FROM Dashboard WHERE Title LIKE ..."` |
| Objeto de classificação ligado à conta (alternativa do redesenho) | Não existe objeto próprio para isso. Não procurei por nome parecido além de `RankingRange`, que é só a tabela de faixas | Não | `sf data query -t -q "... FROM CustomObject WHERE DeveloperName LIKE '%RankingRange%' OR ... '%ScheduledFlow%'"` |
| Agente `SFAgent2` | Existe como `GenAiPlannerBundle`, com várias versões na dev (v3, v5, v7, v10, v13 listadas; a v13 é de 16/11). A demanda não é de assistente e nenhuma referência aos campos desta demanda foi verificada nos tópicos | Não aplicável | `sf org list metadata -m GenAiPlannerBundle` |

## 2. O que será tocado

| Componente | Tipo / detalhe confirmado | Descrição | Comando |
|---|---|---|---|
| `Account.Ranking__c` | Picklist, 7 valores, histórico ligado. Picklist não pode virar fórmula sem recriar o campo | Tem | retrieve do campo |
| `Account.LastMonthPurchaseValue__c` | Currency, `trackHistory` false | Tem (explica que guarda a soma do ano, apesar do rótulo "Último Mês") | retrieve do campo |
| `Account.AveragePurchasesThisYear__c` | Currency, `trackHistory` false | Sem descrição | retrieve do campo |
| `Account.TotalPurchasesThisYear__c` | Currency, `trackHistory` false | Sem descrição | retrieve do campo |
| `Opportunity.ThisYear__c` | Checkbox com fórmula `IF(YEAR(DATEVALUE(CreatedDate)) = YEAR(DATEVALUE(NOW())), true, false)` (data de criação, como decidido na P2) | Não conferida | retrieve do campo |
| `IntegrationLog__c` | Objeto usado pelo `LogFault` do Flow (campos `ExecutionDate__c`, `IntegrationAction__c`, `ResponseBody__c`, `ResponseStatus__c`). Definição do objeto não retrievada | Não conferida | leitura do XML do Flow |
| Leitores dos campos | Permission set `Protheus` tem `Ranking__c`, `LastMonthPurchaseValue__c` e `AveragePurchasesThisYear__c` com `readable` e `editable` verdadeiros (o `editable` aparece no mesmo bloco de campos; confira o par por campo no XML) | n/a | `sf project retrieve start -m PermissionSet:Protheus` |
| Escritores dos campos | Flow `ScheduledFlowOpportunity` v2 (`LastMonthPurchaseValue__c`, `Ranking__c`, lê `AveragePurchasesThisYear__c`); Flow `OpportunityFlow` v2 Active (`AveragePurchasesThisYear__c`, `TotalPurchasesThisYear__c`). Nenhum dos outros 9 Flows retrievados referencia os 4 campos | n/a | grep nos XML de 11 Flows retrievados |

Não consegui provar que nenhum Apex, layout, página ou relatório (fora o descrito) lê ou grava esses campos: só retrievei `AccountTriggerHandler`, `AccountTriggerHelper`, `OpportunityTriggerHandler` e `TriggerUtility`, e nenhum cita os 4 campos.

## 3. Automação concorrente

### Account (o ponto crítico do redesenho)

| Automação | Evento | O que faz de relevante | Comando |
|---|---|---|---|
| `AccountTrigger` (custom, Active) | before insert/update, after insert/update | before: `validateCNPJ` (só dá erro se `CompanyDocument__c` mudou ou é insert). after update (se `!System.isQueueable()`): `updateAccountInfoFromCNPJ` | `sf data query -t` em `ApexTrigger`; retrieve do trigger |
| `AccountTriggerHelper.updateAccountInfoFromCNPJ` | after update, para cada conta | Se `CompanyDocument__c` mudou: `System.enqueueJob(new UpdateAccountCompanyInfo(...))`. **Senão: `System.enqueueJob(new SendAccountToProtheus(...))`**. Não filtra por campo alterado, então toda atualização de `Ranking__c` ou de valor de compra enfileira um envio ao Protheus por conta (limite de 50 enqueue por transação) | retrieve de `AccountTriggerHelper`, linhas 18 a 28 |
| Bypass | `TriggerUtility.bypassTrigger` lê `TriggerUtility__mdt` registro `TriggerExecution`, campo `BypassTrigger__c`. É chave global: desliga todos os triggers que a consultam (Account e Opportunity), não só este caso. O `AccountTrigger` retorna logo se verdadeiro | retrieve de `TriggerUtility` |
| `AccountBefore` (trigger do pacote SBQQ, Active) | Account | Trigger do CPQ. Corpo não lido (pacote gerenciado) | `sf data query -t ... WHERE NamespacePrefix='SBQQ'` |
| Flow `AccountTriggered` (Active) | Account create/update, after save | Opera em `EconomicGroup__c`, `Task`, `User`, `Profile`. Critério de entrada não conferido, então não sei se uma mudança em `Ranking__c` o aciona | retrieve do Flow |
| Flow `UpdateParentAccountUsedLimit` (Active) | Account create/update, after save | Atualiza Account (3 referências ao objeto). Critério de entrada não conferido | retrieve do Flow |
| Flows agendados em Account: `AccountUpdateEconomicGroup` (Active), `Account` (Obsolete) | Scheduled | Nenhuma referência aos 4 campos | retrieve + grep |
| Validation rules ativas em Account (6) | before save | `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk`. Não conferi a fórmula de nenhuma: não sei se alguma bloqueia o update de uma conta com dado incompleto | `sf data query -t ... FROM ValidationRule` |

### Opportunity

| Automação | Evento | Observação | Comando |
|---|---|---|---|
| `OpportunityTrigger` (custom, Active) | after insert, after update (`!System.isQueueable()` e sem bypass) | `OpportunityTriggerHandler` enfileira `OpportunityTriggerHelper` em toda inserção e atualização. Helper não lido | retrieve do trigger e do handler |
| `OpportunityBefore`, `OpportunityAfter` (SBQQ, Active) | Opportunity | Triggers do pacote CPQ | `sf data query -t ApexTrigger` |
| Flow `OpportunityFlow` (v2 Active, última modificação 2026-02-03) | Opportunity create/update, after save | Cria cotação CPQ, envia análise financeira e grava `AveragePurchasesThisYear__c` e `TotalPurchasesThisYear__c` na conta (updates em Account nas linhas 2038 a 2107 do XML). Esses updates também disparam o `AccountTrigger` | retrieve do Flow |
| Flow `Oportunidade_Industria` (Active) | Opportunity update, after save | Sem referência aos 4 campos | retrieve + grep |
| Flow `Opportunity_Scheduled_AlertaParada` | Opportunity, agendado | **Draft** (não ativo) | retrieve + grep |
| Validation rules ativas em Opportunity (16) | before save | `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `LossReason`, `PriceBook`, `TaxAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`. Só importam se o desenho gravar em Opportunity | `sf data query -t ... FROM ValidationRule` |

### Order e Marketing Cloud Connect

- `OrderTrigger` existe duas vezes em Order (Active): uma é o `OrderTrigger` do SBQQ (confirmado por `NamespacePrefix`), a outra é o trigger custom do mesmo nome. Não lidos; o desenho não grava em Order.
- `et4ae5` instalado: 523 classes Apex no namespace e 11 triggers ativos em objetos do próprio pacote (`et4ae5__SendDefinition__c`, `__SMSDefinition__c`, `__IndividualEmailResult__c`, `__Automated_Send__c`, `__JB_*` e em `User`). **Nenhum trigger do `et4ae5` em Account, Opportunity ou Order.** Consulta: `sf data query -t -q "... FROM ApexTrigger WHERE NamespacePrefix IN ('SBQQ','et4ae5')"` (resultado cortado em 30 linhas; os do SBQQ em Account/Opportunity/Order foram confirmados por consulta própria). Campos e objetos do `et4ae5` que referenciem Account não foram levantados.

## 4. Volume e dados de teste

| Objeto | Contagem na dev | Comando |
|---|---|---|
| Account | 0 | `sf data query -q "SELECT COUNT() FROM Account" --json` (`totalSize`) |
| Opportunity | 0 | idem |
| Order | 0 | idem |
| AccountHistory | 0 | idem |
| Flows ativos (todos) | 52 | `sf data query -t -q "SELECT COUNT(Id) FROM Flow WHERE Status='Active'"` |
| CronTrigger (jobs agendados) | 8 | `sf data query -q "SELECT COUNT() FROM CronTrigger"` |

- A dev não tem dado de negócio. O teste exige criar dados sintéticos pelos scripts de `fixtures/` (regra 6 da conta). Criar Opportunity dispara `OpportunityFlow`, CPQ e a cadeia do Protheus (autorizado pelo responsável em 15/11, só dados "TESTE EPLAST-47", menor volume possível).
- Usuário de teste (regra 6): a consulta `Username da conta de serviço da Konecta (filtro da regra 6 da conta)` devolveu **dois** usuários, ambos com perfil "Administrador do sistema": `005bJ00000hBJmYQAW` (IsActive = false) e `005bJ00000piKAaQAM` (IsActive = true). Usar o ativo. Não alterar perfil, permissão ou papel.

## 5. Permissões

| Item | Confirmado | Comando |
|---|---|---|
| Permission set `Protheus` | Dá acesso a `Account.Ranking__c`, `LastMonthPurchaseValue__c`, `AveragePurchasesThisYear__c`. Um objeto novo de classificação precisaria entrar nele, se o ERP for ler dele (P8 segue aberta) | retrieve de `PermissionSet:Protheus` |
| Permission sets `PS_Comercial_*` (ScorePrioridade, ResumoClienteAgente, AssistenteAcoes etc.) | Existem na dev; não abri o que concedem. Não sei se algum dá acesso aos campos desta demanda | `sf org list metadata -m PermissionSet` |
| OWD de Account e de Opportunity | Não consultado | n/a |
| Perfis com acesso aos campos | Não consultado (`ObjectPermissions` não é suportado por essa consulta) | n/a |

## O que não consegui confirmar

1. **Critério de entrada dos Flows `AccountTriggered` e `UpdateParentAccountUsedLimit`.** Disparam em Account após salvar; não sei se reagem à mudança de `Ranking__c` ou de valor de compra.
2. **Corpo de `OpportunityTriggerHelper`, `SendAccountToProtheus` e `UpdateAccountCompanyInfo`.** Só li as chamadas de enqueue. Não sei se o envio ao Protheus leva `Ranking__c`.
3. **Fórmula das 6 validation rules de Account.** Não sei se alguma bloquearia update de conta com dado incompleto (relevante se o Flow continuar gravando em Account).
4. **Filtro do relatório `AccountRankingChanges`.** Vi o tipo e as colunas; não conferi se filtra por `Ranking__c`. O mesmo vale para o que os 7 relatórios da pasta "MARKETING CLOUD" leem.
5. **Se `FaultRecipient__c` está preenchido** no registro `Default`. A P11 segue sem endereço informado.
6. **Se o Protheus aceita MP e 3G** (P8) e o que `SendAccountToProtheus` serializa.
7. **Layouts, páginas Lightning, outros relatórios e classes Apex** (fora as 4 que li) que lerem os 4 campos de compra. Só Flows e o permission set `Protheus` foram varridos.
8. **Objetos e campos do `et4ae5` ligados a Account**, e se o Marketing Cloud Connect lê `Ranking__c` (regra 2 da conta). Só confirmei que o pacote está instalado e que não tem trigger em Account, Opportunity ou Order.
9. **OWD de Account/Opportunity e perfis** com acesso aos campos.
10. **Se `SFAgent2` (v13) referencia `Ranking__c` ou os campos de compra.** Versões listadas; tópicos e ações não lidos nesta etapa.
11. **Estado da QA.** Não é minha org; pelo card, a QA ficou com a config no dia 15 e o Flow v4, e a classificação em massa estourou o limite de 50 queueables. Isso vem do card, não de consulta que eu fiz.
12. **Dois Flows entregues como Active não coincidem com a v1 descrita na análise** (a dev está na v2 de `ScheduledFlowOpportunity` e `OpportunityFlow`). Não comparei a v2 da dev com a v4 da QA.
