**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`)

# EPLAST-47 — Testes (rodada 3, fase 2: conferência)

## Org e execução
`sf org list`: só `sbx-eplast-qa` (Connected). Conferência em 2026-11-16 ~08:25Z, depois do `Conferir depois de` (2026-11-15 20:40Z). A org ainda estava como armada: Flow `ScheduledFlowOpportunity` v5 Active (v1 a v4 Obsolete), `CronTrigger` `ScheduledFlowOpportunity-5`: `PreviousFireTime` 2026-11-15T20:10:00Z, `TimesTriggered` 1, próxima 2026-11-16T20:10Z. A automação **rodou no horário**, mas não produziu o resultado esperado. Nenhum DML meu; nada criado, nada alterado na org.

## Falhas

### FALHA 1 (crítica) — A execução não classifica as contas: toda atualização de conta falha com "Too many queueable jobs added to the queue: 51"
- **Reproduzir:** na QA, com `RunDayOfMonth__c` = dia atual, deixar o Flow agendado rodar sobre as contas elegíveis (555 com média).
- **Obtido (consultas agregadas, depois da execução das 20:10Z):**
  - `Account.Ranking__c`: vazio 619; PP 54; P 116; M 23; G 396; GG 13; MP 0; 3G 0. Praticamente igual ao de antes (vazio 615; PP 54; P 116; M 23; G 396; GG 13). Esperado: MP 207; PP 138; P 107; M 73; G 30; GG 0; 3G 0 nas elegíveis.
  - `AccountHistory` (campo Ranking): 391 linhas, as mesmas de antes. Esperado: até 478 novas.
  - Soma de `LastMonthPurchaseValue__c` nas contas com ganha do ano: 106.422.982,34. Esperado: 183.408.613,36 (soma das ganhas: 183.408.613,36, confere com a base).
  - `IntegrationLog__c` de ação `ScheduledFlowOpportunity`: 324 (eram 162), ou seja, **+162 registros de erro**; todos com `ResponseStatus__c` = Erro. Esperado: 0 novos. Amostra de um log (texto de sistema, sem dado pessoal): `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY: AccountTrigger: System.LimitException: Too many queueable jobs added to the queue: 51`.
  - Só 4 contas com `LastModifiedDate` depois de 20:00Z na QA.
- **Esperado:** 100% das contas elegíveis com Ranking da faixa, 1 histórico por mudança, 0 erros.
- **Causa provável:** o Flow atualiza as contas em lote e o `AccountTrigger` enfileira um job Queueable por conta (provavelmente a sincronização com o Protheus). Passando de 50 enfileirados na mesma transação, o limite da plataforma derruba a atualização. O mesmo quadro já aparecia na execução da v3 (162 erros). Opções ao builder: o gatilho não enfileirar um job por conta (agrupar, ou não enfileirar quando só `Ranking__c`/`LastMonthPurchaseValue__c` mudam), ou o Flow atualizar em blocos pequenos o bastante para ficar abaixo de 50 por transação. Conferir no `AccountTrigger` (classe do Queueable) antes de decidir.

## Casos
| Caso | Critério | Evidência | Status |
|---|---|---|---|
| 4 (1 atualização por conta) | 4 | Contas não foram atualizadas; histórico inalterado (391) | Reprovado (FALHA 1) |
| 6 (sem lock) | 6 | 0 `UNABLE_TO_LOCK_ROW` identificado, mas o erro obtido foi o limite de Queueable em 162 contas | Reprovado (FALHA 1) |
| 8, 9 (soma e vazio) | 8, 9 | Soma 106.422.982,34 contra 183.408.613,36 esperado | Reprovado (FALHA 1) |
| 10, 11 (faixas) | 10, 11 | Rankings das elegíveis não mudaram (G 396 contra 30 esperado) | Reprovado (FALHA 1) |
| 14 (relatório de mudanças) | 14 | Nenhuma mudança gravada, relatório não tem o que mostrar | Reprovado (FALHA 1) |
| 16 (falha com destinatário) | 16 | Exige falha forçada em registro existente | Não executado (a falha real da FALHA 1 gerou log de erro; envio de aviso não verificado) |
| 17, 18 | volume | Sem número do cliente (P10) | Não executado |
| 1 a 3, 5, 12, 13, 15 | configuração/documentação | Mesmo pacote das rodadas anteriores; Flow v5 e metadata de `Ranking__c`/faixas implantados (`05-deploy-qa.md`) | Não reconferidos nesta fase; sem evidência nova |
| 7 | período configurável | Fora de escopo (D3) | Não aplicável |

## O que pode ter saído da org
- 162 novos `IntegrationLog__c` de erro da ação `ScheduledFlowOpportunity` (sem chamada externa nesses).
- Atualizações de conta que passaram (poucas) podem ter disparado sincronização com o Protheus; logs de `Send Client To Protheus` na janela: 13 (total geral da janela, de todas as ações: 1 AlertaParada, 5 Get Client, 4 Consulta CNPJ).

## Estado deixado
Org como armada (Flow v5 com início 17:10 do fuso da org e `RunDayOfMonth__c` = 15). A esteira reimplanta o build original. Nada a desfazer do meu lado.
