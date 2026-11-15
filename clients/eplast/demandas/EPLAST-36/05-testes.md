**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# EPLAST-36 — Testes na sandbox de QA (QAS da Eplast, Partial Copy)

`sf org list` mostrou um único alias, `sbx-eplast-qa` (Sandbox, Connected, org `00DHa000006vZtmMAE`). Nada foi feito em produção nem no Marketing Cloud. Nenhum componente do build foi alterado ou implantado por mim.

Rodada 1 (não existe `05-testes-rodada-<n>.md`). Aprovado porque os critérios centrais (região, segmento, inativos, faixas de compra, opt-out, produto, nada gravado, permission set) têm evidência. Dois critérios do design ficaram sem prova, com a causa registrada abaixo (casos 10 e 12); a homologação os cobre (roteiro do cliente, testes 8 e 9). Nenhuma falha encontrada.

## Falhas
Nenhuma.

## Observações (não são falha)
- Na QAS o relatório `PRODUTO - CONTAS POR PRODUTO COMPRADO` salvo devolve só as primeiras 10.000 linhas (a org tem 10.320 Pedidos). O pedido de teste não aparece na execução salva; filtrando por nome da Conta na execução (sem salvar) o agrupamento funciona. Em produção o relatório pode vir truncado: vale o cliente filtrar por período ou produto.
- `OrderItem` não aparece em `ObjectPermissions` do PS (o XML o declara); o acesso segue o de Pedido. Conferir com usuário de Marketing real na homologação.
- Usuário de serviço `005bJ00000piKAaQAM` (ativo, Administrador do sistema) e `005bJ00000hBJmYQAW` (inativo). Só o primeiro foi usado, só para executar a massa.

## Existência dos componentes (conforme `05-deploy-qa.md`, deploy `0AfHa00000EI5ArKAL`)
- `SELECT COUNT() FROM Report WHERE FolderName='MARKETING CLOUD'` = 58 (igual ao plano de build).
- `PS_Marketing_Publicos` existe (`0PSHa000002DNAXOA4`).

## Casos
Massa sintética (`TESTE EPLAST-36`): 5 Contas, 6 Contatos (A1 com um 2º Contato com opt-out de e-mail), 3 Leads (L2 com opt-out), 4 Oportunidades Fechado/Ganho, 1 Pedido com 1 item. Fixtures em `clients/eplast/fixtures/` (`conta-oportunidade-ganha.apex` ajustado para a QAS: regra de duplicidade, e-mail e telefone distintos por Conta). Relatórios executados por `GET /analytics/reports/<id>?includeDetails=true`; só foram lidas as linhas `TESTE EPLAST-36` e o total agregado.

Contas: A1 Recorrente/SP/Alimentos/compra há 30 dias; A2 Recorrente/MG/Bebidas/120; A3 Inativo/SP/Alimentos/200; A4 Sazonal/RJ/Industrial/400; A5 Recorrente/SP/Alimentos/sem compra. Leads: L1 SP/Alimentos; L2 SP/Alimentos com opt-out; L3 MG/Bebidas.

