# Plano de build — EPLAST-27: Próxima melhor ação por cliente

**Cliente:** Eplast · **Tipo:** projeto · **Org:** `sbx-eplast-dev`
**Base:** `03-design.md` (aprovado por Carlos Sordi em 2026-11-12T13:50:28Z, restrições
D1–D4) + addendum de revisão pré-build do mesmo arquivo (2026-11-12).

---

## 0. Por que este plano não cria nenhum metadata nesta rodada

O design aprovado fecha quatro restrições de arquitetura (D1–D4, seção 1.1 de
`03-design.md`), mas deixa **explicitamente em aberto** a escolha entre as opções A
(fórmula), B (tópico Agentforce), C (Flow) e D (Apex + LWC) — seção 1.2, "Nenhuma está
escolhida" — porque isso depende de respostas do cliente (Q1–Q5) e do gestor de conta
(B0, B1) que, confirmei nesta sessão, continuam sem registro em `comentarios-do-card.md`
ou em `contrato.md`:

- **B0 (escopo contratual):** `contrato.md` ainda lista "Ondas 3 (Comercial), 4
  (Marketing) e 5 (Integrações e treinamento) ainda não contratadas" — sem atualização
  desde a análise.
- **B1 (sobreposição com `SFAgent2`/`insights_comerciais` e `eplast-ent-09/10/11`):** sem
  resposta.
- **Q1 (lista de ações candidatas e critério de priorização):** sem resposta. Esta é a
  lacuna que mais pesa aqui — sem ela não existe regra para codificar em nenhuma das
  quatro opções, nem em fórmula, nem em Flow, nem em prompt de agente, nem em Apex.
- **Q2–Q5 (fonte de dado, canal, IA×regra, público/frequência):** sem resposta.

Escrever um Flow, uma fórmula, um tópico de Agentforce ou uma classe Apex agora
significaria escolher uma das opções e inventar a regra de negócio por conta própria —
exatamente o padrão que travou `CustomerSummaryService` (EPLAST-23), citado no próprio
design como precedente, e que o guardrail #3 (`CLAUDE.md` raiz) proíbe. Por isso este
plano documenta o que **pode** ser planejado hoje (seção 1) e o que fica **condicional**
por opção (seção 2), sem fechar metadata nenhum.

**Nenhuma branch foi criada, nenhum PR foi aberto, nenhum `sf project deploy` ou
`sf project retrieve` foi executado nesta sessão** — não há o que empacotar ainda.

## 1. O que já está decidido e vale para qualquer opção escolhida depois

Direto de `03-design.md` D1–D4, repetido aqui porque é o que efetivamente constrange
qualquer build futuro desta demanda:

- **D1.** Solução somente leitura sobre Account, Opportunity, Order e OrderItem. Nenhuma
  DML nesses objetos, nenhum campo gravado com a sugestão.
- **D2.** Nenhuma criação automática de Task como efeito colateral da sugestão.
- **D3.** Histórico/persistência de sugestões (se vier a ser pedido) é objeto novo —
  escalado à arquitetura sênior, fora deste plano.
- **D4.** Nenhum código novo toca a cadeia Protheus (`ProtheusAPI`, `SendAccountToProtheus`,
  `SendOrderToProtheus`, `OrderAdapter`, `OrderTriggerHandler`).

Essas quatro restrições já eliminam, de antemão, qualquer passo de build que grave em
Account/Opportunity/Order/Task ou que altere a integração com o Protheus — isso vale
para as opções A, B, C e D por igual e não depende de Q1–Q5.

## 2. Plano condicional por opção — passo a passo a executar quando B0/B1/Q1–Q5 forem respondidos

Nenhuma das quatro colunas abaixo foi escolhida. Cada uma é o plano que **seria**
executado se aquela opção fosse a confirmada — para encurtar o caminho entre a resposta
do humano e o build de verdade, sem repetir a investigação de recon.

### Opção A — Campo fórmula em Account

