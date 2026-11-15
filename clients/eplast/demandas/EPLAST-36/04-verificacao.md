**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (sandbox de dev da esteira, apontando para a sandbox `eplast--qa` da Eplast, regra 5 do CLAUDE.md da conta; usuário de serviço da conta omitido)

# EPLAST-36 — Verificação (reverificação)

`sf org list` mostrou um único alias, `sbx-eplast-dev`, Sandbox, Connected. Nada em QA, nada em produção, nada no Marketing Cloud. Não alterei `force-app/`.

## Existência dos componentes na dev
- Pasta `MARKETING CLOUD`: 58 relatórios (`SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'` = 58, igual ao plano de build).
- `PS_Marketing_Publicos` existe. Objetos: leitura em Account, Contact, Lead, Order, Product2; Campaign com leitura, criação e edição; sem delete e sem modificar tudo. FLS de leitura (sem edição) em `Account.Sector__c`, `Subsector__c`, `LastPurchase__c`, `Inactive__c`, `Lead.Sector__c`, `Lead.Subsector__c` e `et4ae5__HasOptedOutOfMobile__c` (Contact e Lead). `RunReports` e `CreateCustomizeReports` ligados, `ModifyAllData` e `ViewAllData` desligados. Nenhum campo de valor de compra.
- Observação: a org não devolve linha de `ObjectPermissions` para `OrderItem` neste PS (o XML do repositório a declara). Em Salesforce o acesso a OrderItem segue o de Order, e o relatório de produto rodou com sucesso na dev, então não tratei como falha. Vale conferir com um usuário de Marketing na homologação.
- `SAZONAIS - MG` e `SAZONAIS - MG (DUPLICADO - REVISAR)` coexistem (2 relatórios, nenhum excluído).

## Dados de teste (sintéticos, `TESTE EPLAST-36`)
`clients/eplast/fixtures/` não existia. Montei e gravei três scripts que funcionaram na dev: `conta-oportunidade-ganha.apex`, `lead-segmento.apex` e `pedido-com-produto.apex`.
- A dev tinha 0 Contas e 0 Leads (contagem agregada), então a massa é toda minha.
- A Oportunidade Fechado/Ganho (necessária porque `Account.LastPurchase__c` é rollup MAX de `Opportunity.CloseDate` em Fechado/Ganho) exigiu: `Account.Owner.ProtheusSellerId__c` preenchido, Filial com `CodeERP__c`, Prazo de pagamento, forma de pagamento e análises fiscal e financeira. Usei record type Indústria e `TriggerUtility.bypassTrigger = true` para não disparar integração.
- Campo temporário no meu usuário de execução (`005bJ00000piKAaQAM`, só na dev): `ProtheusSellerId__c` antes = vazio; durante = `TESTE36`; depois = vazio (conferido por consulta).
- Massa: 5 Contas (A1 Recorrente/SP/Alimentos/última compra há 30 dias; A2 Recorrente/MG/Bebidas/120; A3 Inativo/SP/Alimentos/200; A4 Sazonal/RJ/Industrial/400; A5 Recorrente/SP/Alimentos/sem compra), 6 Contatos (A1 tem um 2º com opt-out de e-mail), 3 Leads (L1 SP/Alimentos; L2 SP/Alimentos com opt-out; L3 MG/Bebidas), 1 Pedido com 1 item de 1 Produto.
- Execução dos relatórios: `GET /analytics/reports/<id>?includeDetails=true` via `sf api request rest`. Conferi os nomes e as contagens devolvidos.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Público por região | Rodei `RECORRENTES (ATIVOS) - SP` (`Cpia_de_RECORRENTES_ATIVOS_SP_hLD`) e `- MG` | SP: A1 e A5 (Recorrente em SP); MG: A2 | SP = A1, A5; MG = A2 | passou |
| 2 | Região com tipo (PA-11, `TYPE = Recorrente`) | Rodei `RECORRENTES (ATIVOS) - RJ`; A4 é de RJ mas Sazonal | 0 linhas (A4 não é Recorrente) | 0 linhas. `SAZONAIS - RJ` devolveu A4 | passou |
| 3 | Região, negativo | `SAZONAIS - SP` | 0 linhas (não há Sazonal em SP) | 0 linhas | passou |
| 4 | Combinar critérios (setor e região) | `SEGMENTO - ALIMENTOS` (setor) cruzado com a região nos dados: A1 (SP) e A3 (SP) e A5 (SP) são os únicos Alimentos | Só Contas de Alimentos; nenhuma de outro setor | A1, A3, A5. `SEGMENTO - BEBIDAS` = A2. `SEGMENTO - PET` = 0 | passou |
| 5 | Opt-out de e-mail excluído (PA-07) | `SEGMENTO - ALIMENTOS` com 4 Contatos de Alimentos, 1 com opt-out | 3 linhas, sem o Contato com opt-out | 3 linhas (A1, A3, A5) | passou |
| 6 | Opt-out em Lead | `LEADS - SEGMENTO - ALIMENTOS`, `LEADS - SP`, `LEADS - MG` | Alimentos = L1 (L2 excluído); SP = L1; MG = L3 | Alimentos = L1; SP = L1; MG = L3. `LEADS - SEGMENTO - BEBIDAS` = L3, `- FARMACEUTICO` = 0 | passou |
| 7 | Inativos | `INATIVOS - GERAL` | A3 | A3 | passou |
| 8 | Histórico de compra, faixas (PA-04) | `COMPRA - ÚLTIMOS 90 DIAS`, `SEM COMPRA - 91 A 180`, `- 181 A 365`, `- MAIS DE 365 DIAS` | A1; A2; A3; A4, sem lacuna nem sobreposição; A5 (sem data) em nenhuma | A1; A2; A3; A4. A5 em nenhuma | passou |
| 9 | Público por produto | `PRODUTO - CONTAS POR PRODUTO COMPRADO` com 1 pedido de A1 | Agrupado por produto e Conta, sem valores | Grupo `TESTE EPLAST-36 Produto` > `TESTE EPLAST-36 A1`; colunas: número, data, status, família, quantidade (sem preço) | passou |
| 10 | Público não grava em registro | Consultei `LastModifiedDate` das Contas depois de rodar os relatórios | Sem alteração pelos relatórios | Última modificação 18:23:14Z, 1 segundo após a criação (18:23:13Z); os relatórios rodaram depois. Relatório e PS não têm DML | passou |
| 11 | Permission set sem poder excessivo | Consultei ObjectPermissions, FieldPermissions e PermissionSet | Só leitura, sem valores de compra, sem ViewAll nem ModifyAll | Conforme descrito acima | passou |
| 12 | Acesso respeita perfil (usuário sem permissão não vê o público) | Não executado | Acesso negado ou público não aparece | Não executado: o único usuário de teste disponível é o de serviço (Administrador do sistema), que é também o meu usuário de execução. Não alterei perfil nem permissão | não executado |
| 13 | Contagem do público = relatório de controle | Cada contagem acima vem do próprio relatório; comparei com a massa conhecida (a verdade esperada é a massa que criei) | Contagem igual à massa | Igual em todos os casos 1 a 9 | passou |
| 14 | Sem dado real | Massa 100% sintética, e-mails `example.invalid`, nenhum dado de cliente lido | Nenhum dado real no contexto | Cumprido; a dev nem tinha Contas | passou |

