# SOMOSAGILITY-7 — Testes (QA)

**Cliente:** somos-agility · **Data:** 2026-10-23
**Entradas:** `01-analise.md` (Gherkin-esqueleto), `comentarios-do-card.md` (P1/P2/P3),
`02-recon.md`, `03-design.md` (tabela R1–R5, riscos T1–T7, lacuna L1), `04-plano-build.md`
(v5 deployada em dev, desvio do `triggerOrder`, bloqueio de FLS).

---

## 0. Estado do ambiente nesta sessão (confirmado antes de testar)

```
sf org list
```
retornou **apenas** `sbx-somos-agility-dev` (Sandbox, Connected). `sbx-somos-agility-qa`
**não aparece** — não está conectada nesta sessão, batendo com o `CLAUDE.md` do cliente
(campos de sandbox de QA ainda como placeholder). Por isso:

- **Não tentei** `qa_browser_open` contra `sbx-somos-agility-qa`: a falha seria "org não
  conecta", não um resultado de teste, e documentar uma tentativa fadada não agrega nada
  além do que já está dito aqui.
- Os únicos itens **de fato executados nesta sessão** foram conferências de metadata em
  **dev** (CT-00 e CT-01 abaixo) — não são homologação, são confirmação de que o artefato
  do build está no estado que `04-plano-build.md` descreve.
- **Todo o resto dos critérios de aceite virou roteiro escrito para humano rodar em
  `sbx-somos-agility-qa`** quando ela conectar, pelos dois motivos que se somam: (a) ausência
  da sandbox de QA; (b) o usuário desta sessão não tem FLS nos campos do modelo de 3
  executores em dev (confirmado de novo abaixo, CT-02), então nem em dev seria possível
  montar massa de teste e exercitar a regra de ponta a ponta com a sessão atual.

Nenhuma query rodada retornou dado pessoal ou de negócio de cliente — só metadata
(`Flow`/`Definition` via Tooling API) e uma tentativa de `data create record` que falhou
antes de gravar qualquer coisa.

---

## 1. Resultados (falhas e bloqueios primeiro)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-02 | Executar `sf data create record --sobject Lancamento_de_Atividades__c --values "Status__c='Rascunho' Qtd_de_executores__c='1'"` em `sbx-somos-agility-dev` | Registro sintético criado para servir de base aos testes funcionais | `INVALID_FIELD: No such column 'Qtd_de_executores__c'` — o usuário da sessão não enxerga o campo via API | **Bloqueado** (ambiente/permissão, não é falha da correção). Confirma `02-recon.md` §1 e `04-plano-build.md` §6: sem FLS atribuída (`Lancamento_de_atividades_admin` ou equivalente) não dá para montar massa de teste nem em dev, nem para validar a regra via tela sem ser esse usuário |
| CT-03 a CT-13 | Ver §3 — matriz derivada dos critérios de aceite | — | **Não executados nesta sessão** — viraram roteiro para humano (falta de `sbx-somos-agility-qa` conectada + FLS) | **Não executado (roteiro para humano)** |
| CT-00 | Conferir via Tooling API em dev: `SELECT Id, VersionNumber, Status, ProcessType FROM Flow WHERE Definition.DeveloperName = 'Atualiza_o_status_final_de_aprovacao_do_LAT'` | v5 `Active`, v4 `Obsolete` | v5 `Active` (Id `301Ha000014cOgXIAU`), v4 `Obsolete`, v3/v2/v1 `Obsolete` | **Passou** (conferência de metadata em **dev**, não é homologação) |
| CT-01 | Reler `04-plano-build.md` §4 (deploy) e conferir consistência com CT-00 | Deploy relatado bate com o estado atual da org | Bate: nenhuma reativação manual, nenhum passo pendente de deploy | **Passou** (conferência documental + metadata em dev) |

**Risco T1 (ordem de execução entre os 4 flows after-save + Process Builder, sem
`triggerOrder`) e T3 (disparo do flow pelo field update do approval process) seguem
**sem confirmação prática**.** Nada nesta sessão testou isso — nem poderia, dado o bloqueio
de FLS. Ambos exigem o roteiro da §3 rodando em QA (ou em dev com um usuário com FLS, se o
humano decidir validar lá antes).

---

## 2. Critérios de aceite usados como base (reconstruídos, não o esqueleto cru)

O Gherkin de `01-analise.md` §4 ficou com placeholders `<...>`. Os valores abaixo vêm de
`comentarios-do-card.md` (P1) e da tabela R1–R5 de `03-design.md` §2:

