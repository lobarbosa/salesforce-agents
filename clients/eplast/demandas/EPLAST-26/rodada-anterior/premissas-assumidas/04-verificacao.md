**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# EPLAST-26 — Verificação do build (dev)

Org conferida com `sf org list`: só `sbx-eplast-dev` (Sandbox, Connected, Org Id final `...vfMLMAY`). Nada fora da dev. `force-app/` não alterado. Dados sintéticos `TESTE EPLAST-26`, todos apagados (seção final).

## Casos (derivados dos critérios de `01-analise.md`)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| L1 | Lead setor+origem+Contatado | Apex anônimo cria Lead; `SELECT PriorityScore__c, PriorityBand__c` | 100 / Alta | 100 / Alta | passou |
| L2 | Lead só setor, "Aberto - Não contatado" | idem | 30 / Baixa | 30 / Baixa | passou |
| L3 | Lead sem setor e origem, Contatado | idem | 0 / Sem dados suficientes | 0 / Sem dados suficientes | passou |
| L4 | Mudança de status atualiza score | Lead com setor+origem "Aberto - Não contatado" (60 / Média); `sf data update` Status=Contatado; reconsulta | 100 / Alta | 60 / Média antes; 100 / Alta depois | passou |
| O1 | Opp Prob 90, Amount>0, +30 dias, origem | Apex cria Opp (RT Indústria); consulta | 96 / Alta | 96 / Alta | passou |
| O2 | Opp Prob 50, +61 dias, sem origem | idem | 40 / Média | 40 / Média | passou |
| O3 | Opp Prob 10, Amount 0, +200 dias | idem | 4 / Baixa | 4 / Baixa | passou |
| O4 | Opp encerrada (Fechado/Perdido, IsClosed=true) | idem | 0 / Encerrada | 0 / Encerrada | passou |
| O5 | Borda 60 dias, Prob 55 (22 pontos, PD-04) | Opp com CloseDate hoje+60 | 22+20+20 = 62 / Média | 62 / Média | passou |
| O6 | Reabrir após alteração (regressão leve) | `sf data update` em Opp sem bypass: Amount=500, StageName=Análise Técnica (Prob 20), CloseDate +16 dias | 8+20+20 = 48 / Média; update aceito com triggers e Flows ativos | 48 / Média; update aceito | passou |
| S1 | Campos somente leitura | `sf data update` de `Lead.PriorityScore__c`, `Opportunity.PriorityBand__c` | Escrita recusada | "Unable to create/update fields ... read/write" | passou |
| V1 | List view Lead filtra abertos e inclui score/faixa | REST `listviews/Leads_Abertos_Prioridade/results` | 4 leads de teste com score e faixa | 4 registros, colunas de score e faixa presentes | passou |
| V2 | List view Opp filtra faixa Alta | REST `Oportunidades_Prioridade_Alta/results` | só faixa Alta | só O1 (96 / Alta) | passou |
| V3 | List view Opp abertas exclui encerrada | REST `Oportunidades_Abertas_Prioridade/results` | O1, O2, O3, O5 sem O4 | exatamente esses 4 | passou |
| V4 | Lista ordena por score (clique na coluna) | REST com `orderBy=PriorityScore__c&order=desc`; colunas `sortable` | ordem 100, 30, 0 | `PriorityScore__c` aparece como coluna ordenável, mas o endpoint REST devolveu a mesma ordem para asc e desc (ordenação do parâmetro não refletida). Clique na tela não exercitado | não executado |
| D1 | Sem trigger, Flow, Apex, e-mail, callout, Named Credential | `git diff --name-status main...HEAD -- clients/eplast/force-app` | só campos, list views, permission set, layouts, flexipages | 12 componentes, todos desses tipos; nenhum ApexTrigger, ApexClass, Flow ou email alert; automações de Opportunity sem diff | passou |
| R1 | Regressão: criar e alterar Opp com automações existentes | Criação com `TriggerUtility.bypassTrigger=true` (preciso para o Account/Opp passar sem consulta externa) e alteração sem bypass (O6) | automações executam como antes | alteração aceita pela cadeia (OpportunityTrigger, Flows ativos); sem erro | passou (parcial: criação com bypass) |
| R2 | Classes de teste Apex existentes de Opportunity passam | não executado | — | não rodei `sf apex run test` (risco de DML em cadeia e tempo; nenhuma classe foi alterada) | não executado |
| T1 | Seção "Prioridade" na tela; `Opportunity_Record_Page_Three_Column` | exige interface | — | não exercitado (sem UI). Dynamic Forms confirmados em metadata no plano de build | não executado |
| N1 | Taxa de ganho por faixa | critério de negócio pós go-live | — | fora do escopo da dev | não executado |

## Premissas assumidas usadas
PA-01/PA-03/PA-13 (pesos e campos) e PD-03 a PD-05 (fechamento vencido não pontua, `ROUND`, `IsConverted`): os valores esperados acima vêm dessas premissas, e batem. Nenhuma foi motivo de reprovação.

## Dependências e observações
- Dev e QA são orgs distintas (card de 15/11; Org Id final `...vfMLMAY` na dev). B0 resolvido.
- Conflitos de preflight: EPLAST-30 (`Opportunity_Record_Page`) e EPLAST-35 (`Lead-Lead Layout`) tocam componentes que esta demanda também alterou. Não alterei nada; o conflito é de merge e precisa ser visto na revisão do PR.
- `Opportunity-CPQ Opportunity Layout` (pacote SBQQ) não foi alterado, como declarado no plano.
- Permission set `PS_Comercial_ScorePrioridade`: atribuído só ao usuário da esteira. A atribuição aos perfis da PD-07 continua passo do administrador em cada org.
- Fixture montada e gravada: `clients/eplast/fixtures/lead.apex` e `opportunity.apex` (não existia pasta `fixtures/`).

## Ajuste temporário de usuário (usuário de execução, só dev)
`User` `005bJ00000piKAaQAM`, campo `ProtheusSellerId__c`: antes vazio (null), durante `TESTE26` (exigido pela validation `CheckAccountOwnerHasProtheusSellerId`), depois vazio de novo (conferido por consulta). Perfil, permissão e papel intocados. Esse usuário é a conta de serviço da Konecta (identificada pelo Id acima, conforme regra 6 do briefing) e também o executor do job.

## O que pode ter saído da org
Nada. Os Leads, a Account e as Opportunities foram criados com triggers de Account e Opportunity desviados, e a consulta posterior mostrou 0 `SBQQ__Quote__c` ligadas às Opportunities de teste. Nenhum callout, pedido ou log de integração identificado. Não consultei objetos de log de integração além da cotação e de Order (0 de teste).

## Limpeza
Apagados por Apex: 4 Leads, 5 Opportunities, 1 Account. Consulta final: 0 de cada, 0 cotações de teste. Nada ficou. Nenhum job Apex agendado criado.

## O que ficou sem prova
- Ordenação por clique na coluna de score (V4) e aparência da seção "Prioridade" nas páginas Lightning (T1): exigem a tela. Quem homologa confere nos Testes do `05-roteiro-cliente.md`.
- R2, classes de teste Apex de Opportunity: não executadas. Nenhuma classe foi alterada nesta demanda.
- N1, taxa de ganho por faixa: só mede depois do go-live.
