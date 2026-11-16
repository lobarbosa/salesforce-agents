**Resultado do build:** concluído

# EPLAST-44 — Plano de build (builder-declarativo)

**Org:** `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, Connected, conferida com `sf org list`). Branch `feature/EPLAST-44`. Sem produção, sem QA, sem Marketing Cloud.

## Contagem da pasta antes do build (CA-05)
- `SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'` antes: **64** (o design previa 63). A diferença é o relatório `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`, criado na dev em 2026-11-16T00:15Z, fora desta demanda. Não alterado.
- Depois do deploy: **65** (64 + 1). `LEADS_BOAS_VINDAS` não existia antes (conferido por SOQL).

## Componentes criados
| # | Tipo | API name | Arquivo | Descrição |
|---|---|---|---|---|
| C1 | Report (LeadList, Tabular) | `MARKETINGCLOUD/LEADS_BOAS_VINDAS` (nome "LEADS - BOAS-VINDAS", Id `00OHa000002zH1BMAU`) | `force-app/main/default/reports/MARKETINGCLOUD/LEADS_BOAS_VINDAS.report-meta.xml` | Preenchida (texto da seção 3.1 do design) |

Especificação aplicada: colunas FIRST_NAME, LAST_NAME, COMPANY, STATE, Lead.Sector__c, LEAD_SOURCE, STATUS, CREATED_DATE, Lead.PriorityBand__c, EMAIL; filtro de data padrão `CREATED_DATE` = `INTERVAL_LAST7` (últimos 7 dias; ponto configurável, PD-03); `CONVERTED = false`; `EMAIL_OPT_OUT = false`; `STATUS ≠ "Fechado - Não convertido"`; escopo `org`; sem filtro de opt-out de celular (PD-06). Campos `Sector__c` e `PriorityBand__c` de Lead confirmados na org.

## Deploy
- `sf project deploy start --dry-run` (só o relatório): sucesso. Deploy real: sucesso, 1 componente.
- Pasta `MARKETINGCLOUD` não foi incluída no pacote (já existe; compartilhamento intocado). Report e ReportFolder recuperados só como molde foram removidos do repositório.
- Conferência pós-deploy: por retrieve do relatório implantado (formato Tabular, escopo org, `INTERVAL_LAST7`, os 3 filtros acima). O describe pela Analytics API retornou FORBIDDEN para o usuário de execução (pasta `Hidden`), por isso a conferência foi feita pelo metadata. O verificador deve exercitar o relatório por outro meio (contagem agregada).
- Pacote sem `EmailTemplate`, `WorkflowAlert`, Flow, Apex ou campo (CA-04): só 1 arquivo de relatório.

## Reuso (regra 3)
R1 `LEADS_PROSPECCAO_PRIORIDADE`, R2 `POTENCIAIS_SEM_COMPRA`, R3 `COMPRA_ULTIMOS_90_DIAS`, R4–R6 `SEM_COMPRA_91_A_180_DIAS`, `SEM_COMPRA_181_A_365_DIAS`, `SEM_COMPRA_MAIS_DE_365_DIAS`, R7–R8 `MSG_LEADS_CELULAR_APTOS`, `MSG_CONTATOS_CELULAR_APTOS`: todos existem na pasta `MARKETING CLOUD` da dev (conferido por SOQL de DeveloperName) e atendem J2–J5 e canal mensagem; não alterados. Filtros de R1 conferidos no metadata baixado (faixa ≠ "Sem dados suficientes", opt-out de e-mail e celular, não convertido). Criação de C1 justificada: nenhum relatório da pasta recorta lead por criação recente. `PS_Marketing_Publicos`, `SFAgent2`, Flow `Lead_AfterInsert_AplicaRegraAtribuicao`: não tocados.

## Versões e ativação
Nenhum Flow, agente ou classe alterado; sem versão nova nem ativação.

## Premissas
PD-01 e PD-02 e demais premissas do design seguidas sem alteração; nenhuma pendência de negócio.
