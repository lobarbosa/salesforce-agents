# EPLAST-29 · Design (rodada 4) — Ações por linguagem natural no assistente de IA, ajustado às respostas do cliente de 17/11

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** design · **Autor:** arquiteto (proposta para o aceite do arquiteto humano)
**Org conectada nesta sessão:** `sbx-eplast-dev` (sandbox, Org ID 00DHa000006vfMLMAY, única org em `sf org list`; é a `eplast--qa` da Eplast, dev da esteira pela regra 5). Produção e QA não foram tocadas. Só metadata e contagens agregadas; nenhum registro lido, nenhum DML, deploy ou anonymous Apex.
**Entradas:** `01-analise.md` (aprovada em `gates.md`), `02-recon.md` (refeito em 17/11), `00-preflight.md`, `comentarios-do-card.md`, respostas do cliente de 17/11 (registradas no fim do desenho anterior e reproduzidas na seção 1), build e QA da rodada anterior em `rodada-anterior/premissas-assumidas/` (QA aprovado na v13).
**Histórico consultado (RAG):** `EPLAST-46/03-design.md` (custom metadata de parâmetros levado à decisão do arquiteto humano, precedente para o item 3.2-C), `EPLAST-27/03-design.md` (versão acumulada do `SFAgent2`: "v15 a partir da v14"), decisão do responsável de 16/11 (versões acumuladas, cada demanda parte da mais nova da dev).

---

## 1. Contexto e escopo

O que já foi construído e aprovado no QA (rodada 3, v13): tópico `acoes_comerciais` no `SFAgent2`, com as ações `IdentificarRegistro` (busca padrão `identifyRecordByName`) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`), confirmação obrigatória, e uma Task gravada por confirmação, ligada a conta ou oportunidade.

A Eplast respondeu por escrito em 17/11. **Onde a resposta diverge de premissa anterior, vale a resposta:**

| Resposta do cliente | Situação no que foi construído | O que muda |
|---|---|---|
| Só **tarefas**, ligadas a **lead**, cliente ou oportunidade. Compromisso, conta, oportunidade e pedido fora | Aceita só conta e oportunidade (guarda de prefixo `001`/`006`, grava em `WhatId`) | **Aceitar Lead** (prefixo `00Q`, gravado em `WhoId`) |
| E-mail e mensagem só como rascunho, revisado pelo usuário antes do envio | Já é assim (rascunho em `Task.Description`, nada enviado) | Nada, só reforço da frase "revise antes de enviar" |
| Confirmação obrigatória antes de gravar, mostrando registro relacionado, responsável, descrição e prazo | Resumo mostra assunto, registro, responsável, vencimento e rascunho quando há. Descrição só aparece se houver rascunho | Resumo passa a mostrar **sempre** os quatro itens (descrição como "sem descrição" quando vazia) |
| Acesso: SDR, vendedores/executivos, pós-vendas e gestão comercial, respeitando as permissões de cada usuário | PS `PS_Comercial_AssistenteAcoes` atribuído pelo administrador; Task e leitura do registro vêm do perfil | Nada no desenho de acesso; o roteiro lista os quatro públicos |
| Parâmetros configuráveis, sem deploy para ajustar (pedido do cliente, registrado pelo responsável) | Regras fixas no Flow | Parâmetros do Flow saem para configuração editável em Setup (3.2-C) |

**Escopo desta rodada:** só o que a resposta pede. Reaproveita tudo o que passou no QA.

## 2. Decisão declarativo vs. código

**Declarativo, sem Apex.** Nova versão do Flow `Task_Agente_CriarTarefa` (v2), nova versão acumulada do `SFAgent2` (v16, a partir da v15) e, se o arquiteto humano aprovar, um custom metadata type de parâmetros.

- **Por que não só configuração:** a ação padrão `createTask` não recebe registro relacionado (nem `WhatId` nem `WhoId`), e `createRecord` deixa o modelo escolher o objeto (confirmado na rodada anterior, seção 2.1 do desenho de 15/11). Aceitar Lead exige mudar a guarda e o campo gravado, que só existem no Flow.
- **Por que Flow basta:** a mudança é uma decisão a mais (prefixo `00Q` → `WhoId`) e um Get Records a mais (lead convertido). Uma transação por confirmação humana, 1 DML, sem callout, sem rollback complexo, sem recursão. Nenhum gatilho da doutrina para Apex. Sem Apex, o achado #2 do assessment (cobertura de 10%) não piora.
- **Agente:** estende o tópico existente do `SFAgent2` (regra 3). Nenhum agente, tópico ou ação nova.

## 3. Reaproveita vs. cria (item a item)

### 3.1 Reaproveita sem alterar

| Componente | Confirmado | Como é usado |
|---|---|---|
| Agente `SFAgent2` | recon §1 | Recebe a versão v16. Continua o único agente |
| Tópicos `insights_comerciais`, `agent_router`, `ambiguous_question`, `off_topic` e as ações de EPLAST-27, 34 e 46 na v15 | recon §1 e §7 | Copiados para a v16 **sem mudança de conteúdo** |
| Ação `IdentificarRegistro` (alvo `identifyRecordByName`) | recon §1 | Mesma ação; só a instrução passa a pedir `objectApiName = Lead` também |
| PS `PS_Comercial_AssistenteAcoes` | recon §1; nesta sessão: é o único `SetupEntityAccess` apontando para o `BotDefinition` do `SFAgent2` (o recon §8.3 dizia que não havia referência ao agente; **concede sim** o agente) | Continua concedendo agente e Flow. Recebe só leitura do custom metadata, se 3.2-C for aprovado |
| Campos padrão de Task (`Subject`, `ActivityDate`, `WhatId`, `WhoId`, `OwnerId`, `Description`, `Priority`, `Status`, `TaskSubtype`) | recon §2 (`WhoId` aceita Lead e Contact; `WhatId` não aceita Lead) | Únicos campos gravados. Nenhum campo novo |
| Perfis comerciais | nesta sessão: `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, `Marketing`, `Usuário do Marketing` com `EditTask = true`, leitura e edição de Lead, `RunFlow = false` | Não alterados. Dão criar Task e ler Lead; o PS dá o Flow |
| Flow `TaskCreatedOrUpdated` | recon §3 | Não alterado |

