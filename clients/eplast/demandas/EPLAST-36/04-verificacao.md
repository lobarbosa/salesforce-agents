**Verificação:** inconclusiva
**Org de teste:** sbx-eplast-dev

# EPLAST-36 — Verificação do build

**Data:** 2026-11-15. `sf org list` mostrou uma única org conectada, a sandbox de alias `sbx-eplast-dev` (tipo Sandbox, Connected). É a "QA" da Eplast usada como dev da esteira (regra 5 da conta). QA da esteira não tocada. Só leitura de metadata e contagens agregadas. Nenhum DML, nenhum registro criado, nada a apagar.

## Por que inconclusiva
A dev tem 0 registros de Account (`SELECT COUNT(Id) FROM Account` devolveu 0). O critério principal (o público retorna só as Contas do filtro, e a contagem bate com um relatório de controle) não pôde ser exercitado com dados. A metadata não mostrou defeito. Não criei massa sintética: não foi pedido, e Account/Contact/Lead têm automação cuja cadeia (inclusive o conector `et4ae5`) não foi isolada nesta verificação.

## O que uma pessoa precisa fazer para provar
1. Carregar massa sintética `TESTE EPLAST-36` na dev (ou executar na QAS com autorização no card): Contas em regiões, setores, `Type` e `LastPurchase__c` variados, com e sem `HasOptedOutOfEmail`.
2. Rodar os relatórios e comparar com a contagem esperada da massa. Cobrir as fronteiras de recência (hoje-90, 91, 180, 181, 365, 366 dias) e Conta sem data de última compra.
3. Atribuir `PS_Marketing_Publicos` a um usuário de teste e confirmar o acesso. Usar um usuário sem o PS para o cenário negativo.
4. Conferir `PRODUTO - CONTAS POR PRODUTO COMPRADO` com Pedidos e itens.

## Casos executados (metadata na dev)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| C01 | Público por região | Analytics REST `describe` dos 58 relatórios da pasta; filtros dos 7 `RECORRENTES (ATIVOS) - <região>` | Filtro por UF por região, mais `TYPE = Recorrente` | CO `GO,DF,MT,MS,TO`; ES; MG; NO/NE (15 UFs); RJ; SP; SUL `PR,SC,RS`; todos com `TYPE = Recorrente` (PA-11). GERAL só `TYPE` e opt-out | passou (metadata) |
| C02 | Público combinando critérios (segmento) | Filtros de `SEGMENTO - ALIMENTOS`, `SEGMENTO - PET`, `LEADS - SEGMENTO - ALIMENTOS` | `Account.Sector__c` / `Lead.Sector__c` = setor, mais opt-out | `Account.Sector__c = Alimentos` e `= PET (Bem-estar animal)`; `Lead.Sector__c = Alimentos`; todos com opt-out falso | passou (metadata) |
| C03 | Histórico de compra | Filtros das 4 faixas e de `COMPRA - ÚLTIMOS 90 DIAS` | Faixas sem lacuna nem sobreposição, Conta sem data fora | ≤90d (`>=` 90 dias atrás até hoje); 91–180 (`<=` 91 e `>=` 180 dias atrás); 181–365 (`<=` 181 e `>=` 365); mais de 365 (`<` 365 dias atrás). Contíguas por construção | passou (metadata) |
| C04 | Inativos | Filtro de `INATIVOS - GERAL` | `TYPE = Inativo` + opt-out | Conforme | passou (metadata) |
| C05 | Opt-out em todos | Procura de `EMAIL_OPT_OUT` nos filtros dos 58 | Presente nos 35 ajustados e nos novos baseados em Contact/Lead | Presente em 57 de 58. Exceção: `PRODUTO - CONTAS POR PRODUTO COMPRADO` (tipo `OrderItemList`, sem filtros). Ver observação 1 | passou com observação |
| C06 | Contagem e duplicado | `SELECT COUNT(Id) FROM Report WHERE FolderName='MARKETING CLOUD'`; consulta por nome | 58 relatórios; `SAZONAIS - MG` duplicado renomeado, não excluído | 58; `SAZONAIS_MG_X7D` = `SAZONAIS - MG (DUPLICADO - REVISAR)`; original `SAZONAIS_MG_Jfz` mantido | passou |
| C07 | Documentação | Descrição dos 58 relatórios | Todos com descrição | 58 de 58 | passou |
| C08 | Não grava em registro | Plano e design sem Flow, Apex nem campo novo; só relatórios e permission set | Nenhuma automação nem campo novo | Consistente com o plano. Não verificado por teste de gravação | passou (por construção) |
| C09 | Acesso respeita perfil (permission set) | Consulta a PermissionSet, ObjectPermissions e FieldPermissions de `PS_Marketing_Publicos` | Leitura em Account, Contact, Lead, Order, Product2; Campaign leitura, criação e edição; RunReports e CreateCustomizeReports; sem ViewAll, ModifyAll nem export; FLS de leitura nos campos de segmento e opt-out | Conforme: Account, Contact, Lead, Order, Product2 só leitura; Campaign R/C/E sem delete; RunReports e CreateCustomizeReports verdadeiros; ViewAllData, ModifyAllData e ExportReport falsos; 8 FLS de leitura (`Sector__c`, `Subsector__c`, `LastPurchase__c`, `Inactive__c` em Account; `Sector__c`, `Subsector__c` em Lead; `et4ae5__HasOptedOutOfMobile__c` em Lead e Contact), sem edição | passou (metadata) |
| C10 | Contagem do relatório = relatório de controle, filtros com dados | Não executado | Resultado igual à massa esperada | Account = 0 na dev | não executado |
| C11 | Acesso negado a usuário sem PS / pasta | Não executado | Usuário sem permissão não vê o público | `PermissionSetAssignment` do PS = 0 (nenhum usuário atribuído); sem usuário de teste | não executado |
| C12 | Relatório de produto com dados | Não executado | Contas por produto comprado, sem valores | Sem Order nem OrderItem de teste | não executado |

## Observações (não são reprovação)
1. `PRODUTO - CONTAS POR PRODUTO COMPRADO` não tem filtro de opt-out nem qualquer filtro. `OrderItemList` não expõe `EMAIL_OPT_OUT`. Se o relatório alimentar envio, o opt-out precisa ser aplicado em outro ponto. Confirmar com o arquiteto.
2. `ObjectPermissions` do PS não lista `OrderItem` (o plano diz que o PS lê OrderItem). O acesso a itens de pedido costuma seguir Order e Product2. Conferir na homologação com um usuário real.
3. `LEADS - NO/NE` não existe (lacuna já registrada pelo builder). Os setores de Lead são 8, não 9 (`Lead.Sector__c` não tem PET), também já declarado.
4. Compartilhamento da pasta `MARKETING CLOUD` e "Usuário de marketing" são passos do administrador (pendências do plano). Não verificados aqui.
5. Faixas de data usam valores relativos (`N_DAYS_AGO`); o comportamento nas fronteiras só se prova com dados.

## Cadeia externa
Nenhum registro foi criado, então nada disparou automação nem saiu da org. "O que pode ter saído da org": nada.

## Dados de teste
Nenhum criado. Nada a apagar. Arquivos temporários só em `/tmp`, fora do repositório.
