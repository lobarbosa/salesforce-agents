# SOMOSAGILITY-7 — Testes (QA) — rodada em `sbx-somos-agility-qa`

**Cliente:** somos-agility · **Data:** 2026-10-30
**Entradas:** `01-analise.md` (Gherkin-esqueleto), `comentarios-do-card.md` (P1/P2/P3),
`02-recon.md`, `03-design.md` (tabela R1–R5, riscos T1–T7, lacuna L1), `04-plano-build.md`
(v5 do Flow, desvio do `triggerOrder`, bloqueio de FLS em dev), rodada anterior deste
documento (testada só em dev, revertida duas vezes — ver `status.yaml`).

Este documento **substitui inteiramente** a rodada anterior de `05-testes.md` (não é um
acréscimo). A rodada anterior ficou obsoleta: foi feita contra `sbx-somos-agility-dev`
porque `sbx-somos-agility-qa` não conectava. Desta vez `sbx-somos-agility-qa` está
conectada e foi usada em tudo abaixo.

---

## 0. Estado do ambiente nesta sessão (verificado antes de qualquer teste)

### 0.1 Org conectada

```
sf org list
```

retornou **apenas** `sbx-somos-agility-qa` — `Sandbox`, `Connected`, `isSandbox: true`,
Enterprise Edition, instância `BRA8S`. `sbx-somos-agility-dev` **não aparece** nesta sessão
(o inverso da rodada anterior). Todos os comandos abaixo usaram
`--target-org sbx-somos-agility-qa`.

### 0.2 Ponto crítico — a v5 do Flow está ativa em QA: CONFIRMADO

```
sf data query --use-tooling-api --query "SELECT Id, VersionNumber, Status, ProcessType,
Definition.DeveloperName FROM Flow WHERE Definition.DeveloperName =
'Atualiza_o_status_final_de_aprovacao_do_LAT' ORDER BY VersionNumber"
```

| Versão | Status | Id |
|---|---|---|
| 1 | Obsolete | `301U400000j5zaZIAQ` |
| 2 | Obsolete | `301U400000jvkx6IAA` |
| 3 | Obsolete | `301U400000lNyq8IAC` |
| 4 | Obsolete | `301U400000lNFgEIAW` |
| **5** | **Active** | `301Ha000014rLOdIAM` |

