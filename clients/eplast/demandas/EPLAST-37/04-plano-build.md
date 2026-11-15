**Resultado do build:** concluído

# Plano de build — EPLAST-37 · Classificação de clientes em ativos, inativos e potenciais

**Org de build:** `sbx-eplast-dev` (`projetos@konectabr.com.eplast2.qa`, Org Id `00DHa000006vfMLMAY`), conferida com `sf org list`. QA e produção não foram tocadas. Branch `feature/EPLAST-37`.
**Abordagem:** configuração nativa (design, nível 1). Sem Flow, Apex nem trigger; nada gravado em Account, Opportunity ou Order. Nada feito no Marketing Cloud.

## Componentes criados

| Tipo | API name | Descrição / detalhe |
|---|---|---|
| CustomField | `Account.RelationshipClass__c` | "Classe de Relacionamento"; fórmula Texto `IF(ISBLANK(LastPurchase__c), "Potencial", IF(Inactive__c, "Inativo", "Ativo"))`; `BlankAsBlank`; descrição e ajuda preenchidas |
| Report | `MARKETINGCLOUD/CLASSIFICACAO_CONTAS_POR_CLASSE` | "CLASSIFICAÇÃO - CONTAS POR CLASSE"; `AccountList`, Resumo, agrupado por `RelationshipClass__c` e `TYPE`; colunas: conta, proprietário, UF de cobrança, `LastPurchase__c`, `Inactive__c`, `Ranking__c`; sem dado pessoal; `scope` organization (aceito); descrição preenchida |
| Report | `MARKETINGCLOUD/POTENCIAIS_SEM_COMPRA` | "POTENCIAIS - SEM COMPRA"; `ContactList`, tabular, organization; filtros `Account.RelationshipClass__c = Potencial` e `EMAIL_OPT_OUT = 0`; colunas: Id do contato, nome, sobrenome, conta, classe, proprietário (sem e-mail, telefone, endereço; PA-13); descrição preenchida |
| FLS (leitura, `editable=false`) | `Account.RelationshipClass__c` | Espelha quem lê `Account.Inactive__c`: perfis Admin, Standard, Marketing, Pricing, Financeiro, Engenharia de Produtos, Comercial - Analista, Comercial, Anypoint Integration, SalesforceIQ Integration User, External Einstein Agent User, External Apps Login User, Einstein Agent User; permission sets `Protheus` e `PS_Marketing_Publicos`. Pós-deploy: 17 entradas de `FieldPermissions` para o campo |

Reaproveitados sem alteração: `LastPurchase__c`, `Inactive__c`, `Type`, `Ranking__c` e os 4 relatórios de público por data de compra da pasta `MARKETING CLOUD`. Pasta existente usada; nenhuma pasta nova.

## Notas do build
- A consulta de FLS de `Inactive__c` na dev retornou 15 entradas, incluindo `AncCrmIntegrationUser` e `sfdc_a360_sfcrm_data_extract` (permission sets de sistema/integração, sem arquivo editável no repo). Esses dois não receberam a leitura do campo novo; o deploy resultou em 17 entradas totais de FLS (padrão da plataforma inclui acessos que a org concede por perfil). Conferir na homologação se alguma integração de sistema precisa ler a classe.
- Em Protheus e PS_Marketing_Publicos o `fieldPermissions` foi inserido junto dos demais; nos perfis do repo, que não traziam `fieldPermissions`, só a entrada nova foi acrescentada (partial deploy não remove nada).
- `PS_Marketing_Publicos` foi baixado da org para o repo (não estava versionado) antes de acrescentar o FLS.
- Primeiro dry-run acusou: `TYPE` não pode estar nas colunas por ser agrupamento (removido) e ordem do `fieldPermissions` nos permission sets (corrigida). Segundo dry-run e deploy real passaram (Deploy ID `0AfHa00000EI10nKAD`).
- Retrieve de referência (XML dos relatórios existentes) ficou em `/tmp/eplast37-proj`, fora de `force-app/`.

## Versões e ativação
Nenhuma. Não há Flow, agente ou classe alterados; nenhuma versão nova nem ativação. Relatórios e campo ficam disponíveis no deploy.

## Premissas do design (PA-11 a PA-17, P5)
Seguidas como decididas; nenhuma virou pendência.

## Para a verificação
Massa sintética por script em `fixtures/` (design, seção 14); ler valor do campo e relatórios só por rótulos e contagens; usuário de teste `005bJ00000piKAaQAM`.
