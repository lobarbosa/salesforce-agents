# EPLAST-39 — Design: Origem dos leads e retorno das campanhas (rodada 2)

**Org consultada:** alias `sbx-eplast-dev` (Sandbox, Enterprise Edition, `IsSandbox = true`, API 68.0). Só leitura nesta etapa: metadata, Analytics API (GET) e `COUNT()`. Nenhum DML, nenhum deploy.
**Insumos:** `01-analise.md` (aprovada em 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, `rodada-anterior/05-testes-rodada-1.md`, metadata da rodada anterior em `force-app/` (commit `de897e19`), skill `salesforce-doutrina` (seção "Relatórios e painéis por metadata", escrita a partir desta própria demanda).

**Estimativa de esforço:** 8–12 h
Mudou em relação à análise (12–18 h): os 5 relatórios, o painel, as pastas, o grupo e o permission set já estão implantados na org e versionados em `force-app/`; o build é de correção (1 campo fórmula, 3 relatórios ajustados, 1 componente de painel, permission set) e não de construção. A doutrina já registra as armadilhas de XML que custaram a rodada 1. A faixa ainda inclui a massa sintética (org vazia) e a verificação de cada componente pela Analytics API. Não inclui o tempo de resolver o bloqueio B1 (ambiente).

---

## 0. Bloqueios e decisões que precisam do arquiteto humano

| # | Tipo | O quê | Efeito |
|---|---|---|---|
| **B1** | **Bloqueio operacional (guardrail #1), não de negócio** | O alias `sbx-eplast-dev` aponta para `https://eplast--qa.sandbox.my.salesforce.com` e não há alias `sbx-eplast-qa` nesta sessão para comparar (assessment, achado 6; análise R6/PC-1/CA-14). | **O build não escreve nada na org enquanto alguém da equipe não confirmar que `sbx-eplast-dev` é a sandbox de dev.** O agente não contorna. |
| **E1** | **Mudança de modelo de dados — escalada ao arquiteto humano** | Criar o campo fórmula `Lead.MKT_Origem_Agrupada__c` (seção 2, D1). É o único jeito declarativo e versionável de atender CA-02 e CA-03. | Se aceito, segue o desenho. Se recusado, o build usa a alternativa B da seção 2 e CA-02/CA-03 passam a premissa "rótulo ajustado à mão / uma linha por valor". |

Evidência nova sobre B1, para acelerar a decisão (não resolve sozinha): o painel desta org tem Id `01ZHa000001uFevMAE` e 0 leads; o painel testado pelo QA na rodada 1 em `sbx-eplast-qa` tinha Id `01ZHa000001uI4vMAE` e 712 leads (`rodada-anterior/05-testes-rodada-1.md`). Os relatórios desta org têm `LastModifiedDate` 2026-11-12T03:30, o mesmo minuto do build da rodada 1. Ou seja: o alias de dev e a org testada pelo QA **parecem ser orgs distintas**, e o nome `--qa` da instância seria só nomenclatura. Isto é indício, não confirmação: quem administra as sandboxes confirma.

Perguntas de negócio em aberto (caso 3 da regra 4): **nenhuma**.

---

## 1. Diagnóstico das falhas da rodada 1 (confirmado na org)

| Falha | Causa | Prova |
|---|---|---|
| F1 — componente "Desempenho de Campanhas" com erro | `MKT_Desempenho_Campanhas` é **Tabular** sem agrupamento e sem "Configurações do Painel". Erro 209 permanente, independe de dado. | `SELECT DeveloperName, Format FROM Report WHERE FolderName='Origem e Retorno de Campanhas'` → Tabular; `GET /analytics/dashboards/01ZHa000001uFevMAE` → componente `01aHa000001JFqqIAG` com `errorCode 209` nesta org também. |
| F1 — outros 4 componentes com `NO_DATA` | **Não confirmada.** Nesta org os 4 aparecem `dataStatus = null`, `refreshStatus = IDLE`, sem erro, mas a org tem 0 registros e o painel nunca foi atualizado. Hipótese principal: o QA tentou atualizar com `GET ...?refreshDashboard=true`, que não é a forma documentada de atualizar pela Analytics API (a atualização é `PUT /analytics/dashboards/<id>`, depois `GET .../status`). Hipótese secundária: algum `chartSummary` aponta para coluna sem agregação no relatório. | Leitura da API nesta sessão; XML do painel em `force-app/`. |
| F2 — vazio aparece como "-" | Bucket de picklist não aceita entrada para vazio (`<sourceValues/>` deu erro interno na rodada 1); `nullTreatment n` mostra "-". | Doutrina, seção "Bucket sobre picklist"; XML `MKT_Leads_por_Origem` (39 `sourceValue`, sem vazio). |
| F3 — "Fora da lista" não agrupa | `otherBucketLabel` não consolida valores soltos de picklist **não restrita**. | Doutrina; describe `Lead.LeadSource` (não restrita). |
| (não reportada) CA-05 período | Nenhum relatório tem `timeFrameFilter` e o painel não tem `dashboardFilters`. O filtro de período não existe. | `grep` nos XML de `force-app/`. |
| (não reportada) permissão | `PS_Marketing_AnaliseCampanhas` tem `PermissionsRunReports = false` e 0 atribuições; o grupo `Marketing_Origem_Retorno` tem 0 membros. Um usuário só com o PS não roda relatório. | `SELECT PermissionsRunReports ... FROM PermissionSet`; `COUNT()` em `PermissionSetAssignment` e `GroupMember`. |

---

## 2. Decisão e justificativa

**Abordagem: configuração nativa (nível 1).** Relatório, painel, campo fórmula e permission set. **Sem Flow, sem Apex, sem trigger.** Não há regra que exija automação: tudo é leitura agregada. Descer para Flow ou Apex não traria nada e criaria automação em Lead, que a análise exclui (CA-12).

### D1 — Agrupamento de origem por campo fórmula (resolve F2 e F3) — escalado em E1

Alternativas:

| | Alternativa | Atende CA-02/03? | Custo e risco |
|---|---|---|---|
| **A (escolhida)** | Campo fórmula texto `Lead.MKT_Origem_Agrupada__c`: vazio → "Sem origem"; um dos 13 valores → o próprio valor; qualquer outro → "Fora da lista". Relatórios agrupam por ele. | Sim, por metadata, versionado, testável. | Um campo novo em Lead (modelo de dados → E1). Sem armazenamento, sem automação, sem carga retroativa (fórmula vale para lead antigo e novo). Manutenção: quando a Eplast criar valor novo na picklist, a fórmula precisa do valor (senão cai em "Fora da lista", que é o comportamento seguro). |
| B (alternativa se E1 for recusada) | Manter o bucket de picklist; renomear "-" para "Sem origem" à mão na tela do relatório, em dev e em QA; aceitar uma linha por valor solto. | Parcial: CA-02 por passo manual não versionado; CA-03 não. | Passo manual repetido em cada org; volta a falhar em qualquer redeploy. |
| C | Flow ou Apex gravando um campo texto em Lead. | Sim. | Automação nova em Lead (contraria CA-12), exige carga dos leads antigos, armazenamento. Pior em tudo que A. |

Bônus de A: a picklist é não restrita, então integração pode gravar valor com grafia diferente (doutrina, achado SOMOSAGILITY-21). A fórmula põe isso em "Fora da lista" em vez de espalhar linhas. O mesmo campo serve ao Marketing Cloud para segmentar por origem (seção 6).

Fórmula (os 13 API names foram conferidos por describe nesta sessão: valor = rótulo em todos, 0 inativos):
```
IF(ISBLANK(TEXT(LeadSource)), "Sem origem",
  CASE(LeadSource,
    "Campanha","Campanha", "WhatsApp","WhatsApp", "Indicação","Indicação", "Evento","Evento",
    "Google Ads","Google Ads", "Google Orgânico","Google Orgânico", "Instagram","Instagram",
    "Facebook","Facebook", "Prospecção ativa","Prospecção ativa", "Prospecção passiva","Prospecção passiva",
    "Econodata","Econodata", "E-mail MKT","E-mail MKT", "SDR","SDR",
    "Fora da lista"))
```
`Description` obrigatória (assessment achado 4): "EPLAST-39. Agrupa LeadSource para relatório e segmentação: vazio = Sem origem; fora dos 13 valores = Fora da lista. Ao incluir valor novo na picklist LeadSource, incluir também aqui."

### D2 — `MKT_Desempenho_Campanhas` de Tabular para Summary (resolve F1, componente 4)

Alternativas: (a) Summary agrupado por `CAMPAIGN_NAME`; (b) manter Tabular com "Configurações do Painel" (`tableRowLimit` + coluna de agrupamento). Escolho (a): é o formato que a doutrina indica como seguro e o mesmo dos outros 4 relatórios, que não deram 209. Detalhe:
- Tipo `CampaignList` (mantido). Agrupamento `CAMPAIGN_NAME`. Colunas conferidas no describe do tipo nesta sessão: `ACTUAL_COST`, `AMOUNT_WON`, `ROI` (percent, nativo), `NUM_LEADS`, `CAMPAIGN_TYPE`, `START_DATE`, `CREATED_DATE`.
- `ACTUAL_COST` e `AMOUNT_WON` com agregação `Sum` (o componente usa `AMOUNT_WON` como `chartSummary`; precisa da agregação no relatório e `<aggregate>Sum</aggregate>` no componente).
- Fórmula de resumo "Receita ganha ÷ custo" (P7, CA-08): `IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)` — campanha sem custo fica em branco, sem erro de divisão (CA-09, premissa PA-03).
- Mantém a coluna nativa `ROI` como informação complementar, com rótulo próprio (ela é `(ganho − custo) ÷ custo`, fórmula diferente da P7; premissa PA-02).
- `showDetails = false`.

### D3 — Relatórios de origem passam a agrupar pela fórmula
- `MKT_Leads_por_Origem` e `MKT_Conversao_Leads_por_Origem`: remover o bucket `BucketField_Origem`; agrupar por `Lead.MKT_Origem_Agrupada__c` (o nome exato da coluna no tipo `LeadList` o builder confere no describe `/analytics/report-types/LeadList` após o deploy do campo). Manter o segundo agrupamento `CREATED_MONTH`, a fórmula `CONVERTED:SUM / RowCount`, `scope org`, `showDetails false` (CA-13).
- Ajustar o `groupingColumn` dos componentes 1 e 2 do painel para a nova coluna.
- `MKT_Oportunidades_por_Origem` e `MKT_Resposta_Membros_Campanha`: **sem alteração** (premissa PA-04 para o primeiro).

### D4 — Período (CA-05)
- Preferido: filtro de painel sobre data de criação. Não há exemplo de `dashboardFilters` com data na org versionada e a doutrina proíbe adivinhar enum. Regra para o builder: retrieve de um painel ou relatório da org que já use filtro de data e copie a sintaxe; **duas tentativas recusadas → pare e use o fallback**.
- Fallback: cada relatório ganha filtro padrão de data (`timeFrameFilter` sobre `CREATED_DATE`, intervalo "todo o período") copiado de relatório existente da org; o usuário muda o período no relatório. CA-05 passa a valer por relatório, não pelo painel (premissa PA-05).

### D5 — Atualização e verificação do painel (F1, os 4 `NO_DATA`)
- O painel continua `LoggedInUser` (não grava username no metadata; já implantado e contado: 4 painéis dinâmicos na org).
- No build, depois da massa sintética: `PUT /analytics/dashboards/<id>` (atualiza), aguardar, `GET /analytics/dashboards/<id>/status` e `GET /analytics/dashboards/<id>`. Ler só `status.dataStatus`, `errorCode` e totais agregados. Qualquer componente com `errorCode` ou `NO_DATA` é defeito de build (doutrina), não achado para o QA.
- Instrução ao QA: atualizar pelo `PUT`, não por `?refreshDashboard=true`.

### D6 — Permission set (reaproveita)
`PS_Marketing_AnaliseCampanhas`: hoje Read em Campaign, Lead, Opportunity e FLS de leitura em 6 campos, sem edição (confirmado). Acrescentar: FLS leitura em `Lead.MKT_Origem_Agrupada__c` e a permissão de sistema `RunReports` (premissa PA-06). Nada de edição, `ViewAllData`, `ModifyAllData` ou "Marketing User".

---

## 3. Reaproveita / cria / altera — item a item (regra 3)

| Item | Ação | Prova de que existe | Observação |
|---|---|---|---|
| `Lead.LeadSource` (13 valores, não restrita) | Reaproveita, sem alteração | describe | Fonte da origem |
| `Lead.MKT_Origem_Agrupada__c` (fórmula texto) | **Cria** (E1) | Confirmado que **não** existe: lista dos 12 campos custom de Lead | Nenhum campo de origem/UTM custom em Lead (lista completa: CNAE, CompanyDocument, CompanyName, Facebook, Instagram, LinkedIn, Subsector, WhatsApp, Sector, 2 `et4ae5__`, 1 `maps__`) |
| `Opportunity.LeadSource`, `CampaignId`, `Amount`, `IsWon` | Reaproveita | recon | Opportunity não tem campo custom de origem/UTM (FieldDefinition) |
| `Campaign.ActualCost`, `BudgetedCost`, `ExpectedRevenue`; colunas `ROI`, `AMOUNT_WON` do tipo `CampaignList` | Reaproveita | recon + describe do tipo | Sem campo custom em Campaign |
| Pasta `Marketing_Origem_Retorno` e `Marketing_Origem_Retorno_Dash` | Reaproveita | SOQL Folder | Compartilhamento com o grupo vem do XML versionado; não conferido na org (incerteza) |
| Grupo `Marketing_Origem_Retorno` (Regular) | Reaproveita | SOQL Group | 0 membros: passo manual pós-deploy |
| `MKT_Leads_por_Origem` | **Altera** (D3) | SOQL Report | Bucket → agrupamento pela fórmula |
| `MKT_Conversao_Leads_por_Origem` | **Altera** (D3) | idem | idem |
| `MKT_Desempenho_Campanhas` | **Altera** (D2) | idem | Tabular → Summary |
| `MKT_Oportunidades_por_Origem` | Reaproveita, sem alteração | idem | — |
| `MKT_Resposta_Membros_Campanha` | Reaproveita, sem alteração | idem | — |
| Painel `MKT_Origem_e_Retorno_Campanhas` | **Altera** (D3, D4, D2) | SOQL Dashboard + Analytics API | `groupingColumn` dos componentes 1–2, agregação do componente 4, filtro de data se aceito |
| `PS_Marketing_AnaliseCampanhas` | **Altera** (D6) | SOQL PermissionSet / FieldPermissions | +1 FLS, +`RunReports` |
| 380 relatórios / 20 painéis fora da pasta, pasta `MARKETINGCLOUD` | Não toca (CA-10) | `COUNT()` | — |
| `SFAgent2` | Não se aplica | recon (1 `BotDefinition`) | Demanda não pede assistente, resumo nem recomendação; tópicos e ações não reexaminados |
| Objetos e Flows `et4ae5`/`MCC_*` | Não toca | seção 6 | — |
| Flow, trigger, Apex, e-mail | **Nada criado** | — | CA-12 |

---

## 4. Automação concorrente e ordem de execução

- **Nenhum componente desta demanda escreve em registro.** Fórmula e relatório não disparam trigger nem Flow. O desenho não depende da ordem de execução; por isso não a mapeio entre `OpportunityBefore`/`OpportunityAfter`/`OpportunityTrigger`, triggers SBQQ e Flows (`Oportunidade_Industria`, `OpportunityFlow`, `AccountTriggered`, `Order`…). Fica declarado como não analisado e não necessário.
- **Onde a automação existente aparece: na massa sintética.** Inserir Account e Opportunity, ou converter Lead, dispara `AccountBefore`/`AccountTrigger`, os triggers de Opportunity e os Flows desses objetos, e passa pelas validation rules ativas (Account: `Celular`, `Contato_Fiscal`, `Telefone`, `WhatsApp`, `CheckUserCanSet…`; Opportunity: `CheckHasAccount`, `CheckOppHasBranch`, `CheckAccountHas…`; Lead: `Celular`, `Telefone`). Regra para builder e QA (doutrina): a fixture preenche **todo** campo exigido por validation rule ativa, com dado fictício; se a conversão de Lead for barrada pela automação de Account/Opportunity, use oportunidades criadas diretamente com `LeadSource` e `CampaignId` e leads com `IsConverted` vindo da conversão mínima possível. Falha da fixture por automação existente é registrada, não contornada desligando automação.
- **Volume e CPU:** não há código nem automação; limites de governador não se aplicam ao desenho. Relatório Summary sem detalhe agrega no servidor. A org tem 0 registros; a QA tinha 712 leads na rodada 1 — muito abaixo de qualquer limite de relatório. O cenário "um pai com muitos filhos" não existe aqui (nada recalcula pai).

---

## 5. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R-B1 | Alias de dev pode ser a QA (assessment achado 6) | **Alta** | Bloqueio B1. Build não começa sem confirmação. |
| R-E1 | Campo novo em Lead (modelo de dados) | Média | Escalado (E1). Fórmula, sem armazenamento; rollback = remover dos relatórios e apagar o campo. |
| R-D4 | Sintaxe de filtro de data no painel desconhecida | Média | Copiar de exemplo da org; 2 tentativas; fallback por relatório (PA-05). |
| R-D5 | `NO_DATA` nos 4 componentes ter outra causa além de atualização | Média | Verificação obrigatória no build pela Analytics API (D5). Persistindo com dado sintético presente, o build sai `**Verificação:** reprovada` e não chama humano. |
| R-MNT | Valor novo em `LeadSource` sem atualizar a fórmula cai em "Fora da lista" | Baixa | `Description` do campo diz isso; comportamento seguro (não some do total, CA-01 continua fechando). |
| R-FX | Fixture barrada por validation rule ou trigger de Account/Opportunity | Média | Seção 4. |
| R-SH | Compartilhamento das pastas com o grupo não conferido na org | Baixa | Builder confere após deploy; QA prova em CA-11 com usuário de teste. |

**Riscos do assessment que tocam a demanda:**
- Achado 1 (automação concorrente em Account/Opportunity/Order): não se aplica ao desenho (nada escreve); aplica-se à massa de teste (seção 4).
- Achado 2 (cobertura Apex ~10%): não se aplica, sem Apex.
- Achado 3 (validation rules de Order): não se aplica, não há Order na massa.
- Achado 4 (campos sem descrição): aplica-se ao campo novo; sai com `Description` (D1). Relatórios e painel já têm `description`.
- Achado 6 (dev × QA): **aplica-se** → B1.
- Achado 10 (nome de trigger duplicado com SBQQ): não se aplica, sem trigger.
- Org vazia (análise R7): aplica-se → massa sintética (seção 7).

---

## 6. Preparação do Sales Cloud para o Marketing Cloud

Nada é feito no Marketing Cloud. O conector está instalado (pacote `MCCA5PROD`, 523 classes `et4ae5`, Flows `MCC_*`, 40+ objetos `et4ae5__*`), mas com 0 registros em `et4ae5__SendDefinition__c`, `et4ae5__IndividualEmailResult__c`, `et4ae5__Business_Unit__c` e `et4ae5__Campaign_Member_Configuration__c` nesta org (`COUNT()`): o conector está instalado e não há envio registrado aqui.

| Tema | No CRM (objeto.campo) | Status |
|---|---|---|
| Dados que o MC lê | `Lead.LeadSource`, `Lead.MKT_Origem_Agrupada__c` (novo), `Lead.IsConverted`, `Campaign` (`Type`, `Status`, custos), `CampaignMember.Status`/`HasResponded` | Existentes, exceto o campo novo |
| Como o público fica identificável | Por `MKT_Origem_Agrupada__c` (ex.: segmento "Sem origem" para campanha de qualificação) e por Campanha + Membro de campanha com `Status`. Não se cria lista, relatório de público nem campo de segmento novo nesta demanda. | Desenho |
| O que o MC devolve e onde grava | Pelo conector, em `et4ae5__IndividualEmailResult__c` (campos confirmados: `et4ae5__Lead__c`, `et4ae5__CampaignMemberId__c`, `et4ae5__Opened__c`, `et4ae5__Clicked__c`, `et4ae5__DateOpened__c`, `et4ae5__DateUnsubscribed__c`, `et4ae5__NumberOfTotalClicks__c`) e na resposta do membro de campanha. Esta demanda **não** reporta métricas de envio (P10 da análise). | Existente, vazio |
| Consentimento e opt-out | `Lead.HasOptedOutOfEmail` (padrão, confirmado), `Lead.et4ae5__HasOptedOutOfMobile__c` (conector, confirmado), `Lead.DoNotCall`. Não se cria campo de consentimento. | Existentes |
| O que fica para quem opera o MC | Incluir `MKT_Origem_Agrupada__c` no objeto Lead sincronizado (se usar Synchronized Data Sources) para segmentar por origem; respeitar `HasOptedOutOfEmail` e opt-out de mobile; usar Campanha/Membro de campanha como público; garantir que o tracking volte para `et4ae5__IndividualEmailResult__c` e para o status do membro de campanha, para o relatório `MKT_Resposta_Membros_Campanha` refletir respostas. | Passo de quem opera o MC |

---

## 7. Massa de teste (org vazia)

Sintética, fictícia, criada pelo builder na dev (após B1) e pela esteira/QA na QA; nunca de produção; nenhum dado pessoal real. Mínimo para cobrir CA-01 a CA-09: leads com cada um dos 13 valores, com `LeadSource` vazio e com 1 valor fora da lista (a picklist não restrita aceita via API); parte convertida; 2 campanhas (uma com `ActualCost > 0`, uma com 0/vazio) com membros e com oportunidades ganhas vinculadas por `CampaignId`. Registros marcados por prefixo no nome (ex.: `EPLAST39-TESTE`) e **apagados por quem criou** ao fim da etapa, registrando a contagem antes/depois no artefato.

---

## 8. Impacto em permissões

- `PS_Marketing_AnaliseCampanhas`: +FLS leitura `Lead.MKT_Origem_Agrupada__c`, +`RunReports` (D6). Continua sem edição.
- Perfis: não alterados. FLS do campo novo: o deploy do campo não concede visibilidade a perfis além do administrador; quem precisar vê pelo PS. OWD de Lead/Campaign/Opportunity não conferido e não alterado: o relatório respeita o compartilhamento do usuário (incerteza declarada; o usuário de Marketing vê só o que o OWD/papéis permitem).
- Pós-deploy manual: atribuir o PS e incluir membros no grupo `Marketing_Origem_Retorno` (sem Id fixo em metadata).

---

## 9. O que NÃO será feito

- Nada no Marketing Cloud; nenhum envio, template, alerta de e-mail ou Flow de disparo (regra 2, CA-12).
- Nenhum Flow, trigger ou Apex; nenhuma escrita em Account, Opportunity ou Order.
- Nenhuma correção de `LeadSource` nos dados (P3).
- Nenhuma alteração fora da pasta da demanda, do campo novo e do PS (CA-10).
- Sem `CampaignInfluence` (não suportado nesta org, recon) nem atribuição multitoque (P6).
- Sem UTM (nenhum campo UTM/origem custom em Lead ou Opportunity, confirmado pela lista de campos).
- Sem extensão do `SFAgent2`.
- Sem agrupamento "Sem origem/Fora da lista" no relatório de oportunidades (PA-04).

---

## 10. Premissas assumidas (validar na homologação)

Herdadas da análise e mantidas: P1 (rótulo "Sem origem"), P2 ("Fora da lista" numa linha), P3 (não corrigir dado), P4 (`LeadSource` como fonte), P5 (período selecionável — ver PA-05), P6 (primeiro toque), P7 (receita ganha ÷ custo real), P8 (Marketing, visão agregada), P9 (complementar, não alterar existentes), P10 (sem métricas do MC), P11 (massa sintética), P12 (ambiente → B1). O card registra que as premissas da análise foram aprovadas em lote; vale a conferência do arquiteto humano neste gate.

Acrescentadas no design:

- [x] **PA-01 — Como produzir "Sem origem" e "Fora da lista".** Pergunta: bucket ajustado à mão ou campo? Decisão: campo fórmula `Lead.MKT_Origem_Agrupada__c` (D1), sujeito a E1. Evidência: bucket de picklist não aceita vazio nem consolida valores soltos (doutrina, erro real da rodada 1); picklist não restrita (describe). Como mudar: voltar ao bucket (alternativa B) ou editar a fórmula.
- [x] **PA-02 — Qual "retorno" mostrar.** Decisão: a coluna principal é a fórmula P7 (receita ganha ÷ custo real), e a coluna nativa `ROI` ((ganho − custo) ÷ custo) aparece ao lado com rótulo próprio. Evidência: P7 da análise; `ROI` existe no tipo `CampaignList` (describe). Como mudar: tirar uma das colunas no relatório.
- [x] **PA-03 — Campanha sem custo.** Decisão: célula em branco, não o texto "n/a" — fórmula de resumo é numérica e não devolve texto. Evidência: padrão de fórmula de resumo do Salesforce. Como mudar: se o texto for indispensável, exige campo fórmula em Campaign (outra mudança de modelo de dados).
- [x] **PA-04 — Relatório de oportunidades por origem.** Decisão: continua agrupando por `Opportunity.LeadSource` cru (vazio aparece "-"). Evidência: CA-01 a CA-04 tratam do relatório de leads; Opportunity não tem campo de agrupamento; criar outro campo só por consistência aumenta E1. Como mudar: campo fórmula gêmeo em Opportunity, mesma lógica.
- [x] **PA-05 — Período.** Decisão: filtro de data no painel se a plataforma aceitar pela sintaxe copiada da org; senão, filtro de data em cada relatório. Evidência: D4; não há exemplo versionado. Como mudar: adicionar o filtro de painel na tela depois.
- [x] **PA-06 — Executar relatórios.** Decisão: incluir `RunReports` no PS. Evidência: o PS hoje não tem a permissão (SOQL) e CA-11 exige que o usuário só com o PS veja os relatórios. Como mudar: remover do PS se os perfis de Marketing já concederem.
- [x] **PA-07 — Quem entra no grupo e no PS.** Decisão: atribuição manual pela Eplast após o deploy. Evidência: grupo com 0 membros e PS com 0 atribuições (SOQL); padrão do squad de não fixar Id de usuário em metadata. Como mudar: lista de usuários informada pela Eplast.

---

## 11. Rollback

Redeploy dos XML da rodada 1 a partir do git (relatórios e painel), remover FLS e `RunReports` do PS, depois apagar o campo `MKT_Origem_Agrupada__c` (só depois de nenhum relatório referenciá-lo). Sem dado a restaurar.

## 12. Ordem do build (para o builder declarativo)

0. Confirmar B1. Sem confirmação: `**Resultado do build:** bloqueado`.
1. Deploy do campo fórmula (com `--dry-run` antes).
2. Describe do tipo `LeadList` para o nome da coluna; ajustar `MKT_Leads_por_Origem` e `MKT_Conversao_Leads_por_Origem`.
3. `MKT_Desempenho_Campanhas` em Summary (D2).
4. Painel: `groupingColumn` 1–2, agregação do componente 4, filtro de data (D4, até 2 tentativas).
5. PS (D6).
6. Massa sintética, `PUT` de atualização do painel, verificação de cada componente pela Analytics API (D5), apagar a massa.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
