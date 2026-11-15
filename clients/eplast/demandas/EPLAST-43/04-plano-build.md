**Resultado do build:** bloqueado

# EPLAST-43 - Plano de build

**Org:** `sbx-eplast-dev` (única conectada; `sf org list`). **Branch:** `feature/EPLAST-43`. Nada no Marketing Cloud, nenhum Flow, Apex, campo ou objeto.

## Motivo do bloqueio (um item, o resto está construído)

O passo B6 pede criar `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE`, com base na afirmação do design (item 7, D4) de que "nenhum relatório agrupa por origem ou faixa". Na dev existe `LEADS_PROSPECCAO_PRIORIDADE` na pasta MARKETING CLOUD ("LEADS - PROSPECÇÃO PRIORIZADA", descrição EPLAST-42): LeadList, resumo, agrupado por `Lead.PriorityBand__c`, com `LEAD_SOURCE` como coluna e filtros `EMAIL_OPT_OUT=0`, `HasOptedOutOfMobile=0`, `CONVERTED=0` e faixa diferente de "Sem dados suficientes". Criar o novo duplicaria o existente (regra 3 da conta); alterar o existente mexeria no entregável de outra demanda. Não improvisei.
- **O que falta decidir (arquiteto):** (a) reaproveitar o existente sem criar o terceiro relatório (diferenças: ele agrupa só por faixa, não por origem, e não filtra `STATUS` aberto/contatado, e exclui quem recusou celular); ou (b) ajustar o existente (acrescentar agrupamento por `LEAD_SOURCE` e filtro `STATUS`); ou (c) criar o novo mesmo assim. Evidência para o design: a regra 3 favorece (a) ou (b). Não é pergunta de negócio ao cliente.
- A pergunta é do arquiteto; ao decidir, o CA correspondente e a seção 11 do design precisam do ajuste.

## Componentes construídos e implantados na dev (deploy `0AfHa00000EI5E5KAL`, Succeeded)

| Passo | Componente | Resultado |
|---|---|---|
| B1 | Retrieve de `PS_Marketing_Publicos` e dos relatórios de Lead | Feito. `ReportFolder` retirado e descartado do `force-app` (R2) |
| B2 | `PermissionSet:PS_Marketing_Publicos` | +9 FLS de leitura: `Lead.LeadSource`, `Lead.MobilePhone`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.LeadSource`, `Contact.MobilePhone`, `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__Mobile_Country_Code__c`, `Account.Type`. As 12 FLS anteriores e as permissões de objeto foram mantidas. Description com "EPLAST-43" (limite de 255 caracteres; texto antigo condensado, EPLAST-36 e 42 citadas) |
| B3 | `Group:Marketing_Publicos` ("Públicos de Marketing"), sem membros | Criado. `Group` por metadata não tem campo description; a finalidade fica neste plano |
| B4 | Compartilhamento da pasta | Feito por REST (ver abaixo). Pasta passou de `user/manage` para `user/manage` + `group/view` |
| B5 | Relatórios de Lead com `CONVERTED equals 0` | 15 ajustados (um critério cada): `LEADS_SEGMENTO_` (8 setores), `LEADS_ES_SQz`, `LEADS_MG_26H`, `LEADS_RJ_24t`, `LEADS_SP_2yf`, `LEADS_SUL_0EK`, `Cpia_de_LEADS_SP_fWa`, `Cpia_de_LEADS_GERAL_D2D` |
| B6 | `MSG_CONTATOS_CELULAR_APTOS` (ContactList) e `MSG_LEADS_CELULAR_APTOS` (LeadList) | Criados conforme itens 5 e 6, filtro "celular não vazio" como `notEqual` vazio, aceito no deploy (R4 não se materializou) |
| B6 | `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | **Não criado** (bloqueio acima) |
| B7 | `clients/eplast/fixtures/README.md` e `eplast43_publicos.apex` | Escritos, **não executados** (cabe ao verificador) |

## Divergências entre o design e a org (estado mudou desde o design)

- `LEADS_OlB` já tinha `CONVERTED` (de outra demanda): não alterado. Portanto são 15 relatórios ajustados, não 16.
- O permission set já tinha `Lead.MKT_Origem_Agrupada__c` e `Lead.PriorityBand__c` (EPLAST-42): dos 11 FLS do item 8, só 9 eram novos. Resultado final idêntico ao desenhado.

## Comando do compartilhamento (B4, sem identificador de usuário; repetir na QA como passo pós-deploy)

`sf api request rest "/services/data/v67.0/folders/<Id da pasta MARKETINGCLOUD>/shares" --method POST --body '{"shares":[{"shareType":"Group","shareWithId":"<Id do grupo Marketing_Publicos>","accessType":"View"}]}' --target-org <alias>`

O corpo exige o envelope `shares`; sem ele a API devolve `JSON_PARSER_ERROR`. O POST acrescenta e preserva o compartilhamento nominal. Ids na dev: pasta `00lbJ000004l9K6QAI`, grupo `00GHa000006bP5eMAE`. Na QA os Ids são outros: resolver por `DeveloperName`.

## Premissas e observações

- Nenhuma premissa nova. PA-09 a PA-13 seguidas.
- Verificador: o `ReportFolder` não está em `force-app`; descartei do `force-app` os relatórios retirados só como molde.
