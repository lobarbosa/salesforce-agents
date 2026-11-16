**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Partial Copy; usuário de execução `005bJ00000piKAaQAM`)
**Conferir depois de:** 2026-11-16T01:35:00Z (antecipado de 01:50 pelo responsável; o job dispara às 01:20)

# EPLAST-33 — Testes na QA, fase 1 (armar)

Org confirmada por `sf org list`: só `sbx-eplast-qa` conectada. Nenhuma escrita minha em Account, Opportunity, Order ou OrderItem. Não criei dado de teste persistido: `fixtures/` não existe no cliente, e criar Order exige a cadeia `OrderTrigger` (envio ao Protheus) e o usuário `integracao*` que a fábrica usa só dentro de teste Apex. A prova das regras de borda vem da suíte Apex rodada na QA; a prova ponta a ponta vem da execução agendada sobre a base existente (permitida pela regra da esteira), conferida só por contagens.

## Componentes do `05-deploy-qa.md` na org
Conferidos: objetos `CommercialSignal` e `CommercialSignalSetting` (Tooling `CustomObject`), permission set `PS_Comercial_SinaisComerciais` (`0PSHa000002DOHtOAO`), classes `CommercialSignal*` (suíte rodou, logo existem). Cobertura abaixo.

## Casos executados nesta fase
| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| CA-20 | `sf apex run test -o sbx-eplast-qa` nas 4 classes de teste, com cobertura (Run `707Ha00001E4Kfo`) | Suíte passa; cada classe ≥ 85% | 41 de 41 passam (100%). Service 99%, GroupStatsBatch 98%, Batch 97%, Scheduler 100% | aprovado |
| CA-01 a CA-11, CA-15, CA-16, CA-17 (regras e bordas) | Mesma suíte (casos 59/60/61 dias, 30%/31%, grupo 4/5, 4 de 10 / 2 de 10, sem Industry, reexecução, pedido novo, parâmetro 90 dias) | Asserts passam | Passam na QA (mesma Run) | aprovado (por teste Apex; ponta a ponta com dado persistido: ver fase 2) |
| CA-12 (só escrita em objetos comerciais, parte teste) | Teste Apex de contagem e maior LastModifiedDate | Iguais antes e depois | Passa | aprovado; conferência real na fase 2 |
| CA-13 parcial (sem permissão) | Como o usuário de execução, antes de atribuir o permission set: `SELECT COUNT() FROM CommercialSignal__c WHERE SignalKey__c != null` | Sem acesso ao campo | `No such column 'SignalKey__c'` | aprovado (parte de permissão) |

## O que foi alterado para armar (desfazer ao fim da fase 2)
1. **Permission set** `PS_Comercial_SinaisComerciais` atribuído ao usuário de execução `005bJ00000piKAaQAM` (antes: sem atribuição, 0 atribuições na org). Necessário para o batch rodar e para eu ler o resultado. **Desfazer:** remover o `PermissionSetAssignment` desse usuário ao fim da fase 2.
2. **Job agendado de uma vez só** `EPLAST33 QA arme` (CronTrigger `08eHa00000Xr7aEIAR`), cron `0 20 22 15 11 ? 2026` no fuso America/Sao_Paulo; `NextFireTime` conferido: 2026-11-16T01:20:00Z, estado WAITING, 0 disparos. Chama `CommercialSignalScheduler` (fase 1 e encadeia fase 2). Sem implantação; agendado por Apex anônimo. **Desfazer:** não se repete sozinho (data única); se ainda constar, `System.abortJob('08eHa00000Xr7aEIAR')`. O agendamento do design (04:00 UTC diário) **não** está armado na QA; a fase 2 agenda `CommercialSignalScheduler.scheduleDaily(...)` se o design pedir, dizendo isso no roteiro.

## Estado de antes (só contagens agregadas)
- `CommercialSignal__c`: 0.
- Account 1.220 (458 sem Industry); Order 10.320 (Concluido 8.070, Cancelado 2.125, Faturamento 25, Liberacao Estoque 74, Liberacao Financeiro 14, Revisao de Pedido 12); contas com pedido válido (Faturamento/Concluido): 583.
- Maior `LastModifiedDate`: Account 2026-11-15T23:30:14Z; Order 2026-11-13T19:08:09Z; OrderItem 2026-11-13T19:06:52Z; Opportunity 2026-11-15T23:30:14Z (contagem 9.332). Contagem OrderItem 10.008. EmailMessage 805.
- Contas com Industry vazio e pedido válido: 273.

## Esperado depois da execução (job dispara 01:20 UTC, "hoje" = 2026-11-15 no fuso do usuário)
- **Nunca comprou:** 1.220 − 583 = **637** sinais (CA-03/04).
- **Recuperação:** contas cuja última compra válida tem EffectiveDate ≤ 2026-09-15 (> 60 dias): **530** sinais; se a data da execução virar 2026-11-16, seriam 533 (3 contas com última compra em 2026-09-16). Cada uma com DaysWithoutPurchase > 60 (CA-01/02).
- **Queda/Alta/Cruzada:** sem valor exato calculável por agregação simples; conferir coerência: Queda e Alta só com base > 0 e |variação| > 30; Cruzada só em contas com Industry, nenhuma das 273 sem Industry com pedido válido pode ter Cruzada, no máximo 10 por conta, produto nunca comprado pela conta em 180 dias (CA-07, 08, 09, 10).
- Uma conta tem no máximo um sinal por chave (`SignalKey__c` único): 0 duplicatas (CA-15).
- Account, Order, OrderItem: contagens iguais; maior LastModifiedDate de Order e OrderItem inalterado (de Account e Opportunity, só mudança por outras automações da org; sinal de escrita nosso é o objeto filho `CommercialSignal__c`, que não toca o pai); EmailMessage igual a 805 (CA-12).
- Nenhum Flow, trigger ou validation rule novo em Account/Opportunity/Order (CA-21): comparar `05-deploy-qa.md` (nenhum desses itens na lista).
- Colunas do relatório `CommercialSignals_ByAccount` sem contato (CA-14); abrir na fase 2 via `qa_browser` se possível.
- Não executáveis nesta QA: CA-18 (amostra do Comercial) e CA-19 (Marketing Cloud, fora da esteira); CA-13 visibilidade por conta (A não vê X): precisa de usuário B com compartilhamento real; só a parte de permissão foi provada.

## Fase 2 (o que fazer)
1. Passou de 01:50 UTC? Conferir `CronTrigger.PreviousFireTime`/`TimesTriggered` (`08eHa00000Xr7aEIAR`), `AsyncApexJob` das duas classes batch (status, `NumberOfErrors`).
2. Contagem de `CommercialSignal__c` por `Type__c`; comparar com o esperado acima; duplicatas por `SignalKey__c`; contagens e maior LastModifiedDate de antes.
3. Abrir o relatório; dar veredito final; desfazer a atribuição do permission set.

## O que pode ter saído da org
Nenhum e-mail, callout ou registro em objeto comercial por ação minha. O job gravará só `CommercialSignal__c`. Nenhuma chamada externa prevista (o batch só lê Order/OrderItem/Account).
