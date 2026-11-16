**Verificação:** reprovada
**Org de teste:** sbx-somos-agility-dev

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-dev` (sandbox). QA não tocada. Nenhum dado de teste criado fora das transações dos próprios testes Apex (rollback automático); nada ficou na org. Nenhuma alteração em usuário.

## Resultado
Execução conjunta das 3 classes de teste (`sf apex run test --class-names ... --code-coverage`, run `707Ha00001E9w6U`): 11 testes, 10 passaram, 1 falhou. A cobertura das 3 classes de negócio ficou acima de 85%, mas a falha no teste impede aprovar, porque o mesmo teste pode derrubar o deploy na QA (RunSpecifiedTests).

### FALHA 1 — `SolicitacaoReembolsoTriggerHandlerTest.testMudarEtapaReSalvaLancamento` é instável (flaky)
- Como reproduzir: rodar as 3 classes juntas, como acima (ou o deploy com RunSpecifiedTests).
- Obtido: `Assertion Failed: Lançamento deveria ser re-salvo quando a SR muda de etapa de aprovação: Same value: 2026-11-16 18:49:23` (linha 104).
- Esperado: `LastModifiedDate` do Lançamento diferente antes e depois da mudança de etapa.
- Causa provável: `LastModifiedDate` tem resolução de segundo. Quando o insert do Lançamento e o re-save disparado pelo handler caem no mesmo segundo, os valores são iguais e o `areNotEqual` falha, mesmo com o re-save acontecendo. Isolado, o teste passou 2 de 2 (execuções síncronas separadas), então o defeito é de asserção frágil, não de lógica. O teste não foi alterado por esta rework; o commit só adicionou o campo JOB no helper. Sugestão ao builder: provar o re-save de outro modo (contador/campo alterado pelo handler, ou `Test.setCreatedDate`/espera controlada), sem depender do relógio.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Testes de `LancamentoDespesasBOTest` passam na dev | Rodada conjunta das 3 classes | Pass | `testOne` Pass | passou |
| C2 | Testes de `SolicitacaoReembolsoBOTest` passam | Idem | 6 Pass | 6 Pass (inclui bulk de 200) | passou |
| C3 | Testes de `SolicitacaoReembolsoTriggerHandlerTest` passam | Idem | 4 Pass | 3 Pass, 1 Fail (FALHA 1); reexecutado isolado 2x: Pass | falhou |
| C4 | Cobertura >= 85% por classe numa execução conjunta | `--code-coverage` na mesma execução | >= 85% | `SolicitacaoReembolsoBO` 95% (linha 41 descoberta), `SolicitacaoReembolsoTriggerHandler` 100%, `LancamentoDespesasBO` 88% (linhas 25,26) | passou |
| C5 | Regra "Favor preencher o JOB" existe e o fixture a satisfaz | Tooling API: `ValidationRule WHERE ValidationName LIKE '%JOB%' LIMIT 10` na dev | Regra localizada | Só `Verifica_status_do_JOB` (objeto `Previsao_de_Gastos_Job_Investimentos__c`); a regra citada não existe na dev e não há metadata da QA no repositório (`grep Possui_JOB` em force-app sem retorno em XML) | não executado |
| C6 | Fixture sem dado pessoal real | Leitura do diff e grep por CPF/e-mail/telefone nas 3 classes | Só valores sintéticos | CPF `90000000...` (sintético, comentado), telefone `1130000000` (fictício), sem e-mail; nomes `Contact Test` etc. | passou |
| C7 | Mudança restrita às 3 classes de teste | `git show --stat b9bb7e77` | 3 arquivos de teste | Em `force-app`: exatamente as 3 classes de teste (+6/-1, +2, +1 linhas). O commit também traz arquivos da esteira (agents, `tools.py`, `scripts/implantar-build-qa.sh`, `04-plano-build.md` etc.), fora do escopo Salesforce e sem relação com a regra de negócio | passou (com ressalva) |

## Pendências
- Corrigir a asserção frágil (FALHA 1) e rodar de novo.
- Incerteza (C5): a validation rule "Favor preencher o JOB" não pode ser lida na dev. Preencher `Possui_JOB_investimento_ou_treinamento__c = 'Não'` é a hipótese do builder; só o deploy/teste na QA confirma se a regra exige mais algum campo. Pessoa com acesso à QA pode ler a fórmula da regra.

## O que pode ter saído da org
Nada. Os testes usam bypass de `PPMProjectTriggerHandler` e `IdMSProject__c` nulo; nenhum callout foi exercitado. Dados de teste não persistiram.
