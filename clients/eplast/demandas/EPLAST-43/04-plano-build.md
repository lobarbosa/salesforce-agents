**Resultado do build:** concluído

# EPLAST-43 - Plano de build

**Org conectada:** `sbx-eplast-dev` (única em `sf org list`, sandbox, Connected). **Branch:** `feature/EPLAST-43`. Solução 100% configuração: nada no Marketing Cloud, nenhum Flow, Apex, trigger, campo, objeto nem envio pelo CRM.

## Contexto desta rodada

O build anterior (commit `6ed819a9`) deixou tudo pronto menos `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`, porque a EPLAST-42 criou depois do design `LEADS_PROSPECCAO_PRIORIDADE`. O design foi reaprovado sem alteração (mesmo sha256 em `gates.md`), então construí o que ele manda e tratei a sobreposição como risco registrado, sem mexer no relatório da EPLAST-42.

## Componentes construídos e implantados na dev

| Passo | Componente | Resultado |
|---|---|---|
| B1 | Retrieve de `PS_Marketing_Publicos` e dos relatórios de Lead | Feito. `ReportFolder` não entra no `force-app` (design 7.3) |
| B2 | `PermissionSet:PS_Marketing_Publicos` | +9 FLS de leitura (`Lead.LeadSource`, `Lead.MobilePhone`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.LeadSource`, `Contact.MobilePhone`, `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__Mobile_Country_Code__c`, `Account.Type`). As 12 anteriores ficaram. Conferido na org: 21 FLS no total. Description com "EPLAST-43" |
| B3 | `Group:Marketing_Publicos` ("Públicos de Marketing"), sem membros | Existe na org (confirmado). `Group` por metadata não tem description; finalidade registrada aqui |
| B4 | Compartilhamento da pasta `MARKETINGCLOUD` | Conferido por `GET .../folders/<Id>/shares`: `user/manage` mais `group/view`. Comando abaixo |
| B5 | `CONVERTED equals 0` nos relatórios de Lead | 15 ajustados: `LEADS_SEGMENTO_` (8 setores), `LEADS_ES_SQz`, `LEADS_MG_26H`, `LEADS_RJ_24t`, `LEADS_SUL_0EK`, `LEADS_SP_2yf`, `Cpia_de_LEADS_SP_fWa`, `Cpia_de_LEADS_GERAL_D2D` |
| B6 | `MSG_CONTATOS_CELULAR_APTOS` (ContactList), `MSG_LEADS_CELULAR_APTOS` (LeadList) | Criados (rodada anterior) |
| B6 | `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` (LeadList, resumo, escopo `org`) | **Criado nesta rodada.** Rótulo "LEADS - PROSPECÇÃO ORIGEM E PRIORIDADE" (o rótulo do design passava de 40 caracteres e o 1º deploy falhou; deploy `0AfHa00000EI6dBKAT` Succeeded). Agrupa por `LEAD_SOURCE` e `Lead.PriorityBand__c`. Filtros: `EMAIL_OPT_OUT=0`, `CONVERTED=0`, `STATUS` em `Aberto - Não contatado,Contatado` (valores conferidos em `LeadStatus`), faixa diferente de `Sem dados suficientes`. Colunas: nome, empresa, e-mail, UF, setor |
| B7 | `clients/eplast/fixtures/README.md` e `eplast43_publicos.apex` | Escritos; **não executados** neste build (cabe ao verificador) |

## Arquivos alterados

- `force-app/main/default/permissionsets/PS_Marketing_Publicos.permissionset-meta.xml`
- `force-app/main/default/groups/Marketing_Publicos.group-meta.xml`
- 15 relatórios de Lead em `force-app/main/default/reports/MARKETINGCLOUD/`
- novos: `MSG_CONTATOS_CELULAR_APTOS`, `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` (`.report-meta.xml`)
- `clients/eplast/fixtures/README.md`, `clients/eplast/fixtures/eplast43_publicos.apex` (não implantados)

## Outras demandas nos mesmos componentes (preflight)

- EPLAST-36, 37 (homologação) e 42 (gate de build) também tocam `PS_Marketing_Publicos` e `reports/MARKETINGCLOUD`.
- Parti do XML retirado da org, só acrescentei FLS e critérios; nada foi removido. `LEADS_OlB` já tinha `CONVERTED` (outra demanda) e não foi alterado: são 15 relatórios, não 16. O permission set já tinha `Lead.MKT_Origem_Agrupada__c` e `Lead.PriorityBand__c` (EPLAST-42): dos 11 FLS do design, 9 eram novos; resultado final igual ao desenhado.
- `LEADS_PROSPECCAO_PRIORIDADE` (EPLAST-42) não foi tocado.

## Risco registrado: sobreposição com a EPLAST-42

`LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` e `LEADS_PROSPECCAO_PRIORIDADE` são parecidos. Diferem em: agrupamento (origem e faixa, contra só faixa), filtro de `STATUS` (só no novo) e opt-out de celular (só no da EPLAST-42, que é público multicanal). Se a Eplast achar redundante, é um relatório a apagar ou a fundir na homologação; nada depende dele. O arquiteto pode registrar isso no design.

## Comando do compartilhamento (B4, sem identificador de usuário; repetir na QA como passo pós-deploy)

`sf api request rest "/services/data/v67.0/folders/<Id da pasta MARKETINGCLOUD>/shares" --method POST --body '{"shares":[{"shareType":"Group","shareWithId":"<Id do grupo Marketing_Publicos>","accessType":"View"}]}' --target-org <alias>`

Exige o envelope `shares`. O POST acrescenta e preserva o compartilhamento nominal. Ids na dev: pasta `00lbJ000004l9K6QAI`, grupo `00GHa000006bP5eMAE`. Na QA os Ids são outros: resolver por `DeveloperName`.

## Confirmado via sf nesta sessão

`sf org list` (org); `LeadStatus` (4 valores); `FieldPermissions` do PS (21); `Group` `Marketing_Publicos` existe; compartilhamento da pasta; relatório novo na org após deploy. Nenhum SOQL de dado de cliente. Usuário de teste da regra 6 não foi usado neste build (só no fixture).

## Premissas

Nenhuma nova. PA-09 a PA-13 do design seguidas.

## Versões e ativação

Nada a ativar: sem Flow, agente ou classe.

## Para o verificador

- Rodar o fixture na dev, medir só contagens pela Analytics API e apagar o que criou (prefixo `EPLAST43-TESTE`).
- O `ReportFolder` não está no `force-app`.
- O Flow de atribuição de Lead pode trocar o dono do lead de teste; não é defeito.

## Correções da verificação 1

**Falha 1 (CA-03, Q10): lista dos públicos ausente do plano.** Corrigida só em documentação, sem alterar configuração nem reimplantar nada. A lista abaixo foi lida da dev em 2026-11-16 (`sf org list metadata -m Report --folder MARKETINGCLOUD` e retrieve para pasta temporária, descartada). Org: `sbx-eplast-dev`.

- Contagem hoje na dev: **68** relatórios na pasta `MARKETINGCLOUD`. A verificação contou 64 (63 do design mais `LEADS_PROSPECCAO_PRIORIDADE` da EPLAST-42); os 4 a mais entraram depois na dev, por outras demandas que mexem na mesma pasta (preflight: EPLAST-36, 37, 42, 44, 45, 46). Não identifiquei qual demanda criou cada um; não é desta demanda.
- Criados pela EPLAST-43: `MSG_CONTATOS_CELULAR_APTOS`, `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`. Ajustados (`CONVERTED = 0`): os 15 da seção B5. Os demais não foram tocados.
- Colisão a registrar: os 15 relatórios ajustados diferem dos XMLs da branch na dev. Conferi o conteúdo em `LEADS_ES_SQz`: a dev traz o filtro `et4ae5__HasOptedOutOfMobile__c = Falso`, que **não está** no XML versionado (é o que o verificador viu em Q1 e Q2). Nos outros 14 não abri o diff; a diferença pode ser a mesma ou só de formatação. Quem acrescentou o filtro não foi esta demanda. **Não reimplantar os XMLs da branch sobre a dev nem sobre a QA sem antes baixar de novo a versão da org**, ou o filtro seria removido. Arquivos afetados: `Cpia_de_LEADS_GERAL_D2D`, `Cpia_de_LEADS_SP_fWa`, `LEADS_ES_SQz`, `LEADS_MG_26H`, `LEADS_RJ_24t`, os 8 `LEADS_SEGMENTO_*` e `LEADS_SP_2yf`, `LEADS_SUL_0EK`. Fica para o arquiteto e o roteiro de homologação, como a verificação já indicou.

### Públicos da pasta MARKETINGCLOUD (nome, tipo de relatório, filtro)

Filtros no formato `campo operador valor`, como estão na dev. Operadores: `equals`, `notEqual`, `greaterThan`, `lessThan` etc. do metadata.

| Relatório (API name) | Tipo | Filtro |
|---|---|---|
| `AMPLIACAO_MIX_CONTATOS` | ContactList | EMAIL_OPT_OUT equals 0; EMAIL notEqual  |
| `CLASSIFICACAO_CONTAS_POR_CLASSE` | AccountList | (sem filtro) |
| `COMPRA_ULTIMOS_90_DIAS` | ContactList | Account.LastPurchase__c greaterOrEqual N_DAYS_AGO:90; Account.LastPurchase__c lessOrEqual TODAY; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `CONTAS_E_CONTATOS_RECORRENTES_6PU` | ContactList | TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `Cpia_de_CONTAS_E_CONTATOS_SAZONAIS_YaM` | ContactList | TYPE equals Sazonal; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `Cpia_de_LEADS_GERAL_D2D` | LeadList | STATUS equals Fechado - Não convertido; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `Cpia_de_LEADS_SP_fWa` | LeadList | STATE equals GO,DF,MT,MS,TO; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `Cpia_de_PROSPECTS_MG_Kk0` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals RJ; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `Cpia_de_RECORRENTES_ATIVOS_SP_hLD` | ContactList | ACCOUNT.ADDRESS1_STATE equals SP; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `Cpia_de_SAZONAIS_ES_u17` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals ES; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `INATIVOS_GERAL` | ContactList | TYPE equals Inativo; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `LEADS_BOAS_VINDAS` | LeadList | CONVERTED equals 0; EMAIL_OPT_OUT equals 0; STATUS notEqual Fechado - Não convertido |
| `LEADS_ES_SQz` | LeadList | STATE equals ES; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_MG_26H` | LeadList | STATE equals MG; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_OlB` | LeadList | EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | LeadList | EMAIL_OPT_OUT equals 0; CONVERTED equals 0; STATUS equals Aberto - Não contatado,Contatado; Lead.PriorityBand__c notEqual Sem dados suficientes |
| `LEADS_PROSPECCAO_PRIORIDADE` | LeadList | Lead.PriorityBand__c notEqual Sem dados suficientes; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_RJ_24t` | LeadList | STATE equals RJ; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_ALIMENTOS` | LeadList | Lead.Sector__c equals Alimentos; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_BEBIDAS` | LeadList | Lead.Sector__c equals Bebidas; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_DISTRIBUIDOR_VAREJO` | LeadList | Lead.Sector__c equals Distribuidor & Varejo; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_FARMACEUTICO` | LeadList | Lead.Sector__c equals Farmacêutico; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_HIGIENE_LIMPEZA` | LeadList | Lead.Sector__c equals Higiene & Limpeza; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_INDUSTRIAL` | LeadList | Lead.Sector__c equals Industrial; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_INDUSTRIA_DE_SOPRO` | LeadList | Lead.Sector__c equals Indústria de Sopro; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SEGMENTO_INDUSTRIA_DE_TRANSFORMACAO` | LeadList | Lead.Sector__c equals Indústria de Transformação; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SP_2yf` | LeadList | STATE equals SP; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `LEADS_SUL_0EK` | LeadList | STATE equals PR,SC,RS; EMAIL_OPT_OUT equals 0; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0 |
| `MSG_CONTATOS_CELULAR_APTOS` | ContactList | Contact.et4ae5__HasOptedOutOfMobile__c equals 0; PHONE3 notEqual  |
| `MSG_LEADS_CELULAR_APTOS` | LeadList | Lead.et4ae5__HasOptedOutOfMobile__c equals 0; CONVERTED equals 0; MOBILE_PHONE notEqual  |
| `NUTRICAO_LEADS_EMAIL` | LeadList | Lead.MKT_Nutricao_Elegivel__c equals 1; EMAIL_OPT_OUT equals 0; EMAIL notEqual  |
| `NUTRICAO_LEADS_MENSAGEM` | LeadList | Lead.MKT_Nutricao_Elegivel__c equals 1; Lead.et4ae5__HasOptedOutOfMobile__c equals 0; MOBILE_PHONE notEqual  |
| `POTENCIAIS_SEM_COMPRA` | ContactList | Account.RelationshipClass__c equals Potencial; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PRODUTO_CONTAS_POR_PRODUTO_COMPRADO` | OrderItemList | (sem filtro) |
| `PROSPECTS_CO_D3n` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals GO,DF,MT,MS,TO; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_ES_iu8` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals ES; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_GERAL_vjU` | ContactList | TYPE equals Prospect; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_MG_4jm` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals MG; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_NONE_xn7` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_NOVO_lId` | ContactList | TYPE equals Novo; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_SP_kvL` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals SP; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `PROSPECTS_SUL_OQ5` | ContactList | TYPE equals Prospect; ACCOUNT.ADDRESS1_STATE equals PR,SC,RS; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `REATIVOS_GERAL_rbp` | ContactList | TYPE equals Reativo; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_CO_I98` | ContactList | ACCOUNT.ADDRESS1_STATE equals GO,DF,MT,MS,TO; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_ES_cG0` | ContactList | ACCOUNT.ADDRESS1_STATE equals ES; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_MG_dSH` | ContactList | ACCOUNT.ADDRESS1_STATE equals MG; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_NORTE_E_NORDESTE_1nd` | ContactList | ACCOUNT.ADDRESS1_STATE equals AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_RJ_yuH` | ContactList | ACCOUNT.ADDRESS1_STATE equals RJ; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `RECORRENTES_ATIVOS_SUL_lXr` | ContactList | ACCOUNT.ADDRESS1_STATE equals PR,SC,RS; TYPE equals Recorrente; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_CO_tKS` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals GO,DF,MT,MS,TO; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_MG_Jfz` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals MG; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_MG_X7D` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals MG; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_NONE_lJc` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals AC,AP,AM,PA,RO,RR,AL,BA,CE,MA,PB,PE,PI,RN,SE; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_RJ_IxD` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals RJ; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_SP_qII` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals SP; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SAZONAIS_SUL_dZZ` | ContactList | TYPE equals Sazonal; ACCOUNT.ADDRESS1_STATE equals PR,SC,RS; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_ALIMENTOS` | ContactList | Account.Sector__c equals Alimentos; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_BEBIDAS` | ContactList | Account.Sector__c equals Bebidas; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_DISTRIBUIDOR_VAREJO` | ContactList | Account.Sector__c equals Distribuidor & Varejo; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_FARMACEUTICO` | ContactList | Account.Sector__c equals Farmacêutico; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_HIGIENE_LIMPEZA` | ContactList | Account.Sector__c equals Higiene & Limpeza; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_INDUSTRIAL` | ContactList | Account.Sector__c equals Industrial; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_INDUSTRIA_DE_SOPRO` | ContactList | Account.Sector__c equals Indústria de Sopro; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_INDUSTRIA_DE_TRANSFORMACAO` | ContactList | Account.Sector__c equals Indústria de Transformação; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEGMENTO_PET_BEM_ESTAR_ANIMAL` | ContactList | Account.Sector__c equals PET (Bem-estar animal); EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEM_COMPRA_181_A_365_DIAS` | ContactList | Account.LastPurchase__c lessOrEqual N_DAYS_AGO:181; Account.LastPurchase__c greaterOrEqual N_DAYS_AGO:365; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEM_COMPRA_91_A_180_DIAS` | ContactList | Account.LastPurchase__c lessOrEqual N_DAYS_AGO:91; Account.LastPurchase__c greaterOrEqual N_DAYS_AGO:180; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
| `SEM_COMPRA_MAIS_DE_365_DIAS` | ContactList | Account.LastPurchase__c lessThan N_DAYS_AGO:365; EMAIL_OPT_OUT equals 0; Contact.et4ae5__HasOptedOutOfMobile__c equals 0 |
