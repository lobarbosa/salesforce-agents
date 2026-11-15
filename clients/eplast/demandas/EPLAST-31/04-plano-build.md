**Resultado do build:** concluído

# EPLAST-31 — Plano de build: previsão de pedidos por vendedor, região e mês

**Org de build:** `sbx-eplast-dev` (Sandbox, `IsSandbox=true`, Connected). Nada em QA nem em produção.
**Branch:** `feature/EPLAST-31`. Solução declarativa conforme `03-design.md`: sem Flow, Apex, trigger, validation rule ou campo. Nada feito no Marketing Cloud. Relatórios existentes não alterados (PA-23).

## Componentes criados ou alterados (todos implantados na dev)
| # | Tipo | API name | Observação |
|---|---|---|---|
| 1 | ReportType (alterado, só aditivo) | `Pedidos_customizados` | Nova seção "Conta do pedido" com `Account.Owner`, `Account.BillingState`, `Account.Sector__c`. Confirmado pela Analytics API como `Order.Account.Owner.Name`, `Order.Account.BillingState`, `Order.Account.Sector__c`. Descrição existente mantida. |
| 2 | Group | `Comercial_Previsao_Vendas` | Sem membros. O metadata `Group` não tem campo de descrição; ela não pôde ser gravada (desvio do design §4.2). |
| 3 | ReportFolder | `Previsao_de_Vendas` | Shared, só o grupo acima em `View`. |
| 4 | DashboardFolder | `Previsao_de_Vendas_Paineis` | Idem. |
| 5 | Report | `Previsao_de_Vendas/Previsao_Vendas_Vendedor_Regiao_Mes` | Summary: dono da conta, bucket Região, mês de `ExpectedSaleDate__c`. Somas de `TotalAmount` e `Total_com_Desconto__c`. |
| 6 | Report | `Previsao_de_Vendas/Previsao_Vendas_por_Mes` | Summary por mês. |
| 7 | Report | `Previsao_de_Vendas/Previsao_Vendas_por_Regiao` | Summary por bucket Região. |
| 8 | Report | `Previsao_de_Vendas/Previsao_Vendas_Sem_Data_Prevista` | `ExpectedSaleDate__c` vazio, por dono da conta (PA-19). |
| 9 | Dashboard | `Previsao_de_Vendas_Paineis/Previsao_de_Vendas` | `LoggedInUser` (PA-21), sem `runningUser`. 5 componentes: 2 métricas, 2 barras, 1 colunas. |

Filtros comuns (PA-16, copiados do `Previso_de_Pedidos_Perodo_Yko`): status Liberacao Financeiro/Estoque/Faturamento; os 9 setores mais vazio; `TypeOperation__c` diferente dos 8 códigos. Período: `INTERVAL_CURY` (ano corrente) sobre `ExpectedSaleDate__c` (PA-22), aceito pelo deploy e confirmado pela API (`THIS_YEAR`). O relatório "sem data" usa `INTERVAL_CUSTOM` sobre `CreatedDate` (sem limite) para não herdar período.
Bucket Região (§4.4): `text` sobre `Account.BillingState`, 6 regiões, `otherBucketLabel` "Sem região".

## Desvios e sintaxe descoberta
- Em relatório sobre o tipo custom, as colunas são `Order$Campo` e `Order$Account.Campo` (dono = `Order$Account.Owner`, nome da conta = `Order$Account`). O formato `Order.Account.Owner.Name` foi recusado.
- `FolderShare` usa `accessLevel`, não `accessType`.
- Coluna usada como agrupamento não pode estar na lista de colunas (retirei `ExpectedSaleDate__c` das colunas dos relatórios agrupados por mês). Nesses dois relatórios a data aparece pelo agrupamento.
- Componentes Metric exigem `indicatorLowColor` (e demais indicadores) e não aceitam `chartAxisRange`, `showValues`, `showPercentage` nem `enableHover`.
- `TypeOperation__c` neste tipo é lookup: o filtro usa a coluna `Order$TypeOperation__c` (Analytics: `Order.TypeOperation__c.Name`). Os valores ("04", "05"...) foram copiados do molde, que filtra o mesmo campo no tipo `OrderList`; a conferência do efeito exige dado (ver pendências).
- Painel dinâmico: deploy aceito. O limite provável de 5 não bloqueou.

## Conferência feita na dev
- Dry-run e deploy real: sucesso em todos os componentes.
- Analytics API: os 4 relatórios executam sem erro; agrupamentos e filtros conforme o design; os 5 componentes do painel sem `errorCode` (status `NO_DATA`, esperado: a dev tem 0 `Account` e 0 `Order`).
- Painel `LoggedInUser` confirmado pela API.

## Não feito neste build (passa para a verificação)
- **Script de dado sintético e limpeza (`EPLAST31 TESTE`, design §13 passos 7–8):** não criado. Sem dado, não foram provados os casos 1 a 9 da §11: reconciliação por vendedor, limites do mês, "Sem região" (e se o estado vazio vira `-`, risco R4), filtros herdados de status/setor/tipo de operação (inclusive o filtro por `TypeOperation__c` lookup) e igualdade painel × relatório. O verificador deve criar o fixture (preenchendo todas as validation rules de `Account`, `Order` e `OrderItem`, e registrando o namespace do trigger que falhar, R2) e apagar ao final.

## Passos manuais pós-deploy
1. Incluir os gestores comerciais no grupo `Comercial_Previsao_Vendas` (PA-20). Para o QA, um usuário de teste sem "Ver todos os dados" nem "Gerenciar relatórios em pastas públicas".
2. Se "Sem região" aparecer como `-`, renomear na tela e registrar.

## Rollback
Remover o painel, os 4 relatórios, as 2 pastas e o grupo; reverter `Pedidos_customizados` ao XML do baseline (`git revert` do commit).
