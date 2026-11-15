# Recon — EPLAST-27: Próxima melhor ação por cliente

**Org:** `sbx-eplast-dev` (`sf org list`: Sandbox, Connected). Instância `https://eplast--qa.sandbox.my.salesforce.com`, API 68.0 (`sf org display --json`, só `instanceUrl` e `apiVersion`).
**Atenção:** o alias de dev aponta para uma instância com sufixo `--qa` (achado 6 do assessment). Não foi possível provar daqui que dev e QA são orgs distintas. Ver "O que não consegui confirmar".
Só leitura: metadata e `COUNT()`. Nenhum registro de negócio foi lido.

## 1. O que já cobre o pedido

| Item | Achado | Comando |
|---|---|---|
| Agente `SFAgent2` | Existe (`BotDefinition`). Planners `SFAgent2_v1` a `v4`. **As 4 versões do Bot estão `Inactive` na dev** | `SELECT DeveloperName FROM BotDefinition`; `SELECT ... FROM BotVersion`; `SELECT DeveloperName FROM GenAiPlannerDefinition` |
| Tópico `insights_comerciais` | Há 4 registros `GenAiPluginDefinition` com esse prefixo, em 2 formas. Duas dizem "analisa o histórico de pedidos e oportunidades de uma conta, gera insights para negociação e identifica oportunidades paradas, pedidos pendentes e…" (texto cortado a 220 caracteres). As outras duas dizem "Analisa o histórico de pedidos de uma conta e gera insights e sugestões práticas para apoiar o vendedor…". Os rótulos variam: "Insights Comerciais e Acompanhamento" e "Insights Comerciais sobre Pedidos" | `SELECT DeveloperName, Description FROM GenAiPluginDefinition WHERE DeveloperName LIKE 'insights_comerciais%'` |
| Ações do agente | `ConsultarPedidos` (`queryRecords`), `AgregacaoPedidos` (`queryRecordsWithAggregate`), `IdentificarConta` (`identifyRecordByName`), todas `standardInvocableAction`, repetidas por versão. Existe também `QueryRecords_17208408f837c47` (`queryRecords`), fora das 3 ações citadas no CLAUDE.md do cliente | `SELECT DeveloperName, InvocationTarget, InvocationTargetType FROM GenAiFunctionDefinition` |
| Motor de recomendação nativo | Não existe: 0 `RecommendationStrategy` | `SELECT COUNT() FROM RecommendationStrategy` (Tooling), `totalSize: 0` |
| Relatórios e painéis | 380 relatórios e 20 painéis na org. Nenhum relatório com nome contendo Risco, parad, sem compra, Próxima ou última compra | `SELECT COUNT() FROM Report/Dashboard`; `SELECT Name FROM Report WHERE Name LIKE ...` (0 linhas) |
| Flow `ScheduledFlowOpportunity` | Existe, ativo, agendado, objeto Oportunidade. Há 1 registro em `ScheduledFlowOpportunitySetting__mdt`. Não li o que o Flow faz. Pode já cobrir "oportunidade parada" (tema da EPLAST-28) | `FlowDefinitionView`; `SELECT COUNT() FROM ScheduledFlowOpportunitySetting__mdt` |
| Custom Metadata existentes | `Protheus__mdt`, `RankingRange__mdt` (7 linhas), `ScheduledFlowOpportunitySetting__mdt` (1 linha), `TriggerUtility__mdt`. Nenhum é de limiar de próxima ação. Não li os campos | `sf sobject list --sobject custom` filtrado por `__mdt` |
| Flows `MCC_*` | Flows do conector Marketing Cloud (Envio de email, Envio acionado etc.), ativos. Confirmam a integração com o MC. Não foram abertos | `FlowDefinitionView` |

Conclusão: o único ponto de partida existente para a sugestão é o `SFAgent2` (tópico `insights_comerciais`). Não há relatório, campo de score ou motor que entregue a "próxima ação". A regra A1 a A3 da análise não existe pronta na org.

## 2. O que será tocado (campos lidos pela regra)

| Campo | Tipo confirmado | Descrição | Comando |
|---|---|---|---|
| `Account.Risk__c` | Lista de opções. Valores: A, B, C, D, E; **E é o padrão** | Sem descrição | `SELECT Metadata FROM CustomField` (Tooling), `valueSet` |
| `Account.LastPurchase__c` | Resumo da totalização, MAX de Oportunidade | Sem descrição | `FieldDefinition` e `CustomField` |
| `Account.AccountHasCheckInTask__c` | Existe. Preenchimento não verificado | Sem descrição | `CustomField` (Tooling) |
| `Account.OwnerId` | Pesquisa (Usuário) | n/a | `FieldDefinition` |
| `Opportunity.LastActivityInDays` | Número(9,0) | n/a | `FieldDefinition` |
| `Opportunity.LastStageChangeInDays` | Número(9,0) | n/a | idem |
| `Opportunity.StageName`, `IsClosed` | Lista de opções; caixa de seleção | n/a | idem |
| `Opportunity.LastActivityDate` | Data | n/a | idem |
| `Opportunity.IqScore` | Número(9,0), significado não confirmado | n/a | idem (fora da v1) |

Implicação para P1: os valores de `Risk__c` são letras A a E, e nenhuma fonte na org diz qual delas é "risco". O padrão E sugere o valor sem classificação ou o mais baixo, mas isso é hipótese. A definição de "risco" fica em aberto para o arquiteto resolver pela regra 4 (premissa configurável).

## 3. Automação concorrente (Account, Opportunity, Order)

A v1 só lê, mas a regra 3 do cliente e o assessment pedem o mapa.

