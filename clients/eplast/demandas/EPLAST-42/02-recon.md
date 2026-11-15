# EPLAST-42 — Recon da org

**Data da coleta:** 2026-11-15
**Org:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`), confirmada com `sf org list` (única org conectada, status Connected). Sandbox de dev da esteira (regra 5 do cliente).
**Modo:** só leitura. Metadata e contagens agregadas. Os relatórios foram baixados para `/tmp/recon42` (fora do repositório) e só tiveram filtros lidos. Nenhum registro de negócio foi consultado.

---

## 1. O que já cobre o pedido

| Item | Achado | Comando que provou |
|---|---|---|
| Pasta de relatórios `MARKETINGCLOUD` | 60 relatórios. Tipos: 42 `ContactList`, 16 `LeadList`, 1 `AccountList`, 1 `OrderItemList`. Os API names têm sufixo aleatório (ex.: `REATIVOS_GERAL_rbp`, `LEADS_SP_2yf`). Há cópias `Cpia_de_*`. Existem relatórios que a análise não listou: `INATIVOS_GERAL`, `COMPRA_ULTIMOS_90_DIAS`, `POTENCIAIS_SEM_COMPRA`, `CONTAS_E_CONTATOS_RECORRENTES_6PU`, `CLASSIFICACAO_CONTAS_POR_CLASSE`. | `sf org list metadata --metadata-type Report --folder MARKETINGCLOUD`; `sf project retrieve start --metadata Report:MARKETINGCLOUD/<nome>` (todos os 60, em `/tmp`) |
| Filtro de opt-out de e-mail nos relatórios | 58 de 60 têm `EMAIL_OPT_OUT equals 0`. Sem o filtro: `CLASSIFICACAO_CONTAS_POR_CLASSE` e `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` (agregações de Account e OrderItem, não são lista de envio). | `grep -L '<column>EMAIL_OPT_OUT</column>'` nos 60 XML |
| Filtro de opt-out de celular nos relatórios | **Nenhum dos 60** filtra `et4ae5__HasOptedOutOfMobile__c`. | `grep -il HasOptedOutOfMobile` nos 60 XML: 0 |
| Recorte de prioridade e origem nos relatórios | **Nenhum dos 60** usa `PriorityBand__c` nem `MKT_Origem_Agrupada__c`. | `grep -E 'PriorityBand\|MKT_Origem'` nos 60 XML: 0 |
| Públicos de reativação | `SEM_COMPRA_91_A_180_DIAS`: `Account.LastPurchase__c` <= `N_DAYS_AGO:91` e >= `N_DAYS_AGO:180`. `SEM_COMPRA_181_A_365_DIAS`: <= `N_DAYS_AGO:181` e >= `N_DAYS_AGO:365`. `SEM_COMPRA_MAIS_DE_365_DIAS`: < `N_DAYS_AGO:365`. Faixas contíguas, sem lacuna. O dia 365 cai na faixa 181-365 e não na "mais de 365". Todos `ContactList`, com opt-out de e-mail. | retrieve dos 3 relatórios e leitura de `criteriaItems` |
| `REATIVOS_GERAL_rbp`, `RECORRENTES_ATIVOS_SUL_lXr`, `SAZONAIS_SP_qII`, `PROSPECTS_GERAL_vjU` | Filtram `TYPE` (campo `Account.Type`) = Reativo, Recorrente, Sazonal, Prospect, e opt-out de e-mail. Região por estado. | retrieve e leitura de filtros |
| `LEADS_SP_2yf` | `LeadList`, filtra `STATE = SP` e opt-out de e-mail. Sem filtro de `Status`, nem `IsConverted`. | retrieve e leitura de filtros |
| Pasta `Volume_Inativos` | A listagem devolveu **1** relatório: `Novo_relat_rio_Contas`. A análise dizia 3. | `sf org list metadata --metadata-type Report --folder Volume_Inativos` |
| Marketing Cloud Connect | Pacote `et4ae5` ("Marketing Cloud") instalado, mais `MCCA5PROD` (MarketingCloudConnectedApp). | `sf data query --use-tooling-api` em `InstalledSubscriberPackage` |
| Campos `et4ae5` nos objetos de marketing | `et4ae5__Activity__c` em `CampaignMember`. `HasOptedOutOfMobile` e `Mobile_Country_Code` em `Contact` e em `Lead`. Nada em `Campaign`. | Tooling `CustomField` com `NamespacePrefix='et4ae5'`; describe de `CampaignMember` |
| Agente SFAgent2 | Não conferido: a demanda não envolve assistente, resumo, recomendação nem linguagem natural (análise, 2.4). | não aplicável |

## 2. O que será tocado

| Objeto.campo | Tipo | Descrição/help | Observação | Comando |
|---|---|---|---|---|
| `Account.LastPurchase__c` | date | não conferido | Base das faixas `SEM_COMPRA_*`. Em 5 dos 60 relatórios. | describe de `Account` |
| `Account.Type` | picklist | não conferido | Valores: Inativo, Novo, Prospect, Prospect Indústria, Reativo, Recorrente, Sazonal, Stand-by, Encerrou atividades. | describe de `Account` |
| `Lead.PriorityScore__c` | double | com help text | Existe e aparece no describe. | describe de `Lead` |
| `Lead.PriorityBand__c` | string | com help text | Existe e aparece no describe. | describe de `Lead` |
| `Lead.MKT_Origem_Agrupada__c` | não confirmado | não confirmado | Existe na Tooling (`CustomField`, `TableEnumOrId='Lead'`), mas **não aparece no describe de `Lead`** do usuário da sessão. Provável falta de permissão de campo (FLS). | Tooling `CustomField` x describe de `Lead` |
| `Lead.LeadSource`, `Lead.Status`, `Lead.IsConverted` | picklist, picklist, boolean | n/a | `Status`: Aberto - Não contatado, Contatado, Fechado - Convertido, Fechado - Não convertido. | describe de `Lead` |
| `Lead.HasOptedOutOfEmail` | boolean | n/a | Standard. | describe de `Lead` |
| `Lead.et4ae5__HasOptedOutOfMobile__c` | custom do conector | n/a | Aparece no describe de `Lead`. | describe de `Lead` |
| `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__HasOptedOutOfMobile__c` | boolean | n/a | Presença na Tooling para o campo do conector; o describe de `Contact` não foi rodado. | Tooling `CustomField` |
| `CampaignMember.et4ae5__Activity__c` | campo do conector | n/a | Único campo custom do objeto. Objeto createable e queryable. | describe de `CampaignMember` |
| `Campaign` | sem campo custom | n/a | Contagem na Tooling: 0 campos custom. | Tooling `CustomField` |

Observação sobre o campo de retorno: o campo real é `et4ae5__Activity__c`. Não há outro campo de resultado de envio em `CampaignMember`.

## 3. Automação concorrente

| Objeto | Automação ativa | Comando |
|---|---|---|
| `Lead` | Flow `Lead_AfterInsert_AplicaRegraAtribuicao` (`AutoLaunchedFlow`, `RecordAfterSave`). Único. | `FlowDefinitionView` com `TriggerObjectOrEventLabel='Lead'` e `IsActive=true` |
| `Contact`, `Campaign`, `CampaignMember` | Nenhum Flow ativo. | `FlowDefinitionView` por objeto (0 linhas cada) |
| `Lead`, `Contact`, `Campaign`, `CampaignMember` | Nenhum `ApexTrigger`. | Tooling `ApexTrigger` (0 linhas) |
| `Lead` | Validation rules ativas: `Celular`, `Telefone`. | Tooling `ValidationRule` |
| `Contact` | Validation rules ativas: `Telefone`, `WhatsApp`. | Tooling `ValidationRule` |
| `Campaign`, `CampaignMember` | Nenhuma validation rule. | Tooling `ValidationRule` |
| `Account`, `Opportunity`, `Order` | Não consultado de novo. A análise decidiu não escrever nesses objetos (PA-03). O assessment (achado 1) segue como referência para a ordem de execução, se o design mudar isso. | n/a |

Ordem de execução afetada: só em `Lead`. Qualquer lead de teste criado dispara o Flow de atribuição (after-save) e passa pelas validation rules `Celular` e `Telefone`, que já bloqueiam formato de telefone. Dado sintético precisa respeitá-las. Não confirmei o conteúdo dessas regras.

## 4. Volume e dados de teste

| Objeto | Registros | Comando |
|---|---|---|
| `Lead`, `Contact`, `Account`, `Campaign`, `CampaignMember`, `Order`, `Opportunity` | 0 em todos | `sf data query "SELECT COUNT() FROM <obj>"` |

- A dev está vazia: todo teste exige dado sintético com prefixo `EPLAST42 TESTE`, criado pelos scripts de `fixtures/`.
- O bloqueio de "sObject type not supported" relatado na análise **não se repetiu**: as contagens de `Lead`, `Campaign` e `CampaignMember` funcionaram nesta sessão.
- Usuário de teste (regra 6), conforme a query indicada: duas linhas. `005bJ00000piKAaQAM` (ativo, perfil "Administrador do sistema") e `005bJ00000hBJmYQAW` (inativo, mesmo perfil). Usar o ativo.

## 5. Permissões

| Item | Achado | Comando |
|---|---|---|
| OWD | `Lead`: Private externo, ReadWriteTransfer interno. `Account` e `Contact`: Private externo, ReadWrite interno. `Campaign`: Private externo, FullAccess interno. | `EntityDefinition` |
| `PS_Marketing_Publicos` | Leitura em Account, Contact, Lead, Order, Product2. Campaign com criar e editar. FLS de leitura em `Account.LastPurchase__c`. **Sem FLS conferida para `PriorityBand__c` ou `MKT_Origem_Agrupada__c`.** | `ObjectPermissions` e `FieldPermissions` |
| `PS_Marketing_AnaliseCampanhas` | Leitura em Campaign, Lead, Opportunity. FLS de leitura em `Lead.MKT_Origem_Agrupada__c`. | idem |
| Atribuições desses dois permission sets | **0** usuários na dev. | `COUNT()` em `PermissionSetAssignment` |
| Outros que alcançam `Lead` e `Campaign` | `Modify_All`, `MarketingUsers`, `GeneralUsers` (só Campaign), `AncMarketingIntegrationUser`, `sfdc_a360`, entre outros de plataforma. | `ObjectPermissions` com `LIMIT 30` (lista cortada) |

## 6. Riscos para o desenho

- **Opt-out de celular não está em nenhum relatório.** O critério CA-03 só passa se o filtro for acrescentado, ou se o público de mensagem não vier destes relatórios.
- **Os 16 `LeadList` não filtram `Status` nem `IsConverted`.** Lead convertido pode entrar no público. A análise (5a) previa excluir convertidos.
- **Sem recorte de prioridade e origem.** CA-05 e CA-06 não têm relatório que os exercite hoje.
- **Faixa de reativação:** o dia 365 pertence a `SEM_COMPRA_181_A_365_DIAS`, e a faixa 3 só começa no dia 366.
- **Todos os públicos de reativação e relacionamento são `ContactList`** (agrupados por `Account.Type` e `LastPurchase__c`). A janela de reativação mede a conta, não o contato.

## O que não consegui confirmar

1. **`Lead.MKT_Origem_Agrupada__c`:** não aparece no describe do usuário da sessão. Não sei o tipo, os 13 valores nem se há descrição. Preciso de um usuário com FLS, ou de um retrieve do `CustomField`.
2. **Conteúdo das validation rules** `Celular` e `Telefone` (Lead) e `Telefone` e `WhatsApp` (Contact). Só os nomes e o status foram conferidos.
3. **Mecanismo pelo qual o Marketing Cloud lê o público** (relatório, Data Extension, sincronização do conector). Nada disso é visível pela org sem acessar o Marketing Cloud, o que está proibido.
4. **Sentido da sincronização de opt-out** entre Marketing Cloud e CRM. Não confirmado.
5. **Pasta `Volume_Inativos`:** 1 relatório listado contra 3 na análise. Pode ser divergência de listagem; não abri o relatório.
6. **Histórico de EPLAST-36** (35 relatórios com filtro de opt-out). Hoje são 58. Não verifiquei o que mudou.
7. **Descrição (`Description`) dos campos** `Account.LastPurchase__c` e `Account.Type`, e se `PriorityBand__c` e `PriorityScore__c` têm `Description` além do help text.
8. **Automação em `Account`, `Opportunity` e `Order`:** não reconsultada nesta sessão.
9. **Acesso do usuário de integração do conector** (`MarketingUsers` e outros) a `PriorityBand__c` e `MKT_Origem_Agrupada__c`: não confirmado.
10. **Dado de teste em QA:** a QAS não foi consultada nesta etapa.
