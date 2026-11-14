**Resultado do build:** concluído

# EPLAST-47 — Plano de build

**Branch:** `feature/EPLAST-47` · **Sandbox:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`, `sf org list` mostrou só ela, conectada). Nada foi feito em QA nem em produção.
**Base:** `03-design.md` aprovado em `gates.md` (Leonardo Barbosa, 2026-11-14, commit `b0318c43`). D1, D2 e D3 aceitas no card (19:11). Sem Apex, sem mudança de perfil ou permission set.
**Sobre a tentativa anterior:** o plano antigo (build não executado, escritor concorrente) foi substituído. Nesta sessão não havia outro processo `sf` ou deploy em andamento. As edições que ela deixou foram commitadas em `b0318c43`; conferi que não há `<description>` nem `<trackHistory>` duplicados nos dois campos de Account.

## O que foi construído (todos com descrição preenchida)

| Componente | API name | Estado na dev |
|---|---|---|
| Custom metadata type (D1) | `RankingRange__mdt` (`Ranking__c`, `UpperLimit__c`, `SortOrder__c`) | Existe. 7 registros conferidos por query: MP 10.000, PP 35.000, P 80.000, M 160.000, G 500.000, GG 1.000.000, X3G (valor `3G`, sem teto), `SortOrder__c` 1 a 7 |
| Custom metadata type (D1) | `ScheduledFlowOpportunitySetting__mdt` (`RunDayOfMonth__c`, `FaultRecipient__c`) | Existe. Registro `Default` com dia 14 e destinatário vazio |
| Campo | `Account.Ranking__c` | Picklist restrita ativa = MP, PP, P, M, G, GG, 3G (describe). Histórico de campo ativo (`IsFieldHistoryTracked = true`; é o único campo de Account com histórico) e `enableHistory` do objeto ligado (D2) |
| Campo | `Account.LastMonthPurchaseValue__c` | Só descrição (soma das ganhas do ano; rótulo mantido, P4) |
| Flow (v2, ativa) | `ScheduledFlowOpportunity` | Versão 1 Obsolete, versão 2 Active (query de Flow). Mesmo API name, mesmo agendamento (Daily 15:47 UTC), mesma população (`IsWon = true`) |
| Relatório (D2) | `EPLAST47/AccountRankingChanges` ("Mudancas de Classificacao de Contas") sobre o tipo `AccountAuditHistory` | Criado na pasta provisória `EPLAST47` (acesso Hidden). Colunas: conta, data, campo, valor anterior, valor novo |

Commits desta etapa: `b0318c43` (modelo de dados, anterior) e o commit desta sessão (Flow v2, relatório e este plano; hash no `git log` da branch).

### Flow v2: o que mudou em relação à v1
- Novos: `GetSetting` (mdt), `CheckAccount`, `GetRepresentativeOpportunity` (primeiro Id ganho da conta) + `IsRepresentative`, `ClassifyRanking`, `GetRanges` (ordem `SortOrder__c`) + `LoopRanges` + `RangeMatches` (condição `1 AND (2 OR 3)`: sem faixa ainda e (limite vazio ou média ≤ limite)), `HasChanges`, `UpdateAccount` (1 update), `LogFault` (`IntegrationLog__c`, `IntegrationAction__c = ScheduledFlowOpportunity`, `ResponseStatus__c = Erro`), `HasRecipient`, `SendFaultEmail`.
- Alterado: `CheckDayMonth` compara com `GetSetting.RunDayOfMonth__c` (era 14 fixo; descrição corrigida, dizia "dia 1º").
- Mantidos sem mudar filtro: `GetOpportunities` (AccountId, `Fechado/Ganho`, `ThisYear__c`), `LoopOpportunities`, `AssignSumValue`, `SumAmount`.
- Removidos: `GetOpportunities2` (lia todas as oportunidades `LastMonth__c` da org), `QuantityOpportunities`, variável `Count`, `LastMonthPurchaseValue`, `ValuePurchasesLastMonth` e os 5 updates `UpdateAccountPP/P/UpdatAccountM/UpdateAccountG/UpdateAccountGG`.
- Média vazia: `KeepCurrentRanking` (não altera `Ranking__c`). Média 0 cai em MP. Sem limite fixo no XML (70.000 e 150.000 saíram).
- Validação: `deploy --dry-run` do Flow passou, depois deploy real. Ordenação por `Id` no Get Records foi aceita (R7 não se materializou).

## Confirmado via `sf` nesta sessão
`sf org list`; query dos 7 registros e do registro `Default`; versões do Flow (1 Obsolete, 2 Active); describe de `Account.Ranking__c`; `FieldDefinition` (histórico só em `Ranking__c`); describe de `IntegrationLog__c` (4 campos usados existem, nenhum obrigatório); lista de tipos de relatório (`AccountAuditHistory` existe, `AccountHistory` não).

**R8 conferido:** `Logs_Delete_Records` (ativo, Daily 02:00 UTC) apaga `IntegrationLog__c` com `CreatedDate` anterior a 30 dias (`$Flow.CurrentDate - 30`). O log de falha do `ScheduledFlowOpportunity` some em 30 dias. O mês tem execução uma vez só, então o log da falha do dia 14 vive até ~dia 14 do mês seguinte. Se a Eplast quiser reter mais, é decisão dela (não alterei esse fluxo).

## O que ficou de fora e por quê
- **Não testei o comportamento do Flow na dev.** A dev tem 0 contas e 0 oportunidades; só validei que o metadata é aceito e que a versão 2 está ativa. Nenhuma faixa, update ou log foi exercitado. Cabe ao QA.
- **Dado sintético, DML e Debug do Flow:** não criei dados (R5: dispara a cadeia Order/Quote/CPQ).
- **Agendamento ativo do job (`CronTrigger`):** a consulta não é suportada nesta org via API; não confirmei se o job está agendado. Não medido.
- **Comparação do Flow da QA com a v1 da dev** (incerteza do design): não feita. Build só toca a dev; retrieve na QA ficou para o QA/release.
- Período configurável (D3), `OpportunityFlow`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, triggers, Protheus (P8), Marketing Cloud: fora do escopo, intocados.
- Não abri PR (não foi pedido). Não escrevi `gates.md` nem `status.yaml`. Há uma alteração staged em `src/salesforce_agents/orchestrator.py` que não é desta sessão; ficou fora do meu commit.

## Pendências de negócio (não bloqueiam o build; vêm do design)
- **P5** (alerta operacional x marketing): o `SendFaultEmail` está construído, mas **dormente** (destinatário vazio, só o log funciona). É aviso técnico de job a um operador, não campanha (regra 2 da conta). Se a Eplast classificar como marketing, remover `SendFaultEmail` e `HasRecipient`; o disparo vira passo de quem opera o Marketing Cloud lendo os `IntegrationLog__c`. Trava a promoção a QAS.
- **P11:** endereço do destinatário em `FaultRecipient__c` (registro `Default`).
- **P12:** pasta definitiva do relatório (hoje `EPLAST47`, provisória, Hidden) e se já existe relatório equivalente. Conteúdo dos 379 relatórios da org não foi lido.
- **P6** (média vazia / conta sem compra) e a troca em massa GG para MP da seção 1.2 do design: avisar a Eplast antes da homologação.
- P1, P8, P10: como no design.

## Para o QA (sbx-eplast-qa; pré-checar Org ID diferente de `00DHa000006vfMLMAY`)
Roteiro do design, seção 8, com estes pontos específicos da implementação:
1. **Nulos em `HasChanges`:** compara `SumAmount` e `NewRanking` com `NotEqualTo` contra os valores da conta. Verificar com `SumAmount` nulo (conta sem ganha do ano, mas com ganha em outro ano) e com `LastMonthPurchaseValue__c` vazio: se grava, não grava, ou grava vazio/zero (caso 5). Caso 24 (sem mudança, sem update) depende disso.
2. **Fronteiras das faixas** (casos 6 a 17) e média 0 e vazia (caso 18). `RangeMatches` testa por `SortOrder__c`; 3G é só o registro sem `UpperLimit__c`.
3. **`SendFaultEmail`:** o flow roda como Automated Process e não defini remetente (`senderType` padrão). Caso 23 pode falhar por remetente ou por "só e-mail do sistema" na sandbox. Se falhar, o log já foi criado antes do e-mail, mas a interview termina em erro.
4. **`ResponseBody__c` do log** leva o Id da conta e `$Flow.FaultMessage` (fórmula `FaultBody`). Conferir que a mensagem não vaza dado de cliente (ex.: valor de campo na mensagem de validation rule).
5. **Relatório:** o tipo é `AccountAuditHistory`; sem filtro por campo, porque o valor de filtro de `field_key` não pôde ser verificado (sem linhas de histórico na dev). Hoje só `Ranking__c` tem histórico em Account. Conferir no caso 21 que mostra anterior e novo.
6. **Ordem de deploy (R3):** picklist e histórico, depois custom metadata e registros, depois Flow, depois relatório. Na QA, a pasta `EPLAST47` vem junto.
7. **Riscos abertos:** R1 (ordem entre `AccountBefore` e `AccountTrigger`, 2 flows after-save sem critério de entrada), R2 (troca em massa na primeira execução), R5 (dado sintético dispara Order/Quote/CPQ/Protheus: conferir endpoint na QA antes), R9 (validation rules em contas legadas passam a gerar log).
8. **Rollback:** reativar a v1 do `ScheduledFlowOpportunity`; não desativar o histórico de campo.
