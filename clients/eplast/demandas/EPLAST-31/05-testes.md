**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-31 — Testes na sandbox de QA (previsão de pedidos por vendedor, região e mês)

Org confirmada com `sf org list`: `sbx-eplast-qa` (Sandbox, Connected, `eplast--qas`, Partial Copy). Nada em produção. Só contagens agregadas e registros sintéticos criados por mim (`TESTE EPLAST-31`). Nenhum registro real foi lido ou alterado, nenhum screenshot foi tirado (não houve uso de `qa_browser_*`: os casos foram exercitados pela Analytics API e por consultas de contagem).

## Falhas
Nenhuma falha que bloqueie o aceite. Dois pontos não foram exercitados (casos 6b e 9b abaixo) e seguem para o roteiro do cliente. Não são falhas do build.

## Pacote implantado (05-deploy-qa.md, deploy `0AfHa00000EHwM5KAL`, Succeeded)
Todos existem na org: 4 relatórios (`Previsao_Vendas_por_Mes`, `_por_Regiao`, `_Sem_Data_Prevista`, `_Vendedor_Regiao_Mes`, confirmados por SOQL em `Report`), painel `Previsao_de_Vendas` (tipo `LoggedInUser`), pastas `Previsao_de_Vendas` (relatórios) e `Previsao_de_Vendas_Paineis` (painel), ambas `AccessType = Hidden`, grupo `Comercial_Previsao_Vendas`. O tipo de relatório `Pedidos_customizados` é o que os 4 relatórios usam (executaram sem erro).

## Fixture (criado por Apex anônimo na QA, apagado ao final)
3 contas `TESTE EPLAST-31 ...` (SP, PR, sem estado; setores Alimentos, Bebidas, Industrial; dois proprietários internos, citados como A e B), 5 pedidos em status `Revisao de Pedido`, 1 filial, 1 transportadora, 1 tipo de operação (`TESTE EPLAST-31 01`). Contas criadas com `TriggerUtility.bypassTrigger = true` em memória (evita a chamada à BrasilAPI do trigger de conta); nenhuma metadata foi alterada. Valores dados por `Discount__c` negativo (alimenta `Total_com_Desconto__c`), porque `TotalAmount` fica 0 em pedido sem item.

| Pedido | Conta (dono) | Previsão | Valor | Deve entrar |
|---|---|---|---|---|
| O1 | SP (A) | 31/03/2026 | 100 | março |
| O2 | SP (A) | 01/04/2026 | 200 | abril |
| O3 | PR (A) | 15/03/2026 | 300 | março, SUL |
| O4 | sem estado (B) | 10/03/2026 | 400 | março, Sem região |
| O5 | SP (A) | sem data | 600 | só no relatório "sem data" |

Leitura: Analytics API (`POST /analytics/reports/<id>`), sobrescrevendo em tempo de execução só o filtro de status (para `Revisao de Pedido`) e acrescentando o filtro "nome da conta começa com TESTE EPLAST-31", para que nenhum dado real entrasse na leitura. Os relatórios salvos não foram alterados. As demais restrições (setor, tipo de operação, período do ano corrente) ficaram como estão no relatório salvo.

