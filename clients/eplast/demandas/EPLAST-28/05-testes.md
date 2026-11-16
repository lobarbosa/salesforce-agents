**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-16T04:15:00Z

# EPLAST-28 — Testes na QA, rodada 3, fase 1 (armar)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS). Deploy da esteira (`05-deploy-qa.md`, `0AfHa00000EI9xdKAD`, commit `f28902e4`) conferido: o Flow e o registro de configuração estão na org; o Flow chegou como versão 7 em Draft e a versão 6 era a ativa. Essa versão 7 é a que traz o rastro `ALERTA_ENVIADO` (correção da falha da rodada 2). Sem ela ativa, a QA não teria como provar o aviso.

## Estado de antes (contagens agregadas, 2026-11-16T03:50Z)
- Opportunity 9337; Account 1221; Order 10321; `IntegrationLog__c` 846; `IntegrationLog__c` com `ALERTA_ENVIADO` 0.
- Configuração: 14 dias, regra `AtividadeEEstagio`, ativo, gestor desligado, sem carga inicial.
- Dados de teste da rodada 1 (meus, `TESTE EPLAST-28`), data de referência = última atividade: A `006Ha00000QWpOcIAL` (aberta, 2026-11-13 = 3 dias em 16/11), B `006Ha00000QWpOdIAL` (aberta, 2026-11-14 = 2 dias), C `006Ha00000QWpOeIAL` (aberta, sem atividade, criada em 15/11 = 1 dia), D `006Ha00000QWpOfIAL` (fechada, 2026-11-13 = 3 dias). Dono: `005bJ00000piKAaQAM`.

## O que foi alterado para armar (únicas implantações da sessão, só na QA)
1. Flow `Opportunity_Scheduled_AlertaParada`: build original com status Active e início 01:05 hora da org (= 04:05Z, America/Sao_Paulo) em 16/11, nada mais mudou. Resultado: versão 7 Active, versão 6 Obsolete.
2. Registro de configuração: `DiasSemAcompanhamento__c` 3 (era 14) e `RegraParada__c` `SoAtividade` (era `AtividadeEEstagio`).
3. Conferido: `CronTrigger` `08eHa00000XraqLIAR` `Opportunity_Scheduled_AlertaParada-7`, WAITING, `NextFireTime` 2026-11-16T04:05:00Z.
Nenhuma mudança no meu usuário de execução. Nada commitado (arquivos locais restaurados).

## Esperado depois do disparo (04:05Z)
- Opp A (3 dias, aberta): 1 `IntegrationLog__c` `ALERTA_ENVIADO` com o Id de A e `DiasParado=3`, e 1 notificação ao dono.
- Opp B (2 dias), C (1 dia) e D (fechada): nenhum `ALERTA_ENVIADO` para elas (CA-03, CA-04 por prazo, CA-01).
- Mais, possivelmente, `ALERTA_ENVIADO` de oportunidades reais da QAS com exatamente 3 dias (autorizado, só contagem); nenhum `FALHA_NOTIFICACAO` esperado, `DONO_INATIVO` só se houver dono real inativo.
- CA-06: Opportunity, Account, Order e `LastModifiedDate` de A a D sem alteração; só `IntegrationLog__c` cresce (por alertas, 846 + N).
- `CronTrigger`: `PreviousFireTime` 04:05Z, `TimesTriggered` 1.
- Fase 2: conferir também o sino do dono (`/connect/notifications`) e o histórico de execução do Flow.

## Como desfazer
Nada manual: a esteira reimplanta o build original (14 dias, `AtividadeEEstagio`, Flow Draft com início 07:00) depois da fase 2.

## Casos ainda sem prova (todos aguardam a fase 2)
CA-01 a CA-04, CA-06, CA-07, CA-09, CA-11. CA-05 (dia seguinte, 17/11) e CA-08 (gestor) não são executáveis em uma sessão.
