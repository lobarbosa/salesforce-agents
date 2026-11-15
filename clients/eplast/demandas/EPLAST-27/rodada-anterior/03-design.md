# Design — EPLAST-27: Próxima melhor ação por cliente

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 · Comercial (**não contratada**, `contrato.md`)
**Org do recon:** `sbx-eplast-dev` (sandbox confirmada, ver `02-recon.md`, coleta de 2026-11-10)
**Status deste design:** **condicional e bloqueado para build.** Ele fecha as restrições de
arquitetura que o recon permite fechar hoje e deixa explícito o que não pode ser decidido
sem resposta do cliente e do gestor de conta.

---

## 0. Bloqueios que vêm antes de qualquer decisão técnica

### B0. Escopo contratual: escalado ao humano, bloqueante

`contrato.md` cobre só as Ondas 1–2 (120 h, fim previsto em 2026-11-30). A Onda 3, de onde
esta demanda vem, está listada como "ainda não contratada". O gate de análise foi aprovado
sem resposta registrada a essa pergunta: `comentarios-do-card.md` só traz o registro da
aprovação.

Isto não é decisão do arquiteto. **Recomendo que o gate de design não libere o build** até
o gestor de conta registrar uma das opções abaixo (mesma formulação usada em
[RAG: demandas/EPLAST-31/01-analise.md], para manter as demandas irmãs da Onda 3 coerentes):

- (a) a Onda 3 foi autorizada (aditivo ou autorização escrita) e a demanda entra na esteira com horas próprias;
- (b) a demanda volta para `backlog` como antecipação, sem build até o aceite;
- (c) a demanda sai deste projeto e vai para uma proposta futura.

Pela regra de estimativa do squad, o gate de design também não libera o build sem
aprovação do cliente para a estimativa. Sem contrato, essa aprovação não tem contra o que
debitar.

### B1. Sobreposição com o que já existe e com o escopo contratado

O recon achou na org coisas que a análise não tinha como ver:

- **Já existe um agente Agentforce (`SFAgent2`, Employee Agent)** com o tópico
  `insights_comerciais`. A descrição dele, na própria metadata, já promete "gera insights
  para negociação e identifica oportunidades paradas, pedidos pendentes e sinais de risco
  na carteira do vendedor". Isso é muito próximo de "sugerir a próxima melhor ação". As 4
  versões estão inativas nesta sandbox.
- Os entregáveis **contratados** `eplast-ent-09` ("Quais clientes precisam de acompanhamento
  hoje?"), `eplast-ent-10` (resumo completo do cliente) e `eplast-ent-11` (clientes há mais
  tempo sem comprar) estão sendo construídos **fora da esteira** (`contrato.md`), e no
  mesmo agente, pelo que se vê na org.
- `CustomerSummaryService`, o Agent Action do resumo de cliente (EPLAST-23), está na org como
  **scaffold bloqueado**. O próprio comentário da classe registra que a arquitetura foi
  aprovada, mas que as decisões de negócio e LGPD (D2–D6) nunca foram respondidas. É o mesmo
  padrão de lacuna desta demanda, e o histórico mostra que aprovar a arquitetura sem essas
  respostas produziu código que não roda.
- Há demandas irmãs da Onda 3 com o mesmo território: EPLAST-26 (scoring), EPLAST-28
  (oportunidade parada), EPLAST-33 (recuperação e venda cruzada)
  [RAG: demandas/EPLAST-33/01-analise.md].

**Pergunta ao humano:** EPLAST-27 é (i) um tópico ou ação novos no `SFAgent2`, estendendo o
piloto, (ii) uma entrega separada com regra própria, ou (iii) parte de EPLAST-33/26/28? Sem
essa resposta há risco de cobrar o mesmo trabalho duas vezes e de ter duas "próximas ações"
com regras diferentes para o mesmo vendedor.

### B2. Perguntas da análise que continuam sem resposta e que mudam a arquitetura

