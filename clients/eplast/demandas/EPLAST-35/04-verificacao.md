**Verificação:** aprovada
**Org de teste:** sbx-eplast-dev (eplast--qa)

# EPLAST-35 — Verificação do build

Org conferida com `sf org list`: só `sbx-eplast-dev` (Sandbox, Org Id 00DHa000006vfMLMAY, usuário de CLI da sandbox de dev, identificado só pelo alias). Nada na QA da esteira nem em produção. Branch `feature/EPLAST-35`, commit `fe0b211b`, sem alteração. Registros de teste só sintéticos (`TESTE EPLAST-35 ...`, sem CPF, e-mail ou telefone); a dev tinha 0 Leads antes.

## Critérios de aceite usados
A análise (`01-analise.md`, seção 7) dá os cenários de Distribuição de Leads: (a) Lead novo recebe o responsável pela régua; (b) Lead sem critério cai na fila de fallback e nunca fica sem dono; (c) não dispara automação de Account/Opportunity/Order. A régua e o fallback vêm das premissas PA-03 e PA-17 do design (7 regiões por UF + `Leads_Triagem`). Os casos abaixo derivam desses cenários, mais os 7 pontos pedidos para a verificação.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C1 | (a) régua | Lead criado por REST com `Sforce-Auto-Assign: FALSE` (simula integração sem cabeçalho), executado por usuário COM `PS_Integracao_DistribuicaoLead`, 12 UFs: SP, RJ, MG, ES, PR, SC, RS, GO, DF, BA, PE, AM. Consulta após 60-90 s | Dono = fila da região, não o integrador | 12 de 12: SP→Leads SP, RJ→Leads RJ, MG→Leads MG, ES→Leads ES, PR/SC/RS→Leads Sul, GO/DF→Leads Centro-Oeste, BA/PE/AM→Leads Norte e Nordeste. Nenhum ficou com o integrador | passou |
| C2 | (a) só com o PS | Mesmo cabeçalho FALSE, antes de atribuir o PS ao usuário, UF=SP (Lead `SEM-PS SP-FALSE`) | Flow não aplica a regra; dono segue o criador | Dono = o próprio usuário criador (sem o PS), após 60 s | passou |
| C3 | (a) lote | Bulk API (`sf data import bulk`), 200 Leads, 10 UFs, usuário com o PS. Job `750Ha00000Hdg0oIAB` | Sem erro de governador, todos distribuídos | Job JobComplete, 200 processados, 0 falhas. Donos por consulta agregada: Leads Sul 60, Norte e Nordeste 40, SP 20, RJ 20, MG 20, ES 20, Centro-Oeste 20 (soma 200), nenhum com o usuário criador | passou |
| C4 | (b) fallback | UF vazia e UF por extenso ("Sao Paulo"), usuário com o PS | Vão para `Leads_Triagem`, nunca sem dono | Os dois em Leads Triagem | passou |
| C5 | cobertura | `sf apex run test --class-names LeadAssignmentServiceTest --code-coverage` | Testes verdes, >= 85% | 7 de 7 passam; `LeadAssignmentService` 100% (cobertura geral da org 26%, pré-existente) | passou |
| C6 | reaproveitamento | `ProcessDefinition`: AssignPricing (Quote), FinancialAnalysis (Opportunity), LiberationFinancial (Order) | Ativos e inalterados | Os 3 `Active`; `LastModifiedDate` 2026-08-31, 2024-09-04 e 2025-01-29, todas anteriores ao build; `git diff` sem arquivos deles (conforme plano) | passou |
| C7 | relatório | Report `Aprovacoes_Pendentes_Por_Processo` (Summary) consultado e executado pela Analytics API | Existe e executa | Existe; executou com `allData = true`, 0 linhas (dev sem aprovação pendente) | passou |
| C8 | histórico | Contagem de `LeadHistory` com `Field='Owner'` para os Leads de teste | Histórico de dono gravado | 414 linhas (a atribuição fica registrada) | passou |
| C9 | (c) sem efeito colateral | Plano e consulta: Lead tem 0 triggers e 1 Flow ativo (o novo); Account, Opportunity, Order não tocados | Nada além do esperado | Não exercitei conversão de Lead; só confirmado por metadata do plano e pela ausência de erro nos 216 Leads | não executado (parcial, ver abaixo) |

## Observações relevantes
- A API REST, sem o cabeçalho `Sforce-Auto-Assign`, já aplicou a regra nativa por conta própria (Lead `SEM-PS SP`, usuário sem o PS, caiu em Leads SP). Ou seja, o Flow só faz diferença para quem cria Lead sem aplicar a regra (Bulk API, Apex DML, cabeçalho FALSE). Isso não contradiz o design, mas o admin deve saber que integração por REST padrão já é distribuída sem o PS.
- Não há como consultar, pela org, falhas de execução do Flow assíncrono; a ausência de erro de governador está provada pelo resultado: 200 de 200 reatribuídos e 0 falhas no job.

## O que ficou sem prova
- C9: conversão de Lead e ausência de disparo de automação de Account/Opportunity/Order não foram exercitadas. Pelo plano, Lead não tem trigger e só tem o Flow novo; Account/Opportunity/Order não foram tocados.
- O caso "com PS" rodou com o usuário do CLI (Administrador) com o PS atribuído temporariamente, e não com um usuário de integração real. Foram criados dois usuários de teste com o perfil de integração, mas o login por API exigia security token, que não dá para obter sem e-mail. O Flow avalia a custom permission do usuário que cria o Lead, então a via é equivalente, mas um Lead criado de fato pelo usuário de integração da Eplast fica para a homologação.
- Leads de tela (caixa de atribuição no layout) não foram testados: precisa de UI.
- Filas sem membros: o dono ficou na fila; atribuição a vendedores depende do admin incluí-los (passo manual do plano).

## Limpeza
- 216 Leads `TESTE EPLAST-35 ...` apagados (consulta final: 0).
- Atribuição temporária do PS ao usuário do CLI removida (consulta final: 0). Permission set de teste `TESTE_EPLAST35_Acesso` e suas atribuições apagados.
- Ficaram na dev, inativos (usuário não pode ser apagado): dois usuários de teste de integração, identificados pelos IDs `005Ha00000Bd4jlIAB` e `005Ha00000Bd4lNIAR`, ambos com o perfil `Salesforce API Only System Integrations`. O primeiro ainda tem a atribuição do `PS_Integracao_DistribuicaoLead`. Podem ser removidos pelo admin da sandbox.
- Os registros de histórico dos Leads apagados vão para a lixeira junto com eles.
