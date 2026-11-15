**Verificação:** aprovada
**Org de teste:** `sbx-somos-agility-dev` (alias da sandbox de dev; usuário omitido por LGPD)

# SOMOSAGILITY-10 — Verificação (reverificação pelas regras de 15/11)

`sf org list` mostrou uma única org conectada: `sbx-somos-agility-dev` (Sandbox, Connected). Todos os comandos usaram `--target-org`/`-o` explícito.

Divergência registrada: o cabeçalho do `00-preflight.md` diz "Etapa que vai rodar: build", mas esta sessão é `verificacao`. O conteúdo do preflight foi tratado como válido.

Os critérios de `01-analise.md` são provisórios (termos entre colchetes). Os casos abaixo vêm deles, lidos com o significado fechado no design aprovado: SR = `Solicitacao_de_Reembolso__c`, projeto = `PPM_Project__c`, campo = `Total_de_despesas_realizadas__c`, regra de inclusão = etapa da SR depois da aprovação do GP.

## Estado confirmado na dev
- Flow `Atualiza_valor_total_de_despesas_realizadas_no_projeto`: versão 10 Ativa; versões 6 a 9 Obsoletas (`Flow` pela Tooling API).
- Job Apex pendente para `SolicitacaoReembolsoBO` e `SolicitacaoReembolsoTriggerHandler`: 0 (`AsyncApexJob`).
- Não existe `clients/somos-agility/fixtures/`. A massa foi montada por Apex anônimo, com o mesmo padrão de campos da classe de teste do build, que já passa nas validation rules (inclusive `Phone` no Contact). Gravar o script como fixture é opcional e não foi feito.
- O `CLAUDE.md` do cliente não traz usuário de teste nem proíbe dado de teste. Nenhum usuário, permission set ou opção foi alterado.

## Dados de teste
Todos sintéticos, com nome `TESTE SOMOSAGILITY-10`: 1 conta, 1 contato, 3 projetos, 3 SR e 4 a 7 Lançamentos de Despesas.
- Todos os scripts usaram `TriggerHandler.bypass('PPMProjectTriggerHandler')`, o desvio que a própria org oferece. Os Lançamentos tinham `IdMSProject__c` nulo, então nenhum callout ao MS Project foi disparado.
- Cada transição de etapa rodou numa execução anônima separada, para simular transações distintas.
- `Status__c` ficou em `Rascunho` o tempo todo, porque o Flow nativo `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` reescreve a etapa quando o status é `Pendente`. O build e o design registram o mesmo ponto.
- Limpeza feita (Apex anônimo): contagem final de 0 em Conta, Contato, Projeto, SR e Lançamento com `TESTE SOMOSAGILITY-10`. Nada ficou.

## Casos executados

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Projeto sem SR elegível (RN-08) | `setup.apex`: projeto A com SR em `Pendente - Gerente de Projetos` e Lançamentos de 150,00 e quilometragem 20 km x 1,50. Consulta do total. | Total = 0, nunca nulo | Projeto A: 0.00 | passou |
| C2 | Várias SR/Lançamentos válidos somam | SR de A: `Pendente - Gerente de Projetos` para `Pendente - Gestor` (execução separada) | Total A = 150 + 30 = 180 | Projeto A: 180.00 | passou |
| C3 | Idem, outro projeto | SR de B (Lançamento de 100,00): para `Pendente - Gestor` | Total B = 100 | Projeto B: 100.00 | passou |
| C4 | SR fora do critério não entra na soma (rejeição) | SR de B: `Pendente - Gestor` para `Rejeitado` | Total B volta a 0 | Projeto B: 0.00 | passou |
| C5 | Idem (recall após aprovação) | SR de C (Lançamento de 80,00) já em `Aprovado`: total inicial 80,00. Depois, para `Recall`. | Total C cai de 80 para 0 | Projeto C: 80.00, depois 0.00 | passou |
| C6 | Alteração de valor recalcula | Lançamento de A: 150 para 200 | Total A = 230 | 230.00 | passou |
| C7 | Inclusão de Lançamento recalcula | Novo Lançamento de 50,00 em A | Total A = 280 | 280.00 | passou |
| C8 | Remoção de Lançamento recalcula | Exclusão do Lançamento de 50,00 | Total A volta a 230 | **280.00 (não recalculou)** | falhou, ver observação 1 |
| C9 | Lançamento sem projeto não afeta nenhum total e não dá erro | Lançamento de 999,00 sem `Relacionado_ao_Projeto__c`, em SR com projeto | Sem erro; totais inalterados | Sem erro; A 280, B 0, C 0 | passou |
| C10 | Testes Apex do build (bulk 200 SR, sem mudança de etapa, recursão, vários Lançamentos no mesmo projeto) | `sf apex run test -o sbx-somos-agility-dev --class-names SolicitacaoReembolsoBOTest --class-names SolicitacaoReembolsoTriggerHandlerTest` (run `707Ha00001E2Ukx`) | 10 de 10 passam | 10 de 10 Pass, 100% | passou |
| C11 | Histórico (RN-07) | Não exercitado: o design D2 deixou o recálculo retroativo fora do escopo. | n/a | n/a | não executado |

## Observações para o gate
1. **C8, exclusão de Lançamento não recalcula o total.** O Flow roda em `CreateAndUpdate`, e o design (seção 10, "O que NÃO será feito") exclui expressamente recalcular na exclusão ou na troca de projeto de um Lançamento. Existem na org os triggers `TrgLancamentoDeDespesas` e `RHX_Lancamento_de_Despesas`, mas não foram analisados quanto a delete. O comportamento corresponde ao escopo aprovado no gate de design e não é regressão do build. O cenário provisório da análise ("desassociada ou excluída") pede o contrário. Como o critério da análise não foi fechado, a decisão é do gate: aceitar a limitação ou abrir demanda própria.
2. **`DespesasRealizadasAtividades__c` não acompanha o recall.** Após `Recall` da SR de C, o campo continuou em 80,00 enquanto `Total_de_despesas_realizadas__c` foi a 0. Na rejeição de B ele caiu a 0. A regra desse campo está fora do escopo (design D1). O teste do build assertou só o `Total` no recall. O R3 do plano sugere que o campo também desconta recolhidas, o que não se confirmou.
3. Antes da correção, SR em `Pendente - Gerente de Projetos` aparecia em `DespesasRealizadasAtividades__c` (180) com `Total` em 0. Isso é comportamento da regra existente, sem alteração.
4. Não exercitado na dev, e já passado ao QA pelo build: submissão real de aprovação (R6), medição de `Limits` em UI (R2), Rollup Helper em produção (R7), integração MS Project (callout fora de teste), execução sob os ~19 Flows after-save de projeto com o bypass desligado. Todos os testes usaram o bypass de `PPMProjectTriggerHandler`.
5. A cobertura da org de 40% segue baixa. As duas classes alteradas ficaram acima de 85% segundo o build (100% e 94,7%). Isso não foi remedido nesta sessão.

## O que pode ter saído da org
Nada. Sem callout (`IdMSProject__c` nulo, `PPMProjectTriggerHandler` com bypass), sem e-mail e sem pedido, cotação ou log de integração criado por esta verificação. Os registros de teste foram apagados.

## Usuário de execução
Nenhuma alteração: nenhum permission set, nenhuma opção de usuário e nenhum campo de usuário foram mudados.
