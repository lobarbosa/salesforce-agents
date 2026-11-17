**Veredito:** aguardando execução
**Org de teste:** `sbx-eplast-qa`
**Conferir depois de:** 2026-11-17T11:28:00Z

# EPLAST-28 — Testes na QA, fase 1 (armar)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, Org Id 00DHa000006vZtmMAE, QAS, Partial Copy). Usuário de execução = o usuário de teste da regra 6, Id `005bJ00000piKAaQAM` (ativo, Administrador do sistema); nenhum permission set, valor ou perfil dele foi alterado. Inativo: `005bJ00000hBJmYQAW`.

## Pacote na QA
`05-deploy-qa.md` (deploy `0AfHa00000EJ4izKAD`, Succeeded): conferidos na org o CMDT `AlertaOportunidadeParadaSetting__mdt` com os 5 campos (incluindo `DiasEscalarGestor__c`), o registro `Default` (7 / 14 / `SoAtividade` / gestor false / carga inicial vazia) e o Flow `Opportunity_Scheduled_AlertaParada`. Nada faltando.

## Versão do Flow (ativação na QA)
- Antes: v1 a v6 Obsolete, **v7 Active** (versão da rodada anterior), v8 Draft (a da demanda, entregue inativa pelo deploy).
- Para armar, implantei só esse Flow com `<status>Active</status>` e o início trocado (deploy `0AfHa00000EJ4xVKAT`, depois `0AfHa00000EJ4z7KAD` para corrigir o fuso: a plataforma lê `startTime` no fuso da org, UTC-3). Conteúdo do Flow inalterado (mesmo XML do repositório).
- Depois: v7 e v8 Obsolete, **v9 Active** (`Opportunity_Scheduled_AlertaParada-9`, `CronTrigger` `08eHa00000Xtg0SIAR`, WAITING, `NextFireTime` 2026-11-17T11:18:00Z, `TimesTriggered` 0). Fica ativa ao final.

## O que foi alterado para armar (não commitado; a esteira reimplanta o build original)
1. Registro `Default` do CMDT: `DiasSemAcompanhamento__c` **7 -> 2** (só para o teste; o resto igual: `DiasEscalarGestor__c` 14, `SoAtividade`, `NotificarGestor__c` false, `Ativo__c` true). Motivo: sem permissão de "campos de auditoria" (`CreatedDate` não gravável, testado por Apex e REST), o único jeito de ter oportunidades com idade exata é usar a idade que elas têm hoje.
2. Início do Flow: 2026-11-17 11:18Z (08:18 no fuso da org) em vez de 07:00 diário.
Desfazer: reimplantar o build original (`Default` 7, início 07:00, o Flow ficará com a versão nova ativa).

## Dados de teste (todos `TESTE EPLAST-28`, dono `005bJ00000piKAaQAM`, conta de teste `001Ha000016UqejIAC`, tipo de registro `012bJ000000m049QAA`)
Criados por Apex com `TriggerUtility.bypassTrigger` (uma oportunidade por execução). Hoje = 2026-11-17 (dias = hoje menos a referência):
| Opp | Situação | Referência | Dias hoje | Esperado às 11:18Z (prazo 2) |
|---|---|---|---|---|
| A `006Ha00000QWpOcIAL` | aberta, tarefa concluída 13/11 | 13/11 | 4 | não alerta (4 != 2; aviso é no dia exato) |
| B `006Ha00000QWpOdIAL` | aberta, tarefa concluída 14/11 | 14/11 | 3 | não alerta |
| C `006Ha00000QWpOeIAL` | aberta, sem atividade, criada 15/11 | criação 15/11 | 2 | **alerta** (CA-04: sem atividade conta da criação) |
| D `006Ha00000QWpOfIAL` | fechada perdida, tarefa 13/11 | - | - | não alerta (CA-01) |
| F `006Ha00000QYi4VIAT` | tarefa concluída 15/11; depois **estágio mudou para Qualificação e valor 1234 hoje** | 15/11 | 2 | **alerta** (mudança de estágio e alteração administrativa não reiniciam) |
| G `006Ha00000QYnk5IAD` | tarefa concluída 15/11 + tarefa **aberta** "Amostra" vencimento 16/11 | 15/11 | 2 | **alerta** (tarefa aberta não reinicia) |
| H `006Ha00000QYnlhIAD` | tarefa concluída 16/11 | 16/11 | 1 | não alerta (tarefa concluída reinicia) |
| I `006Ha00000QYnnJIAT` | tarefa concluída sem data de vencimento, criada hoje | criação hoje | 0 | não alerta |

