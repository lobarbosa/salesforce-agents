**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (Org ID `00DHa000006vfMLMAY`; única org em `sf org list`, Connected; usuário de conexão omitido por conter dado pessoal)

# EPLAST-47 — Verificação do build (dev)

## Resumo
O comportamento do Flow `ScheduledFlowOpportunity` v2 **não pôde ser exercitado na dev**: o Flow só enxerga `Opportunity` com `IsWon = true`, e a dev não deixa criar uma oportunidade ganha sintética sem alterar registros que não são meus ou contornar regras da org. Os critérios de metadata e de configuração foram provados. Os de comportamento (4, 6, 8, 9, 10, 11, 14, 16) ficaram sem prova. Nenhum caso executado falhou, então não é `reprovada`.

## Por que a oportunidade ganha não foi criada
Tentei `sf data create record -s Opportunity` com `StageName='Fechado/Ganho'` ligada à conta `TESTE EPLAST-47 Conta A`. A org recusou com 12 validation rules (campos lidos da resposta de erro):
- `Branch__c` com Filial que tenha Código ERP (a dev tem 0 `Branch__c`).
- `Formas_de_Pagamento__c` e `PaymentTermId__c` (condição de pagamento).
- Conta com endereço de cobrança, CNAE, e-mail, telefone e Loja preenchidos.
- ID Usuário Protheus no proprietário da conta, que é um usuário existente que eu não posso alterar.
- Fase Análise Financeira e Fase Análise Fiscal concluídas.
- Catálogo de preço válido.

Satisfazer isso exige criar Filial, condição de pagamento, catálogo e fases (cadeia CPQ/Protheus), alterar o usuário proprietário, ou contornar as regras. Não fiz nenhum dos três. A tentativa falhou no DML, então nenhuma oportunidade, pedido ou cotação foi criado.

Também fica sem prova que o job rode hoje: o gate `CheckDayMonth` compara o dia com `Default.RunDayOfMonth__c` = 14 (hoje é dia 15), e eu não alterei essa configuração, porque não havia dado ganho para rodar.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | 13 | `sf sobject describe -s Account` filtrando `Ranking__c` | Picklist restrita, ativos exatamente MP, PP, P, M, G, GG, 3G | `restrictedPicklist=true`; ativos `["MP","PP","P","M","G","GG","3G"]` | passou |
| 2 | 10, 12 (faixas, só configuração) | `SELECT Ranking__c,UpperLimit__c,SortOrder__c FROM RankingRange__mdt ORDER BY SortOrder__c` | 7 faixas: 10.000, 35.000, 80.000, 160.000, 500.000, 1.000.000, 3G sem teto | MP 10000, PP 35000, P 80000, M 160000, G 500000, GG 1000000, 3G nulo; `SortOrder__c` 1 a 7 | passou (só o dado; a comparação não foi executada) |
| 3 | 12 | Tooling API, `Flow.Metadata` da v2 (`301Ha000016RPxQIAW`), listando todo `numberValue` | Nenhum limite fixo (10.000, 70.000, 150.000, 500.000) no Flow | Nenhum `numberValue` preenchido; valores de texto só `Default`, `Erro`, `Fechado/Ganho`, nomes do Flow | passou |
| 4 | 15 | Mesma Metadata, busca de `@` em qualquer string e leitura do `actionCalls` | Nenhum e-mail ou endereço fixo do ex-parceiro | Nenhuma string com `@`; único e-mail é `SendFaultEmail`, com destinatário `GetSetting.FaultRecipient__c` | passou |
| 5 | 16 (parte "sem destinatário") | `SELECT ... FROM ScheduledFlowOpportunitySetting__mdt` | Destinatário não configurado | `Default`: dia 14, `FaultRecipient__c` nulo (só o log funcionaria). Não executado | não executado (só a configuração confere) |
| 6 | Versão ativa | Query em `Flow` por `DeveloperName='ScheduledFlowOpportunity'` | v2 Active, v1 Obsolete | v1 Obsolete, v2 Active (`AutoLaunchedFlow`, Daily 15:47Z) | passou |
| 7 | 14 (existência do relatório) | `SELECT DeveloperName,FolderName FROM Report WHERE DeveloperName='AccountRankingChanges'` | Relatório existe | Existe, pasta provisória de P12 | passou (conteúdo com N contas não exercitado) |
| 8 | 4 (1 update por conta) | Criar conta e oportunidade ganha | Conta atualizada 1 vez | Conta criada; oportunidade ganha recusada pelas 12 validation rules (ver acima) | não executado |
| 9 | 5 (consulta com filtro de `AccountId`) | Leitura do Metadata (`GetOpportunities` com `AccountId`) | Sem consulta de `Opportunity` sem filtro de conta | Não li o filtro do Metadata nesta rodada; o plano do builder diz que `GetOpportunities2` foi removido | não executado |
| 10 | 6 (50 contas, `UNABLE_TO_LOCK_ROW`) | Nada | Zero erros de lock | Sem dado e sem número de P10 | não executado |
| 11 | 8, 9 (soma só de ganhas, conta sem ganha) | Nada | Soma 5.000; valor configurado | Não há oportunidade ganha criável | não executado |
| 12 | 10, 11 (fronteiras, zero, vazio) | Nada | MP/PP/.../3G; sem cair em GG | Idem | não executado |
| 13 | 14 (relatório mostra N contas) | Nada | N contas com valor anterior e novo | Sem execução do Flow, sem linha de histórico | não executado |
| 14 | 16 (falha forçada, aviso e log) | Nada | `IntegrationLog__c` com `Erro`; e-mail só se houver destinatário | Sem execução | não executado |
| 15 | 7 (período configurável) | Fora do escopo (D3) | n/a | n/a | n/a |

