**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-31: verificação do build (previsão de vendas por vendedor, região e mês)

Org confirmada com `sf org list`: só `sbx-eplast-dev` (Sandbox, Connected). Nada em QA nem em produção. Só metadata, contagens e agregados de dados sintéticos criados por mim.

## Resumo
Agrupamento por vendedor, região e mês, o bucket "Sem região", os limites de mês, o filtro de tipo de operação (lookup) e o relatório "sem data" funcionam e reconciliam. Nenhum defeito encontrado. Dois pontos não foram provados:

1. **O caminho do filtro de status salvo, com status ativado, não foi exercitado.** Na dev, `Order` só aceita insert em `Revisao de Pedido` (Rascunho). Os outros cinco status (inclusive os três do filtro) dão `FAILED_ACTIVATION` no insert (sonda com rollback). Ativar exige `UPDATE` de status. O `OrderTrigger` (after update) chama `sendOrderToProtheus` para status diferente de `Revisao de Pedido`, e isso é callout ao ERP Protheus. Não há autorização por escrito em `comentarios-do-card.md` para disparar integração externa, então **não disparei**.
   - Alternativa usada: a Analytics API aceita sobrescrever os filtros em tempo de execução (POST com `reportMetadata`, sem salvar). Troquei só o filtro de status para `Revisao de Pedido` e mantive setor, tipo de operação, período, bucket e agrupamentos como estão no relatório salvo. Os relatórios não foram alterados.
2. **Valores com `TotalAmount` diferente de zero e painel com dados não foram provados.** `TotalAmount` é soma dos itens do pedido, e itens exigem o pedido em Rascunho. Os pedidos sintéticos têm `TotalAmount = 0`. Os valores de teste foram dados por `Discount__c` negativo, o que alimenta `Total_com_Desconto__c` (fórmula `TotalAmount - Discount__c`). A coluna `TotalAmount` ficou em 0 em todos os casos.

**O que uma pessoa precisa fazer para fechar:** na QA ou na dev, com autorização do responsável pela conta para a chamada ao Protheus (ou com o ERP isolado), ativar alguns pedidos sintéticos. Depois executar os relatórios salvos e o painel, sem override, e conferir o `TotalAmount`.

## Fixture e isolamento
- Dev estava vazia (0 `Account`, 0 `Order`, 0 `Opportunity`, 0 `Task`, 0 `TypeOperation__c`, `Branch__c` e `ShippingCompany__c`).
- Criado por Apex anônimo na dev: 4 contas `TESTE EPLAST-31 ...`, 10 pedidos (marcador `Description = 'TESTE EPLAST-31 Ox'`, porque `Order` não tem `Name`), 2 `TypeOperation__c`, 1 `Branch__c`, 1 `ShippingCompany__c`.
- Para criar contas sem a chamada à BrasilAPI (`AccountTrigger` after insert) e sem a validação de CNPJ do trigger, o script definiu `TriggerUtility.bypassTrigger = true` em memória, só na transação. Não alterei metadata customizada nem código. `OrderTrigger` só dispara em update, que não foi feito. Nenhum callout rodou.
- Validation rules de `Order` e `Account` (registro para R2): exigiram `ProtheusId__c` na conta, `DeliveryDate__c`, `DispatchBranch__c` (com `CodeERP__c` na filial), `ShippingCompany__c` (com `Code__c`), `Species1__c`, `Volume1__c` e, no tipo de operação, `Code__c`. Preenchidos com valores sintéticos. Nenhum erro de trigger com namespace apareceu.
- Os `TypeOperation__c` tiveram `Name` e `Code__c` iguais a "01" e "04", porque o filtro compara com o nome. São os únicos registros sem o prefixo `TESTE` no nome. Foram apagados.
- Uma sonda de status (com savepoint/rollback depois do insert dos pais) deixou um segundo conjunto de contas, tipos, filial e transportadora e 8 tarefas nas contas de teste. Tudo isso foi apagado.
- Donos das contas: dois usuários internos da dev (A e B), apenas como `OwnerId` das contas de teste.

