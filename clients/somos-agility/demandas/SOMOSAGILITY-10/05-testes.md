**Veredito:** aprovado
**Org de teste:** `sbx-somos-agility-qa`

# SOMOSAGILITY-10 — Testes na QA

Org confirmada com `sf org list`: `sbx-somos-agility-qa` (Sandbox, Connected, orgId 00DHa000006WcTcMAK). Produção e dev não foram tocadas. Primeira rodada de QA desta demanda (não existe `05-testes-rodada-<n>.md`).

## Falhas
Nenhuma.

## Pacote na org (`05-deploy-qa.md`, deploy 0AfHa00000EIfuIKAT)
- 5 classes (`LancamentoDespesasBOTest`, `SolicitacaoReembolsoBO`, `SolicitacaoReembolsoBOTest`, `SolicitacaoReembolsoTriggerHandler`, `SolicitacaoReembolsoTriggerHandlerTest`) existem, com LastModifiedDate de 2026-11-16 19:24Z (query em `ApexClass`).
- Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`: v10 Active (descrição cita SOMOSAGILITY-10, 27/10/2026), v9 e anteriores Obsolete (query em `Flow`, Tooling). Não precisei ativar nada. Versão de antes: v9; ficou: v10.
- Nenhum job em fila/processamento (`AsyncApexJob`: 0).

## Execução
`sf apex run test -o sbx-somos-agility-qa` com as 3 classes, `--code-coverage` (testRunId `707Ha00001EAFX2`): 11 executados, 11 Pass, 0 Fail. Os testes rodam em transação revertida (sem dado persistido). Cobertura: `SolicitacaoReembolsoTriggerHandler` 100%, `SolicitacaoReembolsoBO` 95%, `LancamentoDespesasBO` 88%, `TrgSolicitacaoReembolso` 100%. Cobertura total da org 38% (fora do escopo; o assessment já aponta 40%).

## Casos (derivados dos cenários de `01-analise.md`)
| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| T1 | Cenário 1: PRJ com várias SR válidas soma | `testInclusaoAoAprovarPeloGP`, `testVariosLancamentosMesmoProjeto` | Total = soma dos Lançamentos elegíveis | Pass (asserts sobre `Total_de_despesas_realizadas__c`) | passou |
| T2 | Cenário 2: PRJ sem SR elegível | `testProjetoSemLancamentoElegivelTotalZero` | Total 0 | Pass | passou |
| T3 | Cenário 3: SR fora do critério não entra | `testExclusaoAoRejeitar`, `testExclusaoAoRecolher` | SR rejeitada/recolhida fora do total | Pass | passou |
| T4 | Cenário 4/5: mudança de etapa da SR recalcula o total (causa do defeito) | `testMudarEtapaReSalvaLancamento` | Total real, não o marcador 999 | Pass | passou |
| T5 | Borda: update sem mudar etapa não re-salva | `testUpdateSemMudarEtapaNaoReSalvaLancamento` | Marcador permanece | Pass | passou |
| T6 | Borda: recursão e ordem de execução com os demais automatismos da SR/Projeto | `testTravaDeRecursao...`, `testTransicaoRealNaoCausaRecursaoDescontrolada` | Sem LimitException, 2ª chamada não re-salva | Pass | passou |
| T7 | Volume: 200 SR em 20 projetos | `testBulk200SolicitacoesMudandoDeEtapa` | Dentro dos limites | Pass (75,8 s) | passou |
| T8 | Regressão de Lançamento | `LancamentoDespesasBOTest.testOne` | Pass | Pass | passou |
| T9 | Cobertura >= 85% por classe | `--code-coverage` | >= 85% | 100/95/88 | passou |
| T10 | Flow nova versão, anterior não editada | Query Tooling | v10 Active | Confirmado | passou |
| T11 | Cenário 6: recálculo retroativo (RN-07) | — | — | Fora do escopo por decisão D2 do design (não faz parte da demanda) | não coberto |
| T12 | Aprovação real pela tela com usuário GP, integração MS Project e perfis | — | — | Não executado: exige fluxo de aprovação real e dispara callout; não criei dado persistido. Fica no roteiro do cliente | não coberto |

Permissão por perfil: não testada (sem permission set novo na demanda; nenhuma permissão minha foi alterada).

## Limites
- Prova por teste Apex em transação revertida; a cadeia completa de Flows de `PPM_Project__c` roda nesses testes, mas a aprovação pela interface (T12) não foi exercitada. Nenhum screenshot (sem tela testada).
- Sem veredito de risco do assessment além do coberto por T6 e T7 (ordem de execução e volume).

## Alterações no usuário de execução
Nenhuma.

## O que pode ter saído da org
Nada persistido: testes Apex revertem a transação; nenhum e-mail ou chamada externa registrada por mim.
