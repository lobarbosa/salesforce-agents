**Verificação:** inconclusiva
**Org de teste:** `sbx-somos-agility-dev`

# SOMOSAGILITY-26 — Verificação do build

Org confirmada com `sf org list`: única conectada, `sbx-somos-agility-dev` (sandbox, Connected). QA e produção não foram tocadas. Nada foi ativado, criado, alterado ou apagado na org (só consultas e retrieves para pasta temporária, descartada). Nenhum dado de cliente lido: só metadata e contagem agregada. Nenhum usuário, perfil ou permission set alterado.

## Resumo
A construção bate com o desenho em tudo o que é metadata: 9 campos, FLS, 16 layouts e lógica do Flow. Ficou sem prova o comportamento em execução (cópia BluePrint para PSL, limite de 32.768, regressão) e há uma divergência de estado do Flow entre o pedido e a dev (ver "Divergência"). Por isso `inconclusiva`, não defeito.

## Divergência de estado do Flow (não é falha do build)
O pedido e o plano dizem que a versão nova está em Draft e não ativa. Na dev, `Flow` na Tooling API mostra: v1 Obsolete, v2 Obsolete, **v3 Active**. A v3 ativa contém a lógica nova (descrição "v2 SOMOSAGILITY-26..." e referências a `PFP_N_Texto__c`). Ou seja, a v3 já foi ativada na dev antes desta sessão (o plano prevê isso no passo 5 de verificação e a autorização do gate); eu não ativei nada. O arquivo do repositório está com `<status>Draft</status>`, diferente da org. Convém o time confirmar se a ativação na dev foi intencional. A v2 original em uso, que o plano diz Active, está Obsolete.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | Cinco campos aceitam tamanho alvo (tipo/tamanho) | `sf data query` em `FieldDefinition` dos 3 objetos, `PFP%` | 3 campos `PFP_N_Texto__c` por objeto, Long Text Area 32768 | 9 campos: BluePrint__c, Propostas_de_Solucao__c, FluxoVendaProdutos__c, todos "Área de texto longo(32768)", rótulos PFP 1/2/3 | passou |
| V2 | Dados existentes íntegros (campos antigos) | Mesma consulta, campos antigos | Antigos mantêm tipo e tamanho | BluePrint `PFP_N_UNC_Path__c` URL(255); PSL `PFP_N__c` Text(255), `PFP_N_UNC_Path__c` fórmula; FVP `PFPNUNCPath__c` fórmula. Nenhum alterado | passou |
| V3 | Permissões de campo mantidas | `SELECT COUNT(Id) FROM FieldPermissions WHERE Field IN (9 campos)` | 573 (plano) | 573 | passou |
| V4 | Layouts com o novo campo logo abaixo do antigo | `sf project retrieve` de 16 layouts da dev para pasta temporária; posição do campo anterior a cada `PFP_N_Texto__c` | 16 layouts, 3 campos cada, anterior é o antigo | 16 layouts, 3 campos em cada. BluePrint: anterior `PFP_N_UNC_Path__c`; PSL (11 layouts): `PFP_N__c`; FVP (5): `PFPNUNCPath__c` | passou |
| V5 | Automação aponta para campos novos | Retrieve do Flow da dev; leitura da metadata | Decisões testam `PFP_N_Texto__c` vazio; `recordUpdate` grava `PFP_N_Texto__c` do BluePrint e `PFP_N__c` com fórmula `*_Antigo_Preservado` | Confere (22 referências `_Texto__c`; 3 fórmulas `IF(ISBLANK(PFP_N__c), BluePrint.PFP_N_UNC_Path__c, PFP_N__c)`; objeto PSL, CreateAndUpdate, RecordAfterSave) | passou |
| V6 | Versão nova em Draft, sem ativar | `Flow` na Tooling API por versão | v nova Draft, antiga Active | v3 **Active**, v2 Obsolete (ver Divergência). Repo em Draft | falhou (expectativa do pedido; não é defeito de construção) |
| V7 | Cópia BluePrint para PSL, texto > 255 | Não executado (escopo desta verificação limitado a metadata; massa exige 15 VRs ativas e automações de Oportunidade) | PSL recebe texto do BluePrint, antigo preservado | Sem execução na dev nesta sessão. A QA registrou C1 a C4, C7, C8, C10, C11 aprovados em `05-testes-rodada-*.md` | não executado |
| V8 | Valor N+1 (32.769) recusado; N aceito | Não executado | Recusa com mensagem de tamanho | Sem execução | não executado |
| V9 | Automações e VRs sem erro ao salvar | Não executado | Sem erro | Sem execução | não executado |

## O que ficou sem prova
- V7 a V9: comportamento em execução na dev (cópia pelo Flow com texto > 255 caracteres, limite de 32.768 caracteres, regressão com validation rules e automações). Para provar: com massa sintética `TESTE SOMOSAGILITY-26` (fixture em `clients/somos-agility/fixtures/` não existe; seria preciso montar Opportunity, BluePrint, PSL satisfazendo as 15 VRs), salvar uma PSL por transação e conferir os campos.
- Paridade com a QA (layouts, FLS 459 contra 573, fórmula `FVP.PFP1UNCPath__c`) fora do escopo da dev.
- Premissas P1 a P5 e G5 (relatórios, Conga/SDocs, SnapERP) seguem para a homologação.

## Dados de teste e limpeza
Nenhum dado criado; nenhum usuário alterado; nenhum job Apex agendado. Pasta temporária de retrieve removida (`git status` mostra só `00-preflight.md` modificado e `04-verificacao.md` com esta nova versão).

## O que pode ter saído da org
Nada. Nenhum registro foi criado e nenhuma automação foi disparada.
