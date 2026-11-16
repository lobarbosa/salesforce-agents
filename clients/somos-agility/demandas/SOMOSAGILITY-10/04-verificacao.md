**Verificação:** aprovada
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-10 — Verificação do build (rodada 2)

Org confirmada com `sf org list`: só `sbx-somos-agility-dev` (Sandbox, Connected, orgId 00DHa0000070wxfMAA). QA e produção não foram tocadas. Nenhum dado criado fora das classes de teste Apex (que revertem a transação); nenhuma SOQL em dado de cliente, só metadata e contagens.

## Reteste da rodada anterior

- FALHA 1 (`testMudarEtapaReSalvaLancamento` instável por `LastModifiedDate`): **corrigida**. Rodei as 3 classes juntas e o teste passou. O diff do commit 2b9f28da mexe só em `SolicitacaoReembolsoTriggerHandlerTest.cls` (19+/14-) e troca a asserção por relógio por um marcador (999) em `Total_de_despesas_realizadas__c`.
- Limite da prova de estabilidade: o teste passou na rodada desta sessão e em 2 de 2 rodadas do builder. Essas 3 execuções não esgotam a possibilidade de instabilidade.

## Resultado dos testes (dev)

Comando: `sf apex run test --target-org sbx-somos-agility-dev --class-names LancamentoDespesasBOTest --class-names SolicitacaoReembolsoBOTest --class-names SolicitacaoReembolsoTriggerHandlerTest --code-coverage --wait 20` (testRunId `707Ha00001EA7La`).
Resultado: 11 executados, 11 Pass, 0 Fail, outcome Passed.

| Classe | Linhas | Cobertas | % |
|---|---|---|---|
| `SolicitacaoReembolsoTriggerHandler` | 11 | 11 | 100 |
| `SolicitacaoReembolsoBO` | 19 | 18 | 95 (linha 41, só log de falha) |
| `LancamentoDespesasBO` | 16 | 14 | 88 |
| `TrgSolicitacaoReembolso` | 1 | 1 | 100 |

Todas as classes tocadas ficam com 85% ou mais por classe na execução conjunta. Cobertura total da org: 38% (não é escopo da demanda).

## Flow (versão nova, sem edição no lugar)

Consulta Tooling `Flow WHERE Definition.DeveloperName='Atualiza_valor_total_de_despesas_realizadas_no_projeto'`: v1 a v9 Obsolete, **v10 Active**. A descrição da v10 cita SOMOSAGILITY-10 e a data 27/10/2026 (critério de entrada "Lançamento tem projeto" e valor padrão 0). A v9 (anterior, de 28/07/2025) ficou Obsolete, como esperado do deploy de nova versão. Não há job Apex agendado pendente para as 3 classes (`AsyncApexJob` ScheduledApex, 0 registros).

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Soma de SR aprovadas (cenário 1 e RN) | `SolicitacaoReembolsoBOTest.testInclusaoAoAprovarPeloGP` e `testVariosLancamentosMesmoProjeto` | Total = soma dos Lançamentos elegíveis | Pass (asserts sobre `Total_de_despesas_realizadas__c`) | passou |
| C2 | PRJ sem SR/Lançamento elegível tem total zero (cenário 2) | `testProjetoSemLancamentoElegivelTotalZero` | Total 0 | Pass | passou |
| C3 | SR fora do critério não entra (cenário 3) e rejeitada/recolhida sai da soma (cenário 4/5) | `testExclusaoAoRejeitar`, `testExclusaoAoRecolher` | Total sem a SR | Pass | passou |
| C4 | Mudança só de etapa da SR recalcula o total (causa do defeito) | `testMudarEtapaReSalvaLancamento` (marcador 999 sobrescrito pelo total real) | Total real, não 999 | Pass | passou |
| C5 | Update da SR sem mudar etapa não re-salva | `testUpdateSemMudarEtapaNaoReSalvaLancamento` | Marcador 999 permanece | Pass | passou |
| C6 | Trava de recursão e fim da transação dentro dos limites | `testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao`, `testTransicaoRealNaoCausaRecursaoDescontrolada` | 2ª chamada não re-salva; sem LimitException | Pass | passou |
| C7 | Bulk de 200 SR sem estourar limite | `testBulk200SolicitacoesMudandoDeEtapa` (200 SR em 20 projetos) | SOQL/DML dentro do limite | Pass | passou |
| C8 | Testes pré-existentes de Lançamento voltam a passar | `LancamentoDespesasBOTest.testOne` | Pass | Pass | passou |
| C9 | Cobertura >= 85% por classe | `--code-coverage`, execução conjunta | >= 85% | 100 / 95 / 88 | passou |
| C10 | Flow novo, ativo, anterior não editada no lugar | Tooling API (acima) | v10 Active, anteriores Obsolete | Confirmado | passou |
| C11 | Cenário 6: recálculo retroativo de PRJ com SR anteriores à correção (RN-07) | Não exercitado | — | Depende de decisão D2 e de dados reais | não executado |
| C12 | Aprovação real pela UI, `Limits` com N = 1/50/200 e integração MS Project | Não exercitado | — | Fica para o QA (plano 9, itens 1, 2 e 4) | não executado |
| C13 | Regra "Favor preencher o JOB" da QA | Tooling na dev | Regra localizada | Só existe na QA; o fixture usa `Possui_JOB_investimento_ou_treinamento__c = 'Não'` por hipótese | não executado |

## Pendências (não são defeito do build)

- C11, C12 e C13 não puderam ser provados na dev. C13 só se confirma no deploy da QA, que é a esteira. O PDF anexo não foi reaberto: os critérios vêm de `01-analise.md` e os testes cobrem a regra descrita lá.
- Sem prova de aprovação real (`Approval.process`) e de medição de `Limits` com a cascata completa de Flows de `PPM_Project__c`.
- A linha 41 do BO (log de falha do `Database.update` parcial) não tem cobertura.

## O que pode ter saído da org

Nada. Os testes Apex rodam em transação revertida, sem registro persistido. `IdMSProject__c` nulo e bypass do handler de projeto evitam a integração externa. Não alterei usuário, perfil, permission set nem opções do usuário de execução.