| # | Pergunta (01-analise.md) | Por que muda a arquitetura |
|---|---|---|
| Q1 | Lista de ações candidatas e critério de priorização | Sem isso não existe regra para implementar, nem em fórmula, nem em Flow, nem em prompt |
| Q2 | Fontes de "histórico e situação comercial" | Campos de Account já calculados (seção 2.2) cabem em fórmula ou Flow. Agregação de Order/OrderItem por conta pode empurrar para Apex |
| Q3 | Canal (página do registro × agente) | Decide se é Lightning page ou tópico no `SFAgent2` |
| Q4 | IA generativa/preditiva × regra determinística | LLM exige decisão LGPD sobre o que vai ao modelo, a mesma D6 pendente em EPLAST-23. Preditivo de verdade exige plataforma (Einstein/Data Cloud) que **não foi confirmada** na org (0 `RecommendationStrategy`) |
| Q5 | Público e frequência (sob demanda × recalculado) | Recalcular e gravar põe a solução dentro da cadeia de automação da seção 2.1. Calcular na leitura fica fora dela |

Nada disso foi respondido no card. **Não preenchi nenhuma dessas lacunas por suposição.**

---

## 1. Decisão

### 1.1 O que fica decidido agora (restrições de arquitetura, valem para qualquer opção)

**D1. A solução é somente leitura sobre Account, Opportunity, Order e OrderItem.** A
sugestão é calculada na hora da consulta. Ela não é gravada em campo desses objetos e não
dispara DML neles.

Justificativa, pelo recon (`02-recon.md` §2.3):

- **Todo update de Account enfileira `SendAccountToProtheus`.** `AccountTriggerHelper.updateAccountInfoFromCNPJ`
  faz um `enqueueJob` por conta, sem filtro de campo. Gravar a "próxima ação" num campo de
  Account, mesmo que só uma vez por dia, reenviaria cada conta ao ERP a cada recálculo. Em
  lote síncrono acima de 50 contas, estoura o limite de 50 `enqueueJob` por transação.
- Account, Opportunity e Order têm Flows after-save **sem critério de entrada**, além de
  trigger custom e trigger do CPQ no mesmo evento, sem ordem garantida (achado 1 do
  assessment, confirmado).
- Ficar fora dessa cadeia é o jeito mais barato de não piorar o achado 1. Consolidar a
  automação desses objetos é um trabalho de esforço alto, que o assessment recomenda e que
  não pertence a esta demanda.

**D2. Criar Task automaticamente como "ação" também conta como escrita em Account, e está
fora do desenho padrão.** `TaskCreatedOrUpdated` (after-save, sem critério) atualiza
`Account.AccountHasCheckInTask__c`, o que dispara a cadeia acima. Se o negócio quiser que a
sugestão vire tarefa, isso volta ao arquiteto com o desenho dessa cascata.

**D3. Se o negócio quiser histórico ou persistência das sugestões** (ex.: medir aceite das
sugestões), isso exige objeto novo, ou seja, **mudança de modelo de dados**. **Escalo à
arquitetura sênior. Não decido aqui.**

**D4. Nenhum código novo chama ou altera a cadeia Protheus** (`ProtheusAPI`,
`SendAccountToProtheus`, `SendOrderToProtheus`, `OrderAdapter`, `OrderTriggerHandler` etc.).

### 1.2 O que não dá para decidir ainda: declarativo × código × plataforma de IA

A ordem de preferência da doutrina (configuração → Flow → código) só pode ser aplicada
quando existir regra (Q1), fonte (Q2) e canal (Q3). Abaixo estão as opções viáveis **já
filtradas pelo recon**, na ordem da doutrina, com a condição que faz cada uma ser a certa.
Nenhuma está escolhida.