## Casos
| Caso | Critério (01-analise.md §4) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Total por vendedor reconcilia | `Previsao_Vendas_Vendedor_Regiao_Mes` com override | A = 600 (3 pedidos), B = 400 (1), geral = 1.000 | A 600 (3), B 400 (1), geral 1.000 (4 pedidos). A+B = geral | passou |
| 2 | Limites do mês | Mesmo relatório e `Previsao_Vendas_por_Mes` | 31/03 em março; 01/04 em abril | Março 800 (3: O1, O3, O4), abril 200 (1: O2). Março + abril = 1.000 | passou |
| 3 | Sem data prevista (PA-19) | `Previsao_Vendas_Sem_Data_Prevista` e relatórios de período | O5 (600) só no relatório "sem data" e em nenhum mês | Sem data: 600, 1 pedido (dono A). Os relatórios de período somam 1.000 sem o O5 | passou |
| 4 | Sem região | `Previsao_Vendas_por_Regiao` | Conta sem estado em "Sem região"; SP e PR em regiões certas; soma = total | Sem região 400 (1), SP 300 (2), SUL 300 (1). Soma 1.000 = geral. O vazio aparece como "Sem região", não como `-` | passou |
| 5a | Painel sem erro | `GET` do painel `Previsao_de_Vendas` | Nenhum componente com `errorCode` | 5 componentes (Total previsto no período, Previsão por região, Pedidos sem data prevista, Previsão por mês, Previsão por vendedor); `errorCode` nulo em todos; `dashboardType` = `LoggedInUser` | passou |
| 5b | Painel = relatório | Dados reais da QA, sem override, comparando só por script (valor nunca gravado aqui). Painel x agregado `TotalAmount` do relatório salvo | Iguais | Total previsto, Previsão por região, Previsão por mês e Previsão por vendedor: **iguais ao total do relatório `Previsao_Vendas_por_Mes`: sim**. "Pedidos sem data prevista" iguais ao total de `Previsao_Vendas_Sem_Data_Prevista`: sim (0 pedidos) | passou |
| 6a | Acesso: configuração (PA-20) | Retrieve das duas pastas da org; SOQL em `Group`, `GroupMember`, `Folder` | Pastas compartilhadas só com o grupo, nível View; pasta oculta ao compartilhamento amplo | Retrieve da org: as duas pastas com `sharedTo` = `Comercial_Previsao_Vendas`, `sharedToType` = Group, `accessLevel` = View, e nenhum outro compartilhamento. Pastas `AccessType = Hidden`. Grupo existe, 0 membros (como projetado: o admin Eplast inclui os gestores) | passou |
| 6b | Acesso negado a usuário fora do grupo | Exigiria logar como usuário comercial sem "Ver todos os dados" e sem "Gerenciar relatórios em pastas públicas" | URL direta negada, relatório fora da lista | A esteira não permite logar como outro usuário | não executado. Segue no roteiro do cliente (Teste 6). Design §11.6 já prevê isso |
| 7 | Consulta não altera registros | `COUNT()` antes do seed, depois de executar relatórios e painel, e depois da limpeza | Sem alteração por consulta | Antes: Order 10.320, Opportunity 9.327, Account 1.217, Task 8.537. Depois do seed (+5 Order, +3 Account, +3 Task criadas pela automação de criação de conta) e das consultas: 10.325, 9.327, 1.220, 8.540. Depois da limpeza: 10.320, 9.327, 1.217, 8.537, igual ao inicial. As consultas em si não mudaram nada (a diferença é exatamente o fixture) | passou |
| 8 | Sem meta e sem faturado | Metadata dos 4 relatórios e do painel | Só pedido previsto | Colunas: conta, número do pedido, número externo, status, data prevista, estado, `TotalAmount`, `Total_com_Desconto__c`. Componentes do painel só de previsão. Nenhuma meta nem faturado | passou |
| 9a | Filtros herdados (PA-16): status | Relatórios salvos, sem override, com pedidos sintéticos em Rascunho | Pedido em Rascunho não entra | Os relatórios salvos não incluíram os pedidos sintéticos (agregados por conta TESTE = 0 no painel e relatórios salvos; ver caso 5b). Com os dados reais da QA, os relatórios salvos retornam 67 pedidos (contagem, sem valores), o que mostra que o filtro de status positivo seleciona pedidos reais ativados | passou (lado negativo e leitura positiva por contagem agregada) |
| 9b | Filtro de status: ativar pedido sintético | Exigiria `UPDATE` de status, que aciona `OrderTrigger` → `sendOrderToProtheus` (callout ao ERP) | Pedido entra | Sem autorização por escrito em `comentarios-do-card.md` para disparar o Protheus, não ativei | não executado |
| 9c | Filtro de tipo de operação | Pedidos com tipo `01` sintético | Entram (tipo não está na lista de excluídos) | Entraram (O1 a O4) | passou. Tipos excluídos não testados individualmente na QA (cobertos na dev, `04-verificacao.md` caso 9c) |
| 9d | Filtro de setor / período | Setores Alimentos, Bebidas, Industrial; período ano corrente (`THIS_YEAR` 2026) | Entram | Entraram | passou. Setor fora da lista não testado |
| 10 | Fixture e automação (achados 1 e 10 do assessment) | Seed de contas e pedidos na QA | Registrar regra/trigger que falhar | Passou pelas validation rules de `Order` e `Account` (exigem `ProtheusId__c`, `DeliveryDate__c`, filial com `CodeERP__c`, transportadora com `Code__c`, `Species1__c`, `Volume1__c`) sem erro de trigger. Criar contas gerou 3 tarefas automáticas (uma por conta; removidas junto das contas). Triggers de conta isolados pelo bypass em memória; `OrderTrigger` só dispara em update, não executado | passou |

## O que pode ter saído da org
Nenhuma chamada externa: bypass dos triggers de conta (BrasilAPI) e nenhum update de pedido (Protheus). 3 tarefas internas criadas pela automação de conta, apagadas com o fixture. Limpeza conferida: 0 contas `TESTE EPLAST-31`, contagens iguais às iniciais.

## Premissas assumidas (design §7)
Testado conforme PA-05, 16, 17, 18, 19, 20, 21, 22. Nenhuma foi motivo de reprovação. A PA-21 (painel dinâmico) foi criada sem erro de limite na QA.

## Fora do escopo desta sessão
- Teste negativo de acesso com usuário real (6b) e ativação de pedido (9b), descritos acima.
- Acurácia da previsão (PA-13), fora da v1.
- O painel não foi aberto pela tela (sem screenshot); foi exercitado pela API.
