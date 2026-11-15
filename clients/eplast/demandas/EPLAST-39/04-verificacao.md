**Verificação:** inconclusiva
**Org de teste:** `sbx-eplast-dev`

# EPLAST-39 — Verificação (reverificação após a rodada 2 do build)

`sf org list` mostrou uma única org conectada: `sbx-eplast-dev` (sandbox `eplast--qa` da Eplast, que é a dev da esteira pela regra 5 do CLAUDE.md do cliente). Não toquei QA, produção nem Marketing Cloud. Todos os comandos usaram `--target-org sbx-eplast-dev`.

## Resumo
- Passaram com execução: CA-01, CA-02, CA-03, CA-04, CA-07, CA-10, CA-11 (por metadata), CA-12, CA-13. CA-05 passou parcialmente.
- Não exercitados: CA-08, CA-09 e a parte positiva de CA-06 (motivos abaixo). Nenhum caso executado falhou.
- Inconclusiva porque CA-08 e CA-09 (retorno por campanha) não puderam ser provados com dado na dev, por razão que o builder não resolve.

## Divergências encontradas
1. **Preflight desatualizado.** `00-preflight.md` foi gerado para a etapa `build` e diz "a demanda ainda não tem componentes no repositório". No disco os componentes existem: `git diff --name-only ae173a02 HEAD -- force-app` lista o campo `Lead.MKT_Origem_Agrupada__c`, 5 relatórios, o painel, as pastas, o grupo e o permission set; o commit `ce26e97e` é o do build. Na org também: o campo existe (`FieldDefinition`: Fórmula (Texto), calculado). O preflight não reflete o estado real.
2. **Relatórios de leads não rodam isoladamente pela API de relatórios.** `MKT_Leads_por_Origem` e `MKT_Conversao_Leads_por_Origem` não têm nenhum `<columns>` no XML (resumo só com agrupamento). `GET /analytics/reports/<id>` devolve `BAD_REQUEST` com código 203 ("nenhuma coluna selecionada"). Pelo painel os dois rodam e trazem dados (CA-07). Não consegui provar se o usuário que abrir o relatório direto na tela verá erro ou o resumo. Recomendo ao revisor abrir os dois relatórios na UI da dev. Não classifiquei como falha porque os critérios medem o painel e o total agrupado.
3. **Pré-condição do build confirmada.** Sem o permission set, o campo novo não aparece para o usuário de teste (`Invalid field` em SOQL). Com `PS_Marketing_AnaliseCampanhas` atribuído, o campo e o painel funcionam. Isso confirma a PA-07 (atribuição manual). Atribuí o PS ao usuário de teste durante a verificação e removi no fim.

## Casos

Dados de teste (todos com `TESTE EPLAST-39` no nome): 4 leads, sendo L1 e L2 com `LeadSource = Campanha`, L3 sem origem, L4 com `LeadSource = TESTE EPLAST-39 fora` (picklist não restrita). A dev tinha 0 leads antes.

