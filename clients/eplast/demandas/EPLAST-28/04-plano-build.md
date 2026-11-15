**Resultado do build:** concluído

# EPLAST-28 — Plano de build (builder-declarativo)

- **Org de dev usada:** `sbx-eplast-dev` (Org Id 00DHa000006vfMLMAY, API 68.0), conferida com `sf org list`. QA não tocada. Nenhum Apex.
- **Branch:** `feature/EPLAST-28`. Deploy final: ID `0AfHa00000EHswnKAD`, Succeeded.
- **Design seguido:** `03-design.md`, seções 4.1 e 10; sem alterar nenhum componente existente (4.2).

## Componentes criados (caminhos em `force-app/main/default/`)

| Tipo | API name | Arquivo |
|---|---|---|
| Custom Metadata Type | `AlertaOportunidadeParadaSetting__mdt` | `objects/AlertaOportunidadeParadaSetting__mdt/` |
| Campo CMDT | `Ativo__c` (Checkbox, padrão true) | `.../fields/Ativo__c.field-meta.xml` |
| Campo CMDT | `DiasSemAcompanhamento__c` (Number 3,0) | `.../fields/DiasSemAcompanhamento__c.field-meta.xml` |
| Campo CMDT | `RegraParada__c` (Picklist restrita: AtividadeEEstagio padrão, SoAtividade, SoEstagio) | `.../fields/RegraParada__c.field-meta.xml` |
| Campo CMDT | `NotificarGestor__c` (Checkbox, false) | `.../fields/NotificarGestor__c.field-meta.xml` |
| Campo CMDT | `DataCargaInicial__c` (Date, vazio) | `.../fields/DataCargaInicial__c.field-meta.xml` |
| Registro CMDT | `AlertaOportunidadeParadaSetting.Default` (Ativo true, 14 dias, AtividadeEEstagio, gestor false, carga vazia) | `customMetadata/` |
| CustomNotificationType | `Oportunidade_Parada` (desktop e mobile) | `notificationtypes/` |
| Flow Schedule-Triggered | `Opportunity_Scheduled_AlertaParada` (API 68.0, Active) | `flows/` |

Todos com `Description` citando EPLAST-28. Confirmado por `sf` antes de construir: `IntegrationLog__c` tem `IntegrationAction__c`, `ResponseStatus__c`, `ExecutionDate__c`, `RequestBody__c`; só existia o tipo de notificação `Novo_Pedido`; nenhum `AlertaOportunidade*` pré-existente.

## Flow: o que faz
Start em Opportunity com `IsClosed = false`, diário. Lê o CMDT `Default` e o tipo de notificação; `Ativo__c = false` encerra. `Alertar` = `DiasParado = DiasSemAcompanhamento__c` ou (hoje = `DataCargaInicial__c` e `DiasParado >= N`). Dono inativo: grava `IntegrationLog__c` `DONO_INATIVO` e encerra. Senão, destinatários = dono (+ gestor se `NotificarGestor__c`, gestor preenchido, ativo e diferente do dono) e envia a Custom Notification com alvo na oportunidade; fault grava `FALHA_NOTIFICACAO`. Título e corpo conforme P9, sem valor nem dado de contato.

## Revisão estática (item 4 do design)
- XML do Flow: 0 `recordUpdates`, 0 `recordDeletes`; `recordCreates` só em `IntegrationLog__c` (2).
- Sem e-mail, sem Marketing Cloud, sem Apex, sem permission set novo.
- Agendamento: `CronTrigger` criado `0 0 7 ? * * *`, próximo disparo 2026-11-16T10:00Z (07:00 no fuso da org), estado WAITING. Os 4 horários já ocupados (02:00, 06:00, 15:47, 17:36) não foram tocados.

## Observações e itens que ficaram sem prova
- **Limites oficiais (design 5.2, item 5): NÃO conferidos.** Esta sessão não tem acesso à documentação oficial e não vou citar de memória. Pendente: limite horário de notificações personalizadas e limite diário de interviews de Flow agendado (o limiar de 150.000 do design 1.3c também depende disso). Quem confere: QA/humano, antes da carga inicial (P16).
- **Permissão do destinatário (design 6):** não exercitada. Dev tem 0 oportunidades abertas (contagem agregada), então o Flow ainda não rodou sobre nenhum registro. A verificação tenta debug com registro sintético ou declara inconclusivo.
- **Dev x QA podem ser a mesma sandbox (R2):** o alias de dev aponta para `projetos@konectabr.com.eplast2.qa`. O Flow ativo já agenda nessa org. Comparar Org Id das duas antes do deploy de QA.
- Sintaxe de `$Record.Owner.IsActive` e `$Record.Owner.Manager.IsActive` aceita no deploy, mas o comportamento em tempo de execução só se prova com registro.
- `DataCargaInicial__c` não vai no registro `Default` (vazio, P16).

## Premissas assumidas
Seguem as P1 a P18 do `03-design.md` seção 8; nenhuma nova no build.
