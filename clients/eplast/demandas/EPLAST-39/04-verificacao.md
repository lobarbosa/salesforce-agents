**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (usuário de integração da dev, sandbox `eplast--qa` da Eplast = dev da esteira, regra 5 do CLAUDE.md do cliente; instância `eplast--qa.sandbox.my.salesforce.com`)

# EPLAST-39 — Verificação (reverificação após a rodada 2 do build)

`sf org list` mostrou uma única org conectada, `sbx-eplast-dev`. Todos os comandos usaram `--target-org sbx-eplast-dev`. Não toquei QA, produção nem Marketing Cloud. Não alterei `force-app/`.

## Divergências com a esteira
- `00-preflight.md` (etapa build) diz "sem componentes no repositório". Está desatualizado: o build existe (`04-plano-build.md`, "concluído") e os componentes estão na org (`CustomField` `Lead.MKT_Origem_Agrupada` confirmado por Tooling API).
- `clients/eplast/fixtures/` não existe, então não havia script de fixture a reutilizar.

## Resumo
Não consegui exercitar com dado os critérios principais (CA-01 a CA-03, CA-06, CA-08, CA-09), por dois bloqueios de acesso do usuário de execução que o builder não resolve e que eu não posso alterar (perfil e permissão do usuário ficam intocados):

1. **FLS.** O usuário de execução não enxerga `Lead.MKT_Origem_Agrupada__c`: está fora do `describe` do Lead e o Apex anônimo recusa `SELECT MKT_Origem_Agrupada__c` com "Invalid field". As únicas FLS do campo estão no `PS_Marketing_AnaliseCampanhas` e num PS do sistema, e o PS tem 0 atribuições (PA-07). Atribuí-lo a este usuário seria alterar permissão dele, fora do que a esteira me autoriza. Sem isso não dá para criar Lead e ler a origem agrupada, nem abrir os relatórios que a usam.
2. **Campanha.** O Apex anônimo recusa gravar `Campaign.Name` ("Field is not writeable"), embora o perfil tenha Create em Campaign. Não consegui criar campanha de teste (CA-08, CA-09). Não alterei o usuário.

Nenhum defeito de build foi observado nos casos executados. A falha do painel é a que o builder já previu como dependente do PS.

## Casos

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | CA-04 | Comparei os 13 valores do `CASE` do campo (XML do repositório) com `describe` de `Lead.LeadSource` (13 ativos, picklist não restrita) | Os 13 iguais | 13 iguais, nenhum a mais ou a menos | passou |
| V2 | CA-01, CA-02, CA-03 | Tentei inserir leads `TESTE EPLAST-39` e agrupar por `MKT_Origem_Agrupada__c` por Apex anônimo | Soma = total; "Sem origem"; "Fora da lista" | Compilação falhou: `Invalid field: 'MKT_Origem_Agrupada__c'` (FLS). Nenhum lead criado | não executado |
| V3 | CA-06 | Depende de V2 | Taxa = convertidos / total | Não executado | não executado |
| V4 | CA-08, CA-09 | Tentei criar campanhas `TESTE EPLAST-39` (com custo 100 e sem custo) e oportunidades ganhas | Retorno = receita / custo; sem custo em branco | Compilação falhou: `Field is not writeable: Campaign.Name`. Nada criado | não executado |
| V5 | CA-07 | `PUT /analytics/dashboards/01ZHa000001uFevMAE` (atualização) e `GET` do painel | 5 componentes sem erro | 3 sem erro (Oportunidades e Valor por Origem, Respondentes por Campanha, Desempenho de Campanhas: o erro 209 da F1 sumiu). 2 com erro: `01aHa000001JiG5IAK` erro 406 ("campos selecionados... não estão mais disponíveis") e `01aHa000001JiG6IAK` erro 209. Causa provável: FLS do campo novo para o usuário do painel (`LoggedInUser`), como previsto pelo builder | não executado (parcial: 3 de 5) |
| V6 | CA-11 | Consultei `PermissionSet` e `ObjectPermissions` do `PS_Marketing_AnaliseCampanhas` | Só leitura | `RunReports` true; `ModifyAllData` false; `EditReadonlyFields` false; Create/Edit/Delete false em Lead, Campaign e Opportunity; FLS do campo com Read true e Edit false | passou |
| V7 | CA-12 | `SELECT COUNT(Id) FROM ApexTrigger WHERE TableEnumOrId IN ('Lead','Campaign')`; revisão do plano de build | Nenhum trigger/automação nova | 0 triggers; plano declara sem Flow, Apex ou e-mail; nada feito no Marketing Cloud | passou |
| V8 | CA-05 | Não exercitado: depende de abrir relatório com FLS e de dado | Período recalcula totais | Só metadata declarada pelo build; desvio 3 do build (2 relatórios de campanha sem filtro de período) segue valendo | não executado |

CA-10, CA-13 e CA-14 não foram reexecutados nesta rodada; ficam como declarado no plano de build (por metadata, sem prova própria minha).

## O que ficou sem prova e o que uma pessoa precisa fazer
- Atribuir `PS_Marketing_AnaliseCampanhas` ao usuário de teste da dev (passo manual PA-07), atualizar o painel de novo e conferir os componentes 406 e 209. Se o erro persistir com o PS, é defeito de build.
- Dar ao usuário de teste permissão para criar Campaign (por exemplo Marketing User), ou usar usuário que já a tenha, para provar CA-08 e CA-09.
- Com isso, rerodar V2 a V5 com massa sintética `TESTE EPLAST-39`.

## Dados de teste e limpeza
Nenhum registro foi criado (0 Lead, 0 Campaign, 0 Opportunity antes e depois; as inserções falharam na compilação). Nenhum campo de usuário foi alterado. A atualização do painel (`PUT`) só reprocessa relatórios, sem DML.

## O que pode ter saído da org
Nada. Nenhum registro criado, nenhuma chamada externa, nenhum e-mail.