### 3.2 Cria

| Id | Tipo | API name | O que é |
|---|---|---|---|
| A | Versão de Flow | `Task_Agente_CriarTarefa` **versão 2** (hoje só existe a v1, `Active`, confirmado nesta sessão) | Mudanças da seção 4.1 |
| B | GenAiPlannerBundle + BotVersion | `SFAgent2_v16` + `bots/SFAgent2/v16.botVersion-meta.xml`, inativa ao nascer, ligada ao planner | Cópia da v15 com nomes globais `_v16`; muda só o tópico `acoes_comerciais_EPLAST29` e o schema da ação `CriarTarefa` (seção 4.2) |
| C | Custom metadata type (**decisão do arquiteto humano, seção 9**) | `AssistenteTarefaSetting__mdt`, registro `Padrao` | Parâmetros editáveis em Setup sem deploy (seção 4.3). Segue o precedente de `CampaignSuggestionSetting__mdt` (EPLAST-46) e `NextBestActionSetting__mdt` (EPLAST-27), ambos confirmados na org nesta sessão; nenhum deles serve (são de outras funções, acoplaria demandas) |
| D | Fixture | `fixtures/lead.apex` (pasta do cliente) | Lead sintético `REG-TESTE-LEAD-01` e dois `REG-TESTE-DUP` como Lead, sem telefone (as validation rules `Celular` e `Telefone` de Lead só checam formato, recon §3). Hoje só existe `fixtures/account.apex` e não há `fixtures/README.md`; o build cria o script e o README |

### 3.3 Não cria

Agente, tópico ou ação nova; campo em Task ou Lead; trigger; permission set novo; perfil; relatório.

## 4. Componentes a alterar (sempre versão nova)

### 4.1 Flow `Task_Agente_CriarTarefa`, versão 2

A v1 está ativa e não é editada. A v2 é criada a partir da v1 e **ativada como passo separado** na dev, para a verificação (rollback: reativar a v1). Na QA, a esteira implanta e ativa no passo fixo de `05-deploy-qa.md`.

Entradas e saídas: as mesmas da v1 (`Assunto`, `DataVencimento`, `RegistroRelacionadoId` obrigatórias; `Descricao`, `Prioridade` opcionais; saídas `Sucesso`, `TarefaId`, `Mensagem`). As descrições em pt-BR de `RegistroRelacionadoId` e da mensagem de falha passam a dizer "lead, conta ou oportunidade".