| Opção | Nível | Quando é a certa | Componentes (todos **propostos, nenhum existe**) | Por que não subir um nível |
|---|---|---|---|---|
| **A. Fórmula em Account** | Configuração | Regra determinística, poucas ações, e só sobre campos que **já existem** em Account (`LastPurchase__c`, `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`, `Risk__c`, `LimitUsed__c`, `Saldo_duplicatas_a_vencer__c`, `LastActivityDate`) | 1 campo fórmula texto em Account (nome a definir pela skill `padrao-entrega`), na `Account_Record_Page` | É o topo. Campo fórmula não faz DML e não dispara trigger nem Flow, então respeita D1. **Mas é campo novo em Account, ou seja, alteração de schema: confirmar com a arquitetura sênior (D3).** Limite: fórmula não enxerga Order nem Task |
| **B. Tópico ou ação no `SFAgent2`** | Declarativo (Agentforce) | Canal = agente, resposta em linguagem natural, coerente com o piloto | Tópico novo ou extensão de `insights_comerciais`. Ações padrão (`queryRecords`, `queryRecordsWithAggregate`) e, se preciso, um Prompt Template | Só vale se Q3 = agente e Q4 = IA generativa aceita. **Exige decisão LGPD** sobre o que vai ao LLM (a mesma D6 de EPLAST-23, até hoje sem resposta) e **licença em produção confirmada** (`eplast-ent-04`, fora do workspace). A sobreposição com `insights_comerciais` tem que ser resolvida antes (B1) |
| **C. Flow autolaunched/de tela na página da conta** | Declarativo (Flow) | Regra determinística que precisa ler Opportunity, Order ou Task da conta, com volume por conta pequeno | 1 Flow somente leitura (Get Records + decisão), exibido na `Account_Record_Page` | Sobe para Flow só se a regra precisar de dado fora de Account (a fórmula não alcança). Não pode ter elemento de gravação (D1) |
| **D. Apex invocável + LWC** | Código | Agregação de Order/OrderItem por conta em volume que o Flow não aguenta, ou regra com muitos ramos que exija teste unitário determinístico | Classe `with sharing`, `WITH USER_MODE`, sem SOQL em loop, `<Classe>Test` com 85%. LWC na página da conta, ou a mesma classe como Agent Action na opção B | Desce para código só com volume medido e regra que justifique (critérios da doutrina). Hoje **não há volume medido** (dev vazia, seção 3), então não há justificativa para escolher D de antemão |
| ~~E. Einstein Next Best Action / preditivo~~ | Plataforma | — | — | **Descartada nesta demanda**: 0 `RecommendationStrategy`, e Data Cloud ou modelo preditivo não foram confirmados na org. Se Q4 = "modelo preditivo de verdade", vira outra demanda com levantamento de licença e de dado de treino |

**Inclinação, não decisão:** pela doutrina e pelo recon, o caminho mais barato e seguro
tende a ser **A ou C para regra determinística** ou **B para canal agente**. Qual delas
depende de Q1–Q4. Escrevo isso para orientar a conversa com o cliente, não para fechar o
design.

---

## 2. Riscos do assessment que tocam esta demanda

