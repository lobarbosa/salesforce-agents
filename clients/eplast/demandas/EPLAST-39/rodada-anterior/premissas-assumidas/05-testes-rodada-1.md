**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-39 — Testes na QA (rodada 2): origem dos leads e retorno das campanhas

Org confirmada por `sf org list`: `sbx-eplast-qa` (alias `sbx-eplast-qa`, Org Id `00DHa000006vZtmMAE`, Connected; instância `eplast--qas`, distinta da dev). Pacote de `05-deploy-qa.md` (deploy `0AfHa00000EI4zZKAT`, Succeeded): os 11 componentes existem na org (campo, 5 relatórios, painel, PS). Usuário de execução: `005bJ00000piKAaQAM` (Administrador do sistema, sem o PS). A conta de serviço da Konecta tem dois registros (o outro, `005bJ00000hBJmYQAW`, inativo). Não atribuí o PS a ninguém, porque o CLAUDE.md do cliente proíbe alterar permissão desse usuário. Não criei nem alterei nenhum registro na QA nesta rodada.

## Falhas (primeiro)

### FALHA 1 (crítica) — Painel na QA: 2 dos 5 componentes sem dado para quem não tem o permission set
- **Reproduzir:** na QA, como o usuário de execução (sem `PS_Marketing_AnaliseCampanhas`), atualizar o painel `01ZHa000001uI4vMAE` (`PUT /analytics/dashboards/<id>`) e ler (`GET`) o `status` de cada componente.
- **Obtido:** componente `01aHa000001JihVIAS` (Leads por origem): `NO_DATA`, erro 406 ("um ou mais campos selecionados no componente não estão mais disponíveis no relatório"). Componente `01aHa000001JihWIAS`: `NO_DATA`, erro 209 ("este relatório não pode ser usado como origem… adicione um ou mais agrupamentos"). Os outros 3 componentes retornam `DATA`.
- **Esperado:** CA-07, os 5 componentes com dado e sem erro de formato.
- **Causa provável:** `Lead.MKT_Origem_Agrupada__c` não tem FLS em nenhum perfil. `FieldPermissions` do campo na QA traz só o PS de Marketing e `sfdc_a360_sfcrm_data_extract`, nenhum perfil. O `sf sobject describe Lead` do Administrador não lista o campo. Com isso o relatório `MKT_Leads_por_Origem` perde, para o usuário, o primeiro agrupamento: `describe` do relatório devolve só `CREATED_MONTH`. O `03-design.md` (seção 8) assume que "o administrador" vê o campo, e isso não se confirmou. O mesmo vale para o relatório de conversão (componente 3). O painel é `LoggedInUser`, então quem não tiver o PS vê o erro.
- **Correção sugerida:** conceder leitura do campo ao perfil Administrador do sistema, ou aos perfis de quem abre o painel, ou documentar que o PS tem de estar atribuído antes de qualquer uso e entregar a atribuição. Reteste só prova o painel com o PS atribuído a um usuário de teste.

### FALHA 2 (crítica) — CA-01, CA-02, CA-03, CA-05, CA-06, CA-07 (dado), CA-08, CA-09 e CA-11 (parte de tela) não executados na QA
- Os relatórios de origem e conversão só funcionam com o PS atribuído. Sem alterar o usuário de execução eu não consegui exercitá-los. Critério principal não executado vale reprovação. Nenhum deles foi dado como passou.
- Para o build, ficam dois pedidos: tornar o painel utilizável pelo usuário de execução da QA (ver FALHA 1), ou informar um usuário de teste com o PS atribuído. A rodada 1 já tinha deixado campanhas `QA-TESTE EPLAST-39` (com e sem custo) na QA, que aparecem no painel.

