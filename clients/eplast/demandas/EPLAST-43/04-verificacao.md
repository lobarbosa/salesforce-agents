**Verificação:** aprovada
**Org de teste:** sbx-eplast-dev

# EPLAST-43 - Verificação do build (rodada 2)

Org conferida com `sf org list`: `sbx-eplast-dev` (sandbox, Connected, único alias). Só dev. Nada em QA, produção ou Marketing Cloud. Nenhum DML, nenhum Apex anônimo, nenhum deploy nesta rodada: só consultas e um retrieve para diretório temporário (descartado). Nenhum dado de cliente lido; só metadata e contagens.

## Reteste da rodada 1

Rodada 1 (`04-verificacao-rodada-1.md`): `reprovada`, com uma falha.

- **FALHA 1 (lista dos públicos ausente do plano, CA-03/Q10): corrigida.** `04-plano-build.md` traz agora a tabela "Públicos da pasta MARKETINGCLOUD" com 68 linhas (contadas nas linhas 80 a 147), cada uma com nome, tipo e filtro. Na dev, `SELECT COUNT(Id) FROM Report WHERE OwnerId='00lbJ000004l9K6QAI'` (pasta MARKETINGCLOUD) devolveu **68**. A conta fecha. O plano explica a diferença para os 64 da rodada 1 (outras demandas criaram relatórios na mesma pasta).
- Nenhum arquivo de `force-app` mudou depois do commit `a9788fda`, que a rodada 1 já exercitou. O commit `d5dffd52` só mexeu em plano, agente de QA e script de deploy. Por isso os casos de dado (Q1 a Q5) **não foram refeitos**: valem as evidências da rodada 1, que ainda constam em `04-verificacao-rodada-1.md`. Reconferi só o estado da metadata, abaixo.

## Evidência por critério (estado atual da dev)

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| R2-1 | CA-03 | Contagem de `Report` da pasta e tabela do plano | Lista no plano igual à org | 68 na org, 68 linhas no plano | passou |
| R2-2 | CA-02, CA-03 | `Report` por `DeveloperName` na pasta: `MSG_CONTATOS_CELULAR_APTOS`, `MSG_LEADS_CELULAR_APTOS`, `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` | 3 existem | Os 3 existem (mais `LEADS_PROSPECCAO_PRIORIDADE` da EPLAST-42, intacto, e `LEADS_ES_SQz`) | passou |
| R2-3 | CA-05 | `FieldPermissions` do `PS_Marketing_Publicos`, `PermissionsRead=true` | As 9 FLS novas presentes, as anteriores preservadas | 25 linhas. As 9 novas presentes (`Lead.LeadSource`, `Lead.MobilePhone`, `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__Mobile_Country_Code__c`, `Contact.LeadSource`, `Contact.MobilePhone`, `Contact.HasOptedOutOfEmail`, `Contact.et4ae5__Mobile_Country_Code__c`, `Account.Type`). As anteriores (EPLAST-36/37/42, ex.: `Lead.PriorityBand__c`, `Lead.MKT_Origem_Agrupada__c`, `Lead.MKT_Nutricao_Elegivel__c`) seguem lá. Eram 21 na rodada 1; as 4 a mais (`Lead.MKT_MC_Engajamento__c`, `Lead.MKT_MC_EngajamentoData__c`, `Lead.MKT_Nutricao_ProntoAbordagem__c` e `Lead.PriorityScore__c` ou equivalente, entre as listadas) vêm de outras demandas | passou |
| R2-4 | CA-05 | `Group` `Marketing_Publicos` | Existe | `00GHa000006bP5eMAE`, "Públicos de Marketing" | passou |
| R2-5 | CA-05 | `GET /folders/00lbJ000004l9K6QAI/shares` | `user/manage` preservado mais `group/view` | `user/manage` e `group/view` | passou |
| R2-6 | CA-04, CA-08 | Retrieve de `LEADS_ES_SQz` e `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` da dev; conferir filtros | `CONVERTED equals 0` presente | `LEADS_ES_SQz` na dev: `STATE=ES`, `EMAIL_OPT_OUT=0`, `Lead.et4ae5__HasOptedOutOfMobile__c=0`, `CONVERTED=0` | passou |
| R2-7 | CA-01 a CA-04 | Casos Q1 a Q5 da rodada 1 (dado sintético, Analytics API) | Ver rodada 1 | Passaram na rodada 1; sem mudança de `force-app` desde então | passou (evidência da rodada 1, não refeita) |
| R2-8 | CA-06, CA-07 | Rodada 1: grep de e-mail/envio e diff de `classes`, `triggers`, `flows`, `workflows`, `objects` | Zero | Zero. Sem mudança de `force-app` desde então | passou (rodada 1) |
| R2-9 | CA-08 | Contagem antes e depois nos 16 relatórios | Só mensurável na QA | Dev não tem lead real; cabe ao QA | não executado |
| R2-10 | CA-10 | Roteiro do cliente | Existe depois do QA | Artefato de etapa posterior | não executado |

## Colisão do relatório LEADS_ES_SQz (confirmada na org)

- Na dev, `LEADS_ES_SQz` tem o filtro `Lead.et4ae5__HasOptedOutOfMobile__c equals 0`. No XML da branch (`force-app/.../reports/MARKETINGCLOUD/LEADS_ES_SQz.report-meta.xml`) o campo **não aparece** (0 ocorrências); `CONVERTED` aparece nos dois.
- A construção desta demanda (`CONVERTED = 0`) está presente na dev e não removeu o filtro de celular. Não é defeito de configuração da dev.
- **Risco, não falha:** implantar os XMLs da branch sobre a dev ou a QA removeria o filtro de opt-out de celular nos relatórios afetados. O plano já avisa para baixar de novo a versão da org antes de reimplantar (o plano lista os 15 relatórios). Só `LEADS_ES_SQz` foi aberto por mim; nos outros 14 não comparei. Isso interessa à esteira (`scripts/implantar-build-qa.sh`) e ao PR: o revisor precisa decidir se a branch passa a carregar o XML da org.
- Os filtros de celular também aparecem em `LEADS_SEGMENTO_ALIMENTOS` e `SEGMENTO_ALIMENTOS` (divergência já registrada na rodada 1: Q1 e Q2 do design esperavam o lead e o contato 3, que têm só opt-out de celular; o arquiteto deve corrigir a premissa).

## Sobreposição com outras demandas

- `PS_Marketing_Publicos`: o que é da EPLAST-43 está lá e nada das outras demandas foi perdido (FLS de EPLAST-36/37/42 presentes, total 25).
- Pasta MARKETINGCLOUD: 68 relatórios; os da EPLAST-43 existem; `LEADS_PROSPECCAO_PRIORIDADE` (EPLAST-42) existe. Não consegui atribuir a cada demanda os 4 relatórios além dos 64 da rodada 1.
- `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` sobrepõe `LEADS_PROSPECCAO_PRIORIDADE` (EPLAST-42): risco já registrado no plano, para homologação.

## Sem prova

- CA-08, contagem antes e depois nos relatórios existentes: só mensurável na QAS, que tem dado.
- CA-10: roteiro do cliente, etapa de QA.
- Atribuir o PS a usuário e testar visibilidade: não é prova válida com usuário administrador (R6 do design); substituído pela conferência de `FieldPermissions`.

## Dados de teste e limpeza

Nenhum dado criado nesta rodada. Consulta `Lead` com prefixo `EPLAST43`: 0. Usuário de execução intocado. Nada saiu da org.
