# EPLAST-29 · Design (rodada 5, versão 18 do assistente) — Ações por linguagem natural no assistente de IA

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** design · **Autor:** arquiteto (proposta para o aceite do arquiteto humano)
**Org conectada nesta sessão:** `sbx-eplast-dev` (sandbox, Org ID 00DHa000006vfMLMAY, única org em `sf org list`; é a `eplast--qa` da Eplast, dev da esteira pela regra 5). Produção e QA não foram tocadas. Só metadata e contagens; nenhum registro lido, nenhum DML, deploy ou anonymous Apex.
**Entradas:** `01-analise.md` (aprovada em `gates.md`), `02-recon.md` (refeito em 17/11 para a v18), `00-preflight.md`, `comentarios-do-card.md`, `05-testes-rodada-4.md` (FALHAS 6, 7 e 8), decisão do responsável de 17/11 (seção 13, reproduzida), metadata da v17 e do Flow no repositório da branch.
**Histórico consultado:** desenho da rodada 4 (este arquivo, versão aprovada em 17/11 16:42, no git), decisão de 16/11 (versões acumuladas do `SFAgent2`), `EPLAST-46/03-design.md` (precedente do custom metadata). O RAG não trouxe precedente de trava determinística em agente nesta conta.

---

## 1. Contexto e escopo desta rodada

O que existe e passou no QA: tópico `acoes_comerciais_EPLAST29` no `SFAgent2`, ações `IdentificarRegistro` (`identifyRecordByName`) e `CriarTarefa` (Flow `Task_Agente_CriarTarefa`, com `isConfirmationRequired = true`), Task ligada a lead (`WhoId`), conta ou oportunidade (`WhatId`), custom metadata `AssistenteTarefaSetting__mdt`, PS `PS_Comercial_AssistenteAcoes`. A gravação está correta em todos os casos da rodada 4 (A1, A6, B2); **nenhuma Task errada foi gravada**.

O que reprovou (rodada 4, v17 ativa na QA) é **conversa**, não gravação:

| Falha | O que aconteceu | Por que a v17 não segura |
|---|---|---|
| FALHA 6 (crítica, 1 de 2) | Pedido sem data nem texto; usuário responde "sim, confirmo"; o assistente diz "criado" sem chamar ação | A única defesa é a instrução 5 do tópico (texto). Nada no planner impede o modelo de redigir "criado" |
| FALHA 7 (média, 4 de 4 numa redação) | "revisar contrato para o lead ..." monta o cartão com o **nome** em `RegistroRelacionadoId`, sem `IdentificarRegistro`; o Flow recusa depois do "sim" | A instrução 1 permite pular a busca; o Flow só valida depois do aceite |
| FALHA 8 (branda) | Resumo antes do cartão sem registro e responsável | O resumo é redigido pelo modelo (instrução 4); o cartão nativo mostra só os parâmetros |

**Escopo:** só as diretrizes 1 a 4 do responsável (seção 13). Tudo o mais é reaproveitado sem mudança de comportamento.

## 2. Decisão: declarativo, sem Apex, com a validação e o texto saindo do Flow

**Princípio:** o que hoje o modelo **redige** (resumo, frase de sucesso, diagnóstico do que falta) passa a ser **calculado por Flow** e devolvido pela ação; o modelo só repete. O que hoje o modelo **decide sozinho** (se o registro está identificado, se falta dado) passa a ser respondido por uma ação determinística, chamada antes do cartão.

### 2.1 Alternativas avaliadas

| # | Alternativa | Avaliação |
|---|---|---|
| A | Só reescrever instruções do tópico | **Rejeitada** pela diretriz 2 do responsável: a FALHA 6 é intermitente e voltou depois de duas rodadas de reforço de texto (FALHA 1 da rodada 1) |
| B | Só mudar o Flow `CriarTarefa`: mensagem de sucesso pronta, com o código da tarefa | Necessária, mas insuficiente: o Flow só roda depois do cartão e do aceite, então não corrige FALHA 7 nem FALHA 8, e não dá ao modelo nada a repetir quando falta dado (FALHA 6) |
| **C** | **B + ação nova `PrepararTarefa` (Flow sem gravação) chamada antes do cartão, que valida tudo, lê o nome e o tipo do registro e devolve o resumo pronto ou o que falta; o `CriarTarefa` reusa a mesma validação como subflow** | **Escolhida.** Cobre as três falhas com lógica determinística, sem Apex, dentro do tópico existente (regra 3: estende o tópico com uma ação, não cria agente nem tópico) |
| D | Variáveis customizadas do agente + filtro de disponibilidade de ação ("`CriarTarefa` só disponível depois de `PrepararTarefa` com sucesso") | Seria a trava mais forte na plataforma, mas **não confirmada nesta org**: o planner da v17 não usa variável customizada, filtro nem mapeamento de saída (grep sem ocorrência no bundle) e não verifiquei o formato de metadata. Fica como **próximo degrau** se C não passar no 5 de 5 (seção 9), por decisão do arquiteto humano, não improvisada no build |
| E | Reescrever o agente em Agent Script (raciocínio determinístico) | O bundle tem `agentScript/SFAgent2_v17_definition.agent`, mas **vazio**; o planner é `Atlas__ConcurrentMultiAgentOrchestration`. Migrar o modelo de autoria do agente inteiro afetaria EPLAST-27, 34 e 46. Fora desta demanda; registrado como recomendação |
| F | Apex (ação invocável) | Vetado pela diretriz 5. E não acrescenta nada: o problema é o texto do modelo, não a lógica da ação, que Flow resolve |

