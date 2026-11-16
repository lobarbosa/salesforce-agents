# EPLAST-34 — Recon da org

**Data da coleta:** 2026-11-15. Só leitura: metadata e contagens agregadas. Nenhum registro de negócio lido. Retrieve de recon não foi gravado em `force-app/`.

## 0. Org conectada

| Item | Resultado | Comando |
|---|---|---|
| Alias conectado | `sbx-eplast-dev` (única org listada), Connected | `sf org list` |
| Papel | Sandbox de dev. `IsSandbox = true`, API 68.0, Org ID 00DHa000006vfMLMAY | `sf org display`; `SELECT IsSandbox FROM Organization` |
| Dev distinta da QA? | **Não confirmado.** O username técnico da org contém o sufixo "qa". Só um alias está conectado, então não há como comparar com `sbx-eplast-qa` | `sf org list` |

## 1. O que já cobre o pedido (reaproveitar)

Nada cobre o resumo de reunião no todo. Há peças de apoio.

| Item | Existe? | Cobre | Prova |
|---|---|---|---|
| Bot `SFAgent2` | Sim, 1 Bot, planners `SFAgent2_v1` a `_v4` | Veículo para expor o resumo (regra 3 da conta, CA-09) | `SELECT DeveloperName FROM BotDefinition`; `... FROM GenAiPlannerDefinition` |
| Ação `AgregacaoPedidos` ("Query records with aggregate") | Sim, 1 por versão de plugin | Agregação sobre pedidos. É a base do recorte S&OP e do total de Order | `GenAiFunctionDefinition` (tooling) |
| Ação `ConsultarPedidos` ("Query records") | Sim | Consulta de pedidos | idem |
| Ação `IdentificarConta` ("Identify record by name") | Sim | Resolver conta pelo nome (recorte GDD) | idem |
| Ação `QueryRecords_*` ("Query records") | Sim, em 2 versões de plugin | Consulta genérica. Não há ação equivalente para Opportunity confirmada | idem |
| Tópico `insights_comerciais_*` ("Insights Comerciais sobre Pedidos"; na versão mais antiga, "Insights Comerciais e Acompanhamento") | Sim, é o tópico de negócio. Os demais são padrão (`agent_router`, `GeneralFAQ`, `off_topic`, `ambiguous_question`) | Ponto natural de extensão. Cada versão de plugin liga 2 a 3 funções | `GenAiPluginDefinition`, `GenAiPluginFunctionDef` (tooling) |
| Flow `Opportunity_PromptFlow_DadosOportunidade` (PromptFlow, ativo) e `Opportunity_PromptFlow_CotacaoPrimaria` | Sim | Dado de oportunidade para prompt. **Conteúdo não lido**, papel não confirmado | `FlowDefinitionView` |
| Relatórios e dashboards da Eplast sobre resumo, GDD, S&OP ou Board | **Não existem.** Há 380 relatórios e 20 dashboards. Os dashboards cujo título casa com "Board" são só "...Dashboard" de amostra ou padrão (Marketing, Adoption, Sales Manager, Activities, Einstein Conversation Insights). 0 relatórios com "Resumo", "GDD" ou "S&OP" no nome | `SELECT COUNT() FROM Report/Dashboard WHERE ...` |
| Ação ou tópico para Opportunity agregada por etapa/equipe | **Não existe** (não confirmado nas funções listadas). A criar | idem |
| Ação para os 4 recortes, data de corte e origem por número | **Não existe.** A criar | idem |

## 2. O que será tocado

Contagem de custom fields feita em `CustomField` (tooling) por `TableEnumOrId`.

| Objeto | Campos padrão usados pela demanda | Campos custom (total / sem descrição) | Registros |
|---|---|---|---|
| Opportunity | `Amount`, `StageName`, `CloseDate`, `OwnerId` (declarados na análise; **não reconfirmados campo a campo neste recon**) | 28 / 19 | 0 |
| Account | `Name` (idem) | 90 / 76 | 0 |
| Order | `TotalAmount`, `Status`, `EffectiveDate` (idem, não reconfirmados campo a campo) | 64 / 53 | 0 |

