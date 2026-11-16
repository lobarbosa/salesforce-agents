**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-34 — Testes na sandbox de QA

Org confirmada com `sf org list`: única org `sbx-eplast-qa` (Sandbox, Connected, Org Id `00DHa000006vZtmMAE`). Todos os comandos com `--target-org`/`-o sbx-eplast-qa`. Nada na dev, em produção ou no Marketing Cloud.

## Falhas
Nenhuma falha que bloqueie o aceite. Duas lacunas de prova, não reprovadoras (seção "O que ficou sem prova").

## Pacote e agente
- Componentes de `05-deploy-qa.md` conferidos na org: classes `MeetingSummaryService` e `MeetingSummaryServiceTest` (2 linhas em `ApexClass`), planner `SFAgent2_v8` (7 planners `SFAgent2_v1`..`_v8`), ação `ResumoReuniao_EPLAST34_v8` (`GenAiFunctionDefinition`, alvo Apex `01pHa000004mhtBIAQ`), permission set `PS_Comercial_ResumoReuniao` (Id `0PSHa000002DORZOA4`).
- **Versão do SFAgent2 na QA:** antes, v4 Active (v1,v2,v3,v6,v7,v8 Inactive). Ativada a v8 com `sf agent activate --api-name SFAgent2 --version 8 --target-org sbx-eplast-qa` ("SFAgent2 v8 activated"). Depois, por `BotVersion.Status`: v8 Active, v4/v6/v7 Inactive. **Fica ativa.** Risco de conflito com EPLAST-27/29/46 (pré-checagem): a v8 já traz as ações de 27 e 29 (`ProximaAcaoCliente_EPLAST27_v8`, `CriarTarefa_EPLAST29_v8`) segundo o pacote.

## Mudanças no usuário de execução (Id `005bJ00000piKAaQAM`, desfeitas)
| Mudança | Antes | Depois | Estado final |
|---|---|---|---|
| Permission set `PS_Comercial_ResumoReuniao` atribuído | sem atribuição | atribuído | removido; contagem de atribuições = 0 |
| Campo "ID Usuário Protheus" (`ProtheusSellerId__c`) para a regra de validação da conta | nulo | `TESTE34` | devolvido a nulo (conferido) |
`UserPermissionsMarketingUser` não tocado (false). Perfil, papel e outros permission sets intactos. A conta de serviço Konecta (Id `005bJ00000hBJmYQAW`, inativa; o ativo é o próprio usuário de execução) não foi alterada.