1. Confirmar via `sf` (recon já fica velho em 7 dias, ver seção 4) que
   `LastPurchase__c`, `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`,
   `LastMonthPurchaseValue__c`, `Risk__c`, `LimitUsed__c`,
   `Saldo_duplicatas_a_vencer__c`, `LastActivityDate` continuam como estão.
2. Confirmar com o cliente o significado de cada campo usado (nenhum tem
   `Description` — achado 4 do assessment, confirmado no recon) antes de montar a
   fórmula, e preencher a `Description` do campo novo.
3. Criar 1 campo fórmula (texto) em Account, nome pela skill `padrao-entrega` (ou
   convenção própria da Eplast, que ainda não está preenchida no `CLAUDE.md` do
   cliente — confirmar antes de nomear).
4. Adicionar o campo à `Account_Record_Page`.
5. Sem Apex, sem Flow, sem trigger — nenhuma classe de teste exigida (achado 2 do
   assessment não se aplica a esta opção).
6. Permission set: avaliar reaproveitar `PS_Comercial_ResumoClienteAgente` só se B1
   concluir que esta demanda é extensão do piloto; senão, permission set novo.

### Opção B — Tópico ou ação no `SFAgent2`

1. Resolver B1 antes de tocar em `SFAgent2` — ação concorrente no mesmo agente de
   outras duas demandas (`eplast-ent-09/10/11`) sem coordenação duplica trabalho.
2. Resolver a decisão LGPD (mesma D6 pendente de EPLAST-23) sobre o que vai ao LLM.
3. Confirmar licença de Agentforce em produção (`eplast-ent-04` não está no
   workspace) — sem isso o tópico roda em dev mas não tem onde ir em produção.
4. Estender o tópico `insights_comerciais` ou criar tópico novo no
   `GenAiPlannerBundle` `SFAgent2_v4`, usando ações padrão (`queryRecords`,
   `queryRecordsWithAggregate`) e, se necessário, um Prompt Template novo.
5. Nenhum Apex novo necessariamente — se as ações padrão bastarem, achado 2 do
   assessment não se aplica; se precisar de Agent Action customizada, cai na mesma
   barra de teste da opção D.

### Opção C — Flow somente leitura na página da conta

1. Confirmar com `sf` que `OpportunityFlow`, `ScheduledFlowOpportunity` e os demais
   Flows do recon não mudaram (são a referência de "o que já dispara no mesmo
   evento" — este Flow novo não entra nessa cadeia por ser de tela/autolaunched sob
   demanda, não record-triggered, mas vale reconferir antes de criar).
2. Criar 1 Flow (Get Records em Opportunity/Order/Task da conta + elemento de
   decisão), sem nenhum elemento de gravação (D1).
3. Expor na `Account_Record_Page` (Flow como componente de tela).
4. Sem Apex — achado 2 do assessment não se aplica.
5. Permission set para quem pode ver o componente, mesma decisão de B1 que na opção A.

### Opção D — Apex invocável + LWC

1. Medir volume antes de escrever qualquer SOQL agregado: dev está vazia (recon,
   seção 1), então a carga sintética de QA (ver `03-design.md` seção 3) precisa rodar
   **antes** de fechar a consulta, não depois.
2. Classe `with sharing`, `WITH USER_MODE`, sem SOQL em loop, agregação por
   `GROUP BY` em vez de trazer linha de Order/OrderItem para memória.
3. `<Classe>Test` com cobertura ≥85% da classe nova — convenção do squad
   (`CLAUDE.md` raiz) e já no padrão que 3 das 54 classes desta org seguem
   (`CustomerSummaryServiceTest`, `CreateQuoteCPQControllerTest`,
   `FlowOpportunityControllerTest`). Fixtures sintéticas para todo campo obrigatório
   de Account/Order/OrderItem (as validation rules de Order, achado 3 do
   assessment, não tocam esta classe mas as fixtures precisam passar por elas para
   inserir dado de teste). **Não** assumir cobertura nenhuma da cadeia de
   automação existente (`AccountTrigger`, `OrderTriggerHandler` etc.) — o recon
   mediu 0% nela, e D4 já proíbe esta classe de chamar a cadeia Protheus, então o
   teste não precisa (e não deve) exercitar aquele caminho.