### 2.2 Limite honesto da plataforma (diretriz 2)

**Evidência:** no planner atual (`Atlas__ConcurrentMultiAgentOrchestration`, sem Agent Script e sem filtros de ação, seção 2.1-D/E) não existe configuração que impeça o modelo de escrever a palavra "criada" sem ter chamado uma ação. O que a plataforma garante de forma determinística é: (1) nada é gravado sem o cartão de confirmação aceito (`isConfirmationRequired`); (2) o Flow só grava com Id válido e campos obrigatórios; (3) a saída marcada `isDisplayable` é entregue ao usuário como resultado da ação.

A alternativa C transforma isso em trava verificável:
- **Gravação:** impossível sem Id identificado, prazo e assunto (já era; mantido e centralizado no subflow).
- **Resumo e sucesso:** o texto vem do Flow. Toda criação real termina com a linha `Código da tarefa: 00T...`; uma afirmação de criação sem esse código **não veio da ação**, e o usuário e o QA conseguem ver isso. O roteiro do cliente ensina a conferir.
- **Falta de dado:** toda resposta do usuário neste tópico (inclusive "sim") passa por `PrepararTarefa`, que responde de forma fixa "ainda falta o prazo; nada foi criado". O modelo recebe uma frase pronta para repetir, em vez de improvisar, que é a situação que gerou a FALHA 6.

O risco residual (o modelo ignorar a regra e redigir "criado" sem chamar ação) não chega a zero nesta arquitetura. Ele é medido pelo critério 5 de 5 (seção 10); se falhar, o próximo degrau é a alternativa D, levada ao arquiteto humano.

### 2.3 Por que não o nível acima e não código

- **Configuração pura** não basta: a ação padrão `createTask` não recebe registro relacionado e o resumo do cartão nativo não é configurável (desenho de 15/11, seção 2.1; recon §1).
- **Flow** resolve tudo: validações por fórmula e decisão, Get Records de um registro por Id, montagem de texto, uma gravação. Nenhum gatilho da doutrina para Apex (sem callout, sem volume, sem lógica que Flow não expresse). Sem Apex, o achado #2 do assessment (cobertura 10%) não piora.

## 3. Reaproveita vs. cria (item a item)

### 3.1 Reaproveita sem alterar

| Componente | Confirmado | Uso |
|---|---|---|
| Agente `SFAgent2` | recon §1; `BotVersion` v13 `Active`, v14 a v17 `Inactive` (nesta sessão) | Recebe a v18. Continua o único agente |
| Tópicos `insights_comerciais` (3 ações originais + `ProximaAcaoCliente_EPLAST27`, `ResumoReuniao_EPLAST34`, `SugestaoCampanha_EPLAST46` e as instruções `instruction2_EPLAST27`, `instruction1_EPLAST34`, `instruction1_EPLAST46`), `agent_router`, `ambiguous_question`, `off_topic` | recon §1 e §7; bundle v17 | Copiados para a v18 **sem mudança de conteúdo**, só com sufixo `_v18` |
| Ação `IdentificarRegistro` (`identifyRecordByName`, `isConfirmationRequired = false`) | bundle v17 | Mesma ação, sufixo `_v18`. Passa a ser chamada sempre (diretriz 1) |
| `AssistenteTarefaSetting__mdt`, registro `Padrao` (`Ativo__c`, `PrefixosPermitidos__c`, `PrioridadePadrao__c`, `DescricaoObrigatoria__c`, `MarcaOrigem__c`) | recon §1 (1 registro) | Lido pelo subflow novo. Sem campo novo |
| PS `PS_Comercial_AssistenteAcoes` (agente, Flow `Task_Agente_CriarTarefa`, leitura do custom metadata; 0 atribuições) | recon §1 e §6; arquivo do PS na branch | Recebe só acesso ao Flow novo (3.2) |
| Campos padrão de Task (`Subject`, `ActivityDate`, `WhatId`, `WhoId`, `OwnerId`, `Description`, `Priority`, `Status`, `TaskSubtype`) | recon §2 | Únicos campos gravados. Nenhum campo novo |
| Flow `TaskCreatedOrUpdated` | recon §3 | Não alterado |
| Fixtures `fixtures/lead.apex` e `fixtures/account.apex` | usadas na rodada 4 | Mesmos dados sintéticos `REG-TESTE` |

