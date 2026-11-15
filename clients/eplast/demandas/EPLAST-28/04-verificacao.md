**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Sandbox, Org Id 00DHa000006vfMLMAY, conexão ativa; é a "eplast--qa" da Eplast, regra 5 da conta). Conferida com `sf org list`; é a única org conectada e não é produção.

# EPLAST-28 — Verificação (reverificação)

## Resumo
A construção existe na dev como descrita e a revisão estática passa. O comportamento do alerta (CA-01 a CA-09, CA-11) **não foi exercitado**: nenhum registro de teste foi criado e o Flow ainda não rodou sobre nenhuma oportunidade. Não há falha executada, então não é reprovação.

## Por que ficou sem prova
- A dev tem 0 Opportunity e 0 Task (contagem agregada). Sem registro, o Flow não tem o que avaliar.
- O Flow é Schedule-Triggered (próximo disparo 2026-11-16T10:00Z, 07:00 da org). Não há como dispará-lo sob demanda por `sf` ou Apex anônimo, e o debug do Flow só existe na interface.
- O alerta só sai quando `DiasParado = 14` exatamente. Isso exige oportunidade com `CreatedDate` no passado (a análise e o design dizem que depende da opção "Definir campos de auditoria na criação" habilitada) ou Task concluída com data passada, além de passar nas 16 validation rules de Opportunity. Não tentei criar esses dados: sem a opção de auditoria e sem como disparar o job, o resultado não provaria o critério.
- Também ficam fora: CA-07 em runtime (e-mail, Marketing Cloud), CA-08 com gestor, CA-09 com dono inativo, permissão do destinatário (design seção 6), sintaxe `Owner.IsActive` e `Owner.Manager.IsActive` em execução, e os limites oficiais de notificação e de interviews (o builder registrou que não conferiu).

## O que uma pessoa precisa fazer para provar
1. Na dev (ou na QA, pela esteira): habilitar "Definir campos de auditoria na criação" e criar oportunidades sintéticas `TESTE EPLAST-28 ...` que passem nas validation rules (dono com ID Usuário Protheus), com Task concluída datada em hoje menos 14 dias.
2. Rodar o Flow (debug na interface ou esperar o disparo das 07:00) e conferir notificação, `IntegrationLog__c` e contagens de Opportunity, Account, Order, Task e Event antes e depois (CA-06, achado 1 do assessment).
3. Duas sessões de QA para a automação agendada (arma e confere depois das 07:00), conforme o fluxo.
4. Conferir na documentação oficial os limites de notificação personalizada e de interviews diários antes da carga inicial.

## Tabela de casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Build existe | `sf data query --use-tooling-api` em Flow por DeveloperName | Versão ativa do Flow | `Opportunity_Scheduled_AlertaParada` v1, Active, AutoLaunchedFlow | passou |
| V2 | P4, P6 (parâmetros) | Query no CMDT `AlertaOportunidadeParadaSetting__mdt` | Default: ativo, 14 dias, AtividadeEEstagio, gestor desligado | `Default`, Ativo true, 14, AtividadeEEstagio, NotificarGestor false | passou |
| V3 | CA-07 (canal) | Query no `CustomNotificationType` | Tipo `Oportunidade_Parada` existe | 1 registro, pt_BR | passou |
| V4 | CA-06 (estático) | grep no XML do Flow: recordUpdates, recordDeletes, recordCreates | 0 updates, 0 deletes, creates só em `IntegrationLog__c` | 0, 0, 2 creates, ambos `IntegrationLog__c` | passou |
| V5 | CA-07 (estático) | grep de ações no XML | Só `customNotificationAction`, sem e-mail | Única ação: `customNotificationAction`; nenhum emailSimple | passou |
| V6 | Agendamento | Query em `CronTrigger` | Diário 07:00 | `Opportunity_Scheduled_AlertaParada-1`, WAITING, `0 0 7 ? * * *`, próximo 2026-11-16T10:00Z | passou |
| V7 | CA-10 (parcial) | Contagem de `GenAiPluginDefinition` e revisão do build | Nenhum agente novo | 23 tópicos hoje; sem referência antes do build para comparar; o plano de build não cria nada de agente | não executado (só o plano confere) |
| V8 | CA-12 | n/a | Sem Apex | Plano de build declara nenhum Apex | n/a |
| C1 | CA-01 elegibilidade | Não exercitado (0 Opportunity na dev) | Fechada não alerta, aberta é avaliada | Start do Flow filtra `IsClosed = false` (só leitura do XML) | não executado |
| C2 | CA-02 parada em N | Não exercitado | Dono notificado com o texto do design | — | não executado |
| C3 | CA-03 atividade recente | Não exercitado | Sem notificação | — | não executado |
| C4 | CA-04 sem atividade | Não exercitado | Alerta usando CreatedDate | — | não executado |
| C5 | CA-05 sem repetição | Não exercitado | Segunda execução não repete | — | não executado |
| C6 | CA-06 leitura pura (runtime) | Não exercitado | Contagens e LastModifiedDate iguais | — | não executado |
| C7 | CA-08 gestor | Não exercitado | Gestor só com a chave ligada | — | não executado |
| C8 | CA-09 dono inativo | Não exercitado | Log `DONO_INATIVO`, sem notificação | Consulta de `IntegrationLog__c` com DONO_INATIVO ou FALHA_NOTIFICACAO: 0 (Flow nunca rodou sobre registro) | não executado |
| C9 | CA-11 volume | Não exercitado | Sem erro de governador | — | não executado |

## Dados de teste
Nenhum criado, nenhum alterado, nenhum usuário modificado. Nada a apagar. O job agendado do Flow (`Opportunity_Scheduled_AlertaParada-1`) é da construção e foi mantido; o design deste Flow é schedule-triggered da plataforma, não um job Apex, então não bloqueia deploy de classe.

## O que pode ter saído da org
Nada. Nenhum registro foi criado por esta verificação e o Flow não rodou. `IntegrationLog__c` sem registros de FALHA_NOTIFICACAO ou DONO_INATIVO.

## Premissas
Seguem as P1 a P18 do design. Nenhuma foi motivo de reprovação.
