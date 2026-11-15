# EPLAST-41 · Recon da org

**Org conectada:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, conferido com `sf org list` em 2026-11-15; única org listada, status Connected).
Só leitura. Metadata baixada para diretório temporário fora do repositório e descartada. Nenhum registro lido; só `COUNT()`.

## 1. O que já cobre o pedido

| Componente | Estado confirmado | Cobre | Comando |
|---|---|---|---|
| GenAiPromptTemplate `Rascunho_Proposta_Comercial`, `Rascunho_Followup_Comercial`, `Argumentos_Comerciais_Oportunidade` | Existem, `Published`, unmanaged, criados em 2026-11-15, tipo `einstein_gpt__flex`, modelo `sfdc_ai__DefaultOpenAIGPT4OmniMini`. Entradas: `DadosOportunidade` e `DadosCotacao` (String). A descrição de cada um cita EPLAST-30 e "só leitura" | Os 3 textos comerciais. **Nenhum é de relacionamento** | `sf org list metadata -m GenAiPromptTemplate`; `sf project retrieve start -m GenAiPromptTemplate:<nome>` |
| Flow `Opportunity_Screen_RascunhoComercial` (tela, v1 ativa) | Ativo. A descrição diz EPLAST-30 rev. 2 e "só leitura: zero criação ou atualização de registro". Lê Opportunity, Account, `SBQQ__Quote__c` e `SBQQ__QuoteLine__c`; chama os 3 templates por ação de Prompt Template; `isAdditionalPermissionRequiredToRun = true`; acesso pelo PSG `PSG_Comercial_RascunhoIA`. **Não grava Task e não tem entrada para tipo de relacionamento** | Tela de rascunho comercial, só a partir de Opportunity | `sf data query -t ... FROM Flow`; retrieve de `Flow:Opportunity_Screen_RascunhoComercial` |
| Custom Permission `IA_Rascunho_Comercial` | Existe. Concedida por `PS_Comercial_RascunhoIA` e pelo PSG `PSG_Comercial_RascunhoIA` (status `Updated`) | Controle de acesso das telas | `SELECT ... FROM SetupEntityAccess WHERE SetupEntityType='CustomPermission'` |
| Bot `SFAgent2` | Um só Bot. Bundles `SFAgent2_v1` a `v7` (v5 a v7 criados em 2026-11-15). Tópicos e ações não inspecionados | Fora do escopo (a análise manda não alterar) | `SELECT DeveloperName FROM BotDefinition`; `sf org list metadata -m GenAiPlannerBundle` |
| Flows `Task_Agente_CriarTarefa`, `Account_Agente_ProximaAcao` | Existem e estão ativos (v1). Conteúdo não lido | Padrão da EPLAST-29 | `SELECT ... FROM FlowDefinition` |

Lacuna: não existe template, tela ou Flow de **relacionamento**, nem Flow que **grave Task** a partir do rascunho. Os três templates e o Screen Flow aceitam só Opportunity, com `DadosCotacao`. Para partir de Account, falta entrada e dado de conta sem cotação (não confirmei como os templates tratam o bloco de cotação vazio além do texto de prompt de proposta, que prevê "sem cotação").

### Conflito com a EPLAST-30 (resolvido em fato, decisão é do arquiteto)
A análise dizia que a `03-design.md` da EPLAST-30 chama esses templates de "só existem no force-app". Na dev os templates **e** o Screen Flow existem, todos criados em 2026-11-15 (EPLAST-30 consta como `backlog`). A origem é uma construção anterior da EPLAST-30 na dev ou deploy fora da esteira; não consegui provar qual. O corpo do template de proposta foi lido: regras de rascunho, sem invenção de dado, `[nome do contato]` no lugar de pessoa física, tratamento do bloco de dados como dado e não instrução. Os outros dois templates não tive o corpo conferido linha a linha.

## 2. O que será tocado

| Item | Confirmado | Comando |
|---|---|---|
| `Task.Subject` (picklist), `Description` (textarea longa 32000), `WhatId` (lookup polimórfico, inclui Conta e Oportunidade), `WhoId` (Contato, Lead), `TaskSubtype` (picklist) | Sim | `FieldDefinition` de Task |
| `Contact.HasOptedOutOfEmail` e `Contact.et4ae5__HasOptedOutOfMobile__c` | Sim, ambos | `FieldDefinition` de Contact |
| `et4ae5__HasOptedOutOfMobile__c` e `et4ae5__Mobile_Country_Code__c` em Contact, Lead e Account (a consulta devolveu os dois campos em duas linhas cada; o objeto de cada linha não foi separado) | Sim | `FieldDefinition ... LIKE 'et4ae5__%'` |
| Objetos do conector `et4ae5` | Existem, entre eles `et4ae5__Automated_Send__c`, `et4ae5__SendDefinition__c`, `et4ae5__IndividualEmailResult__c`, `et4ae5__MC_CDC_Journey__c`, `et4ae5__Business_Unit__c` (lista cortada em 40 linhas) | `EntityDefinition WHERE NamespacePrefix='et4ae5'` |
| `Account.AccountHasCheckInTask__c` (checkbox, sem descrição) | Sim. Ver seção 3 | `FieldDefinition` de Account |

A demanda prevê criar apenas Prompt Template(s) de relacionamento, ajustes de tela e gravação de Task. Campo novo: nenhum necessário pelo que a análise descreve.

## 3. Automação concorrente