### Dados de teste (valor = `Total_com_Desconto__c` = -Discount)
| Pedido | Conta (dono) | Previsão | Tipo | Valor | Deve entrar? |
|---|---|---|---|---|---|
| O1 | SP (A) | 31/03/2026 | 01 | 100 | sim, março |
| O2 | SP (A) | 01/04/2026 | 01 | 200 | sim, abril |
| O3 | PR (A) | 15/03/2026 | 01 | 300 | sim, março, SUL |
| O4 | sem estado (B) | 10/03/2026 | 01 | 400 | sim, Sem região |
| O5 | "São Paulo" por extenso (B) | 20/03/2026 | 01 | 500 | sim, Sem região |
| O6 | SP (A) | sem data | 01 | 600 | só no relatório "sem data" |
| O8 | SP (A) | 06/03/2026 | **04** | 800 | não (tipo excluído) |
| O9 | SP (A) | 07/03/2026 | 01 | 900 | sim, março (faz o papel de pedido comum) |
| O10 | SP (A) | 31/12/2025 | 01 | 1000 | não (fora do ano corrente) |
| O11 | SP (A) | 08/03/2026 | sem tipo | 1100 | sim (tipo vazio não é excluído por "diferente de") |

Esperado com o status trocado para `Revisao de Pedido`: total 3.500 (7 pedidos). Dono A 2.600 e dono B 900. SP 2.300, SUL 300, Sem região 900. Março 3.300 e abril 200. Sem data: 600 (O6).

