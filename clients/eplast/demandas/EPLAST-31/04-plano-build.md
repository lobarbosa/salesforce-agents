# EPLAST-31 — Plano de build

**Status deste plano: bloqueado por decisão pendente.** Não há passo a passo de
componentes porque nenhuma arquitetura foi escolhida — e escolher uma aqui
seria decidir por suposição o escopo que o cliente pediu, o que não é papel
do agente (guardrail #3, "não invente metadata"). Este documento existe para
registrar, de forma auditável, por que o plano não pôde ser produzido e o que
falta para ele existir.

## O que foi conferido antes de concluir que não há o que planejar

- **`03-design.md` inteiro**, especialmente:
  - Seção 0 — três perguntas bloqueantes (Q1: a Onda 3 foi autorizada para
    entrar com horas próprias, ficar em backlog ou sair de escopo; Q2:
    EPLAST-31 e EPLAST-32 são a mesma entrega ou entregas separadas; Q3: qual
    das quatro leituras de "previsão" o cliente quer) — nenhuma respondida.
  - Seção 1.2 ("O que NÃO está decidido"): *"A arquitetura. As quatro opções
    da seção 3 usam objetos, recursos e licenças diferentes. Escolher uma
    agora seria decidir por suposição o escopo que o cliente pediu. Isso não
    é papel do agente."*
  - Seção 4 ("Componentes a criar / alterar / depreciar"): *"Nenhum nesta
    etapa. Sem a escolha de Q3, qualquer lista de API names seria invenção."*
  - Seção 13 ("O que este gate pede ao arquiteto humano"): *"Este design não
    deve ser aprovado como liberação de build. Não há componente para
    construir."* Os dois únicos caminhos reconhecidos ali são (a) devolver a
    demanda para `backlog` (se Q1 = b/c) ou (b) responder Q2/Q3 e refazer o
    design (se Q1 = a) — nenhum dos dois é "ir para build".
- **`comentarios-do-card.md`**: só tem dois registros, ambos aprovação
  mecânica de gate ("Aprovou o gate..."). Nenhuma resposta a Q1, Q2 ou Q3 em
  lugar nenhum.
- **`gates.md`**: o hash registrado em `aguardando_gate_design` bate com o
  `03-design.md` atual — o que foi aprovado por Carlos Sordi em
  2026-11-11T22:05:44Z é exatamente este texto, que diz de si mesmo que não
  libera build. (Em contrato de projeto o gate de design libera o build
  direto, sem aprovação de estimativa do cliente — por isso `status.yaml` foi
  para `build` só com essa aprovação, o que é esperado pelo fluxo; o que não é
  esperado é o conteúdo aprovado não ter arquitetura nenhuma.)
- **`sf org list`** (rodado agora, nesta sessão):

  ```
  Type     Alias           Username                           Org Id              Status
  Sandbox  sbx-eplast-dev  projetos@konectabr.com.eplast2.qa  00DHa000006vfMLMAY  Connected
  ```

  Só `sbx-eplast-dev` está autenticada neste runner. `sbx-eplast-qa` não
  aparece. O próprio username contém `.eplast2.qa`, o que é consistente com o
  risco 5 do design ("`sbx-eplast-dev` pode ser a mesma sandbox que
  `sbx-eplast-qa`") — não consegui confirmar nem descartar isso só pelo
  username, precisa de confirmação humana (Org Id de `sbx-eplast-qa` não
  disponível para comparar neste runner).

## Decisão deste agente

Não escrevi metadata em `force-app/`, não rodei `sf project deploy start` e
não criei nenhum componente (Flow, relatório, permission set, campo). As
quatro opções do design (A — painel analítico, B — Forecasting nativo, C —
projeção estatística/IA, D — previsão de pedido) implicam objetos,
licenças e nível de automação diferentes entre si; escolher uma sozinho para
"ter algo para construir" seria inventar escopo não aprovado, que é
exatamente o que o builder tem instrução de não fazer (`.claude/agents/
builder-declarativo.md`: *"Se durante o build você descobrir que o design não
fecha, pare e reporte — não improvise uma solução diferente da aprovada."*).

## O que não consegui medir

- Não tentei `sf project deploy start` nem `sf apex run test`, porque não há
  nenhum componente para empacotar — não é uma falha de comando, é a ausência
  de alvo.
- Não comparei o Org Id de `sbx-eplast-dev` com o de `sbx-eplast-qa` para
  confirmar o risco 5, porque `sbx-eplast-qa` não está autenticada neste
  runner e não há como consultar o Org Id dela daqui.

## O que destrava o build (ordem, conforme seção 0/13 de `03-design.md`)

1. **Q1** — gestor de conta decide: (a) Onda 3 entra com horas próprias, (b)
   fica em `backlog`, (c) sai de escopo. Se (b) ou (c), a demanda volta para
   `backlog` e este ciclo encerra aqui.
2. Se Q1 = (a): **Q2** (gestor de conta + cliente — sobreposição com
   EPLAST-32) e **Q3** (cliente comercial + arquiteto humano — qual leitura de
   "previsão", ou mais de uma) precisam de resposta registrada no card.
3. Com Q1–Q3 respondidas, o design é refeito (o recon de `02-recon.md` vale
   até 2026-11-17) com arquitetura escolhida e lista de componentes — só aí há
   o que materializar neste plano de build.
4. Em qualquer caso, o build também depende de confirmação humana de que
   `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes de fato distintas (risco
   5), o que este agente não conseguiu confirmar nem descartar a partir daqui.

Nenhuma dessas decisões é deste agente. Este plano fica registrado como
bloqueado até que Q1–Q3 e o risco 5 tenham resposta humana.