### 3.2 Cria

| Id | Tipo | API name | O que é |
|---|---|---|---|
| A | Flow novo (autolaunched, **sem DML**) | `Task_Agente_PrepararTarefa` (nome livre na dev: só `Task_Agente_CriarTarefa` existe com o prefixo `Task_Agente`, conferido nesta sessão) | Validação única e texto do resumo (seção 4.1). Usado como ação do agente e como subflow do `CriarTarefa` |
| B | Versão nova de Flow | `Task_Agente_CriarTarefa`, **próxima versão** (na dev será a v3: hoje v1 `Active`, v2 `Obsolete`, conferido nesta sessão; na QA será a seguinte à v5 ativa) | Chama o subflow A antes de gravar; mensagem de sucesso com código (seção 4.2) |
| C | GenAiPlannerBundle + BotVersion | `SFAgent2_v18` + `bots/SFAgent2/v18.botVersion-meta.xml`, inativa ao nascer, ligada ao planner (nome livre: `SFAgent2_v18` não existe na dev, conferido) | Cópia da v17 com sufixo `_v18`; muda só o tópico `acoes_comerciais_EPLAST29_v18` (seção 4.3) |
| D | Ação local nova no tópico existente | `PrepararTarefa_EPLAST29_v18` (alvo `Task_Agente_PrepararTarefa`, `isConfirmationRequired = false`; nenhuma função `PrepararTarefa%` na dev, conferido) | Única ação nova. Fica no tópico `acoes_comerciais` (regra 3) |
| E | Alteração de PS | `PS_Comercial_AssistenteAcoes`: `flowAccesses` de `Task_Agente_PrepararTarefa` | Sem objeto, campo nem perfil |

### 3.3 Não cria

Agente, tópico, campo, objeto, custom metadata novo, trigger, Apex, permission set novo, perfil, relatório.

## 4. Componentes (versão nova sempre; ativação é passo separado)

### 4.1 Flow novo `Task_Agente_PrepararTarefa`

