**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-16T00:10:00Z

# EPLAST-28 — Testes na QA, fase 1 (armar)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS da Eplast, Partial Copy). Fuso da org: America/Sao_Paulo (UTC-3). `05-deploy-qa.md` existe (deploy `0AfHa00000EI5QzKAL`, Succeeded). Presença na org conferida: Flow `Opportunity_Scheduled_AlertaParada` (versão 1 ativa e job `-1` agendado para 07:00 antes do arme), tipo de notificação `Oportunidade_Parada` e CMDT `AlertaOportunidadeParadaSetting` com registro `Default` (consultado por SOQL em `AlertaOportunidadeParadaSetting__mdt`: 14 dias, `AtividadeEEstagio`, gestor desligado, ativo).

Esta sessão não executa os casos de comportamento: o Flow é agendado e só roda no horário. A segunda sessão confere.

## O que foi alterado para armar (somente QA, não commitado)
Deploy `0AfHa00000EI5SbKAL` (Succeeded), de uma cópia fora do `force-app`:
1. Flow `Opportunity_Scheduled_AlertaParada`: início trocado de 2026-11-16 07:00 para **2026-11-15 20:55 (hora da org) = 23:55Z**, nada mais mudou. Gerou a versão 2, ativa. Conferido: `CronTrigger` `Opportunity_Scheduled_AlertaParada-2`, WAITING, `NextFireTime` 2026-11-15T23:55:00Z, cron `0 55 20 ? * * *`.
2. Registro `Default` do CMDT: `DiasSemAcompanhamento__c` 14 para **2** e `RegraParada__c` `AtividadeEEstagio` para **`SoAtividade`**. Motivo: `CreatedDate` não é gravável (`Field is not writeable: Opportunity.CreatedDate`, conferido por Apex em dry run com rollback) e `LastStageChangeDate` nasce com a data de hoje, então não há como fabricar uma oportunidade com 14 dias. Com atividade (Task concluída datada) e prazo 2, o mesmo Flow é exercitado. **Efeito: o prazo de 14 dias e a regra "atividade E estágio" não são provados em runtime nesta rodada.**
3. Como desfazer: a esteira reimplanta o build original (Flow com início 07:00 de 2026-11-16 e CMDT 14 / `AtividadeEEstagio`) antes da segunda sessão; confirmar lá.

Risco para dado real: com prazo 2 e `SoAtividade`, só alerta oportunidade aberta cuja última atividade (ou criação, se sem atividade) foi em 2026-11-13. Contagem agregada de reais nessa condição: **0** (com dono inativo: 0). Logo o único alerta esperado é o do dado de teste.

## Dado de teste criado (Apex anônimo, `TriggerUtility.bypassTrigger = true`, CNPJ fictício 11222333000181)
Dono das oportunidades: usuário ativo `005bJ00000piKAaQAM` (conta de serviço Konecta; perfil e permissões não alterados). Dono da Conta de teste: `005Hp00000gijVrIAI` (precisa de "ID Usuário Protheus" preenchido pela validation rule; usuário não alterado).
- Conta `TESTE EPLAST-28 Conta` — `001Ha000016UqejIAC`
- Opp A `TESTE EPLAST-28 A parada 2 dias` — `006Ha00000QWpOcIAL`: aberta (Qualificado), Task concluída com data 2026-11-13 (LastActivityDate 2026-11-13)
- Opp B `TESTE EPLAST-28 B atividade 1 dia` — `006Ha00000QWpOdIAL`: aberta, Task concluída 2026-11-14
- Opp C `TESTE EPLAST-28 C sem atividade` — `006Ha00000QWpOeIAL`: aberta, sem atividade, criada hoje
- Opp D `TESTE EPLAST-28 D fechada parada` — `006Ha00000QWpOfIAL`: Fechado/Perdido, Task concluída 2026-11-13
- 3 Tasks `TESTE EPLAST-28 atividade` (A, B, D). Contagem de Task subiu 4, não 3; a diferença é provavelmente Task automática de Flow existente (P3), a conferir na fase 2.

## Estado de antes (contagens agregadas, QA, ~23:30Z, após criar o dado de teste)
| Objeto | Contagem |
|---|---|
| Opportunity | 9332 (9328 sem o teste; 90 abertas antes) |
| Account | 1220 |
| Order | 10320 |
| Task | 8543 |
| Event | 5455 |
| IntegrationLog__c | 831 (0 com `IntegrationAction__c` = `Opportunity_Scheduled_AlertaParada`) |
| Maior `LastModifiedDate` de Opportunity real (antes do teste) | 2026-11-15T22:44:22Z |

## Esperado depois da execução (23:55Z)
| Caso | Critério | Esperado |
|---|---|---|
| E1 | CA-02, CA-07 | Opp A: uma notificação interna "Oportunidade parada ha 2 dias" para `005bJ00000piKAaQAM`, com nome, conta, estágio e data de referência; nenhum e-mail |
| E2 | CA-03 | Opp B: nenhuma notificação |
| E3 | CA-01 | Opp D (fechada): nenhuma notificação |
| E4 | CA-04 (parcial) | Opp C: nenhuma (referência = criação de hoje, 0 dias). O ramo "sem atividade, usa criação" só é provado em estática |
| E5 | CA-06 | Contagens de Opportunity, Account, Order, Task e Event iguais ao quadro; `LastModifiedDate` das 4 oportunidades de teste e do máximo real inalterados |
| E6 | CA-09 | `IntegrationLog__c` da ação do Flow: 0 (nenhum dono inativo entre elegíveis; inativo não pôde ser criado: `INACTIVE_OWNER_OR_USER`). Zero `FALHA_NOTIFICACAO` |
| E7 | Execução | Job `Opportunity_Scheduled_AlertaParada-2` executou (sumiu de WAITING ou NextFireTime avançou para 2026-11-16T23:55Z) |
| E8 | Notificação | Entrega confirmada só por ausência de `FALHA_NOTIFICACAO` e, se der, pelo sino do usuário de serviço; não há registro consultável de notificação |

Não executáveis nesta sandbox: CA-05 (repetição no dia seguinte, depende de dois dias), CA-08 com gestor ligado (nenhum usuário alterável com gestor), CA-09 com dono inativo real, CA-11 (volume: o dado real elegível é 0 e carga sintética grande não foi criada), prazo de 14 dias e regra combinada, `DataCargaInicial__c`. CA-10 e CA-12: estáticos (sem Apex, nenhum agente alterado), ver `04-verificacao.md`.

## O que pode ter saído da org
Dado de teste acima (nada apagado ainda; apagar na fase 2 depois de conferir). Uma notificação interna esperada para o usuário de serviço. Nenhuma chamada externa prevista.
