**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-26 — Testes na sandbox de QA (rodada 3: critérios e faixas AA/A/B/C/D)

Reprovado por critério principal não executado (regra da esteira), **não por defeito encontrado no build**: nenhum resultado obtido divergiu do esperado. Os casos de Lead com engajamento preenchido (1, 2 e 4b) não puderam ser exercitados porque o usuário de execução do job não enxerga o campo `Lead.MKT_MC_Engajamento__c` na QA (ver FALHA 1).

- Org conferida com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, QAS da Eplast). Deploy `0AfHa00000EJBR9KAP` (Succeeded, commit `0ea434ee`) conferido em `05-deploy-qa.md`.
- Casos derivados da seção 8 do `03-design.md` (a seção 4 do `01-analise.md` é da rodada anterior e foi substituída pelas respostas do cliente de 17/11). Só registros sintéticos `TESTE EPLAST-26`, uma transação por coisa. Nenhum registro existente da QAS foi lido ou alterado (só contagens e registros criados por mim).

## Falhas

### FALHA 1 (crítica) — Casos de Lead com engajamento preenchido não executáveis na QA
- Reproduzir: Apex anônimo na QA com `new Lead(..., MKT_MC_Engajamento__c='Alto')`, ou `Lead.put('MKT_MC_Engajamento__c', ...)`.
- Obtido: "Field does not exist: MKT_MC_Engajamento__c on Lead" / "Invalid field". O campo existe na org (`CustomField` no Tooling API; as fórmulas do build compilam com ele), mas o usuário do job não tem permissão de campo. Quem concede leitura e edição é o permission set `PS_Marketing_RetornoMC` (e `sfdc_a360_sfcrm_data_extract`, só leitura), que **não é da demanda**; a regra da esteira só permite atribuir o permission set que a demanda criou. `PS_Comercial_ScorePrioridade` não cobre esse campo, por desenho.
- Esperado: Lead Alto 15 D; Sem engajamento 0 D; Médio 10 D; Baixo 5 D.
- Consequência: a parte do cálculo do Lead que usa o engajamento não tem evidência na QA. Na dev esses casos passaram (`04-verificacao.md`, casos 1, 2, 4b), mas a regra pede prova na QA.
- Como destravar: o time dar ao usuário do job, na QA, o permission set `PS_Marketing_RetornoMC` (decisão de quem administra a org), ou o roteiro do cliente (Teste 1 a 3) ser executado por pessoa que tenha esse acesso, antes da homologação.
- Causa provável do ponto sem acesso: campo do conector/retorno do Marketing Cloud só liberado ao perfil de marketing.

## Resultado por caso

| Caso | Critério (design, seção 8) | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| 1 | Lead engajamento Alto | Insert de Lead com `MKT_MC_Engajamento__c`='Alto' | 15, D | Campo indisponível ao usuário do job (FALHA 1) | não executado |
| 2 | Lead "Sem engajamento" | idem | 0, D | idem | não executado |
| 3 | Lead engajamento vazio | Insert de Lead L3 (Status Contatado), consulta de score e faixa | 0, Não classificado | 0, Não classificado | passou |
| 4 | Critérios antigos saíram | Lead L4 com Status "Contatado", `Sector__c`=Alimentos, `LeadSource`=Campanha, sem engajamento | 0 | 0, Não classificado | passou |
| 4b | Médio e Baixo | Leads com Médio e Baixo | 10 D e 5 D | Campo indisponível (FALHA 1) | não executado |
| 5 | Opp com descoberta, orçamento, Negociação Comercial, atividade 5 dias, próximo passo | Opp O5 + Task concluída com data há 5 dias | 45, C | `LastActivityDate`=2026-11-12, 45, C | passou |
| 6 | Opp Qualificação sem nada | Opp O6 | 0, D | 0, D | passou |
| 7 | Atividade há 31 e há 30 dias | Opps O7 (31 dias) e O8 (30 dias), mesmo cenário do caso 5 | 35 D / 45 C | O7: 35 D; O8: 45 C | passou |
| 8 | Opp encerrada | Opp O9 passada a "Fechado/Perdido" | 0, Não classificado | 0, Não classificado | passou (Perdido). "Fechado/Ganho" não executado: exige filial e pagamento, mesma ramificação `IsClosed` |
| 9 | Campos somente leitura | Apex: `Opportunity.put('PriorityScore__c', 99)` | recusado | "Field PriorityScore__c is not editable". `PS_Comercial_ScorePrioridade` traz `editable=false` nos 4 campos | passou (API). Tela não exercitada |
| 10 | List view `Oportunidades_Prioridade_Alta` filtra AA e A | Conferência do filtro no metadata da QA e contagem sobre as Opps de teste | Filtro `CLOSED=0` e `PriorityBand__c` igual a "AA,A"; nenhuma Opp de teste em AA/A (máx. 45) | Filtro confere no XML implantado (list view existe na QA, Id `00BHa00000ApFtj`); 0 Opps de teste AA/A | passou (lista vazia esperada). Abrir a lista na tela não foi feito: mostraria Opps reais da QAS |
| 11 | `MKT_Nutricao_ProntoAbordagem__c` falso para leads de teste | Leitura do campo | falso | Campo existe na QA, mas o usuário do job não tem permissão de leitura (só `PS_Marketing_RetornoMC` e `sfdc_a360_sfcrm_data_extract`); valor não lido | não executado |
| 12 | Regressão em Opportunity (criar e alterar) | Insert de 5 Opps, Task, fechamento de uma, update de NextStep/Amount/CloseDate em outra | sem erro de automação | Todas as execuções "Executed successfully", score recalculado (O6 passou de 0 a 10 ao preencher próximo passo). Uma mudança de fase para "Cotação" foi barrada pela validation existente "Selecione um catálogo de preços" (comportamento já documentado na fixture, não é da entrega) | passou |
| 13 | Diff sem Apex, Flow, e-mail, callout, Named Credential | `git diff --name-only main -- force-app` filtrando classes, triggers, flows, workflow e e-mail | nada | 28 arquivos, só metadata declarativa (campos, custom metadata, list views, layouts, páginas, permission set); nenhum Apex, Flow ou e-mail | passou |
| 14 | Valores iniciais do `Default` | `SELECT` em `PriorityScoreSetting__mdt` | 15/10/5; 10/10/5/10/30/10; cortes 90/75/60/40 | idênticos; 1 único registro | passou |

