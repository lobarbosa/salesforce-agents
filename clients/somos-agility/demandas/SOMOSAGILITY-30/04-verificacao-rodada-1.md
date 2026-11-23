**Verificação:** reprovada
**Org de teste:** `sbx-somos-agility-dev`

# 04 — Verificação: SOMOSAGILITY-30 — Total de despesas realizadas só na aprovação final da SR

Org conferida com `sf org list` (`sbx-somos-agility-dev`, Sandbox, Connected). QA e produção não tocadas.

Resumo: a regra funcional (CA-01 a CA-05, CA-08, CA-09, CA-10) passou em 12 de 12 testes Apex com a v11 ativa, e a cobertura das classes de produção ficou acima de 85%. O caso de volume (uma SR com 150 Lançamentos para `Aprovado`) fechou com CPU de 10521 ms contra o limite de 10000 ms. A transação concluiu e o total ficou certo, mas o contador passou do limite. Pelo design (seção 6), esse resultado devolve a demanda ao gate de design, e não é um defeito de implementação que o builder resolva sozinho.

## Preparação

- Ativação (passo separado, só na dev): Tooling API, `FlowDefinition` `300U400000RLJd6IAH`, `Metadata.activeVersionNumber = 11`. Antes: v11 Draft, v10 Active. Depois: v11 Active, v10 Obsolete (consulta ao objeto `Flow`).
- Nenhum usuário, perfil, permission set ou opção de usuário foi alterado.
- A v11 ficou **ativa na dev** ao final. Reativar a v10 só se a demanda for descartada. Os testes ajustados exigem a v11 ativa.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 `testInclusaoAoAprovarPeloGP` | CA-01, CA-02, CA-03, CA-10 | `sf apex run test` (run 707Ha00001F1C7u) | Total 0 em Pendente - Gestor e Pendente - Operações; 180 só após Aprovado | Pass | passou |
| T2 `testExclusaoAoRejeitar` | CA-04 | idem | Rejeitado zera o total | Pass | passou |
| T3 `testExclusaoAoRecolher` | CA-05 | idem | Recall zera o total | Pass | passou |
| T4 `testProjetoSemLancamentoElegivelTotalZero` | CA-07 | idem | Total 0 | Pass | passou |
| T5 `testVariosLancamentosMesmoProjeto` | CA-09 | idem | Soma das SRs aprovadas | Pass | passou |
| T6 `testLancamentoSemProjetoNaoAlteraProjeto` | CA-08 | idem | Nenhum projeto alterado | Pass | passou |
| T7 `testQuilometragemAprovadaSomaValorDaKilometragem` | CA-10 | idem | Soma o valor da quilometragem | Pass | passou |
| T8 `testBulk200SolicitacoesMudandoDeEtapa` | bulk 200 SR | idem | Total 0 nas pendentes; soma por projeto em Aprovado | Pass (58,9 s) | passou |
| T9 a T12 `SolicitacaoReembolsoTriggerHandlerTest` (4 métodos) | regressão do re-save e da trava de recursão | idem | Pass | 4 Pass | passou |
| V1 volume, pré-condição | CA-01, CA-09 | Apex anônimo (`fixtures/lancamento-volume-setup.apex`): 1 projeto, SR A em Aprovado com 3 Lançamentos de 10, SR B em Pendente - Gestor com 150 Lançamentos de 1 | Total do projeto 30 (a SR B pendente fica fora) | `Total_de_despesas_realizadas__c` = 30 | passou |
| V2 volume, transição | design seção 6 | Outra execução de Apex anônimo: SR B para `Aprovado`; `Limits` impressos na mesma transação | Total 180 e CPU dentro de 10000 ms | Total = 180. CPU = **10521/10000**, SOQL 7/100, DML 9/150, linhas DML 158. Sem exceção capturada | **falhou** |
| N1 cobertura | meta 85% por classe | `sf apex run test -c` | >= 85% nas classes de produção tocadas | `SolicitacaoReembolsoBO` 95%, `SolicitacaoReembolsoTriggerHandler` 100%, `LancamentoDespesasBO` 88%, `LancamentoDespesasTriggerHandler` 100%, `TrgSolicitacaoReembolso` 100%, `TrgLancamentoDeDespesas` 100% | passou |
| CA-06 | Aprovado volta atrás | Cobertura parcial: CA-04 e CA-05 exercitam Rejeitado e Recall a partir de Aprovado. As demais transições dependem de P5 | — | Sem prova adicional | não executado |

## Cobertura por classe (execução de 12 testes)

`SolicitacaoReembolsoBO` 95% (linha 41 sem cobertura), `SolicitacaoReembolsoTriggerHandler` 100%, `LancamentoDespesasBO` 88% (linhas 25 e 26), `LancamentoDespesasTriggerHandler` 100%. Estas classes não foram alteradas pela demanda. `PPMProjectTriggerHandler` aparece com 0% e `TriggerHandler` com 45% porque os testes usam `TriggerHandler.bypass('PPMProjectTriggerHandler')` de propósito. Esse handler também não foi alterado. Cobertura da org: 38% (não é o foco desta demanda).

## Falhas

### FALHA 1 — CPU acima do limite com uma SR de 150 Lançamentos indo para Aprovado

- **Como reproduzir:** na dev, com a v11 ativa, criar um projeto com 150 Lançamentos de uma SR em `Pendente - Gestor` e outra SR aprovada no mesmo projeto. Em uma transação separada, atualizar `Status_de_Aprovacao_e_Etapas__c` da SR para `Aprovado`, com `TriggerHandler.bypass('PPMProjectTriggerHandler')`. Ler `Limits.getCpuTime()` ao final da mesma transação.
- **Obtido:** CPU 10521 ms, limite 10000 ms (105%). Total do projeto correto (180). O sistema não lançou exceção nesta execução, mas o contador passou do limite e uma medição ligeiramente maior pode abortar a transação.
- **Esperado:** CPU abaixo de 10000 ms, ou o design aceitar o risco (seção 6: "Se estourar, o build volta ao gate de design").
- **Causa provável:** custo do Flow proporcional a (Lançamentos regravados) × (Lançamentos do projeto que passam no filtro). Isso é o que o design previu, o mesmo do achado do SOMOSAGILITY-10. A v11 não piora o pior caso, mas também não o resolve. Não comparei com a v10 nesta sessão (seria preciso reativá-la). Foi uma única medição, então há variação possível.
- **Quem resolve:** decisão do arquiteto humano. O design proíbe trocar o algoritmo nesta demanda sem essa decisão. Alternativas a avaliar no design: aceitar o limite documentado, limitar Lançamentos por SR, ou mover o somatório para Apex/agregação.

## O que pode ter saído da org

Nada. A cadeia usou o bypass do handler de projeto. Não foi feita nenhuma chamada externa observada, e nenhum e-mail, log de integração ou pedido foi gerado que eu tenha visto. Não verifiquei se há automação de e-mail na SR.

## Limpeza

Dados de teste criados (1 Account, 1 Contact, 1 PPM_Project__c, 2 Solicitações, 153 Lançamentos, todos `TESTE SOMOSAGILITY-30`) foram apagados. Contagem posterior de Account, Contact, projeto e Lançamentos de teste: 0. Nenhum job agendado foi criado. Script de massa gravado em `fixtures/lancamento-volume-setup.apex`.