4. LWC na página da conta, ou a mesma classe exposta como Agent Action (opção B),
   conforme Q3.
5. API version da classe nova: v68 (org atual, recon seção "Divergências"), não
   replicar o v58/v59 das classes legadas (achado 9 do assessment).

## 3. O que explicitamente não será feito nesta rodada nem em nenhuma das opções

- Nenhuma escrita em Account, Opportunity, Order, OrderItem ou Task (D1, D2).
- Nenhuma alteração em trigger, Flow ou classe Apex já existente nesses objetos.
- Nenhum toque na cadeia Protheus (D4).
- Nenhum objeto novo para histórico de sugestões (D3 — escalado à arquitetura sênior).
- Nenhuma alteração de perfil (achados 7/8 do assessment).
- Deploy em produção (guardrail #1 — não se aplica aqui de nenhuma forma, a esteira só
  alcança dev e qa).
- Abertura de branch `feature/EPLAST-27` ou PR: não há diff de metadata para propor
  enquanto a opção não é escolhida. Criar a branch vazia só para "cumprir etapa" seria
  abrir um PR sem conteúdo revisável — pior do que não abrir nenhum.

## 4. O que não consegui medir, ou não tentei medir, nesta sessão — e por quê

- **Não executei nenhuma consulta `sf` nova contra `sbx-eplast-dev`.** Nenhuma decisão
  de metadata foi tomada nesta rodada (seção 0), então não havia objeto/campo novo para
  confirmar — o recon de `02-recon.md` (coletado em 2026-11-10, validade declarada de 7
  dias) segue sendo a referência. **Atenção:** essa validade vence em 2026-11-17; se o
  build real começar depois dessa data, o próximo agente de build precisa reconfirmar
  via `sf` antes de assumir qualquer item do recon como atual (achado 1, triggers/Flows,
  e achado 5, cobertura, mudam com o tempo — a própria divergência registrada no recon
  já mostra cobertura subindo de 10% para 11% entre o assessment e o recon).
- **Não dá para medir volume real de contas por vendedor nem de pedidos/itens por
  conta** — a dev está vazia (recon, seção 1) e produção é proibida (guardrail #1). Isso
  já estava registrado no design (seção 3) como coisa que só o roteiro de QA com carga
  sintética resolve, e continua valendo: nenhuma opção acima pode ser dimensionada para
  CPU/SOQL sem essa carga.
- **Não confirmei separação dev/qa** (achado 6 do assessment/recon): o alias
  `sbx-eplast-qa` não está configurado neste runner. Isso bloqueia a etapa de QA desta
  demanda independentemente da opção escolhida, não é specific deste plano de build.
- **Não tentei abrir branch nem PR**, pela razão da seção 3: não há metadata para
  propor.

## 5. Gate seguinte

Este plano é a entrada do gate **PR obrigatório / aguardando_gate_build** do fluxo
canônico — mas, diferente de uma etapa de build normal, não há PR de metadata para
revisar ainda, porque nenhuma opção foi escolhida. O que o humano precisa decidir neste
gate:

1. Responder B0, B1 e Q1–Q5 (seção 0 deste plano e seção 9 de `03-design.md`) — sem
   isso, aprovar este gate só adiantaria para "construir algo", não para "construir o
   que foi pedido".
2. Com a opção escolhida (A, B, C ou D), o próximo agente de build retoma direto na
   seção 2 correspondente deste plano — a investigação de recon e o desenho das
   restrições já estão feitos, falta só a decisão e, então, a execução.
3. Se a resposta a B0 for "a Onda 3 não está e não vai ser autorizada agora", a
   recomendação é mover esta demanda para `backlog` (opção (b) de `03-design.md`) em vez
   de manter o ciclo girando em um gate que não evolui.

---

Plano de build pronto nos limites do que podia ser decidido sem inventar escopo nem
regra de negócio. Nenhum metadata foi criado, nenhuma branch ou PR foi aberta. Parando
no gate humano seguinte.
