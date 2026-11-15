**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-26 — Testes na sandbox de QA (rodada 2)

Org conferida com `sf org list`: só `sbx-eplast-qa` conectada (Sandbox, `eplast--qas`, Org Id 00DHa000006vZtmMAE). Nada tocado na dev, no Marketing Cloud ou em produção. `05-deploy-qa.md`: deploy `0AfHa00000EI09aKAD` Succeeded, commit `15dc3a9c`. Os 12 componentes já tinham sido conferidos na org na rodada 1; nesta rodada os campos, as list views, a seção "Prioridade" dos dois layouts e o permission set responderam nos testes abaixo.

**Rodada anterior.** A rodada 1 reprovou por FALHA 1 (média): cenários de Opportunity sem registro que os exercitasse, porque não se criou dado. Agora a esteira autoriza dado sintético (regra de 2026-11-15, card de 18:15 para a Conta com `TriggerUtility.bypassTrigger`). Esperei passar das 21:00 UTC (fim do teste armado da EPLAST-47, card 10:16) antes de criar registros. **FALHA 1: corrigida** (O1, O2, O5 e a faixa Alta na list view agora têm evidência, abaixo).

## Falhas
Nenhuma que bloqueie o aceite. Pontos não provados estão em "Não executado".

## Casos (dados sintéticos `TESTE EPLAST-26`, criados por Apex anônimo na QAS e apagados ao fim)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| L1 Lead setor+origem+Contatado | insert; `SELECT PriorityScore__c, PriorityBand__c` | 100 / Alta | 100 / Alta | passou |
| L2 Lead só setor, Aberto - Não contatado | idem | 30 / Baixa | 30 / Baixa | passou |
| L3 Lead sem setor e sem origem, Contatado | idem | 0 / Sem dados suficientes | 0 / Sem dados suficientes | passou |
| L4 Mudança de status | Lead setor+origem não contatado: 60 / Média; `sf data update` Status=Contatado; reconsulta | 100 / Alta | 60 / Média antes; 100 / Alta depois | passou |
| O1 Opp 90%, valor, +30 dias, origem | insert; consulta | 96 / Alta | 96 / Alta | passou |
| O2 Opp 50%, valor, +61 dias, sem origem | idem | 40 / Média | 40 / Média | passou |
| O3 Opp 10%, valor 0, +200 dias, sem origem | idem | 4 / Baixa | 4 / Baixa | passou |
| O4 Opp encerrada (Fechado/Perdido) | idem | 0 / Encerrada | 0 / Encerrada | passou |
| O5 Borda +60 dias, 55% (22 pts), valor, origem | idem | 22+20+20+20 = 82 / Alta | 82 / Alta | passou |
| O6 Reabrir após alteração | `sf data update` na O1: Amount=500, Stage=Análise Técnica (20%), fechamento +16 dias; reconsulta | 8+20+20+20 = 68 / Média; update aceito com as automações ativas | 68 / Média; update aceito | passou |
| Contagens da rodada 1 (712 Leads, 9.327 Opps reais) | contagem de divergentes por combinação de entradas | 0 divergentes | 0 divergentes (rodada 1, mantido) | passou |
| S1 Campos somente leitura | `sf data update` de `Lead.PriorityScore__c` | recusado | "Unable to create/update fields: PriorityScore__c ..." | passou |
| P1 Permission set | rodada 1: 4 campos Read=true, Edit=false. Nesta: atribuído ao usuário da esteira, campos passaram a aparecer na página | campos visíveis | Score e Faixa visíveis (screenshots) | passou |
| V2 List view Opp faixa Alta | REST `Oportunidades_Prioridade_Alta/results` | só faixa Alta, com o registro de teste | 1 registro, 82, Alta (O5; O1 já estava em 68/Média) | passou |
| V3 List view Opp abertas | REST `Oportunidades_Abertas_Prioridade/results` | só abertas | faixas Baixa e Média; nenhuma "Encerrada" | passou |
| V1 Lead list view ordena por score (clique na coluna) | REST `orderBy=PriorityScore__c` asc e desc | ordem 100, 30, 0 | endpoint devolveu a mesma ordem nos dois sentidos (parâmetro ignorado pelo REST, igual à dev); coluna `sortable=true` | **não executado (tela)** |
| UI Lead | `qa_browser`: página do Lead de teste L1, expandir "Prioridade" | Score 100, Faixa Alta | Score de prioridade 100, Faixa de prioridade Alta (screenshot, registro de teste) | passou |
| UI Opportunity | idem, Opp de teste O1 | 68 / Média | Score de prioridade 68, Faixa Média (screenshot, registro de teste) | passou |
| R1 Sem trigger, Flow ou Apex | rodada 1: diff de 12 arquivos, só campos, layouts, flexipages, list views e permission set | nenhum | idem | passou |
| R2 Sem callout ou e-mail | revisão do diff | nenhum | nenhum | passou |
| R3 Regressão Opp | criação (com `bypassTrigger` no insert) e alteração sem bypass (O6) pela cadeia existente, sem erro | automações como antes | update aceito, 0 cotações CPQ, 0 pedidos nas Opps de teste | passou (parcial) |
| R4 Classes de teste Apex de Opportunity | não executado: nenhuma classe foi alterada pela entrega | — | — | não executado |
| N1 Taxa de ganho por faixa | critério pós go-live, não bloqueia | — | — | não aplicável |

## Não executado
- **V1, ordenação por clique na coluna.** A list view de Lead mostra leads reais copiados; abrir a tela exporia dado real (guardrail 2). A ordenabilidade do campo está confirmada (`sortable=true`) e o `05-roteiro-cliente.md` traz o Teste 8 para o time conferir.
- **R4, testes Apex existentes de Opportunity:** não rodados; a entrega não altera Apex.
- Observação: a seção "Prioridade" vem **recolhida** na página do Lead; é preciso clicar para ver os valores (consta no roteiro).
- Efeito cruzado de preflight: EPLAST-35/-38 (layout de Lead) e EPLAST-30 (`Opportunity_Record_Page`) tocam componentes desta demanda; a seção apareceu corretamente nesta QAS, o conflito é de merge e fica para a revisão.

## O que pode ter saído da org
Criados: 4 Leads, 1 Account e 5 Opportunities `TESTE EPLAST-26`, e uma atribuição temporária do permission set. Nenhuma chamada externa identificada: 0 cotações CPQ e 0 pedidos ligados às Opportunities de teste; Conta criada com `TriggerUtility.bypassTrigger` (sem consulta à BrasilAPI). Não consultei log de integração.
Alterações em registro que não era meu: no usuário da esteira `005bJ00000piKAaQAM` (conta de serviço, regra 6), o campo `ProtheusSellerId__c` ficou `TESTE26` durante o teste (exigido pela validation de proprietário da Conta) e foi devolvido a vazio, como estava antes; perfil, permissões e papel intocados.

## Limpeza (conferida por contagem)
Leads de teste = 0, Opportunities de teste = 0, Accounts de teste = 0, atribuições do permission set = 0, `ProtheusSellerId__c` do usuário = vazio. Nenhum job agendado criado. Nenhuma alteração em registro real.