- Divergência do achado 4: o assessment citava 153 campos sem descrição. A contagem atual é 76 + 19 + 53 = 148 nos três objetos. A diferença de 5 não foi explicada.
- Nenhum campo custom foi identificado como necessário. Não há campo de meta, carteira ou pedido imputado confirmado. Não foi feita nova busca por nome neste recon e o resultado da análise (PA-08) não foi reproduzido aqui.
- Classes Apex `SendAccountToProtheus`, `SendAccountToProtheusTDF`, `SendOrderToProtheus` e `SendOrderToProtheusTDF` existem (Active). Estão fora do escopo e não devem ser tocadas.

## 3. Automação concorrente

A demanda só lê (PA-04, CA-05). Esta tabela vale se o design passar a gravar em algum desses objetos.

**Triggers Apex** (`SELECT ... FROM ApexTrigger`, tooling), todos Active:

| Objeto | Trigger | Eventos |
|---|---|---|
| Account | `AccountBefore` | before insert, before update |
| Account | `AccountTrigger` | before insert/update, after insert/update |
| Opportunity | `OpportunityBefore` | before insert, before update, before delete |
| Opportunity | `OpportunityTrigger` | after insert, after update |
| Opportunity | `OpportunityAfter` | after insert, after update |
| Order | `OrderTrigger` (linha 1) | before e after, insert, update e delete |
| Order | `OrderTrigger` (linha 2) | before update, after update |

- A tabela de triggers do SBQQ não foi mapeada: a consulta filtrou só pelo objeto e devolveu 7 triggers, dois deles com o nome `OrderTrigger`. Não identifiquei qual das duas linhas é do namespace SBQQ. Isso fica como incerteza.

**Flows ativos com gatilho no objeto** (`FlowDefinitionView`, `TriggerObjectOrEventId`):

| Objeto | Flow | Tipo |
|---|---|---|
| Account | `AccountTriggered` | RecordAfterSave |
| Account | `UpdateParentAccountUsedLimit` | RecordAfterSave |
| Account | `AccountUpdateEconomicGroup` | Scheduled |
| Opportunity | `Oportunidade_Industria` | RecordAfterSave |
| Opportunity | `OpportunityFlow` | RecordAfterSave |
| Opportunity | `ScheduledFlowOpportunity` | Scheduled |
| Order | `Order` | RecordAfterSave |
| Order | `Acionado_por_registro_Antes_de_atualizar_Pedido_Atribui_Id_externo_para_update_p` | RecordBeforeSave |
| Order | `OrderScheduledFlow` | Scheduled |

- A ordem de execução entre triggers e Flows no mesmo evento **não foi levantada** (sem leitura do corpo). Não é necessária enquanto a demanda não gravar.
- Flows `Scheduled` rodam sem ação do usuário. Pode haver gravação em Account, Opportunity e Order durante um teste de CA-05 (LastModifiedDate). O corpo deles não foi lido.

**Validation rules ativas** (`ValidationRule`, tooling): Order 17, Opportunity 16, Account 6. O assessment falava em 23 para Order. Conta atual: 17. A diferença não foi explicada. Em dev vazia, isso afeta só a criação de dado sintético (PA-13): o builder terá de satisfazer as regras ao criar Opportunity e Order de teste.

## 4. Marketing Cloud Connect (`et4ae5`)

A demanda não toca marketing (sem envio, PA-04). Registro para o arquiteto não propor campo nem objeto em paralelo.

