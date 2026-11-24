**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-47 — Testes (rodada 1)

## Org
`sf org list` mostrou só `sbx-eplast-qa` (Sandbox, conectada), Org ID `00DHa000006vZtmMAE`, instância `eplast--qas.sandbox.my.salesforce.com`. É diferente da dev (`00DHa000006vfMLMAY`), então é a QA de fato. A dúvida dev x qa do assessment ficou resolvida para esta demanda. Nenhum DML nem deploy foi feito.

## Falhas

### FALHA 1 (crítica) — O build da EPLAST-47 não está na sandbox de QA; nenhum critério de aceite é testável
- **Reproduzir:** consultar a QA com `sf` (contagens e metadata, sem dado pessoal).
- **Obtido:**
  - `Flow` `ScheduledFlowOpportunity`: só a versão 1, Active. A v2 não existe.
  - `Account.Ranking__c` ativo: PP, P, M, G, GG (5 valores). Faltam MP e 3G.
  - `RankingRange__mdt`: "sObject type not supported" (tipo inexistente).
  - `ScheduledFlowOpportunitySetting__mdt` em `EntityDefinition`: 0 registros (tipo inexistente).
  - Relatório `AccountRankingChanges`: não pôde ser confirmado (a consulta de `Report` via Tooling não é suportada). Sem o resto do pacote, ele não foi tratado como presente.
- **Esperado:** o build (Flow v2, picklist de 7 valores, 2 custom metadata types e seus registros, histórico de campo, relatório) implantado na QA antes do teste. O plano de build (`04-plano-build.md`) diz que tudo foi feito só na dev e que o retrieve e o deploy na QA ficam para o release/QA.
- **Causa provável:** falta o deploy dev para QA, na ordem do R3 do design (picklist e histórico, depois custom metadata e registros, depois Flow, depois relatório). Eu não faço deploy; isso é do `release` ou de quem a esteira designar. Com a v1 ativa na QA, qualquer execução testaria o comportamento antigo, o que não prova nada sobre o aceite.
- **Ação para o próximo build:** implantar o pacote na QA e conferir os 7 valores, os 7 registros de faixa, o registro `Default` e a v2 Active. Depois devolver para QA.

### FALHA 2 (média) — Pré-requisitos de dado de teste e de risco R5 não resolvidos
- **Obtido:** a QA tem 1.217 contas e 7.454 oportunidades ganhas (contagens), ou seja, dado real de cliente. O dia de execução do Flow é mudado em `RunDayOfMonth__c`, e o job diário processaria todas essas contas. Criar oportunidade ganha sintética dispara `OpportunityFlow` (Order, Quote, CPQ, aprovação; R5 do design).
- **Esperado:** antes do teste, confirmar para onde aponta a integração Protheus na QA (só metadata). Definir com o humano como isolar o teste, porque o Flow v2 atualizaria `Ranking__c` em massa nas contas reais da QA (R2: troca em massa de GG para MP). Também falta o número do teste de volume (P10).
- **Não executado:** a conferência do endpoint Protheus não foi feita, porque o deploy não existe.

## Casos (derivados de `01-analise.md`, seção 4)

| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1-3 | H1: análise de impacto | Conferir `02-recon.md` / design | Tabela de campos, 4 pontos marcados, lista 5 x 7 | Documental, fora do escopo de execução na QA | Não executado |
| 4 | H2: 1 update por conta | Rodar o Flow com 3 ganhas na conta A e 1 na B | A=1 update, B=1 | Flow v2 ausente na QA | Não executado |
| 5 | H2: sem consulta sem filtro | XML/debug | Nenhuma consulta sem `AccountId` | A QA tem a v1 (a órfã `GetOpportunities2` ainda existe) | Não executado |
| 6 | H2: 50 contas sem `UNABLE_TO_LOCK_ROW` | Lote de 50 | 0 erros | Sem v2; sem dado de teste isolado | Não executado |
| 7-9 | H3: cálculo, período, conta sem compra | Cenários do design | 5.000 (perdida fora); zero/vazio por configuração | Sem v2 | Não executado |
| 10-12 | H4: fronteiras e zero/vazio | 12 valores de borda | MP/PP/PP/P/P/M/M/G/G/GG/GG/3G | Sem v2 nem `RankingRange__mdt` | Não executado |
| 13 | H4: picklist `Ranking__c` | `sobject describe` na QA | MP, PP, P, M, G, GG, 3G | PP, P, M, G, GG | **Reprovado** |
| 14 | H4: relatório de mudanças | Alterar N classificações | N linhas, anterior e novo | Sem v2; relatório não confirmado | Não executado |
| 15 | H5: sem e-mail do ex-parceiro | XML do Flow | Nenhum | A QA tem a v1 (sem e-mail, segundo a análise); v2 ausente | Não executado |
| 16 | H5: falha com destinatário | Falha forçada | Aviso ao destinatário; sem destinatário, só log | Sem v2 | Não executado |
| 17-18 | H6: 15 cenários e volume | Execução na QA | Evidência por cenário; P10 | Dependem da FALHA 1; P10 sem número | Não executado |

Resumo: 1 caso reprovado (13), 0 aprovados. Os demais critérios principais (H2, H3, H4, H5) não foram executados porque o build não está na QA. Por isso o veredito é reprovado.

## Limitações
- Não fiz screenshot nem abri a UI: sem o build implantado, não há o que ver, e a QA só tem dado real de cliente.
- O comportamento do Flow v2 nunca foi exercitado em nenhuma org (a dev tem 0 contas), então todo o aceite depende de uma nova rodada.
- Não confirmei o job agendado (`CronTrigger` não é suportado via API, como já registrado no build).

Testes executados. Preciso da sua homologação para liberar o release.