| Caso | Critério | O que foi feito | Esperado | Obtido | Status |
|---|---|---|---|---|---|
| V1 | CA-01 | Atualizei o painel (`PUT /analytics/dashboards/01ZHa000001uFevMAE`) e li o componente "Leads por Origem" | Soma dos grupos igual ao total (4) | Total 4 = Campanha 2 + Fora da lista 1 + Sem origem 1 | passou |
| V2 | CA-02 | Mesmo componente; `SELECT LastName, LeadSource, MKT_Origem_Agrupada__c` nos 4 leads | Lead sem origem aparece como "Sem origem", nenhuma linha "-" | L3 = "Sem origem"; linha "Sem origem" = 1; sem linha "-" | passou |
| V3 | CA-03 | Idem, com L4 | Valor fora da lista cai em "Fora da lista", sem linha própria | L4 = "Fora da lista" (1); valor `TESTE EPLAST-39 fora` não aparece como linha | passou |
| V4 | CA-04 | Extraí os valores literais da fórmula do XML e comparei com o describe de `Lead.LeadSource` (13 ativos, picklist não restrita) | 13 valores iguais, sem sobra | 13 valores idênticos; apenas "Sem origem" e "Fora da lista" a mais, como definido | passou |
| V5 | CA-05 | Conferi o XML: `timeFrameFilter` em `CREATED_DATE` nos relatórios de Leads, Conversão e Oportunidades. Não alterei o intervalo na tela | Filtro de período nos relatórios | Filtro existe (2000-01-01 a 2099-12-31) nos 3 relatórios. O período não foi variado, e o painel não tem filtro próprio. `MKT_Desempenho_Campanhas` e `MKT_Resposta_Membros_Campanha` ficam sem filtro (desvio 3 do build, tipo de relatório não aceita) | passou parcial (premissa PA-05; recalculo por intervalo não exercitado) |
| V6 | CA-06 | Painel com 4 leads, nenhum convertido; tentei converter L1 por `Database.convertLead` | Taxa = convertidos / total por origem | Taxa 0% em todas as origens e no total, sem erro (fórmula roda). A conversão falhou com `Erro de validação em Conta: CNPJ incompleto ou inválido` (validation rule da org). Não inventei CNPJ | não executado (positivo); caso zero passou |
| V7 | CA-07 | Li os 5 componentes após o refresh (`componentDataStatus`, `errorCode`) | Nenhum componente com erro | Os 5 com status `DATA`, sem `errorCode`. Os 2 que davam erro 406/209 no build (Leads por Origem, Taxa de Conversão) agora trazem dado. Relatório de campanha agora é Summary (`reportFormat SUMMARY`) | passou |
| V8 | CA-08 | Tentei criar Campaign de teste com `ActualCost` por Apex anônimo | Retorno = valor ganho / custo real | `Campaign.Name is not writeable`: o usuário da dev não tem create em Campaign (`describe createable=false`). Painel/relatório de campanha rodam sem erro com 0 registros (`AMOUNT_WON` 0, `ROI` "-") | não executado |
| V9 | CA-09 | Idem V8 | Campanha sem custo não quebra e mostra célula em branco (PA-03) | Não consegui criar campanha. Metadata: `IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)` | não executado |
| V10 | CA-10 | `git diff --name-only ae173a02 HEAD -- force-app` | Só pasta Marketing_Origem_Retorno, campo novo, painel/pastas, grupo e PS | 11 arquivos, todos esses. Nenhum relatório ou painel fora da pasta | passou |
| V11 | CA-11 | `ObjectPermissions` e `FieldPermissions` do PS por SOQL | Sem create/edit/delete em Lead, Campaign, Opportunity; sem FLS de edição; com RunReports | Campaign, Lead, Opportunity: só Read. 0 FLS com edição. `PermissionsRunReports = true`. Não testei a edição negada com um usuário real | passou (metadata) |
| V12 | CA-12 | Procurei EmailAlert/EmailTemplate nos arquivos do diff; 0 `ApexTrigger` em Lead | Sem componente de envio nem automação nova | Nenhum no diff; 0 triggers em Lead. Nada criado em Account/Opportunity/Order | passou |
| V13 | CA-13 | Li `MKT_Leads_por_Origem.report-meta.xml` | Resumo, sem coluna pessoal, sem detalhe | Format Summary, `showDetails false`, 0 colunas | passou |
| V14 | CA-14 | `sf org list`: só `sbx-eplast-dev`, conectado; regra 5 do CLAUDE.md do cliente | Dev distinta da QA | QA da esteira não está conectada nesta sessão; a regra 5 já registra as duas orgs como distintas (IDs conferidos em 2026-11-15). Não é bloqueio | passou (por regra do cliente) |

## Concorrência e riscos do assessment
- Automação concorrente em Account/Opportunity/Order (CPQ, `OrderTrigger`): não se aplica a escrita. A demanda só cria campo fórmula, relatórios, painel e PS (V12). A tentativa de converter um lead disparou a regra de validação de CNPJ da Account, o que não prova nada sobre concorrência.
- Cobertura Apex de 10%: não se aplica, não há Apex.

## O que ficou sem prova
- CA-08 e CA-09: precisa de Campaign com custo e oportunidades ganhas com `CampaignId`. O usuário da dev não cria Campaign. Uma pessoa com perfil que crie Campaign deve criar duas campanhas `TESTE EPLAST-39` (uma com `ActualCost > 0` e uma ganha vinculada, outra sem custo) e abrir o relatório de campanha.
- CA-06 positivo: precisa de lead convertido. A conversão exige CNPJ válido na Account, dado que não inventei. Alguém precisa converter um lead de teste com CNPJ sintético válido.
- CA-05: variar o período na tela.
- Abertura direta dos relatórios `MKT_Leads_por_Origem` e `MKT_Conversao_Leads_por_Origem` na UI (divergência 2).
- CA-11: tentativa de edição negada com usuário real.
- Observação: a API trata PA-02: o `ROI` nativo permanece com o rótulo padrão (já declarado no build).

## O que pode ter saído da org
Nada. A cadeia não tem Flow, Apex, trigger nem integração em Lead; nenhuma chamada externa. Marketing Cloud intocado.

## Limpeza
- 4 leads `TESTE EPLAST-39` apagados (`SELECT COUNT(Id) FROM Lead` = 0, mesmo estado inicial).
- Atribuição de `PS_Marketing_AnaliseCampanhas` ao usuário de teste removida (0 atribuições, mesmo estado inicial).
- A conversão falhou e foi revertida: 0 contas `TESTE EPLAST-39`.
- Nenhum job agendado criado. O painel ficou com dados atualizados na última execução (inclui os leads agora apagados), até o próximo refresh.
- Nada ficou na org.
