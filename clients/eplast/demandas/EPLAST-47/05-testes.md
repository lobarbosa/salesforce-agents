**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org ID `00DHa000006vZtmMAE`)

# EPLAST-47 — Testes na QA (rodada 6: classificar a conta ao salvar a oportunidade)

`sf org list`: só `sbx-eplast-qa` (Connected). Todo comando com `--target-org` explícito. Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EJ46HKAT`, Succeeded, commit `4d7281e8`, 2026-11-17T09:05Z).

Rodada 6 reteste a FALHA 1 da rodada 5 (agendado ativo na QA) e 3 bordas da classificação, como pede a última seção de `03-design.md`. O restante vale pela rodada 4 (ver tabela).

## Falhas
Nenhuma nesta rodada.

**Reteste da rodada anterior:** FALHA 1 da rodada 5 (`ScheduledFlowOpportunity` ativo e armado na QA): **corrigida**. A versão 8 aparece `Obsolete` (alterada pelo deploy de 09:05Z), sem versão ativa e sem agendamento pendente (Q8 abaixo).

## Conferência do pacote
- `Opportunity_AfterSave_ClassificaConta`: v3 `Active` (v1 e v2 `Obsolete`); `FlowDefinitionView.ActiveVersionId` = `LatestVersionId` = `301Ha000016aiTBIAY`.
- `ScheduledFlowOpportunity` existe (v7 e v8 `Obsolete` no filtro consultado) e não foi apagado.
- Faixas, picklist e relatório: conferidos na rodada 4 sobre o mesmo metadado; o deploy desta rodada os reenviou sem mudança de conteúdo declarada.

## Casos
| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| Q8 | estado / PA14 | `FlowDefinitionView` para `ScheduledFlowOpportunity`; `COUNT` de `Flow` (Tooling) com `Status='Active'`; `COUNT` de `CronTrigger` com nome `ScheduledFlowOpportunity%` | Sem versão ativa, sem agendamento | `ActiveVersionId` = null; 0 versões `Active`; 0 `CronTrigger` | passou |
| Borda MP | 10 | Conta de teste, 1 ganha de 10.000 (com cotação aprovada sintética, fixture `eplast47-cotacao.apex`), salva em execução própria | Ranking MP | `Ranking__c` = MP, soma 10000, média 10000 | passou |
| Borda P | 10 | 1 ganha de 35.000,01 | Ranking P (acima do teto de PP) | `Ranking__c` = P, soma 35000.01 | passou |
| Borda 3G | 10 | 1 ganha de 1.000.000,01 | Ranking 3G (acima de GG) | `Ranking__c` = 3G, soma 1000000.01 | passou |
| Histórico | 4, 14 | `AccountHistory` de `Ranking__c` nas 3 contas | 1 linha por conta | 3 | passou |
| Erro do Flow novo | 6 | `IntegrationLog__c` do dia com a ação `ClassificaConta` | 0 | 0 | passou |
| Q1, Q2, Q3, Q4, Q5 (12 bordas), Q6 | 4, 6, 8, 9, 10, 11, 13, 14 | — | — | Evidência da rodada 4 (`05-testes-rodada-4.md`): todos passaram. Herdado, não reexecutado (a versão ativa do Flow é agora a v3; reconfirmei só 3 bordas, pedido do design) | herdado |
| Q7 / critério 16 (falha forçada) | 16 | — | Log da ação nova, venda salva | Não exercitável na QA: a regra `CheckAccountOwnerHasProtheusSellerId` barra a oportunidade antes do Flow novo (decisão 2 do design). Provado só por leitura do Flow. Segue para a homologação, sem reprovar (decisão do responsável, 17/11) | não executado (validar na homologação) |
| 5, 7, 18 | — | Não se aplicam (design, seção 8 e PA5) | — | — | não aplicável |

Observação de dado de teste: na primeira tentativa, as ganhas sem cotação aprovada gravaram a soma mas deixaram a média vazia e a classificação em branco (comportamento previsto: PA12, média vazia mantém a classificação). Com a cotação sintética, a média foi calculada e a classificação veio correta. Não é falha.

Evidência de tela: nenhuma captura; a verificação foi por consulta.

## Alterações no usuário de execução (revertidas)
- `User` `005bJ00000piKAaQAM` (meu usuário de execução, conta de serviço do projeto): `ProtheusSellerId__c` de vazio para `T47`; ao final devolvido a vazio (conferido por SOQL: nulo). Sem mudança de perfil, permission set ou papel. O usuário inativo `005bJ00000hBJmYQAW` não foi tocado.

## O que pode ter saído da org
- Criei 3 contas, 3 oportunidades, 3 cotações (`Quote`) e 3 cotações CPQ, 1 filial e 1 condição de pagamento, todas "TESTE EPLAST-47"; a cadeia existente criou 3 casos, 3 pedidos e 3 tarefas. **Tudo apagado**; contagem final 0 de oportunidades, contas, filiais, condições e cotações de teste. As contas foram criadas com o desvio da trigger (`bypassTrigger`), então nenhuma foi enviada ao Protheus nem consultou a BrasilAPI.
- Sem e-mail (destinatário de falha vazio) e nada no Marketing Cloud. Chamadas ao Protheus pela cadeia existente: não verifiquei o resultado nesta rodada (nenhuma conta passou pela trigger).
- Usei duplicate rule override (`allowSave`) só ao inserir as contas de teste.

## Motivo do veredito
A única falha aberta (agendado antigo ativo) foi corrigida e comprovada por consulta; as 3 bordas reexecutadas classificam certo e gravam 1 linha de histórico por conta. Os demais critérios passaram na rodada 4. O critério 16 (falha forçada) não é exercitável na QA e vai para a homologação por decisão do responsável.