| Item | Resultado | Prova |
|---|---|---|
| Classes Apex do namespace `et4ae5` | 523 | `SELECT NamespacePrefix, COUNT(Id) FROM ApexClass ... GROUP BY` |
| Objetos do namespace (amostra, `LIMIT 40`) | `et4ae5__Configuration__c`, `__ET4AEConfig__c`, `__ET4AE_Config__c`, `__Email_Linkage__c`, `__IndividualEmailResult__c`, `__IndividualLink__c`, `__MC_CDC_Journey__c`, `__SMSDefinition__c`, `__SMSJunction__c`, `__SendDefinition__c` e seus Share, History e ChangeEvent. A lista foi cortada em 40 e não é completa | `EntityDefinition WHERE NamespacePrefix='et4ae5'` |
| Campos `et4ae5` em Account, Opportunity e Order | 0 em cada um | `FieldDefinition WHERE NamespacePrefix='et4ae5'` |
| Flows `MCC_*` | Vários, ativos, ligados a objetos `et4ae5` (não a Account, Opportunity ou Order) | `FlowDefinitionView` |

Nada foi feito no Marketing Cloud.

## 5. Volume e dados de teste

| Objeto | `COUNT()` |
|---|---|
| Account | 0 |
| Opportunity | 0 |
| Order | 0 |
| EmailMessage | 0 |
| Campaign | 0 |
| CampaignMember | 0 |
| Lead | 0 |

A dev não tem dado para testar. Todo teste usa registro sintético com a marca `TESTE-EPLAST34` (PA-13, CA-12). Não há volume real para medir desempenho.

## 6. Permissões

| Item | Resultado | Prova |
|---|---|---|
| OWD interno | Account `ReadWrite`, Order `ReadWrite`, Opportunity `Read`. OWD externo `Private` nos três | `EntityDefinition` (`InternalSharingModel`, `ExternalSharingModel`) |
| Perfis com leitura de Opportunity e Order | Opportunity e Order: `Gerente de soluções`, `Gerente do contrato`, `Comercial`, `Comercial - Analista`, `Comercial - Analistas`. Só Opportunity (sem leitura de Order): `Comercial Padrão` | `ObjectPermissions` com `IsOwnedByProfile=true` |
| Total de perfis com leitura | Opportunity 21, Account 22, Order 20 | idem |
| Permission sets não gerenciados, sem namespace | 10. Quais objetos eles alcançam não foi levantado | `PermissionSet` |

- Perfis comerciais duplicados (`Comercial - Analista` e `Comercial - Analistas`) existem.
- O recorte Board, que consolida Opportunity e Order, não fica disponível para `Comercial Padrão` pela permissão de objeto.

## O que não consegui confirmar

1. Se `sbx-eplast-dev` é distinta de `sbx-eplast-qa`. Só um alias está conectado e o username técnico tem sufixo "qa".
2. O conteúdo do planner `SFAgent2_v4`: o retrieve estourou o tempo. O vínculo de tópicos e funções vem de consulta tooling. Não sei qual versão está ativa, nem as instruções do tópico `insights_comerciais`.
3. O papel do Flow `Opportunity_PromptFlow_DadosOportunidade`: o corpo não foi lido.
4. Quais das duas linhas `OrderTrigger` são do SBQQ, e a ordem de execução entre triggers e Flows no mesmo evento.
5. Se os Flows `Scheduled` de Account, Opportunity e Order gravam registros (relevante para CA-05).
6. Os campos padrão `Amount`, `StageName`, `CloseDate`, `OwnerId`, `TotalAmount`, `EffectiveDate` e `Status`: citados na análise, não reconfirmados campo a campo aqui.
7. Se existe campo de meta, carteira ou pedido imputado: a busca por nome da análise não foi repetida.
8. A diferença entre as contagens do assessment e as de hoje (campos sem descrição, 153 contra 148; validation rules de Order, 23 contra 17).
9. Quais objetos os 10 permission sets alcançam, e se há ação do SFAgent2 sobre Opportunity.
10. A tabela completa de objetos `et4ae5`: a consulta foi cortada em 40.
