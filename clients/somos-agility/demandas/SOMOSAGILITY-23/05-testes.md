# SOMOSAGILITY-23 — Testes (qa)

**Cliente:** somos-agility
**Tipo:** sustentação (bug). Fluxo reduzido: etapas 1, 2, 3 (enxuto), 4, 5, 7.
**Entradas:** `01-analise.md` (critérios de aceite), `03-design.md` (hipóteses de causa),
`04-plano-build.md` (diagnóstico em sandbox de dev, sem build de metadata),
`comentarios-do-card.md`, anexo do card (PDF, só a URL do erro, sem texto da mensagem).
**Gate que libera esta etapa:** `aguardando_gate_build`, aprovado por Leonardo Barbosa em
`gates.md` (2026-10-28T01:38:35Z).

---

## 1. Bloqueio encontrado antes de qualquer execução

A etapa `qa` roda na sandbox de QA — `src/salesforce_agents/ambientes.py`,
`ambiente_do_estagio("qa") == "qa"`, alias `sbx-somos-agility-qa`, GitHub Environment
`somos-agility-qa` (confirmado rodando `sfagents demanda ambiente SOMOSAGILITY-23 --client
somos-agility` nesta sessão).

Este job autenticou **só `sbx-somos-agility-dev`**:

- `sf org list` e `sf org list --all` mostram uma única org conectada, `sbx-somos-agility-dev`
  (`Status: Connected`). Nenhuma org `sbx-somos-agility-qa` aparece.
- `~/.sfdx/alias.json` só tem o alias de dev.
- As variáveis de ambiente do próprio job são `TARGET_ORG=sbx-somos-agility-dev` e
  `AMBIENTE=dev`, não `qa`.
- No `CLAUDE.md` deste cliente, a linha da sandbox **qa** da esteira ainda está em branco
  (`<instance url>` / `API v<NN>`), o que é consistente com essa sandbox nunca ter sido
  conectada via skill `conectar-ambiente`.

**Não tentei rodar o roteiro abaixo contra `sbx-somos-agility-dev` como substituto da QA.**
Isso romperia a própria razão de a esteira cortar dev/qa onde corta (`ambientes.py`): build e
diagnóstico acontecem em dev, homologação acontece na sandbox onde a entrega de fato vai
viver — "homologar em dev e só depois mover pra QA seria homologar uma coisa e entregar
outra". Também não haveria credencial própria de QA para abrir o navegador
(`qa_browser_open`) no ambiente certo.

**Resultado desta etapa: nenhum cenário de teste foi executado em sandbox.** O roteiro abaixo
fica pronto para rodar assim que `sbx-somos-agility-qa` estiver conectada.

## 2. Roteiro de teste (derivado de `01-analise.md` §4)

