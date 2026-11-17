**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-26 — Verificação na dev (rodada 3: critérios e faixas AA/A/B/C/D)

- Org conferida com `sf org list`: `sbx-eplast-dev` (Sandbox, Connected, org `00DHa000006vfMLMAY`). Nada na QA, nada na produção, nada no Marketing Cloud.
- Casos derivados da seção 8 do `03-design.md` (a seção 4 do `01-analise.md` é da rodada anterior e foi substituída pelas respostas do cliente de 17/11), mais os pontos que o plano de build deixou para o verificador (faixas AA/A/B, I-2, comportamento "ou" da list view).
- Dados só sintéticos `TESTE EPLAST-26`. Uma transação por coisa (massa, tarefas, fechamento, atualização e leitura em execuções separadas). Nenhum registro existente da dev foi lido ou alterado (só contagens e os criados por mim).
- O build não foi alterado. Os parâmetros do `Default` foram trocados temporariamente por deploy (caso 15) e restaurados.

## Limitação conhecida (não é reprovação)

O acesso ao campo `Lead.MKT_MC_Engajamento__c` pelo perfil de teste é limitado: a edição vem de `PS_Marketing_Publicos` e `PS_Marketing_RetornoMC`, que não são desta demanda, e `PS_Comercial_ScorePrioridade` não a concede (leitura sim). Decisão do responsável de 17/11: o build não muda e o pacote não inclui essas permissões. Na dev o usuário de execução conseguiu preencher o campo por Apex anônimo (sem alterar permissão), então os casos de Lead com engajamento foram exercitados aqui. Na QA o mesmo usuário não enxerga o campo (FALHA 1 de `05-testes-rodada-1.md`); isso continua como limitação do ambiente de teste.

## Resultado por caso

| Caso | Critério (design, seção 8) | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Lead engajamento Alto | Insert de Lead L1 com `MKT_MC_Engajamento__c`='Alto'; SOQL de score e faixa | 15, D | 15, D | passou |
| 2 | Lead "Sem engajamento" | Lead L2 | 0, D | 0, D | passou |
| 3 | Lead engajamento vazio | Lead L3 (Status Contatado) | 0, Não classificado | 0, Não classificado | passou |
| 4 | Critérios antigos saíram | Lead L4 com Status Contatado, `Sector__c`=Alimentos, `LeadSource`=Campanha, sem engajamento | 0 | 0, Não classificado | passou |
| 4b | Médio e Baixo | Leads L5 (Médio) e L6 (Baixo) | 10 D e 5 D | 10 D e 5 D | passou |
| 5 | Opp com descoberta, orçamento, Negociação Comercial, atividade há 5 dias, próximo passo | Opp O5 + Task concluída com data há 5 dias | 45, C | `LastActivityDate`=2026-11-12, 45, C | passou |
| 6 | Opp Qualificação sem nada | Opp O6 | 0, D | 0, D (O10, idem) | passou |
| 7 | Atividade há 31 e há 30 dias | O7 (31 dias) e O8 (30 dias), resto igual ao caso 5 | 35 D / 45 C | O7: 35 D; O8: 45 C | passou |
| 8 | Opp encerrada | O9 passada a "Fechado/Perdido"; O5 (que tinha 45) também passada a "Fechado/Perdido" | 0, Não classificado | O9: 0, Não classificado; O5: de 45 C para 0, Não classificado | passou ("Fechado/Ganho" não executado: exige filial e pagamento; mesma ramificação `IsClosed`) |
| 9 | Campos somente leitura (API) | Apex: `put` e `update` em `PriorityScore__c` e `PriorityBand__c` de Opportunity e de Lead | recusado | 4 de 4: "Field ... is not editable" | passou (tela não exercitada) |
| 10 | List view `Oportunidades_Prioridade_Alta` filtra AA e A | Retrieve do metadata da dev; depois, com o `Default` de cortes baixos (caso 15), resultado da list view pela API REST, só contagem e nome de teste | Filtro `CLOSED=0` e `PriorityBand__c equals "AA,A"`; "ou" funcionando | Filtro confere; lista devolveu 2 registros: O7 (A) e O8 (AA), nenhum registro fora dos de teste, O6 (C) ficou de fora | passou |
| 10b | Colunas novas das list views | Retrieve do metadata da dev | `NEXT_STEP` e `LAST_ACTIVITY` em `Oportunidades_Abertas_Prioridade`; `MKT_MC_Engajamento__c` em `Leads_Abertos_Prioridade` | as três colunas presentes | passou |
| 11 | `MKT_Nutricao_ProntoAbordagem__c` falso para os leads de teste | SOQL do campo nos 6 Leads | falso | falso nos 6 | passou |
| 12 | Regressão em Opportunity (criar e alterar) | Insert de 6 Opps (RT Indústria, Account com `bypassTrigger`), 3 Tasks, fechamento de 2, update de `NextStep`, `Amount` e `CloseDate` em O6 | sem erro de automação | todas "Executed successfully"; O6 passou de 0 a 10 ao preencher o próximo passo | passou |
| 13 | Diff sem Apex, Flow, e-mail, callout, Named Credential | `git diff --name-only main -- clients/eplast/force-app` filtrando classes, triggers, flows, workflow, e-mail, Named Credential; `git log 92d22928..HEAD -- force-app` | nada | 28 arquivos, nenhum dos tipos filtrados; 0 commits em `force-app` depois do build | passou |
| 14 | Valores iniciais do `Default` | SOQL em `PriorityScoreSetting__mdt` | 15/10/5; 10/10/5/10/30/10; cortes 90/75/60/40 | idênticos; 1 único registro (conferido antes e depois do caso 15) | passou |
| 15 | Faixas AA, A, B, C, D leem o parâmetro | Deploy só na dev (`0AfHa00000EJCzuKAH`) de cópia do `Default` com cortes AA 45, A 35, B 15, C 5; SOQL; deploy do original (`0AfHa00000EJLK1KAP`) | Opp 45 AA, 35 A, 10 C, 0 D; Lead 15 B, 10 C, 5 C, 0 D | Opp O8 45 AA; O7 35 A; O6 10 C; O10 0 D; Lead L1 15 B; L5 10 C; L6 5 C; L2 0 D; vazios "Não classificado". As cinco faixas apareceram | passou |
| 16 | I-2: usuário sem "Personalizar aplicativo" lê o valor calculado | Classe de teste temporária `TmpVerify26Test` implantada na dev (0 de cobertura exigida, `RunSpecifiedTests`): `System.runAs` de usuário ativo `005bJ000004gGVxQAM` (perfil com `PermissionsCustomizeApplication=false`, confirmado dentro do teste), insert de Lead com engajamento Alto, leitura de score e faixa | 15, D | teste passou (1 de 1, asserts 15 e D); classe removida por destructive change (0 classes com o nome) | passou, com ressalva abaixo |

