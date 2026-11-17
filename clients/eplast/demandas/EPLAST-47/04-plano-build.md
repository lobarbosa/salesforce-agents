**Resultado do build:** concluído

# EPLAST-47 — Plano de build (rodada 3: classificar a conta ao salvar a oportunidade)

**Org de teste:** `sbx-eplast-dev` (sandbox, Org ID `00DHa000006vfMLMAY`, a "QA" da Eplast, `eplast--qa`, regra 5 da conta). `sf org list` mostrou só ela, conectada. Nada foi feito na QA nem em produção, e nada no Marketing Cloud.
**Branch:** `feature/EPLAST-47`. **Commit:** ver o último commit da branch (`EPLAST-47: construir Flow de classificacao por oportunidade`).
**Base:** `03-design.md` (rodada 3), aceite em `gates.md` (Leonardo Barbosa, 2026-11-17, commit `7bc549de`). Substitui o plano da rodada 2 (objeto `AccountRanking__c`, não construído). Sem Apex, sem campo, objeto ou permission set novo.

## O que foi criado ou alterado (todos com descrição)

| Componente | API name | Ação | Estado na dev |
|---|---|---|---|
| Flow disparado por registro | `Opportunity_AfterSave_ClassificaConta` | **Criado** | Active, API 68.0, `RecordAfterSave`, `CreateAndUpdate`, `triggerOrder` 1500 (conferido em `FlowDefinitionView`). Arquivo `force-app/main/default/flows/Opportunity_AfterSave_ClassificaConta.flow-meta.xml` |
| Campo de metadado | `ScheduledFlowOpportunitySetting__mdt.RunDayOfMonth__c` | **Só a descrição** ("Sem uso desde a EPLAST-47...") | Deploy ok |
| Relatório | `EPLAST47/AccountRankingChanges` | **Filtro novo**: `field_key` igual a `Ranking__c` | Deploy ok. Ver "Ficou para a verificação" |

Lógica do Flow como no design 1.2: `GetAccount` (consulta explícita, lê a média já gravada pelo `OpportunityFlow`), `GetSetting`, `GetOpportunities` (ganhas, `ThisYear__c`), laço de soma, `ClassifyRanking` (média vazia mantém), `GetRanges`/`LoopRanges`/`RangeMatches` (faixa de `RankingRange__mdt` por `SortOrder__c`), `HasChanges` (só grava se mudou), `UpdateAccount` (só `Ranking__c` e `LastMonthPurchaseValue__c`) e fault para `LogFault` (`IntegrationLog__c`, ação `Opportunity_AfterSave_ClassificaConta`), `HasRecipient`, `SendFaultEmail`. A condição de entrada é a fórmula da seção 1.3, sem alteração; o deploy aceitou `ISNEW()` e `PRIORVALUE`, então o plano B do design não foi usado.

Ajustes de construção em relação ao design (sem mudar a lógica):
- `GetAccount` e `GetOpportunities` usam `storeOutputAutomatically` (o deploy recusa referenciar campo de lookup com `queriedFields`). Na prática o Get lê todos os campos, mas só os 3 de Account e `Amount` são usados.
- `SumAmount` nasceu como variável interna com valor inicial 0 (na v2 era entrada/saída sem padrão), para a conta sem ganha gravar 0 (PA3).
- `GetOpportunities` sem ordenação (a soma não depende dela).

## Reaproveitado (sem tocar)

`RankingRange__mdt` (7 faixas), `ScheduledFlowOpportunitySetting__mdt.Default` (`FaultRecipient__c` vazio), `Account.Ranking__c`, `Account.LastMonthPurchaseValue__c`, `Account.AveragePurchasesThisYear__c` (só leitura), `Opportunity.ThisYear__c`, `IntegrationLog__c`, relatório `CLASSIFICAÇÃO - CONTAS POR CLASSE`, permission set `Protheus`. Campos conferidos por `describe` na dev hoje (Ranking picklist, 2 moedas, `ThisYear__c` boolean não editável, 4 campos de `IntegrationLog__c`). **Não tocados:** `OpportunityFlow`, `AccountTriggered`, `UpdateParentAccountUsedLimit`, `AccountTrigger`, `AccountTriggerHelper`, `TriggerUtility__mdt`, `OpportunityTrigger`, classes Protheus.

## Versões e ativação

| Componente | Ação | Estado | Como desfazer |
|---|---|---|---|
| `Opportunity_AfterSave_ClassificaConta` | Flow novo, nasce Active na dev (não substitui nada) | Feito | Desativar o Flow |
| `AccountRankingChanges` | Filtro novo | Feito | Tirar o filtro |
| `RunDayOfMonth__c` | Descrição | Feito | Voltar a descrição anterior |
| `ScheduledFlowOpportunity` | **Desativado na rodada 5 (ver "Correções da rodada 4")**. Texto original: desativar em passo separado, NÃO feito no build 3. v2 segue Active na dev (`FlowDefinitionView`, hoje). Deve ser desativado depois de o verificador provar V1 a V6; na QA, pelo pacote da esteira (`FlowDefinition` com versão ativa 0 ou equivalente) | Feito (dev) | Reativar a versão anterior |

Enquanto o agendado segue ativo, os dois coexistem na dev. Risco R7 do design: o agendado só age no dia 14 (próximo, 14/12).

## Premissas assumidas usadas (design, seção 10)

PA1 a PA14 do `03-design.md` valem sem alteração. Nenhuma é caso 3, nenhuma pergunta bloqueia. As que moldam o Flow: PA3 (soma 0; média vazia mantém; média 0 vira MP), PA6 (destinatário vazio = só log; evidência: `FaultRecipient__c` vazio na dev), PA8 (só a conta nova se a oportunidade troca de conta), PA9 (exclusão não recalcula), PA11 (ano anterior não dispara), PA12 (classifica pelo campo de média como gravado), PA13 (falha não barra a venda).

