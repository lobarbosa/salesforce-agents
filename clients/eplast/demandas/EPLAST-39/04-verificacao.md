**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast = dev da esteira, Org Id `00DHa000006vfMLMAY`, conferida com `sf org list`: Connected)

# EPLAST-39 — Verificação (reverificação do build rodada 2)

## Divergência do preflight
`00-preflight.md` diz "Etapa que vai rodar: build" e "a demanda ainda não tem componentes no repositório". Isso estava defasado: `04-plano-build.md` existe e abre com `**Resultado do build:** concluído`, e o diff `main...HEAD` em `force-app` tem 11 arquivos desta demanda. Não tratei como bloqueio.

## Componentes confirmados por `sf`
- `Lead.MKT_Origem_Agrupada__c` existe (Tooling `CustomField`, fórmula com `Sem origem`, 13 origens e `Fora da lista`).
- 5 relatórios `MKT_*` na pasta (Leads, Conversão, Desempenho de Campanhas, Oportunidades, Resposta de Membros) e o painel `01ZHa000001uFevMAE` com 5 componentes.
- `PS_Marketing_AnaliseCampanhas`: Read em Campaign, Lead e Opportunity; sem Create, Edit nem Delete; FLS do campo novo com leitura true e edição false.
- Dev estava com 0 Lead, 0 Campaign e 0 Opportunity antes do teste.

## Dados de teste e mudanças no usuário de execução (dev)
Usuário de execução: `005bJ00000piKAaQAM` (Administrador do sistema). Não há fixture em `clients/eplast/fixtures/` (a pasta não existe); montei a massa por Apex anônimo com `TriggerUtility.bypassTrigger = true`, tudo com `TESTE EPLAST-39` no nome. Script não gravado como fixture (esta etapa não grava fora da demanda).
Dados criados: 6 Leads, 1 conversão (gerou Conta e Contato sintéticos), 2 Campanhas, 2 Oportunidades Indústria `Fechado/Ganho`, 1 CampaignMember, 1 Branch__c e 1 PaymentTerms__c (exigidos pelas validation rules da Oportunidade).

| Mudança no usuário | Antes | Durante | Depois |
|---|---|---|---|
| PermissionSetAssignment de `PS_Marketing_AnaliseCampanhas` (0 atribuições antes) | ausente | atribuído | removido |
| `UserPermissionsMarketingUser` | false | true | false |
| `ProtheusSellerId__c` (exigido pela validation rule `CheckAccountOwnerHasProtheusSellerId`) | null | valor sintético | null |

Limpeza: contagens finais de Lead, Campaign, Opportunity, Account e Contact com `TESTE EPLAST-39` = 0. Nada ficou.

