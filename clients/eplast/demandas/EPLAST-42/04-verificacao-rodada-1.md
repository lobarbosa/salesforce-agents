**Verificação:** reprovada
**Org de teste:** `sbx-eplast-dev` (conexão confirmada com `sf org list`: Sandbox, Connected; Id do usuário de teste `005bJ00000piKAaQAM`)

# EPLAST-42 — Verificação do build

Dados de teste: `fixtures/publicos-mc-eplast42.apex` (CRIAR) na dev: 6 leads, 3 contas Recorrente, 5 contatos (+1 do lead convertido), 3 oportunidades. Relatórios executados pela Analytics API (`includeDetails=true`); só foram contadas linhas com `EPLAST42 TESTE`.

## Falhas

### FALHA 1 — Filtro de opt-out de celular está em 2 dos 58 relatórios alterados na dev
- Como reproduzir: `sf project retrieve start -o sbx-eplast-dev` dos 58 `Report:MARKETINGCLOUD/<nome>` da lista do `04-plano-build.md`, depois contar `HasOptedOutOfMobile` nos XML baixados.
- Obtido: só `COMPRA_ULTIMOS_90_DIAS` e `LEADS_OlB` (os dois pilotos) têm o critério. `CONVERTED` aparece em 1 relatório (`LEADS_OlB`). Os outros 56 estão sem o filtro na org. Na branch, 59 XML têm o critério (58 + o novo), então o XML da branch não corresponde ao que está na dev.
- Efeito medido: `SEM_COMPRA_91_A_180_DIAS` devolveu o contato sintético com opt-out de celular (`EPLAST42 TESTE C100 optout celular`). `LEADS_SP_2yf` e `LEADS_SEGMENTO_ALIMENTOS` devolveram L1 (opt-out de celular) e L3 (convertido).
- Esperado: nenhum desses aparecer (CA-03, e filtro de lead não convertido, PD-03).
- Causa provável: o deploy em lote dos 56 não chegou à dev, ou foi sobrescrito, ou foi aceito com o critério descartado em silêncio por falta de FLS do usuário que implanta no campo `et4ae5__HasOptedOutOfMobile__c`, como já ocorreu com a coluna de origem. FLS de leitura do campo existe só em `PS_Marketing_Publicos` (Lead), no perfil `X00ex00000018ozT_128_09_43_34_1` e em alguns PS de integração. Reimplantar e conferir por retrieve.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | CA-01 | Conferi a lista do plano contra a org | Todo alterado listado com justificativa | Lista de 58 + 1 + 1 PS presente, mas 56 dos 58 não estão alterados na org (FALHA 1) | falhou |
| C2 | CA-02 | Executei `SEM_COMPRA_91_A_180_DIAS` e `CONTAS_E_CONTATOS_RECORRENTES_6PU` com contato HasOptedOutOfEmail=true | Contato fora | Contato com opt-out de e-mail ausente nos dois (filtro `EMAIL_OPT_OUT` já existia) | passou |
| C3 | CA-03 (contato) | Mesmos relatórios, contato com opt-out de celular | Contato fora | Contato `optout celular` aparece em `SEM_COMPRA_91_A_180_DIAS` e no 6PU | falhou |
| C4 | CA-03 (lead) | `LEADS_SP_2yf` e `LEADS_SEGMENTO_ALIMENTOS` com L1 (opt-out celular) | L1 fora | L1 presente nos dois (5 e 4 linhas de teste) | falhou |
| C5 | CA-03 (relatório novo) | `LEADS_PROSPECCAO_PRIORIDADE` com L1 | L1 fora | L1 ausente; filtros no describe: faixa, e-mail, celular, convertido | passou |
| C6 | PD-03 convertido | `Database.convertLead` em L3; relatórios de lead | L3 fora | Convertido (`IsConverted=true`). Fora do relatório novo; presente em `LEADS_SP_2yf` e `LEADS_SEGMENTO_ALIMENTOS` | falhou (relatórios antigos) |
| C7 | CA-04 | Contas com última compra há 100, 365 e 400 dias (`LastPurchase__c` = 2026-08-07, 2025-11-15, 2025-10-11) | 100 só em 91-180; 400 só em >365 | 91-180: C100; 181-365: C365 (fronteira); >365: C400. C100 não aparece em 181-365 e C400 só em >365 | passou |
| C8 | CA-05 | SOQL `MKT_Origem_Agrupada__c` com PS atribuído ao usuário | Evento = "Evento"; vazio = "Sem origem" | L4 e L6 "Evento"; L1, L2, L3, L5 "Sem origem". Relatório por origem (`MKT_Leads_por_Origem`) não executado (Id obtido, run da API falhou) | passou parcial (campo); relatório não executado |
| C9 | CA-06 | `LEADS_PROSPECCAO_PRIORIDADE` | Alta aparece; "Sem dados suficientes" não | PriorityBand: L6 Alta (100), L3 Alta (70, convertido), L4 Média, L1/L2 Baixa, L5 Sem dados suficientes (0). Relatório devolveu 3 linhas de teste: L6, L2, L4. L5 fora, L1 e L3 fora por opt-out e conversão | passou |
| C10 | Desvio do builder | Colunas do relatório novo | Sem `MKT_Origem_Agrupada__c` (fato a verificar) | Confirmado: colunas FIRST_NAME, LAST_NAME, COMPANY, STATE, Sector__c, LEAD_SOURCE, PriorityScore__c, STATUS, EMAIL; sem a coluna de origem agrupada nem `PriorityBand__c` (o agrupamento é pela faixa). Segue pendente a decisão do gate sobre FLS (P1) | confirmado, não resolvido |
| C11 | PS | Consulta `FieldPermissions` e atribuição de `PS_Marketing_Publicos` ao usuário de execução | 3 leituras, sem edição; campo legível | 3 campos `PermissionsRead=true`; com o PS atribuído, `PriorityBand__c` e `MKT_Origem_Agrupada__c` lidos por SOQL | passou |
| C12 | CA-07 | Relatório de retorno com CampaignMember | — | Não montei CampaignMember nem executei | não executado |
| C13 | CA-08/09/10 | `git diff --name-only main...HEAD` filtrando flows, classes, triggers, objetos, `et4ae5` | Nenhum | Nenhum arquivo dessas pastas | passou |

