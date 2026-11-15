**Resultado do build:** concluído

# EPLAST-39 — Plano de build (rodada 2)

**Org:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast = dev da esteira, `projetos@konectabr.com.eplast2.qa`, Org Id 00DHa000006vfMLMAY), conferida com `sf org list`. B1 resolvido pelo card (2026-11-15 09:58) e pela regra 5 do CLAUDE.md do cliente. Não toquei `sbx-eplast-qa`, nem produção, nem Marketing Cloud.
**Branch:** `feature/EPLAST-39`. **Abordagem:** configuração nativa (campo fórmula, relatório, painel, permission set). Sem Flow, Apex, trigger ou e-mail. Sem DML em registro.
**Commits:** ver seção final.

## Componentes

Todos os caminhos sob `force-app/main/default/`. Todo deploy abaixo foi `Succeeded` na dev.

| # | Componente | Ação | Caminho | Design |
|---|---|---|---|---|
| 1 | `Lead.MKT_Origem_Agrupada__c` (fórmula texto) | **Criado** (E1 aceito no gate de design); dry-run antes | `objects/Lead/fields/MKT_Origem_Agrupada__c.field-meta.xml` | D1 |
| 2 | `MKT_Leads_por_Origem` | **Alterado**: bucket removido, agrupa pela fórmula, mantém `CREATED_MONTH`, `showDetails false`, `scope org` | `reports/Marketing_Origem_Retorno/MKT_Leads_por_Origem.report-meta.xml` | D3 |
| 3 | `MKT_Conversao_Leads_por_Origem` | **Alterado**: idem; mantém `FORMULA1 = CONVERTED:SUM / RowCount` | `reports/Marketing_Origem_Retorno/MKT_Conversao_Leads_por_Origem.report-meta.xml` | D3 |
| 4 | `MKT_Desempenho_Campanhas` | **Alterado**: Tabular para Summary agrupado por `CAMPAIGN_NAME`; `Sum` em custo, valor ganho etc.; `FORMULA1 = IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)`; `ROI` nativo mantido; `showDetails false` | `reports/Marketing_Origem_Retorno/MKT_Desempenho_Campanhas.report-meta.xml` | D2 |
| 5 | `MKT_Oportunidades_por_Origem`, `MKT_Resposta_Membros_Campanha` | Reaproveitados; só ganharam filtro de período (item 8) | idem, pasta `reports/Marketing_Origem_Retorno/` | PA-04 |
| 6 | Painel `MKT_Origem_e_Retorno_Campanhas` | **Alterado**: `groupingColumn` dos componentes 1 e 2 passou de `BucketField_Origem` para `Lead.MKT_Origem_Agrupada__c`. Componente 4 já tinha `aggregate Sum` e agora o relatório tem a agregação. Permanece `LoggedInUser` | `dashboards/Marketing_Origem_Retorno_Dash/MKT_Origem_e_Retorno_Campanhas.dashboard-meta.xml` | D3, D5 |
| 7 | `PS_Marketing_AnaliseCampanhas` | **Alterado**: +FLS leitura `Lead.MKT_Origem_Agrupada__c`, +`RunReports`; descrição encurtada (limite de 255 caracteres). Sem edição | `permissionsets/PS_Marketing_AnaliseCampanhas.permissionset-meta.xml` | D6, PA-06 |
| 8 | Filtro de período (CA-05, fallback D4) | `timeFrameFilter` sobre `CREATED_DATE`, `INTERVAL_CUSTOM` 2000-01-01 a 2099-12-31 (todo o período), nos relatórios de Leads, Conversão e Oportunidades (sintaxe copiada de relatório da org, `LeadsbySource`) | nos 3 relatórios | D4, PA-05 |
| - | Pasta, grupo `Marketing_Origem_Retorno`, pasta do painel | Reaproveitados, sem alteração | - | regra 3 |
| - | Flow, Apex, trigger, Marketing Cloud, `SFAgent2`, `et4ae5` | Nada criado nem tocado | - | CA-12 |

## Desvios do design (e por quê)

1. **Fórmula usa `TEXT(LeadSource)` no `CASE`.** O design escreveu `CASE(LeadSource, ...)`; campo picklist não entra em `CASE` sem `TEXT()`. Mesma lógica, mesmos 13 valores; só a sintaxe mudou.
2. **Filtro de período por relatório, não de painel.** O design pedia tentar o filtro de painel com sintaxe copiada de exemplo da org. Procurei: não há `dashboardFilters` no repositório e os 6 painéis que consultei pela API não têm filtro. Sem exemplo para copiar, não adivinhei e usei o fallback do design (PA-05).
3. **Dois relatórios ficam sem filtro de período.** `CampaignList` (`MKT_Desempenho_Campanhas`) e `CampaignLead` (`MKT_Resposta_Membros_Campanha`) foram recusados pelo deploy ("report type does not support time frame filter"). Retirado, sem segunda tentativa de coluna. CA-05 vale para os 3 relatórios de lead e oportunidade; o desempenho de campanha mostra todas as campanhas.
4. **Rótulo próprio da coluna `ROI`** (PA-02): o XML de relatório não aceita rótulo para coluna padrão. O ROI nativo aparece com o nome padrão e, ao lado, a fórmula "Receita ganha / custo real". Rótulo só por edição na tela.
5. **Massa sintética não criada** (passo 6 do design): por instrução do orquestrador, o builder não faz DML. A org dev tem 0 registros; a prova com dado fica para a verificação.

