**Veredito:** reprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-26 — Testes na sandbox de QA

Org conferida com `sf org list`: só `sbx-eplast-qa` conectada (Sandbox, Org Id 00DHa000006vZtmMAE, `eplast--qas`). Nada foi implantado, nada tocado na dev, no Marketing Cloud ou em produção. `05-deploy-qa.md`: deploy `0AfHa00000EHwNhKAL` Succeeded; os 12 componentes existem na org (campos por Tooling, list views por `ListView`, permission set e FieldPermissions por query).

**Método.** A QAS é Partial Copy (712 Leads, 9.327 Opportunities, dado real) e a EPLAST-47 tem teste armado nela até 15/11 21:00 UTC (card). Por isso **não criei, alterei nem apaguei nenhum Lead ou Opportunity**. Provei as fórmulas só com contagens agregadas: para cada combinação de entradas, conto os registros existentes e quantos têm score diferente do esperado (esperado = 0 divergentes). Nenhum valor de registro foi lido nem exibido. Mudança única na org: atribuí o permission set `PS_Comercial_ScorePrioridade` ao usuário da esteira (sem isso os campos são invisíveis na API) e removi a atribuição ao fim (contagem final: 0 atribuições, como estava).

## Falhas

### FALHA 1 (média) — Opportunity: cenários de faixa Alta, score 96 e bordas sem prova de execução
- **Reproduzir:** procurar na QAS Opportunity aberta com score >= 70, ou com `LeadSource` preenchido, ou fechamento em até 60 dias com valor. Resultado das contagens: 0 oportunidades abertas com score >= 70 (2 Média, 87 Baixa); 0 com `LeadSource` preenchido; só 8 com fechamento na janela de 60 dias (Probability 10, sem valor).
- **Obtido:** os cenários da análise "Probability 90 / valor / 30 dias / origem = 96 Alta" (O1), "prazo em 61 dias = 40 Média" (O2), "fechamento exatamente em 60 dias", "55% = 22 pontos" (arredondamento) e "faixa Alta na list view" (V2 com linhas) não têm registro na QAS que os exercite, e não criei registro (ver abaixo). Não há divergência encontrada; falta prova.
- **Esperado:** cada cenário executado com evidência. Critério de aceite principal não executado é reprovado.
- **Por que não executei:** criar Opportunity nesta org passa por 16 validation rules e dispara `OpportunityFlow` (cotação CPQ, possível aprovação e cadeia até o Protheus, design seção 8). O card não traz autorização por escrito para disparar essa cadeia, e a EPLAST-47 não pode ter contagem afetada.
- **Para fechar:** o responsável pela conta autorizar por escrito, no card, a fixture de Opportunity (menor número de registros, `TESTE EPLAST-26` no nome, apagar ao fim, confirmando o endpoint da QAS), ou o time seguir o `05-roteiro-cliente.md` (Testes 5 a 9) com oportunidades de teste. Não é defeito de construção: a fórmula lida da org (Tooling) é idêntica ao design e todo registro existente bate com ela.

## Casos