Mudanças de lógica:
1. **Leitura dos parâmetros** (Get Records no registro `Padrao` de `AssistenteTarefaSetting__mdt`; leitura de custom metadata não conta no limite de SOQL). Sem registro ou com `Ativo__c = false`: recusa com mensagem "a criação de tarefas pelo assistente está desligada".
2. **Guarda de prefixo configurável:** o prefixo do `RegistroRelacionadoId` tem de estar em `PrefixosPermitidos__c` (valor inicial `001;006;00Q`). Fora da lista: recusa, mensagem "só é possível criar tarefa ligada a lead, cliente ou oportunidade". O prefixo identifica o objeto, não é Id de registro.
3. **Lead (`00Q`):** Get Records do Lead (`Id`, `IsConverted`). Não achado → mensagem genérica "registro não encontrado ou sem acesso" (sem nome nem campo, AC-4). `IsConverted = true` → recusa: "este lead já foi convertido; peça a tarefa na conta ou na oportunidade dele" (a plataforma não aceita Task nova em lead convertido). Senão grava **`WhoId` = Id do lead e `WhatId` vazio**.
4. **Conta e oportunidade (`001`, `006`):** comportamento da v1, `WhatId` = Id, `WhoId` vazio.
5. **Descrição obrigatória configurável:** se `DescricaoObrigatoria__c = true` e `Descricao` vier vazia, recusa pedindo a descrição. Valor inicial `false` (premissa PA-3).
6. Prioridade padrão vem de `PrioridadePadrao__c` (valor inicial `Normal`); valor fora de `Normal`/`High` vira o padrão.
7. Marca de origem: a linha final da `Description` vem de `MarcaOrigem__c` (valor inicial `Origem: assistente de IA`, o mesmo da v1, AC-8).
8. Mantidas da v1: assunto vazio recusa; assunto começando com `Check In @` recusa; data vazia recusa; `OwnerId = $User.Id`; `Status = Open`; `TaskSubtype = Task`; fault path com mensagem amigável; 1 DML, sem gravação parcial; `runInMode = DefaultMode`.

**Fallback se o arquiteto humano recusar o item C:** os valores viram constantes do Flow com os mesmos valores iniciais (guardas 1, 5, 6 e 7 fixas). Ajustar exigirá nova versão do Flow e deploy, e o pedido "sem deploy" fica registrado como não atendido.

### 4.2 `SFAgent2`, versão v16 a partir da v15

- **Por que v15:** é a mais nova na dev (v1 a v15; só a v13 ativa, recon §1) e reúne as ações de EPLAST-27, 34 e 46 (recon §7). Regra de versões acumuladas (decisão de 16/11): o build parte da mais nova que existir na dev **no momento do build**; se outra demanda tiver criado a v16 antes, esta vira a seguinte e o build registra a base usada.
- **Nada de EPLAST-27, 34 e 46 é removido nem editado.** O build confere por grep que `insights_comerciais` mantém as 6 ações da v15.
- **Mudanças só no tópico `acoes_comerciais_EPLAST29` (nome `_v16`):**
  1. Instrução de escopo: "só cria tarefas ligadas a um **lead**, a um cliente (conta) ou a uma oportunidade". Compromisso, conta, oportunidade, pedido, alteração de registro, tarefa para outra pessoa e check-in: recusa e informa que não está disponível nesta etapa.
  2. Busca: `IdentificarRegistro` com `objectApiName` `Lead`, `Account` ou `Opportunity`, conforme o usuário disser ("lead", "cliente/conta", "oportunidade"). Se o usuário não disser o tipo, procura nos três; mais de um candidato (inclusive mesmo nome em tipos diferentes) → lista com nome, **tipo** e identificador, e pergunta; não chama `CriarTarefa` (AC-3). Na página de um registro desses três tipos, usa o registro da página.
  3. **Resumo de confirmação, sempre com os quatro itens pedidos pelo cliente**, mais o assunto: registro relacionado (nome e tipo: lead, cliente ou oportunidade), responsável ("você", o usuário que pede), descrição (o texto que será gravado, ou "sem descrição"), prazo (data absoluta). Só chama `CriarTarefa` depois do aceite; só diz "tarefa criada" quando a ação volta com `Sucesso = true`; com falha, repassa a `Mensagem` (mantidas da v13: correções da FALHA 1 e FALHA 2).
  4. Rascunho de e-mail ou mensagem: texto no campo descrição, assunto `Rascunho de e-mail - <tema>` ou `Rascunho de mensagem - <tema>`, e a frase "revise o texto antes de enviar; o envio não é feito pelo CRM" (Marketing Cloud, se for comunicação de marketing; canal do próprio usuário, se for contato individual).
  5. Quando `CriarTarefa` recusa por regra (prefixo, lead convertido, desligado), repassa a mensagem sem insistir.
