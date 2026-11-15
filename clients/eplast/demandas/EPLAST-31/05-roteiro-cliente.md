# EPLAST-31 — Roteiro de teste: previsão de vendas por vendedor, região e mês

Foi entregue uma pasta de relatórios e um painel de Previsão de Vendas, que mostram os pedidos com "Data previsão de vendas" somados por vendedor, região e mês, sem montar a conta à mão. Os relatórios só leem dados: não alteram nenhum pedido. Quem usa passa a ver a previsão em um lugar só.

**Situação do teste automático:** o time já comprovou, em dados de teste criados na QAS, a soma por vendedor, o limite de mês (31/03 em março, 01/04 em abril), o grupo "Sem região", o relatório de pedidos sem data, que o painel e o relatório mostram o mesmo total e que consultar não altera pedidos. Ficaram para quem segue este roteiro: o bloqueio de acesso para quem não está no grupo (o time não consegue entrar como outro usuário) e a conferência com pedidos reais ativados (o time não ativou pedidos para não acionar a integração com o ERP Protheus).

## Antes de começar
- Ambiente: sandbox de QA da Eplast (QAS).
- Perfil: use um usuário que esteja no grupo "Comercial - Previsão de Vendas" para os Testes 1 a 5 e 7. Para o Teste 6 use um usuário comercial que **não** esteja no grupo e que **não** tenha "Ver todos os dados" nem "Gerenciar relatórios em pastas públicas".
- Se o grupo estiver vazio, peça ao administrador para incluir o usuário de teste em Configuração > Grupos Públicos > Comercial - Previsão de Vendas.
- Dado de teste: crie 3 contas com nome começando por "TESTE EPLAST-31": uma com estado de cobrança SP, uma com PR e uma sem estado, todas com setor Alimentos. Em cada uma, crie pedidos com "Data previsão de vendas" em 31/03, 01/04 e 15/03 do ano corrente e um pedido sem data, e avance o status para "Liberacao Financeiro" (os relatórios só consideram pedidos nos status Liberação Financeiro, Liberação Estoque e Faturamento). Use tipo de operação diferente dos tipos excluídos.
- Ao terminar, apague as contas e pedidos de teste.

## Teste 1 — Total por vendedor
1. Abra Relatórios e a pasta "Previsão de Vendas".
2. Abra o relatório "Previsão Vendas Vendedor Região Mês".
3. No filtro de data, escolha março do ano corrente.
4. Some, à mão, os valores dos pedidos de teste de cada proprietário.

**Resultado esperado:** o total de cada proprietário é igual à sua soma, e a soma dos proprietários é igual ao total geral do relatório.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Limites do mês
1. No mesmo relatório, deixe o filtro em março.
2. Procure o pedido com data 31/03 e o de 01/04.

**Resultado esperado:** o pedido de 31/03 aparece em março e o de 01/04 não aparece em março (aparece em abril ao trocar o filtro).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Pedido sem data prevista
1. Abra o relatório "Previsão Vendas Sem Data Prevista".
2. Abra depois o relatório "Previsão Vendas por Mês".

**Resultado esperado:** o pedido sem data aparece só no primeiro relatório e em nenhum mês do segundo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Conta sem estado
1. Abra o relatório "Previsão Vendas por Região".
2. Localize a conta de teste sem estado de cobrança.

**Resultado esperado:** o valor aparece na linha "Sem região", e a soma de todas as regiões é igual ao total geral. A conta de SP aparece na região SP e a de PR na região SUL.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Painel e relatório mostram o mesmo total
1. Abra Painéis e a pasta "Previsão de Vendas - Painéis" (painel "Previsão de Vendas").
2. Anote o valor de "Total previsto no período".
3. Abra "Previsão Vendas por Mês" com o mesmo período e anote o total.
4. Confirme que nenhum componente do painel mostra mensagem de erro.

**Resultado esperado:** o valor do painel é igual ao total do relatório, e os 5 componentes (Total previsto no período, Previsão por região, Pedidos sem data prevista, Previsão por mês, Previsão por vendedor) abrem sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Quem não está no grupo não vê a previsão
1. Entre com o usuário comercial que não está no grupo (e sem as duas permissões descritas acima).
2. Procure por "Previsão de Vendas" em Relatórios e em Painéis.
3. Cole o endereço direto de um dos relatórios no navegador.

**Resultado esperado:** a pasta não aparece na lista e o acesso direto é negado. Atenção: usuários com "Ver todos os dados" ou "Gerenciar relatórios em pastas públicas" veem a pasta de qualquer forma.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Consultar não altera nada
1. Antes do teste, anote quantos pedidos existem (relatório de Pedidos, total).
2. Abra, filtre e exporte os relatórios da previsão.
3. Conte os pedidos de novo.

**Resultado esperado:** a quantidade de pedidos é a mesma.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Não há meta nem faturado
1. Abra cada relatório e o painel e leia colunas, filtros e títulos.

**Resultado esperado:** só há dados de pedido previsto (conta, número, status, data prevista, estado, valor). Não há meta nem valor faturado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Quais pedidos entram
1. Confira que um pedido em Rascunho, ou em status fora de Liberação Financeiro, Liberação Estoque e Faturamento, não aparece nos relatórios.
2. Confira que um pedido nesses três status aparece.

**Resultado esperado:** só entram pedidos nesses três status, de contas dos 9 setores listados e sem os tipos de operação excluídos, com data prevista no ano corrente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Região (PA-05):** a região é o agrupamento do estado de cobrança da conta nas 6 regiões que a Eplast já usa (CO, MG, NO/NE, RJ/ES, SP, SUL). "DIRETA" não é região, é carteira. Confirme os agrupamentos.
- **Quais pedidos contam (PA-16):** os mesmos critérios do relatório "Previsão de Imputados Período" (status, setores e tipos de operação). Confirme que o total novo bate com o que o comercial já vê.
- **Vendedor (PA-04/17):** é o proprietário da conta, não do pedido.
- **Valor (PA-18):** soma do valor total do pedido. "Total com indenização" aparece ao lado, só para informação.
- **Data previsão de vendas (PA-02):** assumimos que é a data em que o comercial espera vender o pedido. Confirme o significado do campo.
- **Pedidos sem data (PA-19):** ficam em relatório e componente à parte, não em linha do relatório por mês.
- **Quem vê (PA-20):** só quem estiver no grupo "Comercial - Previsão de Vendas". O grupo começa vazio: o administrador da Eplast inclui os gestores comerciais. Confirme quem entra.
- **Painel (PA-21):** mostra os dados conforme o usuário que o abre, e usa a última vaga provável de painel desse tipo na org; a EPLAST-32 deve acrescentar componentes a ele.
- **Período (PA-22):** o relatório abre com o ano corrente, e o filtro pode ser mudado.
- **Fórmula (PA-03):** soma simples, sem ponderar por probabilidade. Meta e faturado ficam fora desta versão.

## O que não dá para conferir pela tela
- Execução dos relatórios com a API, contagens antes e depois e limpeza dos dados de teste: evidência em `05-testes.md`.
- Ativação de pedidos reais com integração ao ERP Protheus: não foi feita pelo time para não acionar o ERP.
