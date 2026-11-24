**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# Verificação — SOMOSAGILITY-17

Org confirmada com `sf org list`: só `sbx-somos-agility-dev` (Sandbox, Connected). Todos os comandos usaram `--target-org sbx-somos-agility-dev`. A QA não foi tocada.

## Por que inconclusiva
O critério principal (sequência Gustavo, Wanderley, Walmor para JOB criado pelo usuário Cyber) exige criar o registro como membro de "Grupo Cyber Salesforce" e aprovar como cada aprovador. O verificador não age em nome de outro usuário. Isso segue a decisão do responsável de 2026-11-23 (03-design.md, opção a): os casos T-sequência ficam para o cliente na homologação, com `05-roteiro-cliente.md`. Não é defeito da construção. A configuração foi provada por consulta e nenhum caso executado falhou.

## Evidência de configuração (retrieve da dev em projeto temporário, descartado)
- `Aprova_o_JOB`: ativo, `processOrder` 1.
- `JOB_Investimento_Cyber`: ativo, `processOrder` 2; entrada `CreatedBy equals Grupo Cyber Salesforce` AND `Status_da_Qualificaco__c notEqual Aprovado`; passos na ordem `Aprovacao_Gustavo`, `Aprovacao_Wanderley` (RejectRequest), `Aprovacao_Walmor` (RejectRequest); Gustavo sem rejectBehavior explícito (padrão do 1º passo, rejeição final); ações de submissão, aprovação final, rejeição e recall iguais às do geral.
- `JOB_de_solicitacoes_de_investimento`: ativo, `processOrder` 3.
- Ordem efetiva na dev (1, 2, 3) bate com o design. Os arquivos de `force-app` do Cyber e do geral são idênticos ao que a dev devolveu (`diff` sem diferença). Isso confirma a Correção 1 do plano: o XML está certo, a inversão na QA vem do deploy (R1) e pede passo manual na QA.
- Aprovadores Gustavo, Wanderley e Walmor: um usuário cada no XML. O de Gustavo termina em `br1` (usuário ativo, ver achado 2 do plano).

## Impacto de SOMOSAGILITY-22
O preflight avisou que SOMOSAGILITY-22 também mexe em `approvalProcesses/JOB_de_Solicita_o_de_Investimento__c`. Na dev, o retrieve trouxe outros processos do objeto (`JOBSolicitacaoInvestimento*`, `JOB_de_solicitacoes_de_investimentos`), todos inativos. Os três processos desta demanda estão como o plano descreve, então a SOMOSAGILITY-22 não alterou o que foi testado. Conflito de merge no arquivo do processo geral continua possível; confira no PR.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | Config: processo Cyber existe, ativo, ordem 2, entrada e passos | Retrieve + leitura do XML na dev | Conforme design | Conforme (ver acima) | passou |
| C2 | Config: geral só mudou ordem para 3 | Retrieve, diff contra o `force-app` | Ordem 3, ativo | Ordem 3, ativo, arquivo idêntico | passou |
| C3 | Ordem efetiva 1, 2, 3 (Correção 1) | Retrieve na dev | 1, 2, 3 | 1, 2, 3 | passou |
| C4 | Cenário 3: JOB de outro usuário não é afetado | Criei 1 JOB com meu usuário de execução (não Cyber) e submeti por Apex, na dev | Não entrar no processo Cyber | `NO_APPLICABLE_PROCESS`: não entrou no Cyber. Também não entrou no geral, porque meu usuário não está nas listas dele. Não prova que o fluxo vigente de outros criadores continua igual. | passou (parcial) |
| C5 | Cenário 1: Cyber cria, Gustavo, Wanderley, Walmor, aprovado só após Walmor | Não executado: exige criar como Cyber e aprovar como cada pessoa | Sequência na ordem | n/a | não executado (exceção do responsável, homologação) |
| C6 | Cenário 2: aprovador fora de ordem não age | Não executado: exige os usuários reais | Etapa não pendente para Wanderley e Walmor | n/a | não executado (idem) |
| C7 | Rejeição em cada passo (R4) | Não executado | Rejeição final no passo 1 e RejectRequest nos passos 2 e 3 | n/a | não executado (idem) |

Observação: o campo `Name` do objeto é autonumeração; o registro de teste não pôde levar `TESTE` no nome.

## O que pode ter saído da org
Nada. A submissão falhou sem processo aplicável, então não houve alerta nem atualização de campo.

## Limpeza
O JOB de teste foi apagado (`sf data delete record`); `COUNT` do objeto na dev voltou a 0. Nenhuma alteração no usuário de execução, nenhum permission set atribuído, nenhum job agendado, nenhum arquivo do repositório alterado.

## O que fica sem prova e como provar
C5, C6 e C7: na QA, com os usuários reais (Cyber e os três aprovadores), seguir `05-roteiro-cliente.md`. Antes, reler `processOrder` na QA até dar 1, 2, 3 (Correção 1) e conferir o username do Gustavo (achado 2).
