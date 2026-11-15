**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev

# EPLAST-28 — Verificação do build (dev)

Org confirmada com `sf org list`: único alias `sbx-eplast-dev` (Sandbox, Connected). Todas as consultas usaram `--target-org sbx-eplast-dev`, só metadata e contagens agregadas. Nenhum registro foi criado, alterado ou apagado nesta verificação; nada ficou para limpar. Nenhum dado de cliente lido.

## Por que inconclusiva
O comportamento do Flow (CA-02 a CA-09, CA-11 e os extras) só se prova com oportunidades abertas e paradas. A dev tem 0 oportunidades (`SELECT COUNT(Id) FROM Opportunity` devolveu 0). Não criei dado sintético, por três motivos:
1. Criar Opportunity e Task passa por 16 validation rules, `OpportunityFlow` (grava em Order/Quote/Account/Task) e `TaskCreatedOrUpdated` (design seções 5 e 10, achado 1 do recon). Não confirmei por metadata que essa cadeia não chama sistema externo. `comentarios-do-card.md` só traz autorização de escopo; não autoriza testar com esse risco (regra 4 da verificação).
2. Datas no passado (`CreatedDate`) exigem "Definir campos de auditoria na criação", que não está habilitado na dev.
3. Flow agendado não tem como ser disparado sob demanda pela CLI. O próximo disparo é 2026-11-16 07:00 (fuso da org), fora desta sessão.

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Build implantado (plano) | `sf data query -t` em `Flow` por `Definition.DeveloperName` | Flow ativo | `Opportunity_Scheduled_AlertaParada`, Active, AutoLaunchedFlow, versão 1 | passou |
| V2 | Agendamento (design 10.3) | Query em `CronTrigger` | Diário 07:00, WAITING | `Opportunity_Scheduled_AlertaParada-1`, WAITING, `0 0 7 ? * * *`, próximo 2026-11-16T10:00Z | passou |
| V3 | CMDT de configuração (P4, P6, P16) | Query em `AlertaOportunidadeParadaSetting__mdt` | Default: ativo, 14 dias, AtividadeEEstagio, gestor desligado, carga vazia | Default: true, 14, AtividadeEEstagio, false, null | passou |
| V4 | Tipo de notificação | Query em `CustomNotificationType` | Existe `Oportunidade_Parada` | Existe ("Oportunidade Parada") | passou |
| CA-06 (estático) | Leitura pura | Contagem de elementos no XML do Flow | 0 `recordUpdates`/`recordDeletes`; `recordCreates` só em `IntegrationLog__c` | 0 updates/deletes; 2 `recordCreates`, ambos `IntegrationLog__c`; objeto Opportunity só no start | passou (estático; execução não provada) |
| CA-07 (estático) | Só canal interno | `actionType` no XML | Sem e-mail, sem Marketing Cloud | Única ação: `customNotificationAction` | passou (estático; execução não provada) |
| CA-10 | Sem agente novo | Leitura do build: nenhum componente GenAi no plano. Baseline `GenAiPluginDefinition` = 18 hoje, sem baseline anterior | Nenhum agente, tópico ou ação novo | Plano lista só CMDT, notificação e Flow; sem comparação antes/depois | passou parcialmente; tratado como não provado por execução |
| CA-12 | Cobertura Apex | Plano: nenhum Apex | Não se aplica | Não se aplica | não se aplica |
| CA-01 | Elegibilidade (aberta avaliada, fechada não) | Nada executado | — | 0 oportunidades na dev | não executado |
| CA-02 | Alerta em N dias com texto da P9 | Nada executado | — | sem dado | não executado |
| CA-03 | Atividade recente não alerta | Nada executado | — | sem dado | não executado |
| CA-04 | Sem atividade, criada há N dias alerta | Nada executado | — | sem dado | não executado |
| CA-05 | Sem repetição diária | Nada executado | — | sem dado e sem segunda execução | não executado |
| CA-06 (execução) | Contagens e LastModifiedDate iguais | Nada executado | — | sem dado | não executado |
| CA-07 (execução) | Nenhum e-mail nem chamada externa | Nada executado | — | sem execução | não executado |
| CA-08 | Gestor só com configuração ligada | Nada executado | — | sem dado | não executado |
| CA-09 | Dono inativo: sem notificação, log `DONO_INATIVO` | Nada executado. `IntegrationLog__c` com `DONO_INATIVO`/`FALHA_NOTIFICACAO` = 0 | — | Flow nunca rodou | não executado |
| CA-11 | Volume em lote, sem erro de limite | Nada executado | — | sem dado | não executado |
| Extra | `DataCargaInicial__c`, `Ativo__c = false` | Nada executado | — | sem dado | não executado |

## Resumo
- Passaram (estático/metadata): V1, V2, V3, V4, CA-06 e CA-07 estáticos. CA-10 só por leitura do plano.
- Falharam: nenhum.
- Sem prova: CA-01 a CA-05, CA-06 e CA-07 em execução, CA-08, CA-09, CA-11 e extras. Também ficam sem prova a sintaxe de runtime de `$Record.Owner.IsActive` e `$Record.Owner.Manager.IsActive`, a permissão do destinatário (design 6) e os limites oficiais de notificação e Flow agendado, que o builder não conferiu (plano, item 5 do design).

## O que uma pessoa precisa fazer para provar
1. Decidir se testa na dev ou na QA e confirmar se dev e QA são a mesma org (o alias `sbx-eplast-dev` aponta para uma org cujo usuário e URL se identificam como QA; comparar Org Id).
2. Revisar a cadeia de Opportunity e Task por metadata quanto a callout e e-mail. Se houver, o responsável pela conta autoriza por escrito, no card, o teste com esse risco.
3. Habilitar "Definir campos de auditoria na criação" na sandbox de teste.
4. Criar oportunidades sintéticas `TESTE EPLAST-28` que passem nas 16 validation rules, com Tasks concluídas em datas passadas.
5. Aguardar o disparo das 07:00 (ou ajustar o horário na sandbox de teste) e conferir as notificações e `IntegrationLog__c`. Isso segue o desenho de duas sessões de QA para automação agendada.
6. Conferir os limites oficiais antes da carga inicial.

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhuma automação foi disparada por esta verificação.