Medições já feitas (antes do disparo, por consulta, `LastActivityDate`): G ficou com **2026-11-15** apesar da tarefa aberta de 16/11 (tarefa aberta não conta, comportamento previsto pelo design, confirmado nesta org). I ficou **vazio** (tarefa concluída sem vencimento não gera `LastActivityDate`; o alerta usa a criação, hoje). F: `LastStageChangeDate` = hoje 11:06Z e `LastActivityDate` continua 15/11.

## Estado de antes (contagens agregadas, 11:06Z)
Opportunity 9341; Account 1221; Order 10321; Event 5455; Task 8549 (+5 das minhas tarefas e 0 de Account/Order/Event); `IntegrationLog__c` total 911, dos quais da ação `Opportunity_Scheduled_AlertaParada`: ALERTA_ENVIADO 1, nenhum outro status.
Candidatos reais com a mesma idade, só contagem: abertas com `LastActivityDate` = 15/11: 2 (as minhas F e G, ou seja 0 reais); abertas sem atividade criadas em 15/11 (dia do fuso da org): 7 (inclui C).

## Esperado depois da execução (para a fase 2)
- `CronTrigger` `08eHa00000Xtg0SIAR`: `PreviousFireTime` ~11:18Z, `TimesTriggered` 1.
- `IntegrationLog__c` novos com a ação do Flow: 1 `ALERTA_ENVIADO` para cada uma de C, F e G (`RequestBody__c` = `<Id> | DiasParado=2`); nenhum para A, B, D, H, I. Total esperado de logs novos por volta de 9 (7 sem atividade criadas em 15/11 + F + G), entre `ALERTA_ENVIADO` e `DONO_INATIVO`, com tolerância nas bordas de fuso. Zero `ALERTA_GESTOR_ENVIADO` e zero `SEM_GESTOR` (gestor desligado, CA-08). Zero `FALHA_NOTIFICACAO`.
- Contagens de Opportunity, Account, Order, Event e Task iguais às de antes; `LastModifiedDate` das oportunidades de teste inalterados (F: 11:06:24Z); só `IntegrationLog__c` cresce (CA-11).
- Sem agente novo: `GenAiPluginDefinition` e `GenAiFunctionDefinition` iguais (contagem a conferir na fase 2).
- Sino do usuário de teste: aviso "Oportunidade sem atividade há 2 dias" com o nome da oportunidade (captura por tela na fase 2, só de oportunidade de teste).
- Limites do Flow agendado: conferir na fase 2 que não houve erro em `FlowInterview`/log.

## Não exercitável nesta sandbox (declarar na fase 2)
- CA-08 com gestor real: 0 usuários com `ManagerId` e o design proíbe alterar usuário. Prova só o desligado. O ramo ligado com `SEM_GESTOR` exigiria ligar `NotificarGestor__c` por uma segunda rodada de arme; não está nesta (um único disparo por vez).
- CA-09 dono inativo: não consegui criar oportunidade de teste com dono inativo (não alterar usuário); só se aparecer `DONO_INATIVO` entre os registros copiados.
- CA-05 no dia seguinte (sem repetição): inferido pela regra de dia exato; reexecução não é possível na mesma sessão.
- Oportunidade sem atividade com idade exata de N dias por criação: só C (2 dias), pelo motivo da alteração 1.

## O que pode ter saído da org
- Dados de teste `TESTE EPLAST-28`: oportunidades F, G, H, I (novas) e as tarefas delas; mais as tarefas automáticas que os Flows de Oportunidade tenham criado (Task +5 no total).
- Na execução às 11:18Z: notificações internas (sino) aos donos das oportunidades que baterem o prazo, incluindo registros copiados da produção (automação da própria solução, autorizada). Nenhum e-mail, nada no Marketing Cloud, nada ao Protheus (nenhuma gravação em Account; a conta de teste não foi atualizada fora do bypass).
