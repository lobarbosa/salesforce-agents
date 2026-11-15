**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev`

# Verificação — EPLAST-37 · Classificação de clientes (ativo, inativo, potencial)

Org conferida com `sf org list`: só `sbx-eplast-dev` (alias `sbx-eplast-dev`, Org Id `00DHa000006vfMLMAY`), conectada. QA e produção não foram tocadas. Nada feito no Marketing Cloud.

## Dados de teste e ajustes no usuário de execução
- Fixture base: `fixtures/conta-oportunidade-ganha.apex` (da main, EPLAST-36), adaptada para EPLAST-37 em `/tmp` (6 contas `TESTE EPLAST-37 B1..B6`, 7 contatos, 5 oportunidades Fechado/Ganho + 1 criada no CA-05, filial e condição de pagamento de teste). Usa `TriggerUtility.bypassTrigger`, sem chamada externa. A org de dev estava com 0 contas, 0 oportunidades e 0 contatos antes.
- Usuário `005bJ00000piKAaQAM` (Administrador do sistema): `ProtheusSellerId__c` era `null`, foi para `TESTE37` (exigido pela validation rule de Oportunidade) e voltou a `null` ao final (conferido por consulta). Nenhuma outra alteração no usuário (sem permission set, sem Marketing User).
- Limpeza: oportunidades, contas (cascata em contatos), filial e condição de pagamento de teste apagadas. Contagens finais: Account 0, Opportunity 0, Contact 0, Branch__c 0, PaymentTerms__c 0. Nada ficou.

## Resultado por critério

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| 1 | Existência | Tooling API em `CustomField` e `Report` | Campo `Account.RelationshipClass__c` e 2 relatórios na pasta MARKETING CLOUD | Campo com a fórmula `IF(ISBLANK(LastPurchase__c),"Potencial",IF(Inactive__c,"Inativo","Ativo"))`; relatórios `CLASSIFICACAO_CONTAS_POR_CLASSE` (Summary) e `POTENCIAIS_SEM_COMPRA` (Tabular), pasta `MARKETING CLOUD`; 17 `FieldPermissions` para o campo | passou |
| 2 | CA-01 Potencial | Conta B5 sem oportunidade ganha; leitura de `LastPurchase__c`, `Inactive__c`, `RelationshipClass__c` | Potencial | LastPurchase nulo, Inactive__c = false, classe = Potencial (fecha o "não confirmei" 1 do recon: `Inactive__c` é falso com data vazia) | passou |
| 3 | CA-02 Ativo recente | B1, ganha há 30 dias | Ativo, Inactive = false | 2026-10-16, false, Ativo | passou |
| 4 | CA-03 Inativo antigo | B4, ganha há 120 dias | Inativo, Inactive = true | 2026-07-18, true, Inativo | passou |
| 5 | CA-04 limite 90 dias | B2 (90 dias) e B3 (91 dias) | B2 Ativo, B3 Inativo | B2 Ativo (false), B3 Inativo (true); sem divergência da fórmula existente | passou |
| 6 | CA-05 atualização automática | Inserida oportunidade Fechado/Ganho (CloseDate hoje-5) na conta B5 e relido o campo sem outra ação | Potencial passa a Ativo, `LastPurchase__c` = data de fechamento | `LastPurchase__c` = 2026-11-10, classe = Ativo | passou |
| 7 | CA-06 Type não decide | B6 com Type = Prospect e compra há 30 dias | Ativo | Type Prospect, classe Ativo | passou |
| 8 | Relatório de classificação | Analytics API (`/analytics/reports/00OHa000002zGY9MAM`), só contagens | Contas agrupadas por classe e Type | Antes do CA-05: Ativo (Prospect 1, Recorrente 2), Inativo (Recorrente 2), Potencial (Recorrente 1), total 6. Depois: Ativo (Prospect 1, Recorrente 3), Inativo (Recorrente 2), Potencial sem linhas | passou |
| 9 | Relatório POTENCIAIS_SEM_COMPRA | Analytics API (`00OHa000002zGYAMA2`) | Só contatos de conta Potencial sem opt-out | Filtros `RelationshipClass__c = Potencial` e `EMAIL_OPT_OUT = Falso`; 1 linha (contato sem opt-out de B5; o contato com opt-out ficou fora); 0 linhas depois de B5 virar Ativo | passou |
| 10 | CA-07 (ajustado, seção 11 do design) | `git diff main` na `force-app` | Sem Apex, trigger nem Flow novos; único campo novo em Account é a fórmula | Mudanças: 1 campo (`RelationshipClass__c`), 2 relatórios, FLS em 13 perfis e 2 permission sets. Nenhum arquivo em classes, triggers, flows ou outro objeto | passou |
| 11 | CA-08 Ranking intacto | Mesmo diff | Nenhuma versão nova de Flow | Nenhum Flow no diff; `Ranking__c` não é gravado pela solução | passou |
| 12 | CA-09 Reaproveitamento | Não verificado nesta etapa (é critério do design) | Registrado no `03-design.md` | Já avaliado no gate de design; sem execução aqui | não executado |
| 13 | CA-10 LGPD (ajustado) | Colunas lidas dos metadados dos 2 relatórios | Sem e-mail, telefone ou CPF; teste só com massa sintética | Colunas do relatório 1: conta, proprietário, UF, LastPurchase, Inactive, Ranking. Do relatório 2: Id do contato, nome, sobrenome, conta, classe, proprietário. Nenhum dado pessoal; massa 100% sintética | passou |
| 14 | CA-11 Marketing Cloud | Nenhuma ação lá; sem artefato de MC no diff | Nada configurado no MC | Confirmado | passou |
| 15 | CA-12 Apex | Sem Apex no build | Sem objeto | Não se aplica | não executado (sem objeto) |

## Observações (não bloqueiam)
- A leitura do `formulaTreatBlanksAs` pela Tooling API devolveu `null` (plano diz `BlankAsBlank`). Sem efeito observado: o caso Potencial (data vazia) devolveu o valor correto.
- Conforme o plano de build: os permission sets de sistema `AncCrmIntegrationUser` e `sfdc_a360_sfcrm_data_extract` não receberam leitura do campo; conferir na homologação se alguma integração precisa da classe.
- Filtro de opt-out do relatório 2 foi exercitado só com opt-out por e-mail (`EMAIL_OPT_OUT`), como no padrão dos 58 relatórios.
- O script usado ficou em `/tmp`, fora do repositório; o fixture da EPLAST-36 já cobre o uso (troque o ID da demanda e as datas).

## O que pode ter saído da org
Nada. A cadeia rodou com `TriggerUtility.bypassTrigger`, sem integração, callout ou e-mail; nenhum registro externo criado.
