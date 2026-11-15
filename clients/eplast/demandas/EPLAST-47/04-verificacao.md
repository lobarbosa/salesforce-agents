**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-47 — Verificação do build

Org confirmada com `sf org list`: alias `sbx-eplast-dev`, Org ID `00DHa000006vfMLMAY`, Sandbox, conectada. Nada foi feito em QA nem em produção. Nenhum dado foi criado, alterado ou apagado na dev (nada ficou para limpar).

## Por que inconclusiva
O comportamento do Flow v2 (critérios 4, 6 a 11, 14 e 16) não foi exercitado. Não é defeito do build.
- `SELECT COUNT() FROM Account` e `FROM Opportunity` na dev devolveram 0. Não há dado para o Flow processar.
- Dado sintético exigiria criar `Opportunity` ganha. Na dev há `AccountTrigger`, `OpportunityTrigger`, `OpportunityBefore`, `OpportunityAfter` e o flow ativo `OpportunityFlow`, além de `Order`, `CPQQuoteFlow` e `QuoteLineCPQFlow`. O design (R5) e o builder dizem que essa cadeia cria Order e Quote, chama CPQ e envia aprovação, com possível ligação ao Protheus. Não consegui isolar a cadeia, então não disparei. Os casos de comportamento ficam "não executado".
- O critério 17 exige execução na QA, fora do meu escopo.

## O que uma pessoa precisa fazer para provar
1. Antes de criar dado na QA, confirmar para onde aponta a integração Protheus (só metadata). Se apontar para ERP real, parar.
2. Criar contas e oportunidades sintéticas `TESTE EPLAST-47`. Rodar o Flow no dia configurado, ou ajustar `RunDayOfMonth__c` no registro `Default`, e conferir os valores de borda do critério 10.
3. Limpar Order e Quote sintéticos ao fim.
4. Informar os números de volume (P10) para o critério 18.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | 13 | `sf sobject describe` de `Account`, valores ativos de `Ranking__c` | MP, PP, P, M, G, GG, 3G | `['MP','PP','P','M','G','GG','3G']` | passou |
| V2 | 12 | grep de 70000, 150000, 10000.0 e 500000 no XML `ScheduledFlowOpportunity.flow-meta.xml` do repo (cópia local; não conferi se é idêntica à da org) | 0 ocorrências | 0 ocorrências | passou (sobre o XML do repo) |
| V3 | 15 | grep de `@` e `.com` no mesmo XML | nenhum e-mail fixo | nenhuma ocorrência | passou (sobre o XML do repo) |
| V4 | 5 | Leitura do `GetOpportunities` no XML | filtro por `AccountId` | filtra `AccountId = $Record.AccountId`, `StageName = Fechado/Ganho`, `ThisYear__c`. O `GetRepresentativeOpportunity` também é lookup de `Opportunity`; não inspecionei o filtro dele | passou parcialmente (XML) |
| V5 | 4 | Não executado | Conta A atualizada 1 vez, B 1 vez | A dev não tem dado e a cadeia dispara CPQ/Protheus | não executado |
| V6 | 6 | Não executado | 0 `UNABLE_TO_LOCK_ROW` com 50 contas | idem; também é um caso de QA | não executado |
| V7 | 7 | Não executado | Mudar o período muda o valor | D3 fora do escopo do build segundo o plano | não executado |
| V8 | 8, 9 | Não executado | Perdida não entra. Sem ganha usa o valor configurado | sem dado | não executado |
| V9 | 10, 11 | Não executado | Faixas e bordas conforme a tabela | Sem dado. Só confirmei que o plano registra 7 faixas no `RankingRange__mdt`; não reconsultei | não executado |
| V10 | 14 | Não executado | Relatório mostra N mudanças | Sem execução do Flow. O plano diz que o relatório foi criado, e eu não o consultei | não executado |
| V11 | 16 | Não executado | Falha envia aviso, ou registra se não houver destinatário | Falha não forçada | não executado |
| V12 | 1, 2, 3 | Critérios de documentação, não de build | n/a | n/a | fora do escopo desta verificação |
| V13 | 17, 18 | Execução na QA e números de volume (P10) | n/a | n/a | não executado |

## Observações
- Nenhuma falha foi encontrada nos casos executados, mas eles são só checagens estáticas.
- O plano do builder diz que o job agendado (`CronTrigger`) não pôde ser confirmado. Também não medi isso.
