# Recon — EPLAST-37 · Classificação de clientes em ativos, inativos e potenciais

**Org confirmada:** `sbx-eplast-dev` (Org Id `00DHa000006vfMLMAY`, sandbox, Connected), conferida com `sf org list` em 2026-11-15. É a sandbox "QA" da Eplast (regra 5 do cliente; não é risco). Coleta de 2026-11-15; vence em 2026-11-22. A QAS (`sbx-eplast-qa`) não foi consultada nesta etapa.
**Preflight (`00-preflight.md`):** sem bloqueios, sem outra demanda nos mesmos componentes, nada a conferir na org (demanda sem componentes no repositório).
**Método:** só metadata e `COUNT()`. Nenhum registro lido. Retrieves foram para um projeto descartável em `/tmp/reconp`, nunca para `force-app/` do repositório.

---

## 1. O que já cobre o pedido

| Item | Situação confirmada | Comando que provou | Leitura para o desenho |
|---|---|---|---|
| `Account.LastPurchase__c` ("Última Compra") | Roll-up: `MAX(Opportunity.CloseDate)` filtrado por `Opportunity.StageName = 'Fechado/Ganho'`, chave `Opportunity.AccountId`. Sem descrição. | Tooling `CustomField` (Metadata, DeveloperName=LastPurchase) | Data da última compra ganha. Confirma a premissa P7 da análise (compra = oportunidade ganha). |
| `Account.Inactive__c` ("Inativo") | Fórmula Checkbox: `IF((today() - LastPurchase__c) > 90, true, false)`, `formulaTreatBlanksAs = BlankAsZero`. Sem descrição. | Tooling `CustomField` (Metadata, DeveloperName=Inactive) | Confirma 90 dias, com `>` estrito: 90 dias é Ativo, 91 é Inativo (CA-04). **Ponto de atenção:** com `LastPurchase__c` vazio e `BlankAsZero`, o comportamento da fórmula não foi exercitado (0 contas). Pela regra de data em branco tratada como zero, é provável que dê `true`; é inferência, ver "Não confirmei". A precedência da análise (Potencial antes de `Inactive__c`) já cobre. |
| Relatórios na pasta `MARKETING CLOUD` (DeveloperName da pasta `MARKETINGCLOUD`) | 58 relatórios, 49 tabulares. Todos os 7 abertos têm `reportType = ContactList`, `scope = organization` e filtro `EMAIL_OPT_OUT = 0`. | `SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'`; retrieve `Report:MARKETINGCLOUD/...` | Ver tabela abaixo. |
| Agente `SFAgent2` | Existe, `Type = InternalCopilot`. | `SELECT DeveloperName, Type FROM BotDefinition` | Regra 3 do cliente vale. Tópicos e ações não mapeados (ver "Não confirmei"). Existem tópicos `Insights Comerciais ...` e `Ações Comerciais` (`acoes_comerciais_EPLAST29`) na lista de `GenAiPluginDefinition`, sem vínculo confirmado com o `SFAgent2`. |
| Campo único de classe de relacionamento | Não existe campo dedicado em Account. O mais próximo é `Account.Type` (picklist manual, 9 valores, segundo a análise). | Não reconfirmado nesta sessão (describe feito na análise) | Dado de relatório depende de `Type` manual nos 7 abertos (abaixo). |

**Os 7 relatórios abertos (critério de cada um)**

| Relatório (DeveloperName) | Filtro de classe | Fonte | Colunas pessoais |
|---|---|---|---|
| `INATIVOS - GERAL` (`INATIVOS_GERAL`) | `TYPE = Inativo` | `Type` manual | nome, cargo, endereço, 3 telefones, e-mail |
| `REATIVOS - GERAL` (`REATIVOS_GERAL_rbp`) | `TYPE = Reativo` | `Type` manual | idem |
| `NOVOS` (`PROSPECTS_NOVO_lId`) | `TYPE = Novo` | `Type` manual | idem |
| `PROSPECTS - GERAL` (`PROSPECTS_GERAL_vjU`) | `TYPE = Prospect` | `Type` manual | idem |
| `RECORRENTES (ATIVOS) - GERAL` (`CONTAS_E_CONTATOS_RECORRENTES_6PU`) | `TYPE = Recorrente` | `Type` manual | idem |
| `COMPRA - ÚLTIMOS 90 DIAS` (`COMPRA_ULTIMOS_90_DIAS`) | `LastPurchase__c >= N_DAYS_AGO:90` e `<= TODAY` | `LastPurchase__c` | idem |
| `SEM COMPRA - 91 A 180 DIAS` (`SEM_COMPRA_91_A_180_DIAS`) | `LastPurchase__c <= N_DAYS_AGO:91` e `>= N_DAYS_AGO:180` | `LastPurchase__c` | idem |

