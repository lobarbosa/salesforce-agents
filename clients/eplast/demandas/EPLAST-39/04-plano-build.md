**Resultado do build:** concluído

# EPLAST-39 — Plano de build (rodada 3: origem dos leads e retorno das campanhas)

**Org de build:** `sbx-eplast-dev` (Sandbox, Connected; é a "QA" da Eplast, regra 5 da conta). Nada na QA nem em produção. Nada no Marketing Cloud.
**Branch:** `feature/EPLAST-39`. **Desenho:** `03-design.md` (nível 1, configuração nativa). Sem Flow, Apex, trigger, e-mail ou DML em registro de negócio.
**Linha de base (passo 0):** 419 relatórios e 21 painéis na org, igual ao recon.

## Componentes (todos em `clients/eplast/force-app/main/default/`)

| Item | Ação | Arquivo | Resultado |
|---|---|---|---|
| `Lead.MKT_Origem_Agrupada__c` | Alterado (D1): fórmula com de-para para as 10 origens + "Sem origem" + "Outros", `UPPER(TRIM(TEXT(LeadSource)))`; `Description` nova | `objects/Lead/fields/MKT_Origem_Agrupada__c.field-meta.xml` | Deploy ok (~1.350 caracteres de fórmula) |
| `Opportunity.MKT_Origem_Agrupada__c` | Criado (D2, E2): fórmula gêmea, mesmo texto do Lead; `Description` cruzada | `objects/Opportunity/fields/MKT_Origem_Agrupada__c.field-meta.xml` | Deploy ok |
| `Campaign.MKT_ROI_Situacao__c` | Criado (D5, E2): "Não calculável" se `ActualCost` vazio ou <= 0, senão "Calculável" | `objects/Campaign/fields/MKT_ROI_Situacao__c.field-meta.xml` | Deploy ok |
| `PS_Marketing_AnaliseCampanhas` | Alterado (D7): +FLS de leitura nos 2 campos novos; sem edição, sem ViewAll/ModifyAll | `permissionsets/PS_Marketing_AnaliseCampanhas.permissionset-meta.xml` | Deploy ok |
| `MKT_Leads_por_Origem`, `MKT_Conversao_Leads_por_Origem` | Alterados (D4): `timeFrameFilter` sobre `CREATED_DATE` com `INTERVAL_THISMONTH` | `reports/Marketing_Origem_Retorno/` | Deploy ok |
| `MKT_Oportunidades_por_Origem` | Alterado (D2, D4): grupo `Opportunity.MKT_Origem_Agrupada__c` no lugar de `LEAD_SOURCE`; mês atual | idem | Deploy ok; API confirma `THIS_MONTH` |
| `MKT_Desempenho_Campanhas` | Alterado (D4, D5): sai a fórmula "Receita ganha / custo real" (PA-12), `ROI` nativo mantido, 2º grupo `Campaign.MKT_ROI_Situacao__c`, filtro `START_DATE equals THIS_MONTH`; `description` com "NAO e faturamento" | idem | Deploy ok; API confirma filtro "Este mês" |
| `MKT_Resposta_Membros_Campanha` | Alterado (D4): filtro `START_DATE equals THIS_MONTH` | idem | Deploy ok; filtro confirmado |
| `MKT_Origem_Original_por_Grupo` | Criado (D3): Summary `LeadList`, grupos origem padronizada x `LEAD_SOURCE`, contagem, sem detalhe, mês atual, fora do painel | idem | Deploy ok |
| Painel `MKT_Origem_e_Retorno_Campanhas` | Alterado (D6): componente de oportunidades agrupa por `Opportunity.MKT_Origem_Agrupada__c`; componente de desempenho ganha `footer` "Receita atribuída = valor das oportunidades ganhas vinculadas à campanha. Não é faturamento." (`chartSummary` segue em `AMOUNT_WON`) | `dashboards/Marketing_Origem_Retorno_Dash/` | Deploy ok |

## Decisões e desvios de build
1. **Enum do período (passo 3):** confirmado por retrieve de relatório da org (`SP_Current_Month_Open_Pipeline`): `INTERVAL_THISMONTH`. Aceito na primeira tentativa nos 4 relatórios de Lead e Opportunity. PA-05b não precisou de fallback nesses.
2. **Relatórios de Campanha (`CampaignList`, `CampaignLead`):** filtro comum `criteriaItems` em `START_DATE` com valor `THIS_MONTH`, aceito na primeira tentativa nos dois. **Nenhum relatório caiu no fallback PA-05b.**
3. **Limite de 255 caracteres:** a primeira validação recusou as 6 `description` (excediam 255). Reduzidas, mantendo o aviso "não é faturamento" na do desempenho.
4. **Nomes de coluna (passo 2):** conferidos no describe `/analytics/report-types/<tipo>` depois de atribuir o PS ao usuário da esteira (sem FLS o campo novo não aparece): `Opportunity.MKT_Origem_Agrupada__c`, `Lead.MKT_Origem_Agrupada__c`, `Campaign.MKT_ROI_Situacao__c`, `START_DATE`.
5. **Atribuição do PS (R5):** `PermissionSetAssignment` `0PaHa00000ELYDCKA5` do PS ao usuário `005bJ00000piKAaQAM` (administrador da esteira), só na dev, para o describe e a verificação. **Continua atribuída** para o verificador; deve ser desfeita ao fim dos testes (passo 6 do design). Atribuição a usuários da Eplast: manual, pós-deploy (PA-07).
6. **Relatórios de Lead sem coluna:** `GET /analytics/reports/<id>` dos relatórios `LeadList` retorna 203 ("nenhuma coluna selecionada"), pois são Summary sem coluna de detalhe, como na rodada anterior (não alterei colunas). Verificação de Lead deve usar o painel ou `POST` com `includeDetails=false` na requisição; se o verificador achar que é defeito, está nos 3 relatórios de Lead.

## Validação feita no build
- `--dry-run` antes de cada deploy (campos/PS e relatórios/painel); deploys finais `Succeeded`.
- Relatórios de Opportunity, Desempenho e Resposta executam sem erro na API e mostram o filtro de mês atual.
- Painel: `PUT` de atualização é feito pelo verificador. Estado atual dos componentes: `NO_DATA`, esperado, pois a dev tem 4 leads e 0 campanhas/oportunidades (a massa sintética de teste da seção 7 do design **não foi criada neste build**).

## Fica para a verificação (`verificador`)
Massa sintética da seção 7 do design (prefixo `EPLAST39-TESTE`, via `fixtures/`, apagada ao fim), `PUT` e `GET` do painel sem `errorCode`/`NO_DATA`, CAs da seção 9 (CA-01' a CA-17), comparação do texto das duas fórmulas (CA-15) e desfazer a atribuição do PS.

## Versões e ativação
Nenhum Flow, agente ou classe criado ou alterado. Campo fórmula, relatório e painel não têm versão na plataforma: vale no deploy; rollback pelo git (seção 12 do design).

## Pós-deploy manual (Eplast)
Atribuir `PS_Marketing_AnaliseCampanhas` e incluir membros no grupo `Marketing_Origem_Retorno` (PA-07). Avisar quem opera o Marketing Cloud dos novos valores de `Lead.MKT_Origem_Agrupada__c` (seção 6 do design).