| Achado | Severidade | Como este design lida |
|---|---|---|
| **1. Automação concorrente em Account/Opportunity/Order** | Alta | **Evitado por construção (D1, D2).** A solução não grava nesses objetos nem em Task, então não entra na ordem de execução não mapeada. O recon piorou o quadro: os Flows after-save não têm critério de entrada, e o update de Account reenvia a conta ao Protheus. **Se qualquer resposta de Q1–Q5 exigir escrita nesses objetos, este design perde a validade e volta ao gate**, com o mapeamento da ordem de execução como pré-requisito, como o assessment recomenda |
| **2. Cobertura Apex ~10% (hoje 11%), Protheus sem rede de teste** | Alta | **Não se aplica às opções A, B e C** (sem Apex novo, e D4 proíbe tocar a cadeia Protheus). **Na opção D**: classe nova com `<Classe>Test` e 85%, fixtures sintéticas preenchendo todo campo exigido pelas validation rules de Account/Order (doutrina, achado SOMOSAGILITY-10) e `TriggerUtility.bypassTrigger` só na fixture, para criar dado de teste sem enfileirar callout real. Não assumo nenhuma cobertura da integração existente: hoje é 0 linha no caminho dos triggers dos três objetos. Risco à parte: se a regra usar `LastPurchase__c` ou outros campos alimentados pelo ERP, o problema é **qualidade do dado** (o mesmo alerta de `eplast-ent-11` no contrato), não cobertura de código |
| 3. Validation rules de Order | Média | Não se aplica: sem DML em Order |
| 4. Campos sem descrição | Média | **Se aplica**: nenhum dos campos candidatos da seção 2.2 do recon tem `Description`. Antes do build, cada campo usado pela regra precisa ter o significado confirmado com o cliente. Qualquer campo novo (opção A) sai com `Description` |
| 5. Convenção `<Classe>Test` | Média | Só na opção D: seguir `<Classe>Test` |
| 6. Alias dev aponta para instância "qa" | Média | **Bloqueante para o build e a QA, independente de B0**: o host de `sbx-eplast-dev` continua indicando "qa", e `sbx-eplast-qa` não está configurado. Confirmar a separação dev/qa antes do build |
| 7, 8. Perfis | Baixa | Ver seção 4. Nenhuma alteração de perfil |
| 9, 10 | Baixa | Não se aplicam: nenhuma classe existente é editada |

## 3. Ordem de execução, governador e CPU

- **Opções A, B e C (leitura):** nenhuma DML, nenhum trigger ou Flow disparado. Risco de
  ordem de execução: nenhum.
- **SOQL:** a consulta por conta precisa ser agregada (`COUNT`/`SUM`/`MAX` com `GROUP BY`),
  sem trazer linhas de Order/OrderItem para a memória. Limites de referência: 100 SOQL e
  50.000 linhas por transação síncrona.
- **CPU, dois cenários (doutrina, achado SOMOSAGILITY-10):**
  - *muitos registros:* só existiria numa visão de carteira (lista de contas do vendedor
    com a sugestão de cada uma). Isso pede cálculo por lote de contas, nunca uma consulta
    por conta em loop;
  - *uma conta com muitos filhos* (muitos pedidos e itens): é o cenário que estoura CPU com
    agregação em memória. **Não dá para dimensionar agora**: a dev tem 0 registros e
    produção é proibida. O roteiro de QA tem que incluir carga sintética de uma conta com
    volume realista de pedidos e itens, com o número informado pelo cliente. Se a medição
    passar de ~70% de qualquer limite, o design volta para revisão.
- **Se alguém propuser gravar a sugestão** (contra D1): uma transação síncrona com mais de
  50 contas atualizadas estoura `enqueueJob` pelo caminho já existente
  (`AccountTriggerHelper`), antes mesmo de chegar a qualquer código desta demanda.

## 4. Permissões

- **Nenhum perfil é alterado** (assessment, achados 7 e 8: quatro perfis "Comercial" coexistindo).
- O acesso entra por **permission set**. Reaproveitar `PS_Comercial_ResumoClienteAgente`
  (já existe) só se B1 concluir que esta demanda é extensão do piloto. Se for entrega
  separada, um permission set novo, com nome pela skill `padrao-entrega`.
- Opção B: o usuário precisa da PSL de Agentforce correspondente **em produção**. Isso não
  foi confirmado: a sandbox mostra as licenças, mas não comprova contrato.
- Opções C e D: a leitura respeita o compartilhamento do usuário (`with sharing`,
  `WITH USER_MODE`). O vendedor só vê sugestão de conta que já enxerga.

## 5. Componentes

| Ação | Componente | Situação |
|---|---|---|
| Criar | Depende da opção (seção 1.2) | **Nenhum até B0, B1 e Q1–Q4 serem respondidos** |
| Alterar | `Account_Record_Page` (opções A, C, D) ou `SFAgent2` / tópico `insights_comerciais` (opção B) | Existem na org. Alteração só depois da decisão |
| Alterar | Qualquer trigger, Flow ou classe existente em Account/Opportunity/Order/Task | **Proibido nesta demanda** (D1, D4) |
| Depreciar | Nenhum | — |