## Premissas assumidas exercitadas (validar na homologação)
- PA-04 (faixas de recência 0–90, 91–180, 181–365, mais de 365 dias): exercitada nos 4 relatórios, sem lacuna nem sobreposição (caso 8). O cliente valida se as faixas servem.
- PA-05 (7 regiões, filtros existentes preservados): exercitada em SP, MG e RJ (casos 1 a 3). CO, ES, NO/NE e SUL não rodei com massa própria.
- PA-06 (`Sector__c` como segmento): casos 4 a 6.
- PA-07 (opt-out em todos): casos 5 e 6. Reduz a contagem de todos os 35 relatórios existentes.
- PA-08 (sem valores de compra): casos 9 e 11.
- PA-11 (`TYPE = Recorrente` nos 7 `RECORRENTES (ATIVOS)`): caso 2. Muda a contagem desses relatórios.
Nenhuma premissa foi motivo de reprovação.

## O que ficou sem prova
- Acesso negado para usuário sem o PS e pasta compartilhada só com um usuário nominal (caso 12): precisa de um usuário comum de Marketing e outro sem acesso, na homologação, e do administrador da Eplast atribuir `PS_Marketing_Publicos` e compartilhar a pasta.
- Regiões CO, ES, NO/NE e SUL, e os demais setores de Conta e de Lead (só 4 setores de Conta e 2 de Lead com massa): o filtro é do mesmo padrão dos testados, mas não rodei cada um.
- Campos do Marketing Cloud Connect (`et4ae5`) e a leitura pelo Marketing Cloud: fora da esteira, nada foi feito lá.
- `LEADS - NO/NE` não existe (desvio 4 do build): lacuna conhecida, não é falha do build.

## O que pode ter saído da org
Nada. Usei `TriggerUtility.bypassTrigger = true` em todo DML de teste, as triggers não chamaram o Protheus, e não criei Pedido que dispare integração além do Pedido de teste em status inicial, também com bypass. Não há log de integração nem chamada externa registrada por mim.

## Limpeza
Apaguei por Apex todos os `TESTE EPLAST-36`: Pedido e item, Oportunidades, Leads, Contatos, Contas, Produto, entrada de preço, Filial e Prazo de pagamento. Contagem final na dev: Account 0, Contact 0, Lead 0, Opportunity 0, Order 0, Branch 0, PaymentTerms 0 (Product2 mostra 1042 registros que já existiam, não são meus; os meus saíram). `ProtheusSellerId__c` do meu usuário devolvido ao vazio. Nenhum job agendado criado. Ficam no repositório apenas os fixtures em `clients/eplast/fixtures/`.