Comando: retrieve dos 7 relatórios e leitura de `column`, `operator`, `value`, `reportType`. Observações para o arquiteto:
- Os relatórios por `Type` usam um campo manual; os dois por `LastPurchase__c` usam o campo derivado. A org já tem duas definições de "ativo/inativo" convivendo, o que a análise (seção 10) pediu para não duplicar.
- Todos os 7 expõem e-mail, 3 telefones e endereço. Reaproveitar um deles como está **contraria o CA-10** da análise; é preciso criar variante sem essas colunas ou aceitar que o relatório é uma lista de público para o MC (decisão do arquiteto).
- Os relatórios abertos não cobrem "Potencial" por `LastPurchase__c` vazio. Os demais 51 relatórios não foram abertos. Pelos nomes (não pelo critério), existem `SEM COMPRA - 181 A 365 DIAS` e `SEM COMPRA - MAIS DE 365 DIAS`; os critérios não foram lidos.
- Há `SAZONAIS - MG (DUPLICADO - REVISAR)` na pasta, sinal de duplicidade já existente (só pelo nome).

## 2. O que será tocado

| Objeto / campo | API name | Tipo | Descrição | Evidência |
|---|---|---|---|---|
| Account | `LastPurchase__c` | Roll-up (MAX CloseDate) | Vazia | Tooling `CustomField` |
| Account | `Inactive__c` | Fórmula Checkbox | Vazia | Tooling `CustomField` |
| Account | `Type` | Picklist padrão | n/a | Análise (describe); não reconfirmado hoje |
| Account | `Ranking__c`, `Risk__c` | Listas | Não reconferidas hoje | Análise; fora do escopo |
| Contact | `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | Padrão / conector MC | Não lidas | `sf sobject describe -s Contact` (só nomes) |
| Opportunity | `StageName`, `CloseDate` | Padrão | n/a | Usados pelo roll-up (Tooling) |
| Relatório | pasta `MARKETING CLOUD` | 58 relatórios | n/a | `COUNT` e retrieve |

Nenhum campo novo é confirmado como necessário; essa é decisão do arquiteto. Campos novos em Account esbarram na automação concorrente (seção 3).

## 3. Automação concorrente e ordem de execução

Coletado por `SELECT ... FROM ApexTrigger` (Tooling), `FlowDefinitionView`, retrieve de Flow e Apex e `ValidationRule` (Tooling).

### Account

| Camada | Componente | Detalhe | Evidência |
|---|---|---|---|
| Trigger before insert/update | `AccountBefore` (namespace `SBQQ`) | Pacote CPQ; sem acesso ao corpo | `ApexTrigger` Tooling |
| Trigger before/after insert/update | `AccountTrigger` (custom) | before: `validateCNPJ`; after insert: `fillAccountWithCNPJInfo`; after update: `updateAccountCNPJInfo` (se `!System.isQueueable()`); respeita `TriggerUtility.bypassTrigger` | retrieve `ApexTrigger:AccountTrigger` |
| Validation rules (6, todas ativas) | `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSetLimitDueDate`, `CheckUserCanSetRisk` | Não abri as fórmulas. Nenhuma aparece pelo nome ligada a `LastPurchase__c`/`Inactive__c` | `ValidationRule` Tooling |
| Flow after save create/update | `UpdateParentAccountUsedLimit` | Ativo | retrieve `Flow` (bloco `<start>`) |
| Flow after save create/update | `AccountTriggered` | Ativo (nome "Conta - Acionado por registro") | idem |
| Flow agendado (Once) | `AccountUpdateEconomicGroup` | Ativo | idem |
| Flow autolaunched sem gatilho | `Account_Agente_ProximaAcao` | Chamado por agente/ação, sem `<start>` de registro | idem |

A ordem de execução padrão da plataforma se aplica (triggers before e validation, depois after e Flows after-save), mas **a ordem interna entre `AccountBefore` (SBQQ) e `AccountTrigger` (custom) não é garantida e não foi testada**.

### Opportunity (origem do roll-up de `LastPurchase__c`)

| Camada | Componente | Detalhe | Evidência |
|---|---|---|---|
| Trigger before insert/update | `OpportunityBefore` (SBQQ) | Pacote CPQ | `ApexTrigger` Tooling |
| Trigger after insert/update | `OpportunityAfter` (SBQQ) e `OpportunityTrigger` (custom) | O custom chama `OpportunityTriggerHandler.afterInsert/afterUpdate`, respeitando `bypassTrigger` | retrieve `ApexTrigger:OpportunityTrigger` |
| Flow after save create/update | `OpportunityFlow` | Ativo; grava `Type` da **Oportunidade** (valor "Nova Compra"), não de Account | retrieve (`$Record` é Opportunity) |
| Flow after save update | `Oportunidade_Industria` | Ativo | retrieve |
| Flow agendado diário | `ScheduledFlowOpportunity` | Ativo; grava `Account.Ranking__c` (análise); EPLAST-47 corrige | `FlowDefinitionView`, retrieve |
| Outros ativos que citam Opportunity | `Opportunity_Scheduled_AlertaParada`, `PaymentTermsOpportunity`, `Opportunity_Screen_RascunhoComercial` | Gatilho não lido | `FlowDefinitionView` (só nome) |
| Flow inativo | `Custom_Stale_Opp` | Não reativar (análise) | `FlowDefinitionView` (análise) |

Sobre Account.Type: nos Flows e handlers retrievados (9 Flows, 2 triggers, `AccountTriggerHandler`, `OpportunityTriggerHandler`), nenhum grava `Account.Type`. As ocorrências de `<field>Type</field>` em `OpportunityFlow` são da Oportunidade. A busca **não é exaustiva** (ver "Não confirmei"). Os handlers tinham 25 e 10 linhas; nenhum cita `LastPurchase__c`, `Inactive__c` ou atribui `Type`.

Risco da ordem de execução para esta demanda: a solução da análise não grava nada em Account (P5). A única automação em jogo é o roll-up de `LastPurchase__c`, disparado por mudança de `StageName`/`CloseDate` em Opportunity. Se o arquiteto optar por campo gravado (Flow, trigger ou fórmula persistida), ele entra na cadeia acima de Account, com 2 triggers (1 SBQQ), 2 Flows after-save e 6 validation rules.

## 4. Volume e dados de teste (dev)

| Objeto | Contagem | Comando |
|---|---|---|
| Account | 0 | `SELECT COUNT() FROM Account` |
| Opportunity | 0 | idem |
| Contact | 0 | idem |
| Lead | 0 | idem |
| Campaign | 0 | idem |
| CampaignMember | 0 | idem |
| Order | 0 | idem |

A dev está vazia: todo teste exige massa sintética (script em `fixtures/`, regra 6 do cliente). Para CA-02 a CA-05 será preciso criar Opportunity `Fechado/Ganho` com `CloseDate` controlado; cuidado com validation rules e triggers de Opportunity/CPQ ao criar a massa (não testado).

**Usuário de teste:** a consulta de User pelo username da conta de serviço da Konecta (regra 6 do cliente) retornou **dois** usuários, os dois com perfil "Administrador do sistema":
- `005bJ00000piKAaQAM`, **ativo** (usuário da conexão atual da esteira nesta org);
- `005bJ00000hBJmYQAW`, **inativo**.
Use o ativo, `005bJ00000piKAaQAM`. Não houve alteração de perfil, permissão ou papel.

## 5. Permissões

| Item | Resultado | Comando |
|---|---|---|
| OWD Account | Externo `Private`, interno `ReadWrite` | `EntityDefinition` Tooling |
| OWD Contact | Externo `Private`, interno `ReadWrite` | idem |
| OWD Opportunity | Externo `Private`, interno `Read` | idem |
| Leitura de `Account.LastPurchase__c` | 18 entradas de `FieldPermissions` com leitura; `Account.Inactive__c`: 17 | `COUNT` agrupado em `FieldPermissions` |
| Quem lê `LastPurchase__c` | Perfis: Administrador do sistema, Engenharia de Produtos, Financeiro, Marketing, Pricing, Usuário Padrão, Comercial - Analista, Comercial, mais perfis de integração/Einstein. Permission sets: `PS Comercial Proxima Acao`, `PS Marketing Publicos`, `Protheus`, `CRM próximo ao núcleo agêntico`, `Data Cloud Salesforce Connector`. | `FieldPermissions` com `Parent.Profile.Name`, `Parent.Label` (LIMIT 30) |

Os perfis comerciais duplicados do assessment ("Comercial - Analistas", "Comercial Padrão") **não** aparecem na lista de leitura de `LastPurchase__c`; só "Comercial" e "Comercial - Analista" aparecem. Há permission set de nome `PS Marketing Publicos`, aparentemente ligado a público de marketing; conteúdo não lido. Acesso a relatórios (pasta, compartilhamento) não verificado.

## 6. Conflitos e riscos do assessment que tocam a demanda

| Risco | Como toca |
|---|---|
| Achado 1: automação concorrente em Account | Confirmado: `AccountBefore` (SBQQ), `AccountTrigger`, `UpdateParentAccountUsedLimit`, `AccountTriggered`, 6 validation rules. Só pesa se houver gravação em Account. |
| Achado 2: cobertura Apex de 10% | Só pesa se houver Apex novo. Cobertura não remedida hoje. |
| Achado 4: campos sem descrição | Confirmado para `LastPurchase__c` e `Inactive__c` (Description nula). |
| Definições concorrentes de "ativo/inativo" | Confirmado: 5 relatórios por `Type` manual e 2 por `LastPurchase__c`, mais `Inactive__c` (90 dias). |
| Relatórios expõem dado pessoal | Confirmado nos 7 abertos (e-mail, telefones, endereço). Afeta CA-10. |
| Cenário `LastPurchase__c` vazio | Fórmula `Inactive__c` com `BlankAsZero`: comportamento a testar na massa sintética. |
| EPLAST-36 e eplast-ent-11 | Usam o mesmo sinal; não consultei o estado das duas hoje. |

## 7. Preparação do Sales Cloud para o Marketing Cloud (o que a org já tem)

| Item | Confirmado | Comando |
|---|---|---|
| Conector instalado (`et4ae5`) | Sim, 17 objetos custom: `et4ae5__AggregateLink__c`, `Automated_Send__c`, `Business_Unit__c`, `Campaign_Member_Configuration__c`, `Configuration__c`, `Email_Linkage__c`, `IndividualEmailResult__c`, `IndividualLink__c`, `MC_CDC_Journey__c`, `SMSDefinition__c`, `SMSJunction__c`, `SendDefinition__c`, `SendJunction__c`, `SupportRequest__c`, `Triggered_Send_Execution__c`, `UEBU__c`, `abTest__c` (todos com sufixo `__c`) | `sf sobject list` filtrado por `et4ae5` |
| Campos `et4ae5__` em Contact | `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c` | `sf sobject describe -s Contact` (só nomes) |
| Campos `et4ae5__` em Account | Nenhum | `sf sobject describe -s Account` (sem retorno) |
| Opt-out de e-mail | `Contact.HasOptedOutOfEmail` existe (campo padrão). Os 7 relatórios abertos filtram `EMAIL_OPT_OUT = 0`. | describe + retrieve |
| Campanha e membros | 0 registros | `COUNT` |
| Permission sets ligados | `PS Marketing Publicos`, `Data Cloud Salesforce Connector` com leitura de `LastPurchase__c` | `FieldPermissions` |

Não verifiquei quais objetos e campos do `et4ae5` estão efetivamente em uso (todos os contadores estão zerados na dev; configuração do conector, `et4ae5__Configuration__c` e `Business_Unit__c`, não foi lida). Nada foi feito no Marketing Cloud.

## O que não consegui confirmar

1. Comportamento de `Inactive__c` com `LastPurchase__c` vazio: a dev tem 0 contas e não criei massa. Inferência pelo `BlankAsZero`, não prova.
2. Critério dos 51 relatórios da pasta `MARKETING CLOUD` que não abri (por exemplo, `SEM COMPRA - 181 A 365 DIAS`, `SEM COMPRA - MAIS DE 365 DIAS`, `LEADS - ...`, `SEGMENTO - ...`), e se algum já separa Potencial por `LastPurchase__c` vazio.
3. Se algum Flow ou Apex fora dos 9 Flows e 2 triggers retrievados grava `Account.Type`. A busca não foi feita em todas as classes Apex nem em todos os Flows de Account/Opportunity; `AccountTriggered` foi só classificado, não lido.
4. Ordem exata entre `AccountBefore` (SBQQ) e `AccountTrigger`, e se um roll-up que muda `LastPurchase__c` dispara os triggers e Flows de Account. Não testado.
5. Fórmulas das 6 validation rules de Account (só nomes e status). Não sei se afetam criação de conta sintética para teste.
6. Tópicos e ações do `SFAgent2` e a que versão cada `GenAiPluginDefinition` pertence; só confirmei que o `BotDefinition` existe.
7. Uso real do conector `et4ae5`: configuração, `Business_Unit__c` e quais campos o MC lê. Contagem dos objetos do conector não foi coletada.
8. Estado da QAS (`sbx-eplast-qa`): não consultada; não sei se a metadata (campos, relatórios) é igual à da dev.
9. Compartilhamento da pasta `MARKETING CLOUD` e quem acessa os relatórios.
10. Estado atual de EPLAST-36 e eplast-ent-11 (backlog), só citados na análise.
11. Cobertura Apex atual e conteúdo dos handlers `AccountTriggerHandler` e `OpportunityTriggerHandler` além da busca por `Type`, `LastPurchase`, `Inactive__c`.