- Objeto: `Lancamento_de_Atividades__c`. Status Geral = `Status__c`. Status secundários =
  `Status_de_aprovacao_1/2/3__c` (conforme `Qtd_de_executores__c`).
- R1 — algum secundário em uso = `Pendente - Gerente de projetos` → geral = `Pendente -
  Gerente de projeto`.
- R2 — todos os secundários em uso = `Aprovado` → geral = `Aprovado`.
- R3 — algum secundário em uso = `Pendente - Preenchimento do executor` → geral =
  `Pendente - Preenchimento do(s) executor(es)`.
- R4 — algum secundário em uso = `Rejeitado` (nenhum dos casos acima) → geral = `Pendente -
  Preenchimento do(s) executor(es)`. **Esta é a regra L1, proposta do agente, ainda não
  confirmada pelo cliente/arquiteto no gate.** Os casos CT-07/CT-08/CT-09 abaixo testam o
  comportamento *implementado*, não uma regra homologada — se o humano não confirmar R4 como
  correta, o resultado "esperado" desses casos muda e o teste precisa ser refeito.
- R5 — nenhum dos casos acima (ex.: todos `Rascunho`, `Qtd_de_executores__c` vazio) → geral
  não é alterado pelo flow (idempotência).
- Avaliação em cascata R1→R2→R3→R4; primeira que bater decide.

---

## 3. Matriz de testes — roteiro escrito (não executado nesta sessão)

Pré-requisito comum, a cargo do humano antes de rodar qualquer linha: atribuir o permission
set `Lancamento_de_atividades_admin` (ou equivalente com FLS nos campos de 3 executores) a
um usuário de teste que também seja submissor/aprovador dos approval processes
`Fluxo_de_aprovacao_1/2/3_executor`; criar Projeto → Marco → LAT sintéticos (sem dado real de
cliente).

