**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`)

# EPLAST-47 — Testes na QA (rodada 4: classificar a conta ao salvar a oportunidade)

`sf org list`: só `sbx-eplast-qa` (Connected). Todo comando com `--target-org` explícito. Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EJ3a1KAD`): Flow `Opportunity_AfterSave_ClassificaConta` v1 **Active**; `RankingRange__mdt` com 7 faixas (MP 10.000, PP 35.000, P 80.000, M 160.000, G 500.000, GG 1.000.000, 3G sem teto, `SortOrder__c` 1 a 7); `ScheduledFlowOpportunitySetting.Default` com `RunDayOfMonth__c` = 14 e `FaultRecipient__c` vazio; relatório `AccountRankingChanges` existe (`00OHa000002zCUX`); picklist `Ranking__c` com os 7 valores ativos. Nada faltando.

Como é uma rodada nova, a falha da rodada 3 (limite de Queueable ao atualizar contas em lote pelo agendado) não se repete no desenho novo: o Flow novo grava 1 conta por salvamento. Ver caso Q2 e a FALHA 1 abaixo.

## Falhas

### FALHA 1 (média) — `ScheduledFlowOpportunity` continua ativo na QA, com execução agendada
- **Reproduzir:** `SELECT Definition.DeveloperName, VersionNumber, Status FROM Flow WHERE Definition.DeveloperName='ScheduledFlowOpportunity'` (Tooling) e `CronTrigger` `ScheduledFlowOpportunity-7`.
- **Obtido:** v7 `Active` (v1 a v6 Obsoleta); `CronTrigger` `ScheduledFlowOpportunity-7` em `WAITING`, próxima execução 2026-11-17T18:47Z.
- **Esperado:** caso Q8 do design e PA14: o agendado desativado na QA depois do deploy, para não coexistir com o Flow novo. O plano de build deixou a desativação como "passo separado, pendente".
- **Impacto:** o agendado antigo é o que, na rodada 3, falhou com "Too many queueable jobs added to the queue: 51" em 162 contas e gerou 162 logs de erro. Segue ativo e rodará no dia configurado (14), reproduzindo o defeito e disputando a mesma conta com o Flow novo. Não executei nem desativei (não implanto; DML meu não é permitido).
- **Correção:** incluir no pacote a desativação (versão ativa 0 ou equivalente que o builder confirmar) e reenviar à QA, ou registrar a decisão do arquiteto de mantê-lo ativo até a EPLAST-48.

## Casos (dados sintéticos "TESTE EPLAST-47", 14 contas e 16 oportunidades; Flow exercitado: `Opportunity_AfterSave_ClassificaConta` v1)

