**Resultado do build:** concluído

# EPLAST-42 — Plano de build

**Org:** `sbx-eplast-dev` (sandbox de dev da esteira; conexão confirmada com `sf org list`). Nada na QA, nada em produção, nada no Marketing Cloud.
**Branch:** `feature/EPLAST-42`. Design: `03-design.md` (aceite em `gates.md`).
**Pacote:** 58 relatórios alterados, 1 relatório criado, 1 permission set alterado. Zero Flow, Apex, campo, objeto, Campaign ou agente.

## Componentes

| # | Componente | Ação | Descrição / o que mudou |
|---|---|---|---|
| 1 | 42 relatórios `ContactList` da pasta `MARKETINGCLOUD` | Alterado | + critério `Contact.et4ae5__HasOptedOutOfMobile__c` = 0, lógica AND, filtros existentes intactos |
| 2 | 16 relatórios `LeadList` da pasta `MARKETINGCLOUD` | Alterado | + `Lead.et4ae5__HasOptedOutOfMobile__c` = 0 e `CONVERTED` = 0 |
| 3 | `MARKETINGCLOUD/LEADS_PROSPECCAO_PRIORIDADE` (nome de exibição "LEADS - PROSPECÇÃO PRIORIZADA") | Criado | `LeadList`, Summary agrupado por `Lead.PriorityBand__c`, escopo `org`. Filtros: faixa diferente de "Sem dados suficientes", e-mail e celular sem opt-out, não convertido. Colunas: nome, empresa, UF, setor, origem, score, status, e-mail. Sem telefone, CPF ou documento. Descrição preenchida (EPLAST-42). |
| 4 | `PS_Marketing_Publicos` | Alterado | + leitura (sem edição) em `Lead.PriorityBand__c`, `Lead.PriorityScore__c`, `Lead.MKT_Origem_Agrupada__c`. Descrição acrescida de "EPLAST-42: le prioridade e origem agrupada do Lead" (resumida: o limite é 255 caracteres e a primeira tentativa foi recusada por isso). |
| 5 | `fixtures/publicos-mc-eplast42.apex` | Criado (script, **não executado**) | Variação de `lead-segmento.apex` e `conta-oportunidade-ganha.apex`; prefixo `EPLAST42 TESTE`; `MODO` = `CRIAR` ou `LIMPAR`. Os dois scripts-base vieram da `main`. |

Reaproveitados sem alteração: `CLASSIFICACAO_CONTAS_POR_CLASSE`, `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` (agregações, sem filtro de e-mail), `MKT_Leads_por_Origem`, campos e pacote `et4ae5`.

## Como foi feito
1. Describe da Analytics API: `Contact.et4ae5__HasOptedOutOfMobile__c`, `Lead.et4ae5__HasOptedOutOfMobile__c` e `CONVERTED` (boolean) existem nos tipos. `Lead.MKT_Origem_Agrupada__c` **não** aparece para o usuário de execução (sem FLS, R3).
2. Retrieve dos 60 relatórios da pasta e do PS na dev (base do XML, não o `/tmp` do recon).
3. Piloto em `COMPRA_ULTIMOS_90_DIAS` (ContactList) e `LEADS_OlB` (LeadList): `--dry-run` e deploy real aceitos (Deploy ID `0AfHa00000EI4ukKAD`). Depois o mesmo script (`insere criteriaItems antes de <language>`) nos outros 56. Contagem final: 58 arquivos com o critério de celular, 2 sem (as duas agregações). Nenhum dos 58 tem `booleanFilter`.
4. Deploy do PS e do relatório novo. Conferência por SOQL em `FieldPermissions`: as 3 leituras existem em `PS_Marketing_Publicos`, sem edição.
5. Execução pela Analytics API (`includeDetails=false`, só contagem): os relatórios da pasta e o novo executam sem erro. O relatório novo retorna 0 linhas (dev sem lead; esperado). Nenhum dado pessoal lido.