## Dados de teste (criados por mim)
Conta `TESTE EPLAST-34 Conta A` (CNPJ e contatos fictícios, e-mail `.invalid`), 5 Opportunity `TESTE EPLAST-34 Opp 1..5` (tipo de registro Indústria, etapa Qualificação, `CloseDate` 10/03/2031, Amount 1.000 a 5.000, soma 15.000) e 1 Order da conta (Status "Revisao de Pedido", `EffectiveDate` 12/03/2031, TotalAmount 0). Período de 2031 escolhido de propósito: 0 Opportunity e 0 Order reais nessa janela (query de contagem antes), então os totais conferidos só contêm dado de teste. Fixtures: `clients/eplast/fixtures/` não existe no workspace; usei Apex anônimo com `allowSave` de duplicidade apenas nos meus registros (a regra de duplicidade acusava conta real; nada real foi lido).

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-10 teste Apex | `sf apex run test -n MeetingSummaryServiceTest -c` na QA | 100% pass, cobertura >= 85% | 10 testes, Pass Rate 100%, cobertura `MeetingSummaryService` 93% | passou |
| T2 | CA-02 números | Apex anônimo, `resumir` COMERCIAL, 01-31/03/2031 | contagem 5, total 15.000 em pt-BR, igual à query de mesmo filtro | "Qualificação: 5 oportunidade(s), R$ 15.000,00"; SOQL `COUNT/SUM` de mesmo filtro: 5 e 15000 | passou |
| T3 | CA-04 seções por tipo | `resumir` para COMERCIAL, GDD, SOP, BOARD | cada tipo só com suas seções (PA-07) | COMERCIAL: etapa + vendedor; GDD: oportunidades por conta + pedidos por conta; SOP: pedidos por status + total; BOARD: pipeline por vendedor + pedidos por vendedor + total geral, sem nome de conta. Nenhuma seção cruzada | passou |
| T4 | CA-03 corte e origem | mesma execução | data/hora de corte e objeto.campo por número | `dataHoraCorte` preenchida nas 4; cada título com origem (ex.: `Opportunity.StageName, Opportunity.Amount`); rodapé "Dados ate 15/11/2026 22:49" (fuso da org, GMT-3) | passou |
| T5 | CA-05 sem gravação | contagens de Account/Opportunity/Order e DML dentro da execução; `MAX(LastModifiedDate)` dos meus registros antes e depois | sem mudança | Account 1221/1221, Opportunity 9337/9337, Order 10321/10321; DML da execução 0; `LastModifiedDate` dos meus opps 01:49:42Z antes e depois | passou |
| T6 | CA-06 sem envio | `EmailMessage` antes e depois; callouts na execução | sem mudança, 0 callout | 805/805; callouts 0; e-mails 0 | passou |
| T7 | CA-07 dado pessoal | regex de e-mail, CPF e telefone sobre o texto dos 4 tipos (conta de teste com e-mail e telefone fictícios preenchidos) | nenhum padrão | `pii=false` nos 4 | passou |
| T8 | CA-08 falha / tipo inválido | `resumir` tipo `xyz`; período 2000-2040 | mensagem de erro, sem resumo | `ERRO` "Tipo de reuniao invalido..."; `ERRO` "Periodo maior que 366 dias..." | passou |
| T9 | CA-08 falha simulada na agregação | teste Apex `deveDevolverListaVaziaOuErroSemExplodir` / VOLUME (T1) | erro sem parcial | coberto pelos 10 testes (T1); não injetei falha própria na org | passou (via teste do builder) |
| T10 | CA-11 período | `resumir` SOP sem datas; com 01-31/03/2031 | padrão = mês corrente, exibido; informado respeitado | "periodo 01/11/2026 a 30/11/2026" (corrente); "01/03/2031 a 31/03/2031" | passou |
| T11 | CA-01 acesso negado | teste Apex `deveInformarSemAcessoParaUsuarioSemLeituraDeOpportunityEOrder` (`runAs`), executado na QA em T1 | `SEM_ACESSO`, sem dado | passou dentro dos 10 testes. Não executei com usuário real de perfil sem leitura (a conta de serviço é Administrador do sistema) | passou (via teste Apex) |
| T12 | CA-01 com leitura | `resumir` COMERCIAL com o PS, usuário com leitura | totais batem com a consulta de mesmo filtro | igual a T2 | passou |
| T13 | CA-09 sem agente novo | `BotDefinition`, `GenAiPlannerDefinition` | só SFAgent2 ganha a ação | 2 bots (`SFAgent2`, `SearchAgent`; `SearchAgent` não consta em `05-deploy-qa.md`, pré-existente); planners só `SFAgent2_v*`; ação `ResumoReuniao_EPLAST34_v8` no bundle v8 | passou |
| T14 | CA-12 dados identificados | nomes dos registros criados | marca de teste | todos com `TESTE EPLAST-34` | passou |
| T15 | Ativação v8 | ver seção "Pacote e agente" | v8 Active | v8 Active | passou |
| T16 | Volume | execução de T2/T3 | longe dos limites | Board/GDD: 34 SOQL de 100 somando 5 resumos, 72 linhas de 50.000, CPU 124 ms de 10.000, DML 0 | passou |

## O que ficou sem prova
1. **Roteamento da conversa (R4 do design).** `sf agent preview` é interativo e falha em CI (já na dev) e a tela do Agent Builder na QA não abriu por `qa_browser_*` (clique em "SFAgent2" expirou, sem sessão útil). Provei a ação (Apex), a existência dela no planner v8 e a instrução no bundle, mas não que as 4 frases vão para `ResumoReuniao` e não para `AgregacaoPedidos`, nem a regressão das ações de EPLAST-27/29. Fica para o roteiro do cliente.
2. **Valor monetário de pedidos conferido com relatório.** O Order de teste tem TotalAmount 0 (criar item exige catálogo e regras fora do escopo). Contagem de pedidos conferida; soma de pedidos só vista agregada sem comparação (período corrente: 8 pedidos, R$ 4,75, dado real agregado, sem nome).

## O que pode ter saído da org
Criados: 1 Account, 5 Opportunity, 1 Order, todos `TESTE EPLAST-34`, mantidos (não apaguei para não disparar automação de exclusão). A criação passa pela cadeia existente de triggers/Flows de Account e Order (possível integração com Protheus, `SendAccountToProtheus`/`SendOrderToProtheus`); não consegui ler o resultado dessas chamadas (a conta de serviço tem 13 linhas de AsyncApexJob "Completed" hoje, sem falha). EmailMessage não mudou (805). Nenhum envio de e-mail pela solução. Remoção: apagar os registros `TESTE EPLAST-34*`.
