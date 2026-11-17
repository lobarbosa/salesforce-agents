**Resultado do build:** concluído

# EPLAST-26 — Plano de build (rodada 3: critérios e faixas AA/A/B/C/D da Eplast)

- **Branch:** `feature/EPLAST-26`
- **Commit:** `92d22928` (pushed). PR: `gh` sem GH_TOKEN nesta sessão, não aberto por mim.
- **Org de build:** `sbx-eplast-dev` (Sandbox, Connected, conferido com `sf org list`; usuário de conexão omitido)
- **Deploy:** `0AfHa00000EJIM9KAP`, Succeeded, 74/74 componentes, `NoTestRun` (sem Apex). Antes: dry-run que falhou por rótulo de campo acima de 40 caracteres e por coluna de list view; corrigido e repetido.
- **Base:** XML das fórmulas partiu do retrieve da org (não do repositório), conforme B2. Só metadata declarativa: nenhum Apex, Flow, e-mail, callout ou Named Credential.
- **Plano B (I-1):** não foi necessário. A plataforma aceitou `$CustomMetadata.PriorityScoreSetting__mdt.Default.*` nas quatro fórmulas, inclusive no tamanho compilado.

## Componentes

| # | Componente | Ação | Arquivo |
|---|---|---|---|
| C1 | `PriorityScoreSetting__mdt` ("Score de prioridade - parâmetros", Public, com descrição) | Criado | `objects/PriorityScoreSetting__mdt/PriorityScoreSetting__mdt.object-meta.xml` |
| C2 | 13 campos Number(3,0) obrigatórios, SubscriberControlled, cada um com descrição: `LeadEngagementHighPoints__c`, `LeadEngagementMediumPoints__c`, `LeadEngagementLowPoints__c`, `OppDiscoveryPoints__c`, `OppBudgetPoints__c`, `OppAdvancedStagePoints__c`, `OppRecentActivityPoints__c`, `OppRecentActivityDays__c`, `OppNextStepPoints__c`, `BandAAMin__c`, `BandAMin__c`, `BandBMin__c`, `BandCMin__c` | Criados | `objects/PriorityScoreSetting__mdt/fields/` |
| C3 | Registro `PriorityScoreSetting.Default` (15/10/5, 10/10/5, 10/30 dias/10, cortes 90/75/60/40) | Criado | `customMetadata/PriorityScoreSetting.Default.md-meta.xml` |
| A1 | `Lead.PriorityScore__c` | Fórmula, descrição e ajuda substituídas (só engajamento pontua, máx. 15) | `objects/Lead/fields/` |
| A2 | `Lead.PriorityBand__c` | AA/A/B/C/D e "Não classificado" (engajamento vazio) | idem |
| A3 | `Opportunity.PriorityScore__c` | Fórmula nova (descoberta, orçamento, estágio avançado, interação recente, próximo passo; encerrada = 0). Precisão gravada em Number(3,0); a org tinha 18 | `objects/Opportunity/fields/` |
| A4 | `Opportunity.PriorityBand__c` | AA/A/B/C/D; encerrada = "Não classificado" | idem |
| A5 | List views `Oportunidades_Prioridade_Alta` (filtro `AA,A`, rótulo "Oportunidades de prioridade AA e A"), `Oportunidades_Abertas_Prioridade` (+ `OPPORTUNITY.NEXT_STEP`, `OPPORTUNITY.LAST_ACTIVITY`), `Leads_Abertos_Prioridade` (+ `MKT_MC_Engajamento__c`) | Alterados | `objects/*/listViews/` |
| A6 | `Lead.MKT_Nutricao_ProntoAbordagem__c` (EPLAST-45) | Fórmula trocada para `OR(PriorityBand__c = "AA", PriorityBand__c = "A")` conforme D2 aprovada no gate. Descrição e ajuda atualizadas. O arquivo não existia no repositório; veio por retrieve | `objects/Lead/fields/MKT_Nutricao_ProntoAbordagem__c.field-meta.xml` |

## Conflito com outras demandas

- Layouts, flexipages e `PS_Comercial_ScorePrioridade` não foram tocados (EPLAST-30, 35, 38, 40, 41, 45).
- A6 altera componente da EPLAST-45 só na fórmula, o que o design manda (D2). Quem integrar a EPLAST-45 deve manter o `OR` AA/A.
- Fica registrado para as donas (EPLAST-42 e 43): o filtro `notEqual "Sem dados suficientes"` dos relatórios deve virar "Não classificado". Não alterado aqui.

## Desvios e pontos para o verificador

- O `CASE` do Lead usa `TEXT(MKT_MC_Engajamento__c)`, não a picklist direta (o `CASE` sobre picklist exige texto). Compilou com "Médio" acentuado.
- O ListView de filtro `AA,A` foi aceito no deploy; o comportamento de "ou" deve ser conferido na tela ou por contagem agregada (vazia com os valores iniciais, esperado).
- Máximo de score com os campos atuais: Lead 15 (faixa D), Opportunity 45 (faixa C). AA, A e B inalcançáveis até existirem os campos da seção 5 do design (D3, fora deste build). O verificador prova as faixas com cópia temporária do `Default` com cortes baixos, só na dev, e redeploya o original.
- A dev tem 4 Leads hoje (o design dizia 0). Não foram lidos; o verificador usa só registros sintéticos das fixtures.
- I-2 (usuário sem "Personalizar aplicativo" lê o valor calculado) fica para o verificador. Se falhar, volta ao gate, pois mexeria em `PS_Comercial_ScorePrioridade`.
- Ao implantar a pasta `objects/Lead/fields` inteira, o retrieve posterior mostrou diferença só em `Lead.Status` (`trackHistory` presente na org e ausente no repositório, defasagem da linha de base). Não foi alterado nem commitado.

## Versões e ativação

Não há Flow, agente nem classe. Fórmula e list view não têm versão: o rollback é redeployar o XML da rodada anterior (histórico do git e `rodada-anterior/premissas-assumidas/`) e remover C1 a C3 por destructive change. Não há passo de ativação.

## Premissas assumidas

As do design (PD-09 a PD-14 e seção 9) foram construídas como decididas; nenhuma pergunta ficou em aberto.
