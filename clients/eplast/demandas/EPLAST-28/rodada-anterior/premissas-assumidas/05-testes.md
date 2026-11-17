**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-28 — Testes na QA, rodada 3, fase 2 (conferência)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS). Conferência em 2026-11-16T04:24Z, depois de `Conferir depois de` (04:15Z). A org estava como armada na fase 1 (Flow versão 7 Active com início 04:05Z, configuração 3 dias / `SoAtividade`). Nenhuma mudança no meu usuário de execução (sem permission set, sem valores). Nada foi desfeito porque nada foi alterado; a esteira reimplanta o build original.

## Falhas
Nenhuma nova. A FALHA 1 da rodada 2 (sem rastro do efeito do alerta) está **corrigida**: a versão 7 grava `ALERTA_ENVIADO` em `IntegrationLog__c`.

## Reteste das falhas da rodada anterior
| Falha da rodada 2 | Situação |
|---|---|
| FALHA 1 — sem prova de que o aviso foi gerado | **Corrigida.** 1 `IntegrationLog__c` `ALERTA_ENVIADO` criado às 04:05:02Z para a Opp A. No Flow, `Log_Alerta_Enviado` só é alcançado depois de `Envia_Notificacao` terminar sem cair no `faultConnector` (que leva a `Log_Falha_Notificacao`, 0 registros). |

## Casos
| Caso | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|
| Disparo agendado | `CronTrigger` `08eHa00000XraqLIAR` | Rodou 1 vez às 04:05Z | `PreviousFireTime` 2026-11-16T04:05:00.285Z, `TimesTriggered` 1, próxima 17/11 04:05Z, WAITING | Passou |
| CA-02 / CA-04 — Opp A (aberta, 3 dias) alerta o dono | `IntegrationLog__c` criado depois de 03:55Z | 1 `ALERTA_ENVIADO`, Id de A, `DiasParado=3` | `a37Ha000002g8pdIAA`, `ResponseStatus__c` ALERTA_ENVIADO, `RequestBody__c` "006Ha00000QWpOcIAL \| DiasParado=3" | Passou |
| CA-03 — Opp B (2 dias) e C (1 dia, sem atividade, usa criação) não alertam | Mesmo log | Nenhum para B e C | Só 1 log novo no total (o de A) | Passou |
| CA-01 — Opp D fechada não alerta | Mesmo log | Nenhum para D | Idem | Passou |
| CA-06 — leitura pura | Contagens e `LastModifiedDate` | Sem alteração; só `IntegrationLog__c` cresce | Opportunity 9337, Account 1221, Order 10321, iguais ao antes; A a D com `LastModifiedDate` 2026-11-15T23:30:14Z, inalterado; `IntegrationLog__c` 846 para 847 (+1) | Passou |
| CA-07 — só canal interno | Revisão do Flow e dos logs | Só notificação interna, sem e-mail | Flow usa só `customNotificationAction`; sem Apex nem e-mail alert. Leitura de `/connect/notifications` como `005bJ00000piKAaQAM` voltou `[]` (a API não lista para esta sessão, como na rodada 2); o conteúdo visual do aviso não foi visto | Passou (canal); conteúdo na tela fica para o roteiro do cliente |
| CA-09 — falha/dono inativo | `IntegrationLog__c` com `FALHA_NOTIFICACAO` ou `DONO_INATIVO` | 0 (nenhum cenário) | 0 | Passou (cenário sem dono inativo) |
| CA-11 — volume | Job sobre toda a base da QAS | Termina sem erro | Job correu sobre 9337 oportunidades (abertas e fechadas), 1 alerta, 0 falhas. Carga sintética grande não foi criada | Passou parcialmente (sem carga sintética) |
| CA-05 — sem repetição no dia seguinte | Aguardar 17/11 04:05Z | 1 alerta por episódio | Não executável nesta sessão | Não executado |
| CA-08 — gestor desligado por padrão | Configuração | `NotificarGestor__c` falso | Falso no estado de antes (fase 1); sem usuário com gestor para exercitar ligado | Passou (padrão); ligado não executado |

## O que pode ter saído da org
- 1 `IntegrationLog__c` ALERTA_ENVIADO (`a37Ha000002g8pdIAA`) e 1 notificação interna ao dono `005bJ00000piKAaQAM` (dono das oportunidades de teste). Nenhum e-mail ou chamada externa.
- Dados de teste `TESTE EPLAST-28` (4 oportunidades A a D) criados na rodada 1 permanecem.

## Ressalvas para a homologação
CA-05 (dia seguinte), CA-08 ligado e a leitura do aviso na tela (sino) ficam para a homologação, via `05-roteiro-cliente.md`. Premissas P1 a P16 estão no design e no roteiro.