A `Description` da v5 em QA foi lida via Tooling API e bate, palavra por palavra, com o
comportamento descrito em `04-plano-build.md` §2 (cita `SOMOSAGILITY-7`, cobre aprovação
parcial, aprovação total e rejeição, e a condição "só grava quando o valor calculado é não
vazio e diferente do atual"). **Isto resolve o bloqueio que motivou a segunda devolução**
("a correção ainda pode não existir em QA"): ela existe e está ativa.

### 0.3 Como a v5 chegou a QA não está documentado em nenhum artefato desta demanda

Isto precisa ser dito com todas as letras, porque não bati o olho nisso por acaso: o
`06-entrega.md` gravado em 2026-10-28 (commit `e82f842c`) afirma explicitamente **"Deploy em
QA: não houve. Nenhum dry-run e nenhum deploy real contra QA. Não existe Deploy ID de QA."**
E o histórico de `status.yaml` entre a segunda devolução (2026-10-30 01:23, "volta para a
revisão do PR") e a reaprovação do gate (2026-10-30 02:43) não registra nenhuma etapa
`build` ou `release` rodando entre essas duas datas — o gate foi reaprovado e a demanda foi
direto para `qa`. **Não existe, nos artefatos desta demanda, um release documentado que
explique o deploy da v5 em `sbx-somos-agility-qa`.**

Não vou inventar uma explicação para essa lacuna (guardrail #3). O que posso afirmar com
confiança, porque medi agora: a v5 está de fato ativa em QA, o conteúdo bate com o que foi
desenhado e construído, e o deploy (seja lá quando/por quem tenha acontecido — possivelmente
fora do fluxo automatizado, usando o pacote que `06-entrega.md` já deixou pronto em
"Comandos prontos para rodar assim que `sbx-somos-agility-qa` conectar") é sintaticamente
equivalente ao que `04-plano-build.md` deployou em dev. Sinalizo isto ao humano como um gap
de rastreabilidade a esclarecer antes do release formal — não como um erro desta rodada de
QA, mas como algo que quem aprova o release vai querer saber.

### 0.4 Novo achado: o bloqueio de FLS que impediu testar em dev também existe em QA

Com a v5 confirmada ativa, seria o momento de criar massa sintética e rodar a matriz
funcional via `qa_browser_*`, como esta tarefa pede. **Não foi possível.** O mesmo bloqueio
de FLS registrado em `02-recon.md` §1 e reproduzido em `04-plano-build.md` §6 (em dev)
**se repete em QA, com o mesmo usuário e a mesma causa raiz**:

- `sf sobject describe --sobject Lancamento_de_Atividades__c` para o usuário conectado
  nesta sessão em `sbx-somos-agility-qa` (perfil "Administrador do sistema") **não retorna**
  `Status_de_aprovacao_1/2/3__c`, `Qtd_de_executores__c` nem `Executor_da_atividade_1/2/3__c`
  — os mesmos campos que em dev davam `INVALID_FIELD`.
- Consulta a `FieldPermissions` confirma que esses campos só têm FLS concedida pelos
  permission sets `Lancamento_de_atividades_admin`, `_gerente_de_projetos` e `_analista` —
  nenhum perfil concede FLS neles (igual ao recon).
- Consulta a `PermissionSetAssignment` do usuário conectado mostra que ele **não tem
  nenhum dos três** atribuído — só o permission set automático gerado pelo próprio perfil.
  Contagem agregada (sem nomes de usuário, guardrail #2) de quem **tem** cada um atribuído
  em QA: `Lancamento_de_atividades_admin` = 2, `_gerente_de_projetos` = 10, `_analista` = 1 —
  ou seja, existem usuários corretamente configurados em QA, só não é o usuário desta sessão.
- **Confirmado também na UI**, não só na API: abri `sbx-somos-agility-qa` via
  `qa_browser_open` em `/lightning/o/Lancamento_de_Atividades__c/list` (lista com 0 registros,
  batendo com `02-recon.md` §4) e cliquei em "Criar". O formulário de criação (print tirado
  como evidência, sem nenhum dado de cliente — registro nunca chegou a ser salvo) mostra
  **apenas** os campos `Marco`, `Nome da atividade`, `Descrição da atividade` e `Status`.
  Nenhum campo do modelo de 3 executores aparece no layout de criação para este usuário —
  consistente com a ausência de FLS, não com uma opção do layout.

Por `03-design.md` §7, atribuir o permission set é **decisão do humano**, não do agente —
não fiz essa atribuição, mesmo sendo tecnicamente possível com o acesso desta sessão.

**Consequência prática:** mesmo com a v5 confirmada ativa, **a validação funcional de ponta
a ponta (os critérios de aceite centrais da demanda) continua impossível nesta sessão** —
agora por um motivo diferente do das duas rodadas anteriores (antes era "QA não conecta" ou
"QA só tinha o build antigo"; agora é "FLS do usuário conectado"), mas o efeito é o mesmo:
ninguém testou de fato se o Status Geral se comporta como a tabela R1–R5 prevê.

### 0.5 Achados adicionais de ambiente (parity dev × QA, via metadata, sem dado de negócio)

| Item | Dev (recon, 2026-10-21) | QA (esta sessão) | Conclusão |
|---|---|---|---|
| Validation rules ativas no objeto | 8 ativas / 4 inativas (nomes listados em `02-recon.md`) | Mesmas 8 ativas / 4 inativas, nomes idênticos | Parity confirmada |
| `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` | v5 Active | v5 Active | Parity confirmada |
| `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` | Active | v1 Active | Parity confirmada |
| `Subtrai_Horario_de_Almoco` | Active | v1 Active | Parity confirmada |
| Approval processes no objeto | `Fluxo_de_aprovacao_1/2/3_executor` (ativos) + `Solicitacao_de_aprovacao_para_atividade` (legado) | Mesmos 4 nomes presentes (`sf org list metadata --metadata-type ApprovalProcess`) | Presença confirmada; **estado ativo/inativo de cada um não reconfirmado nesta sessão** (a listagem de metadata não traz essa flag; exigiria retrieve completo do XML, não feito por não mudar o resultado da matriz de testes) |
| `COUNT()` em `Lancamento_de_Atividades__c` | 0 | 0 | Igual |
| `COUNT()` em `Executor_atividade__c` | 0 | 0 | Igual |
| `COUNT()` em `Marcos__c` | 0 | **6639** | **Divergente.** QA não é uma cópia vazia como dev — tem uma massa de `Marcos__c` pré-existente. Nenhum campo de negócio foi lido (só `COUNT()`), mas isso importa para quem for montar massa sintética depois: crie um `Marcos__c` novo e isolado para o teste, não reaproveite nem toque nos existentes. |

T1 (risco de ordem entre os 4 flows after-save ativos + Process Builder) e T2 (paridade
dev × produção, que o agente não pode verificar) seguem exatamente como `03-design.md` os
registrou — nada nesta sessão muda a severidade deles, porque nenhum deles foi exercitado
com dado de verdade.

---

## 1. Resultados (falhas e bloqueios primeiro)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| **AMB-02** | `sf sobject describe` + tentativa de "Criar" via UI em `Lancamento_de_Atividades__c`, usuário da sessão conectada em `sbx-somos-agility-qa` | Campos `Qtd_de_executores__c` e `Status_de_aprovacao_1/2/3__c` visíveis/editáveis para montar massa de teste | Campos ausentes do describe e do layout de criação (FLS). Usuário sem nenhum dos 3 permission sets de LAT atribuído | **Bloqueado (ambiente/permissão)** — idêntico ao bloqueio de `02-recon.md`/`04-plano-build.md`, agora reproduzido em QA, não em dev |
| **CT-03 a CT-13** | Matriz de regras de negócio (R1–R5, T1, T3, T5, L1) — ver §3 | Validar que `Status__c` reflete os secundários conforme a tabela do design | **Não executados nesta sessão** — seguem como roteiro para humano. A causa deixou de ser "sandbox de QA ausente" e passou a ser "FLS do usuário de teste", mas o efeito é o mesmo: nenhuma validação funcional de ponta a ponta aconteceu ainda, em nenhuma das três rodadas desta demanda | **Não executado (roteiro)** |
| **AMB-00** | Tooling API: versões do Flow `Atualiza_o_status_final_de_aprovacao_do_LAT` em QA | v5 `Active`, v1–v4 `Obsolete` | Confirmado exatamente assim (Id da v5: `301Ha000014rLOdIAM`) | **Passou** |
| **AMB-01** | Conferir `Description` da v5 em QA contra `04-plano-build.md` §2 | Texto consistente com o que foi construído | Bate integralmente (cita SOMOSAGILITY-7, R1/R2/R4, idempotência) | **Passou** |
| **AMB-03** | Rastreabilidade: como/quando a v5 chegou a QA | Deploy documentado em `06-entrega.md` ou em novo artefato de release | **Não há registro.** `06-entrega.md` de 28/10 afirma expressamente que não houve deploy em QA; não há etapa `build`/`release` registrada em `status.yaml` entre a 2ª devolução e agora | **Achado a esclarecer** (não é um "teste" no sentido de passar/falhar — é uma lacuna de rastreabilidade que quem aprova o release vai querer entender) |
| **AMB-04** | Parity de metadata dev × QA (validation rules, flows concorrentes, approval processes, volume) | Ambiente de QA equivalente ao que `02-recon.md` descreveu em dev | Validation rules e flows concorrentes idênticos; approval processes presentes (estado ativo não reconfirmado); `Marcos__c` tem 6639 registros em QA contra 0 em dev | **Passou, com uma divergência de volume registrada (não bloqueia, mas orienta a massa de teste)** |

---

## 2. Critérios de aceite usados como base (sem mudança desde a rodada anterior)

Reconstruídos de `comentarios-do-card.md` (P1) e `03-design.md` §2 — nenhuma lacuna nova
desde a última rodada:

- Objeto: `Lancamento_de_Atividades__c`. Status Geral = `Status__c`. Status secundários =
  `Status_de_aprovacao_1/2/3__c` (conforme `Qtd_de_executores__c`).
- R1 — algum secundário em uso = `Pendente - Gerente de projetos` → geral = `Pendente -
  Gerente de projeto`.
- R2 — todos os secundários em uso = `Aprovado` → geral = `Aprovado`.
- R3 — algum secundário em uso = `Pendente - Preenchimento do executor` → geral =
  `Pendente - Preenchimento do(s) executor(es)`.
- R4 — algum secundário em uso = `Rejeitado` (nenhum dos casos acima) → geral = `Pendente -
  Preenchimento do(s) executor(es)`. **Ainda é proposta do agente (L1), não confirmada pelo
  cliente/arquiteto.** Continua sem confirmação porque nenhuma rodada de QA chegou a validar
  nem sequer o comportamento implementado (ver §0.4).
- R5 — nenhum dos casos acima → geral não é alterado (idempotência).
- Avaliação em cascata R1→R2→R3→R4; primeira que bater decide.

---

## 3. Matriz de testes funcionais — continua roteiro (não executado nesta sessão)

**Pré-requisito único e bloqueante para esta matriz rodar**, agora que a v5 está confirmada
ativa em QA: atribuir o permission set `Lancamento_de_atividades_admin` (ou outro com FLS
nos campos de 3 executores) a um usuário de teste em `sbx-somos-agility-qa` que também seja
submissor/aprovador dos approval processes `Fluxo_de_aprovacao_1/2/3_executor` — e então
criar um `Marcos__c`/LAT sintéticos **novos**, isolados dos 6639 `Marcos__c` já existentes em
QA (achado §0.5). Isso é decisão/execução do humano (`03-design.md` §7); o agente de QA não
a fez.

| Caso | Passos | Esperado |
|---|---|---|
| CT-03 — Caminho feliz, Qtd 1 | LAT Qtd=1; executor preenche e envia; GP aprova via approval process | `Status__c`: Pendente - Preenchimento → Pendente - Gerente de projeto (submissão) → Aprovado (R2) |
| CT-04 — Caminho feliz, Qtd 2 | 2 executores aprovados em sequência | Geral só vira Aprovado depois do 2º; entre o 1º e o 2º volta para Pendente - Preenchimento (R3) — **valida o conserto central da demanda** |
| CT-05 — Caminho feliz, Qtd 3 | 3 executores | Mesmo padrão de CT-04, estendido |
| CT-06 — Aprovação parcial, restante pendente (R1) | Qtd 2/3; GP aprova 1 enquanto outro segue em Pendente - Gerente de projetos | Geral = Pendente - Gerente de projeto (R1 tem prioridade sobre R3) |
| CT-07 — Rejeição parcial (R4, regra não confirmada — L1) | Qtd 2/3; GP rejeita 1 executor | Pela implementação: geral = Pendente - Preenchimento. **Sinalizar ao homologador que este é o ponto que precisa confirmação de negócio** |
| CT-08 — Borda Qtd=1, secundário em Rascunho | LAT recém-criado | R5: geral não muda |
| CT-09 — Borda `Qtd_de_executores__c` vazio | LAT sem Qtd preenchida | R5: geral não muda |
| CT-10 — Negativo: `Checa_preenchimento_unitario_do_executor` (T5) | Update do flow em registro com mais de 1 posição pendente | Update do flow v5 não é bloqueado pela VR (roda em contexto de sistema) |
| CT-11 — FLS por perfil/permission set | Comparar FLS entre `_admin`, `_gerente_de_projetos`, `_analista` e perfis | **Parcialmente coberto nesta sessão** (§0.4): confirmado que nenhum perfil concede FLS, só os 3 permission sets — mas não comparado campo a campo entre os três permission sets como a rodada anterior planejava |
| CT-12 — Auto aprovação do GP concorrendo no mesmo save (T1) | `Fluxo_de_auto_aprovacao_...` grava secundário no mesmo save que `Atualiza_o_status_final_...` | Geral correto mesmo sem `triggerOrder` (mitigação por idempotência) — **caso mais importante para fechar T1** |
| CT-13 — Disparo pelo approval process (T3) | Aprovar/rejeitar via approval process real | Flow v5 dispara e recalcula sem segundo save manual |
| CT-14 — Volume | N/A | Fórmula roda por registro, sem SOQL/lote; não aplicável como teste de carga (reafirmado, agora com `Marcos__c`=6639 em QA — ainda não é volume relevante para esta correção pontual) |

---

## 4. O que fica explicitamente fora desta rodada de QA

- **Correção retroativa de registros já divergentes** (`03-design.md` §9, T6): fora de
  escopo; sem caso de teste aqui.
- **Paridade dev × produção além do que §0.5 cobriu** (T2): o agente não acessa produção.
- **Quem/quando deployou a v5 em QA** (§0.3): não é testável por mim — é uma pergunta para
  quem orquestra o release, não um critério de aceite.
- **Estado ativo/inativo de cada approval process em QA**: presença confirmada, estado
  específico não (ver AMB-04).

---

## 5. Resumo

- **Progrediu de fato nesta rodada:** a v5 do Flow está confirmada **ativa em
  `sbx-somos-agility-qa`** (não mais só em dev), com conteúdo batendo com o que foi
  desenhado e construído. Isso resolve a razão da segunda devolução.
- **Não progrediu:** nenhum critério de aceite central (a consolidação do Status Geral em
  aprovação parcial e em rejeição — o motivo da demanda existir) foi validado de ponta a
  ponta em nenhuma das três rodadas de QA até agora. Desta vez o impeditivo é FLS do usuário
  de teste em QA, não a ausência da sandbox nem a ausência do deploy.
- **Risco T1 (ordem de execução) e T3 (disparo pelo approval process) seguem sem
  confirmação prática.** R4/L1 segue sem confirmação de negócio.
- **O que falta, especificamente, antes de qualquer homologação fazer sentido:** o humano
  (ou um agente autorizado a fazê-lo) precisa (a) atribuir FLS/permission set a um usuário de
  teste em QA, (b) esclarecer como a v5 chegou a QA sem um release documentado (§0.3), e só
  então (c) rodar de fato a matriz do §3 com massa sintética nova. Sem isso, "homologar" seria
  aprovar a mesma coisa que já foi aprovada e revertida duas vezes: a aparência de pronto sem
  a prova.

Testes executados. Preciso da sua homologação para liberar o release — mas registro, para
que a decisão seja informada: a homologação possível hoje é a de **ambiente** (a correção
está implantada e ativa em QA, com paridade de metadata confirmada), não a de
**comportamento** (ninguém ainda viu o Status Geral se recalcular corretamente num cenário
real de aprovação parcial ou rejeição). Se "homologação" aqui significa a segunda, o bloqueio
de FLS em §0.4 precisa ser resolvido primeiro.