| Caso | Passos | Esperado | Status |
|---|---|---|---|
| CT-03 — Caminho feliz, Qtd 1 | Criar LAT Qtd=1; executor 1 preenche horas e envia; GP aprova via approval process | `Status__c` vai de `Pendente - Preenchimento do(s) executor(es)` → `Pendente - Gerente de projeto` (submissão) → `Aprovado` (R2, flow v5) | Roteiro — não executado |
| CT-04 — Caminho feliz, Qtd 2 | Igual, com 2 executores, ambos aprovados em sequência | Geral vira `Aprovado` só depois do 2º aprovado (R2); entre o 1º e o 2º, geral deve voltar para `Pendente - Preenchimento do(s) executor(es)` (R3, pois o 2º ainda está "Pendente - Preenchimento do executor") | Roteiro — não executado. **Este caso valida o conserto central da demanda** (recon §3: "GP aprova um executor e ainda há executor pendente → falha hoje") |
| CT-05 — Caminho feliz, Qtd 3 | Igual, com 3 executores | Mesmo padrão de CT-04, estendido para 3 posições; geral só `Aprovado` quando os 3 estiverem `Aprovado` (R2) | Roteiro — não executado |
| CT-06 — Aprovação parcial, restante pendente (R1) | Qtd 2 ou 3; GP aprova 1 executor enquanto outro ainda está em `Pendente - Gerente de projetos` (ex.: 2 executores enviaram ao mesmo tempo) | Geral = `Pendente - Gerente de projeto` enquanto houver algum secundário em `Pendente - Gerente de projetos` (R1 tem prioridade sobre R3) | Roteiro — não executado |
| CT-07 — Rejeição parcial (R4) — **regra não confirmada (L1)** | Qtd 2 ou 3; GP rejeita 1 executor, os demais seguem em outro estado (nenhum em Pendente-GP) | Pela implementação atual: geral = `Pendente - Preenchimento do(s) executor(es)` (R4). **Sinalizar explicitamente ao homologador que este é o ponto que precisa de confirmação de negócio antes de aceitar o resultado como correto** | Roteiro — não executado. Resultado esperado é condicional à confirmação de L1 |
| CT-08 — Borda Qtd=1, secundário único vazio/Rascunho | LAT recém-criado, Qtd=1, secundário 1 = `Rascunho`, geral = `Rascunho` | R5: flow não altera o geral (nenhum dos R1–R4 bate) | Roteiro — não executado |
| CT-09 — Borda `Qtd_de_executores__c` vazio | LAT sem Qtd preenchida | R5: flow não altera o geral (fórmula não entra em nenhum ramo de Qtd 1/2/3) | Roteiro — não executado |
| CT-10 — Negativo: validation rule `Checa_preenchimento_unitario_do_executor` (T5) | Registro com mais de uma posição com horas preenchidas e não aprovada, update feito via usuário comum | Confirmar que o Update Records do flow v5 **não é bloqueado** pela VR porque o flow roda em contexto de sistema (conforme `03-design.md` §7); se bloquear, é achado novo a reportar | Roteiro — não executado |
| CT-11 — Permissão/FLS nos 3 executores (T2/§7) | Comparar FLS de `Status_de_aprovacao_N__c`, `Qtd_de_executores__c`, `Executor_da_atividade_N__c` entre perfis (`Lancamento_de_atividades_admin`, `_gerente_de_projetos`, `_analista`, "Diretor de Projetos") | Perfis/PS batem com o que `02-recon.md` §1 e §5 documentam (edição restrita a admin/GP; leitura mais ampla); nenhuma regressão de FLS causada pela v5 do flow (o flow não altera FLS, roda em contexto de sistema) | Roteiro — não executado. Pode ser conferido só com `sf` CLI (describe/PermissionSet), sem precisar de UI — candidato a rodar ainda em dev se/quando a FLS for concedida |
| CT-12 — Auto aprovação do GP concorrendo no mesmo save (mitigação de T1) | Qtd 2/3; disparar `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` (grava secundário fora do approval process) de forma que ele rode no mesmo save que `Atualiza_o_status_final_...` | Geral calculado corretamente mesmo sem `triggerOrder` (mitigação: cálculo idempotente sobre `$Record` final + save recursivo corrige, conforme `04-plano-build.md` §3) — **este é o caso mais importante para fechar T1**, já que a mitigação primária (ordem determinística) não pôde ser deployada | Roteiro — não executado. Risco T1 permanece **sem confirmação prática** até este caso rodar |
| CT-13 — Disparo do flow pelo field update do approval process (T3) | Submeter e aprovar/rejeitar via approval process real (`Fluxo_de_aprovacao_N_executor`), confirmar que o after-save Update do secundário dispara `Atualiza_o_status_final_...` v5 | Flow dispara e recalcula o geral logo após a ação do approval, sem precisar de um segundo save manual | Roteiro — não executado. Risco T3 permanece **sem confirmação prática**; é pré-requisito para aceitar CT-03 a CT-07 como válidos em produção |
| CT-14 — Volume | N/A | A fórmula roda por registro, sem SOQL, sem lote — `03-design.md` §6 já descarta impacto de volume. Dev tem 0 registros do processo LAT (`02-recon.md` §4) e não há indício de operação em massa nesta demanda | **Não aplicável** — registrado o porquê, não testado como caso de carga |

---

## 4. O que fica explicitamente fora desta rodada de QA

- **Correção retroativa de registros já divergentes** (`03-design.md` §9, T6): fora de
  escopo da demanda; não há caso de teste para isso aqui.
- **Paridade dev × produção** (T2, D1/D2 de `02-recon.md`): o agente não acessa produção;
  fica para o humano comparar a versão ativa do flow e os flows de "Somatória" antes de
  promover.
- **UI Lightning**: não testada nesta sessão por falta de `sbx-somos-agility-qa` conectada.
  Quando a sandbox conectar, os casos CT-03 a CT-13 podem ser repetidos também via
  `qa_browser_*` para evidência de tela (telas do LAT: preenchimento de horas pelo executor,
  aprovação pelo GP), sempre com dado sintético criado para o teste — nunca registro real.

---

## 5. Resumo

- **Executado nesta sessão, em `sbx-somos-agility-dev`:** confirmação de metadata (v5 Active,
  v4 Obsolete — CT-00/CT-01) e confirmação de que o bloqueio de FLS para massa de teste
  continua valendo (CT-02, bloqueado).
- **Não executado — roteiro para humano rodar em `sbx-somos-agility-qa`** (ou em dev, se o
  humano decidir conceder FLS antes): CT-03 a CT-13, que são os casos que de fato validam a
  regra de negócio e os riscos T1/T3/T5/L1.
- Nenhum dos critérios de aceite centrais da demanda (consolidação do Status Geral em
  aprovação parcial e em rejeição) foi validado de ponta a ponta nesta sessão. O que existe
  de garantia até aqui é: a fórmula foi simulada fora da plataforma (`04-plano-build.md` §6)
  e o XML foi aceito e ativado pelo deploy — não que o comportamento em tela está correto.

Testes executados. Preciso da sua homologação para liberar o release.
