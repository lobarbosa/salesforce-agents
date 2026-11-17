**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-39 — Verificação (dev)

Org confirmada com `sf org list`: único alias conectado `sbx-eplast-dev` (usuário de execução `005bJ00000piKAaQAM`, instância `eplast--qa`, que é a dev da esteira pela regra 5 do CLAUDE.md). Não toquei QA, produção nem Marketing Cloud. Nada foi alterado no metadata.

## Dado de teste
- Fixtures novas gravadas: `clients/eplast/fixtures/lead.apex` (8 leads, 2 convertidos sem oportunidade) e `clients/eplast/fixtures/campanha_oportunidade_ganha.apex` (conta, filial, condição, 2 campanhas, 2 oportunidades Indústria ganhas). Todos `TESTE EPLAST-39`. `TriggerUtility.bypassTrigger = true` nos dois.
- Leads: Campanha x3 (1 convertido), WhatsApp x2 (1 convertido), Google Ads x1, vazio x1, "Origem Inventada XYZ" x1. Antes dos testes a dev tinha 0 leads no mês.

## Mudanças temporárias no usuário de execução (todas desfeitas)
| Item | Antes | Durante | Depois |
|---|---|---|---|
| `PermissionSetAssignment` de `PS_Marketing_AnaliseCampanhas` | nenhuma | atribuído (`0PaHa00000EJYxEKAX`) | removido (COUNT = 0) |
| `User.ProtheusSellerId__c` (exigido pela validação `CheckAccountOwnerHasProtheusSellerId`) | vazio | `TESTE39` | vazio |
| `User.UserPermissionsMarketingUser` (criar e apagar Campaign) | false | true | false |

Perfil, papel e outros usuários intocados. Conferido por consulta: usuário com os dois campos vazios/false.

## Resultado por critério
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | CA-01 | Painel atualizado por `PUT /analytics/dashboards/<id>`; componente "Leads por Origem"; SOQL `COUNT(Lead)` | Soma dos grupos = total | Campanha 3 + Fora da lista 1 + Google Ads 1 + Sem origem 1 + WhatsApp 2 = 8; total do relatório 8; SOQL 8 | passou |
| 2 | CA-02 | Lead sem origem | Linha "Sem origem", nenhuma "-" | Fórmula = "Sem origem"; relatório mostra "Sem origem" (1), sem "-" | passou |
| 3 | CA-03 | Lead com `LeadSource='Origem Inventada XYZ'` | Cai em "Fora da lista" | Fórmula e relatório: "Fora da lista" (1); o valor não aparece como linha | passou |
| 4 | CA-04 | `sf sobject describe Lead` (LeadSource, 13 ativos, não restrita) x `CASE` da fórmula (Tooling API) | 13 iguais | 13 valores idênticos, sem a mais nem a menos | passou |
| 5 | CA-05 | `POST /analytics/reports/<id>` com `standardDateFilter` ad hoc (sem salvar) | Totais recalculam; soma = total | LAST_MONTH = 0; THIS_MONTH = 8, grupos somam 8 | passou (nível de relatório) |
| 6 | CA-06 | Relatório de conversão, no painel, com 2 convertidos de 8 | Taxa = convertidos / total por origem | Campanha 33% (1/3), WhatsApp 50% (1/2), demais 0%, total 25% (2/8); SOQL IsConverted = 2 | passou |
| 7 | CA-07 | Painel atualizado, 5 componentes lidos | Todos com dado, formato resumo | 5 de 5 com `componentDataStatus: DATA`, sem erro, todos `SUMMARY`; com dado em Leads, Conversão e Desempenho (Opp x campanha: 2.500 e 700) | passou |
| 8 | CA-08 | Campanha com `ActualCost=1000` e oportunidade ganha de 2.500 | Retorno = 2.500 / 1.000 | Relatório `MKT_Desempenho_Campanhas`: fórmula "Receita ganha / custo real" = 2,50 | passou |
| 9 | CA-09 | Campanha sem custo, ganha de 700 | Sem erro de divisão; "n/a" | Célula "-" (em branco), sem erro. O texto "n/a" não é possível por PA-03 (célula em branco, premissa assumida) | passou (conforme PA-03) |
| 10 | CA-10 | `git diff origin/main...HEAD` fora de `demandas/` | Só pasta `Marketing_Origem_Retorno`, PS e o necessário | Em `force-app`: campo, pasta e grupo `Marketing_Origem_Retorno`, 5 relatórios, painel, PS. Nada fora disso | passou |
| 11 | CA-11 | `ObjectPermissions`/`FieldPermissions`/`PermissionSet` do PS | Só leitura; vê relatórios | Lead, Campaign, Opportunity: Read true, Create/Edit/Delete false; FLS do campo novo: leitura true, edição false; `RunReports` true; sem `ViewAll`/`ModifyAll` | passou (por metadata) |
| 12 | CA-12 | Mesmo diff | Sem e-mail, Flow, trigger, Apex novos | Nenhum componente desse tipo no diff | passou |
| 13 | CA-13 | Metadata do relatório e `describe` | Resumo, sem coluna pessoal | `MKT_Leads_por_Origem`: Summary, `showDetails false`, sem coluna de detalhe, agrupa por origem e mês | passou |
| 14 | CA-14 | `sf org display` do alias de dev | Instância diferente da QA | Dev: `eplast--qa.sandbox`. A QA (`eplast--qas`) não está conectada neste job e não foi tocada; diferença documentada na regra 5 do CLAUDE.md | não executado (comparação direta) |

## O que ficou sem prova
- **CA-11, caso de acesso negado real:** o usuário de execução tem perfil de administrador, então a negação de edição não foi tentada por DML. Provado só pelas permissões do PS. O QA já cobre o caso sem PS (rodada 1).
- **CA-05 no painel:** o filtro foi exercitado no relatório (ad hoc); não há filtro de painel (desvio 2 do build). Não há como mexer em filtro de painel de forma legítima por API aqui.
- **CA-14:** não comparei `instanceUrl` das duas orgs, só a dev.
- **Execução dos relatórios por GET direto na API:** `MKT_Leads_por_Origem` e `MKT_Conversao_Leads_por_Origem` devolvem erro 203 ("nenhuma coluna selecionada") quando executados sozinhos, porque não têm coluna de detalhe (design R1: sem dado pessoal). Pelo painel e pelo `POST` com coluna ad hoc, rodam certo. Não vi como a tela de relatório se comporta no navegador. Vale o QA abrir os dois relatórios pela interface; se der o mesmo erro, é ajuste do builder (por exemplo, uma coluna não pessoal).

## O que pode ter saído da org
Nenhuma chamada externa, e-mail ou integração (sem trigger em Lead; Account e Opportunity com bypass). Registro criado pela cadeia: 2 Cases "Pós-vendas: TESTE EPLAST-39 Opp 1/2" (automação existente da org ao ganhar a oportunidade, não do build), apagados. Contagem final de todos os objetos com `TESTE EPLAST-39` (Lead, Account, Contact, Case, Campaign, Opportunity, Branch__c, PaymentTerms__c): 0.

## Observações
- A primeira tentativa de limpeza reverteu inteira (Cases bloqueavam a exclusão da conta); refiz apagando os Cases primeiro. Registrado no topo da fixture.
- O commit com `.claude/agents/qa.md` e `scripts/implantar-build-qa.sh` não foi analisado, como orientado.
