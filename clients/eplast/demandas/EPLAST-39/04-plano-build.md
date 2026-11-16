**Resultado do build:** concluído

# EPLAST-39 — Plano de build (rodada 2, com correção da rodada 1 de QA)

**Org:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast = dev da esteira), conferida com `sf org list`. B1 resolvido pela regra 5 do CLAUDE.md do cliente e pelo card de 2026-11-15 09:58. Não toquei `sbx-eplast-qa`, produção nem Marketing Cloud.
**Branch:** `feature/EPLAST-39`. **Abordagem:** configuração nativa (campo fórmula, relatório, painel, permission set). Sem Flow, Apex, trigger ou e-mail. Sem DML em registro. Gate de design aprovado em 2026-11-16 (`gates.md`), E1 aceito.

## Componentes

Caminhos sob `force-app/main/default/`. Todos já implantados na dev (campo e 5 relatórios reconferidos por consulta de metadata nesta sessão) e sem diferença com o repositório.

| # | Componente | Ação | Caminho | Design |
|---|---|---|---|---|
| 1 | `Lead.MKT_Origem_Agrupada__c` (fórmula texto, com `Description`) | Criado | `objects/Lead/fields/MKT_Origem_Agrupada__c.field-meta.xml` | D1 |
| 2 | `MKT_Leads_por_Origem` | Alterado: bucket removido, agrupa pela fórmula, `CREATED_MONTH`, `showDetails false`, `timeFrameFilter` | `reports/Marketing_Origem_Retorno/MKT_Leads_por_Origem.report-meta.xml` | D3, D4 |
| 3 | `MKT_Conversao_Leads_por_Origem` | Alterado: idem; `CONVERTED:SUM / RowCount` | `reports/Marketing_Origem_Retorno/MKT_Conversao_Leads_por_Origem.report-meta.xml` | D3, D4 |
| 4 | `MKT_Desempenho_Campanhas` | Alterado: Tabular para Summary por `CAMPAIGN_NAME`; fórmula `IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)`; `ROI` nativo mantido | `reports/Marketing_Origem_Retorno/MKT_Desempenho_Campanhas.report-meta.xml` | D2 |
| 5 | `MKT_Oportunidades_por_Origem`, `MKT_Resposta_Membros_Campanha` | Reaproveitados (só filtro de período no primeiro) | mesma pasta | PA-04 |
| 6 | Painel `MKT_Origem_e_Retorno_Campanhas` | Alterado: `groupingColumn` dos componentes 1 e 2 para `Lead.MKT_Origem_Agrupada__c`; permanece `LoggedInUser` | `dashboards/Marketing_Origem_Retorno_Dash/MKT_Origem_e_Retorno_Campanhas.dashboard-meta.xml` | D3, D5 |
| 7 | `PS_Marketing_AnaliseCampanhas` | Alterado: +FLS leitura do campo novo, +`RunReports`; sem edição | `permissionsets/PS_Marketing_AnaliseCampanhas.permissionset-meta.xml` | D6, PA-06 |
| - | Pastas e grupo `Marketing_Origem_Retorno` | Reaproveitados | - | regra 3 |
| - | Flow, Apex, trigger, Marketing Cloud, `SFAgent2`, `et4ae5` | Nada criado nem tocado | - | CA-12 |

## Desvios do design (herdados da rodada 2, já registrados)

1. `TEXT(LeadSource)` no `CASE` da fórmula (picklist não entra em `CASE` sem `TEXT()`); mesma lógica, mesmos 13 valores.
2. Filtro de período por relatório, não de painel (sem exemplo de `dashboardFilters` na org; fallback D4, PA-05).
3. `MKT_Desempenho_Campanhas` e `MKT_Resposta_Membros_Campanha` ficam sem filtro de período: os tipos `CampaignList` e `CampaignLead` recusaram `timeFrameFilter` no deploy.
4. Rótulo próprio da coluna `ROI` não é aceito em XML; aparece com o nome padrão, ao lado da fórmula "Receita ganha / custo real".
5. Massa sintética não criada neste build (sem DML por instrução do orquestrador); a prova com dado fica para a verificação e o QA.

## Correções da rodada 1

Fonte: `05-testes-rodada-1.md` (QA na `sbx-eplast-qa`, reprovado). Decisão do card de 2026-11-16 00:10: opção 1, **sem mudança de metadata e sem mexer em perfil**; build mantém o metadata da rodada 2 como está.

| Falha | Situação |
|---|---|
| FALHA 1: componentes 1 e 3 do painel com erro 406/209 para quem não tem o PS | Sem alteração de metadata, por decisão do card. A causa é acesso: `Lead.MKT_Origem_Agrupada__c` só tem FLS via `PS_Marketing_AnaliseCampanhas`. Tratamento: o agente de QA atribui o PS a si mesmo só na QA e desfaz ao final (PR #208); atribuição aos usuários de Marketing segue como passo manual pós-deploy (PA-07). Não alterei perfil. |
| FALHA 2: CA-01, 02, 03, 05, 06, 07 (dado), 08, 09 e 11 (tela) não executados | Dependia da FALHA 1. Nada a corrigir no metadata; passam a ser exercitáveis com o PS atribuído ao usuário de execução do QA. |

Observação ao QA (D5): atualizar o painel por `PUT /analytics/dashboards/<id>`, não por `?refreshDashboard=true`. O caso sem permissão deve ser testado antes da atribuição do PS.

## Preparação do Sales Cloud para o Marketing Cloud

O build entrega só o lado do CRM: `Lead.MKT_Origem_Agrupada__c` serve de chave de segmentação por origem. Nada foi criado ou configurado no Marketing Cloud; consentimento e opt-out, jornada e envio ficam com quem o opera.

## Premissas assumidas usadas (design, seção 10)

P1 a P12 da análise e PA-01 a PA-07. Nenhuma tratada como bloqueio.

## Versões e ativação

Não se aplica: nenhum Flow, agente ou classe foi criado ou alterado.

## Pós-deploy manual (não feito)

Atribuir `PS_Marketing_AnaliseCampanhas` aos usuários de Marketing e incluir membros no grupo `Marketing_Origem_Retorno` (0 membros, 0 atribuições). O redeploy na QA fica com a esteira.

## Commits

Branch `feature/EPLAST-39`; ver `git log`.
