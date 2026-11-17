**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-28 — Verificação do build

Org conferida com `sf org list`: `sbx-eplast-dev`, Org Id 00DHa000006vfMLMAY, Sandbox, Connected. Todas as consultas usaram `--target-org sbx-eplast-dev`. Nenhum dado foi criado, alterado ou apagado, e nenhum usuário foi tocado. Só metadata e contagens agregadas.

## Por que inconclusiva
A v2 do Flow está em Draft, e o design (seção 5.2, "Ativação") e o plano mandam ativá-la depois da verificação, como passo separado. Um Flow agendado em Draft não roda por Apex, `Flow.Interview` nem pelo agendamento, e eu não ativei o Flow, porque nem o design nem o plano autorizam a ativação na dev. Por isso o comportamento novo não foi exercitado: os alertas ao dono e ao gestor, o texto do aviso, a deduplicação e o ramo `SEM_GESTOR`. A v1 Active segue agendada, com o `Default` novo (7 / `SoAtividade`) e o texto antigo.

Não existe `clients/eplast/fixtures/` neste branch (conferido com `find`). Mesmo com o Flow ativo, a massa de oportunidades e tarefas teria de ser montada do zero, e isso passa por trigger, validation rules e `TaskCreatedOrUpdated`. Eu não montei essa massa, porque não havia o que dispará-la.

## Tabela de casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Versão (design 9) | `SELECT VersionNumber, Status FROM Flow` (Tooling), por `Definition.DeveloperName` | v1 Active intocada, versão nova Draft | v1 Active, v2 Draft | passou |
| V2 | CA-12 (config) | SOQL no CMDT `AlertaOportunidadeParadaSetting__mdt` | `Default`: Ativo true, 7, `SoAtividade`, gestor 14, `NotificarGestor__c` false, carga inicial vazia | Os valores batem com o esperado | passou |
| V3 | CA-11 (estático) | Metadata da v2 lida pela Tooling API | Sem `recordUpdates`/`recordDeletes`; `recordCreates` só em `IntegrationLog__c` | 0 updates, 0 deletes; 6 creates, todos em `IntegrationLog__c` | passou |
| V4 | CA-03 (estático) | Fórmulas da v2 | Título com N dias; corpo só com o nome; alvo é o Id da oportunidade | `TituloAviso` = "Oportunidade sem atividade ha " & N & " dias"; `CorpoAviso` = `$Record.Name`; `targetId` = `$Record.Id`. O título está sem acento ("ha"), e o design diz "há". É desvio cosmético, mas a v2 precisa ser corrigida antes de ativar. | passou, com ressalva |
| V5 | CA-02/12 (estático) | Fórmula `AlertarDono` | `DiasParado` = prazo, ou carga inicial com `>=` | Fórmula conforme o design; nenhum ramo repete aviso diário | passou (estático) |
| V6 | CA-08 (estático) | Fórmula `AlertarGestor` e ramo do gestor | Exige `NotificarGestor__c`, prazo do gestor preenchido e maior que o do dono; dia igual ou carga inicial; gestor fora da coleção do dono; `SEM_GESTOR` se não houver gestor elegível | Fórmula e wiring conferem. `Deve_Alertar_Gestor` e `Gestor_Elegivel` têm destino próprio, e `DestinatariosGestor` recebe `Owner.ManagerId`. Os finais do ramo do dono e o "não" seguem para o ramo do gestor. | passou (estático) |
| V7 | CA-01 | Filtro de entrada da v2 | `IsClosed = false`, agendado diário | Filtro `IsClosed EqualTo`; frequência Daily, início 07:00Z | passou (estático) |
| V8 | CA-12 (`Ativo__c`) | Decisão `Chave_Geral` | `Ativo__c = true` para seguir | Conforme | passou (estático) |
| V9 | Antes do disparo | `COUNT()` de `Opportunity` e de `IntegrationLog__c` com a ação `Opportunity_Scheduled_AlertaParada` | Linha de base | 0 e 0 (a dev não tem Opportunity) | passou (linha de base) |
| E1 | CA-01, 02, 04, 05, 06, 07, 09 | Não exercitado: exige ativar a v2 e massa sintética | Logs `ALERTA_ENVIADO` e `DONO_INATIVO` conforme o caso | Sem execução | não executado |
| E2 | CA-03 (sino) | Não exercitado: sem aviso gerado | Título e corpo no sino | Sem execução | não executado |
| E3 | CA-08 (gestor desligado e `SEM_GESTOR`) | Não exercitado: a v2 não roda em Draft | Nenhum aviso com false; `SEM_GESTOR` uma vez com true e sem `ManagerId` | Sem execução | não executado |
| E4 | CA-08 (gestor real) | Sem prova: a org não tem usuário com `ManagerId` e o design não cria nem altera usuário | `ALERTA_GESTOR_ENVIADO` ao gestor | Sem execução | não executado |
| E5 | CA-10, CA-11 (dinâmico) | Não executado: sem disparo, antes e depois não têm o que comparar | Contagens de negócio iguais; nenhum agente novo | Só a revisão estática da V3 | não executado |
| E6 | Volume e limites (R6) | Não conferido: limites de notificação e de interviews diárias não confirmados pela documentação e não citados de memória | Medição abaixo de 70% | Não medido | não executado |

## O que ficou sem prova e o que fazer
1. Todo o comportamento dinâmico da v2 (CA-01 a CA-09, CA-11 e CA-12 em execução), a captura do sino (CA-03) e o volume. Duas pessoas podem resolver:
   - Quem administra a dev: ativar a v2 na dev e reexecutar a verificação, com a massa pelas fixtures (conta com `TriggerUtility.bypassTrigger` e CNPJ fictício, nome `TESTE EPLAST-28`, poucos registros).
   - Ou a esteira: provar tudo nas duas sessões de QA previstas no design (arma e confere). Lá o Flow entra pelo deploy (`05-deploy-qa.md`).
2. CA-08 com gestor real: precisa de um par dono/gestor de teste com `ManagerId`. A org não tem e o design proíbe alterar usuário.
3. Limites de notificações personalizadas por hora e de interviews diárias do Flow agendado (R6): conferir na documentação oficial.

## Ajuste sugerido ao builder (não é falha de caso)
O título está como "ha" em vez de "há". Corrigir antes de ativar, se a org aceitar o caractere no XML.

## O que pode ter saído da org
Nada. Não foi criado registro nem acionada automação.

## Alterações de usuário e limpeza
Nenhuma alteração no usuário de execução (sem permission set, sem Marketing User, sem campo Protheus). Não há dado de teste a apagar nem job Apex agendado pela verificação.
