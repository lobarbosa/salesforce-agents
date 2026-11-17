**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-26 — Testes na sandbox de QA (rodada 2 de QA: critérios e faixas AA/A/B/C/D)

Esta é a segunda rodada de QA da versão com critérios e faixas AA/A/B/C/D. A rodada 1 (`05-testes-rodada-1.md`) foi reprovada sem defeito no build: só a FALHA 1 (usuário do job sem acesso ao campo `Lead.MKT_MC_Engajamento__c`). Nenhum defeito de build foi encontrado agora.

- Org conferida com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, QAS da Eplast, org `00DHa000006vZtmMAE`). Deploy `0AfHa00000EJGqdKAH` (Succeeded, commit `b2695652`) conferido em `05-deploy-qa.md`.
- Componentes do deploy conferidos na org: tipo `PriorityScoreSetting__mdt` e registro `Default` (1 registro), campos `PriorityScore__c` e `PriorityBand__c` em Lead e Opportunity, `MKT_Nutricao_ProntoAbordagem__c`, list views (retrieve) e `PS_Comercial_ScorePrioridade`. Nenhum ausente.
- Casos derivados da seção 8 do `03-design.md` e dos critérios das respostas do cliente de 17/11. Só registros sintéticos `TESTE EPLAST-26`, uma transação por coisa. Nenhum registro existente da QAS foi lido ou alterado (só contagens e registros que criei).
- Preflight sem bloqueios. Outras demandas (EPLAST-30, 35, 38, 40, 41, 45) tocam os mesmos arquivos; não afetou os testes e não alterei esses componentes.

## Retestes da rodada anterior

| Falha | Situação |
|---|---|
| FALHA 1 (crítica) — casos de Lead com engajamento e caso 11 não executáveis | **Corrigida (do lado do ambiente de teste).** Seguindo a decisão do responsável de 17/11 (`03-design.md`, final), atribuí `PS_Marketing_RetornoMC` ao usuário de execução durante o teste e removi ao final. Casos 1, 2, 4b e 11 executados e passaram. Build sem alteração. |

## Falhas

Nenhuma.

## Resultado por caso

| Caso | Critério (design, seção 8) | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| 1 | Lead engajamento Alto | Insert Lead L1 (`MKT_MC_Engajamento__c`='Alto', Status Contatado, Sector e LeadSource preenchidos); SOQL score e faixa | 15, D | 15, D. Tela: seção Prioridade com 15 e D (`evidencias/04-lead-de-teste-l1-engajamento-alto-secao-.jpg`) | passou |
| 2 | Lead "Sem engajamento" | Lead L2 | 0, D | 0, D | passou |
| 3 | Lead engajamento vazio | Lead L5 sem engajamento | 0, Não classificado | 0, Não classificado | passou |
| 4 | Critérios antigos saíram | L1 a L5 têm Status Contatado, Setor Alimentos e Origem Campanha; só o engajamento muda o score (L5 = 0) | 0 sem engajamento | L5: 0, Não classificado | passou |
| 4b | Médio e Baixo | Leads L3 (Médio) e L4 (Baixo) | 10 D e 5 D | L3: 10 D; L4: 5 D | passou |
| 5 | Opp com descoberta, orçamento, Negociação Comercial, atividade há 5 dias, próximo passo | Opp O5 + Task concluída há 5 dias | 45, C | `LastActivityDate`=2026-11-12, 45, C. Tela: Prioridade 45 e C (`evidencias/05-opp-de-teste-o5-secao-prioridade-mostra-.jpg`) | passou |
| 6 | Opp "Qualificação" sem nada | Opps O9 e O10 (antes de alterar) | 0, D | 0, D | passou |
| 6b | Sem atividade, o resto do cenário 5 | Opp O6 (Negociação, descoberta, orçamento, próximo passo, sem Task) | 35, D | 35, D | passou |
| 7 | Atividade há 31 e há 30 dias | O7 (31 dias) e O8 (30 dias) | 35 D / 45 C | O7: 35 D; O8: 45 C | passou |
| 8 | Opp encerrada | O9 passada a "Fechado/Perdido" | 0, Não classificado | 0, Não classificado (`IsClosed`=true) | passou ("Fechado/Ganho" não executado: exige filial e pagamento; mesma ramificação `IsClosed`) |
| 9 | Campos somente leitura | Apex: `put` de `PriorityScore__c` e `PriorityBand__c` em Opportunity e em Lead | recusado | 4 de 4: "Field ... is not editable" | passou (API; na tela os campos aparecem sem lápis de edição) |
| 10 | List view `Oportunidades_Prioridade_Alta` filtra AA e A | Retrieve do metadata da QA; contagem das Opps de teste em AA/A | Filtro `CLOSED=0` e `PriorityBand__c equals "AA,A"`; nenhuma Opp de teste em AA/A (máx. 45) | Filtro confere; 0 Opps de teste em AA/A | passou. Lista não aberta na tela: mostraria Opps reais da QAS |
| 10b | Colunas novas | Retrieve do metadata da QA | `NEXT_STEP` e `LAST_ACTIVITY` em `Oportunidades_Abertas_Prioridade`; `MKT_MC_Engajamento__c` em `Leads_Abertos_Prioridade` | as três presentes | passou |
| 11 | `MKT_Nutricao_ProntoAbordagem__c` falso para os leads de teste | SOQL do campo nos 5 Leads; retrieve da fórmula | falso; fórmula `OR(AA, A)` | falso nos 5; fórmula `AND(MKT_Nutricao_Elegivel__c, OR(PriorityBand__c = "AA", PriorityBand__c = "A"))` | passou |
| 12 | Regressão em Opportunity (criar e alterar) | Insert de 6 Opps, 3 Tasks, fechamento de uma, update de `NextStep`, `Amount` e `CloseDate` na O10 | sem erro de automação | Todas as execuções "Executed successfully"; O10 foi de 0 D para 10 D ao preencher o próximo passo | passou |
| 13 | Diff sem Apex, Flow, e-mail, callout, Named Credential | Lista do deploy (`05-deploy-qa.md`, 28 componentes); sem mudança de build desde a rodada 1 | nada desses tipos | Só campos, custom metadata, list views, layouts, páginas e permission set. Nenhum Apex, Flow ou e-mail | passou |
| 14 | Valores iniciais do `Default` | SOQL em `PriorityScoreSetting__mdt` | 15/10/5; 10/10/5/10/30/10; cortes 90/75/60/40 | idênticos; 1 único registro | passou |

