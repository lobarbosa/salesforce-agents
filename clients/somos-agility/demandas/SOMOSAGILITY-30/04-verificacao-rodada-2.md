**Verificação:** reprovada
**Org de teste:** `sbx-somos-agility-dev`

# 04 — Verificação (rodada 2): SOMOSAGILITY-30

Org conferida com `sf org list`: `sbx-somos-agility-dev` (Sandbox, Connected, orgId 00DHa0000070wxfMAA). QA e produção não tocadas. Nenhum usuário, perfil ou permission set alterado.

Resumo: a regra funcional passa (11 de 12 testes Apex em todas as execuções; cobertura 100% nas classes de produção tocadas) e o caso de volume ficou dentro do limite de CPU nas duas medições desta rodada. Reprova por um motivo só: o teste `SolicitacaoReembolsoBOTest.testBulk200SolicitacoesMudandoDeEtapa`, ajustado pelo builder, falha de forma intermitente com `Apex CPU time limit exceeded`, o que deixa a suíte, e portanto a validação do PR, instável.

## Estado da org (conferido, não do relato do builder)

- Consulta Tooling ao objeto `Flow`: v11 **Active**, v10 Obsolete, v9 Obsolete, v8 Obsolete.
- A v11 já estava ativa na dev desde a rodada 1 (ativada pelo verificador). Nesta rodada não houve ativação nem alteração.

## Rodada anterior

- FALHA 1 (CPU 10521/10000 no volume): aceita pela decisão (a) do responsável (03-design.md). Não reprova por si. Remedida abaixo: 8311 e 8913 ms, dentro do limite.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 `testInclusaoAoAprovarPeloGP` | CA-01, CA-02, CA-03, CA-10 | `sf apex run test` (run 707Ha00001F4DNf) | 0 em etapas pendentes, soma só em Aprovado | Pass | passou |
| T2 `testExclusaoAoRejeitar` | CA-04 | idem | Rejeitado zera | Pass | passou |
| T3 `testExclusaoAoRecolher` | CA-05 | idem | Recall zera | Pass | passou |
| T4 `testProjetoSemLancamentoElegivelTotalZero` | CA-07 | idem | Total 0 | Pass | passou |
| T5 `testVariosLancamentosMesmoProjeto` | CA-09 | idem | Soma só das SRs aprovadas | Pass | passou |
| T6 `testLancamentoSemProjetoNaoAlteraProjeto` | CA-08 | idem | Nenhum projeto alterado | Pass | passou |
| T7 `testQuilometragemAprovadaSomaValorDaKilometragem` | CA-10 | idem | Soma Valor_da_Kilometragem__c | Pass | passou |
| T8 `testBulk200SolicitacoesMudandoDeEtapa` | bulk 200 SR (CA-01/02) | `sf apex run test`, 3 execuções (completa + 2 isoladas) | Pass sempre | Fail (CPU, linha 40 de `SolicitacaoReembolsoBO.updateLancamentosDespesas`), Pass (50,6 s), Fail (CPU). Na rodada 1 passou (58,9 s) | **falhou** |
| T9 a T12 `SolicitacaoReembolsoTriggerHandlerTest` (4 métodos) | regressão re-save e trava de recursão | idem | Pass | 4 Pass | passou |
| V1 volume, pré-condição | CA-09 | Apex anônimo `fixtures/lancamento-volume-setup.apex` (SR A Aprovado com 3x10; SR B Pendente - Gestor com 150x1, mesmo projeto) | Total 30 | 30 | passou |
| V2 volume, transição (3 medições) | design seção 6 | Outra execução de Apex anônimo: SR B para `Aprovado`, bypass do handler de projeto, `Limits` na mesma transação | Total 180; CPU registrada | Total 180 nas 3. CPU: 10521 (rodada 1), **8311** e **8913** (esta rodada) de 10000. SOQL 8/100, DML 9/150, linhas DML 158. A medição de abertura desta rodada foi feita sem capturar o valor e foi descartada | passou (registrado; limite aceito pela decisão (a)) |
| N1 cobertura | meta 85% por classe | `sf apex run test --code-coverage` | >= 85% | `SolicitacaoReembolsoBO` 100%, `SolicitacaoReembolsoTriggerHandler` 100%, `LancamentoDespesasBO` 100%, `LancamentoDespesasTriggerHandler` 100%, `TrgSolicitacaoReembolso` 100%, `TrgLancamentoDeDespesas` 100%. `PPMProjectTriggerHandler` 0% e `TriggerHandler` 45% (bypass proposital, classes não alteradas). Org 39% | passou |
| CA-06 | Aprovado volta atrás | Só CA-04 e CA-05 exercitam Rejeitado e Recall a partir de Aprovado. Demais transições dependem de P5 | — | sem prova adicional | não executado |

## Falhas

### FALHA 1 — Teste de carga de 200 SRs falha por CPU de forma intermitente

- **Como reproduzir:** `sf apex run test --target-org sbx-somos-agility-dev --tests SolicitacaoReembolsoBOTest.testBulk200SolicitacoesMudandoDeEtapa --wait 20`, repetir. Em 3 execuções desta rodada: Fail, Pass, Fail.
- **Obtido:** `System.LimitException: Apex CPU time limit exceeded` em `SolicitacaoReembolsoBO.updateLancamentosDespesas` (linha 40), chamado por `SolicitacaoReembolsoTriggerHandler.afterUpdate`.
- **Esperado:** teste determinístico. Uma suíte de PR com teste que passa ou falha conforme a carga do servidor deixa a validação do PR vermelha ao acaso.
- **Causa provável:** a mesma do caso de volume (custo do Flow ~ Lançamentos regravados x Lançamentos do projeto), agora multiplicada por 200 SRs numa transação do teste, sem margem. A decisão (a) aceita o limite do produto, não um teste do builder que oscila em cima dele. Sugestão ao builder: reduzir o tamanho do lote do teste (ou dividir em transações) para ficar com folga clara, mantendo a prova de bulk, sem mexer na classe de produção nem no Flow.
- **Observação:** como o teste ajustado faz parte desta entrega, tratei como falha de build e não como o estouro aceito. Se o responsável entender que ele cai sob a decisão (a), a única pendência para aprovar é decidir isso.

## O que pode ter saído da org

Nada observado. A cadeia usou bypass do handler de projeto; sem chamada externa, log de integração ou pedido gerado que eu tenha visto. Não verifiquei se há automação de e-mail na SR.

## Limpeza

Criados e apagados (Apex anônimo, `TESTE SOMOSAGILITY-30`): 1 Account, 1 Contact, 1 PPM_Project__c, 2 Solicitações, 153 Lançamentos. Contagem posterior por consulta: 0 de cada. Sem job Apex agendado criado. Os dados dos testes Apex são revertidos pela própria execução. O script de fixture existente (`fixtures/lancamento-volume-setup.apex`) foi reutilizado sem alteração.
