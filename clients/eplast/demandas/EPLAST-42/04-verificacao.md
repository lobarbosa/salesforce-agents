**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-42 — Verificação do build (rodada 2)

Org confirmada com `sf org list` (Sandbox, Connected, usuário de execução `005bJ00000piKAaQAM`). Dados: `fixtures/publicos-mc-eplast42.apex` (CRIAR e depois LIMPAR), prefixo `EPLAST42 TESTE`: 6 leads (L3 convertido pelo script), 3 contas Recorrente, 5 contatos, 3 oportunidades. Relatórios executados pela Analytics API; só foram lidas linhas com `EPLAST42 TESTE`.

## Reteste da rodada 1

FALHA 1 (lote dos relatórios de MARKETINGCLOUD fora da dev): **corrigida**. Retrieve de 61 relatórios da pasta na dev (`sf project retrieve start ... --target-metadata-dir`, XML conferido por script):
- `HasOptedOutOfMobile__c` em 59 relatórios: 42 ContactList com `Contact.et4ae5__HasOptedOutOfMobile__c` e 17 LeadList com `Lead.et4ae5__HasOptedOutOfMobile__c` (16 alterados + o novo). Sem o critério: só `CLASSIFICACAO_CONTAS_POR_CLASSE` e `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` (agregações, previsto).
- `CONVERTED` em 17 de 17 LeadList. Todos os critérios de celular e CONVERTED com operador `equals` e valor 0/false (0 divergentes).
- Contagem de celular por arquivo igual entre a dev e o XML da branch (0 diferenças).

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | CA-01 | Lista do plano (58 + 1 + 1 PS) contra a org (retrieve acima) | Todo alterado listado e presente na org | 58 alterados e o novo estão na org com o critério; 2 agregações intactas | passou |
| C2 | CA-02 | `SEM_COMPRA_91_A_180_DIAS` e `CONTAS_E_CONTATOS_RECORRENTES_6PU` com contato `HasOptedOutOfEmail=true` | Contato fora | Ausente nos dois | passou |
| C3 | CA-03 (contato) | Mesmos relatórios, contato com opt-out de celular | Contato fora | Ausente nos dois (91-180: 1 linha, só `C100`; 6PU: C100, C365, C400) | passou (retestado) |
| C4 | CA-03 (lead) | `LEADS_SP_2yf` e `LEADS_SEGMENTO_ALIMENTOS` com L1 (opt-out celular) | L1 fora | L1 ausente. SP: L2, L4, L6. Alimentos: L2, L6 | passou (retestado) |
| C5 | CA-03 (relatório novo) | `LEADS_PROSPECCAO_PRIORIDADE` | L1 fora | L1 ausente (L2, L4, L6) | passou |
| C6 | PD-03 convertido | L3 com `IsConverted=true` (SOQL); relatórios de lead | L3 fora | L3 ausente em `LEADS_SP_2yf`, `LEADS_SEGMENTO_ALIMENTOS` e no novo | passou (retestado) |
| C7 | CA-04 | Contas com última compra há 100, 365 e 400 dias; os três públicos de reativação | 100 só em 91-180; 400 só em >365 | 91-180: C100; 181-365: C365; >365: C400 | passou |
| C8 | CA-05 | SOQL de `MKT_Origem_Agrupada__c` e `MKT_Leads_por_Origem` | Evento = "Evento"; vazio = "Sem origem" | SOQL: L4 e L6 "Evento"; L1, L2, L3, L5 "Sem origem". Relatório: grupo Evento (L6, L4), grupo Sem origem (L5, L3, L2, L1), total 6. Ver nota abaixo | passou |
| C9 | CA-06 | `LEADS_PROSPECCAO_PRIORIDADE` | Alta aparece; "Sem dados suficientes" não | L6 (Alta) aparece. L5 (Sem dados suficientes) fora. L3 (Alta) fora por conversão; L1 fora por opt-out | passou |
| C10 | PS | `FieldPermissions` de `PS_Marketing_Publicos` em Lead; PS atribuído ao usuário | Leitura sem edição nos 3 campos; campos legíveis | `PermissionsRead=true`, `PermissionsEdit=false` nos campos do Lead consultados (3 do EPLAST-42 inclusos); `PriorityBand__c` e `MKT_Origem_Agrupada__c` lidos por SOQL | passou |
| C11 | CA-07 | Conferência por metadata (rota prevista no design, linha 228) | Campo existe e não foi alterado | `CampaignMember.et4ae5__Activity__c` existe (FieldDefinition); `git diff main...HEAD` sem arquivo `et4ae5`. Não criei Campaign nem CampaignMember | passou (por metadata; sem execução de relatório de retorno) |
| C12 | CA-08/09/10 | `git diff --name-only main...HEAD` filtrando flows, classes, triggers, objetos e `et4ae5` | Nenhum | Nenhum arquivo dessas pastas; só relatórios, o PS, fixtures e artefatos | passou |
| C13 | CA-11 | Campo novo em Lead ou Contact | Nenhum campo novo, nada a documentar | Nenhum campo criado | passou (não se aplica) |

Notas:
- `MKT_Leads_por_Origem` existe só na dev (vem do EPLAST-39; não está na branch nem foi alterado por esta demanda) e não tem coluna de detalhe, então `includeDetails=true` devolve erro 203 do produto. Rodei por POST com `reportMetadata.detailColumns=["LAST_NAME"]` como sobreposição só na execução, sem salvar nada no relatório. O relatório salvo continua sem colunas; é achado do EPLAST-39, não do build.
- C10: o PS tem 10 leituras de Lead (as demais pré-existentes); conferi só que os campos do EPLAST-42 estão `Read=true`, `Edit=false`.
- A coluna de origem agrupada continua fora do relatório novo (falta FLS ao usuário que implanta; desvio já declarado pelo builder, decisão do gate). Não é falha de critério: CA-05 passa pelo `MKT_Leads_por_Origem`.
- CA-12 (QA com Partial Copy) é da etapa de QA; fora do escopo desta verificação.

## Mudanças no usuário de execução (dev) e reversão
- `User.ProtheusSellerId__c` (`005bJ00000piKAaQAM`): antes vazio, durante `TESTE42`, devolvido a vazio (SOQL: null).
- Atribuição de `PS_Marketing_Publicos`: antes ausente, atribuída, removida ao final (contagem 0).
- `UserPermissionsMarketUser`/`UserPermissionsMarketingUser`: não alterado (false).

## O que pode ter saído da org
A cadeia criou 3 Casos "Pós-vendas: EPLAST42 TESTE Opp C100/C365/C400" (um por oportunidade ganha); apagados por mim antes da limpeza. `TriggerUtility.bypassTrigger = true`: nenhuma integração com Protheus ou BrasilAPI. Nenhum e-mail, nada no Marketing Cloud, nada na QA.

## Limpeza
`MODO='LIMPAR'` executado (`FIXTURE_LIMPO`). Contagem de `EPLAST42 TESTE` em Lead, Account, Contact, Opportunity e Case: 0. Nada ficou, nenhum job agendado. O fixture foi rodado como está na branch (edição temporária do modo revertida com `git checkout`).
