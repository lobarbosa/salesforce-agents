# EPLAST-29 · Design — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** design · **Autor:** arquiteto (proposta para o aceite do arquiteto humano)
**Entradas:** `01-analise.md` (aprovada em `gates.md`, 2026-11-15), `02-recon.md` (2026-11-15), `comentarios-do-card.md`, `assessment.md` (via análise e recon), skills `salesforce-doutrina` e `padrao-entrega`.
**Org conectada nesta sessão:** `sbx-eplast-dev` (sandbox, única org listada por `sf org list`). Nenhuma org de produção foi tocada. Só metadata e contagens agregadas; nenhum registro lido.
**Histórico consultado (RAG):** `rodada-anterior/03-design.md` (mesma decisão técnica, escrita antes da regra 4; usada como referência), `EPLAST-27/03-design.md` e `rodada-anterior/03-design.md` da EPLAST-27 (D1: todo update de Account enfileira `SendAccountToProtheus`; P4: tópico na v4 do `SFAgent2`), `EPLAST-33` D1 (somente leitura, inclusive Task).

> **Aviso do card (2026-11-15 03:12):** a aprovação da análise foi dada em lote, e as premissas "devem ser conferidas no gate de design". Por isso a seção 9 lista todas, uma a uma, com o que este design manteve ou mudou.

---

## 1. Confirmações feitas nesta sessão (complementam o recon)

O recon não foi refeito. Confirmei só o que muda a decisão:

| Ponto | Resultado | Prova (`sf`, `sbx-eplast-dev`) |
|---|---|---|
| Ação padrão `createTask` | Entradas: `taskSubjectName` (obrigatória), `taskAssignedToId`, `taskPriority`, `taskStatus`, `taskComments`, `taskDueInDays`, `taskReminderInDays`, `taskUseAssignedUserLookup`. Saída: `taskId`. **Não recebe `WhatId`** e o vencimento é relativo (dias) | `GET /actions/standard/createTask` |
| Ação padrão `createRecord` | Entradas `objectApiName` + `recordData` (JSON livre): o LLM escolhe o objeto | `GET /actions/standard/createRecord` |
| Tópicos do planner `SFAgent2_v4` | **4** plugins locais: `agent_router`, `ambiguous_question`, `insights_comerciais`, `off_topic`. Fecha a dúvida do recon §8.2: o `agent_router` é tópico local. `plannerType = Atlas__ConcurrentMultiAgentOrchestration`. O arquivo `agentScript/SFAgent2_v4_definition.agent` veio **vazio** (0 linhas): a definição vive no XML do bundle | retrieve em pasta temporária dentro do projeto, apagada em seguida |
| Acesso ao agente | 0 `SetupEntityAccess` apontando para o `BotDefinition` do `SFAgent2`: **nenhum** perfil ou PS concede o agente hoje | `SELECT COUNT() FROM SetupEntityAccess WHERE SetupEntityId = <id do bot>` |
| `PS_Comercial_ResumoClienteAgente` | O único `SetupEntityAccess` é do tipo `ApexClass` (a `CustomerSummaryService`). Confirma o recon: não cobre agente, Flow nem Task | `GROUP BY SetupEntityType` |
| Perfis comerciais | `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`: todos `EditTask = true` e **`RunFlow = false`**. Só `Comercial - Analista` tem usuário ativo (4) | `PermissionSet WHERE IsOwnedByProfile = true`; `COUNT` agregado de `User` |
| Valores de Task | `Priority`: `Normal` (padrão), `High`. `Status`: `Open` (padrão), `Completed`. `TaskSubtype` ativo: `Task`, `Email`, `ListEmail`, `Cadence`, `Call`, `LinkedIn`. `Description` textarea 32.000. Não há campo `Type` em Task nesta org | `TaskPriority`, `TaskStatus`, `sobject describe Task` |
| Flow com nome `Task_*` ou `*Agente*` | Só `TaskCreatedOrUpdated`. Nenhum Flow de criação de tarefa por agente para reaproveitar | `FlowDefinitionView` |
| OWD interno | Account `ReadWrite`, Opportunity `Read`, Contact `ReadWrite`, Task `Private` (recon) | `EntityDefinition` |
| Flows record-triggered de Account (ativos) | `AccountTriggered` e `UpdateParentAccountUsedLimit`, ambos `RecordAfterSave`, `CreateAndUpdate` (reconfirma a análise; o recon não tinha relido). Há também `AccountUpdateEconomicGroup` (agendado) | `FlowDefinitionView` |
| Triggers de Account | `AccountBefore` e `AccountTrigger`, ambos `Active` | `ApexTrigger` |
| Consentimento (para a seção 8) | Contact e Lead têm `HasOptedOutOfEmail`, `EmailBouncedReason`, `et4ae5__HasOptedOutOfMobile__c`, `et4ae5__Mobile_Country_Code__c`. `IndividualId` e `DoNotCall` não aparecem no describe. Campaign: 0 registros | `sobject describe`; `COUNT()` |
| Integração | Há classes `Protheus*` na org (ex.: `ProtheusInsertClientModel`). 0 `NamedCredential`. O endpoint usado na sandbox **não foi verificado** | `ApexClass LIKE '%Protheus%'`; `NamedCredential` |
| Demandas concorrentes no `SFAgent2` | EPLAST-26, 27, 28, 30, 31, 32 e 39 estão em `backlog`. Nenhum artefato cita `SFAgent2_v5` | `status.yaml` das demandas; Grep |

