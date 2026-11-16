**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, usuário de execução: conta de serviço da Konecta, Id `005bJ00000piKAaQAM`)

# EPLAST-46 — Testes na QA: sugestão de campanhas (SFAgent2 v9)

`sf org list` mostrou uma única org conectada: `sbx-eplast-qa` (Org Id `00DHa000006vZtmMAE`). Produção e Marketing Cloud não tocados. Nenhum deploy feito por mim.

## Falhas
Nenhuma.

## Conferência do pacote (05-deploy-qa.md, deploy `0AfHa00000EIAYjKAP`)
Presentes na QA: `BotVersion` SFAgent2 v9; planner `SFAgent2_v9` (1); Flow `Account_Agente_SugestaoCampanha` (v1, Active, AutoLaunched); `CampaignSuggestionSetting__mdt` com `AMPLIACAO_MIX` e `REATIVACAO` (ativos); custom permission `SugestaoCampanha_EPLAST46`; permission set `PS_Marketing_SugestaoCampanha`; relatório `AMPLIACAO_MIX_CONTATOS`. `CommercialSignal__c` existe (1358 registros, agregado).

## Ativação do agente
SFAgent2 antes: v7 Active (v8 e v9 Inactive). `sf agent activate --api-name SFAgent2 --version 9 --target-org sbx-eplast-qa` -> "SFAgent2 v9 activated". Depois: v9 Active (`BotVersion.Status`), v7 e v8 Inactive. Fica ativa ao final.

## Interferência (preflight)
EPLAST-27/29/34 (SFAgent2): a v9 do pacote já contém as ações `ProximaAcaoCliente_EPLAST27_v9`, `ResumoReuniao_EPLAST34_v9` e `CriarTarefa_EPLAST29_v9`; `BotDefinition` SFAgent2 segue 1. Relatórios da pasta `MARKETING CLOUD`: 68 na QA; `AMPLIACAO_MIX_CONTATOS` existe uma vez. Nada indicou conflito; as demais ações não foram exercitadas por esta demanda.

## Mudanças temporárias no usuário de execução (todas desfeitas)
| O que | Antes | Durante | Depois |
|---|---|---|---|
| `User.ProtheusSellerId__c` | vazio | `000001` | vazio (conferido) |
| Permission set `PS_Marketing_SugestaoCampanha` | não atribuído | atribuído após os casos de acesso negado | removido (0 atribuições, conferido) |
| SFAgent2 | v7 ativa | v9 ativada | v9 permanece ativa |

## Dado de teste
Fixture `fixtures/conta-oportunidade-contato-sinal.apex` adaptada na QA (duplicidade de Account exigiu `allowSave`; sinais gravados depois do PS; README atualizado). 6 contas `TESTE EPLAST-46 A..F` (A 100 dias, B 30, C sem compra, D 30 + sinal Cruzada, E 200 + sinal, F 200 com contato opt-out), contatos de teste. Não li nem alterei registro real. Conta de serviço da Konecta: dois usuários casam o filtro (`005bJ00000hBJmYQAW` inativo e `005bJ00000piKAaQAM` ativo, que é o próprio usuário de execução); o acesso negado foi testado antes de atribuir o PS a mim.

## Casos
| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| T1 | CA-09 Flow | Sem PS, `Flow.Interview` nas contas A e B | acesso negado, sem dado | `NO_ACCESS`: "Você não tem acesso à sugestão de campanhas. Peça ao administrador o permission set PS Marketing Sugestão de Campanha." | passou |
| T2 | CA-09 agente | Sem PS, `sf agent preview start/send` com v9: "Qual campanha você sugere para a conta TESTE EPLAST-46 A?" | acesso negado | Mesma mensagem de acesso negado, sem dado da conta | passou |
| T3 | CA-01 | Flow, conta A (100 dias) | reativação com motivo | `REATIVACAO`: "sem compra há 100 dias (última compra ganha). Público: SEM COMPRA - 91 A 180 DIAS" (mesma informação do critério, com o número exato de dias) | passou |
| T4 | CA-02 / CA-12 | Conta B (30 dias, sem sinal) | sem reativação | `NONE`: "comprou recentemente e não há produto sugerido" | passou |
| T5 | CA-03 | Conta F (único contato opt-out e-mail) | e-mail sem contato elegível | "sem contato elegível para e-mail; 1 para mensagem" (conta E, sem contatos, idem) | passou |
| T6 | CA-04 | Conta A (c1 opt-out e-mail, c2 opt-out mensagem, c3 livre) | e-mail 2, mensagem 2 | "2 para e-mail; 2 para mensagem" | passou |
| T7 | CA-05 (reescrito no design) | Conta D (30 dias, sinal PREF) | ampliação de mix citando PREF | `AMPLIACAO_MIX`: "grupos ... PREF (1 produto(s) sugerido(s); sinais calculados em 2026-11-16). Público: AMPLIACAO MIX - CONTATOS. 1 para e-mail; sem contato elegível para mensagem" | passou |
| T8 | CA-06 | Conta C (sem histórico) | `SEM_HISTORICO`, sem erro | `SEM_HISTORICO`; sem exceção na execução | passou |
| T9 | Prioridade | Conta E (200 dias + sinal) | reativação antes de mix | `REATIVACAO`; duas linhas, reativação primeiro | passou |
| T10 | CA-07 | Contagens antes/depois de 6 execuções do Flow e 2 do agente | iguais | Campaign 5/5, CampaignMember 3/3, EmailMessage 805/805, `et4ae5__IndividualEmailResult__c` 0/0 | passou |
| T11 | CA-08 | `BotVersion`/`BotDefinition` | nova versão, mesmo nº de agentes | v9 criada (v7, v8 existentes); `BotDefinition` SFAgent2 = 1 | passou |
| T12 | Agente com PS | v9 ativa, PS atribuído, mesma pergunta | sugestão do Flow na resposta | "Campanhas sugeridas ... Reativação ... 100 dias ... Público: SEM COMPRA - 91 A 180 DIAS ... Nada foi enviado: o disparo é feito pelo Marketing Cloud." | passou |
| T13 | CA-11 | grep do log das 6 execuções por `example.invalid` e `(11)9000` | 0 | 0 ocorrências; só nome da conta de teste, dias, grupo, público e contagens | passou |
| T14 | Relatório `AMPLIACAO MIX - CONTATOS` | `Reports.ReportManager.runReport` com c5 elegível e c6 opt-out em D | só o elegível | 1 linha, do contato de teste | passou |
| T15 | CA-10 | Sem Apex novo | n/a | não se aplica | não executado (n/a) |

12 passos de agente/Flow aprovados, 0 reprovados; T15 não se aplica.

## O que pode ter saído da org
Nenhum e-mail, mensagem ou chamada externa (contagens de envio inalteradas). A org criou 1 `Case` por conta de teste (automação existente); apagados junto. Limpeza conferida: contas, oportunidades, casos, contatos, `Branch__c`, `PaymentTerms__c` de teste = 0. A primeira tentativa de fixture falhou por duplicidade e foi revertida inteira.

## Observações
- Limite de SOQL do Flow (~6 a 7 consultas por conta): não usar em loop de mais de ~14 contas numa transação (achado da verificação na dev; não reexercitado aqui).
- Premissas PA-46-01 a 06 testadas conforme o design; nenhuma motivo de reprovação.
