**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast; usuário e Org Id omitidos, identificados pelo alias)

# EPLAST-39 — Verificação do build

Org conferida com `sf org list` (só `sbx-eplast-dev`, Connected). Nada na QA, nada no Marketing Cloud, nenhum dado pessoal lido, nenhum push.

## Por que inconclusiva
A dev tem 0 Lead e 0 Campaign (`SELECT COUNT(Id) FROM Lead` = 0; `FROM Campaign` = 0). O builder não criou massa (sem DML) e eu não criei: a instrução desta verificação foi de nenhum DML em registro. Sem dado, CA-01, 02, 03, 06, 08 e 09 não puderam ser provados com resultado. Nenhum caso executado falhou.

## Passo de configuração feito na dev (registrado)
Criei `PermissionSetAssignment` (`PS_Marketing_AnaliseCampanhas` para o usuário de teste da org de dev, identificado pelo alias), `0PaHa00000EIkh6KAD`. Atualizei o painel (`PUT /analytics/dashboards/01ZHa000001uFevMAE`) e li o status. Depois **removi** a atribuição (delete Success). Não ficou nada de teste na org. Nenhum outro registro foi criado.

## Resultado por CA

| CA | Status | Evidência |
|---|---|---|
| CA-01 soma = total | não executado | Org sem Lead. Fórmula cobre vazio, 13 valores e resto (leitura do XML); falta massa. |
| CA-02 vazio = "Sem origem" | não executado | Lógica `IF(ISBLANK(TEXT(LeadSource)),"Sem origem",...)` conferida no XML; sem Lead para exercitar. |
| CA-03 "Fora da lista" | não executado | `CASE(...,"Fora da lista")` no XML; sem Lead para exercitar. |
| CA-04 lista = picklist | passou | `sf sobject describe Lead`: 13 valores ativos de LeadSource (Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR) são idênticos, um a um, aos 13 do `CASE` da fórmula. |
| CA-05 período | passou (parcial, desvio 3 aceito) | `timeFrameFilter` INTERVAL_CUSTOM 2000-01-01 a 2099-12-31 presente em `MKT_Leads_por_Origem` (lido do arquivo). Desempenho de Campanhas e Resposta de Membros sem filtro, por limitação do tipo de relatório (desvio 3 do plano). |
| CA-06 conversão | não executado | `FORMULA1` mantida (plano); sem Lead para conferir contagem. |
| CA-07 painel sem erro | passou | Com o PS atribuído, `PUT` + `GET .../status`: os 5 componentes com `componentDataStatus: DATA`, `errorCode: null`. Leads por Origem (antes 406) e Taxa de Conversão (antes 209) sem erro. Valores 0 e `{}` porque a org não tem dado. Dependência: o usuário do painel precisa do PS (PA-07). |
| CA-08 retorno por campanha | não executado | Sem Campaign. O relatório e o componente rodam sem erro; resultado numérico não provado. |
| CA-09 campanha sem custo | não executado | `IF(ACTUAL_COST:SUM > 0, ..., null)` no plano; sem Campaign. |
| CA-10 nada existente alterado | passou (metadata) | `git status`: só `gates.md` e `status.yaml` modificados no working tree, escritos pela esteira; as alterações do build estão no commit `ce26e97e` e restritas ao plano. Não reconferi os 380 relatórios na org. |
| CA-11 somente leitura | passou | PS: `allowCreate`, `allowEdit`, `allowDelete`, `modifyAllRecords`, `viewAllRecords` = false; FLS `editable=false`, `readable=true`; `RunReports` presente. |
| CA-12 sem envio/automação | passou (metadata) | Plano só tem campo, relatórios, painel e PS; a análise confirma 0 `ApexTrigger` em Lead e Campaign. Nada tocado no Marketing Cloud. |
| CA-13 sem dado pessoal | passou (parcial) | `showDetails false` nos relatórios, conforme plano. Não consegui ver a saída com dado por falta de registro. |
| CA-14 ambiente | passou | `sf org list` mostra `sbx-eplast-dev`, Org Id 00DHa000006vfMLMAY; regra 5 do CLAUDE.md e card de 15/11. |

## O que falta para provar
Uma pessoa, na dev, cria poucos Leads sintéticos `TESTE EPLAST-39` (um sem origem, um por valor de picklist ou alguns, um com origem fora da lista, um convertido) e Campaigns com e sem `ActualCost` com oportunidades ganhas. Depois confere: soma dos grupos = total (CA-01), rótulos "Sem origem" e "Fora da lista" (CA-02, CA-03), taxa de conversão (CA-06), retorno e célula vazia (CA-08, CA-09). Se o gate autorizar DML sintético, é um reteste curto.

## O que pode ter saído da org
Nada. Nenhuma automação foi disparada e nenhum registro de negócio foi criado.