## Evidências de tela
- `evidencias/04-lead-de-teste-l1-engajamento-alto-secao-.jpg`: Lead de teste, seção Prioridade com Score 15 e Faixa D.
- `evidencias/05-opp-de-teste-o5-secao-prioridade-mostra-.jpg`: Opp de teste O5, seção Prioridade com Score 45 e Faixa C.
Os demais valores foram provados por consulta (tabela acima). Três capturas anteriores desta sessão (página carregando ou sem a seção visível) foram descartadas.

## Mudanças no usuário de execução (`005bJ00000piKAaQAM`, desfeitas)

| Item | Antes | Durante | Depois (consulta) |
|---|---|---|---|
| `PS_Marketing_RetornoMC` (decisão do responsável, 17/11) | não atribuído (0 na consulta) | atribuído (`0PaHa00000EM7PsKAL`) | removido; 0 atribuições dos dois permission sets |
| `PS_Comercial_ScorePrioridade` (da demanda) | não atribuído | atribuído (`0PaHa00000ELybXKAT`) | removido |
| Total de atribuições do usuário | 11 | 13 | 11 |
| `ProtheusSellerId__c` (validation exige no proprietário) | vazio | `TESTE26` | vazio, conferido |
| Marketing User | não necessário | — | — |

Perfil, papel, outros permission sets e outros usuários não foram tocados. Usuário de teste (conta de serviço Konecta, identificado só pelo Id) ativo, perfil Administrador do sistema (Id `005bJ00000piKAaQAM`, o mesmo do job).

## O que pode ter saído da org
- Criados e apagados ao final: 1 Conta, 6 Opportunities, 3 Tasks, 5 Leads (`TESTE EPLAST-26`). Contagens finais por consulta: 0 em cada. Conta criada com `TriggerUtility.bypassTrigger` (sem BrasilAPI nem Protheus), com permissão de duplicata na inserção.
- Nenhum callout, e-mail ou envio relacionado ao score. Os Flows existentes de Opportunity rodaram sem erro. Nada de Marketing Cloud.

## Premissas assumidas
Do design (seção 9). Não foram motivo de reprovação (regra 4 da conta). Repetidas no roteiro do cliente.

## Não testável nesta sandbox
- Taxa de ganho por faixa (métrica de negócio pós go-live).
- Faixas AA, A e B na QA: com os valores do `Default` e os campos de hoje o máximo é 15 no Lead e 45 na Opportunity. A leitura dos cortes pela fórmula foi provada na dev (`04-verificacao.md`, caso 15); na QA o `Default` não é alterado.
- Usuário sem "Personalizar aplicativo" com o permission set, na tela (I-2): provado na dev por `runAs` (caso 16 da verificação); o usuário do job na QA é administrador.
- "Fechado/Ganho": exige filial e pagamento.
- Cálculo sobre os registros existentes da QAS: não lido, por ser dado real.