---

## 2. Decisão

**Abordagem: declarativa, sem Apex.** Nova versão `v5` do `SFAgent2` com um tópico novo, `acoes_comerciais`, que chama um **Flow autolaunched** (`Task_Agente_CriarTarefa`) com confirmação obrigatória do usuário. O Flow grava uma Task e nada mais.

### 2.1 Por que não só configuração (nível 1)

| Alternativa de configuração | Por que não atende |
|---|---|
| Ligar a ação padrão `createTask` ao agente | Não recebe `WhatId`: a tarefa não fica ligada ao registro (AC-1 exige `WhatId = REG-TESTE-01`). Vencimento só em dias relativos. Não há onde pôr guarda determinística (seção 2.4). |
| Ligar a ação padrão `createRecord` | O LLM escolhe o objeto. Nada impede gravar Account, Opportunity ou Order, exatamente o que AC-7 e o assessment #1 proíbem. Restrição só por instrução de prompt não é controle. |
| Ligar ações de envio (`emailSimple`, mensageria) | Enviariam pelo CRM. Proibido pela regra 2 da conta e pela P3. |

### 2.2 Por que Flow basta (não desce para Apex)

O Flow autolaunched dá o que faltou: só Task, entradas tipadas com `WhatId` e data absoluta, guardas determinísticas e caminho de falha controlado. Nenhum gatilho da doutrina para Apex aparece: sem rollback complexo, sem callout, sem volume (1 SOQL e 1 DML por confirmação humana), sem recursão. Sem Apex, o assessment #2 (cobertura de 10%) não piora e não há classe de teste a escrever.

### 2.3 Alternativas que a análise deixou, e a escolha