| Componente | Objeto e evento | Efeito para a EPLAST-41 | Comando |
|---|---|---|---|
| Flow `TaskCreatedOrUpdated` ("[Tarefa] - Criado ou Atualizado"), v1 ativa | Task, `RecordAfterSave`, create e update | Se `WhatId` começa por `001` **e** `Subject` começa por `Check In @`, faz **update em Account** (`AccountHasCheckInTask__c = true`). Outro assunto: não faz nada | Retrieve do Flow e leitura do XML |
| Triggers de Task (custom ou outros) | Task | Nenhum | `SELECT Name FROM ApexTrigger WHERE TableEnumOrId='Task'` (0 linhas) |
| Validation rules de Task | Task | Nenhuma | `ValidationRule` com Tooling API (0 linhas) |
| Workflow rules de Task | Task | Nenhuma | `WorkflowRule` com Tooling API (0 linhas) |
| Triggers `AccountTrigger`, `OpportunityTrigger` (custom) e `AccountBefore`, `OpportunityBefore`, `OpportunityAfter` (SBQQ) | Account, Opportunity | Só disparam se a Task alterar o pai. Isso só acontece pelo Flow acima | `SELECT ... FROM ApexTrigger` |
| Flows ativos com nome ligado a Account e Opportunity: `AccountTriggered`, `AccountUpdateEconomicGroup`, `PaymentTermAccount`, `SetPaymentTermsChangesinAccount`, `OpportunityFlow`, `Oportunidade_Industria`, `UpdateParentAccountUsedLimit`, `ScheduledFlowOpportunity`, `Opportunity_Scheduled_AlertaParada` | Objeto e evento de cada um **não confirmados** | Não sei quais disparam em update de Account causado pelo Flow de Task | `SELECT ... FROM Flow WHERE Status='Active'` (só nome) |

Conclusão para o arquiteto: a Task gravada com `WhatId` de Account só alcança o pai se o `Subject` começar por `Check In @`. O Subject da Task do rascunho deve ser definido pelo design para não colidir com esse prefixo. O `Subject` de Task é picklist: confirmar se aceita valor livre antes de definir o texto.

## 4. Volume e dados de teste

| Objeto | Registros na dev | Comando |
|---|---|---|
| Task | 0 | `SELECT COUNT() FROM Task` |
| Account | 0 | idem |
| Opportunity | 0 | idem |
| Contact | 0 | idem |
| EmailMessage | 0 | idem |
| SBQQ__Quote__c | 0 | idem |

A dev **não tem dado para testar**. A pasta `clients/eplast/fixtures/` citada no `CLAUDE.md` do cliente **não existe** no repositório, nem o `fixtures/README.md`. O build precisa criar o dado de teste (conta, oportunidade, cotação primária, linhas).

Usuário de teste (conta de serviço Konecta, pelo prefixo de username do briefing): a consulta devolveu **dois** usuários, ambos com perfil `Administrador do sistema`: `005bJ00000hBJmYQAW` (inativo) e `005bJ00000piKAaQAM` (ativo). O ativo é o candidato; o username de cada um não foi registrado aqui.

## 5. Permissões

| Item | Confirmado |
|---|---|
| Custom Permission `IA_Rascunho_Comercial` concedida por `PS_Comercial_RascunhoIA` e `PSG_Comercial_RascunhoIA` | Sim |
| Acesso à criação de Task pelos perfis comerciais, OWD de Account e Opportunity | **Não confirmado** |
| Acesso dos usuários do PSG aos objetos `SBQQ__Quote__c` e `SBQQ__QuoteLine__c`, que o Screen Flow lê | Não confirmado |

## 6. Marketing Cloud (o que está instalado)

- Namespace `et4ae5` existe na org: objetos, e campos de opt-out e país do celular em Contact (confirmados acima). Nada foi alterado.
- A versão do pacote (264.1, citada na análise) **não consegui reconfirmar**: a consulta a `InstalledSubscriberPackage` falhou pelo filtro.
- Quais objetos do conector têm uso ativo (envios, jornadas): não verificado, todos com 0 registros esperados dado o estado vazio, mas só contei Task, Account, Opportunity, Contact, EmailMessage e SBQQ__Quote__c.

## O que não consegui confirmar

1. Licença e habilitação de IA generativa e Einstein Trust Layer. Os templates estão `Published`, mas isso não prova que a geração roda. Não executei nenhum template (seria execução na org).
2. Origem dos três templates e do Screen Flow (EPLAST-30 construída antes da esteira ou deploy manual). Corpo dos templates de follow-up e argumentos não conferido linha a linha.
3. Como o Screen Flow e os templates se comportam com Account sem oportunidade e sem cotação.
4. Objeto e evento dos 9 Flows de Account e Opportunity listados na seção 3; se algum deles dispara no update de `AccountHasCheckInTask__c`.
5. Valores da picklist `Task.Subject` e `TaskSubtype` (se aceitam valor livre e se `Task` é o valor correto).
6. OWD e acesso por perfil a Task, Account, Opportunity e Quote do PSG de rascunho.
7. Tópicos e ações do `SFAgent2` (v1 a v7 existem; qual é a ativa não foi verificado) e relação com a EPLAST-29.
8. Versão do pacote `et4ae5` (264.1).
9. Ordem de execução completa de Account e Opportunity (trigger custom versus trigger SBQQ versus Flows). Não mapeada; só é relevante se o design gravar em Account ou Opportunity.
10. Dado de teste e `fixtures/`: ausentes; o script de criação precisa ser escrito.
