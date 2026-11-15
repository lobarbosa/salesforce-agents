**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-47 — Testes (rodada 2)

## Org
`sf org list`: só `sbx-eplast-qa` (Sandbox, Connected, Org ID `00DHa000006vZtmMAE`). É a QA. Nenhum deploy feito por mim. Nenhum DML nesta rodada: nenhum registro criado ou alterado, nada saiu da org.

## Retorno da rodada 1
- FALHA 1 (build ausente na QA): **corrigida.** O deploy `0AfHa00000EHrCjKAL` (Succeeded) está na org: Flow v2 Active, 7 faixas, picklist de 7 valores, Setting `Default`, relatório e histórico de campo (casos 1 a 7 abaixo).
- FALHA 2 (dado de teste e risco Protheus): **autorização dada** (card, 15/11 00:59 e 01:13), mas a execução continua impossível, ver FALHA 1 desta rodada.

## Falhas

### FALHA 1 (crítica) — Comportamento do Flow não exercitado; critérios de aceite principais sem evidência
- **Reproduzir:** tentar provar os critérios 4, 6, 8, 9, 10, 11, 14 e 16 na QA.
- **Obtido:** não foi possível executar o Flow. (a) O Flow é agendado (Daily 15:47Z) com gate no dia `RunDayOfMonth__c` = 14. A sessão rodou às 01:16Z de 15/11; a próxima execução só ocorre às 15:47Z, depois do fim da sessão, e fluxo agendado não pode ser disparado manualmente por API/Apex. Mudar o dia para 15 e deixar rodar sem observar não poderia ser desfeito dentro da sessão, então não alterei. (b) Criar oportunidade ganha sintética é bloqueado pelas validation rules de Opportunity (Filial com Código ERP, condição de pagamento, catálogo, fases financeira/fiscal, conta com endereço/CNAE/contato, proprietário com ID Usuário Protheus), como já registrado em `04-verificacao.md` na dev. Satisfazê-las exige criar cadeia CPQ/Protheus ou ler/alterar registros reais; não fiz.
- **Esperado:** por `01-analise.md` seção 4, evidência (entrada, saída esperada, saída obtida) para cada cenário de borda e para "1 atualização por conta".
- **Causa provável:** falta de base sintética mínima na QA (Filial, condição de pagamento, catálogo, fases) ou de um mecanismo autorizado de teste. Alternativas para o próximo build: (1) o construtor/verificador montar essa base sintética e uma oportunidade ganha de teste em dia coincidente; (2) o responsável decidir deixar o job rodar às 15:47Z em dia coincidente (autorização do 01:13) e o QA conferir só por contagens agregadas na rodada seguinte, incluindo `AccountHistory`.
- Observação de risco para quem executar: `AccountHistory` está em 0 e 851 das 1.217 contas estão sem classificação; um job real reclassificará em massa (R2 do design) e pode sincronizar com o Protheus.

## Casos

| Caso | Critério | Passos / comando | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Deploy | `SELECT VersionNumber,Status FROM Flow WHERE Definition.DeveloperName='ScheduledFlowOpportunity'` (Tooling) | v2 Active, v1 Obsolete | v1 Obsolete, v2 Active (`301Ha000016SIFXIA4`, criada 01:15Z) | passou |
| 2 | 13 | `sobject describe Account`, `Ranking__c` | Ativos exatamente MP, PP, P, M, G, GG, 3G | `['MP','PP','P','M','G','GG','3G']`, restrita | passou |
| 3 | 10, 12 (dado das faixas) | `SELECT Ranking__c,UpperLimit__c,SortOrder__c FROM RankingRange__mdt ORDER BY SortOrder__c` | 7 faixas 10.000/35.000/80.000/160.000/500.000/1.000.000/sem teto | MP 10000, PP 35000, P 80000, M 160000, G 500000, GG 1000000, 3G nulo; ordem 1 a 7 | passou (só configuração) |
| 4 | 12 | Tooling `Flow.Metadata` da v2, busca de `numberValue` | Nenhum limite fixo no Flow | Nenhum `numberValue` preenchido | passou |
| 5 | 5 | Mesma Metadata, `recordLookups` de Opportunity | Todas filtram `AccountId` | `GetOpportunities` (AccountId, Fechado/Ganho, ThisYear__c) e `GetRepresentativeOpportunity` (AccountId, IsWon). `GetOpportunities2` não existe. Lookups de `RankingRange__mdt` e Setting são metadata | passou |
| 6 | 15 | Busca de `@` e de "levora" em toda a Metadata; `actionCalls` | Sem endereço do ex-parceiro | Nenhuma ocorrência; único e-mail `SendFaultEmail` (emailSimple) com destinatário vindo do Setting | passou |
| 7 | 16 (configuração) | `SELECT DeveloperName,RunDayOfMonth__c,FaultRecipient__c FROM ScheduledFlowOpportunitySetting__mdt` | `Default`, dia 14, destinatário vazio | `Default`, 14, nulo | passou (configuração) |
| 8 | 14 (existência) | `SELECT DeveloperName,FolderName FROM Report WHERE DeveloperName='AccountRankingChanges'` | Relatório existe | Existe, pasta "EPLAST-47 Relatorios (provisorio, P12)" | passou (conteúdo não exercitado) |
| 9 | D2 | `FieldDefinition` de Account com `IsFieldHistoryTracked=true` | Só `Ranking__c` | `Ranking__c` true | passou |
| 10 | 4 | 3 ganhas conta A, 1 conta B, rodar o Flow | 1 atualização por conta | Não executado (ver FALHA 1) | não executado |
| 11 | 6 | 50 contas, contar `UNABLE_TO_LOCK_ROW` | 0 | Não executado | não executado |
| 12 | 8, 9 | Ganhas 3.000+2.000 e perdida 9.000; conta sem ganha | 5.000; valor configurado | Não executado | não executado |
| 13 | 10, 11 | Fronteiras 10.000 a 1.000.000,01, zero, vazio | MP/PP/PP/P/P/M/M/G/G/GG/GG/3G; sem cair em GG | Não executado | não executado |
| 14 | 14 | Execução que muda N contas | Relatório mostra N, anterior e nova | Não executado (`AccountHistory` = 0) | não executado |
| 15 | 16 | Falha forçada | `IntegrationLog__c` com erro; e-mail só com destinatário | Não executado | não executado |
| 16 | 17, 18 | Volume | Número de P10 | Sem número de volume (P10 aberto) | não executado |
| 17 | 7 | Período configurável | Fora de escopo (D3) | n/a | n/a |
| 18 | 1 a 3 | Documentação (H1) | Em `02-recon.md`/design | Não reavaliado nesta rodada | não executado |

## O que pode ter saído da org
Nada. Nesta rodada só executei leituras (Tooling, contagens e metadata). Nenhum registro criado, nenhuma execução do Flow, nenhuma chamada ao Protheus. O dia de execução continua 14.
Contagens lidas (QA): 1.217 contas; 2.764 oportunidades ganhas do ano; `AccountHistory` 0; contas com MP ou 3G: 0.