| Caso | Critério (design, seção 12) | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Região × comportamento, correção PA-11 | Rodar `RECORRENTES (ATIVOS) - SP`, `- MG`, `- RJ` | SP: A1 e A5; MG: A2; RJ: nenhuma (A4 é Sazonal em RJ) | SP = A1, A5 (total 64); MG = A2 (14); RJ = nenhuma de teste (27, só dado existente) | passou |
| 2 | Região, sazonal | `SAZONAIS - RJ`, `SAZONAIS - SP`, `SAZONAIS - GERAL` | RJ: A4; SP: nenhuma; GERAL: A4 | RJ = A4; SP = nenhuma; GERAL = A4 | passou |
| 3 | Segmento de Conta | `SEGMENTO - ALIMENTOS`, `- BEBIDAS`, `- INDUSTRIAL`, `- PET` | Alimentos: A1, A3, A5; Bebidas: A2; Industrial: A4; Pet: nenhuma | Idêntico (Alimentos 87 no total, Bebidas 356, Industrial 5, Pet 3) | passou |
| 4 | Segmento de Lead | `LEADS - SEGMENTO - ALIMENTOS`, `- BEBIDAS`, `- FARMACÊUTICO`, `LEADS - SP`, `LEADS - MG` | Alimentos: L1; Bebidas: L3; Farmacêutico: nenhum; SP: L1; MG: L3 | Idêntico | passou |
| 5 | Inativos | `INATIVOS - GERAL` | A3 | A3 (total 339) | passou |
| 6 | Histórico de compra, uma faixa por Conta | `COMPRA - ÚLTIMOS 90 DIAS`, `SEM COMPRA - 91 A 180`, `- 181 A 365`, `- MAIS DE 365` | A1; A2; A3; A4; A5 (sem data) em nenhuma | A1; A2; A3; A4; A5 em nenhuma das quatro | passou |
| 7 | Opt-out excluído (Contato e Lead) | Rodar `SEGMENTO - ALIMENTOS`, `RECORRENTES (ATIVOS) - GERAL`, `LEADS - SEGMENTO - ALIMENTOS`, `LEADS - SP` | Contato com opt-out (A1) e Lead L2 não aparecem em nenhum | Em todos os 58 relatórios, nenhuma linha "optout" nem L2 apareceu | passou |
| 8 | Produto | `PRODUTO - CONTAS POR PRODUTO COMPRADO` com filtro temporário por nome da Conta (execução sem salvar, por truncamento, ver observações) | Grupo Produto > Conta A1, sem valores | `TESTE EPLAST-36 Produto` > `TESTE EPLAST-36 A1`; colunas: número, data, status, família, quantidade (sem preço) | passou |
| 9 | Nada gravado | Contagem de Account, Opportunity, Order antes e depois de criar a massa e rodar os 58 relatórios | Só a massa do teste | Antes 1219 / 9328 / 10320; com a massa 1224 / 9332 / 10321 (+5 / +4 / +1 = só a massa); depois da limpeza 1219 / 9328 / 10320. Relatórios e PS não têm DML | passou |
| 10 | Campanha congelada (Adicionar à campanha em `PUB -`) | Tentei criar `PUB - TESTE EPLAST-36` e um membro por Apex como usuário de serviço | Membros congelados, relatório muda | Não executado: o usuário de serviço não tem escrita em `Campaign.Name` (erro de compilação "Field is not writeable: Campaign.Name"; ele não tem acesso de Marketing). Não alterei permissão dele. O fluxo "Adicionar à campanha" precisa de usuário com acesso de Marketing | não executado |
| 11 | Dinâmico em vez de congelado (relatório) | Mudei Tipo de A1 (Recorrente para Inativo) e A5 (Recorrente para Sazonal) e rodei de novo | A1 sai de `RECORRENTES (ATIVOS) - SP` e entra em `INATIVOS - GERAL`; A5 sai de RECORRENTES - SP e entra em `SAZONAIS - SP` | RECORRENTES - SP total 64 para 63, só A5 de teste (após A1 sair); INATIVOS = A1 e A3 (340); SAZONAIS - SP = A5 (92) | passou |
| 12 | Permissão: usuário sem PS não vê os públicos | Não executado | Acesso negado | Não executado: só existem usuários Administrador do sistema; não criei usuário nem alterei perfil/permissão. Fica para a homologação | não executado |
| 13 | PS sem poder excessivo | Consultas a `ObjectPermissions`, `PermissionSet`, `FieldPermissions` na QAS | Só leitura (Campaign cria/edita), sem ViewAll/ModifyAll, sem edição de campo | Account, Contact, Lead, Order, Product2: só leitura; Campaign: ler/criar/editar sem excluir; RunReports e CreateCustomizeReports ligados; ModifyAllData e ViewAllData desligados; 0 campos com edição; 0 atribuições do PS hoje | passou |
| 14 | Sem automação nova | Conferir o conteúdo do deploy (`05-deploy-qa.md`) | Só 1 PS e a pasta + 58 relatórios | Só PS, pasta e relatórios; nenhum Flow, trigger ou classe | passou |
| 15 | Sem dado real no artefato | Só linhas `TESTE EPLAST-36` e totais agregados | Nenhum dado real | Cumprido; nenhum Contato ou Conta real lido | passou |

Resumo: 13 passaram, 0 falharam, 2 não executados (casos 10 e 12: faltam usuários com e sem acesso de Marketing).

## Premissas exercitadas
PA-04 (faixas, caso 6), PA-05 (SP, MG, RJ rodadas; CO, ES, NO/NE, SUL não tiveram massa de teste), PA-06 (casos 3 e 4), PA-07 (caso 7), PA-08 (casos 8 e 13), PA-11 (caso 1). Nenhuma levou a falha.

## Riscos do assessment tocados
A demanda não cria Flow, trigger nem classe e não grava em Account, Opportunity ou Order; o risco de automação concorrente só entrou pela massa de teste (Oportunidade Fechado/Ganho para o rollup `LastPurchase__c`, criada com `TriggerUtility.bypassTrigger = true`). EPLAST-37 mexe no mesmo `PS_Marketing_Publicos` e na pasta `MARKETINGCLOUD`; nada foi alterado por mim, e os testes dependem do conteúdo deles como entregue por esta demanda.

## O que pode ter saído da org
Nada externo. Nenhum e-mail, jornada ou chamada ao Marketing Cloud ou Protheus: DML de teste com `bypassTrigger`, e-mails `example.invalid`. Flows de Oportunidade/Pedido da org podem ter rodado nos registros de teste; nenhuma chamada externa registrada por mim. Uma alteração temporária no campo `ProtheusSellerId__c` do usuário de serviço (`005bJ00000piKAaQAM`): antes vazio, durante `TESTE36`, depois vazio (conferido).

## Limpeza
Apaguei por Apex todos os `TESTE EPLAST-36` (Pedido, Oportunidades, Leads, Contatos, Contas, Produto, entrada de preço, Filial, Prazo). Contagens finais iguais às iniciais: Account 1219, Opportunity 9328, Order 10320, Lead 712, Contact 914, Product2 1042 (nenhum de teste). Nenhum job agendado.