## O que pode ter saído da org
Nada. A demanda não tem Flow, Apex, trigger nem e-mail, e o bypass de trigger desligou a automação de Account e Opportunity. Nenhuma chamada externa, nenhum pedido, cotação ou log de integração.

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | Leads: 2 Google Ads, 1 SDR, 2 sem origem, 1 valor fora da lista. Refresh do painel (PUT, depois GET) | Soma dos grupos = total de Lead | Grupos Fora da lista 1, Google Ads 2, SDR 1, Sem origem 2 = 6; total do componente 6; `COUNT()` de Lead no teste = 6 | passou |
| T2 | CA-02 | Mesmo painel | Linha "Sem origem" com a contagem dos vazios; nenhuma linha "-" | "Sem origem" = 2; sem linha "-" no componente de Leads | passou |
| T3 | CA-03 | Lead com `LeadSource` = valor fora da picklist (aceito na inserção) | Contado em "Fora da lista", sem linha própria | "Fora da lista" = 1; o valor não aparece como linha | passou |
| T4 | CA-04 | `sf sobject describe Lead` na picklist `LeadSource` contra a fórmula | 13 valores iguais | 13 ativos, os 13 literais do `CASE` coincidem | passou |
| T5 | CA-05 | POST no relatório de Leads com `standardDateFilter` customizado, sem persistir | Período recalcula o total | 2020-01-01 a 2020-12-31 = 0; 2026-11-01 a 2026-11-30 = 6 | passou (ver premissa PA-05) |
| T6 | CA-06 | 1 lead Google Ads convertido de 2; componente de conversão | Taxa = convertidos ÷ total por origem | Google Ads 50%, demais 0%, total 17% (1 de 6) | passou |
| T7 | CA-07 | Refresh do painel; leitura de `componentData` e do formato dos relatórios | 5 componentes sem erro, todos Summary | 5 de 5 sem erro (`componentStatus` DATA), formato SUMMARY nos 5. Desempenho, Leads, Conversão e Oportunidades com dado. Respondentes retornou 0 e sem grupos no painel no momento do refresh, embora o relatório, rodado direto, devolva a campanha de teste com o membro | passou, com ressalva (ver abaixo) |
| T8 | CA-08 | Campanha com ActualCost 1000 e Opp ganha de 3000 por `CampaignId` | 3000 ÷ 1000 | Coluna "Receita ganha / custo real" = 3,00; total geral 3,50 | passou |
| T9 | CA-09 | Campanha sem custo e Opp ganha de 500 | Sem erro de divisão | Retorno "-" (em branco, premissa PA-03), sem erro | passou |
| T10 | CA-10 | `git diff --name-only main...HEAD -- force-app` | Só pasta Marketing_Origem_Retorno, campo novo, painel, grupo e PS | 11 arquivos, todos esses itens | passou |
| T11 | CA-11 | `ObjectPermissions` e `FieldPermissions` do PS | Sem edição em Lead e Campaign | Read apenas em Campaign, Lead, Opportunity; FLS do campo novo só leitura | passou por metadata; a negativa de edição não foi executada (o único usuário disponível é administrador) |
| T12 | CA-12 | Lista de arquivos do diff | Sem EmailTemplate, Alert, Apex, Flow, trigger | Nenhum desse tipo no diff | passou |
| T13 | CA-13 | XML de `MKT_Leads_por_Origem` | Summary, sem coluna pessoal | `showDetails false`, sem `<columns>`, format Summary | passou |
| T14 | CA-14 | `sf org list` | Dev distinta da QA | Só a dev conectada neste job (`00DHa000006vfMLMAY`, instância `eplast--qa`); a QA não foi consultada. Distinção coberta pela regra 5 do `CLAUDE.md` do cliente (IDs diferentes, 2026-11-15) | passou pela regra 5 (não reexecutado) |

### Ressalvas sem efeito no veredito
- **Relatórios de Leads e Conversão rodados direto pela API:** `BAD_REQUEST 203` ("nenhuma coluna selecionada"), porque o relatório não tem coluna de detalhe, de propósito (CA-13). No painel e com POST que informa coluna eles rodam sem erro. Quem abrir o relatório na tela pode ver esse aviso; se for problema, o builder pode acrescentar uma coluna agregada, o que não afeta o CA-13.
- **Componente Respondentes (CA-07):** mostra a soma de `HAS_RESPONDED`, então 0 é o valor correto para membros sem resposta. O agrupamento do painel veio vazio na leitura logo após o refresh; o relatório direto mostra a campanha. Ressalva de timing do refresh, não de metadata.
- **Oportunidades e Valor por Origem:** o grupo aparece como "-" porque as oportunidades de teste não têm origem. Não é critério da demanda (PA-04).
- **CA-09 diz "n/a", a construção mostra em branco:** coberto pela premissa assumida PA-03.
- **Painel sem filtro de período próprio:** período por relatório (PA-05); `MKT_Desempenho_Campanhas` e `MKT_Resposta_Membros_Campanha` não aceitam filtro (desvio 3 do build).
- **Ordem de execução (assessment, Account/Opportunity/Order com CPQ):** a demanda não adiciona automação nesses objetos (CA-12) e os relatórios só leem. Para criar a massa usei o bypass de trigger; não testei a ordem trigger, CPQ e Flow com a automação ligada, e isso fica sem prova por não pertencer ao escopo.

## Premissas assumidas usadas
P1 a P12, PA-01 (campo fórmula), PA-02, PA-03 (campanha sem custo em branco), PA-04, PA-05 (período por relatório), PA-06, PA-07 (atribuição manual do PS). Nenhuma foi motivo de reprovação.
