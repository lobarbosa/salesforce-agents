**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa` (sandbox `eplast--qas`, Org Id 00DHa000006vZtmMAE, a única conectada em `sf org list`)

# EPLAST-45 · Testes na QA: nutrição de leads até a abordagem comercial

Pacote conferido contra `05-deploy-qa.md` (deploy `0AfHa00000EI93BKAT`, Succeeded): os 4 campos de Lead, a list view `Leads_Prontos_Abordagem`, os 3 permission sets e os 2 relatórios existem na org (FieldDefinition, Report, ListView, PermissionSet consultados). Sem falhas. A demanda não tem automação agendada (sem Flow, sem Apex), então não há duas fases.

Dado de teste: 7 leads `TESTE EPLAST-45 L1..L7` (Company `TESTE EPLAST-45`) criados por `fixtures/lead-nutricao.apex` (o mesmo da dev, rodou sem alteração na QA), dono = Id `005bJ00000piKAaQAM` (conta de serviço da Konecta, ativa, perfil Administrador do sistema; é também o usuário de execução). Nenhum registro pré-existente lido ou alterado: a QAS tem 712 leads (copiados), só contagens agregadas.

## Falhas
Nenhuma.

## Casos
| Caso | Critério | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| T1 | CA-01 | Insert dos 7 leads, SOQL dos campos | L1 elegível/não pronto; L2 elegível/pronto; L6 elegível/não pronto; L7 não elegível | L1 true/false (Média); L2 true/true (Alta); L6 true/false (Sem dados suficientes); L7 false/false | passou |
| T2 | CA-01 | Relatório `NUTRICAO_LEADS_EMAIL` (Analytics API, só total) vs SOQL agregado `Elegivel=true AND HasOptedOutOfEmail=false AND Email!=null` | Contagens iguais | Relatório 202; SOQL 202 | passou |
| T3 | CA-02 | Mesmo relatório com os filtros originais mais Company = TESTE (só leads de teste) | L3 (opt-out e-mail) fora; L4 dentro | L1, L2, L4, L5 (L3 ausente; L6 sem e-mail, ausente; L7 não elegível) | passou |
| T4 | CA-03 | `NUTRICAO_LEADS_MENSAGEM` total vs SOQL; filtro de teste | Contagens iguais; L4 (opt-out mobile) fora; L3 dentro | Relatório 148; SOQL 148; teste: L1, L2, L3, L5 (L4 ausente) | passou |
| T5 | CA-04 | Update L1 de `Aberto - Não contatado` para `Contatado`, sem outra ação | L1 vira Alta e pronto | L1: Alta, pronto = true | passou |
| T6 | CA-04 | SOQL com a condição da list view (confirmada no describe: não convertido e pronto = true) sobre leads TESTE | Só leads Alta elegíveis; L6 (sem dados), L7 fora | Após T5: L1, L2, L3, L4; L6 e L7 ausentes. Total da list view na QA: 108 (SOQL pronto = true: 108 em todos os leads, incluindo convertido/filtro de IsConverted) | passou |
| T7 | CA-05 | `Database.convertLead` em L5 (bypass de trigger de Account, sem oportunidade) | L5 elegível e pronto = false e fora da lista | Conversão ok; L5 IsConverted true, elegível false, pronto false; fora da lista de prontos | passou |
| T8 | CA-06 | Mudança de L1 para Alta (T5) e gravações em L2 (T9) | OwnerId inalterado | `ownerSame=true` em L1 e em L2 | passou |
| T9 | CA-07 | Update de L2 com cada valor da picklist (Sem engajamento, Baixo, Médio, Alto) e data | Valor gravado; Status, Faixa, Owner iguais; L2 continua pronto | 4 valores aceitos; Status Contatado, Faixa Alta, pronto true, dono igual em todos | passou |
| T10 | CA-08 | `05-deploy-qa.md`: lista de componentes | Nenhum Flow, Apex ou trigger; nada em Account/Opportunity/Order | 4 campos, 1 list view, 3 permission sets, 2 relatórios; nenhum Flow/Apex | passou |
| T11 | CA-09 | Insert de 7 leads na QA com o Flow `Lead_AfterInsert_AplicaRegraAtribuicao` | Insert sem erro; sem automação nova | 7 inseridos sem erro, fixtures e update sem erro | passou |
| T12 | CA-10 | `FieldDefinition.Description` dos 4 campos | Descrição preenchida | 4 campos com "EPLAST-45. ..." | passou |
| T13 | FLS | `FieldPermissions` dos 4 campos nos 3 sets | Leitura em todos; edição só em engajamento e data e só no `PS_Marketing_RetornoMC` | Confere (12 linhas; edição true só em 2 linhas do RetornoMC) | passou |
| T14 | PD-04 | Atribuições do `PS_Marketing_RetornoMC` antes de eu atribuir | 0 | 0 | passou |
| T15 | CA-11 | Sem Apex | não se aplica | não se aplica | não se aplica |
| T16 | CA-12 | Saída só com nomes TESTE e contagens | Sem dado pessoal | Cumprido | passou |

## Não exercitado
- Acesso negado com usuário sem permissão: o usuário de teste da conta é o mesmo de execução (e é administrador), então não deu para ver o campo oculto. A FLS foi comprovada por metadata (T13). Fica para o roteiro do cliente.
- Telas (list view e relatórios na interface): comprovadas por API/SOQL equivalente, não pela UI do navegador.

## Efeito cruzado
Os permission sets `PS_Comercial_ScorePrioridade` e `PS_Marketing_Publicos` também são alterados por outras demandas (preflight). Aqui só conferi as 4 linhas de FLS desta demanda, presentes na QA.

## O que pode ter saído da org
Nada. Sem callout nem automação nova. O Flow de atribuição existente rodou no insert dos leads TESTE; sem e-mail ou chamada externa registrada. Marketing Cloud não tocado. A conversão do L5 criou uma Account e um Contact `TESTE EPLAST-45` (bypass do trigger de Account, sem consulta externa).

## Mudanças no usuário de execução e limpeza
- Atribuí `PS_Marketing_RetornoMC` (criado pela demanda) ao usuário de execução para enxergar os campos. Antes: sem atribuição. Depois: removida (0 atribuições).
- Nenhuma outra mudança (sem Marketing User, sem campo Protheus).
- Limpeza: leads TESTE 0 e Account TESTE 0 ao final. Sem job agendado. Total de leads da QAS: 712 (inalterado).
