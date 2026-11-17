**Verificação:** aprovada
**Org de teste:** `sbx-eplast-dev` (Sandbox, Connected; org 00DHa000006vfMLMAY; única org listada por `sf org list`)

# EPLAST-39 — Verificação (rodada 3: origem dos leads e retorno das campanhas)

Build verificado: branch `feature/EPLAST-39`, commit a970e4d0. Só dev, só metadata e agregados; nenhum registro real lido. Premissas PA-07 a PA-14 tratadas como decididas.

## Dados de teste e estado do usuário
- Leads: `fixtures/lead.apex` (8 leads, 2 convertidos) mais 7 leads extras (sinônimos: Site, Meta Ads, Parceiros, "feiras", " SDR ", Indicação, Busca orgânica). Campanhas e oportunidades: `fixtures/campanha_oportunidade_ganha.apex`. Ajustes só em registros `TESTE EPLAST-39`: `LeadSource='Google Ads'` na Opp 1, `StartDate` de hoje nas 2 campanhas, mais 1 campanha `TESTE EPLAST-39 Camp Mes Anterior` (início em 22/10, custo 500).
- Usuário da esteira `005bJ00000piKAaQAM` (dev): `UserPermissionsMarketingUser` false para true e `ProtheusSellerId__c` vazio para `TESTE39`, ambos **devolvidos** (false e vazio, conferido por consulta).
- Permission set `PS_Marketing_AnaliseCampanhas`: estava atribuído a esse usuário (`0PaHa00000ELYDCKA5`, feito no build). **Atribuição removida** ao fim; a consulta devolve 0 atribuições.
- Limpeza: Case, Opportunity, Campaign, Lead, Account, Branch__c e PaymentTerms__c `TESTE EPLAST-39` apagados. Contagens finais: Lead 4 (os 4 que já existiam), Campaign 0, Opportunity 0, Account/Case de teste 0. Nada ficou. Perfil, papel e outros usuários intocados.
- Estado da org no início: 420 relatórios (419 da linha de base + `MKT_Origem_Original_por_Grupo`) e 21 painéis.

## O que pode ter saído da org
Nada. Contas e conversões com `TriggerUtility.bypassTrigger=true` (sem consulta BrasilAPI nem envio ao Protheus); nenhum e-mail, Flow de disparo ou chamada externa nesta demanda. Cases de pós-vendas gerados pela automação existente foram apagados (0 restantes).

