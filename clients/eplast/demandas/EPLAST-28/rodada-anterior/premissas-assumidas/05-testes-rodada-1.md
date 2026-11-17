**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-28 — Testes na QA, fase 2 (conferir)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS, Partial Copy). Usuário da sessão: `005bJ00000piKAaQAM` (é também o dono das oportunidades de teste). Sessão em 2026-11-16T00:23Z, depois do horário armado (2026-11-15T23:55Z). O pacote do build original foi reimplantado pela esteira (`05-deploy-qa.md`, deploy `0AfHa00000EI6mrKAD`, 00:22Z). Nenhuma implantação minha nesta sessão.

## Falhas

### FALHA 1 (crítica) — Não há prova de que o alerta rodou nem de que a notificação do CA-02 chegou
- **Reproduzir:** depois do horário armado (23:55Z), consultar a org: job do Flow, notificações do dono da Opp A, logs.
- **Obtido:**
  - `CronTrigger` do arme (`Opportunity_Scheduled_AlertaParada-2`) não existe mais. Só existe `-3`, WAITING, `NextFireTime` 2026-11-16T10:00Z, `PreviousFireTime` nulo, criado pelo reimplante do build original. O `-2` sumiu e, como o reimplante o substituiu, o sumiço não prova execução.
  - Flow: versões 1 e 2 Obsolete, versão 3 Active.
  - `FlowInterview` com "AlertaParada" no nome: 0. `AsyncApexJob` desde 23:50Z: 0. `IntegrationLog__c` criado desde 23:00Z: 0 (inclusive `FALHA_NOTIFICACAO`).
  - Caixa de notificações do dono da Opp A (`GET /connect/notifications`, executado como `005bJ00000piKAaQAM`): `{"notifications": []}`. Esperado: uma notificação "Oportunidade parada ha 2 dias" para a Opp A (`006Ha00000QWpOcIAL`).
- **Esperado:** evidência de execução (job com `PreviousFireTime` ou notificação recebida) para a Opp A.
- **Causa provável:** o Flow não disparou no horário armado, ou disparou e a notificação não foi entregue ao dono. Com os dados disponíveis não dá para distinguir. Pelo protocolo, automação sem evidência de execução é falha. Investigar também se o reimplante do build cancelou o job antes da execução, e se o início armado (20:55 hora da org) caía antes de o deploy do arme ativar a versão 2.
- **Para o builder:** se possível, o Flow deve deixar um rastro consultável de cada execução (por exemplo, um registro em `IntegrationLog__c` também para execução bem-sucedida), para a QA conseguir provar CA-02, CA-03 e CA-07 sem depender do sino do usuário.

## Casos

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| E1 | CA-02, CA-07 | Conferir notificação do dono da Opp A após 23:55Z | 1 notificação com nome, conta, estágio, dias | Caixa de notificações vazia (acima) | Reprovado |
| E2 | CA-03 | Opp B (atividade 14/11) | Nenhuma notificação | Caixa vazia; mas sem prova de execução, a ausência não prova nada | Não executado (sem prova de execução) |
| E3 | CA-01 | Opp D fechada | Nenhuma notificação | Idem E2 | Não executado |
| E4 | CA-04 | Opp C sem atividade, criada hoje | Nenhuma notificação | Idem E2 | Não executado |
| E5 | CA-06 | Contagens e `LastModifiedDate` | Iguais ao "antes" | Opportunity 9332, Account 1220, Order 10320, Event 5455, IntegrationLog__c 831: iguais. Task 8543 antes, 4 criadas desde 23:00Z (as 3 de teste mais 1 de Flow existente, como já observado na fase 1). `LastModifiedDate` das 4 Opps de teste 2026-11-15T23:30:14Z, inalterado; máximo real 2026-11-15T22:44:22Z, inalterado | Aprovado (leitura pura, mas só vale se o Flow tiver rodado: sem prova) |
| E6 | CA-09 | Log de dono inativo | 0 logs, 0 `FALHA_NOTIFICACAO` | 0 e 0 | Aprovado, com a mesma ressalva |
| E7 | Execução | Job rodou | `PreviousFireTime` ou rastro | Nada consultável | Reprovado (FALHA 1) |
| E8 | Notificação | Sino do usuário | 1 item | 0 itens | Reprovado (FALHA 1) |
| Config | Reversão do arme | CMDT `Default` e job | 14, `AtividadeEEstagio`, início 07:00 | 14, `AtividadeEEstagio`, gestor falso, ativo; job `-3` para 2026-11-16T10:00Z (07:00 hora da org) | Aprovado: configuração original de volta |

Não executáveis nesta sandbox (como na fase 1): CA-05 (exige dois dias), CA-08 com gestor ligado, CA-09 com dono inativo real, CA-11 (volume), prazo de 14 dias e regra combinada, `DataCargaInicial__c`. CA-10 e CA-12 só estáticos (`04-verificacao.md`). Os critérios principais CA-02, CA-03 e CA-07 ficaram sem evidência de execução, o que por si reprova.

## Alterações no meu usuário
Nenhuma nesta sessão (nenhum permission set atribuído, nenhum valor alterado).

## O que pode ter saído da org
Dado de teste da fase 1, ainda na QA, não apagado (apagar dispara automações de Task e Account; a esteira ou o próximo QA decide): Conta `001Ha000016UqejIAC`; Opps `006Ha00000QWpOcIAL`, `006Ha00000QWpOdIAL`, `006Ha00000QWpOeIAL`, `006Ha00000QWpOfIAL`; 3 Tasks `TESTE EPLAST-28 atividade`. Notificação para o usuário de serviço: nenhuma encontrada. Nenhuma chamada externa registrada.