## Casos
| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 Total por vendedor reconcilia | Total por vendedor (design §11.1) | Executei `Previsao_Vendas_Vendedor_Regiao_Mes` via Analytics API, com override só do status | A 2.600, B 900, total 3.500 | A 2.600 (5 pedidos), B 900 (2), total 3.500 (7). A+B = total | passou (com override de status; `TotalAmount` = 0) |
| 2 Limites do mês | Mês (§11.2) | O1 em 31/03 e O2 em 01/04, no relatório por mês e no relatório completo | 31/03 em março, 01/04 em abril | Março 3.300 (6 linhas, inclui O1), abril 200 (1 linha, O2). Março + abril = 3.500 | passou |
| 3 Sem data prevista | PA-19 (§11.3) | Executei `Previsao_Vendas_Sem_Data_Prevista` (override de status) e os relatórios de período | O6 (600) só nele, em nenhum mês | Sem data: dono A, 600, 1 pedido. Os demais não listam O6 (total 3.500 sem ele) | passou |
| 4 Sem região | Região (§11.4) | `Previsao_Vendas_por_Regiao` e o relatório completo, com conta sem estado e conta com "São Paulo" por extenso | Os dois em "Sem região"; SP e PR em regiões certas; soma = total | Sem região 900 (2 pedidos), SP 2.300 (4), SUL 300 (1); soma 3.500. O vazio aparece como "Sem região", não como `-` (risco R4 não ocorreu) | passou |
| 5a Painel sem erro | Painel (§11.5) | `GET` e refresh (`PUT`) do painel `Previsao_de_Vendas` | Nenhum componente com `errorCode` | 5 componentes, `errorCode` nulo em todos. `componentDataStatus` = `NO_DATA`. `dashboardType` = `LoggedInUser` (PA-21) | passou |
| 5b Painel = relatório | Painel (§11.5) | Comparar a métrica do painel com o total de `Previsao_Vendas_por_Mes` | Valores iguais | Só provado o caso vazio: relatórios salvos devolvem 0 pedidos e o painel `NO_DATA`. Com dados não foi possível (item 1 do resumo) | não executado (com dados) |
| 6a Acesso: metadata | PA-20 (§11.6) | Consulta `Group` e `Folder` | Grupo `Comercial_Previsao_Vendas` existe; pastas privadas ao compartilhamento | Grupo existe (Regular, rótulo "Comercial - Previsão de Vendas"). Pastas com `AccessType` = `Hidden`. `FolderShare` não é consultável por SOQL aqui, então o `View` só do grupo vem do plano de build e do XML, não de consulta | passou parcialmente (o compartilhamento não foi confirmado por consulta) |
| 6b Acesso: teste negativo | PA-20 | Logar como usuário fora do grupo | Acesso negado | Não é possível logar como outro usuário na esteira. Fica para o roteiro do cliente | não executado |
| 7 Somente leitura | §11.7 | `COUNT()` de `Order` e `Opportunity` após o seed (10 e 0) e depois de executar os 4 relatórios e o painel | Sem mudança | `Order` 10 e 10; `Opportunity` 0 e 0. `Account` e `Task` só foram contados depois (8 e 8, incluindo a duplicata da sonda), sem leitura "antes" | passou para `Order` e `Opportunity`; `Account` e `Task` sem baseline |
| 8 Sem meta e sem faturado | §11.8 | Li as colunas e os filtros dos 4 relatórios salvos | Só pedido previsto: status, setor, tipo, data, `TotalAmount` e `Total_com_Desconto__c` | Colunas: conta, `OrderNumber`, `ExternalNumber__c`, `Status`, `ExpectedSaleDate__c`, estado, `TotalAmount`, `Total_com_Desconto__c`. Nenhuma meta nem valor faturado | passou |
| 9a Filtro de status (salvo) | PA-16 (§11.9) | Executei os 4 relatórios salvos, sem override, com 10 pedidos em Rascunho | Pedido fora de Liberacao Financeiro, Estoque e Faturamento não entra | 0 pedidos e 0 de valor nos 4 relatórios, embora houvesse 10 pedidos no sistema | passou (só o lado negativo; `Cancelado` não pôde ser criado) |
| 9b Filtro de status (positivo) | PA-16 | Pedido ativado nos três status do filtro | Entra nos totais | Não foi possível ativar sem disparar o Protheus | não executado |
| 9c Filtro de tipo de operação (lookup) | PA-16 | O8 com tipo "04" e O11 sem tipo, com O1 a O5 e O9 tipo "01" | O8 fora; os demais dentro | Março 3.300 = 100+300+400+500+1.100+900, sem os 800 de O8. O filtro por lookup `Order$TypeOperation__c` exclui "04". Os outros 7 códigos da lista não foram testados individualmente | passou para "04" |
| 9d Filtro de setor | PA-16 | Contas com Alimentos, Bebidas e Industrial | Entram | Entraram. Setor "fora da lista" não foi testado: o picklist só tem os 9 valores ativos e o filtro aceita vazio | passou (lado positivo); negativo não executado |
| 9e Filtro de período (ano corrente) | PA-22 | O10 em 31/12/2025 | Fora | Não aparece em nenhum relatório de período (total 3.500 sem os 1.000) | passou |
| 10 Fixture e automação | achados 1 e 10 (§11.10) | Seed de contas e pedidos | Registrar regra ou trigger que falhar | Passou pelas validation rules listadas acima, sem erro de trigger. Triggers de conta isolados (bypass em memória); trigger de pedido não disparou (só insert) | passou |

## Defeitos
Nenhum encontrado nos casos exercitados.

Observação para o QA e o builder, sem ser defeito: o pedido sem `TypeOperation__c` (O11) entra nos totais, porque "diferente de" aceita vazio. É o mesmo comportamento do relatório molde. Se a Eplast achar que pedido sem tipo não deve entrar, ajustar na homologação.

## O que pode ter saído da org
Nada. Nenhum callout foi feito: nenhum `UPDATE` de pedido, nenhum acionamento do Protheus, e a BrasilAPI ficou isolada pelo bypass em memória. Não foi criado log de integração.

## Limpeza
Apagados (Apex anônimo na dev, com contagem posterior): `Order`, `Task`, `Account`, `TypeOperation__c`, `Branch__c`, `ShippingCompany__c`. Contagens finais: todas em 0, como antes. Nada ficou. Relatórios, painel, pastas e grupo não foram alterados.
