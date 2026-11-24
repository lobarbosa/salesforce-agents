**Veredito:** aprovado
**Org de teste:** `sbx-somos-agility-qa`

# 05 — Testes na QA: SOMOSAGILITY-30

Org conferida com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected). Produção e dev não tocadas. Nenhuma alteração em usuário, perfil ou permission set.

## Pacote e versão do Flow
`05-deploy-qa.md` (deploy `0AfHa00000EN8KzKAL`, Succeeded): 2 classes de teste e o Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`. Consulta Tooling na QA: v11 **Active**, v10, v9, v8, v7, v6 Obsolete. A v11 já veio ativa no pacote (commit `9d74b3b2`); nada foi ativado ou desativado por mim. Os componentes existem na org.

## Falhas
Nenhuma.

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| Q1 | Regressão | `sf apex run test` nas duas classes de teste (run `707Ha00001F4PrF`) | 12 de 12 Pass | 12 de 12 Pass, 100%. Cobertura: `SolicitacaoReembolsoBO` 95%, `SolicitacaoReembolsoTriggerHandler` 100%, `LancamentoDespesasBO` 88%, `LancamentoDespesasTriggerHandler` 100% | passou |
| E1 | CA-01, CA-03 | Dados sintéticos: projeto com total 0, SR em "Pendente - Gestor" com 2 Lançamentos (100 e 50). SR para "Pendente - Diretor", depois "Pendente - Operações"; consulta do total após cada | 0 | 0 e 0 | passou |
| E2 | CA-02 | SR para "Aprovado" | 150 | 150 | passou |
| E3 | CA-05 | SR de "Aprovado" para "Recall" | 0 | 0 | passou |
| E4 | CA-06 (parcial) | "Recall" de volta para "Aprovado" | 150 | 150 | passou |
| E5 | CA-04 | "Aprovado" para "Rejeitado" | 0 | 0 | passou |
| T-CA08 | CA-08 | `testLancamentoSemProjetoNaoAlteraProjeto` (Q1) | Nenhum projeto alterado | Pass | passou |
| T-CA09 | CA-09 | `testVariosLancamentosMesmoProjeto` (Q1) | Soma só das SRs aprovadas | Pass | passou |
| T-CA07 | CA-07 | `testProjetoSemLancamentoElegivelTotalZero` (Q1) | 0 | Pass | passou |
| T-CA10 | CA-10 | `testQuilometragemAprovadaSomaValorDaKilometragem` (Q1) | Soma a quilometragem | Pass | passou |
| T-bulk | Volume | `testBulk50SolicitacoesMudandoDeEtapa` (Q1) | 0 em pendente, soma em Aprovado | Pass (22,9 s) | passou |
| CA-06 geral | Outras voltas atrás | Dependem de P5 | — | só E3/E4/E5 exercitados | não executado (depende de P5, não bloqueia) |

Observação: a CPU do pior caso (150 Lançamentos numa SR indo a "Aprovado") fica entre 8,3 s e 10,5 s na dev (04-verificacao.md); risco aceito pela decisão (a) do responsável. Não repeti na QA a massa de volume.

## Efeito cruzado com SOMOSAGILITY-10
Nenhum observado: 12 de 12 passam na QA com o pacote atual. Não comparei a metadata da SOMOSAGILITY-10; risco de conflito de merge nas mesmas classes de teste e no Flow segue com o revisor.

## Dados e limpeza
Dados sintéticos `TESTE SOMOSAGILITY-30` (1 conta, 1 contato, 1 projeto, 1 SR, 2 Lançamentos), criados e apagados por Apex anônimo (uma transação por passo, handler de projeto desviado por `TriggerHandler.bypass`). Consulta posterior: 0 Account e 0 projeto com o prefixo. Nenhum dado real lido, nenhuma captura de tela (caso não depende de tela e a sessão de UI não foi usada).

## O que pode ter saído da org
Nada. Sem callout, e-mail ou integração.
