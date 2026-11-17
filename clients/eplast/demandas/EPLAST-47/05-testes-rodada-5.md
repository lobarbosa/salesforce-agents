**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`)

# EPLAST-47 — Testes na QA (rodada 5: classificar a conta ao salvar a oportunidade)

`sf org list`: só `sbx-eplast-qa` (Connected). Todo comando com `--target-org` explícito. Esta rodada reteste só o que mudou (Q8, decisão do responsável em 17/11, `03-design.md`, última seção). Nenhum dado foi criado nem alterado nesta rodada; nenhuma mudança no meu usuário de execução.

Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EJ3yDKAT`, Succeeded, commit `9ae3a173`): `Opportunity_AfterSave_ClassificaConta` existe e está Active (v2; v1 Obsolete); `RankingRange__mdt` com 7 faixas (MP 10.000, PP 35.000, P 80.000, M 160.000, G 500.000, GG 1.000.000, 3G sem teto, `SortOrder__c` 1 a 7); `ScheduledFlowOpportunity` existe. Componentes presentes.

## Falhas

### FALHA 1 (crítica) — o deploy da esteira não desativou o `ScheduledFlowOpportunity` na QA (Q8 reprovado de novo)
- **Reproduzir:** `sf data query -t --target-org sbx-eplast-qa -q "SELECT VersionNumber, Status, LastModifiedDate FROM Flow WHERE Definition.DeveloperName='ScheduledFlowOpportunity' AND VersionNumber>=7"` e `SELECT CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'ScheduledFlowOpportunity%'`.
- **Obtido:** v8 **Active**, criada pelo deploy de 2026-11-17T08:40:49Z (v1 a v7 Obsoletas). `FlowDefinitionView`: `ActiveVersionId` = `LatestVersionId` = v8. `CronTrigger` `ScheduledFlowOpportunity-8` em `WAITING`, próxima execução 2026-11-17T18:47Z.
- **Esperado:** (decisão 1 do design) sem versão ativa e sem agendamento pendente na QA depois do deploy.
- **Causa provável:** o pacote leva `flowDefinitions/ScheduledFlowOpportunity.flowDefinition-meta.xml` com `activeVersionNumber` 0, mas `flows/ScheduledFlowOpportunity.flow-meta.xml` continua com `<status>Active</status>` (linha 540). O deploy criou a v8 já ativa e o `activeVersionNumber` 0 não prevaleceu. Correção sugerida: no XML do Flow, trocar para `<status>Obsolete</status>` (ou `Draft`) junto com a definição em 0; ou tirar o Flow do pacote e fazer a desativação só pela definição; confirmar na dev por `FlowDefinitionView.ActiveVersionId` nulo e `CronTrigger` ausente antes de reenviar.
- **Impacto:** o agendado antigo é o que na rodada 3 falhou com "Too many queueable jobs added to the queue: 51" em 162 contas. Segue ativo na QA e rodaria no dia configurado, disputando a conta com o Flow novo. Não o desativei (não implanto; DML meu sobre ele não é permitido).
- **Retestes da rodada anterior:** FALHA 1 da rodada 4 (agendado ativo): **não corrigida**.

## Casos

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| Q8 | estado / PA14 | Consultar Flow (Tooling), `FlowDefinitionView` e `CronTrigger` na QA | Sem versão ativa, sem `CronTrigger` em espera | v8 Active; `CronTrigger` `ScheduledFlowOpportunity-8` WAITING, 2026-11-17T18:47Z | **reprovado (FALHA 1)** |
| Pacote | — | Conferir componentes de `05-deploy-qa.md` | Existem na QA | Flow novo Active v2, 7 faixas em `RankingRange__mdt` com os valores acima | passou |
| Regressão da classificação (3 bordas) | 10 | Pedida pelo design para esta rodada | MP/PP/3G nas bordas | Não executada: o defeito do pacote já reprova a rodada e evitei criar massa na QAS (Partial Copy) sem necessidade. Vale a evidência da rodada 4 (12 bordas passaram, deploy `0AfHa00000EJ3a1KAD`, mesmo Flow novo e mesmas faixas) | não executado nesta rodada |
| Q1, Q2, Q3, Q4, Q5, Q6, 12, 15 | 4, 6, 8, 9, 10, 11, 13, 14 | — | — | Evidência da rodada 4 (`05-testes-rodada-4.md`): todos passaram | herdado da rodada 4, não reexecutado |
| Q7 / V6 (falha forçada) | 16 | — | — | Não exercitável pela esteira (decisão 2 do design: regra `CheckAccountOwnerHasProtheusSellerId` barra a oportunidade antes do Flow novo). Caminho de falha provado só por leitura do Flow. Vai para a homologação, sem reprovar | não executado (validar na homologação) |
| 5, 7, 18 | — | Não se aplicam (design, seção 8 e PA5) | — | — | não aplicável |

Evidência de tela: nenhuma captura. A verificação é por consulta (Tooling, `FlowDefinitionView`, `CronTrigger`).

## Alterações no usuário de execução
Nenhuma nesta rodada.

## O que pode ter saído da org
Nada: nenhum registro criado, alterado ou apagado. Nenhum e-mail, chamada ao Protheus ou ação no Marketing Cloud.

## Motivo do veredito
Reprovado só pela FALHA 1: o pacote da esteira deixou o agendado ativo e armado na QA, o que a decisão de 17/11 definia como defeito do pacote. O critério 16 não reprova (vai à homologação). Corrigida a desativação e reenviada, basta reconferir Q8 e 3 bordas.