| Ponto em aberto na análise | Alternativas | Escolha e porquê |
|---|---|---|
| P1: ação dentro de `insights_comerciais` ou em tópico próprio | (a) acrescentar `CriarTarefa` ao `insights_comerciais`; (b) tópico novo `acoes_comerciais` | **(b).** AC-9 exige que `insights_comerciais` continue com as 3 ações atuais. Tópico separado deixa a leitura intacta, isola a instrução de escrita e permite desligar a escrita sem tocar a leitura. |
| P5: estender `PS_Comercial_ResumoClienteAgente` ou criar PS | (a) estender o existente; (b) PS novo | **(b).** O existente serve à `CustomerSummaryService` (resumo de cliente, artefato fora do workspace) e tem 0 atribuições; misturar "resumo" com "criar tarefa" juntaria dois públicos num PS só. Regra 3 é respeitada: o existente não cobre o pedido (recon §6, confirmado acima), então não há sobreposição. |
| Acesso ao agente (lacuna D2 da rodada anterior) | (a) deixar fora da demanda; (b) conceder no PS novo | **(b).** Sem acesso ninguém usa a ação, e nenhum PS concede o agente hoje (confirmado). Regra 4: o padrão da plataforma para agente de funcionário é acesso por permission set; é a opção mais simples e se desfaz removendo uma linha do PS. Premissa PD-6. |
| P7: busca do registro | (a) reaproveitar `identifyRecordByName`; (b) Flow de busca próprio | **(a).** Mesma ação padrão já usada pela `IdentificarConta` da v4. No bundle, ações locais pertencem a um tópico, então o tópico novo ganha a ação local `IdentificarRegistro` apontando para o mesmo alvo padrão: reaproveita a ação, não cria lógica nova. |
| P3: onde vai o rascunho de e-mail/mensagem | (a) Task com texto em `Description`; (b) `EmailMessage` em rascunho; (c) `TaskSubtype = Email` | **(a), com `TaskSubtype = Task`.** (b) cria registro de e-mail no CRM e aproxima do envio (regra 2; AC-6 exige `EmailMessage` inalterado). (c) faz a tarefa aparecer como e-mail enviado na linha do tempo, o que é falso. Premissa PD-3. |
| Escopo de `WhatId` | Account só; Account e Opportunity; qualquer objeto | **Account e Opportunity.** São os objetos que o `insights_comerciais` já trata e onde o vendedor trabalha. Qualquer objeto abriria Order (assessment #1, #3, #10). Premissa PD-1. |

### 2.4 Guardas determinísticas no Flow (não dependem do LLM)

1. `Assunto` vazio → recusa.
2. `Assunto` começando com `Check In @` → recusa (fecha a cascata Task → Account da seção 5).
3. `RegistroRelacionadoId` com prefixo diferente de `001` (Account) ou `006` (Opportunity) → recusa. O prefixo identifica o objeto, não é ID de registro (sem hardcode de ID).
4. `DataVencimento` vazia → recusa com mensagem pedindo a data (AC-5).
5. Get Records do registro relacionado não encontra → mensagem genérica "registro não encontrado ou sem acesso", sem nome nem campo (AC-4).

---

## 3. Componentes

### 3.1 Reaproveita (sem alterar)

| Componente | Como é usado |
|---|---|
| `SFAgent2` (`BotDefinition`) | Recebe a versão v5. Continua o único agente (regra 3). |
| `SFAgent2_v4` (planner) e tópicos `insights_comerciais`, `ambiguous_question`, `off_topic` | Copiados para a v5 sem mudança. A v4 fica intacta como rollback. |
| Ação padrão `identifyRecordByName` | Alvo da ação local `IdentificarRegistro` do tópico novo. |
| Campos padrão de Task (`Subject`, `ActivityDate`, `WhatId`, `OwnerId`, `Description`, `Priority`, `Status`, `TaskSubtype`) | Únicos campos gravados. Nenhum campo custom. |
| `CreatedById` | Rastreabilidade de quem pediu (P8). |
| Perfis comerciais | Já dão `EditTask`; não são alterados. |

### 3.2 Criar

| Tipo | API name | O que é |
|---|---|---|
| Flow (AutoLaunchedFlow, API 67.0 do projeto) | `Task_Agente_CriarTarefa` | Grava 1 Task com as guardas da seção 2.4. Descrição preenchida. |
| GenAiPlannerBundle + BotVersion | `SFAgent2_v5` / versão `v5` do `SFAgent2` | Cópia da v4 + tópico `acoes_comerciais` + descrição de roteamento no `agent_router`. |
| Tópico local (no bundle v5) | `acoes_comerciais` ("Ações Comerciais") | Ações `IdentificarRegistro` (`identifyRecordByName`, sem confirmação, só leitura) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`, **com confirmação do usuário obrigatória**). |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | Acesso ao Flow `Task_Agente_CriarTarefa` (necessário: `RunFlow = false` nos 4 perfis) e acesso ao agente `SFAgent2`. Sem objeto nem campo. Descrição preenchida. |

**Contrato do Flow `Task_Agente_CriarTarefa`.** Toda variável de entrada e saída com `description` em pt-BR, porque o agente usa a descrição para preencher valores (assessment #4).

- Entradas: `Assunto` (Text, obrigatória); `DataVencimento` (Date, obrigatória, absoluta); `RegistroRelacionadoId` (Text, obrigatória); `Descricao` (Text, opcional, recebe o rascunho de e-mail/mensagem quando houver); `Prioridade` (Text, opcional, `Normal` ou `High`; qualquer outro valor vira `Normal`).
- Saídas: `Sucesso` (Boolean), `TarefaId` (Text), `Mensagem` (Text, pt-BR, para o agente repassar).
- Gravação: `Subject` = Assunto; `ActivityDate` = DataVencimento; `WhatId` = RegistroRelacionadoId; `OwnerId` = `$User.Id`; `Priority`; `Status` = `Open`; `TaskSubtype` = `Task`; `Description` = Descricao + linha final `Origem: assistente de IA` (AC-8).
- Fault path no Get e no Create: `Sucesso = false`, mensagem amigável, sem texto técnico de erro. Um único DML, então não há gravação parcial (AC-5).
- `runInMode`: `DefaultMode`. O contexto em que o Agentforce executa o Flow nesta org não está confirmado (risco R5); o build prova com o AC-4 antes de concluir.

**Instruções do tópico `acoes_comerciais`** (resumo do que o build escreve, em pt-BR):
- Só cria Task, uma por confirmação. "Crie 5 tarefas" vira 5 resumos e 5 confirmações.
- Resolve o registro: usa o registro da página atual se for Account ou Opportunity; senão chama `IdentificarRegistro`. Com mais de um candidato, lista com identificador e pergunta; não chama `CriarTarefa` (AC-3).
- Converte data relativa em absoluta e mostra no resumo; se faltar, pergunta (AC-5).
- Antes de `CriarTarefa`, mostra o resumo: assunto, registro relacionado, responsável ("você"), vencimento e, se houver, o rascunho (AC-1, AC-2).
- Pedido de e-mail ou mensagem: redige o texto, propõe Task com assunto `Rascunho de e-mail - <tema>` ou `Rascunho de mensagem - <tema>`, vencimento hoje (editável no resumo), e informa que o envio é feito fora do CRM: pelo Marketing Cloud, se for comunicação de marketing, ou pelo canal do próprio vendedor, se for contato individual (AC-6, P3).
- Pedido de criar ou alterar Account, Opportunity, Order, outro objeto, tarefa para outra pessoa ou check-in: recusa e diz que não está disponível nesta versão (AC-7).

**Forma do bundle:** a v4 é XML (`genAiPlugins` + `localActions`), com o arquivo de Agent Script vazio. O build segue o mesmo formato da v4 e confirma, com `sf project deploy validate` logo no início, a forma aceita para ação local com alvo de Flow e confirmação obrigatória (nenhuma ação da org usa Flow hoje) — risco R7.

### 3.3 Alterar

| Componente | Alteração |
|---|---|
| `SFAgent2` | Ganha a versão v5, ativada em `sbx-eplast-dev` para a verificação. Hoje v1 a v4 estão `Inactive` (recon). Na QA, ativação pelo fluxo de release. |

### 3.4 Não tocar (explícito)

- `TaskCreatedOrUpdated` (a guarda 2 evita o único ramo com DML).
- `insights_comerciais` e suas 3 ações; `PS_Comercial_ResumoClienteAgente`; `CustomerSummaryService`; perfis.
- Account, Opportunity, Order e suas automações; `OrderTrigger` (nenhum componente novo com esse nome).
- Marketing Cloud e o conector `et4ae5`.

### 3.5 Depreciar

Nada.

### 3.6 Modelo de dados

**Nenhuma mudança.** Nenhum objeto ou campo novo. Rastreabilidade por `CreatedById` + marca em `Description` (P8). Um campo de origem em Task seria mudança de modelo de dados: fica para decisão do arquiteto humano, não proposto aqui.

---

## 4. Impacto em permissões

- **Novo `PS_Comercial_AssistenteAcoes`**, atribuído por usuário. Concede: Flow `Task_Agente_CriarTarefa` e agente `SFAgent2`. Não concede objeto nem campo: criar Task vem do perfil.
- **Nenhum perfil alterado** (assessment #7 e #8: perfis comerciais duplicados; acesso fica em PS).
- **Licença do Agentforce:** atribuição de licença de permission set de Agentforce ao usuário de teste é passo manual de administração, não metadata desta demanda. Hoje 0 atribuídas (recon). Sem ela o build deploya, mas a verificação conversacional não roda (vira `inconclusiva`).
- **Licença `Salesforce`:** 14/14 (análise). Teste com usuário existente do perfil `Comercial - Analista` (4 ativos) e, para AC-4, um usuário existente de outro perfil sem o PS (P6).
- **Compartilhamento:** OWD de Task `Private`; a Task criada pertence a quem pediu. Account `ReadWrite` e Opportunity `Read`: ler o registro basta para relacionar a tarefa, e o Get Records do Flow confirma a visibilidade (se o contexto for de usuário, ver R5).
- **Sintaxe de acesso ao agente em PS:** não confirmada nesta org (nenhum PS a usa hoje). O build confirma no deploy validate; se não houver forma por metadata, o acesso vira passo manual pós-deploy documentado.

---

## 5. Automação concorrente, ordem de execução e governador

**Task (objeto gravado).** Sem trigger, sem validation rule. Um Flow after-save: `TaskCreatedOrUpdated` (create e update). Esta demanda **não acrescenta** automação record-triggered em Task: o Flow novo é autolaunched, chamado pelo agente. Ordem em Task: determinística (um único componente).

**Conflito de automação: toda Task criada pelo assistente passa por `TaskCreatedOrUpdated`. Se o assunto começar com `Check In @` e o `WhatId` for Account, ele atualiza `Account.AccountHasCheckInTask__c`, o que dispara a cadeia concorrente de Account: before-save com `AccountBefore` (SBQQ) e `AccountTrigger` (custom), ordem entre os dois não garantida pela plataforma, e after-save com `AccountTriggered` e `UpdateParentAccountUsedLimit`, ordem também não fixa. Pelo histórico da EPLAST-27 (D1), todo update de Account enfileira `SendAccountToProtheus` (não reconfirmado nesta sessão). A guarda 2 da seção 2.4 fecha esse caminho; com ela, o assistente nunca grava em Account.**

**Mapa de ordem de Account: lacuna explícita.** Não é provável com metadata e a dev não tem dado para trace (recon §3.3). Este build não depende dessa ordem, porque a guarda impede a escrita. O que o build deve verificar antes de concluir: (1) caso de teste com assunto `Check In @...` ligado a Account sintética → Flow recusa, contagem de Task inalterada; (2) com assunto comum ligado a Account, debug log da transação mostra `TaskCreatedOrUpdated` saindo nas decisões, sem DML em Account. Se alguém remover a guarda no futuro, o mapa com trace vira pré-requisito.

**Opportunity e Order:** sem DML. Criar Task com `WhatId` de Opportunity atualiza só a atividade derivada pela plataforma; o QA confirma no AC-7 que nenhum registro de Opportunity, Account ou Order é criado ou alterado.

**Governador:** por confirmação, 1 SOQL (Get Records) + 1 DML (Task); `TaskCreatedOrUpdated` sai nas decisões, 0 SOQL e 0 DML a mais. Carga em massa: não se aplica (uma transação por confirmação humana). **CPU, um pai com muitos filhos (SOMOSAGILITY-10):** não se aplica: nenhuma automação recalcula Account ou Opportunity por Task; o único ramo que escreveria no pai está bloqueado. Volume real desconhecido (0 Task na dev; produção não consultada).

---

## 6. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **dev e QA podem ser a mesma sandbox** (assessment #6): a instância de `sbx-eplast-dev` se identifica como `qa`; a QA não está conectada. | **Alta** para a homologação | Não bloqueia design nem build. Confirmar antes do `05-deploy-qa.md` (BASIS ou delivery). |
| R2 | **Agente sem versão ativa e sem acesso concedido.** Ativar a v5 é a primeira ativação do agente nesta sandbox; muda o comportamento do `insights_comerciais` para quem tiver acesso. | Alta | v5 copia a v4 sem mudar a leitura; v4 intacta para rollback. Build faz retrieve imediatamente antes de editar. |
| R3 | **Versionamento com demandas futuras:** EPLAST-27 desenhou seu tópico "na v4"; quem vier depois precisa partir da v5. | Média | Registrar no `06-entrega.md` que a base passa a ser a v5. Hoje nenhuma outra demanda está fora de `backlog`. |
| R4 | Cascata Task → Account → Protheus pelo `TaskCreatedOrUpdated` (seção 5). | Média, mitigado | Guarda 2 + caso de teste dedicado. |
| R5 | Contexto de execução do Flow chamado pelo agente (usuário ou sistema) não confirmado. Em contexto de sistema, CRUD não é checado e o Get Records pode ver registro fora do compartilhamento. | Média | Build prova com AC-4 (usuário sem acesso ao registro e usuário sem PS). Se cair em sistema: mudar para `SystemModeWithSharing` (respeita compartilhamento) e manter o PS restrito a perfis com `EditTask` (todos os 4 comerciais têm). |
| R6 | Ambiguidade e resumo dependem do LLM. | Média | Barreira determinística: confirmação obrigatória + guardas do Flow. Teste conversacional com `REG-TESTE-DUP`. |
| R7 | Deploy de bundle com ação de Flow e confirmação nunca rodou nesta esteira; acesso a agente por PS também não. | Média | `deploy validate` no início do build, antes das instruções finais. |
| R8 | **Dados sintéticos em Account disparam a automação de Account**, inclusive o possível enfileiramento para o Protheus, na dev e na QA. Endpoint da sandbox não verificado (0 `NamedCredential`). | Média | Antes de criar `REG-TESTE-01`/`REG-TESTE-DUP`, o build confere se o callout aponta para ambiente não produtivo ou falha sem efeito; se apontar para ERP produtivo, para e registra (não cria dado). Dados sintéticos apagados ao fim pelo QA. |
| R9 | Licença de Agentforce não atribuída a ninguém (0). | Média | Passo manual pré-verificação (seção 4). Sem ela, verificação `inconclusiva`, não reprovada. |
| R10 | `PS_Comercial_ResumoClienteAgente` / `CustomerSummaryService` sem artefato no workspace. | Baixa | Não tocados. |

### Riscos do assessment que tocam o escopo

| Achado | Como este design lida |
|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | Nenhum DML nesses objetos. Caminho indireto (check-in → Account) fechado pela guarda. Mapa de ordem de Account: lacuna explícita com verificação definida (seção 5). Opportunity e Order: não tocados; mapa fica o da análise. |
| #2 Cobertura Apex 10% | Sem Apex. Não se aplica classe `<Classe>Test`; se o build descobrir que precisa de Apex, volta ao gate de design. |
| #3 Validation rules de Order | Não se aplica (Order fora). |
| #4 Campos sem descrição | Nenhum campo novo. Flow, variáveis, PS e tópico saem com descrição. `AccountHasCheckInTask__c` (sem help text) não é tocado. |
| API version de Apex existente | Não se aplica (nenhuma classe tocada). `TaskCreatedOrUpdated` (API 61) não é editado. |
| #6 dev × QA | R1. |
| #7/#8 Perfis duplicados | Nenhum perfil alterado; acesso por PS. |
| #10 `OrderTrigger` homônimo | Não tocado; nada criado com esse nome. |

---

## 7. O que NÃO será feito nesta demanda

- Criar ou alterar Account, Opportunity, Order, Lead, Contact, Case ou Event pelo assistente.
- Enviar e-mail ou mensagem por qualquer meio do CRM (`emailSimple`, e-mail alert, Apex de e-mail, `EmailMessage`).
- Qualquer configuração no Marketing Cloud ou no conector `et4ae5`.
- Alterar Task existente, atribuir tarefa a outra pessoa, criar em lote numa confirmação, criar check-in.
- Mudar `insights_comerciais`, `TaskCreatedOrUpdated`, perfis, `PS_Comercial_ResumoClienteAgente`.
- Campo novo em Task; relatório ou painel novo (a métrica P9 usa relatório padrão de atividades depois do go-live).
- Apex de qualquer tipo; ativação em produção.

---

## 8. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca comunicação (rascunho de e-mail e mensagem). Ela **não cria público, segmento nem dado para o Marketing Cloud**; o que segue delimita a fronteira.

- **Dados que o MC lê e onde ficam:** nada novo. O rascunho fica em `Task.Description`, com assunto `Rascunho de e-mail - ...` / `Rascunho de mensagem - ...`. Não é fonte de jornada nem de envio: é anotação de trabalho do vendedor.
- **Público ou segmento identificável no CRM:** não se aplica a esta demanda. Se a Eplast quiser que um rascunho vire comunicação de marketing, o caminho do CRM é Campaign e CampaignMember (hoje 0 campanhas na dev), em demanda própria.
- **O que o MC devolve e onde é gravado:** nada desta demanda. O retorno de envio continua nos objetos do conector `et4ae5` (ex.: `IndividualEmailResult`, lista do recon §4), sem alteração.
- **Consentimento e opt-out:** confirmados em Contact e Lead `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c`. Como o assistente não envia nada, ele não consulta nem altera consentimento; quem envia (MC ou o vendedor) aplica o opt-out. Nenhum campo de consentimento é criado ou gravado.
- **O que fica com quem opera o MC:** decidir se rascunhos do assistente devem alimentar algum envio de marketing; se sim, abrir demanda para o lado do CRM (campanha/membro). Nada a fazer no MC por causa deste build.

---

## 9. Premissas assumidas (validar na homologação)

Formato: pergunta → decisão → evidência → como mudar. As da análise foram conferidas uma a uma, como pede o card.

### Da análise (conferidas)

- [x] **P1 — Extensão do `SFAgent2`.** Mantida, refinada: tópico novo `acoes_comerciais` na v5 (seção 2.3). Evidência: único `BotDefinition`; 4 tópicos confirmados. Como mudar: mover a ação para `insights_comerciais` é edição do bundle, sem mudar o Flow.
- [x] **P2 — Só Task.** Mantida, com `WhatId` em Account ou Opportunity (PD-1). Evidência: seção 5; assessment #1. Como mudar: demanda própria com mapa de ordem.
- [x] **P3 — E-mail e mensagem não saem do CRM.** Mantida; formato do rascunho em PD-3. Evidência: regra 2; `createRecord`/`emailSimple` rejeitados. Como mudar: envio 1:1 pelo CRM vira design próprio, alinhado com quem opera o MC.
- [x] **P4 — Confirmação sempre.** Mantida: confirmação obrigatória na ação `CriarTarefa`. Como mudar: desligar a confirmação na ação, sem refazer o Flow.
- [x] **P5 — Quem recebe.** **Mudada.** A análise previa reaproveitar `PS_Comercial_ResumoClienteAgente`; a org mostra que ele só dá acesso a uma classe Apex e não cobre agente, Flow nem Task. Decisão: PS novo `PS_Comercial_AssistenteAcoes` (PD-6). Como mudar: trocar a atribuição ou mover o conteúdo para outro PS.
- [x] **P6 — Usuários de teste.** Mantida: usuários existentes de `Comercial - Analista` (4 ativos); sem usuário de licença completa. Como mudar: com licença livre, cria-se usuário dedicado.
- [x] **P7 — Busca de registro.** Mantida: `identifyRecordByName` + lista de candidatos. Como mudar: trocar o alvo da ação local.
- [x] **P8 — Rastreabilidade.** Mantida: `CreatedById` + `Origem: assistente de IA` em `Description`. Depende de R5 para `CreatedById`. Como mudar: campo de origem (decisão de modelo de dados do arquiteto humano).
- [x] **P9 — Métrica.** Mantida: aceite funcional. Como mudar: meta entra como critério extra na homologação.
- [x] **P10 — Volume baixo.** Mantida: uma transação por confirmação; limites na seção 5. Como mudar: se houver uso em lote, revisar.
- [x] **P11 — Retenção/LGPD.** Mantida: sem log próprio; conteúdo só na Task. Como mudar: retenção específica vai a design e jurídico.
- [x] **P12 — Event fora.** Mantida. Como mudar: demanda própria.
- [x] **P13 — Licença de Agentforce.** Mantida como premissa, agora com passo explícito (seção 4, R9): 0 atribuídas hoje. Como mudar: n/a; sem licença o QA não roda.

### Novas deste design

- [x] **PD-1 — Objetos aceitos como "registro relacionado".**
  - Pergunta: a tarefa pode ligar a qualquer objeto?
  - Decisão: Account e Opportunity (prefixos `001` e `006`).
  - Evidência: são os objetos do `insights_comerciais`; Order tem automação concorrente e 23 validation rules (análise §5). Opção mais simples.
  - Como mudar: acrescentar prefixo na guarda 3 do Flow e na instrução do tópico.
- [x] **PD-2 — Assistente não cria check-in.**
  - Pergunta: tarefa com assunto `Check In @` pode ser criada pelo assistente?
  - Decisão: não; o Flow recusa.
  - Evidência: `TaskCreatedOrUpdated` atualiza Account nesse caso (recon §3.1), entrando na cadeia de Account (assessment #1) e no possível envio ao Protheus (EPLAST-27 D1).
  - Como mudar: remover a guarda 2, depois de mapear a ordem de Account com trace (seção 5).
- [x] **PD-3 — Formato do rascunho.**
  - Pergunta: como o rascunho de e-mail ou mensagem fica no CRM?
  - Decisão: Task `Open`, `TaskSubtype = Task`, assunto `Rascunho de e-mail - <tema>` ou `Rascunho de mensagem - <tema>`, texto em `Description`, vencimento hoje (editável no resumo).
  - Evidência: `TaskSubtype = Email` faria a atividade parecer e-mail enviado; `EmailMessage` contraria AC-6 e a regra 2. Não há campo `Type` em Task.
  - Como mudar: trocar o prefixo de assunto na instrução do tópico.
- [x] **PD-4 — Responsável é sempre quem pede.**
  - Decisão: `OwnerId = $User.Id`; atribuir a outra pessoa é recusado.
  - Evidência: AC-1; evita que o assistente crie trabalho para terceiros sem que eles saibam. Opção mais simples.
  - Como mudar: entrada opcional de responsável no Flow + `IdentificarRegistro` para User.
- [x] **PD-5 — Campos obrigatórios da tarefa.**
  - Pergunta: qual "campo obrigatório" do AC-5?
  - Decisão: assunto, registro relacionado e vencimento. Prioridade padrão `Normal`; status `Open`.
  - Evidência: `Normal` e `Open` são os padrões da org (`TaskPriority`, `TaskStatus`); o describe não exige nenhum campo de Task.
  - Como mudar: tornar o vencimento opcional na entrada do Flow.
- [x] **PD-6 — Acesso pelo PS novo, inclusive ao agente.**
  - Pergunta: quem concede o acesso ao `SFAgent2`?
  - Decisão: `PS_Comercial_AssistenteAcoes` concede o agente e o Flow; licença de Agentforce atribuída à parte.
  - Evidência: 0 acessos ao agente hoje; `RunFlow = false` nos 4 perfis; padrão da plataforma é acesso por PS.
  - Como mudar: tirar o acesso ao agente deste PS e colocá-lo em outro, sem mexer no Flow.
- [x] **PD-7 — Versão nova v5, ativa; v4 é rollback.**
  - Decisão: mudanças só na v5; v4 intacta.
  - Evidência: todas as versões `Inactive` hoje; editar a v4 apagaria o ponto de retorno.
  - Como mudar: reativar a v4.
- [x] **PD-8 — Contexto de execução.**
  - Decisão: `DefaultMode`, provado no build pelo AC-4; fallback `SystemModeWithSharing` (R5).
  - Evidência: comportamento não confirmado nesta org; o fallback é o que preserva o compartilhamento.
  - Como mudar: um atributo do Flow.
- [x] **PD-9 — Dados de teste sintéticos.**
  - Decisão: build cria `REG-TESTE-01` e dois `REG-TESTE-DUP` (Account) na dev; QA cria os seus na QA e apaga ao fim. Só depois da checagem do R8.
  - Evidência: 0 registros na dev (recon §5); guardrail 2.
  - Como mudar: usar Opportunity sintética, que exige Account mesmo assim.
- [x] **PD-10 — Uma tarefa por confirmação.**
  - Decisão: pedido de várias tarefas vira vários resumos.
  - Evidência: P4 e governador (uma transação por confirmação).
  - Como mudar: Flow com coleção; reavaliar limites.

Nenhuma pergunta ficou no caso (c) da regra 4. **Nada bloqueia o build.**

---

## 10. Estimativa

**Estimativa de esforço:** 20–34 h

| Bloco | h |
|---|---|
| Retrieve de baseline do `SFAgent2`, cópia v4 → v5 | 1–2 |
| Flow `Task_Agente_CriarTarefa` (guardas, fault path) e PS | 4–6 |
| Tópico `acoes_comerciais`, roteador, `deploy validate` cedo (R7), ativação em dev | 6–10 |
| Checagem do Protheus (R8) e dados sintéticos | 1–3 |
| Verificação conversacional AC-1 a AC-9 + caso de check-in | 5–9 |
| Documentação e entrega | 3–4 |

**O que mudou em relação à análise (14–26 h) e por quê:** sobe 6–8 h. O recon e esta sessão mostraram que (1) o agente não tem versão ativa nem acesso concedido, e a v5 será a primeira ativação (R2); (2) o PS existente não serve e os perfis não rodam Flow, então há PS novo com acesso ao agente cuja sintaxe nunca foi testada aqui (R7); (3) o bundle é XML com Agent Script vazio e nenhuma ação de Flow na org para copiar; (4) criar dado sintético de Account exige checar a integração Protheus antes (R8). A estimativa não vale se Account, Opportunity ou Order entrarem como objeto gravado.

---

## 11. Para o aceite do arquiteto humano

1. Conferir as premissas da seção 9, em especial **P5 (mudada)**, **PD-2** (check-in bloqueado) e **PD-6** (PS concede o agente inteiro, inclusive a leitura do `insights_comerciais`).
2. Aceitar que dev × QA (R1) seja resolvido antes do `05-deploy-qa.md`, não agora.
3. Confirmar que nenhuma mudança de modelo de dados é desejada (seção 3.6).

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Decisão do responsável (2026-11-16): versão acumulada do SFAgent2

Decidido por Leonardo Barbosa depois da rodada 2 de QA. Vale acima do que este desenho diz
sobre versões.

- As versões do `SFAgent2` passam a ser **acumuladas**: cada demanda parte da versão mais
  nova que existe na org de dev, e não da que estava ativa quando o desenho foi feito.
- Esta demanda cria a **v12 a partir da v10** (EPLAST-27, já na dev: tem as ações e
  instruções de 27, 29, 34 e 46). Na v12, a única mudança é levar para o tópico
  `acoes_comerciais` as instruções reforçadas de confirmação da v11 (correção da FALHA 1 e da
  FALHA 2 da rodada 2: só dizer que a tarefa foi criada depois de a ação `CriarTarefa` voltar
  com sucesso; sem data, não criar e pedir a data). Nada das outras demandas é removido.
- **O pacote leva só a v12**: tirar da branch `genAiPlannerBundles/SFAgent2_v7`,
  `genAiPlannerBundles/SFAgent2_v11` e `bots/SFAgent2/v7.botVersion-meta.xml` e
  `v11.botVersion-meta.xml` (a v7 já está na QA e não aceita reimplante).
- Ordem na QA: EPLAST-46 (v9), EPLAST-27 (v10), esta (v12). O QA ativa a versão que chega, e
  a v12 fica ativa ao final.
- Teste sem tela: `sf agent preview start` / `send` / `end`, sem o modo interativo.
