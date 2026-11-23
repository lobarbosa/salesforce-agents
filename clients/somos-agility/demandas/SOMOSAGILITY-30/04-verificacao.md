**Verificação:** aprovada
**Org de teste:** `sbx-somos-agility-dev`

# 04 — Verificação (rodada 3): SOMOSAGILITY-30

Org conferida com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected). QA e produção não tocadas. Nenhuma alteração em usuário, perfil ou permission set; nenhum dado externo acionado.

## Retesto da falha da rodada 2

| Falha anterior | Situação |
|---|---|
| FALHA 1: teste de carga falhava por CPU de forma intermitente | **Corrigida.** O método agora é `testBulk50SolicitacoesMudandoDeEtapa` (50 SR em 10 projetos, 5 por projeto, uma DML com várias SR). Passou na suíte completa e em 2 execuções isoladas (21,2 s, 20,6 s, 20,3 s), sem falha de CPU. A prova de bulk segue válida: uma única DML com 50 SR de uma vez, com assert de 0 na transição pendente e soma em `Aprovado`. A carga de 200 SR deixou de ser testada em unidade; o limite de CPU do produto (decisão (a)) é medido pelo caso de volume V2. |

## Versão do Flow na dev

Consulta Tooling por DeveloperName `Atualiza_valor_total_de_despesas_realizadas_no_projeto`: v11 **Active**, v10 Obsolete, v9 Obsolete, v8 Obsolete. Conforme o plano (a verificação 1 ativou a v11 na dev). Nada foi ativado ou desativado nesta rodada. Filtro da v11 no XML: `Relacionado_ao_Projeto__c` e `Status_da_SR__c` (um único status de SR, `Aprovado`).

## Casos

Run de teste `707Ha00001F4L3G`, 12 de 12 Pass, 100%, `sf apex run test --code-coverage`.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 `testInclusaoAoAprovarPeloGP` | CA-01, CA-02, CA-03 | Suíte `SolicitacaoReembolsoBOTest` | 0 nas etapas pendentes, soma só em Aprovado | Pass | passou |
| T2 `testExclusaoAoRejeitar` | CA-04 | idem | Rejeitado mantém/zera total | Pass | passou |
| T3 `testExclusaoAoRecolher` | CA-05 | idem | Recall zera | Pass | passou |
| T4 `testProjetoSemLancamentoElegivelTotalZero` | CA-07 | idem | Total 0 | Pass | passou |
| T5 `testVariosLancamentosMesmoProjeto` | CA-09 | idem | Soma só das SR aprovadas | Pass | passou |
| T6 `testLancamentoSemProjetoNaoAlteraProjeto` | CA-08 | idem | Nenhum projeto alterado | Pass | passou |
| T7 `testQuilometragemAprovadaSomaValorDaKilometragem` | CA-10 | idem | Soma `Valor_da_Kilometragem__c` | Pass | passou |
| T8 `testBulk50SolicitacoesMudandoDeEtapa` | bulk (CA-01/02) | Suíte completa e 2 execuções isoladas | Pass sempre | 3 Pass | passou |
| T9 a T12 `SolicitacaoReembolsoTriggerHandlerTest` (4 métodos) | regressão re-save e trava de recursão | Suíte | Pass | 4 Pass | passou |
| V1 volume, pré-condição | CA-09 | Apex anônimo `fixtures/lancamento-volume-setup.apex` (SR A Aprovado 3x10, SR B Pendente - Gestor 150x1, mesmo projeto) | Projeto criado | Criado (ids sintéticos) | passou |
| V2 volume, transição | design seção 6, decisão (a) | Outra execução de Apex anônimo: SR B para `Aprovado`, bypass do handler de projeto, `Limits` na mesma transação | Total 180; CPU registrada | Total do projeto 180. CPU **9159** de 10000 ms, SOQL 8/100, DML 9/150. Histórico: 10521 (rodada 1), 8311 e 8913 (rodada 2) | passou (dentro do limite desta vez; variação entre 8,3 s e 10,5 s confirma que o pior caso fica perto do teto, aceito pela decisão (a)) |
| N1 cobertura | meta 85% por classe | `ApexCodeCoverageAggregate` depois da suíte | >= 85% | `SolicitacaoReembolsoBO` 18/19 (94,7%), `SolicitacaoReembolsoTriggerHandler` 11/11 (100%), `LancamentoDespesasBO` 14/16 (87,5%), `LancamentoDespesasTriggerHandler` 4/4 (100%), `TrgSolicitacaoReembolso` 1/1, `TrgLancamentoDeDespesas` 1/1 | passou |
| CA-06 | Aprovado volta atrás | Só CA-04 e CA-05 exercitam Rejeitado e Recall a partir de Aprovado. Outras transições dependem de P5 | — | sem prova adicional | não executado (depende de P5, não bloqueia) |

## Limites e observações

- Risco de CPU: com 150 Lançamentos numa SR indo para `Aprovado` a CPU ficou entre 8,3 s e 10,5 s em 5 medições, uma acima de 10 s. Decisão (a) do responsável aceita isso; vai para o `06-entrega.md`.
- CA-06 sem prova adicional (P5).

## Observação para o revisor do PR (ponto 1)

`git show --stat dc6b69bf` mostra, além dos arquivos da demanda (`04-plano-build.md`, `SolicitacaoReembolsoBOTest.cls`), quatro arquivos que **não são desta demanda**: `src/salesforce_agents/bloqueio.py` (+71, novo), `cli.py` (+13/-1), `fluxo.py` (+17) e `revisao.py` (+17/-1). Não foi revertido nada nem feito force-push; o revisor deve decidir se separa esses arquivos antes do merge.

## Conflito com SOMOSAGILITY-10 (ponto 2)

O preflight lista SOMOSAGILITY-10 (aguardando_homologacao) mexendo em `SolicitacaoReembolsoBOTest`, `SolicitacaoReembolsoTriggerHandlerTest` e no mesmo Flow. Na dev, o comportamento atual (v11 ativa, 12 de 12 testes passando) não mostrou falha entre as duas, mas **não foi testado contra a entrega do SOMOSAGILITY-10**: não comparei a metadata dele. Risco de sobrescrita das mesmas classes de teste e do Flow no merge/deploy; o revisor deve conferir a ordem de entrega e conflitos de merge.

## Dados e limpeza

Dados sintéticos, nome `TESTE SOMOSAGILITY-30`. Nenhuma SOQL devolveu dado real: só metadata, contagens e o total de um projeto sintético. Nenhuma captura de tela. Limpeza: Lançamentos, SRs, projeto, contato e conta de teste apagados por Apex anônimo; consulta posterior: 0 Account e 0 Contact com o prefixo. Não restou job agendado. Nada ficou na dev.

## O que pode ter saído da org

Nada. Sem callout, e-mail ou integração nos testes (handler de projeto desviado por `TriggerHandler.bypass`).
