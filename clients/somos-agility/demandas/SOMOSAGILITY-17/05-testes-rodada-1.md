**Veredito:** reprovado

**Org de teste:** `sbx-somos-agility-qa`

# Testes — SOMOSAGILITY-17

Org confirmada com `sf org list`: só `sbx-somos-agility-qa` conectada (Sandbox, Connected). Produção não foi tocada. Nenhum dado foi criado, alterado ou lido na QA (o objeto tem dado real; só foi feita contagem agregada). Nenhuma alteração em usuário ou permission set. O retrieve foi feito em projeto temporário em `/tmp`, fora do repositório.

Conflito com outra demanda: SOMOSAGILITY-22 também mexe em `JOB_de_Solicita_o_de_Investimento__c` (approvalProcesses). A falha abaixo não vem dela: o build desta demanda traz `processOrder` 2 e 3 e a QA mostra o inverso. Não dá para afirmar por que a ordem divergiu.

## Falhas

### FALHA 1 (crítica) — Ordem de avaliação invertida na QA: o processo geral vem antes do processo do Cyber
- Reproduzir: `sf project retrieve start --target-org sbx-somos-agility-qa -m "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.*"` (projeto temporário) e ler `<processOrder>` de cada processo ativo.
- Obtido na QA: `Aprova_o_JOB`=1, `JOB_de_solicitacoes_de_investimento` (geral)=**2**, `JOB_Investimento_Cyber`=**3**.
- Esperado (design e `force-app` do commit `faa3db44`): `Aprova_o_JOB`=1, `JOB_Investimento_Cyber`=**2**, geral=**3**.
- Efeito: o processo geral ainda tem `CreatedBy = Grupo Cyber Salesforce` na entrada (2 ocorrências: entrada e passo 1). Com o geral na frente, um JOB do Cyber entra nele (Pós-vendas, depois Walmor) e nunca chega a `JOB_Investimento_Cyber`. A entrega não produz o efeito pedido na QA.
- Causa provável: é o risco R1 do design. O deploy pela Metadata API informou sucesso, mas não aplicou a troca de `processOrder` do processo geral, que já estava ativo.
- Correção sugerida: reordenar em Setup › Approval Processes › Reorder (Cyber antes do geral) na QA e registrar como passo manual no plano de build e no release. Depois reler `processOrder` na QA. O mesmo passo vale para produção.

## Casos

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Cenário 3: ordem dos processos | Retrieve da QA, leitura de `processOrder` | `Aprova_o_JOB`=1, Cyber=2, geral=3 | 1, Cyber=3, geral=2 (ver FALHA 1) | **falhou** |
| T2 | Cenário 1: processo Cyber existe e está ativo | Leitura de `active` | `active=true` | `JOB_Investimento_Cyber` `active=true`, label "JOB de Investimento - Cyber" | passou (configuração) |
| T3 | Cenário 1: critério de entrada | Leitura de `entryCriteria` | `CreatedBy equals Grupo Cyber Salesforce` e `Status_da_Qualificaco__c notEqual Aprovado` | exatamente esses dois critérios | passou (configuração) |
| T4 | Cenário 1: sequência dos passos e rejeição | Leitura dos passos | Gustavo, Wanderley, Walmor; passos 2 e 3 com `RejectRequest` | `Aprovacao_Gustavo`, `Aprovacao_Wanderley`, `Aprovacao_Walmor`, nessa ordem, aprovador usuário; Wanderley e Walmor com `RejectRequest` | passou (configuração) |
| T5 | Cenário 1: ações de aprovação, rejeição, submissão e recall | Leitura das ações | Mesmas ações do processo geral | `Aprova_o_de_JOB`, `Status_Qualificacao_Aprovacao`, `Rejei_o_de_JOB`, `Status_Qualificacao_Rejeicao`, `Status_Qualificacao`, `Status_Qualificacao_Recall`; submissor `owner`, `AdminOrCurrentApprover`, `finalApprovalRecordLock=false` | passou (configuração) |
| T6 | Cenário 3: processo geral só mudou na ordem | Comparar `processOrder` do geral no repositório (3) e na QA | 3 | 2 na QA | **falhou** (mesma causa da FALHA 1) |
| T7 | Cenário 1: Cyber submete e Gustavo é o 1º aprovador | Exige usuário Grupo Cyber | — | Não executado por exceção do responsável (decisão de 2026-11-23, `03-design.md`) | não executado (exceção) |
| T8 | Cenário 1: aprovação em cadeia e status final só após Walmor | Exige os 3 aprovadores | — | Não executado por exceção do responsável | não executado (exceção) |
| T9 | Cenário 2: aprovador fora de ordem | Exige Wanderley e Walmor | — | Não executado por exceção do responsável | não executado (exceção) |
| T10 | Cenário 3: outro criador segue o caminho vigente | Exige usuário de outro criador | — | Não executado por exceção do responsável | não executado (exceção) |
| T11 | Flow `Status_Previs_o_de_Gastos_JOB` e `Status_da_Qualificaco__c` corretos após aprovação | Exige aprovar | — | Não executado por exceção do responsável | não executado (exceção) |

Os casos T7 a T11 não reprovam a rodada (decisão do responsável); ficam para o cliente em `05-roteiro-cliente.md`. A reprovação vem apenas da FALHA 1, que é de configuração e foi provada por consulta.

## Ativação de versão
Não se aplica: a demanda não traz Flow, agente nem modelo de prompt. O processo já veio ativo no deploy.

## Pendência de usuário duplicado
Não verificada na QA nesta rodada. O nome "Gustavo Fernandes Eduardo" teve 2 usuários na dev (1 ativo, 1 inativo). Conferir o aprovador do passo 1 antes do release.

## Alterações em usuário de execução
Nenhuma.

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhuma automação foi disparada. Capturas de tela: nenhuma (nada se confere em tela de registro de teste nesta rodada).
