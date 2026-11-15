**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (alias; sandbox confirmada por `Organization.IsSandbox` = true; `sf org list`: só este alias conectado, Connected; username e Org Id omitidos do artefato)

# EPLAST-26 — Verificação do build na dev

Todo o lado Lead foi exercitado e passou. A Opportunity ficou sem execução, por motivo que o builder não resolve (ver "O que ficou sem prova"). Não é defeito encontrado: nenhum caso executado falhou.

## Método e cuidados
- Casos derivados dos critérios de `01-analise.md` seção 4, não do plano de build.
- Cadeia do Lead conferida pela metadata antes de criar registro: sem ApexTrigger em Lead; um Flow ativo, `Lead_AfterInsert_AplicaRegraAtribuicao`, que chama a Apex `LeadAssignmentService`. O corpo da classe não tem Http, callout, Messaging nem sendEmail. Não sai nada da org.
- Cadeia da Opportunity (OpportunityFlow, CPQ, Protheus): `comentarios-do-card.md` não traz autorização escrita para disparar. Nenhuma Opportunity foi criada.
- Dados: 4 Leads sintéticos (`Company` = `TESTE EPLAST-26`, sobrenome `TESTE EPLAST-26 L1..L4`), todos apagados ao fim. Nenhum registro de cliente foi lido nem alterado (a dev tinha 0 Leads e tem 0 Opportunities).

## Casos

| Caso | Critério (01-analise, seção 4) | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| L1 | Lead com setor, origem e Contatado: Alta | `sf data create record` Lead com Sector=Alimentos, LeadSource=Evento, Status=Contatado; SOQL nos campos | 100 / Alta | 100 / Alta | passou |
| L2 | Lead só com setor: Baixa | Lead com Sector, sem LeadSource, Status "Aberto - Não contatado" | 30 / Baixa | 30 / Baixa | passou |
| L3 | Lead sem setor e sem origem: sem faixa | Lead sem Sector e sem LeadSource, Status=Contatado | 0 / Sem dados suficientes | 0 / Sem dados suficientes | passou |
| L4 | Alteração de status atualiza o score | Lead com Sector e LeadSource, Status "Aberto - Não contatado": lido 60 / Média. `sf data update record` Status=Contatado e nova consulta | 60 / Média, depois 100 / Alta | 60 / Média, depois 100 / Alta | passou |
| RO | Campos somente leitura | `describe` Lead: `PriorityScore__c` e `PriorityBand__c` com `calculated=true`, `createable=false`, `updateable=false`. Tentativa de `update` de cada um | Escrita recusada | "Unable to create/update fields: PriorityScore__c" e idem `PriorityBand__c` | passou (Lead). Opportunity: só metadata, ver abaixo |
| V1 | Lista ordena por score | Vista `Leads_Abertos_Prioridade` (existe na dev) executada pela API REST de list view; SOQL `ORDER BY PriorityScore__c DESC` nos Leads 100, 30, 0 | Ordem 100, 30, 0; coluna ordenável | Ordem 100, 30, 0; `sortable=true` na coluna de score; a vista retornou os 4 Leads de teste com score e faixa | passou (a ordenação pelo clique na tela não foi vista; a coluna é ordenável e o `ORDER BY` confere) |
| V2 | Lista de Opportunity filtra por Alta | Vista `Oportunidades_Prioridade_Alta` existe na dev e foi executada pela API: colunas de score e faixa presentes, `sortable=true`, 0 linhas (a dev não tem Opportunity) | Só faixa Alta | Sem linhas para conferir o filtro | não executado |
| G1 | Sem Trigger, Flow nem Apex novos em Lead/Opportunity | `git show --name-status f9b72bf5` (commit do build): só 4 campos, 3 list views, 1 permission set, 2 layouts e 2 FlexiPages | Nenhum ApexTrigger, Flow ou classe Apex | Confirmado. As automações existentes não foram tocadas | passou |
| G2 | Sem callout, Named Credential, e-mail alert ou Flow de e-mail do score | Mesmo diff e busca por `namedCredential`, `callout`, `emailAlert`, `emailSimple`, `http` | Nenhum | Nenhum no diff do build | passou |
| O1 | Opportunity Prob. 90, valor, 30 dias, origem: 96 / Alta | Não executado | 96 / Alta | — | não executado |
| O2 | Opportunity Prob. 50, 61 dias, sem origem: 40 / Média | Não executado | 40 / Média | — | não executado |
| O3 | Opportunity Prob. 10, sem valor, 200 dias: 4 / Baixa | Não executado | 4 / Baixa | — | não executado |
| O4 | Opportunity encerrada: Encerrada / 0 | Não executado | Encerrada / 0 | — | não executado |
| R1 | Regressão de Opportunity (criar e alterar) | Não executado | Automações existentes iguais; classes de teste de Opportunity passam | — | não executado |
| N1 | Taxa de ganho por faixa | Critério de negócio, medido seis meses após o go-live | — | — | não executado (fora do escopo da verificação) |

## O que ficou sem prova
- **Opportunity (O1 a O4, V2, R1, e a escrita recusada na API da Opportunity).** A dev não tem nenhuma Opportunity. Criar uma passa por 16 validation rules e dispara `OpportunityFlow`, com cotação CPQ e cadeia até o Protheus. Não há autorização escrita do responsável pela conta no card para disparar isso, então não disparei. A fórmula não pôde ser avaliada sem registro.
- **O que uma pessoa precisa fazer para provar:** (a) o Leonardo autoriza por escrito no card uma fixture mínima de Opportunity, com `TESTE EPLAST-26` no nome e apagada ao fim, e o QA ou a verificação a executa na dev (de preferência) e depois na QAS, fora da janela da EPLAST-47, que vai até 15/11 21:00 UTC; ou (b) o time executa os Testes 5 a 9 do `05-roteiro-cliente.md` na homologação.
- Aparência da tela (seção "Prioridade" no layout e na FlexiPage, `Opportunity_Record_Page_Three_Column` sem a seção, layout `SBQQ__CPQ Opportunity Layout` sem os campos, como declarado no plano) não foi conferida. Não há como ver a interface daqui.
- Não conferi as atribuições do permission set aos usuários reais (passo manual do administrador, PD-07).

## B0 — dev distinta de QA
Resolvida. O card de 15/11 confirma que são duas orgs distintas. O Org Id da dev termina em `...vfMLMAY` (conferido agora).

## O que pode ter saído da org
Nada. A cadeia dos Leads de teste (Flow de atribuição, que chama `LeadAssignmentService`) não tem callout nem e-mail; nenhum registro foi criado em outro sistema.

## Limpeza
Os 4 Leads `TESTE EPLAST-26` foram apagados; a consulta por `Company = 'TESTE EPLAST-26'` devolve 0. Não ficou nenhum registro de teste. Os arquivos temporários do retrieve do Flow ficaram só em `/tmp`, fora do repositório.