## 6. Riscos técnicos

| # | Risco | Severidade |
|---|---|---|
| R1 | Build iniciado sem contrato (B0) consome horas sem cobertura comercial | **Alta (bloqueante)** |
| R2 | Duplicar `insights_comerciais` / `eplast-ent-09/10/11`, com duas "próximas ações" de regras diferentes (B1) | **Alta** |
| R3 | Repetir o padrão de EPLAST-23: arquitetura aprovada sem regra de negócio, o que gera código que só lança exceção | **Alta** |
| R4 | Escrita em Account reenviar contas ao Protheus e estourar `enqueueJob` (mitigado por D1 e D2, volta se D1 cair) | Alta (latente) |
| R5 | Opção B mandar dado de cliente ao LLM sem decisão LGPD | Alta (se B for escolhida) |
| R6 | Usar campo de significado ambíguo: 0% de descrição, `Deleted2__c` com o mesmo rótulo de `AveragePurchasesThisYear__c`, `LastPurchase__c` sem escritor identificado | Média |
| R7 | Volume por conta desconhecido. CPU não dimensionável até a QA com carga sintética | Média |
| R8 | Separação dev/qa não confirmada (achado 6) | Média (bloqueante para QA) |

## 7. O que NÃO será feito nesta demanda

- Nenhuma escrita em Account, Opportunity, Order, OrderItem ou Task (D1, D2).
- Consolidar ou mapear a automação concorrente desses objetos (achado 1). É uma demanda
  própria, de esforço alto.
- Aumentar a cobertura da cadeia Protheus (achado 2), ou corrigir o callout em loop do
  `OpportunityTriggerHelper` ou o reenvio incondicional do `AccountTriggerHelper`. Ficam
  registrados como dívida para backlog.
- Implementar ou desbloquear `CustomerSummaryService` (EPLAST-23).
- Modelo preditivo, Einstein Next Best Action ou Data Cloud (opção E).
- Objeto novo para histórico de sugestões (D3, escalado).
- Qualquer alteração de perfil.
- Deploy em produção (guardrail #1).

## 8. Estimativa

**Estimativa de esforço:** 10–28 h

O que mudou em relação à análise (8–24 h), e por quê:

- **Ponta de cima, de 24 para 28 h.** O teto da análise contava com consolidar a automação
  concorrente (achado 1). D1 tira esse trabalho do escopo. Em compensação, o recon mostrou
  que a opção B (Agentforce) é plausível, e ela custa mais em teste de resposta, decisão
  LGPD e coordenação com o `SFAgent2`. A opção D (Apex + LWC com 85% de teste e carga
  sintética de CPU) também cabe nessa ponta.
- **Ponta de baixo, de 8 para 10 h.** Mesmo a opção mais simples (A) agora inclui conciliar
  com `insights_comerciais` / `eplast-ent-09/10/11` e confirmar o significado dos campos
  usados, porque nenhum tem descrição.
- **Fora da faixa:** a resposta a B0/B1/Q1–Q5 com o cliente, a confirmação dev/qa (achado 6),
  um eventual objeto de histórico (D3) e qualquer cenário que derrube D1. Se a regra
  definida exigir agregação pesada de Order/OrderItem com volume grande, a faixa volta para
  revisão.
- A faixa só mede o tamanho do pedido. **Ela não cria escopo contratado** (B0).

## 9. O que o humano precisa decidir no gate

1. **B0.** Registrar (a), (b) ou (c). Sem isso, recomendo **não liberar o build**.
2. **B1.** Extensão do `SFAgent2`/piloto, entrega separada, ou fusão com EPLAST-33/26/28.
3. **Aceitar ou recusar D1–D4** como restrições de arquitetura desta demanda.
4. **D3.** Se houver necessidade de histórico, levar à arquitetura sênior.
5. Encaminhar Q1–Q5 ao cliente. A escolha entre as opções A, B, C e D só fecha com elas.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o
build. Neste caso, minha recomendação explícita é que o aceite cubra apenas as restrições
D1–D4 e que o build **não** seja liberado enquanto B0 e B1 não tiverem resposta registrada.

---

## Addendum — revisão na entrada da etapa de build (2026-11-12)

O gate `aguardando_gate_design` foi aprovado por Carlos Sordi em
2026-11-12T13:50:28Z e a demanda avançou para `build` (ver `status.yaml` e
`gates.md`). Antes de acionar `builder-declarativo`/`dev-apex`, conferi se B0,
B1 e Q1–Q5 (seção 0 e 9 deste design) tinham resposta registrada em algum
lugar sincronizado — `comentarios-do-card.md`, `demanda.md`, `contrato.md` —
porque sem elas não há o que construir sem inventar decisão de negócio
(guardrail #3, e o mesmo padrão que travou `CustomerSummaryService`/EPLAST-23
citado na seção B1 acima).

**O que confirmei nesta revisão:**

- `comentarios-do-card.md` só registra as duas aprovações de gate (análise e
  design), sem nenhuma resposta a B0, B1 ou Q1–Q5.
- `contrato.md` (materializado pelo `planejador`, não editado à mão) continua
  listando, hoje, "Ondas 3 (Comercial), 4 (Marketing) e 5 (Integrações e
  treinamento) ainda não contratadas" — **B0 segue sem confirmação registrada
  de que a Onda 3 foi autorizada.**
