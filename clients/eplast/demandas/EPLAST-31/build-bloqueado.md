# EPLAST-31 — Build não executado

**Data:** 2026-11-11
**Agente:** `builder-declarativo`
**Ambiente conferido:** `sf org list` mostra apenas `sbx-eplast-dev` conectada
(Sandbox, Connected). `sbx-eplast-qa` não aparece — confirma o achado do risco 5
de `03-design.md`.

## O que foi conferido antes de tocar em metadata

Li `03-design.md` inteiro e `comentarios-do-card.md`. Confirmo a leitura que me
foi passada:

- `03-design.md` seção 0 lista Q1, Q2 e Q3 como perguntas bloqueantes, todas sem
  resposta.
- Seção 1.2 ("O que NÃO está decidido") diz explicitamente: "A arquitetura. As
  quatro opções da seção 3 usam objetos, recursos e licenças diferentes.
  Escolher uma agora seria decidir por suposição o escopo que o cliente pediu.
  Isso não é papel do agente."
- Seção 4 ("Componentes a criar / alterar / depreciar"): "**Nenhum nesta
  etapa.** Sem a escolha de Q3, qualquer lista de API names seria invenção."
- Seção 13 ("O que este gate pede ao arquiteto humano"): "Este design **não**
  deve ser aprovado como liberação de build. Não há componente para
  construir." Os dois únicos caminhos que a seção reconhece são (a) devolver a
  demanda para `backlog` se Q1 = (b)/(c), ou (b) responder Q2 e Q3 no card e
  refazer o design se Q1 = (a). Nenhum dos dois é "ir para build".
- `comentarios-do-card.md` tem só dois registros, ambos aprovação mecânica de
  gate ("Aprovou o gate..."). Nenhuma resposta a Q1, Q2 ou Q3 em lugar nenhum.
- `gates.md` confirma: o hash registrado em `aguardando_gate_design` bate com o
  `03-design.md` atual — o que foi aprovado é exatamente este texto, que diz de
  si mesmo que não libera build.

`status.yaml` está em `build` porque o gate do design foi aprovado
mecanicamente (aprovação de card registrada por Carlos Sordi em
2026-11-11T22:05:44Z), mas o conteúdo aprovado não contém nenhuma decisão de
arquitetura nem lista de componentes — só as opções A/B/C/D comparadas, sem
recomendação, para o humano escolher.

## Decisão deste agente

Não escrevi nenhum metadata em `force-app/`, não criei `04-plano-build.md` e
não rodei `sf project deploy start`. Construir qualquer coisa agora exigiria
que eu escolhesse sozinho uma das opções A/B/C/D (declarativo vs. código, e
qual leitura de "previsão" atender) — decisão que o próprio design reserva ao
arquiteto humano e ao cliente, não ao agente. Isso seria invenção de escopo não
aprovado, o que minhas instruções proíbem explicitamente.

## O que destrava o build

Nesta ordem, conforme a seção 0 e a seção 13 de `03-design.md`:

1. **Q1** — Gestor de conta decide: (a) Onda 3 entra com horas próprias, (b)
   fica em backlog, (c) sai do escopo. Se (b) ou (c), a demanda volta para
   `backlog` e este ciclo encerra aqui.
2. Se Q1 = (a): **Q2** (gestor de conta + cliente, sobreposição com
   EPLAST-32) e **Q3** (cliente comercial + arquiteto humano, qual das quatro
   leituras de "previsão" — ou mais de uma) precisam de resposta registrada no
   card.
3. Com Q1–Q3 respondidas, o design precisa ser refeito (o recon atual vale até
   2026-11-17) com a arquitetura escolhida e a lista de componentes — só então
   há o que materializar como metadata e `04-plano-build.md`.
4. Build também depende, em qualquer caso, da aprovação da estimativa pelo
   cliente e da confirmação humana de que `sbx-eplast-dev` e `sbx-eplast-qa`
   não são a mesma sandbox (risco 5) — risco que a checagem de org acima
   reforça, já que `sbx-eplast-qa` nem aparece autenticada neste runner.

Recomendação: mover `status.yaml` de volta para o estágio que reflita que o
design está incompleto por decisão (ou tratar isso diretamente pelo gestor de
conta/arquiteto, já que o histórico de `status.yaml` é mecânico e não deve ser
editado à mão por este agente).
