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
