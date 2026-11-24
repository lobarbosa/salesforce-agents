**Veredito:** aprovado

**Org de teste:** `sbx-somos-agility-qa`

# Testes — SOMOSAGILITY-17 (rodada 3, reconferência da ordem após SOMOSAGILITY-22)

Org confirmada com `sf org list`: só `sbx-somos-agility-qa` (Sandbox, Connected). Produção não foi tocada. Nenhum dado foi criado, alterado ou lido; só contagens agregadas e metadata. Retrieve feito em projeto temporário em `/tmp`, fora do repositório. Deploy de QA conferido em `05-deploy-qa.md` (`0AfHa00000EN9c1KAD`, Succeeded): os dois approvalProcesses listados existem na org.

Conflito com SOMOSAGILITY-22 (mesmo objeto, approvalProcesses): o estado dos dois processos foi lido na org e está como o build desta demanda; o teste não foi afetado.

## Retestes da rodada 1

- **FALHA 1 (processOrder invertido): corrigida.** Retrieve da QA em 2026-11-24 (após a SOMOSAGILITY-22): `Aprova_o_JOB`=1, `JOB_Investimento_Cyber`=2 (ativo), `JOB_de_solicitacoes_de_investimento`=3 (ativo). Os demais processos do objeto estão inativos.
- Pendência de usuário duplicado (Gustavo): verificada. Na QA há 2 usuários com o nome (1 ativo com username terminando em `br1`, 1 inativo). O XML do passo 1 aponta o `br1` (ativo). Em produção, confirmar com o consultor que o username ativo também termina em `br1`.

## Falhas
Nenhuma nesta rodada.

## Casos

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | Cenário 3: ordem dos processos | `sf project retrieve start -m "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.*"`, ler `processOrder` | 1 / Cyber=2 / geral=3 | `Aprova_o_JOB`=1, Cyber=2, geral=3 | passou |
| T2 | Cenário 1: processo Cyber ativo | ler `active` | true | `JOB_Investimento_Cyber` `active=true`, label "JOB de Investimento - Cyber" | passou |
| T3 | Cenário 1: critério de entrada | ler `entryCriteria` | `CreatedBy equals Grupo Cyber Salesforce` e `Status_da_Qualificaco__c notEqual Aprovado` | exatamente esses dois | passou |
| T4 | Cenário 1: sequência dos passos | ler passos | Gustavo, Wanderley, Walmor; passos 2 e 3 com `RejectRequest` | `Aprovacao_Gustavo`, `Aprovacao_Wanderley`, `Aprovacao_Walmor`, nessa ordem, aprovador usuário; Wanderley e Walmor com `RejectRequest` | passou |
| T5 | Cenário 1: ações finais, rejeição, submissão, recall | ler ações | iguais ao geral | `Aprova_o_de_JOB`, `Status_Qualificacao_Aprovacao`, `Rejei_o_de_JOB`, `Status_Qualificacao_Rejeicao`, `Status_Qualificacao`, `Status_Qualificacao_Recall`; submissor `owner` | passou |
| T6 | Cenário 3: processo geral só mudou na ordem | comparar `processOrder` do geral | 3 | 3, ativo; critérios de entrada do geral preservados | passou |
| T7 | Aprovador do passo 1 resolve para usuário ativo | contagem de usuários por nome na QA + XML | username `br1` ativo | 1 ativo (`br1`), 1 inativo; XML usa `br1` | passou |
| T8 | Cenário 1: Cyber submete e Gustavo é o 1º aprovador | exige usuário do grupo Cyber | — | não executado por exceção do responsável (`03-design.md`, 2026-11-23) | não executado (exceção) |
| T9 | Cenário 1: cadeia e status final só após Walmor | exige os 3 aprovadores | — | não executado (exceção) | não executado (exceção) |
| T10 | Cenário 2: aprovador fora de ordem | exige Wanderley e Walmor | — | não executado (exceção) | não executado (exceção) |
| T11 | Cenário 3: outro criador segue o caminho vigente | exige outro criador | — | não executado (exceção) | não executado (exceção) |
| T12 | Flow `Status_Previs_o_de_Gastos_JOB` e `Status_da_Qualificaco__c` após aprovação | exige aprovar | — | não executado (exceção) | não executado (exceção) |

Por decisão do responsável (`03-design.md`, 2026-11-23), T8 a T12 não reprovam a rodada e ficam para o cliente em `05-roteiro-cliente.md`. A QA tem 1274 registros do objeto (dado real, contagem agregada); não foram abertos nem alterados.

## Ativação de versão
Não se aplica: sem Flow, agente ou modelo de prompt. O processo veio ativo no deploy.

## Alterações em usuário de execução
Nenhuma.

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma automação disparada. Capturas de tela: nenhuma (a configuração se prova por metadata; as telas dependem dos usuários reais, no roteiro do cliente).

## Pontos para o release
- Passo `processOrder`: reler após o deploy em produção; se divergir, reordenar em Setup › Approval Processes.
- R2: aprovações já pendentes de JOBs do Cyber seguem o caminho antigo.
- R4: regra de rejeição assumida; confirmar na homologação.
