# SOMOSAGILITY-18 — Testes (QA)

## Resultado em uma frase

**Nenhum roteiro de teste foi executado.** Não há metadata construído ou alterado nesta
demanda para validar. O build está bloqueado desde a etapa anterior (`04-plano-build.md`)
e esta sessão de QA confirmou, de forma independente, que isso continua verdadeiro.

## Falhas / bloqueios (reportados primeiro)

| # | Bloqueio | Evidência |
|---|---|---|
| 1 | Não existe build para testar | `04-plano-build.md` declara explicitamente "BUILD BLOQUEADO. Nenhum metadata foi criado ou alterado", com justificativa nas seções "Por que está bloqueado" e "O que NÃO foi feito nesta sessão" |
| 2 | Confirmado por diff: a branch da demanda não toca `force-app` | `git diff origin/main origin/feature/SOMOSAGILITY-18 --stat -- force-app` retornou vazio (0 arquivos). O diff completo entre as branches só contém artefatos de demanda (`.md`, `status.yaml`, `gates.md`), CSVs de custo em `logs/custos_agentes/` e mudanças em outras demandas/testes não relacionadas a esta — nada em `force-app` |
| 3 | Critérios de aceite de `01-analise.md` estão marcados como BLOQUEADO | Seção 4 de `01-analise.md`: 4 dos 5 cenários Gherkin trazem a tag `# BLOQUEADO` explícita, condicionados às respostas da seção 5 (perguntas 1–10), nenhuma delas respondida até o momento |
| 4 | Design trava o build até diagnóstico humano em produção | `03-design.md`, seção 3: "Este design não escolhe uma causa sem evidência" entre as hipóteses H1–H4; o diagnóstico depende de um humano com acesso a produção abrir o marco `a0zU400000ASbVAIA1` e responder 4 perguntas de sinal no registro — fora do alcance do agente (guardrail de produção) |

## Verificação que esta sessão executou

Comando rodado (sem acesso a nenhuma org, só ao repositório):

```
git fetch origin main feature/SOMOSAGILITY-18
git diff origin/main origin/feature/SOMOSAGILITY-18 --stat -- force-app
```

Resultado: nenhuma linha — zero arquivos alterados em `force-app` entre `main` e
`feature/SOMOSAGILITY-18`. Isso confirma, de forma independente das declarações do agente
de build, que não existe nenhuma mudança de metadata Salesforce (Flow, Apex, fórmula,
validation rule) nesta demanda para exercitar em sandbox de QA.

O diff completo (sem restringir a `force-app`) mostra apenas os artefatos das etapas 1–4
desta demanda (`01-analise.md`, `02-recon.md`, `03-design.md`, `04-plano-build.md`,
`gates.md`, `status.yaml`), CSVs de telemetria de custo (`logs/custos_agentes/`), e
alterações em arquivos de outras demandas (`SOMOSAGILITY-8`, `-19`, `-20`) e de testes do
orquestrador que não pertencem ao escopo desta demanda e não foram investigadas aqui por
não serem objeto desta etapa de QA.

## Por que não dá para fabricar um roteiro

Qualquer cenário de teste de UI ou de verificação em sandbox de QA pressupõe uma correção
aplicada (campo recalculado de outra forma, Flow com nova versão, classe Apex alterada,
validação nova). Como nenhuma das quatro opções de correção mapeadas em `03-design.md`
(seção 4 — H1 configuração, H2 configuração/fórmula, H3 Flow, H4 nenhum build) foi
implementada, não existe comportamento novo para comparar contra um "esperado". Testar o
estado atual da org contra os critérios de aceite também não é válido: os próprios
critérios (seção 4 de `01-analise.md`) estão marcados como bloqueados até resposta do
cliente, então não há "esperado" definido para confrontar.

Não foi aberta sessão de navegador (`qa_browser_*`) nem feita nenhuma consulta à org do
cliente nesta etapa — não há tela nem registro específico desta correção para visitar, e
abrir o registro do chamado em produção para "ver se bate" está fora do guardrail de
produção e não é tarefa do agente de QA.

## Critérios de aceite: cobertura possível hoje

| Critério (de `01-analise.md`, seção 4) | Testável nesta sandbox hoje? |
|---|---|
| Marco soma somente as HNC que pertencem a ele | Não — BLOQUEADO na análise, depende da pergunta 2 da seção 5 |
| Apontamento que não é HNC não entra na soma | Não — BLOQUEADO, depende de confirmar se "comercial" é a classificação excluída |
| Duplicidade não infla o total | Não — BLOQUEADO, depende de confirmar se há duplicidade de fato |
| Outros marcos e projetos não mudam | Não aplicável agora — é teste de não regressão de uma correção que ainda não existe; não há "antes/depois" para comparar |
| Valor corrigido é reconciliado com a fonte | Não — BLOQUEADO, depende das perguntas 1 e 2 |
| Marco continua exibindo o campo de HNC sem erro, nenhum registro apagado/alterado fora do cálculo | Não aplicável — nada foi alterado nesta demanda, logo nada há para verificar que não foi corrompido |

Nenhum dos critérios de aceite é testável na sandbox atual, porque nenhum deles deixou de
ser provisório (todos dependem de respostas ainda não dadas pelo cliente/consultor) e
porque não existe build a validar.

## Recomendação

A demanda não deveria ter avançado para QA sem o diagnóstico prévio que o próprio design
exige. Recomenda-se:

1. Devolver a demanda para uma nova rodada de análise/design (ou, no mínimo, suspender o
   avanço de estágio) até que um humano com acesso à produção:
   - Responda as 4 perguntas de diagnóstico da seção 3 de `03-design.md` (sinal no registro
     do marco `a0zU400000ASbVAIA1` que confirma ou descarta H1, H2, H3 ou H4), e
   - Responda as perguntas 1, 2 e 3 da seção 5 de `01-analise.md` (valor esperado, quais
     horas devem entrar, o que está inflando o valor) — já listadas em `04-plano-build.md`
     como as que bloqueiam o build.
2. Só depois de uma hipótese confirmada (H1–H4), reabrir o build: a correção correspondente
   já está decidida em `03-design.md`, seção 4, e não deveria exigir novo gate de design
   (a menos que a causa real caia fora de H1–H4, caso em que o próprio design prevê voltar
   para revisão).
3. Repetir a etapa de QA somente quando houver metadata de fato alterado em `force-app`
   para comparar contra os critérios de aceite (que também precisarão ser reescritos sem
   as tags `# BLOQUEADO`, já com a definição confirmada de "correto").

## Nota sobre dado pessoal

Esta etapa não consultou o anexo PDF além do que já constava em `demanda.md` e nos
artefatos anteriores. Nenhum dado pessoal (nome, telefone, e-mail) do anexo foi transcrito
aqui, conforme guardrail de dado pessoal/LGPD.

---

Testes executados. Preciso da sua homologação para liberar o release.