### Ressalva do caso 16
O usuário do `runAs` não tem o permission set `PS_Comercial_ScorePrioridade` (não alterei atribuição de outros usuários), então a leitura rodou em modo sistema. Fica provado que a fórmula que lê `$CustomMetadata.PriorityScoreSetting__mdt.Default.*` calcula para usuário sem "Personalizar aplicativo" e sem acesso ao tipo (Public): não é preciso mexer em `PS_Comercial_ScorePrioridade` (I-2 não voltou ao gate). A combinação "usuário real com o permission set e sem Personalizar aplicativo, na tela" não foi exercitada. O usuário do job é administrador.

## Não testado
- "Fechado/Ganho" (exige filial e pagamento).
- Somente leitura e list view na tela (só API e metadata).
- Taxa de ganho por faixa (métrica de negócio pós go-live).
- Efeito de A6 com lead elegível em AA ou A: nenhum lead de teste chegou a A (máximo 15, faixa B só com cortes temporários e sem `MKT_Nutricao_Elegivel__c`). A fórmula foi conferida pela entrega (`OR` AA/A), valor falso confirmado só para os leads de teste (caso 11).

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`, desfeitas)
| Item | Antes | Durante | Depois |
|---|---|---|---|
| `ProtheusSellerId__c` (validation exige no proprietário) | vazio | `TESTE26` | vazio, conferido |
| Permission sets `PS_Comercial_ScorePrioridade` e `PS_Comercial_SinaisComerciais` | já atribuídos antes da sessão | sem mudança | sem mudança (não atribuí nem removi nada) |
| Marketing User | não necessário | — | — |

## Registros criados e removidos
- Criados e apagados: 6 Leads, 1 Account, 6 Opportunities e 3 Tasks (`TESTE EPLAST-26`), com `TriggerUtility.bypassTrigger` na Account. Contagens finais por consulta: Lead 0, Opportunity 0, Account 0.
- Classe temporária `TmpVerify26Test`: criada e removida (0 na consulta final). Nenhum job agendado.
- `PriorityScoreSetting.Default`: restaurado ao original, valores conferidos por SOQL.

## O que pode ter saído da org
Nada. Sem callout, e-mail ou integração relacionados ao score; a Account foi criada com o desvio da trigger (sem BrasilAPI nem Protheus). Nada de Marketing Cloud.

## Premissas assumidas
As do design (seção 9) valem como decididas e não foram motivo de reprovação.
