**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (`sf org list` em 2026-11-15: Sandbox, Connected; única org listada)

# Verificação (rodada 2) — EPLAST-27: Próxima melhor ação por cliente

Só a dev. Nada em QA nem produção. Nada do que o builder construiu foi alterado.

## Resumo
- **A Falha 1 da rodada 1 foi corrigida e provada**: o dono da conta recebe o resultado da regra, e conta de outro dono recebe `NOT_OWNER`, com `RestrictToOwner__c = true` (valor entregue).
- A regra do Flow (C1 a C6, C10 a C13) não foi alterada pela correção (só a decisão `CheckOwner` mudou) e passou na rodada 1. Nesta rodada ela foi reexercitada só em parte (ver abaixo), porque a massa com oportunidades é pesada e atravessa validation rules e a cadeia Protheus.
- O agente SFAgent2 continua sem prova (ativação da v4, licença e concessão são passos manuais). Por isso a verificação é inconclusiva, não reprovada.

## Retestes da rodada anterior
| Falha | Situação |
|---|---|
| Falha 1 — dono recebia `NOT_OWNER` na própria conta | **Corrigida** (C8 e C9 abaixo) |

## Contenção do risco Protheus
`comentarios-do-card.md` não autoriza disparar a cadeia. Usei o desvio da própria solução: `TriggerUtility.TriggerExecution.BypassTrigger__c = true` (deploy do registro na dev) durante a massa, restaurado a `false` ao final (conferido por SOQL; `git status` sem alteração em `force-app`). `IntegrationLog__c` = 0 depois.

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C8 | Dono vê a sugestão na própria conta (config padrão) | CMDT `Default` conferido por SOQL: 30, `E`, `RestrictToOwner=true`. Duas contas `TESTE EPLAST-27` (NODATA, RISCOE) com dono = usuário que executa. Flow via `Flow.Interview` em Apex anônimo | Resultado da regra, não `NOT_OWNER` | NODATA e RISCOE: `NODATA` "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." | passou |
| C9 | Conta de outro vendedor não revela dados (config padrão) | Conta `TESTE EPLAST-27 OTHER` com dono = outro usuário administrador da dev, mesma execução | `NOT_OWNER` sem dado da conta | `NOT_OWNER` "Esta conta não está na sua carteira." | passou |
| C5 | NODATA sem erro técnico | Conta sem oportunidade nem compra, dono = executor | "Dados insuficientes" | Confirmado no C8 | passou |
| C1 a C4, C6 | A1, A2, A3, NONE, risco fora da lista | Não repetidos. Exigem oportunidade (`LastPurchase__c` é roll-up de oportunidade ganha) e a massa é pesada | Regra inalterada desde a rodada 1 | Rodada 1: todos passaram. A correção só tocou `CheckOwner` | não executado nesta rodada (passou na rodada 1) |
| C10 a C13 | Sem gravação, sem e-mail, sem dado pessoal, limiar por CMDT | Não repetidos | Inalterados | Rodada 1: passaram | não executado nesta rodada (passou na rodada 1) |
| C14 | Mesma regra para EPLAST-28 e eplast-ent-11 | Consumidores não existem | n/a | n/a | não executado |
| C15 | Agente responde com a ação | Impossível por `sf` | Resposta do SFAgent2 | n/a | não executado |

Limite da prova de C9: a comparação de dono foi provada com dois donos diferentes (executor e outro usuário) executando como o mesmo usuário. Não consegui executar como o outro usuário (não há login nele), então "outro vendedor logado" não foi simulado literalmente. O CASESAFEID cobre a diferença de 15 e 18 caracteres.

## Lacunas (o que ficou sem prova)
- **Agente SFAgent2 (C15):** as 4 versões do bot estão `Inactive` na dev, `PS_Comercial_ProximaAcao` sem atribuição e sem concessão do agente. Sem prova: que o assistente chama a ação, que perguntas variadas não caem nas instruções antigas (STEP 7 e ACOMPANHAMENTO DE CARTEIRA, limiar de 15 dias, R6), e que o `agentGraph` passa a ter a ação (na rodada 1 não tinha).
- **O que uma pessoa precisa fazer:** ativar a v4 do SFAgent2 na dev, conceder o agente ao `PS_Comercial_ProximaAcao` (licença Agentforce), atribuir a um vendedor de teste, conferir o grafo e repetir C1 a C6 e as perguntas variadas pelo assistente, com contas dele e de outro vendedor.
- C14 depende de EPLAST-28 e eplast-ent-11 existirem.

## O que pode ter saído da org
Nada. Cadeia Protheus desviada, `IntegrationLog__c` = 0. Nenhum e-mail ou callout. Flow sem DML nem ação externa.

## Limpeza
Apaguei 3 contas `TESTE EPLAST-27`, as tarefas e `EconomicGroup__c` criados por Flows para elas. COUNT depois: Account 0, Task 0, `IntegrationLog__c` 0, `EconomicGroup__c` `TESTE EPLAST-27%` 0. `BypassTrigger__c` restaurado a `false`. Resíduo: lixeira da dev até expirar.