Nota sobre o diff do caso 13: os layouts e páginas (`Lead_Record_Page`, `Opportunity_Record_Page`, `Lead Layout`, `Opportunity Layout`) fazem parte do que a esteira implantou porque diferem da `main` (a seção Prioridade vem de rodadas anteriores). O design desta rodada não os altera. Outras demandas do cliente tocam os mesmos arquivos (EPLAST-30, 35, 38, 40, 41, 45): não afetou os testes.

## Evidências de tela
- `evidencias/01-opp-de-teste-o5-teste-eplast-26-score-e-.jpg`: página ainda carregando (sem valor útil).
- `evidencias/02-opp-de-teste-o5-teste-eplast-26-aba-deta.jpg`: Opp de teste O5, aba Detalhes. A seção "Prioridade" existe na página (confirmada pelo texto), mas a ferramenta não rola a tela e a captura não mostra os valores.
- `evidencias/03-opp-de-teste-o5-secao-prioridade-apos-cl.jpg`: tela rolada para a linha do tempo. Sem valor útil.
Os valores de score e faixa foram provados por consulta (tabela acima), não pelas capturas. A conferência pela tela fica para o roteiro do cliente.

## Mudanças no usuário de execução (desfeitas)
- Usuário de execução do job (`005bJ00000piKAaQAM`): `ProtheusSellerId__c` era vazio, ficou `TESTE26` durante os testes (validation rule exige no proprietário). **Devolvido a vazio** e conferido.
- Permission set `PS_Comercial_ScorePrioridade` atribuído a ele para os campos de prioridade; **atribuição removida**, 0 atribuições ao final.
- Marketing User: não necessário.

## O que pode ter saído da org
- Criados e apagados ao final: 1 Conta, 5 Opportunities, 3 Tasks, 2 Leads (`TESTE EPLAST-26`). Conta criada com o desvio `TriggerUtility.bypassTrigger` (sem BrasilAPI nem Protheus). Contagens finais de Opp e Lead de teste: 0.
- Nenhum callout, e-mail ou envio relacionado ao score. Os Flows existentes de Opportunity rodaram sem erro. Nada de Marketing Cloud.
- O registro de teste da Conta ficou sem leitura de dados reais: o primeiro insert foi barrado por regra de duplicidade e repetido com endereço sintético e permissão de duplicata.

## Premissas assumidas
Não foram motivo de reprovação (regra 4 da conta). Repetidas no roteiro do cliente.

## Não testável nesta sandbox
- Taxa de ganho por faixa (métrica de negócio pós go-live).
- Verificação com usuário sem "Personalizar aplicativo" (I-2): feita na dev (caso 16 da verificação); na QA o usuário de teste da regra 6 é administrador, então a prova não se repete aqui.
- Cálculo sobre os registros existentes da QAS: não lido, por ser dado real.
