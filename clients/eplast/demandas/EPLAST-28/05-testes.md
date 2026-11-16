**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-16T03:16:00Z

# EPLAST-28 — Testes na QA, rodada 2, fase 1 (armar)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS, Partial Copy). Usuário da sessão: `005bJ00000piKAaQAM`, dono das oportunidades de teste. Fuso da org e do usuário: America/Sao_Paulo (UTC-3). Esta é a rodada seguinte à `05-testes-rodada-1.md` (reprovada: sem prova de execução do alerta). Pacote do build em `05-deploy-qa.md` (deploy `0AfHa00000EI9ETKA1`, Succeeded, 02:43Z); componentes conferidos na org: Flow, CMDT `AlertaOportunidadeParadaSetting__mdt` com registro `Default`, tipo de notificação `Oportunidade_Parada`.

## Por que a rodada 1 pode não ter provado nada (achado desta sessão)
Com o dado de teste da rodada 1 e `RegraParada__c = AtividadeEEstagio`, nenhuma oportunidade de teste poderia alertar: as Opps foram criadas em 2026-11-15, não têm `LastStageChangeDate`, e o Flow usa a data de criação como referência de estágio. Pela regra "a mais recente das duas", a referência delas era 15/11 (0 ou 1 dia parada). O arme da rodada 1 pode ter rodado e simplesmente não ter achado elegível. Nesta rodada o arme usa `SoAtividade`, que isola a atividade. A regra `AtividadeEEstagio` com 14 dias não é testável em sandbox sem um registro com estágio antigo (não alterável por DML nosso).

## Estado de antes (contagens agregadas, 2026-11-16T02:46Z)
Opportunity 9337, Account 1221, Order 10321, OrderItem 10008, Event 5455, Task 8544, `IntegrationLog__c` 843 (0 com `IntegrationAction__c = Opportunity_Scheduled_AlertaParada`). Máx. `LastModifiedDate`: Opportunity e Account 2026-11-16T01:49:42Z, Order 01:48:10Z. A org tem atividade concorrente (as contagens subiram em relação à rodada 1), então CA-06 se prova por `LastModifiedDate` e `LastModifiedBy` das 4 Opps de teste e por não haver Task/Event/log novo do alerta, não só por contagem total.
Notificações da caixa do usuário `005bJ00000piKAaQAM` (`sf api request rest /connect/notifications`): `[]`.
Dados de teste (da rodada 1, reaproveitados, nenhum DML meu nesta fase): Conta `001Ha000016UqejIAC` (`TESTE EPLAST-28 Conta`); Opps abertas dono `005bJ00000piKAaQAM`, estágio Qualificado:
| Opp | Última atividade (Task `TESTE EPLAST-28 atividade`) | Criada | Papel |
|---|---|---|---|
| `006Ha00000QWpOcIAL` A | 2026-11-13 | 11/15 | 3 dias na data do disparo |
| `006Ha00000QWpOdIAL` B | 2026-11-14 | 11/15 | 2 dias na data do disparo |
| `006Ha00000QWpOeIAL` C | nenhuma (referência = criação, 11/15) | 11/15 | 1 dia |
| `006Ha00000QWpOfIAL` D (fechada) | 2026-11-13 | 11/15 | fechada, 3 dias |

## O que foi alterado para armar (somente na QA, não commitado)
- Deploy `0AfHa00000EI9O9KAL` (02:58Z) só do CMDT `Default` e do Flow: `DiasSemAcompanhamento__c` 14 -> 2, `RegraParada__c` `AtividadeEEstagio` -> `SoAtividade`; Flow, versão nova 5 (Active, as anteriores Obsolete), início diário `startDate 2026-11-16`, `startTime 00:06` hora da org. Arquivos locais restaurados com `git checkout` (nada commitado).
- `CronTrigger` `08eHa00000XrHRTIA3` (`Opportunity_Scheduled_AlertaParada-5`): WAITING, `NextFireTime` 2026-11-16T03:06:00Z, `PreviousFireTime` nulo, `TimesTriggered` 0 (conferido às 02:58Z).
- Escolhi o início depois de 00:00 da org (03:00Z) de propósito: assim `TODAY()` é 2026-11-16 tanto em UTC quanto em Sao_Paulo e o resultado esperado não depende do fuso.
- Meu usuário: nenhuma alteração (nenhum permission set, nenhum valor).

## Resultado esperado depois da execução (DiasParado = 2026-11-16 menos a data de atividade; alerta só quando igual a 2)
- Opp B: 1 notificação "Oportunidade parada ha 2 dias" para `005bJ00000piKAaQAM`, corpo com nome da Opp, `TESTE EPLAST-28 Conta`, "Estagio: Qualificado", "desde 2026-11-14" (CA-02, CA-07; caixa de notificações passa de 0 para 1).
- Opp A (3 dias): nenhuma (o aviso sai só no dia exato, um por episódio, CA-05 por desenho; é como se tivesse alertado ontem). Opp C (1 dia) e Opp D (fechada): nenhuma (CA-03, CA-04 parcial, CA-01).
- `CronTrigger`: `PreviousFireTime` perto de 03:06Z e `TimesTriggered` 1.
- `IntegrationLog__c` com `Opportunity_Scheduled_AlertaParada`: 0 (nenhum dono inativo, nenhuma falha).
- Contagens: Account, Order, OrderItem, Event e Task sem aumento causado pelo alerta; as 4 Opps de teste com `LastModifiedDate` inalterado (2026-11-15T23:30:14Z) (CA-06).
- Não executáveis nesta sandbox: CA-05 (dia seguinte), CA-08 com gestor ligado (0 usuários com gestor na dev; não verificado na QA sem ler usuário), CA-09 com dono inativo (exigiria DML em Opp de teste com outro dono inativo, ver fase 2), CA-11 volume, carga inicial.
- Atenção (Partial Copy): existem 83 Opps abertas sem atividade criadas há mais de 3 dias (contagem). Com N = 2 e `SoAtividade`, o Flow também avaliará as reais; as de referência exatamente 2 dias gerarão notificações para os donos reais, só na QA. Não leio nem altero esses registros. Na fase 2, conferir só contagens (por exemplo `IntegrationLog__c`).

## Como desfazer
A esteira reimplanta o build original depois da sessão de conferência (CMDT 14 dias / `AtividadeEEstagio`, Flow início 07:00). Nada a desfazer manualmente; não commitar.

## Casos
Todos "não executado" até a fase 2 (a automação só roda no horário armado).