## Ficou para a verificação (nada disso foi exercitado no build, só deploy)

- V1 a V7 do design, na dev, com fixture de `fixtures/` (dado com "TESTE EPLAST-47", conta com `TriggerUtility.bypassTrigger`, oportunidade salva sem o desvio).
- **V2 é a prova que decide o design (R1):** no debug log, `Opportunity_AfterSave_ClassificaConta` depois de `OpportunityFlow`, e `GetAccount` com a média já recalculada. Reprovação aqui devolve o design.
- **Filtro do relatório `AccountRankingChanges`:** o valor `Ranking__c` foi aceito pelo deploy e o relatório roda (0 linhas), mas `AccountHistory` está vazio na dev, então não foi possível provar que o valor casa com as linhas de `Ranking__c`. Depois do primeiro registro de histórico (V1), rodar o relatório pela Analytics API (só contagem) e, se vier 0, trocar o valor pelo rótulo do campo exibido na coluna "Campo".
- Contagem de jobs enfileirados, SOQL, DML e CPU do save (V2), reentrada (V4), 20 ganhas da mesma conta (V5, "Duplicate id in list" e CPU), falha forçada (V6), XML sem limites ou e-mail fixo (V7: o XML novo só lê `RankingRange__mdt` e `FaultRecipient__c`).
- Desativação do `ScheduledFlowOpportunity` depois de V1 a V6.
- Dev contém registros de CPQ, Pedido, Caso e Protheus na cadeia do save de ganha: listar o que a fixture criar (autorização de 15/11).

## Validação feita no build

- `sf project deploy start --dry-run` do Flow: Succeeded (depois de corrigir o `queriedFields`). Deploy real dos 3 componentes: Succeeded (Deploy ID `0AfHa00000EJ3OjKAL`). Nenhum teste Apex rodou (não há Apex novo).

## Correções da verificação 1

Fonte: `04-verificacao-rodada-1.md` (reprovada, 2 falhas). Deploy na `sbx-eplast-dev` (Deploy ID `0AfHa00000EJ3RxKAL`, Succeeded). Sem Apex novo, sem teste Apex.

- **FALHA 1 (faixas fora de `SortOrder__c`): corrigida no Flow, sem depender do sort do Get.** `LoopRanges` agora percorre todas as faixas e `RangeMatches` aceita a faixa só se a média couber nela (ou ela não tiver teto) **e** o `SortOrder__c` dela for menor que o da melhor já achada. Variável nova `BestSort` (Number, começa em 999) no lugar de `RangeFound`; `AssignRanking` grava `NewRanking` e `BestSort`. Resultado independe da ordem em que `RankingRange__mdt` é devolvido: vence a faixa de menor `SortOrder__c` que contém a média (MP para 3.000, 5.000, 3.333,33). O `sortField` do Get ficou (inofensivo). Média vazia mantém o ranking e média 0 cai em MP (SortOrder 1), sem mudança. **Não exercitado no build:** reexecutar V1, C10 (12 bordas) e C11 fica para o verificador.
- **FALHA 2 (filtro do relatório): corrigida.** `AccountRankingChanges`: valor do filtro `field_key` trocado de `Ranking__c` para o rótulo `Ranking`, como provado pela verificação (contagem 1 com o rótulo). Reexecutar C14.
- **V6 (falha forçada):** sem prova na dev, como a verificação registrou. Não é corrigível aqui; fica para a QA (conta com dado legado) ou outro meio de forçar a falha.

### Versões e ativação (correção)
`Opportunity_AfterSave_ClassificaConta`: criada **versão 2** pelo deploy (v1 ficou Obsoleta, conferido em `Flow` por Tooling API). Foi deployada com status Active por ser Flow desta própria demanda, ainda sem uso na QA nem em produção, e o verificador precisa dela ativa na dev. Como desfazer: reativar a v1 ou desativar o Flow. `ScheduledFlowOpportunity` segue **ativo e intocado** (desativação continua passo separado, depois de V1 a V6 provados).

## Correções da rodada 4

Fonte: `05-testes-rodada-4.md` (reprovado) e a seção "Decisão do responsável (2026-11-17)" do `03-design.md`. Org: `sbx-eplast-dev` (única do `sf org list`). Nada mais do pacote mudou (Flow novo, faixas, relatório e metadado ficam como estão).

- **FALHA 1 (agendado ativo): corrigida.** `flowDefinitions/ScheduledFlowOpportunity.flowDefinition-meta.xml` com `activeVersionNumber` 0 (o arquivo dizia 1, mas a dev estava na v2 ativa). Dry-run ok; deploy real Succeeded (ID `0AfHa00000EJ3oXKAT`). Conferido na dev: `Flow` por Tooling API v1 e v2 **Obsolete**, nenhuma Active; `CronTrigger` `ScheduledFlowOpportunity-%` com 0 linhas (o agendamento sumiu). Flow e versões não foram apagados.
- **Critério 16 (V6/Q7): não corrigível aqui, por decisão do design (2026-11-17).** Fica para a homologação; o caminho de falha está provado por leitura do Flow.
- **Q5 média 0, V3:** sem mudança, já registrados pelo QA como não exercitados/inconclusivos; não reprovam.

### Versões e ativação (rodada 4)
| Componente | Ação | Estado | Como desfazer |
|---|---|---|---|
| `ScheduledFlowOpportunity` | Desativado (versão ativa 0), sem apagar | Feito na dev; na QA, pelo deploy da esteira | Ativar a v2 (`activeVersionNumber` 2) e reagendar |

Sem prova nesta sessão: efeito na QA (o QA confere Q8 depois do deploy da esteira).