- **Ação `CriarTarefa` (GenAiFunction `_v16`):** schema de entrada com a descrição de `RegistroRelacionadoId` dizendo "Id de lead (00Q), conta (001) ou oportunidade (006)". Confirmação do usuário obrigatória, como na v13.
- **Ativação:** passo separado. Na dev, `sf agent activate` da v16 para a verificação; rollback é reativar a v13. Na QA, pelo fluxo de release, depois das versões de EPLAST-27, 34 e 46 (seção 6, R2).
- **Pacote da branch:** só `SFAgent2_v16` e `v16.botVersion-meta.xml` do agente (v13 e anteriores já estão nas orgs e não aceitam reimplante), a v2 do Flow, o item C e o PS se ele mudar.

### 4.3 Parâmetros (item C, se aprovado)

`AssistenteTarefaSetting__mdt`, visibilidade pública, campos com descrição preenchida (assessment #4):

| Campo | Tipo | Valor inicial no registro `Padrao` | Para que serve |
|---|---|---|---|
| `Ativo__c` | Checkbox | `true` | Desliga a gravação pelo assistente sem desativar o agente |
| `PrefixosPermitidos__c` | Texto (50) | `001;006;00Q` | Objetos aceitos como registro relacionado. Tirar um prefixo bloqueia o objeto sem deploy. **Acrescentar** objeto novo também exige nova versão do Flow (campo gravado) e do agente (busca), e fica para demanda própria |
| `PrioridadePadrao__c` | Texto (20) | `Normal` | Prioridade quando o usuário não diz |
| `DescricaoObrigatoria__c` | Checkbox | `false` | Exige descrição antes de gravar |
| `MarcaOrigem__c` | Texto (80) | `Origem: assistente de IA` | Linha de rastreabilidade na descrição |

Edição: Setup → Tipos de metadados personalizados → registro `Padrao`, pelo administrador, sem deploy. `PS_Comercial_AssistenteAcoes` ganha leitura do tipo (para o caso de a org restringir leitura de custom metadata).

### 4.4 Permissões

- Nenhum perfil alterado (assessment #7/#8). Nenhum PS novo.
- **Quatro públicos:** a org não tem perfil nem papel com nome de SDR, pós-vendas ou gestão comercial (perfis com usuário ativo: `Administrador do sistema` 9, `Comercial - Analista` 4, `Financeiro` 1, mais usuários de integração; papéis: `Coordenação` e `Financeiro`; existe o PS `PS_PosVendas_Atendimento`, conteúdo não lido). Por isso o acesso continua **por usuário**: o administrador atribui `PS_Comercial_AssistenteAcoes` a cada pessoa dos quatro públicos (premissa PA-5). O PS não concede objeto: criar Task e ler o lead, a conta ou a oportunidade vêm do perfil de cada um, o que atende "respeitando as permissões de cada usuário".
- **Licença de Agentforce:** atribuição manual pelo administrador, fora do metadata. Na dev, `Agentforce Coworker` 0 de 100.000 usadas (nesta sessão). Sem licença, o usuário não usa o agente.
- **Compartilhamento:** Task `Private` (o dono vê só as suas; o dono é quem pediu). Lead interno `ReadWriteTransfer` (recon §6): o vendedor enxerga leads, então pode ligar tarefa a qualquer lead que vê. O Get Records do lead no Flow respeita o contexto de execução (R4).

## 5. Ordem de execução e riscos do assessment

**Objeto gravado: só Task.** Nenhuma escrita em Lead, Account, Opportunity ou Order.

| Evento | O que roda | Efeito desta demanda |
|---|---|---|
| Insert de Task (ligada a lead, conta ou oportunidade) | Sem trigger, sem validation rule. Só `TaskCreatedOrUpdated` (after-save), que age apenas com `WhatId` `001` e assunto `Check In @` | Com lead: `WhatId` vazio, não age. Com conta: a guarda `Check In @` continua fechando o ramo que gravaria `Account.AccountHasCheckInTask__c`. Ordem determinística (um componente) |
| Lead | Task com `WhoId` não grava o lead; as validation rules `Celular`/`Telefone` e eventuais automações de Lead não rodam. Nenhum Flow record-triggered de Lead achado no repositório da linha de base (recon §3; não confirmado na org, ver seção 10) | Nenhum |
| Account | `AccountBefore` (SBQQ) e `AccountTrigger` (custom), mais Flows after-save de Account. Ordem entre eles não garantida | **Não acionado**: o assistente não grava em Account (guarda `Check In @` mantida). A `AccountTrigger` enfileira um job por conta e manda a conta ao Protheus em update; esta solução não grava Account, nem em massa. As contas de teste saem de `fixtures/account.apex` com `TriggerUtility.bypassTrigger` |
| Opportunity, Order | Triggers SBQQ e custom, Flows after-save | Não acionados (Task com `WhatId` de oportunidade só atualiza dado derivado de atividade pela plataforma; o QA confere no AC-7) |

**Defeito existente, fora desta demanda:** `UpdateAccountCompanyInfo.execute` grava a conta e chama `SendAccountToProtheus.execute` na mesma transação ("You have uncommitted work pending"). Não é tocado nem corrigido aqui; só registrado. Não interfere no desenho, porque nada aqui grava Account.

**Governador:** por confirmação, 2 SOQL no pior caso (registro relacionado e, para lead, o mesmo Get), 0 SOQL para o custom metadata, 1 DML. Carga em massa não se aplica (uma transação por aceite humano). **CPU com pai de muitos filhos (SOMOSAGILITY-10):** não se aplica, nenhuma automação recalcula o lead, a conta ou a oportunidade por Task.

| Achado do assessment | Como o desenho lida |
|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | Não grava nesses objetos; ramo indireto (check-in) fechado. Mapa de ordem não é pré-requisito |
| #2 Cobertura Apex de 10% | Sem Apex |
| #3 Validation rules de Order / #10 `OrderTrigger` homônimo | Não se aplica (Order fora) |
| #4 Campos sem descrição | Campos do item C, variáveis do Flow e schema da ação saem com descrição |
| #6 dev × QA | Resolvido pela regra 5 da conta; não é risco |
| #7/#8 Perfis comerciais duplicados | Nenhum perfil alterado; acesso por PS |

## 6. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Outras demandas no mesmo agente** (EPLAST-27, 34, 46, aguardando homologação). A v16 carrega as ações delas | Alta | v16 a partir da mais nova da dev, sem editar nada delas. Se uma delas voltar ao build e criar versão nova, a versão desta demanda é refeita sobre a mais nova (regra de 16/11) |
| R2 | **Dependência na QA:** a v16 referencia Flows e classe de EPLAST-27 (`Account_Agente_ProximaAcao`), 34 (`MeetingSummaryService`) e 46 (`Account_Agente_SugestaoCampanha`). Se não estiverem na QA, o deploy da v16 falha | Alta | `05-deploy-qa.md` confere a presença deles antes; ordem do release: 46, 27, 34, depois esta |
| R3 | `identifyRecordByName` com `objectApiName = Lead` não exercitado (a dev tem 0 lead; a ação não aparece em `/actions/standard`, tentado nesta sessão) | Média | Build cria o lead sintético e exercita no início; se a busca padrão não aceitar Lead, volta ao gate de design (alternativa: Flow de busca de lead), sem improvisar |
| R4 | Contexto de execução do Flow chamado pelo agente (`DefaultMode`) não provado com usuário não administrador; o AC-4 ficou não executado na rodada anterior por falta de usuário | Média | Verificação e QA tentam com usuário não administrador com licença; se não houver, fica como inconclusivo declarado e vai ao roteiro do cliente |
| R5 | Mesmo nome em lead e conta (ex.: lead da empresa ainda não convertido e a conta dela) | Média | Instrução manda listar com tipo e perguntar; cenário de teste dedicado (Q-3) |
| R6 | Item C recusado no gate | Baixa | Fallback com constantes (4.1) |
| R7 | Ativação manual em duas peças (Flow v2 e agente v16) | Baixa | Ordem: ativar Flow v2 antes da v16. A v13 ativa já chama o Flow pelo nome, então ativar só a v2 do Flow já aceita Lead pela v13, mas a v13 não procura lead; não há estado quebrado em nenhuma ordem |

## 7. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca lead e comunicação (rascunho de e-mail e mensagem). Ela **não envia nada e não cria público** para o Marketing Cloud.

- **Dados que o MC lê e onde ficam:** nada novo. A tarefa ligada a lead fica em `Task` com `WhoId` = lead; o rascunho fica em `Task.Description`, com assunto `Rascunho de e-mail - ...` ou `Rascunho de mensagem - ...`. É anotação de trabalho do vendedor, não fonte de jornada.
- **Público ou segmento identificável no CRM:** não se aplica a esta demanda. Se a Eplast quiser que um rascunho vire comunicação de marketing, o caminho do CRM é `Campaign` e `CampaignMember` (0 registros na dev, recon §5), em demanda própria.
- **O que o MC devolve e onde é gravado:** nada desta demanda. Retornos de envio continuam nos objetos do conector `et4ae5`, sem alteração.
- **Consentimento e opt-out:** Lead e Contact têm `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` (confirmado no desenho de 15/11). O assistente não envia, então não consulta nem altera consentimento; quem envia (o MC ou o usuário) aplica o opt-out. Nenhum campo de consentimento criado ou gravado.
- **O que fica com quem opera o MC:** nada a fazer por causa deste build. Se quiserem usar tarefas de lead ou rascunhos como gatilho de comunicação, abrir demanda para o lado do CRM.

Nada é feito no Marketing Cloud nem no conector.

## 8. Premissas assumidas (validar na homologação)

Premissas da análise e do desenho de 15/11 que a resposta do cliente **confirmou** deixam de ser premissa: só tarefa (P2, agora com lead), rascunho sem envio (P3, PD-3), confirmação obrigatória (P4), públicos de acesso (P5). As demais seguem como estavam no desenho de 15/11 (P6 a P13, PD-2, PD-5, PD-7 a PD-10), salvo o que muda abaixo.

- [x] **PA-1 — Lead em `WhoId`, sem `WhatId`.**
  - Pergunta: tarefa de lead fica ligada só ao lead?
  - Decisão: sim, `WhoId` = lead, `WhatId` vazio.
  - Evidência: describe de Task na dev (`WhatId` não aceita Lead; `WhoId` aceita Lead e Contact; recon §2). Padrão da plataforma.
  - Como mudar: n/a no modelo; na conversão do lead, a plataforma leva as atividades para o contato e a conta.
- [x] **PA-2 — Lead convertido é recusado.**
  - Pergunta: e se o usuário pedir tarefa num lead já convertido?
  - Decisão: o Flow recusa e orienta a pedir na conta ou na oportunidade.
  - Evidência: padrão da plataforma (Task nova não referencia lead convertido); evita erro técnico na tela.
  - Como mudar: retirar a guarda na próxima versão do Flow (não recomendado).
- [x] **PA-3 — Descrição mostrada sempre, mas não obrigatória.**
  - Pergunta: o cliente pede ver a descrição na confirmação; ela é obrigatória?
  - Decisão: o resumo sempre mostra a descrição (ou "sem descrição"); gravar sem descrição é permitido.
  - Evidência: o cliente pediu exibir, não exigir; o describe de Task não exige `Description`. Opção mais simples.
  - Como mudar: `DescricaoObrigatoria__c = true` no registro `Padrao`, sem deploy.
- [x] **PA-4 — Responsável é sempre quem pede.**
  - Pergunta: o cliente pede ver o responsável; pode escolher outra pessoa?
  - Decisão: não; o resumo mostra "você" e o Flow grava `OwnerId = $User.Id` (PD-4 mantida). Pedido de tarefa para outra pessoa é recusado.
  - Evidência: a resposta pede exibir o responsável, não atribuir a terceiros; Task `Private` faria a tarefa de outro sumir para quem pediu; o Flow não tem entrada de responsável (recon §1).
  - Como mudar: entrada opcional de responsável no Flow e busca de usuário no tópico (nova versão de Flow e agente).
- [x] **PA-5 — Quatro públicos por atribuição individual do PS.**
  - Pergunta: como identificar SDR, vendedores/executivos, pós-vendas e gestão comercial?
  - Decisão: o administrador atribui `PS_Comercial_AssistenteAcoes` e a licença de Agentforce a cada usuário desses públicos; nenhum grupo automático.
  - Evidência: a org não tem perfil nem papel com esses nomes (seção 4.4, nesta sessão); os perfis comerciais e de marketing já dão criar Task e ler Lead.
  - Como mudar: se a Eplast quiser, um permission set group por público, sem mexer no Flow nem no agente.
- [x] **PA-6 — Busca nos três tipos quando o usuário não diz o tipo.**
  - Decisão: procura em lead, conta e oportunidade; candidatos de tipos diferentes são listados com o tipo e o usuário escolhe.
  - Evidência: AC-3 já exige escolha em ambiguidade; padrão mais seguro.
  - Como mudar: instrução do tópico (nova versão do agente) para priorizar um tipo.
- [x] **PA-7 — Parâmetros em custom metadata** (depende do aceite do item C, seção 9).
  - Decisão: valores iniciais da seção 4.3, editáveis em Setup.
  - Evidência: pedido do cliente (sem deploy); precedente EPLAST-46 e 27 na org.
  - Como mudar: editar o registro `Padrao`.

## 9. O que fica bloqueado (caso 3 da regra 4)

**Nada bloqueia o build por pergunta de negócio.** Há uma decisão de arquitetura para o arquiteto humano, não do cliente:

- **Item C (`AssistenteTarefaSetting__mdt`)** é um tipo novo na org. Custom metadata é configuração implantável, não dado de cliente, e não altera Task nem Lead; ainda assim, pela regra do squad, tipo novo é levado ao humano (mesmo tratamento dado ao `CampaignSuggestionSetting__mdt` na EPLAST-46). **Aprovar o gate com o item C** = build com custom metadata; **recusar o item C** = build com o fallback de 4.1 (constantes, ajuste com deploy).

## 10. Critérios para o QA testar

Dados sintéticos: `fixtures/account.apex` (conta com `TriggerUtility.bypassTrigger`), oportunidade sintética ligada a ela e `fixtures/lead.apex` (item D). Contagens por `COUNT()`. Na QA (Partial Copy), só registros criados pelo agente. Usuário de teste da conta de serviço Konecta na dev: `005bJ00000piKAaQAM` (ativo, perfil `Administrador do sistema`; há outro, inativo). Por ser administrador, **não serve para o caso de acesso negado**; perfil, permissão e papel dele não são alterados.

| # | Cenário | Esperado |
|---|---|---|
| Q-1 | Tarefa para `REG-TESTE-LEAD-01` com prazo | Resumo com registro (nome e "lead"), responsável, descrição, prazo; após aceite, +1 Task com `WhoId` = lead, `WhatId` vazio, `OwnerId` = usuário, marca de origem |
| Q-2 | Recusa do resumo (lead) | Nenhuma Task |
| Q-3 | Nome `REG-TESTE-DUP` existente como lead e como conta | Lista com tipo; nada gravado até a escolha |
| Q-4 | Lead convertido sintético | Recusa com a mensagem de PA-2; nenhuma Task |
| Q-5 | Tarefa para conta e para oportunidade (regressão da v13) | Como no QA aprovado: `WhatId` preenchido |
| Q-6 | Resumo de qualquer pedido | Sempre os quatro itens; descrição vazia aparece como "sem descrição" |
| Q-7 | Rascunho de e-mail para o lead | Task com o texto em `Description`; `EmailMessage` inalterado; aviso de revisar e de envio fora do CRM |
| Q-8 | Pedido de compromisso, conta, oportunidade ou pedido | Recusa; nada criado ou alterado |
| Q-9 | Sem prazo | Pergunta o prazo; nada gravado |
| Q-10 | Parâmetros (se item C): tirar `00Q` de `PrefixosPermitidos__c`; depois `Ativo__c = false`; depois `DescricaoObrigatoria__c = true` sem descrição | Recusa com a mensagem certa em cada caso; voltar aos valores iniciais ao fim |
| Q-11 | Assunto `Check In @` em conta | Recusa; nenhuma Task, nenhuma escrita em Account |
| Q-12 | Usuário não administrador sem o PS (se houver com licença) | Recusa sem vazar dado; se não houver usuário, declarar inconclusivo e levar ao roteiro |
| Q-13 | Regressão das outras demandas na v16 | `insights_comerciais` com as 6 ações; uma pergunta de cada (consulta de pedidos, próxima ação, resumo de reunião, sugestão de campanha) responde como na versão anterior |

Teste sem tela: `sf agent preview start` / `send` / `end`. O roteiro do cliente lista os quatro públicos e repete as premissas PA-1 a PA-7 em "O que assumimos e você precisa confirmar".

## 11. O que não será feito nesta demanda

- Compromisso (Event), conta, oportunidade, pedido, contato ou caso pelo assistente; alterar tarefa existente; tarefa para outra pessoa; várias tarefas numa confirmação; check-in.
- Envio de e-mail ou mensagem por qualquer meio do CRM; nada no Marketing Cloud ou no conector `et4ae5`.
- Perfil novo, campo novo, Apex, relatório.
- Corrigir `UpdateAccountCompanyInfo.execute` (defeito existente, sem demanda).
- Mudar `TaskCreatedOrUpdated` ou as ações das EPLAST-27, 34 e 46.

## 12. O que não foi possível confirmar

1. Se `identifyRecordByName` aceita `objectApiName = Lead` nesta org (R3): a ação não é descrita pela API REST de ações padrão e a dev não tem lead.
2. Se há Flow record-triggered de Lead ativo na org (recon §8.1; só o grep da linha de base). Não afeta o desenho, porque nada grava Lead.
3. Contexto real de execução do Flow chamado pelo agente com usuário não administrador (R4).
4. Conteúdo de `PS_PosVendas_Atendimento` e dos outros `PS_*`; quem, entre os usuários reais, pertence a cada um dos quatro públicos.
5. Se a QA tem os componentes de EPLAST-27, 34 e 46 na hora do deploy (R2); confere o `05-deploy-qa.md`.
6. Usuário de teste da conta de serviço Konecta na QA (só consultado na dev).

## 13. Estimativa

**Estimativa de esforço:** 10–18 h

| Bloco | h |
|---|---|
| Flow v2 (decisão de lead, guarda de convertido, leitura de parâmetros) | 2–4 |
| Custom metadata, registro `Padrao`, leitura no PS | 1–2 |
| v16 do agente a partir da v15 (instruções, schema, conferência das ações de 27/34/46) | 2–4 |
| Fixture de lead e verificação Q-1 a Q-13 na dev | 3–5 |
| Documentação, roteiro e entrega | 2–3 |

**O que mudou em relação à análise (14–26 h) e por quê:** cai, porque o tópico, a ação, o Flow, o PS e o acesso ao agente já existem e passaram no QA; esta rodada é ajuste. O que soma: o custom metadata pedido pelo cliente, a regressão das três outras demandas carregadas na v16 e o risco R3 (se a busca padrão não aceitar Lead, volta ao design e a faixa sobe).

---

## Gate

- [ ] **Arquiteto humano aprova** o design (pendente). Pontos para conferir: item C (custom metadata, seção 9), PA-4 (responsável sempre quem pede) e PA-5 (atribuição individual do PS aos quatro públicos).

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

---

## Decisão do responsável (2026-11-17) depois da rodada 4 de QA — diretriz para a versão 18 do assistente

A rodada 4 de QA foi a primeira a exercitar a SFAgent2 v17 de verdade (as rodadas 2 e 3 reprovaram porque a v17 não chegava à sandbox de QA; isso foi corrigido na esteira). O QA reprovou por comportamento do assistente (`05-testes-rodada-4.md`):

- **FALHA 6 (crítica, intermitente, 1 de 2):** afirma "criado" sem chamar a ação, quando o pedido vem sem data nem texto e o usuário responde só "sim, confirmo".
- **FALHA 7 (média, 4 de 4 numa redação):** monta o cartão de confirmação com o nome do registro no lugar do Id, sem chamar `IdentificarRegistro`, e a criação falha.
- **FALHA 8 (branda):** o resumo antes da confirmação não traz o registro relacionado nem o responsável.

Decisão de Leonardo Barbosa, responsável pela conta. Refazer o desenho para a **versão 18** com estas diretrizes:

1. **Identificar o registro sempre, antes de montar a confirmação.** `IdentificarRegistro` é chamada em todo pedido de criação, mesmo quando o usuário já deu o nome completo. O cartão de confirmação só é montado com o Id do registro identificado.
2. **"Criada" só com o retorno de sucesso da ação, e a trava não pode depender só do texto da instrução.** A FALHA 6 é intermitente: reforçar a redação do tópico não basta como única defesa. O arquiteto desenha uma trava determinística na própria ação ou no Flow `Task_Agente_CriarTarefa` (por exemplo: a ação recusa gravar sem Id de registro e sem os campos obrigatórios e devolve uma mensagem pronta para o assistente repetir; a frase de sucesso que o assistente usa vem do retorno da ação, com um identificador da tarefa criada, e não é redigida por ele). Se a plataforma não permitir uma trava assim, dizer isso com a evidência e propor a melhor alternativa declarativa, em vez de só reescrever a instrução.
3. **Resumo completo antes da confirmação:** registro relacionado e tipo, responsável, descrição (ou "sem descrição") e prazo aparecem antes de o usuário confirmar. Se o cartão nativo não mostrar esses itens, o assistente escreve o resumo na mensagem anterior ao cartão.
4. **Critério de aceite por repetição.** Os casos críticos do roteiro (pedido sem data nem texto seguido de "sim"; pedido com nome completo do registro em pelo menos três redações diferentes, incluindo "revisar contrato"; recusa do resumo) passam em **5 de 5 execuções** no QA, em sessões novas. Qualquer execução que afirme criação sem tarefa gravada reprova. O verificador aplica o mesmo critério na dev no que conseguir exercitar.
5. **Sem Apex**, como nas rodadas anteriores. A v18 parte da v17 e é cumulativa (mantém os tópicos das EPLAST-27, 34 e 46). A FALHA 2 (texto "sem descrição" gravado) está corrigida na v17 e não pode voltar.
6. **O que não muda:** tarefa vinculada a Lead por `WhoId`, `AssistenteTarefaSetting__mdt`, rascunho de e-mail como tarefa sem envio pelo CRM, permission set `PS_Comercial_AssistenteAcoes`. O teste com usuário sem permissão (AC-4) continua para a homologação com usuário comum, porque a sandbox de QA só tem administradores.
