# EPLAST-29 · Design — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** design · **Autor:** arquiteto (agente). Precisa do aceite do arquiteto humano.
**Org consultada:** `sbx-eplast-dev`. É sandbox: `Organization.IsSandbox = true`, reconfirmado nesta sessão em 2026-11-11.
**Entradas:** `demanda.md`, `01-analise.md` (gate aprovado em 2026-11-11), `comentarios-do-card.md`, `02-recon.md` (2026-11-11), `assessment.md` (2026-09-30), `contrato.md`, RAG do cliente.

Tudo o que este design cita como existente foi reconfirmado via `sf` nesta sessão. Quando algo não pôde ser confirmado, o texto diz isso. O retrieve de apoio ficou em `/tmp`, fora do repositório.

---

## 0. Leia antes: este design cobre só o escopo reduzido

A análise deixou **seis perguntas bloqueantes** (Q0 a Q5). **Nenhuma foi respondida por escrito.** O único comentário do card registra a aprovação do gate de análise. Seguir para o design foi decisão do humano. Mesmo assim, desenhar para a resposta mais ampla de cada pergunta seria arquitetura apoiada em suposição.

Por isso, a entrega desta rodada é **o mínimo que a `demanda.md` pede sem margem de dúvida**: o usuário comercial pede uma tarefa em linguagem natural ao assistente, vê um resumo e **confirma**. Só depois disso a Task é gravada. Todo o resto fica fora deste design (seção 7) e espera resposta. Isso inclui outros objetos, e-mail e mensagem. Não é um "nunca": é um "ainda não decidido".

Para cada pergunta, o que este design assume como padrão e o que o aceite precisa decidir:

| # | Pergunta da análise | Padrão assumido neste design | O aceite precisa |
|---|---|---|---|
| Q0 | Onda 3 autorizada (aditivo)? | **Não assumido.** O `contrato.md` diz que a Onda 3 "ainda não [foi] contratada". | Confirmar a autorização. Sem ela, este design fica registrado e a demanda não vai para build. |
| Q1 | Plataforma: extensão ou assistente novo? | **Extensão do `SFAgent2`** (Agentforce Employee Agent, único agente da org). Evidência na seção 1. | Confirmar ou rejeitar. |
| Q2 | Quais objetos o assistente cria? | **Só Task**, relacionada (`WhatId`) a uma Account ou Opportunity já existente. | Confirmar ou ampliar. Ampliar para Account, Opportunity ou Order **reabre este design** (assessment #1 e #2). |
| Q3 | E-mail e mensagem: envio ou rascunho? | **Fora do escopo.** | Decidir em outra rodada. Há sobreposição com EPLAST-30 (rascunhos de follow-up). |
| Q4 | A confirmação é sempre obrigatória? | **Sempre**, por configuração da ação (`require_user_confirmation: True`). Não depende do prompt. | Confirmar. |
| Q5 | Quais perfis e permission sets? | Novo permission set atribuído por usuário. Nenhum perfil é alterado. | Dizer quem recebe e quem concede o **acesso ao agente**, que hoje nenhum PS concede (seção 4). |

---

## 1. O que existe na org (reconfirmado nesta sessão)

- **Agente:** `Bot` `SFAgent2` (`AgentforceEmployeeAgent`), com 4 versões de `GenAiPlannerBundle` (`SFAgent2_v1` a `_v4`). **As quatro `BotVersion` estão `Inactive` em `sbx-eplast-dev`** (todas modificadas em 2026-11-10). O recon não registrou esse ponto. Na prática, o assistente não está ativo nesta sandbox hoje.
- **Formato do agente:** Agent Script. Em `SFAgent2_v4` o roteador `agent_router` aponta para 3 subagentes: `off_topic`, `ambiguous_question` e `insights_comerciais`. As 3 ações de `insights_comerciais` são de leitura: `IdentificarConta` → `standardInvocableAction://identifyRecordByName`, `ConsultarPedidos` → `queryRecords` e `AgregacaoPedidos` → `queryRecordsWithAggregate`, todas com `require_user_confirmation: False`. As instruções dizem "Never modify any records; only read data". Não existe `GenAiPlugin` nem `GenAiFunction` na org.
- **Catálogo de ações padrão** (`/actions/standard`, 131 ações). As que servem para escrita aparecem na seção 2: `createTask`, `createRecord`, `updateRecord`, `emailSimple` e `sendConversationMessages`.
- **Task:**
  - sem trigger Apex;
  - 0 validation rules;
  - sem record type;
  - status padrão `Open`, prioridade padrão `Normal`;
  - campos custom só do pacote `maps`;
  - **um Flow ativo, `TaskCreatedOrUpdated`** (RecordAfterSave, Create e Update, API 61). Quando `WhatId` começa com `001` (Account) **e** `Subject` começa com `"Check In @"`, ele atualiza `Account.AccountHasCheckInTask__c = true` (o campo existe e não tem descrição). Fora desse caso, o Flow termina nas decisões, sem DML.
- **Event:** trigger `AdvRouteEvents` do pacote `maps`. Event fica fora do escopo.
- **Perfis comerciais:** `Comercial`, `Comercial Padrão`, `Comercial - Analista` e `Comercial - Analistas` têm `PermissionsEditTask = true` e **`PermissionsRunFlow = false`**. Só `Comercial - Analista` tem usuários ativos (4).
- **Permission sets:** `PS_Comercial_ResumoClienteAgente` dá acesso **só** à classe Apex `CustomerSummaryService`. A descrição cita EPLAST-23. Não dá acesso ao agente, e o `SFAgent2_v4` não referencia essa classe. São 0 atribuições. **Correção ao recon**, que o descreve como "já ligado a este agente". `SetupEntityAccess` não retorna nenhum PS com acesso a `BotDefinition`. O artefato da EPLAST-23 não está no workspace nem no RAG.
- **Baseline local** (`force-app/`): tem `flows/TaskCreatedOrUpdated.flow-meta.xml`. **Não tem** `bots/` nem `genAiPlannerBundles/`.

---

## 2. Decisão

**Abordagem: declarativa.** É um novo subagente no `SFAgent2`, em uma versão nova (v5), com uma ação que chama um **Flow autolaunched** de criação de Task. A ação usa `require_user_confirmation: True`. **Sem Apex.**

### 2.1 Por que não resolver só com configuração (ação padrão do Agent Builder)

Antes de propor o Flow, procurei no catálogo de ações padrão da org uma ação de escrita pronta. Avaliei cada uma:

| Ação padrão (confirmada) | Entradas (`describe`) | Conclusão |
|---|---|---|
| `createTask` ("Criar tarefa") | `taskSubjectName` (obrigatória), `taskAssignedToId`, `taskPriority`, `taskStatus`, `taskComments`, `taskDueInDays`, `taskReminderInDays`, `taskUseAssignedUserLookup` | **Não atende.** Não recebe `WhatId`, então não liga a tarefa ao cliente ou à oportunidade, que é o primeiro critério de aceite. O vencimento é relativo (`DueInDays`), não uma data. Também não permite colocar guardas (seção 3.2). |
| `createRecord` ("Create Record") | `objectApiName` + `recordData` (JSON livre) | **Rejeitada por segurança de escopo.** Quem escolhe o objeto é o LLM. Nada impede o assistente de gravar Account, Opportunity ou Order, que é exatamente o risco alto do assessment (#1 e #2). Restringir só por instrução de prompt não é controle. |
| `updateRecord` | — | Fora do escopo (o pedido é criar). |
| `emailSimple` ("Enviar email") | — | **Envia e-mail de verdade.** Fora do escopo (Q3) e não deve ser ligada ao agente sem decisão explícita. |
| `sendConversationMessages` | — | Mensageria. Fora do escopo (Q3). |

Configuração pura não basta. A única ação padrão específica de Task não aceita o vínculo com o registro, e a genérica abre todos os objetos.

### 2.2 Por que um Flow resolve, sem descer para Apex

O Flow autolaunched exposto como ação do agente resolve o que faltou no nível de configuração:

- tipagem fixa: só cria **Task**, com entradas declaradas;
- `WhatId` e data absoluta;
- guardas determinísticas, que não dependem do LLM;
- caminho de falha com mensagem controlada.

Nenhum dos gatilhos da doutrina para descer a Apex aparece aqui. Não há rollback complexo, callout, volume alto, recursão nem regra que exija teste unitário determinístico. É 1 leitura e 1 DML por pedido confirmado (seção 5).

### 2.3 Por que estender o `SFAgent2` e não criar um agente novo

É o único agente da org. O subagente `insights_comerciais` já resolve a referência a cliente (`identifyRecordByName`, `currentRecordId`) e a mesma ação padrão pode ser reaproveitada. Um agente novo duplicaria roteamento, acesso e licença. A escrita fica em um **subagente separado** para que `insights_comerciais` continue só de leitura, sem mudar uma linha dele.

---

## 3. Componentes

### 3.1 Criar

| Tipo | API name | O que é |
|---|---|---|
| Flow (AutoLaunchedFlow, API 67) | `Task_Agente_CriarTarefa` | Recebe os dados da tarefa e grava 1 Task. Detalhe em 3.2. |
| GenAiPlannerBundle + BotVersion | `SFAgent2_v5` / `SFAgent2.v5` | Nova versão do agente, copiada da v4, com 2 acréscimos: o subagente `acoes_comerciais` e a transição `go_to_acoes_comerciais` no `agent_router`. **A v4 fica intacta** e serve de rollback. |
| PermissionSet | `PS_Comercial_AssistenteAcoes` | `flowAccesses` para `Task_Agente_CriarTarefa`. É necessário porque os perfis comerciais têm `RunFlow = false`. Não dá acesso a objeto, campo ou agente (seção 4). |

**Flow `Task_Agente_CriarTarefa` — contrato:**

- **Entradas.** Todas com `description` preenchida, porque o agente usa a descrição para preencher o valor (assessment #4):
  - `Assunto` (Text, obrigatória);
  - `DataVencimento` (Date, obrigatória, convertida pelo agente para data absoluta);
  - `RegistroRelacionadoId` (Text, obrigatória);
  - `Descricao` (Text, opcional);
  - `Prioridade` (Text, opcional, padrão `Normal`; só `Normal` ou `High`, os valores confirmados).
- **Saídas:** `Sucesso` (Boolean), `TarefaId` (Text), `Mensagem` (Text, em pt-BR, para o agente repassar).
- **Lógica:**
  1. **Guarda de assunto.** Se `Assunto` estiver vazio ou começar com `"Check In @"`, recusa sem gravar (motivo no risco R4).
  2. **Guarda de objeto.** Se `RegistroRelacionadoId` não for de Account nem de Opportunity, recusa. A checagem é por prefixo de objeto (`001`, `006`), que não é ID de registro.
  3. **Get Records** do registro relacionado, para confirmar que existe e que o usuário consegue vê-lo. Se não encontrar, devolve uma mensagem genérica ("registro não encontrado ou sem acesso"), sem nome nem campo do registro (critério de aceite de permissão).
  4. **Create Records Task:**
     - `Subject` = Assunto
     - `ActivityDate` = DataVencimento
     - `WhatId` = RegistroRelacionadoId
     - `OwnerId` = `$User.Id` (sempre quem pediu; delegar para outra pessoa está fora do escopo)
     - `Priority`
     - `Description` = Descricao + linha de origem "Criada pelo assistente de IA" (ver D3)
  5. **Fault path** nos dois elementos: `Sucesso = false` e mensagem amigável. Nada é gravado parcialmente, porque o único DML é o próprio Create.
- **Execução:** `runInMode` = `DefaultMode`. **Ainda não está confirmado** em que contexto (usuário ou sistema) o Agentforce executa um Flow autolaunched nesta org (risco R5). Se o build mostrar contexto de sistema, o fallback é `SystemModeWithSharing`, que respeita o compartilhamento do registro relacionado. A decisão final sai do teste, não deste texto.

**Subagente `acoes_comerciais` (Agent Script, em `SFAgent2_v5`):**

- **Ações:**
  - `IdentificarRegistro` → `standardInvocableAction://identifyRecordByName`, com `require_user_confirmation: False` (só leitura, mesmo alvo já usado na v4);
  - `CriarTarefa` → Flow `Task_Agente_CriarTarefa`, com **`require_user_confirmation: True`**. A sintaxe do alvo de Flow no Agent Script (`flow://...`) não existe em nenhum agente desta org hoje. O build confirma a forma aceita pela plataforma antes de escrever.
- **Instruções** (pt-BR, resumo do que o build escreve):
  - Só cria Task, uma por confirmação.
  - Resolve o registro assim: usa `currentRecordId` se o objeto atual for Account ou Opportunity. Se não for, usa `IdentificarRegistro`. **Com mais de um candidato, lista os candidatos com identificador e pergunta. Não chama `CriarTarefa`.**
  - Se faltar o vencimento, pergunta. Converte datas relativas ("sexta que vem") em data absoluta e mostra a data no resumo.
  - Antes de chamar a ação, mostra o resumo: assunto, registro relacionado, responsável ("você") e vencimento.
  - Se o usuário pedir e-mail, mensagem, outro objeto, alteração de registro existente ou tarefa para outra pessoa, responde que isso não está disponível nesta versão. Não tenta por outro caminho.
- **Roteador:** inclui `go_to_acoes_comerciais` e a descrição do subagente (pedidos de criar tarefa ou follow-up). Fora isso, `agent_router`, `off_topic`, `ambiguous_question` e `insights_comerciais` ficam como estão.

### 3.2 Alterar

| Componente | Alteração |
|---|---|
| `Bot` `SFAgent2` | Ganha a versão v5. Ativar a v5 em `sbx-eplast-dev` é necessário para o teste do build. Hoje nenhuma versão está ativa (risco R2). |

### 3.3 Não tocar (explícito)

- `TaskCreatedOrUpdated`: não muda. A guarda do Flow novo evita o único ramo dele que faz DML.
- `insights_comerciais` e as instruções dele, inclusive a divergência do risco R8.
- `PS_Comercial_ResumoClienteAgente`: ligado à EPLAST-23, que não está no workspace. Não é reaproveitado.
- Perfis.

### 3.4 Depreciar

Nada.

### 3.5 Modelo de dados

**Nenhuma mudança no escopo padrão.** O critério de rastreabilidade (RN-4) fica coberto por `CreatedById`, já que a execução é em contexto de usuário (confirmar em R5), e pela linha de origem em `Description`. Um campo novo em Task para origem ou ID da conversa **seria mudança de modelo de dados** e, por regra deste squad, fica para o arquiteto humano decidir (D3). Não proponho esse campo por conta própria.

---

## 4. Impacto em permissões

- **Novo `PS_Comercial_AssistenteAcoes`**, atribuído por usuário (Q5). Contém só o acesso ao Flow `Task_Agente_CriarTarefa`. Criar Task já vem do perfil (`EditTask = true` nos 4 perfis comerciais).
- **Nenhum perfil é alterado.** Isso segue o assessment #8: permissão em PS, não em perfil duplicado.
- **Acesso ao agente: lacuna fora desta demanda.** Nenhum permission set concede acesso ao `SFAgent2` hoje. A conclusão vem de `SetupEntityAccess` sem nenhum `BotDefinition`, e nenhuma versão está ativa. Sem esse acesso, ninguém usa nem o subagente de leitura nem o novo. Quem concede, e em qual PS, é **decisão D2 do aceite**. Pode ser o dono do `eplast-ent-07`. Não incluo esse acesso no PS novo para não liberar, de carona, o agente inteiro (incluindo `insights_comerciais`) a quem só deveria criar tarefa.
- **Licença:** a licença `Salesforce` está em 14/14. O teste de QA vai rodar com um usuário existente do perfil `Comercial - Analista`, e não com um usuário dedicado. O contador de licença e crédito do Agentforce não é confiável (recon §4). Isso não foi medido; ver R9.
- **OWD:** Account `ReadWrite` e Opportunity `Read` (interno). O compartilhamento de Task segue o registro relacionado. Ler o pai basta para relacionar a tarefa, e o Get Records do Flow confirma isso.

---

## 5. Governador, escala e ordem de execução

- **Por pedido confirmado:** 1 SOQL (Get Records) e 1 DML (Create Task). Depois disso roda o after-save de `TaskCreatedOrUpdated`. Com a guarda de assunto, ele termina nas decisões, com 0 SOQL e 0 DML a mais. A plataforma atualiza `LastActivityDate` sem disparar trigger nem Flow de Account ou Opportunity.
- **Volume em massa:** não se aplica. Cada criação é uma transação própria, disparada por uma confirmação humana. Um pedido como "crie 10 tarefas" vira 10 confirmações, por instrução do subagente.
- **CPU, um pai com muitos filhos (achado SOMOSAGILITY-10):** não se aplica. A Task é filha, mas **não há automação que recalcule o pai por filho**. O único caminho que escreveria no pai (Account, via check-in) é bloqueado pela guarda. Se a guarda for removida, essa análise precisa ser refeita.
- **Volume real:** desconhecido. A sandbox tem 0 Task, e produção não é consultada.
- **Conflito de automação: existe automação em Task no evento de criação.** Esta demanda **não acrescenta** automação record-triggered em Task. O Flow novo é autolaunched, chamado pelo agente. Mesmo assim, **toda Task criada pelo assistente passa por `TaskCreatedOrUpdated` (after-save). Se o assunto começar com "Check In @" e a tarefa estiver ligada a uma Account, o Flow atualiza a Account. Isso dispara a cadeia de Account do assessment #1: `AccountTrigger`, `AccountBefore` (SBQQ) e os Flows `AccountTriggered`, `SetPaymentTermsChangesinAccount` e `UpdateParentAccountUsedLimit`. Também pode chegar a `SendAccountToProtheus`, caminho que não confirmei. A guarda de assunto no Flow novo existe para fechar esse caminho.**

---

## 6. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Q0 a Q5 sem resposta.** Escopo contratual (Onda 3 não contratada) e escopo funcional não confirmados. Qualquer ampliação, como outros objetos, e-mail ou mensagem, invalida partes deste design. | **Alta** | O design cobre só o escopo reduzido. O aceite decide (seção 9). |
| R2 | **Agente sem versão ativa e sem acesso concedido em `sbx-eplast-dev`.** Além disso, `SFAgent2` é base de entregáveis construídos **fora da esteira** (`eplast-ent-09/10`). Uma edição paralela por fora pode sobrescrever a v5, ou a v5 pode sobrescrever o trabalho deles. | **Alta** | Mudança em versão nova (v5) e v4 intacta. Antes do build, alinhar com quem mantém o agente fora da esteira (guardrail #6). O build retrieve do `SFAgent2` atual imediatamente antes de editar. |
| R3 | **dev e qa podem ser a mesma sandbox** (assessment #6, reconfirmado: a instância de `sbx-eplast-dev` se identifica como "qa"). | **Alta** para homologação. Não bloqueia o design. | Resolver com o humano antes da etapa de QA. Não é decisão de agente. |
| R4 | **Cascata Task → Account pelo `TaskCreatedOrUpdated`** (seção 5). Pode acionar a automação concorrente de Account (assessment #1) e a integração Protheus sem teste (assessment #2). | Média, mitigado | Guarda determinística no Flow: recusa assunto que comece com "Check In @". Check-in fica com o fluxo que já existe (aparentemente Salesforce Maps, não confirmado). Caso de QA dedicado. |
| R5 | Contexto de execução do Flow chamado pelo agente (usuário ou sistema) não confirmado. Afeta RN-3 (não elevar privilégio) e `CreatedById`. | Média | Teste obrigatório no build: um usuário sem acesso ao registro deve ser recusado. Fallback: `SystemModeWithSharing` (seção 3.1). |
| R6 | Ambiguidade (RN-5) e o resumo antes da confirmação dependem em parte do LLM. | Média | A barreira determinística é `require_user_confirmation: True` mais as guardas do Flow. A ambiguidade é testada com conversa real no QA (dois registros com o mesmo nome). |
| R7 | Deploy e validação de CI (`ci-salesforce-validate.yml`) de `GenAiPlannerBundle` com Agent Script nunca rodaram nesta esteira. A sintaxe do alvo de Flow não foi confirmada. | Média | O build faz `sf project deploy validate` cedo, antes de escrever as instruções finais. |
| R8 | As instruções da v4 citam ações que não existem no bundle (`ConsultarOportunidadesConta`, `ConsultarAtividadesConta`, `IdentificarUsuario`). É uma divergência anterior a esta demanda, feita fora da esteira. | Baixa | Não corrijo (fora de escopo). Registro para o dono de `eplast-ent-09/10`. A v5 copia a v4 como está. |
| R9 | Licença ou crédito do Agentforce para os usuários de teste não confirmados. O contador "0 em uso" não é confiável. | Baixa | Confirmar no aceite (análise, P6). |
| R10 | `PS_Comercial_ResumoClienteAgente` e `CustomerSummaryService` (EPLAST-23) existem na org sem artefato no workspace. | Baixa | Não reaproveitados nem alterados. |

### Riscos do assessment que tocam os objetos desta demanda

| Achado | Como este design lida |
|---|---|
| #1 Automação concorrente em Account, Opportunity e Order (alta) | Não há DML em nenhum dos três. O único caminho indireto (check-in → Account) é bloqueado pela guarda (R4). Se Q2 incluir esses objetos, o design volta para revisão. |
| #2 Cobertura Apex de 10% e cadeia Protheus (alta) | Não há Apex. A cadeia Protheus não é tocada, porque o caminho indireto é bloqueado. |
| #3 Validation rules de Order (média) | Não se aplica (Order fora do escopo). |
| #4 Campos sem descrição (média) | Entradas do Flow, Flow, PS e subagente saem com descrição. Não usa campo custom de Account ou Opportunity. |
| #5 Convenção de teste e #9 API de Apex | Não se aplicam (sem Apex). O Flow `TaskCreatedOrUpdated` está na API 61, mas não é editado. |
| #6 dev = qa? (média) | R3: bloqueia homologação, não o design. |
| #7 e #8 Perfis | Não altera perfil. O acesso vai por PS. Dos 4 perfis comerciais, só `Comercial - Analista` tem usuário ativo. |
| #10 `OrderTrigger` duplicado | Não se aplica. |
| OWD não medido no assessment | Medido no recon e usado na seção 4. |

---

## 7. O que NÃO será feito nesta demanda

Nada desta lista está proibido para sempre. São pontos **não decididos (Q0 a Q5)**, e desenhar para eles seria arquitetura apoiada em suposição.

- Criar ou alterar **Account, Opportunity, Order, Lead, Contact ou Case** pelo assistente (Q2). Reabre o assessment #1 e #2.
- **Event** (tem trigger `maps` próprio, não avaliado).
- **E-mail**, enviado ou em rascunho, e **mensagens** (WhatsApp, Slack, mensageria) (Q3). `emailSimple` envia de verdade e não será ligada ao agente. Rascunho de follow-up se sobrepõe à EPLAST-30.
- Alterar registros existentes (`updateRecord`), atribuir tarefa a outra pessoa, criar em lote.
- Conceder **acesso ao agente** e ativar o agente fora de `sbx-eplast-dev` (D2). Na sandbox de QA, a ativação acontece no fluxo normal de release, nunca em produção.
- Corrigir as instruções ou ações de `insights_comerciais` (R8), consolidar perfis (assessment #8), mexer em `TaskCreatedOrUpdated`.
- Campo novo em Task para rastreabilidade (D3, mudança de modelo de dados).
- Apex de qualquer tipo.
- Treinamento e adoção (Onda 5).

---

## 8. Estimativa

**Estimativa de esforço:** 20–34 h

| Bloco | h |
|---|---|
| Retrieve do `SFAgent2` para a baseline, alinhamento com quem mantém o agente fora da esteira (R2) | 2–4 |
| Flow `Task_Agente_CriarTarefa` com guardas e fault path, e PS | 4–6 |
| Versão v5: subagente, ações, roteador, deploy validate (R7), ativação em dev | 6–10 |
| Teste em sandbox com conversas reais, cobrindo os cenários da análise: confirmação, recusa, ambiguidade, sem permissão, campo faltante, check-in bloqueado, rastreabilidade | 5–9 |
| Documentação e entrega | 3–5 |

**O que mudou em relação à análise (40–80 h) e por quê:**

- O escopo caiu para Task só, sem e-mail nem mensagem. A própria análise previa a queda para M nesse caso.
- A plataforma já existe (Q1 respondida por evidência na org).
- Não há Apex, então não há classe de teste nem cobertura a construir.
- Nenhum objeto com automação concorrente é escrito.

O limite superior continua alto por quatro motivos:

- o agente está sem versão ativa e sem acesso (R2);
- o deploy de Agent Script ainda não foi testado nesta esteira (R7);
- o teste de agente é conversacional e consome mais tempo que o teste de Flow;
- dev e qa podem ser a mesma sandbox (R3).

**Esta estimativa não vale se Q2 ou Q3 ampliarem o escopo.** Nesse caso o design volta para revisão.

Contrato da Eplast: projeto, não AMS. A aprovação de horas pelo cliente não se aplica. A pendência contratual que importa é Q0.

---

## 9. Para o aceite: o que o arquiteto humano decide neste gate

O aceite deste gate decide **duas coisas juntas**: o desenho técnico **e** o escopo, ou seja, as perguntas da análise que ninguém respondeu. Aprovar sem responder Q0 a Q5 significa **aceitar explicitamente o escopo reduzido da seção 0**. Isso precisa ser dito no aceite, não presumido.

1. **Q0:** a Onda 3 tem autorização para entrar em build? Se não, o design fica registrado e a demanda não segue.
2. **Q1 a Q5:** responder cada uma ou declarar "aceito os padrões da seção 0".
3. **D1:** objetos aceitos como `WhatId`: Account e Opportunity (padrão). Ampliar para Contact ou Lead via `WhoId` aumenta o teste, não a arquitetura.
4. **D2:** quem concede o acesso ao `SFAgent2` e em qual PS. Também: quem coordena com quem mantém o agente fora da esteira (R2).
5. **D3:** rastreabilidade. O padrão é `CreatedById` + linha em `Description`. A alternativa, um campo novo em Task, é **mudança de modelo de dados** e **cabe a você decidir, não ao agente**.
6. **R3:** confirmar quem resolve a dúvida dev/qa antes da etapa de QA.

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