| Objeto | Componente | Evento | Fonte |
|---|---|---|---|
| Account | Trigger `AccountBefore` | before insert, before update | `ApexTrigger` (Tooling) |
| Account | Trigger `AccountTrigger` | before e after, insert e update | idem |
| Account | Flow `AccountTriggered` | after save, create e update | `FlowDefinitionView` |
| Account | Flow `UpdateParentAccountUsedLimit` | after save, create e update | idem |
| Account | Flow `AccountUpdateEconomicGroup` | agendado | idem |
| Opportunity | Trigger `OpportunityBefore` | before insert, before update | `ApexTrigger` |
| Opportunity | Triggers `OpportunityTrigger` e `OpportunityAfter` | after insert, after update | idem |
| Opportunity | Flow `OpportunityFlow` | after save, create e update | `FlowDefinitionView` |
| Opportunity | Flow `Oportunidade_Industria` | after save, update | idem |
| Opportunity | Flow `ScheduledFlowOpportunity` | agendado | idem |
| Order | Trigger `OrderTrigger` (2 registros, o do pacote CPQ e o custom: colisão de nome) | before e after, insert e update | `ApexTrigger` |
| Order | Flow `Order` | after save, create e update | `FlowDefinitionView` |
| Order | Flow `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p...` | before save | idem |
| Order | Flow `OrderScheduledFlow` | agendado | idem |
| Task | Flow `TaskCreatedOrUpdated` | after save, create e update | idem |

Validation rules ativas: Account 6, Opportunity 16 (`SELECT COUNT() FROM ValidationRule WHERE Active=true`, Tooling). Order não foi recontado (o assessment cita 23).

Ordem de execução entre triggers e Flows no mesmo evento não foi mapeada além desta lista. Como a v1 é só leitura (sem DML), nenhum desses componentes dispara pela consulta. O que invalidaria isso é qualquer componente que grave em Account, Opportunity ou Task.

## 4. Volume e dados de teste

| Objeto | Registros | Comando |
|---|---|---|
| Account | 0 | `SELECT COUNT() FROM Account` |
| Opportunity | 0 | idem |
| Order | 0 | idem |
| Task | 0 | idem |

A dev não tem massa. Todos os cenários Gherkin exigem massa fictícia (a análise prevê criá-la em QA). A massa precisa satisfazer as 16 validation rules de Opportunity e as 6 de Account, e atravessar os triggers e Flows da seção 3.

## 5. Permissões

| Item | Achado | Comando |
|---|---|---|
| OWD Account | `ReadWrite` | `SELECT QualifiedApiName, InternalSharingModel FROM EntityDefinition` |
| OWD Opportunity | `Read` | idem |
| Permission sets não ligados a perfil | 180 | `SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile=false` |
| PS com leitura em Account (amostra de 20) | `sfdc_cpq`, `SteelBrickCPQStandardObjectsAccess`, `Protheus`, `Modify_All`, `SalesUsers`, `MarketingUsers`, `GeneralUsers` e outros | `ObjectPermissions` |

**Conflito com um critério de aceite:** o cenário "Vendedor não recebe sugestão de conta que não é da sua carteira" assume que a conta de outro vendedor fica invisível. Com OWD Account `ReadWrite`, qualquer usuário interno vê a conta. O resultado "não revela dados" não decorre do compartilhamento padrão. O arquiteto precisa reescrever o critério ou tratar o recorte de carteira de outra forma. Não verifiquei regras de compartilhamento nem hierarquia de papéis.

Não identifiquei qual perfil ou permission set dá acesso de uso ao `SFAgent2` para o vendedor. Consulta de `SetupEntityAccess` por classe com nome "Agent" retornou 1 linha e não responde a pergunta.

## Marketing Cloud (regra 2 do cliente)

A v1 não envia nada. A sugestão aparece só no assistente. Nada a alimentar no Marketing Cloud nesta demanda. Os Flows `MCC_*` já existem na org e não devem ser tocados.

## O que não consegui confirmar

- **Qual valor de `Risk__c` significa risco.** Valores A a E, padrão E, sem descrição no campo. Nenhuma validation rule ou Flow foi lido para inferir.
- **Se dev e QA são orgs distintas.** O alias `sbx-eplast-dev` mostra instância `eplast--qa`. A QA não foi consultada (guardrail: esta etapa roda na dev).
- **Qual versão do `SFAgent2` é a viva.** Todas as 4 estão `Inactive` na dev. Não sei qual versão referencia qual dos 4 tópicos `insights_comerciais`. Não li as instruções completas do tópico nem o mapeamento planner para tópico para ação.
- **O que faz `ScheduledFlowOpportunity`** e o que contém o registro de `ScheduledFlowOpportunitySetting__mdt`. Pode sobrepor A2 ou a EPLAST-28. Não li o corpo do Flow nem os campos do CMDT (a consulta de campos por `FieldDefinition` voltou vazia).
- **Se `AccountHasCheckInTask__c` é preenchido** e por qual automação. A dev não tem dados.
- **Contagem de validation rules de Order** e a ordem de execução completa entre triggers e Flows (inclusive a colisão do `OrderTrigger`).
- **Regras de compartilhamento e papéis** que restringem a carteira do vendedor sobre Account.
- **Quais usuários ou perfis acessam o `SFAgent2`.**
- **Se as ações padrão (`queryRecords`, `queryRecordsWithAggregate`) conseguem expressar a regra A1 a A3** (comparação de datas, prioridade) ou se exigem Apex invocável. Não testado; não há dados.
- **Conteúdo do recon de 2026-11-10 e de `[demandas/EPLAST-28/02-recon.md]`.** Não foram relidos nesta rodada. As afirmações da análise que dependem deles não foram reconfirmadas, salvo as listadas acima.
