**Resultado do build:** concluído

# EPLAST-36 — Plano de build

**Data:** 2026-11-15 · **Branch:** `feature/EPLAST-36` · **Org:** alias `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast = dev da esteira, regra 5 do CLAUDE.md da conta e confirmação do card de 2026-11-15 09:58). Único alias conectado; QA não tocada. Nada no Marketing Cloud.

**Decisão:** configuração (nível 1), sem Flow, sem Apex, sem campo novo, sem DML. Deploy de 58 relatórios (35 existentes ajustados e 23 novos) e 1 permission set, validado e implantado em `sbx-eplast-dev`.

## C1 a C5 do design

| Cond. | Resultado |
|---|---|
| C1 | Resolvida pela regra 5 da conta (dev = `eplast--qa`). Não é bloqueio |
| C2 | Metadata em `force-app/main/default/reports/MARKETINGCLOUD/` e `permissionsets/`, branch `feature/EPLAST-36` |
| C3 | Lidos os filtros dos 35 relatórios. Os 7 `RECORRENTES (ATIVOS) - <região>` (CO, ES, MG, NO/NE, RJ, SP, SUL) **todos** estavam sem `TYPE`; o design só confirmava SP e NO/NE. Os dois `SAZONAIS - MG` têm XML idêntico (diff vazio) |
| C4 | `ContactList` expõe `Account.Sector__c`, `Account.LastPurchase__c`, `TYPE` e `EMAIL_OPT_OUT`; `LeadList` expõe `Lead.Sector__c` e `EMAIL_OPT_OUT`. Tipo de pedido com produtos: `OrderItemList` (Pedidos com Produtos), serviu; o custom não foi necessário |
| C5 | Pasta `MARKETING CLOUD` tem um único compartilhamento (um usuário nominal, Manage). Não há papel nem grupo de Marketing na org (o grupo `Marketing_Origem_Retorno` tem 0 membros e é do EPLAST-39). **Não alterei o acesso** para não inventar destinatário. Passo do administrador da Eplast, ver pendências |

## Componentes

| Componente | Ação | API name / nome |
|---|---|---|
| Relatórios existentes (35) | Ajustados: filtro `EMAIL_OPT_OUT = Falso` (PA-07) e descrição | pasta `MARKETINGCLOUD` |
| `RECORRENTES (ATIVOS) - CO/ES/MG/NO-NE/RJ/SP/SUL` (7) | Ajustados: `TYPE = Recorrente` acrescentado (PA-11) | `RECORRENTES_ATIVOS_*`, `Cpia_de_RECORRENTES_ATIVOS_SP_hLD` |
| `SAZONAIS - MG` duplicado | Renomeado o mais novo (criado 2024-12-13 14:20) para `SAZONAIS - MG (DUPLICADO - REVISAR)`. Não excluído | `SAZONAIS_MG_X7D` (o original é `SAZONAIS_MG_Jfz`) |
| `INATIVOS - GERAL` | Criado, `TYPE = Inativo` | `INATIVOS_GERAL` |
| `SEGMENTO - <setor>` (9) | Criados, `Account.Sector__c` | `SEGMENTO_<SETOR>` |
| `LEADS - SEGMENTO - <setor>` (8) | Criados, `Lead.Sector__c` | `LEADS_SEGMENTO_<SETOR>` |
| `COMPRA - ÚLTIMOS 90 DIAS` | Criado: `LastPurchase__c` de hoje-90 a hoje | `COMPRA_ULTIMOS_90_DIAS` |
| `SEM COMPRA - 91 A 180 DIAS` | Criado: hoje-180 a hoje-91 | `SEM_COMPRA_91_A_180_DIAS` |
| `SEM COMPRA - 181 A 365 DIAS` | Criado: hoje-365 a hoje-181 | `SEM_COMPRA_181_A_365_DIAS` |
| `SEM COMPRA - MAIS DE 365 DIAS` | Criado: antes de hoje-365 (366 dias ou mais). Faixas sem lacuna nem sobreposição; Conta sem data fora | `SEM_COMPRA_MAIS_DE_365_DIAS` |
| `PRODUTO - CONTAS POR PRODUTO COMPRADO` | Criado, `OrderItemList`, resumo por produto e Conta, sem valores financeiros | `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` |
| Permission set `PS_Marketing_Publicos` | Criado: leitura em Account, Contact, Lead, Order, OrderItem, Product2; leitura/criação/edição em Campaign; RunReports e CreateCustomizeReports; FLS de leitura em `Account.Sector__c`, `Subsector__c`, `LastPurchase__c`, `Inactive__c`, `Lead.Sector__c`, `Lead.Subsector__c` e `et4ae5__HasOptedOutOfMobile__c` (Lead e Contact). Sem valores de compra (PA-08) | `PS_Marketing_Publicos` |

Todos os componentes novos e os ajustados têm descrição.

## Desvios do design (todos pequenos, sem mudar a solução)

1. **Setores de Lead: 8, não 9.** `Lead.Sector__c` não tem `PET (Bem-estar animal)` (só `Account.Sector__c` tem). Criei 8 relatórios `LEADS - SEGMENTO` e 9 `SEGMENTO`. Total de novos: 1 + 9 + 8 + 4 + 1 = 23.
2. **Nome encurtado:** limite de 40 caracteres do nome do relatório. `LEADS - SEGMENTO - IND. TRANSFORMAÇÃO` no lugar de `... INDÚSTRIA DE TRANSFORMAÇÃO`.
3. **FLS de campos padrão fora do PS.** `Account.Type`, `BillingState`, `BillingCity`, `Lead.State`, `Status`, `LeadSource` e `HasOptedOutOfEmail` são campos padrão, sem FLS configurável em permission set (leitura vem do objeto). Só os campos custom entram em `fieldPermissions`.
4. **`LEADS - NO/NE` não existe** na pasta (há `LEADS - CO/ES/MG/RJ/SP/SUL/GERAL/NÃO CONVERTIDOS`). O design não lista como item a criar, então não criei. Registro como lacuna da matriz de leads por região.
5. **`LEADS - CO`** é o `Cpia_de_LEADS_SP_fWa` (nome de API de cópia de SP), filtro correto de CO. Só observação.

## Premissas assumidas aplicadas (design, seção 8)

PA-01 a PA-11 valem como desenhadas. Nenhuma virou bloqueio. As que o build materializou: PA-04 (faixas de recência), PA-05 (7 regiões, filtros existentes preservados), PA-06 (`Sector__c`), PA-07 (opt-out em todos), PA-08 (sem valores), PA-11 (`TYPE = Recorrente`).

## Estado da sandbox de dev e limite da verificação

A sandbox de dev tem 0 registros de Account (contagem agregada). Não carreguei massa nem fiz DML. Os relatórios foram implantados e a pasta tem 58 relatórios (35 + 23). A prova funcional dos filtros com dados (regiões, faixas, opt-out, produto) depende de massa sintética criada pelo verificador ou pelo QA. As faixas de data usam `N_DAYS_AGO`, aceito pelo deploy.

## Pendências para quem opera (não são bloqueio de build)

- Administrador da Eplast: compartilhar a pasta `MARKETING CLOUD` com os usuários de Marketing (hoje só um usuário nominal) e com o usuário de integração do Marketing Cloud Connect; marcar "Usuário de marketing" para quem cria campanha; atribuir `PS_Marketing_Publicos` na homologação (PA-09).
- Decidir a exclusão de `SAZONAIS - MG (DUPLICADO - REVISAR)` na homologação.
- `06-entrega.md` deve listar os relatórios alterados (R8): os 35 ganharam filtro de opt-out; os 7 `RECORRENTES (ATIVOS)` mudam de contagem por causa de `TYPE = Recorrente`. Quem opera o Marketing Cloud precisa saber.
- Marketing Cloud: nada feito. Passos de quem o opera estão na seção 7 do design.
- Sugestão em aberto para o arquiteto humano: campo fórmula `Account.Region__c` (seção 4 do design). Não criado.