### Falhas da rodada 1
- Rodada 1, FALHA 1 (painel sem dado): **parcialmente corrigida**. Os componentes 2, 4 e 5 (desempenho, resposta, oportunidades) renderizam como `DATA`. Os componentes 1 e 3 seguem com erro na QA para quem não tem o PS (FALHA 1 acima).
- Rodada 1, FALHA 2 ("Sem origem" aparecia como "-") e FALHA 3 ("Fora da lista"): **não verificável na QA nesta rodada**. A correção é o campo `MKT_Origem_Agrupada__c`, que o usuário de execução não enxerga. A fórmula entregue tem "Sem origem" e "Fora da lista", conforme o XML versionado. O `04-verificacao.md` (dev) aprova os dois casos com o PS atribuído.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | Rodar `MKT_Leads_por_Origem` na QA | Soma dos grupos = total de leads | Relatório sem o agrupamento por origem para o usuário (FALHA 1). Referência por `COUNT` na QA: 712 leads | não executado |
| T2 | CA-02 | idem | Linha "Sem origem" | Referência: 469 leads com `LeadSource` vazio. Relatório não exercitado | não executado |
| T3 | CA-03 | idem | "Fora da lista" | Referência: 1 lead com valor fora da lista de 13 (agregado). Relatório não exercitado | não executado |
| T4 | CA-04 | `sf sobject describe Lead` na picklist `LeadSource` x literais da fórmula no XML | 13 = 13 | 13 ativos (Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR). A fórmula traz os mesmos 13, mais "Sem origem" e "Fora da lista" | passou |
| T5 | CA-05 | Filtro de período | Recalcula | Relatório de Leads tem filtro de data de criação (padrão 2000-01-01 a 2099-12-31, `describe`). Recálculo não exercitado | não executado |
| T6 | CA-06 | Conversão por origem | Taxa = convertidos ÷ total | Referência: 224 convertidos de 712. Relatório não exercitado (componente 3, erro 209) | não executado |
| T7 | CA-07 | Refresh do painel e leitura de `status` | 5 componentes com dado | 3 `DATA`, 2 `NO_DATA` (erros 406 e 209). Os 5 relatórios são `Summary` | **falhou** (FALHA 1) |
| T8 | CA-08 | Retorno por campanha | Receita ganha ÷ custo real | Painel lista 5 campanhas, dados com valor 0. Cálculo não conferido (sem oportunidade ganha vinculada na QA: `COUNT` de oportunidades com campanha = 0) | não executado |
| T9 | CA-09 | Campanha sem custo | Sem erro de divisão | Componente de desempenho `DATA`, sem erro, incluindo a campanha `QA-TESTE EPLAST-39 Campanha Sem Custo`. O rótulo "n/a" / célula em branco não foi conferido | passou parcialmente, sem erro de divisão; valor exibido não conferido |
| T10 | CA-10 | `git diff --name-only main...HEAD -- force-app` filtrando o que não é da demanda | Zero fora do escopo | 0 arquivos fora da pasta, do campo e do PS | passou |
| T11 | CA-11 | `ObjectPermissions` e `PermissionSet` do PS | Sem Create/Edit/Delete; ver relatórios | Campaign, Lead, Opportunity: só Read (Create/Edit/Delete false). `RunReports` true, `ViewAllData` e `ModifyAllData` false. Edição negada na tela e visão do relatório com usuário só com o PS: não executados | passou parcialmente (permissões); tela não executada |
| T12 | CA-12 | Arquivos do diff com `flow|trigger|classes|email|template` | Nenhum | Nenhum arquivo | passou |
| T13 | CA-13 | XML de `MKT_Leads_por_Origem` | Resumo, sem coluna pessoal | `Summary`, 0 colunas de detalhe, `showDetails` false; `describe` confirma `detailColumns` vazio | passou |
| T14 | CA-14 | `sf org display` | Dev ≠ QA | QA: `eplast--qas`. Dev: `eplast--qa` (`00DHa000006vfMLMAY`, conferido no `04-verificacao.md`). Org Ids diferentes | passou |

Resumo: 5 passaram (T4, T10, T12, T13, T14), 2 passaram em parte (T9, T11), 1 falhou (T7), 6 não executados (T1, T2, T3, T5, T6, T8).

## O que pode ter saído da org
Nada. Não criei registro algum, não atribuí PS, não implantei nada. Executei só consultas agregadas, `describe` e o refresh do painel da própria solução (leitura). Nenhuma chamada externa, e-mail ou integração.
