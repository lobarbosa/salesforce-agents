**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-36 — Verificação (reverificação)

Org conectada (`sf org list`): alias `sbx-eplast-dev`, usuário de execução da esteira (identificação omitida), sandbox `eplast--qa` (= dev da esteira, regra 5 do CLAUDE.md da conta). Nada em QA, nada no Marketing Cloud, `force-app/` não alterado, sem deploy.

## Divergência do preflight
`00-preflight.md` diz "etapa build" e "a demanda ainda não tem componentes no repositório". No disco há 58 relatórios em `force-app/main/default/reports/MARKETINGCLOUD/` e o permission set `PS_Marketing_Publicos`, no commit a31b0880 da branch `feature/EPLAST-36`. O preflight foi gerado antes do build e está desatualizado. Na org: 58 relatórios na pasta `MARKETING CLOUD` e o PS existe.

## Casos
Dados de teste sintéticos, nome `TESTE EPLAST-36`: 4 Contas (CNPJ sintético com dígito válido, exigido pela validation rule), 5 Contatos (1 com opt-out de e-mail), 3 Leads (1 com opt-out). A org tinha 0 Contas antes. Cada relatório foi executado por `sf api request rest /analytics/reports/<id>?includeDetails=true`.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Público por segmento | `SEGMENTO - BEBIDAS` | C1, C2, C4 (A1, A2, A4 são Bebidas); sem opt-out (C5 fora) | 3 linhas: C1, C2, C4 | passou |
| 2 | Público por segmento (negativo) | `SEGMENTO - ALIMENTOS` | só C3 | 1 linha: C3 | passou |
| 3 | Região + tipo combinados | `RECORRENTES (ATIVOS) - SUL` (PR, SC, RS e TYPE=Recorrente, PA-11) | C1 e C3 (PR, Recorrente); A2 (SP) e A4 (Inativo) fora; C5 (opt-out) fora | 2 linhas: C1, C3 | passou |
| 4 | Inativos | `INATIVOS - GERAL` | só C4 | 1 linha: C4 | passou |
| 5 | Leads por segmento e opt-out (PA-07) | `LEADS - SEGMENTO - BEBIDAS` e `... ALIMENTOS` | L1 em Bebidas (L2 com opt-out fora); L3 em Alimentos | 1 linha (L1); 1 linha (L3) | passou |
| 6 | Opt-out em todos | Casos 1, 3 e 5 com contato e lead que recusaram e-mail | nenhum aparece | C5 e L2 ausentes | passou |
| 7 | Público não grava em registro | Build é só relatório e PS, sem Flow nem Apex; execução do relatório é leitura | nenhum DML pela solução | Nenhum DML além da minha massa. Não comparei campos antes e depois | passou (parcial) |
| 8 | Acesso respeita perfil | Consulta de `PS_Marketing_Publicos` | só leitura nos objetos; Campaign com criar e editar; sem valores de compra | Leitura em Account, Contact, Lead, Order, Product2; Campaign R/C/E; 8 FLS de leitura (Sector, Subsector, LastPurchase, Inactive, Lead.Sector e Subsector, `et4ae5__HasOptedOutOfMobile__c` em Contact e Lead). 0 atribuições | passou |
| 9 | Acesso negado a quem não tem o PS | Executar o relatório com usuário sem o PS | negado ou não aparece | Não executado: só existe o meu usuário de execução, e não altero permissão de outro usuário | não executado |
| 10 | Faixas de recência de compra (PA-04): `COMPRA - ÚLTIMOS 90 DIAS`, `SEM COMPRA` 91-180, 181-365, mais de 365 | Não exercitado. `Account.LastPurchase__c` é um resumo (MAX de Oportunidade), então exige Oportunidades de teste, com a validation rule do proprietário (achado EPLAST-36), e eu não fiz isso | Cada Conta cai em uma só faixa, sem lacuna nem sobreposição | Sem evidência funcional. O filtro só foi lido no XML | não executado |
| 11 | `PRODUTO - CONTAS POR PRODUTO COMPRADO` | Não exercitado: precisa de Pedido e item | Resumo por produto e Conta, sem valores financeiros | Sem evidência | não executado |
| 12 | Contagem igual à do relatório de controle (cenário 1 do critério) | Comparação de contagens por SOQL de controle | igual | Conferido só por identificação dos registros esperados (casos 1 a 5), não por SOQL de controle separado | passou (parcial) |

## Observação para o builder (não é reprovação)
- O plano de build diz que o PS dá leitura em `OrderItem`. A consulta a `ObjectPermissions` do PS devolveu 6 objetos (Account, Campaign, Contact, Lead, Order, Product2), sem `OrderItem`. Pode ser que o campo de item de pedido herde de `Order` (detalhe); não confirmei. Se `PRODUTO - CONTAS POR PRODUTO COMPRADO` não abrir para quem só tem o PS, é este ponto.
- `LEADS - NO/NE` não existe (já declarado no plano como lacuna).

## O que ficou sem prova e o que fazer
Casos 9, 10 e 11. Uma pessoa, ou o QA com massa sintética:
1. Criar Oportunidades de teste (com o proprietário atendendo a validation rule) para as 4 faixas e conferir os 4 relatórios de recência.
2. Criar um Pedido com item e abrir `PRODUTO - CONTAS POR PRODUTO COMPRADO`.
3. Atribuir `PS_Marketing_Publicos` a um usuário de teste de Marketing e abrir os relatórios com e sem o PS.

Os casos executados (segmento, região, tipo, inativos, leads, opt-out) passaram, sem falha.

## Limpeza
Contas, Contatos e Leads `TESTE EPLAST-36` apagados. Contagens finais: Account 0, Contact 0, Lead 0 com esse nome. Nada ficou. Nenhum usuário alterado, nenhum job agendado.

## O que pode ter saído da org
Nada. A cadeia de Account (`AccountTrigger`, `AccountBefore`) rodou na criação das Contas de teste, sem registro externo conhecido. Sem e-mail, callout ou log de integração consultados. Marketing Cloud intocado.