- Nenhum artefato novo ou editado desde a aprovação do gate (o hash de
  `03-design.md` e `02-recon.md` em `gates.md` ainda bate com o que está em
  disco) — ou seja, nada mudou de substância entre a aprovação e agora.
- B1 (sobreposição com `SFAgent2`/`insights_comerciais` e com
  `eplast-ent-09/10/11`) segue sem resposta.
- Nenhuma das opções A/B/C/D da seção 1.2 foi escolhida, e Q1 (lista de ações
  candidatas e critério de priorização) continua sem resposta. **Isto por si
  só já impede qualquer build**: não existe regra determinística, tópico de
  agente, fórmula ou classe Apex possível de escrever sem inventar o que a
  "próxima melhor ação" significa — independente de como B0/B1 forem
  resolvidos.

**Decisão desta revisão:** não acionei `builder-declarativo` nem `dev-apex`.
Construir agora exigiria escolher uma das opções A–D e definir a regra de
negócio por conta própria, o que a doutrina deste squad proíbe explicitamente
e que já custou caro uma vez nesta conta (EPLAST-23). Devolvi a demanda para
`aguardando_gate_design` (reversão de status permitida pelo guardrail #5 do
`CLAUDE.md` raiz — "corrigir manualmente pra trás... sempre é permitido, sem
exigir o artefato do estágio abandonado"; nenhum artefato de build foi
produzido, então não há nada a abandonar). Isto não desfaz nem invalida a
aprovação já registrada em `gates.md` — ela continua valendo para as
restrições D1–D4. O que falta é uma aprovação **com as respostas de B0, B1 e
Q1–Q5 registradas em `comentarios-do-card.md` ou em `contrato.md`** antes do
build poder começar de fato.

**Para desbloquear, alguém com visibilidade do contrato e do cliente precisa
responder, no card ou no contrato:**

1. B0 — a Onda 3 foi autorizada para esta demanda entrar em esteira (e
   `contrato.md` precisa ser atualizado pelo `planejador`), ou a demanda
   deve voltar para `backlog` como antecipação sem build, ou sair deste
   projeto?
2. B1 — EPLAST-27 é extensão do tópico `insights_comerciais` do `SFAgent2`,
   entrega separada, ou parte de EPLAST-26/28/33?
3. Q1–Q5 — lista de ações candidatas e critério de priorização, fontes de
   dado, canal (página de registro × agente), regra determinística × IA
   generativa, e público/frequência.

Sem isso registrado, recomendo que o próximo gate aprovado **não** repita a
mesma aprovação genérica — ela não libera o build sozinha.