| Caso | Passos (evidência) | Esperado | Obtido | Status |
|---|---|---|---|---|
| L1 Lead setor+origem+Contatado | `COUNT` Lead com Sector, LeadSource e Status Contatado = 54; com score != 100 ou faixa != Alta | 100 / Alta, 0 divergentes | 54 registros, 0 divergentes | passou |
| L2 Lead só com setor, não contatado | COUNT = 58; divergentes de 30/Baixa | 0 divergentes | 58, 0 | passou |
| L3 Lead sem setor e sem origem | COUNT = 305; divergentes de 0/"Sem dados suficientes" | 0 divergentes | 305, 0 | passou |
| L4 Mudança de status (60 Média -> 100 Alta) | Mesmo lead não alterado (sem DML). Grupo setor+origem não contatado: 101, 0 divergentes de 60/Média; grupo Contatado: L1 (100/Alta). Fórmula depende só dos campos | 60/Média e 100/Alta | confirmado por equivalência, sem alterar registro | passou (por equivalência) |
| L5 Lead só com origem (extra) | Existente na QAS: não medido | — | — | não executado |
| L6 Lead convertido mantém score (PD-05) | COUNT convertidos com setor e origem = 71; com score != 100 = 0 | 100 | 71, 0 divergentes | passou |
| O1 Opp 90% / valor / 30 dias / origem | sem registro; sem DML | 96 / Alta | — | **não executado** |
| O2 Opp 50% / valor / 61 dias / sem origem | 0 registros | 40 / Média | — | **não executado** |
| O3 Opp 10% / sem valor / longe / sem origem | 0 registros com data >= +61 dias nesta combinação | 4 / Baixa | Equivalente com fechamento vencido: 15 registros, 0 divergentes de 4 | passou (por equivalência, bate com PD-03) |
| O3b Pontuação por combinação (Probability 10 a 50, valor, janela, origem) | 9 combinações com registros, 112 oportunidades abertas cobertas por contagem de divergentes (p10 janela: 8; p10 vencida: 15; p15: 36 e 11; p20: 11; p25: 2; p30: 1; p40: 3; p50: 2) | 0 divergentes | 0 divergentes em todas | passou |
| O4 Oportunidade encerrada | IsClosed = 9.238 (Fechado/Ganho 7.454, Fechado/Perdido 1.784); divergentes de "Encerrada"/0 = 0; abertas com "Encerrada" = 0 | 0 divergentes | 0 / 0 | passou (não havia "Closed Won/Lost" na QAS) |
| O5 PD-03 vencida sem ponto de prazo | 15 abertas vencidas sem valor/origem p=10, score 4 | 4 | 0 divergentes | passou |
| O5b Fechamento exato em +60 dias; 55% = 22 | 0 registros | ponto de prazo; 22 | — | **não executado** |
| O-F Fórmulas (leitura Tooling na QAS) | `CustomField.Metadata` de `Opportunity.PriorityScore__c` e `PriorityBand__c` | igual ao design 4.2 | idêntica (ROUND, BLANKVALUE, 0 a 60 dias, IsClosed, 70/40) | passou |
| Faixas Opp | 0 abertas com faixa inconsistente com o score; 0 Alta, 2 Média, 87 Baixa | consistente | 0 divergentes | passou (só Média e Baixa exercitadas) |
| S1 Campos somente leitura | `sf sobject describe` Lead e Opportunity | `calculated=true`, `updateable=false` | os 4 campos assim; `sortable=true` | passou |
| P1 Permission set | FieldPermissions do `PS_Comercial_ScorePrioridade` | 4 campos só leitura | 4 linhas, Read=true, Edit=false; 0 atribuições antes e depois | passou |
| V1 List view ordena por score (Lead) | Existe `Leads_Abertos_Prioridade`; campos `sortable=true`. Clique na coluna: não exercitado (tela só tem dado real) | ordem decrescente | só a ordenabilidade confirmada | não executado (tela) |
| V2 Lista filtra por faixa Alta (Opp) | `Oportunidades_Prioridade_Alta` existe; sem oportunidade Alta para ver linhas | só Alta | — | não executado (ver FALHA 1) |
| V3 `Oportunidades_Abertas_Prioridade` | existe | existe | existe | passou (existência) |
| R1 Sem trigger, Flow ou Apex | `git diff main --stat -- force-app`: 12 arquivos (campos, layouts, flexipages, list views, permission set) | só isso | idem; 0 ApexTrigger em Lead na QAS | passou |
| R2 Sem callout, e-mail ou integração | revisão do diff | nenhum | nenhum | passou |
| R3 Regressão de Opportunity e testes Apex | não executado: exige criar/alterar Opportunity e disparar a cadeia (sem autorização) | automações como antes | — | não executado |
| N1 Taxa de ganho por faixa | critério pós go-live, não bloqueia (design R5) | — | — | não aplicável |
| UI: seção "Prioridade" na página, Three_Column | Tela só abre com registro real; não aberta (guardrail 2) | — | — | não executado (ver roteiro) |

## Não testável / não provado
- Telas (seção "Prioridade" na página, ordenação por clique, atribuição de `Opportunity_Record_Page_Three_Column`, B0 dev x QA): dev e QA têm Org Ids diferentes (00DHa000006vfMLMAY e 00DHa000006vZtmMAE), então B0 está resolvido. O restante só abre com dado real na QAS e fica no roteiro do cliente.
- Pendência de administrador: atribuir `PS_Comercial_ScorePrioridade` aos usuários reais (PD-07). Sem isso os campos ficam invisíveis para quem lê.

## O que pode ter saído da org
Nada. Nenhum registro de negócio criado ou alterado, nenhuma chamada externa. Só a atribuição temporária do permission set ao usuário da esteira, já removida.
