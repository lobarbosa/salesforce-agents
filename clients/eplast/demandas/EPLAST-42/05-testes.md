**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-42 — Testes na sandbox de QA

`sf org list` mostrou só `sbx-eplast-qa` (Sandbox, Connected, org `00DHa000006vZtmMAE`). Deploy `0AfHa00000EI8rtKAD` (Succeeded, commit `b6abb9b0`) registrado em `05-deploy-qa.md`. Nenhuma falha encontrada. Não houve implantação nesta sessão.

Dado de teste: `fixtures/publicos-mc-eplast42.apex` (CRIAR e LIMPAR), prefixo `EPLAST42 TESTE`: 6 leads (L3 convertido), 3 contas Recorrente (C100, C365, C400), 5 contatos (inclui opt-out de e-mail e de celular), 3 oportunidades ganhas. Relatórios executados pela Analytics API (`includeDetails=true`); só linhas com `EPLAST42 TESTE` foram lidas, e dos totais só a contagem. Nenhum registro real lido ou alterado.

## Falhas
Nenhuma.

## Presença dos componentes na QA
- Pasta MARKETING CLOUD (`MARKETINGCLOUD`): 61 relatórios (`sf org list metadata --folder MARKETINGCLOUD`), incluindo `LEADS_PROSPECCAO_PRIORIDADE` (Id `00OHa000002zHCTMA2`). Os componentes de `05-deploy-qa.md` existem.
- `PS_Marketing_Publicos` (`FieldPermissions`): `Lead.PriorityBand__c`, `Lead.PriorityScore__c`, `Lead.MKT_Origem_Agrupada__c` com Read=true, Edit=false.

## Casos

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | Conferir a pasta na QA contra `04-plano-build.md` (58 alterados, 1 novo) | Relatórios presentes | 61 relatórios na pasta (60 + o novo); amostra de 7 executou sem erro | passou |
| T2 | CA-02 | Executar `CONTAS_E_CONTATOS_RECORRENTES_6PU` (RECORRENTES (ATIVOS) - GERAL) e `SEM COMPRA - 91 A 180` com contato `HasOptedOutOfEmail=true` | Contato fora | Linhas de teste: só C100/C365/C400 (e C100 no 91-180); contato "optout email" ausente | passou |
| T3 | CA-03 contato | Mesmos relatórios, contato com opt-out de celular | Contato fora | Contato "optout celular" ausente nos dois | passou |
| T4 | CA-03 lead | `LEADS - SP` e `LEADS - SEGMENTO - ALIMENTOS` com L1 (opt-out celular) | L1 fora | SP: L2, L4, L6. Alimentos: L2, L6. L1 ausente | passou |
| T5 | CA-03 relatório novo | `LEADS - PROSPECÇÃO PRIORIZADA` | L1 fora | L2, L4, L6 presentes; L1 ausente | passou |
| T6 | Convertido | L3 `IsConverted=true` (SOQL) nos relatórios de lead | L3 fora | L3 ausente em SP, Alimentos e no novo | passou |
| T7 | CA-04 | Contas com última compra 2026-08-07 (100d), 2025-11-15 (365d), 2025-10-11 (400d) nos três públicos de reativação | 100 só em 91-180; 400 só em >365 | 91-180: C100; 181-365: C365; >365: C400 (sem cruzamento) | passou |
| T8 | CA-05 | SOQL `MKT_Origem_Agrupada__c` nos leads de teste | Evento = "Evento"; sem origem = "Sem origem" | L4 e L6 "Evento"; L1, L2, L3, L5 "Sem origem". Coluna de origem agrupada não está no relatório novo (desvio já aceito no gate, sem FLS ao implantador); `MKT_Leads_por_Origem` é do EPLAST-39 e não existe na pasta desta demanda | passou (por SOQL) |
| T9 | CA-06 | `LEADS - PROSPECÇÃO PRIORIZADA`; faixas por SOQL | Alta aparece; "Sem dados suficientes" não | L6 (Alta) aparece; L5 (Sem dados suficientes) ausente; L3 (Alta) fora por conversão | passou |
| T10 | PS | Atribuir o PS ao meu usuário e ler os campos do Lead por SOQL | Campos legíveis, sem edição | `PriorityBand__c`, `MKT_Origem_Agrupada__c` lidos; Edit=false nos três | passou |
| T11 | CA-07 | Campo `CampaignMember.et4ae5__Activity__c` existe (FieldDefinition); sem arquivo `et4ae5` no diff | Existe, não alterado | Existe; 0 arquivos `et4ae5`. Não criei Campaign nem CampaignMember | passou (por metadata; relatório de retorno não executado) |
| T12 | CA-08/09/10 | `git diff --name-only main...HEAD` em `force-app` | Sem Flow, classe, trigger, objeto, `et4ae5` | 0 arquivos nessas pastas; só relatórios e o PS | passou |
| T13 | CA-11 | Campo novo em Lead ou Contact | Nenhum | Nenhum campo criado; não se aplica | passou |
| T14 | CA-12 | Totais lidos só de registros de teste | Só `EPLAST42 TESTE` | Só linhas de teste foram lidas; totais dos relatórios citados apenas como contagem | passou |

## Mudanças no meu usuário de execução (QA) e reversão
- `User.ProtheusSellerId__c` (`005bJ00000piKAaQAM`): antes vazio, `TESTE42` durante o teste, devolvido a vazio (SOQL: null).
- `PS_Marketing_Publicos`: antes não atribuído; atribuído e removido (contagem 0).
- Marketing User: não alterado.
- Usuário de teste da conta de serviço Konecta (Id `005bJ00000hBJmYQAW`) está inativo nesta org; não foi usado.

## O que pode ter saído da org
A cadeia criou 3 Casos de pós-venda (um por oportunidade ganha), vinculados às contas de teste; apaguei os 3 e depois rodei o LIMPAR. `TriggerUtility.bypassTrigger = true`: nenhum callout a Protheus ou BrasilAPI. Nenhum e-mail enviado, nada no Marketing Cloud. Contagem final de `EPLAST42 TESTE` em Lead, Account, Contact, Opportunity e Case: 0. Nenhum job agendado.

## Limites
- Marketing Cloud não foi testado (fora do escopo; passo de quem o opera).
- Filtros dos 17 relatórios de lead e 42 de contato foram provados por amostra de 7 relatórios na QA; os demais seguem o mesmo critério conferido por XML na dev (`04-verificacao.md`).
- Outras demandas (EPLAST-36, 37, 43 a 46) tocam o mesmo PS e pasta; nada foi alterado por mim neles.
