**Veredito:** aprovado
**Org de teste:** `sbx-eplast-qa`

# Testes — EPLAST-37 · Classificação de clientes em ativos, inativos e potenciais

Org conferida com `sf org list`: só `sbx-eplast-qa` conectada (Org Id `00DHa000006vZtmMAE`, Partial Copy `eplast--qas`). Pacote implantado pela esteira (deploy `0AfHa00000EI5HJKA1`, Succeeded, commit `3174a8a2`). Produção e Marketing Cloud não foram tocados. Rodada 1 (não existe `05-testes-rodada-<n>.md`).

## Falhas
Nenhuma.

## Dados de teste e limites
- Massa sintética `TESTE EPLAST-37` criada pelo fixture `fixtures/conta-ativo-inativo-potencial.apex` (gravado nesta demanda): 6 contas (B1 a B6), 7 contatos (um com opt-out), 6 oportunidades Fechado/Ganho (5 no fixture + 1 no CA-05), 1 filial e 1 condição de pagamento. Proprietário dos registros: usuário `005Hp00000gijVrIAI` (ativo, já com ID Protheus preenchido; nenhum usuário foi alterado). O usuário `005bJ00000piKAaQAM` da conta de serviço, ativo, não tem ID Protheus; para não alterá-lo, não foi usado. Usou `TriggerUtility.bypassTrigger` (sem chamada externa).
- Na QAS há dado real: nenhuma consulta devolveu dado pessoal; no total da base só contagens agregadas. Nos relatórios, o filtro extra por nome `TESTE EPLAST-37` foi aplicado em execução para ler só linhas de teste.
- Limpeza: ao final, Account, Opportunity, Contact, Branch__c e PaymentTerms__c com `TESTE EPLAST-37` = 0; total de contas voltou a 1219 (antes do teste, 1219).
- Teste por tela (`qa_browser_*`) não executado: os relatórios na QAS exibem dado real de cliente (guardrail 2). Os relatórios foram executados pela API de relatórios, com filtro de teste. A conferência visual fica no roteiro do cliente.
- Preflight: EPLAST-36, 42 e 43 mexem em `PS_Marketing_Publicos` e `reports/MARKETINGCLOUD`. Nada foi alterado por mim; o teste não depende desses componentes além da pasta e dos 2 relatórios novos.

## Casos

| Caso | Critério | Passos | Esperado | Obtido (evidência) | Status |
|---|---|---|---|---|---|
| 1 | Pacote na org | Tooling API em `CustomField`; SOQL em `Report` | Campo `Account.RelationshipClass__c` e 2 relatórios existem | Campo texto, rótulo "Classe de Relacionamento", fórmula `IF(ISBLANK(LastPurchase__c), "Potencial", IF(Inactive__c, "Inativo", "Ativo"))`; relatórios `CLASSIFICACAO_CONTAS_POR_CLASSE` (Summary) e `POTENCIAIS_SEM_COMPRA` (Tabular), pasta `MARKETING CLOUD` | passou |
| 2 | CA-01 Potencial | Conta B5 sem oportunidade ganha; SOQL nos 3 campos | Potencial | LastPurchase vazio, Inactive false, classe Potencial | passou |
| 3 | CA-02 Ativo recente | B1, ganha há 30 dias | Ativo, Inactive false | 2026-10-16, false, Ativo | passou |
| 4 | CA-03 Inativo antigo | B4, ganha há 120 dias | Inativo, Inactive true | 2026-07-18, true, Inativo | passou |
| 5 | CA-04 limite 90 dias | B2 (90 dias) e B3 (91 dias) | B2 Ativo, B3 Inativo | B2 2026-08-17 false Ativo; B3 2026-08-16 true Inativo | passou |
| 6 | CA-05 atualização automática | Oportunidade Fechado/Ganho (hoje menos 5 dias) em B5, sem outra ação; reler | B5 passa a Ativo, LastPurchase = data de fechamento | 2026-11-10, Inactive false, Ativo | passou |
| 7 | CA-06 Type não decide | B6 com Type Prospect e compra há 30 dias | Ativo | Type Prospect, classe Ativo | passou |
| 8 | Relatório de classificação | Analytics API, só contagens, sem detalhes | Contas agrupadas por classe e Type, cobrindo toda a base | Ativo 161, Inativo 407, Potencial 657; soma 1225 = 1219 contas existentes + 6 de teste | passou |
| 9 | Relatório Potenciais sem compra | Execução com filtros do relatório (classe = Potencial, opt-out = Falso) mais filtro de nome de teste | Só o contato sem opt-out de B5; o contato com opt-out fora | 1 linha (B5); contato B5 com opt-out ausente. Após B5 virar Ativo (caso 6): 0 linhas | passou |
| 10 | CA-07 sem gravação nova | Lista de componentes de `05-deploy-qa.md` | Sem Apex, trigger ou Flow; só 1 campo fórmula | Lista: 1 campo, 2 relatórios, 2 permission sets, 13 perfis (FLS). Nenhuma classe, trigger ou Flow | passou |
| 11 | CA-08 Ranking intacto | Mesma lista | Nenhum Flow implantado | Nenhum Flow na lista | passou |
| 12 | Permissão por perfil | Contagem de `FieldPermissions` do campo novo e de `Inactive__c` com leitura | Mesmos 17 leitores | 17 e 17 | passou |
| 13 | CA-10 LGPD | Colunas dos relatórios (metadata) | Sem e-mail, telefone, CPF | Relatório 2: Id do contato, nome, sobrenome, conta, classe, proprietário. Relatório 1 só por conta, com agregados | passou |
| 14 | CA-11 Marketing Cloud | Lista do deploy; nenhuma ação minha | Nada configurado no MC | Confirmado | passou |
| 15 | CA-09 reaproveitamento | Critério do design, não de execução na QA | Registrado no `03-design.md` | Não executado pelo QA (avaliado no gate de design) | não executado (não é critério de execução) |
| 16 | CA-12 Apex | Sem Apex no pacote | Sem objeto | Não se aplica | não executado (sem objeto) |
| 17 | Fragilidade do assessment (ordem de execução Account/Opportunity) | Criação de Opportunity Fechado/Ganho com a cadeia completa da QAS (CPQ, Flows), exceto triggers desviadas por `bypassTrigger` | Roll-up e fórmula corretos sem erro | 6 oportunidades inseridas sem erro; roll-up atualizou as contas. A solução não grava nada em Account | passou |

## Observações (não bloqueiam)
- Volume: o relatório de classificação rodou sobre 1225 contas sem erro.
- Permission sets de sistema `AncCrmIntegrationUser` e `sfdc_a360_sfcrm_data_extract` não leem o campo (conforme plano de build); conferir na homologação se alguma integração precisa da classe.
- Fórmula por data não altera o registro quando a conta envelhece (R3 do design): quem opera o MC deve usar os relatórios ou `LastPurchase__c`.
- A QAS tem 657 contas Potencial, das quais 333 com Type "Inativo": divergência esperada do rótulo manual (P6); o cliente decide.

## O que pode ter saído da org
Nada. A cadeia rodou com `TriggerUtility.bypassTrigger`, sem integração, callout ou e-mail; nenhum registro externo foi criado. Todos os registros de teste foram apagados.
