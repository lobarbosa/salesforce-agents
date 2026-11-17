**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-39 — Testes na QA (rodada 3): origem dos leads e retorno das campanhas

Org confirmada por `sf org list`: `sbx-eplast-qa` (`eplast--qas`, Partial Copy, Org Id `00DHa000006vZtmMAE`, Connected). Deploy `0AfHa00000EI9BFKA1` (Succeeded, commit `5ed69e1d`): campo `Lead.MKT_Origem_Agrupada__c` (Tooling API), 5 relatórios (`MKT_*`), painel `MKT_Origem_e_Retorno_Campanhas`, permission set `PS_Marketing_AnaliseCampanhas` existem na org. Pasta e grupo conferidos pelos relatórios e pelo painel carregarem. Usuário de execução: `005bJ00000piKAaQAM` (Administrador do sistema). A conta de serviço da Konecta ativa é esse mesmo usuário; o outro registro (`005bJ00000hBJmYQAW`) está inativo.

## Falhas
Nenhuma que bloqueie o aceite.

Retestes da rodada anterior (`05-testes-rodada-1.md`):
- FALHA 1 (componentes 1 e 3 sem dado sem o PS): **tratada conforme decisão do card, sem mudança de metadata**. Sem o PS, o comportamento continua (ver T7a): é o esperado, e a atribuição do PS aos usuários de Marketing é passo manual pós-deploy (PA-07). Com o PS, 5 de 5 componentes com dado (T7b).
- FALHA 2 (casos não executados): **corrigida**, todos executados abaixo com o PS atribuído ao usuário de execução.
- Rodada 1, FALHAs 2 e 3 ("Sem origem" e "Fora da lista"): **corrigidas**, ver T2 e T3.

## Mudanças temporárias no usuário de execução (todas desfeitas)
| Item | Antes | Durante | Depois |
|---|---|---|---|
| `PermissionSetAssignment` do `PS_Marketing_AnaliseCampanhas` | nenhuma | `0PaHa00000EJjB5KAL` | removida (COUNT = 0) |
| `User.ProtheusSellerId__c` | vazio | `TESTE39` | vazio |
| `User.UserPermissionsMarketingUser` | false | true | false |

Perfil, papel e outros usuários intocados.

## Casos
Massa: fixtures `lead.apex` (8 leads, 2 convertidos) e `campanha_oportunidade_ganha_qa.apex` (nova; igual à da dev, com `DMLOptions.allowSave` porque a regra de duplicidade de Account da QAS bloqueia o insert simples). Todos `TESTE EPLAST-39`. Antes: 712 leads; durante: 720.

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | Atualizar painel (`PUT /analytics/dashboards/01ZHa000001uI4vMAE`) e ler componente "Leads por origem"; `SELECT COUNT() FROM Lead` | Soma dos grupos = total | 11 grupos: Campanha 4, Econodata 8, E-mail MKT 2, Fora da lista 3, Google Ads 5, Google Orgânico 15, Indicação 18, Prospecção ativa 49, SDR 110, Sem origem 470, WhatsApp 36 = 720; total do relatório 720; COUNT = 720 | passou |
| T2 | CA-02 | Mesmo relatório; `GROUP BY LeadSource` | "Sem origem" = leads com origem vazia; sem "-" | "Sem origem" 470 = SOQL null 470 (469 antes + 1 de teste); nenhum grupo "-" | passou |
| T3 | CA-03 | Mesmo relatório | Valores fora das 13 caem em "Fora da lista" | "Fora da lista" 3 = SOQL: Web 1 + Origem Inventada XYZ 1 + QA_FORA_DA_LISTA 1; nenhum desses como linha própria | passou |
| T4 | CA-04 | `sf sobject describe Lead` (LeadSource) x fórmula | 13 = 13 | 13 ativos na picklist; fórmula tem `TEXT(LeadSource)` e 13 literais (conferido na rodada anterior, mesmo componente) | passou |
| T5 | CA-05 | `POST /analytics/reports/00OHa000002xoShMAI` com filtro `CREATED_DATE` THIS_MONTH e LAST_MONTH (ad hoc, sem salvar) | Totais recalculam; soma = total | THIS_MONTH: total 12, grupos somam 12, SOQL 12; LAST_MONTH: 0, SOQL 0. Filtro por relatório, não de painel (desvio PA-05 aceito) | passou |
| T6 | CA-06 | Componente "Conversão por origem"; SOQL `IsConverted` agregado | Taxa = convertidos / total | Campanha 50% (SOQL 2 de 4), WhatsApp 67% (24 de 36), total 31% (226 de 720); SOQL IsConverted = 226 | passou |
| T7a | CA-07 (sem PS) | Atualizar painel antes de atribuir o PS | Comportamento conhecido (PA-07) | Componentes 1 e 3 com erro de campo/agrupamento; os demais sem erro | esperado, documentado |
| T7b | CA-07 | Atualizar painel com o PS atribuído | 5 componentes com dado, relatórios de resumo | 5 com dado: Leads (720), Desempenho (3.200 total), Conversão (31%), Resposta membros (0, sem membros), Oportunidades. Todos `SUMMARY` | passou |
| T8 | CA-08 | Relatório `MKT_Desempenho_Campanhas`; campanha `TESTE EPLAST-39 Camp Com Custo` (custo 1000, ganho 2500) | 2,50 | "Receita ganha / custo real" = 2,50 | passou |
| T9 | CA-09 | Campanha sem custo (ganho 700) | Sem erro de divisão; em branco (PA-03) | Célula "-" e sem erro; texto "n/a" não existe por PA-03 | passou (conforme PA-03) |
| T10 | CA-10 | `git diff origin/main...HEAD -- force-app` fora da demanda | Zero | 0 arquivos fora de pasta, campo, grupo, painel e PS | passou |
| T11 | CA-11 | `ObjectPermissions`, `PermissionSet`, `FieldPermissions` do PS | Só leitura; vê relatórios | Campaign, Lead, Opportunity: só Read; `RunReports` true; `ViewAllData` e `ModifyAllData` false; FLS do campo novo: leitura, sem edição | passou (por metadata); recusa por DML/tela não exercitada: o único usuário de teste é Administrador |
| T12 | CA-12 | Diff filtrado por flow/trigger/classes/email | Nenhum | 0 arquivos | passou |
| T13 | CA-13 | `describe` do relatório `MKT_Leads_por_Origem` | Resumo, sem coluna pessoal | `SUMMARY`, `detailColumns` vazio, agrupa por origem e mês | passou |
| T14 | CA-14 | Org Ids | Dev ≠ QA | QA `00DHa000006vZtmMAE`; dev `00DHa000006vfMLMAY` (04-verificacao.md) | passou |

Resumo: 15 linhas, todas passaram ou são esperadas. Ressalvas honestas: CA-11 provado só por metadata; "n/a" vira célula em branco por premissa PA-03; filtro de período é por relatório (PA-05).

## O que pode ter saído da org
Criados e apagados nesta sessão: 8 leads, 2 contas geradas pela conversão, 1 conta, 1 filial, 1 condição de pagamento, 2 campanhas, 2 oportunidades (e eventuais casos de pós-venda gerados pela automação ao ganhar a oportunidade). Conferido por COUNT = 0 de cada. Campanhas `QA-TESTE EPLAST-39` da rodada 1 ficaram como estavam. Nenhum e-mail, integração externa ou Marketing Cloud acionado (`TriggerUtility.bypassTrigger = true` na massa).