## Resultados

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V-01 | CA-04', CA-03' | SOQL dos 15 leads de teste lendo `LeadSource` e `MKT_Origem_Agrupada__c` | Sinônimos no grupo certo, minúsculo e com espaço, vazio e não reconhecido tratados | Site para Site/formulário, Meta Ads, Parceiros, "feiras" para Eventos/feiras (UPPER), " SDR " para Prospecção ativa/SDR (a plataforma já grava `SDR` sem espaço, então o TRIM não foi provado isoladamente), Indicação, Busca orgânica, Google Ads certos; vazio para "Sem origem"; "Origem Inventada XYZ" para "Outros". "Campanha" e "WhatsApp" caem em "Outros" conforme o de-para do build | passou |
| V-02 | CA-01', CA-02 | Painel: `PUT` + `GET`, componente "Leads por Origem" | Soma dos grupos = total de leads do mês; nenhuma linha "-" | 10 grupos, soma 19 (4 existentes + 15 de teste), total `T!T` = 19; Sem origem 5 | passou |
| V-03 | CA-05' | Relatório Desempenho: campanha com início no mês anterior | Não aparece com filtro "Este mês" | Só as 2 campanhas do mês; filtro `START_DATE` = ESTE MÊS | passou |
| V-04 | CA-05' | Mesmo relatório via POST com filtro `THIS_QUARTER` | Recalcula e inclui a de mês anterior | 3 campanhas, incluindo `Camp Mes Anterior` | passou |
| V-05 | CA-05' | Metadata dos relatórios (GET `describe`) | Mês atual como padrão | Leads: `CREATED_DATE` `THIS_MONTH` (01 a 30/11/2026); Oportunidades idem; Desempenho e Resposta: `START_DATE` equals ESTE MÊS | passou |
| V-06 | CA-15 | Tooling `CustomField.Metadata.formula` de `Lead.MKT_Origem_Agrupada__c` e `Opportunity.MKT_Origem_Agrupada__c` | Texto idêntico | 1349 caracteres cada, comparação `==` verdadeira | passou |
| V-07 | CA-15 | Relatório `MKT_Oportunidades_por_Origem` com 2 opps de teste | Agrupa pelos mesmos grupos | Google Ads (R$ 2.500) e Sem origem (R$ 700), grupo `Opportunity.MKT_Origem_Agrupada__c` | passou |
| V-08 | CA-16 | `MKT_Origem_Original_por_Grupo` via POST com coluna de detalhe sobreposta só na requisição (o relatório salvo dá 203) | Valor original visível dentro do grupo, inclusive em "Outros" | Outros: Campanha 3, WhatsApp 2, Origem Inventada XYZ 1; Eventos/feiras: "feiras" 1; Sem origem: "-" 5; `LeadSource` intacto na consulta SOQL | passou |
| V-09 | CA-09' | Campanhas de teste: campo `MKT_ROI_Situacao__c` e grupo no relatório Desempenho | Sem custo = "Não calculável", sem erro | Custo 1000 = Calculável; vazio = Não calculável; relatório executa sem erro | passou |
| V-10 | CA-08' | Metadata do relatório Desempenho | ROI nativo, sem fórmula de retorno paralela | Colunas: ACTUAL_COST, BUDGETED_COST, NUM_*, AMOUNT_WON, ROI; sem coluna de fórmula | passou |
| V-11 | CA-17 | `dashboardMetadata` do painel e `description` do relatório | Texto "Não é faturamento" visível | Rodapé do componente: "Receita atribuída = valor das oportunidades ganhas vinculadas à campanha. Não é faturamento."; `description` do relatório com "NAO e faturamento" | passou |
| V-12 | CA-07 | `PUT` e `GET` do painel `01ZHa000001uFevMAE` com a massa | 5 componentes com dado, sem `errorCode` | 5 de 5 `DATA`, `errorCode` nulo; leads, conversão (Outros 33%, Sem origem 20%), desempenho (R$ 2.500 e R$ 700), oportunidades por origem. O componente "Respondentes por campanha" ficou sem agrupamento porque não criei membros de campanha (limitação da massa) | passou |
| V-13 | CA-10 | Contagem de relatórios e painéis; lista dos arquivos alterados no build | Só pasta, 3 campos e PS | Relatórios 420 (419 + 1 novo), painéis 21; 14 arquivos, todos de pasta, campos, grupo, PS, relatórios e painel | passou |
| V-14 | CA-12, CA-13 | `git diff` dos arquivos de `force-app` | Sem Flow, Apex, trigger, e-mail; sem dado pessoal | 0 arquivos de flows, classes, triggers ou e-mail; relatórios Summary sem colunas de nome, e-mail ou telefone | passou |
| V-15 | CA-11 | Acesso do usuário só com o PS, sem edição | Lê relatórios, não edita Lead, Opportunity ou Campaign | Não executado: o único usuário ativo é Administrador do sistema, não serve de prova de acesso negado. A metadata do PS (diff) só traz FLS de leitura nos 2 campos novos, sem edição nem ViewAll/ModifyAll. Fica para a homologação ou para o procedimento do card de 16/11 | não executado |

## Observações
- **Relatórios de Lead (Summary sem coluna de detalhe):** `GET` direto devolve 203 ("nenhuma coluna selecionada"), como no build. Foram exercitados pelo painel e, no caso de `MKT_Origem_Original_por_Grupo`, por POST com coluna sobreposta só na requisição, sem salvar. Os 3 relatórios de Lead são do mesmo tipo da rodada anterior; não considero defeito, pois o painel os executa com dado.
- O relatório de Campanha só enxerga campanha com `StartDate` preenchida: a fixture atual cria campanha sem data, então precisei preencher a data. Sugiro incluir `StartDate=Date.today()` em `fixtures/campanha_oportunidade_ganha.apex`; não alterei a fixture.
- Não foi provado: TRIM isolado (a plataforma já apara o valor), "Respondentes por campanha" com membros, e CA-11 (V-15).

## Resumo por critério
CA-01', CA-02, CA-03', CA-04', CA-05', CA-07, CA-08', CA-09', CA-10, CA-12, CA-13, CA-15, CA-16, CA-17: executados e aprovados. CA-11: não executado na dev (ver V-15). CA-14: resolvido pela regra 5 da conta.