## Verificação feita no build (Analytics API, só leitura)

`PUT /analytics/dashboards/01ZHa000001uFevMAE` + `GET .../status` + `GET` do painel:
- **Desempenho de Campanhas (F1, erro 209): resolvido.** Sem erro.
- Oportunidades e Valor por Origem, Respondentes por Campanha: sem erro.
- **Leads por Origem (erro 406) e Taxa de Conversão (erro 209): com erro nesta org, por causa de permissão, não de metadata.** O usuário que roda o painel (`LoggedInUser`) não tem FLS no campo novo: `FieldPermissions` do campo só tem o PS `PS_Marketing_AnaliseCampanhas` e um PS do sistema, e o PS tem 0 atribuições (PA-07, atribuição manual). Os relatórios foram aceitos no deploy. **Pré-condição da verificação:** atribuir `PS_Marketing_AnaliseCampanhas` ao usuário de teste na dev (atribuição de PS é passo manual; não fiz, por ser alteração de acesso fora do design) e atualizar o painel de novo com `PUT`. Se o erro persistir depois disso, é defeito de build.

## Como cada CA é atendido

| CA | Atendimento | Estado |
|---|---|---|
| CA-01 soma = total | Agrupamento pela fórmula cobre todo lead (vazio, 13 valores, resto); `showGrandTotal` ligado | A provar com massa (verificação) |
| CA-02 vazio = "Sem origem" | Fórmula (P1) | A provar com massa |
| CA-03 "Fora da lista" numa linha | Fórmula | A provar com massa |
| CA-04 lista = picklist | 13 valores da fórmula conferidos por describe no design | Por metadata |
| CA-05 período | `timeFrameFilter` nos 3 relatórios de lead/oportunidade; fora nos de campanha (desvio 3) | Parcial |
| CA-06 conversão | `FORMULA1` mantida sobre o novo agrupamento | A provar com massa |
| CA-07 painel sem erro | 3 de 5 componentes sem erro; 2 dependem do PS atribuído (seção acima) | Pendente da pré-condição |
| CA-08 retorno por campanha | Fórmula Receita ganha / custo real + `ROI` nativo | A provar com massa |
| CA-09 campanha sem custo | `IF(ACTUAL_COST:SUM > 0, ..., null)`: célula em branco (PA-03) | A provar com massa |
| CA-10 nada existente alterado | Só os itens da tabela; 380 relatórios / 20 painéis fora da pasta intactos | Atendido |
| CA-11 somente leitura | PS sem edição, com Read + FLS leitura + `RunReports` | Atendido por metadata |
| CA-12 sem envio nem automação | Nenhum Flow/Apex/trigger/e-mail; nada no Marketing Cloud | Atendido |
| CA-13 sem dado pessoal | `showDetails false`; nenhuma coluna pessoal | Atendido |
| CA-14 ambiente | Regra 5 do CLAUDE.md do cliente e card de 2026-11-15 | Atendido |

## Preparação do Sales Cloud para o Marketing Cloud
O build entrega só o lado do CRM: `Lead.MKT_Origem_Agrupada__c` serve de chave de segmentação por origem. Nada foi criado ou configurado no Marketing Cloud; consentimento/opt-out, jornada e envio ficam com quem o opera.

## Premissas assumidas usadas (design, seção 10)
P1 a P12 da análise e PA-01 (campo fórmula), PA-02 (duas colunas de retorno), PA-03 (campanha sem custo em branco), PA-04 (relatório de oportunidades sem agrupamento novo), PA-05 (período por relatório; com o desvio 3), PA-06 (`RunReports` no PS), PA-07 (atribuição manual do PS e do grupo). Nenhuma foi tratada como bloqueio.

## Pós-deploy manual (não feito)
Atribuir o PS aos usuários de Marketing e incluir membros no grupo `Marketing_Origem_Retorno` (0 membros, 0 atribuições). Repetir o deploy na QA fica com a esteira.

## Commits
Registrados na branch `feature/EPLAST-39`: ver `git log` (commit `EPLAST-39: corrigir origem agrupada, relatórios, painel e permission set`).