`AutoLaunchedFlow`, `runInMode = DefaultMode` (como o `CriarTarefa`), descrição em pt-BR em todos os elementos e variáveis (assessment #4). **Nenhum elemento de gravação.**

**Entradas** (todas opcionais no Flow, para ele poder dizer o que falta): `Assunto`, `DataVencimento` (Date), `RegistroRelacionadoId`, `Descricao`, `Prioridade`.

**Saídas:**

| Saída | Tipo | `isDisplayable` | Conteúdo |
|---|---|---|---|
| `Pronto` | Boolean | não | Verdadeiro só se tudo estiver válido |
| `Resumo` | Texto | **sim** | Quando `Pronto`: texto fixo montado pelo Flow (abaixo) |
| `Mensagem` | Texto | **sim** | Quando não `Pronto`: o que falta ou o motivo da recusa, em frase pronta, terminando sempre com "Nada foi criado." |
| `RegistroNome`, `RegistroTipo` | Texto | não | Para o agente usar na conversa |

**Ordem das validações** (a mesma lógica que hoje está no `CriarTarefa` v2, movida para cá; mensagens mantidas, com a frase final acrescentada):
1. Lê `AssistenteTarefaSetting__mdt` `Padrao`; sem registro ou `Ativo__c = false` → "A criação de tarefas pelo assistente está desligada. Nada foi criado."
2. `RegistroRelacionadoId` vazio, com tamanho diferente de 15/18 ou com prefixo fora de `PrefixosPermitidos__c` → **"Registro ainda não identificado. Use IdentificarRegistro com o nome informado e chame PrepararTarefa de novo com o Id encontrado. Nada foi criado."** (é o que corrige a FALHA 7 antes do cartão; o texto é dirigido ao agente e também é legível pelo usuário).
3. Get Records do registro pelo Id (Lead: `Name`, `IsConverted`; Account: `Name`; Opportunity: `Name`). Não achado → "Registro não encontrado ou sem acesso. Nada foi criado." (sem nome, AC-4). Lead convertido → mensagem de PA-2.
4. Assunto vazio → "Falta o assunto da tarefa. Nada foi criado." Assunto começando com `Check In @` → recusa atual.
5. Data vazia → **"Falta o prazo (data de vencimento). Nada foi criado."** (FALHA 6).
6. `DescricaoObrigatoria__c = true` e descrição vazia → pede a descrição. Descrição com só "sem descrição", "nenhuma" ou parecido é tratada como vazia (proteção determinística contra a volta da FALHA 2).
7. Tudo válido → `Pronto = true` e `Resumo`:

```
Confira antes de confirmar:
- Assunto: <Assunto>
- Registro relacionado: <Nome> (<lead | cliente | oportunidade>)
- Responsável: você
- Descrição: <texto> | sem descrição
- Prazo: <dd/mm/aaaa>
Nada foi criado ainda. A tarefa só é gravada depois que você aprovar a confirmação.
```

### 4.2 `Task_Agente_CriarTarefa`, versão nova

Criada a partir da v2 da branch (a versão com lead, parâmetros e guardas; na dev a v1 está ativa e a v2 obsoleta, recon §8.2). Entradas e saídas iguais às da v2 (a ação continua com o mesmo contrato).

1. **Primeiro passo: subflow `Task_Agente_PrepararTarefa`** com as mesmas entradas. `Pronto = false` → `Sucesso = false`, `Mensagem` = a do subflow; **nenhuma gravação**. Assim a validação é uma só nos dois caminhos e não diverge.
2. `Pronto = true` → grava a Task como na v2: lead em `WhoId` com `WhatId` vazio; conta e oportunidade em `WhatId`; `OwnerId = $User.Id`; `Status = Open`; `TaskSubtype = Task`; prioridade e marca de origem do custom metadata; 1 DML; fault path com mensagem amigável e nada gravado.
3. **Mensagem de sucesso montada pelo Flow** (substitui o fixo "Tarefa criada com sucesso."):

```
Tarefa criada: "<Assunto>" para <Nome> (<tipo>), prazo <dd/mm/aaaa>, responsável: você.
Código da tarefa: <TarefaId>
```

   Para rascunho (assunto começando com `Rascunho de e-mail -` ou `Rascunho de mensagem -`), o Flow acrescenta: "Revise o texto antes de enviar. Nada foi enviado pelo CRM."
4. Falha → `Mensagem` termina com "Nada foi criado."

A versão ativa não é editada. Rollback: reativar a versão anterior do Flow.

### 4.3 `SFAgent2` v18 a partir da v17

- **Base:** v17 (a mais nova na dev, inativa; v13 ativa; recon §1, reconfirmado nesta sessão). Regra das versões acumuladas (16/11): se outra demanda criar a v18 antes do build, esta vira a seguinte e o build registra a base.
- **Nada de EPLAST-27, 34 e 46 muda.** O build confere por grep que `insights_comerciais_..._v18` mantém as 6 ações e as 3 instruções delas, iguais às da v17 salvo o sufixo.
- **Tópico `acoes_comerciais_EPLAST29_v18`** (só aqui há mudança):
  1. **Sequência obrigatória**, escrita como passos numerados: (a) identificar o registro com `IdentificarRegistro` **sempre**, mesmo com o nome completo; única exceção: na página de um lead, conta ou oportunidade, o `currentRecordId` é o registro (o `PrepararTarefa` confere o Id de qualquer forma); (b) chamar `PrepararTarefa` com o Id; (c) se `Pronto` for falso, repetir a `Mensagem` e parar; (d) se `Pronto` for verdadeiro, repetir o `Resumo` e, na mesma resposta, chamar `CriarTarefa` com os mesmos valores (o cartão nativo é a confirmação); (e) depois do retorno, repetir a `Mensagem` da ação.
  2. **Toda resposta do usuário neste tópico, inclusive "sim", "confirmo" ou "pode criar", recomeça em (b)** com os dados que já existem na conversa. "Sim" não é confirmação: a confirmação é só o cartão.
  3. **Frase de criação:** o assistente nunca escreve que criou, salvou ou cadastrou; ele só repete a `Mensagem` do `CriarTarefa`. Uma mensagem de criação sem `Código da tarefa` é proibida.
  4. Palavras do assunto (contrato, pedido, proposta, reunião) não indicam o tipo do registro; o tipo vem só de "lead", "cliente/conta" ou "oportunidade" (hipótese para a FALHA 7 com "revisar contrato": o modelo pode ter lido "contrato" como objeto).
  5. Mantidos da v17: ambiguidade lista candidatos com tipo e Id e não chama ação (AC-3); datas relativas convertidas; rascunho de e-mail ou mensagem só como tarefa; descrição vazia vai vazia no parâmetro; recusas do "não disponível" (inclusive tarefa para outra pessoa, achado A11).
- **Ação `CriarTarefa_EPLAST29_v18`:** mesma entrada da v17; saída `Mensagem` com `isDisplayable = true` (já é) e descrição "Repita este texto ao usuário sem alterar". `isConfirmationRequired = true` mantido.
- **Ação `PrepararTarefa_EPLAST29_v18`:** entradas iguais às de `CriarTarefa` (todas opcionais); saídas da seção 4.1.
- **Pacote da branch:** só `SFAgent2_v18` e `v18.botVersion-meta.xml` do agente (v17 e anteriores ficam fora: já estão nas orgs e versão ativa não aceita reimplante), o Flow novo, a versão nova do `CriarTarefa` e o PS.

### 4.4 Ativação (passo separado)

| Org | Ordem | Rollback |
|---|---|---|
| dev (verificação) | 1. Flow `Task_Agente_PrepararTarefa` ativo; 2. versão nova do `CriarTarefa`; 3. `sf agent activate` da v18 | reativar a v1 do Flow e a v13 do agente |
| QA (esteira, `05-deploy-qa.md`) | mesma ordem; a v18 substitui a v17 ativa | reativar a versão anterior do Flow (v5) e a v17 |

Ativar o Flow antes da v18 é seguro: a v17 já ativa chama `CriarTarefa` com o mesmo contrato e passa a ganhar a validação e a mensagem novas. **Recomendação ao gate:** ativar na dev para que o verificador rode o 5 de 5 lá; nas rodadas anteriores a verificação ficou inconclusiva porque nada estava ativo na dev.

### 4.5 Permissões

- `PS_Comercial_AssistenteAcoes` ganha `flowAccesses` de `Task_Agente_PrepararTarefa` (o agente chama o Flow diretamente na ação D). Nenhum perfil alterado (assessment #7/#8); nenhum PS novo.
- Os quatro públicos (SDR, vendedores/executivos, pós-vendas, gestão comercial) recebem o PS e a licença de Agentforce por usuário (PA-5). Criar Task e ler lead, conta ou oportunidade continuam vindo do perfil de cada um; `DefaultMode` respeita o acesso do usuário.
- Task `Private`: a tarefa é do usuário que pediu.

## 5. Convivência com EPLAST-27, 34 e 46 (preflight)

As três estão em `aguardando_homologacao` e mexem no `SFAgent2`. Na v17 ativa na QA estão as ações e instruções delas (recon §7).

- A v18 **copia sem alterar** tudo o que elas entregaram; muda só o tópico desta demanda e acrescenta uma ação nele.
- Ao ativar a v18 na QA, a homologação delas segue com o mesmo conteúdo. O QA repete uma pergunta de cada (próxima ação, resumo de reunião, sugestão de campanha, consulta de pedidos) antes de liberar (Q-13).
- Se uma delas voltar ao build, a versão nova dela parte da mais nova da dev (v18 ou seguinte) e mantém o que esta entrega; se ela criar versão antes do build desta, esta parte da dela.
- Dependências na QA: `Account_Agente_ProximaAcao`, `MeetingSummaryService`, `Account_Agente_SugestaoCampanha` já estão lá (a v17 foi implantada e ativada na rodada 4). O `05-deploy-qa.md` confere de novo.

## 6. Ordem de execução e riscos do assessment

**Objeto gravado: só Task.** O `PrepararTarefa` não grava nada.

| Evento | O que roda | Efeito |
|---|---|---|
| `PrepararTarefa` | Get Records em Lead, Account ou Opportunity e no custom metadata | Nenhuma gravação, nenhuma automação disparada |
| Insert de Task | Sem trigger e sem validation rule em Task (recon §3). Só `TaskCreatedOrUpdated` (after-save), que age com `WhatId` `001` **e** assunto `Check In @` | Assunto `Check In @` é recusado no subflow, então o ramo que grava `Account.AccountHasCheckInTask__c` não é acionado. Ordem determinística (um componente) |
| Lead, Account, Opportunity, Order | `AccountBefore` (SBQQ), `AccountTrigger` (custom, Protheus), triggers SBQQ e Flows after-save | **Não acionados**: nada grava nesses objetos. A `AccountTrigger` (um job por conta) não roda; nenhuma gravação em massa em Account. Contas de teste pela fixture com `TriggerUtility.bypassTrigger` |

**Defeito existente, fora desta demanda:** `UpdateAccountCompanyInfo.execute` grava a conta e chama `SendAccountToProtheus.execute` na mesma transação. Não é tocado; não interfere, porque nada aqui grava Account.

**Governador:** `PrepararTarefa` como ação: até 1 SOQL (registro; custom metadata não conta). `CriarTarefa`: até 1 SOQL no subflow + 1 DML. Cada chamada é uma transação disparada por uma mensagem do usuário; volume em massa não se aplica. **CPU com pai de muitos filhos (SOMOSAGILITY-10):** não se aplica; nenhuma automação recalcula o registro pai por Task.

| Achado do assessment | Tratamento |
|---|---|
| #1 Automação concorrente em Account, Opportunity e Order | Não grava nesses objetos; ramo indireto (check-in) fechado no subflow |
| #2 Cobertura Apex 10% | Sem Apex |
| #3 Validation rules de Order / #10 `OrderTrigger` homônimo | Não se aplica (Order fora) |
| #4 Campos e elementos sem descrição | Flow novo, variáveis e schemas saem com descrição |
| #6 dev × QA | Resolvido pela regra 5 da conta |
| #7/#8 Perfis comerciais duplicados | Nenhum perfil alterado; acesso por PS |

## 7. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **O modelo ainda redige "criado" sem chamar ação** (limite da seção 2.2) | Alta | Texto de sucesso só do Flow, com código; "sim" passa por `PrepararTarefa`; critério 5 de 5. Se falhar, gate com a alternativa D, não novo reforço de texto |
| R2 | **Outras demandas no mesmo agente** (27, 34, 46) | Alta | Cópia sem alteração; grep das 6 ações; regressão Q-13 |
| R3 | `isDisplayable = true` pode não garantir exibição literal do texto (o modelo pode reescrever) | Média | Não confirmado na documentação nem na org. O QA confere o texto na pré-visualização e na tela; a linha do código é o que importa |
| R4 | Uma chamada a mais por pedido (`PrepararTarefa`) aumenta latência e a chance de o modelo pular passos | Média | Sequência numerada; o próprio `CriarTarefa` refaz a validação pelo subflow, então pular `PrepararTarefa` nunca grava errado, só perde o resumo (FALHA 8 volta só nesse caso; o QA mede) |
| R5 | Ativação em várias peças (Flow novo, versão do Flow, v18) | Baixa | Ordem da seção 4.4; nenhuma ordem deixa estado quebrado |
| R6 | Usuário sem permissão (AC-4) não testável: dev e QA só têm administradores da conta de serviço | Média | Fica para a homologação com usuário comum, com e sem o PS (diretriz 6) |

## 8. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca lead e comunicação (rascunho). **Não envia nada e não cria público** para o Marketing Cloud.

- **Dados que o MC lê e onde ficam:** nada novo. Tarefa de lead em `Task` com `WhoId` = lead; rascunho em `Task.Description`, assunto `Rascunho de e-mail - ...` ou `Rascunho de mensagem - ...`. É anotação de trabalho do vendedor, não fonte de jornada.
- **Público identificável no CRM:** não se aplica. Se a Eplast quiser transformar rascunho em comunicação de marketing, o caminho do CRM é `Campaign` e `CampaignMember` (0 registros na dev, recon §4), em demanda própria.
- **O que o MC devolve e onde é gravado:** nada desta demanda; os objetos do conector `et4ae5` não são alterados.
- **Consentimento e opt-out:** Lead tem `HasOptedOutOfEmail` e `et4ae5__HasOptedOutOfMobile__c` (recon §4 e desenho de 15/11). O assistente não envia, então não consulta nem grava consentimento; quem envia aplica o opt-out.
- **Para quem opera o MC:** nada a fazer por causa deste build.

Nada é feito no Marketing Cloud nem no conector.

## 9. Premissas assumidas (validar na homologação)

Premissas confirmadas pela resposta do cliente de 17/11 deixam de ser premissa (só tarefa, com lead; rascunho sem envio; confirmação obrigatória; os quatro públicos; parâmetros sem deploy, já atendido pelo custom metadata aprovado em 17/11). Seguem PA-1 a PA-6 da rodada 4 e entram PA-8 a PA-11.

- [x] **PA-1 — Lead em `WhoId`, sem `WhatId`.** Evidência: describe de Task (recon §2). Como mudar: n/a; na conversão a plataforma leva as atividades.
- [x] **PA-2 — Lead convertido é recusado** com orientação de pedir na conta ou oportunidade. Evidência: padrão da plataforma. Como mudar: retirar a guarda no subflow.
- [x] **PA-3 — Descrição mostrada sempre, não obrigatória.** Como mudar: `DescricaoObrigatoria__c = true`, sem deploy.
- [x] **PA-4 — Responsável é sempre quem pede**; o resumo mostra "você" e o pedido para outra pessoa é recusado. Evidência: Flow sem entrada de responsável; Task `Private`. Como mudar: entrada de responsável em versão nova do Flow e do agente.
- [x] **PA-5 — Quatro públicos por atribuição individual do PS e da licença.** Evidência: a org não tem perfil nem papel com esses nomes (rodada 4). Como mudar: um permission set group por público.
- [x] **PA-6 — Sem tipo informado, busca em lead, conta e oportunidade** e lista com tipo. Como mudar: instrução do tópico.
- [x] **PA-8 — O resumo e a frase de sucesso têm texto fixo**, gerado pelo Flow (seções 4.1 e 4.2).
  - Pergunta: o cliente aceita um texto padronizado, sempre igual, em vez de uma frase "natural" do assistente?
  - Decisão: sim; é a forma de garantir os quatro itens (diretriz 3) e de não depender da redação do modelo (diretriz 2).
  - Evidência: decisão do responsável de 17/11; FALHA 8 repetida com resumo redigido pelo modelo.
  - Como mudar: o texto fica em elementos de texto do Flow; mudar exige versão nova do Flow (sem mexer no agente).
- [x] **PA-9 — O comprovante de criação é o código da tarefa (Id `00T...`)** na última linha.
  - Pergunta: o usuário precisa de um comprovante de que a tarefa existe?
  - Decisão: mostrar o código; sem código, não houve criação.
  - Evidência: diretriz 2 ("frase de sucesso com um identificador da tarefa criada").
  - Como mudar: trocar por link para o registro numa versão nova do Flow.
- [x] **PA-10 — "Sim" sem os dados completos não é confirmação**: o assistente volta a dizer o que falta e que nada foi criado.
  - Evidência: FALHA 6; padrão da plataforma (a confirmação é o cartão da ação).
  - Como mudar: n/a (é a regra de segurança da demanda).
- [x] **PA-11 — Na página de um lead, conta ou oportunidade, o registro da página conta como identificado** (sem nova busca por nome).
  - Pergunta: a diretriz 1 manda chamar `IdentificarRegistro` sempre; vale também na página do registro?
  - Decisão: na página, o Id já é o do registro e o `PrepararTarefa` lê nome e tipo dele; buscar por nome só abriria ambiguidade.
  - Evidência: comportamento da v13 a v17 (instrução 1) sem falha nesse caminho; o subflow valida o Id de qualquer forma.
  - Como mudar: instrução do tópico, numa versão nova do agente.

## 10. Critérios para verificação e QA

Dados: `fixtures/lead.apex` e `fixtures/account.apex` (`TriggerUtility.bypassTrigger`), oportunidade sintética; contagens por `COUNT()` em Task por `WhoId`/`WhatId`. Na QA (Partial Copy) só registros criados pelo agente. Conversa por `sf agent preview start/send/end`, **cada execução numa sessão nova**.

**Usuário de teste:** conta de serviço da Konecta. Na dev há `005bJ00000piKAaQAM` (ativo, Administrador do sistema) e `005bJ00000hBJmYQAW` (inativo); na QA, os mesmos Ids (rodada 4). **Usa-se `005bJ00000piKAaQAM`** como dono dos registros de teste e executor. Nenhum dos dois serve para o caso de acesso negado (são administradores); perfil, permissão e papel não são alterados.

**Critério por repetição (diretriz 4):** os casos marcados com * passam em **5 de 5** execuções. **Qualquer execução que afirme criação sem Task gravada reprova**, e qualquer afirmação de criação sem a linha `Código da tarefa` também. O verificador aplica o mesmo critério na dev no que conseguir exercitar.

| # | Cenário | Esperado |
|---|---|---|
| Q-1* | Pedido sem data nem texto ("enviar e-mail de proposta para o lead REG-TESTE-LEAD-01"), depois "sim, confirmo" | Diz que falta o prazo e que nada foi criado; Task do lead inalterada |
| Q-2* | Nome completo do registro em 3 redações, incluindo "criar tarefa de revisar contrato para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-05", "lembrete para ligar para o lead REG-TESTE-LEAD-01 dia 2026-12-10" e "follow-up com o lead REG-TESTE-LEAD-01 em 2026-12-12" | Em todas: `IdentificarRegistro` e `PrepararTarefa` chamadas antes do cartão; cartão com Id `00Q`; após aceite, +1 Task e mensagem com código |
| Q-3* | Recusa do resumo ("não, cancela") | Nenhuma Task |
| Q-4 | Resumo antes do cartão (qualquer caso válido) | Os cinco itens do texto fixo: assunto, registro e tipo, "você", descrição ou "sem descrição", prazo |
| Q-5 | Ambiguidade `REG-TESTE-DUP` | Lista com tipo e Id; nada gravado |
| Q-6 | Lead convertido | Recusa (busca ou PA-2); nada gravado |
| Q-7 | Conta e oportunidade (regressão) | `WhatId` preenchido, mensagem com código |
| Q-8 | Rascunho de e-mail com data e texto | Task com o texto; `EmailMessage` inalterado; aviso de revisar e de que nada foi enviado |
| Q-9 | Descrição "sem descrição" | `Description` só com a marca de origem (FALHA 2 não volta) |
| Q-10 | `Check In @` em conta; compromisso/oportunidade/pedido; tarefa para outra pessoa | Recusa; nada gravado |
| Q-11 | Parâmetros (dev): `Ativo__c = false`; tirar `00Q`; descrição obrigatória | Mensagem certa; voltar aos valores iniciais |
| Q-12 | AC-4 usuário comum sem PS | Inconclusivo na dev e na QA (só administradores); vai ao roteiro de homologação |
| Q-13 | Regressão de 27, 34, 46 e consulta de pedidos na v18 | Respondem como na v17 (incluir resumo de reunião, não exercitado na rodada 4) |

O roteiro do cliente lista os quatro públicos, ensina a conferir o código da tarefa e repete PA-1 a PA-11 em "O que assumimos e você precisa confirmar".

## 11. O que não será feito nesta demanda

- Compromisso, conta, oportunidade, pedido, contato ou caso pelo assistente; alterar tarefa; tarefa para outra pessoa; várias tarefas numa confirmação; check-in.
- Envio de e-mail ou mensagem pelo CRM; nada no Marketing Cloud ou no conector `et4ae5`.
- Apex, campo novo, perfil novo, relatório.
- Variáveis e filtros de ação (alternativa D) e migração para Agent Script (alternativa E): só se o arquiteto humano decidir, em rodada ou demanda própria.
- Corrigir `UpdateAccountCompanyInfo.execute`; mudar `TaskCreatedOrUpdated`; mudar as ações de EPLAST-27, 34 e 46.

## 12. O que não foi possível confirmar

1. Se `isDisplayable = true` exibe o texto literal ou se o modelo pode reescrevê-lo (R3).
2. Formato de metadata e disponibilidade de variáveis customizadas e filtros de ação neste planner (alternativa D).
3. Por que, na dev, a v2 do `CriarTarefa` está `Obsolete` e a v1 `Active` (recon §8.2); a versão nova parte da v2 da branch de qualquer forma.
4. Se a ação de Flow do agente exige `flowAccesses` também para o subflow chamado dentro do `CriarTarefa`; o PS recebe o Flow novo de qualquer forma, o que cobre os dois casos.
5. Usuário não administrador com licença para AC-4 (R6).
6. Flow record-triggered de Lead ativo na org (recon §8.1); não afeta, nada grava Lead.

## 13. Decisão do responsável (2026-11-17) depois da rodada 4 de QA

Reproduzida da rodada anterior deste arquivo; é a entrada desta rodada. A rodada 4 exercitou a v17 de verdade e reprovou pelas FALHAS 6, 7 e 8 (`05-testes-rodada-4.md`). Decisão de Leonardo Barbosa, responsável pela conta:

1. Identificar o registro sempre, antes de montar a confirmação; o cartão só com o Id identificado. → seção 4.3, item 1; seção 4.1, validação 2.
2. "Criada" só com o retorno de sucesso da ação, com trava na ação ou no Flow, não só na instrução; se a plataforma não permitir, dizer com evidência e propor a melhor alternativa declarativa. → seções 2.1 e 2.2, 4.1, 4.2.
3. Resumo completo antes da confirmação (registro e tipo, responsável, descrição ou "sem descrição", prazo). → seção 4.1, `Resumo`.
4. Casos críticos em 5 de 5 execuções no QA, em sessões novas; afirmar criação sem tarefa reprova; o verificador aplica o mesmo na dev. → seção 10.
5. Sem Apex; v18 a partir da v17, cumulativa; a FALHA 2 não volta. → seções 2, 4.3, Q-9.
6. Não muda: lead por `WhoId`, `AssistenteTarefaSetting__mdt`, rascunho sem envio, `PS_Comercial_AssistenteAcoes`; AC-4 na homologação com usuário comum. → seções 3.1, 4.5, Q-12.

## 14. Estimativa

**Estimativa de esforço:** 10–16 h

| Bloco | h |
|---|---|
| Flow `Task_Agente_PrepararTarefa` (validações movidas da v2, leitura do registro, texto do resumo) | 3–4 |
| Versão nova do `CriarTarefa` (subflow, mensagem com código) e PS | 1–2 |
| v18 do agente (cópia da v17, ação nova, instruções, conferência das ações de 27/34/46) | 2–3 |
| Verificação na dev com 5 de 5 nos casos críticos | 3–5 |
| Documentação e roteiro | 1–2 |

**O que mudou em relação à rodada 4 (10–18 h) e à análise (14–26 h):** faixa parecida, teto menor. Sai o custom metadata e o ramo de lead (já existem); entram o Flow de preparação, a ação nova e o custo de repetir os casos críticos 5 vezes. Se o 5 de 5 falhar e o arquiteto humano escolher a alternativa D, a faixa sobe e é reestimada nesse gate.

---

## Gate

- [ ] **Arquiteto humano aprova** o design (pendente). Pontos para conferir: alternativa C e o limite da seção 2.2 (risco residual R1), a ação nova `PrepararTarefa` no tópico existente, texto fixo do resumo e do sucesso (PA-8, PA-9), e a recomendação de ativar as versões novas na dev para a verificação (seção 4.4).
- **Bloqueio por pergunta de negócio (caso 3 da regra 4):** nenhum.

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

---

## Aceite do gate de design (2026-11-17, rodada 5) — por Leonardo Barbosa (via Claude)

Aprovado dentro da diretriz do responsável de 17/11 (seção 13), que delegou o aceite do desenho da versão 18 quando ele seguisse a diretriz. O aceite cobre os pontos listados no gate:

- **Alternativa C**, com o limite declarado na seção 2.2: o risco de o modelo afirmar criação sem chamar a ação não chega a zero e é medido pelo critério 5 de 5. Se falhar no QA, o próximo passo é levar a alternativa D ao responsável, não reforçar texto de instrução.
- **Ação nova `PrepararTarefa`** (Flow `Task_Agente_PrepararTarefa`, sem gravação) no tópico existente, e texto fixo do resumo e do sucesso vindo do Flow, com a linha `Código da tarefa`.
- **Ativação na dev para a verificação (seção 4.4):** aceita. O verificador ativa as versões novas na `sbx-eplast-dev`, na ordem da seção 4.4, roda o 5 de 5 e registra o estado de antes e de depois. Vale só para a dev; na QA quem ativa é o QA, como já é regra.
- Sem Apex, sem campo, objeto ou permission set novo. Estimativa 10–16 h.
