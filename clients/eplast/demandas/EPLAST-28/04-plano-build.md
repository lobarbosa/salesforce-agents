**Resultado do build:** concluído

# EPLAST-28 — Plano de build (redesenho de 2026-11-17)

**Org:** `sbx-eplast-dev` (Org Id 00DHa000006vfMLMAY, conferida com `sf org list`). Branch `feature/EPLAST-28`. Deploy `0AfHa00000EJ4flKAD` (Succeeded, 9 componentes). Sem Apex; nada fora do design.

## Componentes
| Tipo | API name | Ação | Descrição preenchida |
|---|---|---|---|
| Campo CMDT | `AlertaOportunidadeParadaSetting__mdt.DiasEscalarGestor__c` | Criado (Number 3,0) | sim |
| Campo CMDT | `DiasSemAcompanhamento__c`, `NotificarGestor__c`, `RegraParada__c` | Descrição ajustada (tipo e picklist iguais) | sim |
| Registro CMDT | `AlertaOportunidadeParadaSetting.Default` | `DiasSemAcompanhamento__c` 14 -> 7; `RegraParada__c` -> `SoAtividade`; `DiasEscalarGestor__c` 14; `NotificarGestor__c` false; `Ativo__c` true; `DataCargaInicial__c` vazio. Conferido por SOQL na dev | n/a |
| Flow | `Opportunity_Scheduled_AlertaParada` | Versão nova, **Draft** (ver "Versões e ativação") | sim, cita EPLAST-28 |

Mudanças no Flow: `Alertar` -> `AlertarDono`; fórmula nova `AlertarGestor` (NotificarGestor__c, DiasEscalarGestor__c preenchido e maior que o do dono, dia igual ou carga inicial); `TituloAviso` = "Oportunidade sem atividade ha N dias"; `CorpoAviso` = nome da oportunidade; `GestorElegivel` sem a chave (a chave está em `AlertarGestor`); gestor fora da coleção do dono, com ramo próprio (`Deve_Alertar_Gestor` -> `Gestor_Elegivel` -> `Envia_Notificacao_Gestor`, coleção `DestinatariosGestor`); novos `Log_Alerta_Gestor_Enviado` (`ALERTA_GESTOR_ENVIADO`), `Log_Sem_Gestor` (`SEM_GESTOR`) e `Log_Falha_Notificacao_Gestor`. Os três finais do ramo do dono e o "não" do dono seguem para o ramo do gestor (independentes). Sem `recordUpdates`/`recordDeletes`; `recordCreates` só em `IntegrationLog__c`. Critério de entrada mantido (`IsClosed = false`, agendado diário 07:00). API 68.0.

## Versões e ativação
- Antes: v1 Active, v2 Draft. Depois (Tooling): **v1 Active (intocada), v2 Draft com o conteúdo novo**.
- Desvio do design (5.2 previa "versão seguinte à v2"): a plataforma sobrescreveu a v2, que era Draft nunca ativada e declarada obsoleta pelo design, em vez de criar a v3. A v1 ativa não foi editada. Número da versão nova: **2 (Draft)**. Não ativada.
- Ativação (passo separado, após a verificação): ativar a v2 e deixar a v1 inativa. Desfazer: reativar a v1 e restaurar o `Default` (14 / `AtividadeEEstagio`). Flow e `Default` sobem no mesmo deploy (R7). Na QA a esteira implanta (`05-deploy-qa.md`).

## Não alterados
`OpportunityTrigger`, `OpportunityFlow`, `Oportunidade_Industria`, `TriggerUtility__mdt`, `IntegrationLog__c` (estrutura), `Oportunidade_Parada`, `SFAgent2`.

## Pendências para a verificação
- Flow é Draft: a verificação deve ativar/exercitar na dev ou validar por revisão estática do XML e depois da ativação (passo separado). Enquanto v1 estiver ativa, o agendado roda a v1 com o `Default` novo (prazo 7, SoAtividade) e o texto antigo.
- Limites de notificação e de interviews diárias não conferidos (R6).
- CA-08 terceiro caso (gestor real) não exercitável: sem `ManagerId` na org.
- Teste do `Default` novo sem Flow novo ativo: ver nota acima.