| # | Cenário | Como executar (quando a QA estiver conectada) |
|---|---|---|
| 1 | Ajustar "Renovação Realizado" no lançamento afetado sem erro | Requer o registro real de produção (`a6UU40000000Ue1MAE`) ou reprodução equivalente em QA com dado sintético no mesmo estado de violação da Opportunity pai. Já identificado em `03-design.md`/`04-plano-build.md` como dependente de ação humana em produção (guardrail #1) — não é executável só pelo agente mesmo com QA conectada. |
| 2 | Demais campos do lançamento afetado continuam editáveis | Testável em QA com dado sintético, sem depender de produção. |
| 3 | Lançamentos não afetados continuam funcionando | Testável em QA com dado sintético (mesmo setup usado em `04-plano-build.md` §3, refeito em QA). |
| 4 | Causa registrada antes da correção (tipo + objeto responsável) | Não é um teste de UI — é checagem documental. Ver §4 abaixo. |
| 5 | Validação em sandbox de QA antes de produção | É esta própria etapa — bloqueada, ver §1. |

## 3. O que foi possível verificar nesta sessão (sem acesso à sandbox de QA)

- Confirmado (leitura, não execução) que `04-plano-build.md` já havia reproduzido em
  **dev** — não em QA, não serve como evidência de homologação — o mecanismo técnico da
  cascata de roll-up (`Realizacao_Financeira_de_Venda__c → Resultado__c → Opportunity`):
  editar `Renova_o__c` recalcula os dois pais, e a validation rule `M38_Valida_Numero_DSA`
  bloqueia esse save quando a Opportunity já viola a regra. Isso é diagnóstico de causa, não
  teste de aceite.
- Confirmado que a causa raiz definitiva **continua não confirmada**: `04-plano-build.md` §5
  registra `M38` como "indefinida, mas mais específica" e `M35`/`M17`-`M20`/`M39` como
  "indefinida — não testável" na sandbox de dev (campos que essas regras referenciam não
  existem no describe ao vivo daquela sandbox). Os passos 1 e 2 do plano de diagnóstico do
  design (mensagem de erro exata do cliente; humano autorizado olhando a Opportunity pai em
  produção) seguem pendentes — não foram feitos entre o build e esta etapa, pelo que consta
  em `comentarios-do-card.md`.

## 4. Critérios de aceite — status

| Cenário (`01-analise.md` §4) | Status | Motivo |
|---|---|---|
| Ajustar o campo no lançamento afetado sem erro | **Não verificado** | Depende de produção (fora do alcance do agente) e, mesmo em QA, de reproduzir o estado de violação da Opportunity pai — não executado nesta etapa (§1). |
| Demais campos do lançamento afetado continuam editáveis | **Não executado** | Sandbox de QA não conectada a este job (§1). |
| Lançamentos não afetados continuam funcionando | **Não executado** | Sandbox de QA não conectada a este job (§1). |
| Causa registrada antes da correção (tipo + objeto responsável) | **Parcialmente atendido** | O tipo de causa foi investigado e restrito (validation rule de estado na Opportunity, hipótese `M38` mais provável, mecanismo de cascata confirmado tecnicamente em dev) mas **não foi confirmado como causa definitiva** — falta a mensagem de erro exata do cliente e a conferência humana da Opportunity pai em produção (`03-design.md` §3, passos 1 e 2, ainda pendentes). |
| Validação em sandbox de QA antes de produção | **Bloqueado** | Esta própria etapa não pôde rodar — ambiente de QA não conectado (§1). |

## 5. O que não consegui medir, e por quê

- **Não consegui autenticar `sbx-somos-agility-qa` nesta sessão** — credencial não
  disponível neste job (só a de dev foi carregada). Confirmado via `sf org list` e
  `sf org list --all`.
- **Não consegui executar nenhum dos 5 cenários Gherkin de `01-analise.md`** em sandbox de
  QA, por causa do bloqueio acima.
- **Não consegui confirmar a causa raiz definitiva do erro em produção** — isso já estava
  fora do alcance desta etapa (depende dos passos 1 e 2 do plano de diagnóstico de
  `03-design.md`, ação humana), e continua pendente.
- Não tentei contornar nenhum dos dois pontos acima com dado inventado ou execução em
  ambiente errado — guardrails #1 (produção/ambiente), #2 (dado real) e #3 (não inventar
  metadata/causa) proíbem isso.

## 6. Recomendação

1. Conectar `sbx-somos-agility-qa` à esteira (skill `conectar-ambiente`: Connected App JWT +
   GitHub Environment `somos-agility-qa` com `SF_CLIENT_ID`/`SF_USERNAME`/`SF_JWT_KEY`
   próprios dessa sandbox) e preencher a seção "qa" no `CLAUDE.md` deste cliente.
2. Depois disso, reexecutar esta etapa para rodar de fato os cenários 2 e 3 do roteiro (§2)
   com dado sintético em QA.
3. Em paralelo — não depende da conexão de QA — seguir cobrando os passos 1 e 2 do plano de
   diagnóstico (`03-design.md` §3): mensagem de erro exata do cliente e conferência humana da
   Opportunity pai em produção. Sem isso, mesmo com QA conectada, o cenário 1 (ajustar o
   campo sem erro) e o critério de "causa registrada" continuam sem fechar.
4. O gate de homologação que segue esta etapa precisa decidir, com esses dois pontos em
   aberto, se aprova mesmo assim (por exemplo, para destravar só os cenários 2 e 3), devolve
   a demanda para diagnóstico adicional, ou espera as respostas pendentes antes de
   homologar.

---

Etapa de teste registrada como **bloqueada por ambiente**, não como homologada. Nenhum
cenário de aceite foi confirmado passando em sandbox de QA nesta sessão.
