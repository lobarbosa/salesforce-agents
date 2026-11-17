**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (alias; Org Id 00DHa000006vfMLMAY, Sandbox, Connected; única org em `sf org list`)

# EPLAST-35: Verificação do build, rodada 2 (reteste da correção da FALHA 1)

Nada foi tocado em QA, QAS, produção ou Marketing Cloud. Nenhum DML, Apex anônimo ou deploy foi executado nesta sessão: não há dado de teste, usuário alterado, permission set ou TraceFlag a desfazer.

## Por que inconclusiva
A correção da FALHA 1 está na **versão 2 do Flow `Lead_AfterSave_DistribuiDonoRodizio`, que está em Draft** (consulta Tooling na DEV: v1 Active, v2 Draft). A v1, com o defeito do `Get_Membros`, continua a versão ativa. Qualquer Lead criado agora exercita a v1 e repetiria a FALHA 1; um Draft não dispara e não há como executar Flow record-triggered after save sem ativá-lo.

O plano (seção "Versões e ativação, desta correção") trata a ativação da v2 do Flow como passo separado e não feito. A liberação do design (seção 12/13, passo 8: "na DEV, a ativação para verificação está liberada") refere-se à regra `Distribuicao_Regional_Leads_v2` e ao interruptor `DistribuicaoAtiva__c`, não a uma versão nova de Flow. Por não haver autorização explícita para ativar versão de Flow, e por ser ativação passo da esteira, não ativei. Não é defeito do build: o que ficou sem prova é a própria correção.

## Casos
| Caso | Resultado | Evidência |
|---|---|---|
| T1 a T3b, T7 a T9, T11, T14, T15, T18, `RodizioAtivo=false` | não executado | Dependem da v2 do Flow ativa (Draft agora) |
| T4, T5, T6, T10, T12, T13, T16, T17 | não reexecutado | Passaram na rodada 1 (`04-verificacao-rodada-1.md`) com a v1 do Flow; só valem como regressão depois da ativação da v2 |
| T6b | não executado | Só QAS |
| FALHA 1 da rodada 1 (`Get_Membros` cai no caminho de falha) | **não confirmada como corrigida** | A correção está só no Draft; sem execução |

## O que ficou sem prova
Tudo que depende do rodízio: correção da FALHA 1, alternância com `MOD`, `AssignCount` em coleção vazia, `Get ... In`, filtro de inativo, CPU/SOQL/DML do lote de 200 pelo caminho completo (limite 70% = 7.000 ms), T3b, T7, T8, T9, T11, T14, T15, T18 e a comparação dos 3 `ApprovalProcess`.

## O que uma pessoa precisa fazer para provar
1. Na DEV, ativar a versão 2 do Flow `Lead_AfterSave_DistribuiDonoRodizio` (desativa a v1; desfazer: reativar a v1), ou autorizar expressamente o verificador a fazê-lo.
2. Conferir a regra de Lead: o estado deixado pela rodada 1 foi v2 ativa e v1 inativa; interruptor `DistribuicaoAtiva__c` = false (a verificação liga e desliga).
3. Rodar de novo o verificador para T1 a T18, com o script `fixtures/lead_rodizio_dono_conta.apex` (ações `preparar`, `filas`, `leads`, `limparfilas`, `limpar`), membros de fila diretos e o usuário de teste da regra 6.

## O que pode ter saído da org
Nada nesta sessão.