Critérios 1 a 3 (H1) são de documentação (`02-recon.md` e design), não de execução na dev, e não foram reavaliados aqui. 17 e 18 são do QA.

## O que pode ter saído da org
Autorização de Leonardo Barbosa (15/11) conferida em `comentarios-do-card.md`. A única coisa que executei com efeito foi criar a conta de teste:
- Conta `TESTE EPLAST-47 Conta A` (`001Ha000016Sdm9IAC`, CNPJ sintético `90470001000192`, gerado por mim, dígitos válidos). O insert enfileirou `UpdateAccountCompanyInfo` (consulta de CNPJ). Resultado registrado em `IntegrationLog__c` `a37Ha000002fv7dIAA`, ação `Consulta CNPJ`, `ResponseStatus__c = Erro(Forbidden)`, 2026-11-15T01:04:04Z. A consulta enviou apenas o CNPJ sintético e não retornou dados.
- Nenhuma oportunidade, pedido, cotação ou chamada ao Protheus (não houve update de conta nem oportunidade ganha). Nada a desfazer do outro lado.

## Limpeza
Apaguei a conta e o log acima (`sf data delete record`). Conferido depois: `COUNT()` de `Account` = 0 e de `IntegrationLog__c` = 0 (eram 0 antes, conforme o plano de build e a contagem de contas que fiz). Nada ficou na dev. Nenhum metadata foi alterado.

## O que uma pessoa precisa fazer para provar o comportamento
1. Na dev ou na QA, criar a base mínima que as validation rules exigem (Filial com Código ERP, condição de pagamento, catálogo de preço, fases financeira e fiscal, conta com endereço/CNAE/contato/Loja e proprietário com ID Usuário Protheus), ou usar um mecanismo de bypass que a Eplast autorize para teste.
2. Rodar o job em dia coincidente com `RunDayOfMonth__c` (ou ajustar `Default` para o dia da execução) e conferir os casos 8 a 14 da tabela.
3. Antes de criar oportunidade ganha, confirmar o endereço configurado do Protheus (R5, autorizado por escrito, mas que continua apontando para a produção do Protheus).