Cada oportunidade foi salva para `Fechado/Ganho` numa execução de Apex anônimo própria (uma transação por conta). A média da conta veio do próprio `OpportunityFlow` (1 ganha = valor da oportunidade).

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| Q5 / C10 (12 bordas) | 10 | Ganha única com valor 10.000; 10.000,01; 35.000; 35.000,01; 80.000; 80.000,01; 160.000; 160.000,01; 500.000; 500.000,01; 1.000.000; 1.000.000,01 | MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G | SOQL em `Account`: MP, PP, PP, P, P, M, M, G, G, GG, GG, 3G, nessa ordem | passou |
| Q5 (3.000) | 10 | Ganha única 3.000 | MP | MP, `LastMonthPurchaseValue__c` 3000 | passou |
| Q1 / V1 | 4, 14 | Cada conta recebeu 1 save | 1 linha de histórico de `Ranking__c` por conta | `AccountHistory` `Field='Ranking__c'` nas contas de teste: 13 (1 por conta; 13 contas classificadas) | passou |
| Q3 | 8 | Conta 1: ganha 3.000, depois ganha 2.000 (insert), depois perdida 9.000 (insert) | Soma 5.000 | `LastMonthPurchaseValue__c` = 5000; Ranking MP | passou |
| Q4 | 9 | Conta 2 (1 ganha de 10.000) passa a `Fechado/Perdido` | Soma 0; ranking segue a média gravada | `LastMonthPurchaseValue__c` = 0; `AveragePurchasesThisYear__c` ficou vazia; Ranking manteve MP (média vazia mantém, PA3) | passou |
| Q5 média vazia | 11 | Mesma conta 2 acima | Ranking não vira GG | MP mantido | passou |
| Q5 média 0 | 11 | Média exatamente 0 | MP | Não provocado: o `OpportunityFlow` não grava 0 neste cenário. Na dev (04-verificacao) passou | não executado na QA |
| Q2 | 6 | 13 saves em transações separadas, mais saves extras | 0 `UNABLE_TO_LOCK_ROW` e 0 "Too many queueable jobs" nos logs da ação nova | `IntegrationLog__c` da ação `Opportunity_AfterSave_ClassificaConta` criados hoje: 0. Todos os logs do dia (32) são `Send Client To Protheus`, `Erro(Internal Server Error)` — vindos da trigger existente, não do Flow novo | passou |
| Q6 picklist | 13 | `describe` de `Account.Ranking__c` | MP, PP, P, M, G, GG, 3G | 7 valores ativos exatamente esses | passou |
| Q6 relatório | 14 | Analytics API de `AccountRankingChanges` com detalhe | Linhas de mudança de `Ranking__c` com anterior e novo | Filtro `field_key` = `Ranking`; 13 linhas das contas de teste, colunas anterior ("-") e novo (MP, PP, PP, P, ...) (só conferi as linhas de teste; o relatório inclui histórico de outras contas) | passou |
| V3 | — | Mudar só a data de fechamento de oportunidade ganha | Flow novo não grava a conta | Ranking e histórico inalterados (13); `LastModifiedDate` da conta mudou, mas por outra automação existente (não conclusivo sobre o Flow novo) | inconclusivo |
| Q7 / V6 | 16 | Forçar falha: esvaziei o "ID Usuário Protheus" do meu usuário (dono das contas) e salvei ganha (update e insert) | `IntegrationLog__c` da ação nova, venda salva, sem e-mail | A regra de validação `CheckAccountOwnerHasProtheusSellerId` barra a própria oportunidade ("preencha o campo ID Usuário Protheus no registro do Proprietário da Conta"), antes do Flow novo. Não há como isolar a falha do Flow novo sem alterar perfil/usuário de terceiros ou dado real. Logs da ação nova: 0 | não executado (não testável nesta sandbox sem tocar dado alheio) |
| Q8 | estado | Estado do agendado | Sem versão ativa | v7 ativa, agendado em `WAITING` | **reprovado (FALHA 1)** |
| 12, 15 | XML sem faixa antiga nem e-mail fixo | Faixas só em `RankingRange__mdt`, destinatário só em `FaultRecipient__c` (vazio) | — | Conferido só nos valores de metadado da org (faixas e `FaultRecipient__c`); XML não relido | parcial (a verificação da dev cobriu o XML) |
| 5, 7, 18 | — | Não se aplicam (design 03 seção 8) | — | — | não aplicável |

Evidência de tela: não tirei capturas (verificação feita por consulta e Analytics API; não abri registro real).

## Alterações no usuário de execução (revertidas)
- `User` `005bJ00000piKAaQAM`: `ProtheusSellerId__c` de vazio para `T47` (para criar contas e salvar oportunidades); esvaziado de propósito durante o caso V6; **ao final devolvido a vazio e conferido por SOQL (nulo)**. Sem mudança de perfil, permission set ou papel. O usuário de teste da conta de serviço (Id `005bJ00000piKAaQAM`) é o mesmo do job; o outro usuário (Id `005bJ00000hBJmYQAW`) está inativo e não foi tocado.

## O que pode ter saído da org
- Criei 14 contas, 16 oportunidades, 1 filial e 1 condição de pagamento de teste; a cadeia existente criou Casos, Pedidos e Tarefas ligados a elas (14 casos e 14 pedidos contados, tarefas conferidas). **Tudo apagado** (contas, oportunidades, filial, condição, casos, pedidos, tarefas), contagem final 0 de cada.
- `IntegrationLog__c` do dia: 32, todos `Send Client To Protheus` com `Erro(Internal Server Error)`: o Protheus não aceitou nada. Sem e-mail (destinatário vazio) e nada no Marketing Cloud.
- Fixture: montei variação da `fixtures/eplast47-base.apex` em arquivo temporário (várias contas com média sintética); a base não foi alterada.

## Motivo do veredito
Os critérios de classificação (10, 11, 13, 14), soma (8, 9) e ausência de erro de limite (6) passaram na QA com evidência. Reprovado por FALHA 1: o agendado antigo segue ativo (Q8) e o caso 16 (falha forçada) não pôde ser provado aqui. Se o time decidir que o agendado fica ativo até a EPLAST-48, a FALHA 1 deixa de bloquear; o critério 16 segue só provado por leitura do desenho.
