**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-28 — Testes na QA, rodada 2, fase 2 (conferência)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS). Conferência feita em 2026-11-16T03:25Z, depois de `Conferir depois de` (03:16Z). A org estava como armada na fase 1 (Flow versão 5, início 00:06 hora da org, CMDT 2 dias / `SoAtividade`). Nenhuma mudança no meu usuário de execução (sem permission set, sem valores).

## Falhas

### FALHA 1 (crítica) — o disparo do Flow ocorreu, mas não há prova de que o aviso (CA-02/CA-07) foi gerado
- **Reproduzir:** com o arme da fase 1, esperar o disparo de 03:06Z e ler `/services/data/v62.0/connect/notifications` (também v61.0 e v60.0) com `sf api request rest --target-org sbx-eplast-qa`, autenticado como o dono `005bJ00000piKAaQAM`.
- **Obtido:** `CronTrigger` `08eHa00000XrHRTIA3`: `PreviousFireTime` 2026-11-16T03:06:00Z, `TimesTriggered` 1, `NextFireTime` 2026-11-17T03:06:00Z (o job rodou). Porém a caixa de notificações do dono voltou `{"notifications": []}`, igual ao estado de antes. Não há `IntegrationLog__c` com `Opportunity_Scheduled_AlertaParada` (0), logo também não há falha registrada pelo caminho de falha do Flow. `FlowInterview` e `AsyncApexJob` dessa janela: 0 registros (nenhum rastro consultável da execução).
- **Esperado:** 1 notificação "Oportunidade parada há 2 dias" para a Opp B `006Ha00000QWpOdIAL` (`LastActivityDate` 2026-11-14, aberta, dono ativo, referência = 2026-11-14, DiasParado 2 em 2026-11-16).
- **Causa provável (não confirmada):** (a) o Flow não encontrou B elegível (por exemplo, a regra `SoAtividade` ou o cálculo de `DiasParado` não bate com o esperado); (b) a notificação foi enviada e a API de conexão não a lista para esse usuário/sessão; (c) a ação `customNotificationAction` falhou sem passar pelo `faultConnector`. O builder deve provar a execução por um meio que deixe rastro: por exemplo, versão de teste do Flow que grave em `IntegrationLog__c` cada elegível avaliado (apenas na dev), ou rodar na dev com Debug/Flow Interview log e conferir a notificação na tela. Tentativa de abrir o sino pela tela com `qa_browser_*`: a sessão abriu, mas o elemento "Notifications" não foi localizado (timeout), sem screenshot útil.

## Retestes da rodada 1
| Falha da rodada 1 | Situação |
|---|---|
| Sem prova de execução do alerta | **Não corrigida.** O disparo agora está provado (`PreviousFireTime`, `TimesTriggered` 1), mas o efeito (notificação) segue sem prova. |

## Casos
| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| Disparo agendado | Armar para 03:06Z; ler `CronTrigger` | Rodou uma vez | `PreviousFireTime` 03:06:00.210Z, `TimesTriggered` 1 | Passou |
| CA-02 / CA-07 — Opp B (2 dias) notifica o dono | Ler notificações do dono depois do disparo | 1 notificação com nome, conta, estágio, data | `notifications: []`; sem log | **Falhou** |
| CA-03 — atividade recente (Opp C, 1 dia) não notifica | Idem | Nenhuma | Nenhuma (consistente, mas sem prova de que o Flow avaliou) | Não conclusivo |
| CA-01 / CA-04 parcial — Opp D fechada não notifica | Idem | Nenhuma | Nenhuma (mesma ressalva) | Não conclusivo |
| CA-06 — leitura pura | Comparar contagens e `LastModifiedDate` | Sem alteração causada pelo alerta | Opportunity 9337, Account 1221, Order 10321, OrderItem 10008, Event 5455, Task 8544, `IntegrationLog__c` 843: todas iguais ao antes. As 4 Opps de teste com `LastModifiedDate` 2026-11-15T23:30:14Z, inalterado | Passou |
| CA-09 — falha/dono inativo registrada | `IntegrationLog__c` com a ação do Flow | 0 (nenhum caso) | 0 | Passou (para o cenário sem dono inativo) |
| CA-05 — sem repetição no dia seguinte | Aguardar 17/11 | 1 por episódio | Não executável nesta sessão | Não executado |
| CA-08 — gestor ligado | Preciso de usuário com gestor | Gestor também recebe | Não executável (sem usuário com gestor verificado, e sem ler usuário real) | Não executado |
| CA-11 — volume | Partial Copy tem 83 Opps abertas sem atividade há mais de 3 dias (contagem fase 1) | Flow conclui sem erro | Sem erro registrado em log, mas sem rastro de execução | Não conclusivo |

Critério de aceite principal (CA-02, o aviso ao dono) não provado: veredito reprovado.

## O que pode ter saído da org
- Notificações personalizadas possíveis para donos reais de Opps reais da QAS que estivessem com referência de exatamente 2 dias (Flow sobre registros existentes, autorizado). Não consegui verificar (só leio a caixa do meu usuário). Nenhum e-mail (o Flow só usa notificação interna). Nenhum registro novo em Opportunity, Account, Order, OrderItem, Task, Event ou `IntegrationLog__c`.
- Dados de teste criados na rodada 1 (Conta `001Ha000016UqejIAC` e Opps `006Ha00000QWpOcIAL`, `OdIAL`, `OeIAL`, `OfIAL`, Tasks "TESTE EPLAST-28 atividade") permanecem.

## Desfazer
A esteira reimplanta o build original (CMDT 14 dias / `AtividadeEEstagio`, Flow início 07:00). Nada manual.