## Relatórios alterados (58)
- `COMPRA_ULTIMOS_90_DIAS`
- `CONTAS_E_CONTATOS_RECORRENTES_6PU`
- `Cpia_de_CONTAS_E_CONTATOS_SAZONAIS_YaM`
- `Cpia_de_LEADS_GERAL_D2D`
- `Cpia_de_LEADS_SP_fWa`
- `Cpia_de_PROSPECTS_MG_Kk0`
- `Cpia_de_RECORRENTES_ATIVOS_SP_hLD`
- `Cpia_de_SAZONAIS_ES_u17`
- `INATIVOS_GERAL`
- `LEADS_ES_SQz`
- `LEADS_MG_26H`
- `LEADS_OlB`
- `LEADS_RJ_24t`
- `LEADS_SEGMENTO_ALIMENTOS`
- `LEADS_SEGMENTO_BEBIDAS`
- `LEADS_SEGMENTO_DISTRIBUIDOR_VAREJO`
- `LEADS_SEGMENTO_FARMACEUTICO`
- `LEADS_SEGMENTO_HIGIENE_LIMPEZA`
- `LEADS_SEGMENTO_INDUSTRIAL`
- `LEADS_SEGMENTO_INDUSTRIA_DE_SOPRO`
- `LEADS_SEGMENTO_INDUSTRIA_DE_TRANSFORMACAO`
- `LEADS_SP_2yf`
- `LEADS_SUL_0EK`
- `POTENCIAIS_SEM_COMPRA`
- `PROSPECTS_CO_D3n`
- `PROSPECTS_ES_iu8`
- `PROSPECTS_GERAL_vjU`
- `PROSPECTS_MG_4jm`
- `PROSPECTS_NONE_xn7`
- `PROSPECTS_NOVO_lId`
- `PROSPECTS_SP_kvL`
- `PROSPECTS_SUL_OQ5`
- `REATIVOS_GERAL_rbp`
- `RECORRENTES_ATIVOS_CO_I98`
- `RECORRENTES_ATIVOS_ES_cG0`
- `RECORRENTES_ATIVOS_MG_dSH`
- `RECORRENTES_ATIVOS_NORTE_E_NORDESTE_1nd`
- `RECORRENTES_ATIVOS_RJ_yuH`
- `RECORRENTES_ATIVOS_SUL_lXr`
- `SAZONAIS_CO_tKS`
- `SAZONAIS_MG_Jfz`
- `SAZONAIS_MG_X7D`
- `SAZONAIS_NONE_lJc`
- `SAZONAIS_RJ_IxD`
- `SAZONAIS_SP_qII`
- `SAZONAIS_SUL_dZZ`
- `SEGMENTO_ALIMENTOS`
- `SEGMENTO_BEBIDAS`
- `SEGMENTO_DISTRIBUIDOR_VAREJO`
- `SEGMENTO_FARMACEUTICO`
- `SEGMENTO_HIGIENE_LIMPEZA`
- `SEGMENTO_INDUSTRIAL`
- `SEGMENTO_INDUSTRIA_DE_SOPRO`
- `SEGMENTO_INDUSTRIA_DE_TRANSFORMACAO`
- `SEGMENTO_PET_BEM_ESTAR_ANIMAL`
- `SEM_COMPRA_181_A_365_DIAS`
- `SEM_COMPRA_91_A_180_DIAS`
- `SEM_COMPRA_MAIS_DE_365_DIAS`

Entre eles, 6 cópias `Cpia_de_*` (R7), alteradas junto, sem limpeza.

## Desvios e pendências
- **Fallback R3 usado.** O deploy de `LEADS_PROSPECCAO_PRIORIDADE` com a coluna `Lead.MKT_Origem_Agrupada__c` foi aceito, mas a coluna foi descartada em silêncio (o usuário que implanta não tem FLS). O XML da branch foi alinhado ao que está na org: o relatório sai **sem** essa coluna. O recorte por origem fica com a coluna `LEAD_SOURCE` do relatório, `MKT_Leads_por_Origem` (EPLAST-39) e o campo. Para a coluna entrar, quem implanta precisa de leitura no campo (pedido P1 do design, que o gate decide) e um novo deploy.
- Nenhuma tentativa de deploy de filtro foi recusada (regra das duas tentativas não acionada).
- O filtro de data do `LEADS_OlB` ("LEADS - GERAL") limita a criação a 2025-10-01 a 2026-01-22; é anterior à demanda e não foi mexido (não faz parte do escopo).

## Pré-condição para o deploy na QA (R4, pedido P2 do design)
O deploy substitui o XML inteiro dos 58 relatórios. Antes do passo fixo de deploy na QAS, a esteira ou um humano compara a lista e os filtros dos 58 entre QAS e branch. Se divergirem, o deploy na QAS espera e a demanda volta ao builder para remontar sobre a base da QAS. O build não toca a QA.

## Dados de teste
`fixtures/publicos-mc-eplast42.apex` foi só gravado. Não foi executado: a execução e a limpeza (`MODO='LIMPAR'`) são do verificador na dev. Pontos a validar na primeira execução: `Database.convertLead` (status de conversão e duplicidade) e a faixa Alta de L6 (fórmula: setor 30 + origem 30 + Contatado 40 = 100). Proprietário de teste da regra 6: `005bJ00000piKAaQAM` (ativo na dev).

## Premissas assumidas
Seguem as PD-01 a PD-08 do `03-design.md`; o build as aplicou sem mudança.

## Versões e ativação
Não se aplica. Nenhum Flow, classe Apex ou agente Agentforce foi alterado (`Lead_AfterInsert_AplicaRegraAtribuicao`, `LeadAssignmentService` e `SFAgent2` ficam como estão). Relatório e permission set não têm ativação; ficam valendo no deploy.