## Mudanças no usuário de execução (dev) e reversão
- `User.ProtheusSellerId__c` (`005bJ00000piKAaQAM`): antes vazio, depois `TESTE42`, devolvido a vazio ao final (conferido por SOQL).
- Atribuição de `PS_Marketing_Publicos`: antes ausente, atribuída, removida ao final.
- `UserPermissionsMarketingUser`: não alterado (false).

## Ajuste no fixture
`publicos-mc-eplast42.apex` falhou na 1a execução (validation `CheckAccountHasPhone` da Oportunidade exige telefone na Conta). Acrescentei `Phone='(11)30000000'` às contas e uma nota no cabeçalho; a 2a execução passou. O Apex anônimo é transacional, sem resíduo da 1a.

## O que pode ter saído da org
A cadeia criou 3 Casos "Pós-vendas: EPLAST42 TESTE Opp C100/C365/C400" (00001208 a 00001210), um por oportunidade ganha. Apagados por mim antes da limpeza (impediam excluir a Conta). Com `TriggerUtility.bypassTrigger = true`, nenhuma integração com Protheus disparada. Nenhum e-mail, nenhuma chamada ao Marketing Cloud.

## Limpeza
`MODO='LIMPAR'` executado (`FIXTURE_LIMPO`). Contagem de `%EPLAST42 TESTE%` em Lead, Account, Contact, Opportunity, Case, Branch__c e PaymentTerms__c: 0. Nada ficou. Nenhum job agendado.

## Para o builder
Corrigir FALHA 1: reimplantar os 56 relatórios na dev, baixar de volta e confirmar o critério `et4ae5__HasOptedOutOfMobile__c` (e `CONVERTED` nos 16 de Lead) em cada um, antes de nova verificação. Retestar C3, C4, C6 e rodar `MKT_Leads_por_Origem`.
