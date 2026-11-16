**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-44 — Verificação

Org conferida com `sf org list`: `sbx-eplast-dev` (Sandbox, Org Id `00DHa000006vfMLMAY`, Connected). Nada em QA nem produção. Por instrução da etapa, não houve DML nem alteração de metadata; só consulta de metadata (retrieve para pasta temporária, já apagada) e contagens agregadas. Nenhum dado de teste foi criado, nada a desfazer, nenhum ajuste no usuário de execução.

## Resumo
A construção (um relatório novo, `LEADS_BOAS_VINDAS`) existe na dev e tem os filtros do design; os relatórios reaproveitados existem e estão como descrito. Não há defeito. O que ficou sem prova é a execução com dados (CA-01, CA-02 e a parte "lead convertido não aparece" do CA-03): a dev tem 0 leads abertos criados nos últimos 7 dias e a etapa não autorizou criar registros; o describe/execução do relatório pela Analytics API retornou FORBIDDEN (pasta `Hidden`) conforme o plano de build. Por isso a verificação é inconclusiva, não reprovada.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Existência de C1 | `SELECT DeveloperName, Name, Format, FolderName FROM Report WHERE FolderName='MARKETING CLOUD' AND DeveloperName IN (...) LIMIT 20` | `LEADS_BOAS_VINDAS` na pasta, Tabular | `LEADS_BOAS_VINDAS`, "LEADS - BOAS-VINDAS", Tabular, MARKETING CLOUD | passou |
| V2 | Filtros de C1 (design 3.1; base de CA-03) | Retrieve do metadata do relatório na dev | LeadList, escopo org, `CREATED_DATE` últimos 7 dias, `CONVERTED=false`, `EMAIL_OPT_OUT=false`, `STATUS ≠ Fechado - Não convertido` | reportType `LeadList`, scope `org`, `INTERVAL_LAST7` sobre `CREATED_DATE`, `CONVERTED equals 0`, `EMAIL_OPT_OUT equals 0`, `STATUS notEqual "Fechado - Não convertido"`, format Tabular | passou |
| V3 | CA-03 (metadata) | Filtro de conversão no público de prospecção (`LEADS_PROSPECCAO_PRIORIDADE`) e em C1 | `IsConverted = false` | `CONVERTED equals 0` nos dois | passou |
| V4 | CA-03 (execução com lead convertido sintético) | Não executado: sem DML nesta etapa | Lead convertido não aparece | — | não executado |
| V5 | CA-01 (opt-out de e-mail) por metadata | Retrieve de C1, J3, J4, J5 (3 faixas) e R1 | `EMAIL_OPT_OUT = false` em todos | `EMAIL_OPT_OUT equals 0` presente em C1, `POTENCIAIS_SEM_COMPRA`, `COMPRA_ULTIMOS_90_DIAS`, as 3 faixas `SEM_COMPRA_*` e `LEADS_PROSPECCAO_PRIORIDADE` | passou (metadata) |
| V6 | CA-01 (execução com Contact sintético opt-out) | Não executado: sem DML | Contato opt-out não aparece | — | não executado |
| V7 | CA-02 (opt-out de mensagem) por metadata | Retrieve e contagem de `HasOptedOutOfMobile` | Filtro de celular em R1, J4 e nos relatórios MSG | Presente em `LEADS_PROSPECCAO_PRIORIDADE`, `COMPRA_ULTIMOS_90_DIAS`, `MSG_LEADS_CELULAR_APTOS` e `MSG_CONTATOS_CELULAR_APTOS`; MSG_LEADS ainda com `CONVERTED = false` | passou (metadata) |
| V8 | CA-02 (execução com Lead e Contact sintéticos) | Não executado: sem DML | Nenhum dos dois aparece | — | não executado |
| V9 | Reuso J2–J5 e canal mensagem (design seção 2) | Retrieve dos 8 relatórios; comparação com o mapa | Filtros como no design | J2 faixa ≠ "Sem dados suficientes"; J3 `RelationshipClass__c = Potencial`; J4 `LastPurchase__c` ≥ N_DAYS_AGO:90 e ≤ TODAY; J5 faixas ≤ N_DAYS_AGO:91 / ≥ 180, ≤ 181 / ≥ 365, < 365. Faixas exclusivas pelas datas. Todos existem | passou |
| V10 | CA-04 (nenhum envio no CRM) | `git show HEAD --name-only` e grep por emailAlert/emailSimple/Messaging no arquivo novo | Só o relatório; zero ocorrências | Pacote do build: 1 arquivo de relatório (mais artefatos da demanda); 0 ocorrências de envio no relatório. Ocorrências de `EmailTemplate`/`WorkflowAlert` em `force-app` são de componentes antigos da org (flexipage, permission set CPQ, app), não do build | passou |
| V11 | CA-05 (reuso e contagem) | `SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'` | 65 (64 antes + 1) e C1 justificado | 65; justificativa de C1 no plano (nenhum relatório recorta lead por criação recente); 0 relatórios sem justificativa. Os 8 reaproveitados não foram alterados | passou |
| V12 | Exercitar C1 por contagem agregada | `SELECT COUNT() FROM Lead WHERE IsConverted=false AND HasOptedOutOfEmail=false AND CreatedDate=LAST_N_DAYS:7` | Equivalente ao relatório | 0 registros (a dev não tem lead recente); sem como comparar com o resultado do relatório | não executado (sem dado) |
| V13 | CA-06 | Bloqueado pela PEND-02 da análise (gatilho de entrada) | — | — | não executado |

## O que ficou sem prova e como provar
- CA-01, CA-02, CA-03 (parte de execução) e V12: precisam de registros sintéticos `TESTE EPLAST-44` (Lead aberto recente, Lead convertido, Lead e Contact com opt-out de celular, Contact com opt-out de e-mail) e da execução do relatório. Pode ser feito pela fixture de lead/contato do cliente numa próxima verificação com DML autorizado, ou na QA pelo agente de QA. Executar o relatório depende de o usuário ter acesso à pasta `MARKETINGCLOUD` (Hidden), que bloqueou a Analytics API para o usuário de execução.
- CA-06 depende da PEND-02.

## Premissas
PD-01 e PD-02 e as demais premissas do design foram seguidas e não foram motivo de reprovação.

## O que pode ter saído da org
Nada: nenhum registro criado, nenhuma automação disparada.
