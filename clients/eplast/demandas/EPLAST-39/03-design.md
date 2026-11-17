# EPLAST-39 — Design: Origem dos leads e retorno das campanhas (rodada 3, ajuste às respostas do cliente de 17/11)

**Org consultada:** alias `sbx-eplast-dev` (`sf org list`: Sandbox, Connected). É a dev da esteira; a Eplast a chama de "QA" (regra 5 da conta, não é bloqueio). Só leitura nesta etapa: metadata e `COUNT()`. Nenhum DML, nenhum deploy, nada no Marketing Cloud.
**Insumos:** `02-recon.md` (refeito em 17/11), `01-analise.md` (aprovada em 15/11), respostas do cliente de 17/11 (registradas no fim do design anterior e reproduzidas na seção 12), `comentarios-do-card.md`, build e QA da rodada anterior em `rodada-anterior/premissas-assumidas/` (QA aprovado), metadata em `force-app/`, skill `salesforce-doutrina` (seção "Relatórios e painéis por metadata").

**Estimativa de esforço:** 10–14 h
Mudou em relação à análise (12–18 h) e ao design anterior (8–12 h): tudo o que existe já está implantado, versionado e passou no QA, então o build é de ajuste, não de construção — por isso fica abaixo da análise. Fica acima do design anterior porque as respostas do cliente acrescentam 2 campos fórmula novos (Opportunity e Campaign), 1 relatório novo de rastreabilidade, a reescrita do de-para da fórmula de Lead, filtro de "mês atual" em 6 relatórios (dois deles de tipos que já recusaram `timeFrameFilter`, o que exige outra sintaxe e pode custar tentativas) e massa sintética nova cobrindo sinônimos e a lista de 10 origens.

---

## 0. O que precisa do arquiteto humano neste gate

| # | Tipo | O quê | Efeito |
|---|---|---|---|
| **E2** | **Mudança de modelo de dados — escalada ao arquiteto humano** | Criar 2 campos fórmula (sem armazenamento): `Opportunity.MKT_Origem_Agrupada__c` (texto, mesmo de-para do Lead) e `Campaign.MKT_ROI_Situacao__c` (texto, "Calculável"/"Não calculável"). Hoje Opportunity e Campaign têm **0 campos custom** (recon, seção 2). O cliente autorizou o campo em Campaign como configuração (resposta de 17/11, item 4); o de Opportunity segue a mesma lógica. | Se aceito, segue o desenho. Se recusado: oportunidades continuam por `LeadSource` cru (volta a PA-04 antiga, contraria a resposta 2 do cliente) e o "não calculável" vira célula em branco (contraria a resposta 4). |
| — | Alteração de campo existente | `Lead.MKT_Origem_Agrupada__c` muda de valores: dos 13 valores crus + "Fora da lista" para as 10 origens do cliente + "Sem origem". O campo foi criado por esta demanda (E1, aceito em 16/11). | Quem filtra pelos valores antigos quebra (ver risco R3). |

Perguntas de negócio em aberto que bloqueiam (caso 3 da regra 4): **nenhuma**.

---

## 1. Decisão e justificativa

**Abordagem: configuração nativa (nível 1).** Campos fórmula, relatórios, painel e permission set. **Sem Flow, sem Apex, sem trigger, sem DML.** Tudo é leitura agregada; nada grava registro. Descer para Flow ou Apex não traz nada que a fórmula não dê e criaria automação em Lead e Opportunity (fora do escopo, CA-12) e regravação de lead existente (vedada pela resposta 5 do cliente).

### D1 — Consolidação das origens: reescrever o de-para da fórmula `Lead.MKT_Origem_Agrupada__c`

Alternativas consideradas:

| | Alternativa | Atende? | Por que sim / por que não |
|---|---|---|---|
| **A (escolhida)** | Reescrever a fórmula existente: normaliza (`UPPER(TRIM(TEXT(LeadSource)))`) e mapeia os 13 valores ativos e os sinônimos conhecidos para as 10 origens do cliente; vazio → "Sem origem"; não reconhecido → "Outros". `LeadSource` não é tocado. | Sim | Reaproveita o campo que já passou no QA. Vale para lead antigo e novo sem carga (fórmula). O de-para é editável em Configuração pelo administrador **sem deploy e sem código** (é o ponto configurável pedido pelo cliente). |
| B | Custom Metadata Type com a tabela de-para | Não por fórmula | Fórmula não busca registro de Custom Metadata por valor dinâmico; seria preciso Flow ou Apex gravando um campo e uma carga dos leads existentes — automação nova em Lead e regravação vedada (resposta 5). |
| C | Padronizar a própria picklist `LeadSource` (criar os 10 valores, desativar os antigos, migrar os dados) | Sim, mas | Regrava lead existente (vedado), muda a tela de cadastro do Comercial e mexe no valor padrão compartilhado por Lead, Opportunity e Contact. Caro de desfazer. |
| D | Bucket de relatório | Não | Doutrina: bucket sobre picklist não aceita vazio nem consolida valor solto (erro real da rodada 1). |

Visibilidade do valor original (resposta 2: "manter a visibilidade ... preservando o dado original"): relatório novo `MKT_Origem_Original_por_Grupo` (D3) mostra, dentro de cada origem padronizada (inclusive "Outros"), cada valor original de `LeadSource` com a contagem.

**Fórmula proposta** (mesmo texto em Lead e Opportunity; o builder confere o limite de caracteres compilados — estimativa ~1.800 caracteres de texto, abaixo de 3.900):

```
IF(ISBLANK(TEXT(LeadSource)), "Sem origem",
CASE(UPPER(TRIM(TEXT(LeadSource))),
"PROSPECÇÃO ATIVA","Prospecção ativa/SDR", "PROSPECCAO ATIVA","Prospecção ativa/SDR",
"PROSPECÇÃO ATIVA/SDR","Prospecção ativa/SDR", "SDR","Prospecção ativa/SDR",
"ECONODATA","Prospecção ativa/SDR", "OUTBOUND","Prospecção ativa/SDR",
"INDICAÇÃO","Indicação", "INDICACAO","Indicação",
"SITE/FORMULÁRIO","Site/formulário", "SITE","Site/formulário", "WEBSITE","Site/formulário",
"FORMULÁRIO","Site/formulário", "FORMULARIO","Site/formulário", "WEB","Site/formulário",
"BUSCA ORGÂNICA","Busca orgânica", "BUSCA ORGANICA","Busca orgânica",
"GOOGLE ORGÂNICO","Busca orgânica", "GOOGLE ORGANICO","Busca orgânica", "SEO","Busca orgânica",
"GOOGLE ADS","Google Ads", "ADWORDS","Google Ads",
"META ADS","Meta Ads", "FACEBOOK ADS","Meta Ads", "INSTAGRAM ADS","Meta Ads",
"REDES SOCIAIS ORGÂNICAS","Redes sociais orgânicas", "REDES SOCIAIS","Redes sociais orgânicas",
"INSTAGRAM","Redes sociais orgânicas", "FACEBOOK","Redes sociais orgânicas", "LINKEDIN","Redes sociais orgânicas",
"EVENTOS/FEIRAS","Eventos/feiras", "EVENTO","Eventos/feiras", "EVENTOS","Eventos/feiras",
"FEIRA","Eventos/feiras", "FEIRAS","Eventos/feiras",
"PARCEIROS","Parceiros", "PARCEIRO","Parceiros",
"CAMPANHA","Outros", "WHATSAPP","Outros", "E-MAIL MKT","Outros", "PROSPECÇÃO PASSIVA","Outros",
"Outros"))
```

De-para dos 13 valores ativos hoje (describe de `Lead.LeadSource`, recon seção 2), para o Marketing aprovar no roteiro:

| Valor atual em `LeadSource` | Origem padronizada | Por quê |
|---|---|---|
| Prospecção ativa, SDR, Econodata | Prospecção ativa/SDR | Item da lista do cliente; Econodata é base de prospecção ativa |
| Indicação | Indicação | Igual |
| Google Orgânico | Busca orgânica | Equivalente |
| Google Ads | Google Ads | Igual |
| Instagram, Facebook | Redes sociais orgânicas | Não há valor "pago" para Meta na picklist; anúncio Meta entra como "Meta Ads" quando o valor existir (PA-11) |
| Evento | Eventos/feiras | Equivalente |
| WhatsApp, E-mail MKT | Outros | Cliente: WhatsApp, telefone e e-mail são canal de contato, não origem |
| Campanha, Prospecção passiva | Outros | Não dizem a origem real; a campanha já é medida pelo objeto Campanha |

"Site/formulário", "Meta Ads" e "Parceiros" não têm valor na picklist hoje (recon). Os sinônimos já estão no de-para, então quando a Eplast criar esses valores (ou uma integração gravar o texto), eles caem no grupo certo **sem mexer na fórmula** (PA-10).

`Description` do campo (assessment, achado 4): "EPLAST-39. Origem padronizada (10 origens + Sem origem) a partir de LeadSource, sem alterar o valor original. Mesmo de-para de Opportunity.MKT_Origem_Agrupada__c: alterar os dois juntos. Valor não reconhecido = Outros."

### D2 — Oportunidades por origem com o mesmo agrupamento (resposta 2; revê PA-04)

| | Alternativa | Escolha |
|---|---|---|
| **A (escolhida)** | Campo fórmula gêmeo `Opportunity.MKT_Origem_Agrupada__c` sobre `Opportunity.LeadSource`, mesmo texto de D1 | Cobre **toda** oportunidade, inclusive as criadas sem lead. Na conversão, o Salesforce copia `LeadSource` do lead para a oportunidade, então o grupo coincide. |
| B | Relatório de leads convertidos (tipo com dados da oportunidade convertida) agrupando pelo campo do Lead | Só alcança oportunidade nascida de conversão; a que é criada direto some do relatório. Recon não confirmou o alcance do tipo (incerteza 4). |

Custo da escolha: o de-para fica em duas fórmulas. Mitigação: `Description` cruzada nos dois campos, item de QA que compara os dois textos (seção 9) e risco R2.

`MKT_Oportunidades_por_Origem`: grupo `LEAD_SOURCE` → coluna do campo novo (o builder confere o nome da coluna no describe `/analytics/report-types/Opportunity` depois do deploy do campo); segundo grupo `WON` mantido; `scope` mantido (`team`, doutrina: `Opportunity` recusou `org`).

### D3 — Relatório novo de rastreabilidade (resposta 2)

`MKT_Origem_Original_por_Grupo`, pasta `Marketing_Origem_Retorno`: Summary, tipo `LeadList` (o mesmo de `MKT_Leads_por_Origem`, copiar `scope` dele), grupos `Lead.MKT_Origem_Agrupada__c` × `LEAD_SOURCE`, contagem, `showDetails false`, sem colunas de nome, e-mail ou telefone (CA-13), período padrão mês atual (D4). Fora do painel (não é indicador, é conferência). Não há relatório na pasta que já faça isso (recon, item 22).

### D4 — Período padrão "mês atual", com mensal, trimestral e anual (resposta 3; revê PA-05)

- Relatórios de Lead e Opportunity (`MKT_Leads_por_Origem`, `MKT_Conversao_Leads_por_Origem`, `MKT_Oportunidades_por_Origem`, `MKT_Origem_Original_por_Grupo`): `timeFrameFilter` sobre `CREATED_DATE` (coluna atual mantida), trocando `INTERVAL_CUSTOM` 2000–2099 pelo intervalo relativo "mês atual". **O valor do enum não está confirmado** (hipótese: `INTERVAL_THISMONTH`); a doutrina proíbe adivinhar: o builder faz retrieve de um relatório da org que já use filtro relativo de mês e copia. Duas recusas → para, registra no plano e mantém o filtro atual nesse relatório (PA-05b).
- Relatórios de Campanha (`MKT_Desempenho_Campanhas` tipo `CampaignList`, `MKT_Resposta_Membros_Campanha` tipo `CampaignLead`): esses tipos **recusaram `timeFrameFilter`** na rodada anterior (plano de build, desvio 3). Usar filtro comum (`<filter><criteriaItems>`) sobre a data de início da campanha (`START_DATE`, campo `Campaign.StartDate` confirmado) com valor relativo de mês atual, copiando a sintaxe de relatório da org. Mesma regra de duas tentativas; fallback: sem período padrão nesses dois (como hoje), premissa PA-05b.
- Mensal, trimestral e anual: o usuário troca o intervalo relativo no filtro do relatório (Este mês / Este trimestre / Este ano), recurso padrão, sem deploy. Para trimestre e ano o segundo grupo `CREATED_MONTH` de `MKT_Leads_por_Origem` continua útil.
- Painel: os componentes mostram o período padrão dos relatórios (mês atual). Filtro de período no painel continua fora (sem exemplo na org, decisão da rodada anterior); trocar o período é abrir o relatório.

### D5 — Retorno de campanha: cálculo nativo e "não calculável" (resposta 4; revê PA-02 e PA-03)

- **ROI:** a coluna nativa `ROI` do tipo `CampaignList` passa a ser o ROI oficial (o cliente pediu "cálculo nativo"; ela é (receita ganha − custo real) ÷ custo real e não divide por zero — doutrina). A fórmula própria "Receita ganha / custo real" (`IF(ACTUAL_COST:SUM > 0, AMOUNT_WON:SUM / ACTUAL_COST:SUM, null)`) **sai** do relatório, para não haver dois "retornos" com números diferentes (PA-12). Recolocá-la é ajuste na tela, sem deploy.
- **Colunas pedidas** (já existem no relatório, recon item 17): investimento = `ACTUAL_COST` (com `BUDGETED_COST` ao lado), leads = `NUM_LEADS`, convertidos = `NUM_CONVERTED_LEADS`, oportunidades ganhas = `NUM_WON_OPPORTUNITIES`, receita atribuída = `AMOUNT_WON`. Mantidas `NUM_OPPORTUNITIES` e `NUM_RESPONSES`.
- **"Não calculável":** campo fórmula texto `Campaign.MKT_ROI_Situacao__c` = `IF(OR(ISBLANK(ActualCost), ActualCost <= 0), "Não calculável", "Calculável")` (só `ActualCost`, campo padrão confirmado; não depende de campo estatístico da campanha em fórmula, cujo suporte não confirmei). Entra como segundo grupo do relatório (`CAMPAIGN_NAME` × situação), então cada campanha sem custo mostra "Não calculável" ao lado do ROI em branco. `Description`: "EPLAST-39. Situação do ROI da campanha: Não calculável quando o custo real está vazio ou zero. Usado no relatório MKT_Desempenho_Campanhas."
- **Receita ≠ faturamento:** `AMOUNT_WON` é valor de oportunidades ganhas, não faturamento (faturamento efetivo fica no ERP, fora do CRM e desta demanda). O rótulo de coluna não é editável no XML (plano de build anterior, desvio 4); a distinção vai no `description` do relatório e no rodapé (`footer`) do componente do painel: "Receita atribuída = valor das oportunidades ganhas vinculadas à campanha. Não é faturamento."
- **Atribuição:** a do padrão da plataforma, campanha principal da oportunidade (`Opportunity.CampaignId`), que é o que `AMOUNT_WON` e `NUM_WON_OPPORTUNITIES` somam. `CampaignInfluence` não é suportado nesta org (recon). O cliente condicionou o cálculo à validação dos custos, dos vínculos e da regra de atribuição: isso é conferência dele na homologação (PA-13).

### D6 — Painel `MKT_Origem_e_Retorno_Campanhas` (ajuste)

- Componente de oportunidades: `groupingColumn` passa para a coluna do campo novo de Opportunity.
- Componente de desempenho de campanhas: `chartSummary` continua sobre uma coluna agregada que permaneça no relatório (não pode apontar para a fórmula que sai); `footer` com o texto de D5.
- Componentes de leads e de conversão: sem mudança de metadata (o campo é o mesmo; os valores mudam).
- Continua `LoggedInUser`. Depois da massa sintética: `PUT /analytics/dashboards/<id>`, `GET .../status`, `GET /analytics/dashboards/<id>`; `errorCode` ou `NO_DATA` em componente é defeito de build (doutrina).

### D7 — Permission set `PS_Marketing_AnaliseCampanhas` (reaproveita)

Hoje: Read em Campaign, Lead e Opportunity, sem edição; FLS de leitura em `Lead.LeadSource` e `Lead.MKT_Origem_Agrupada__c`; `PermissionsRunReports = true` (confirmado nesta sessão). Acrescentar só FLS de leitura em `Opportunity.MKT_Origem_Agrupada__c` e `Campaign.MKT_ROI_Situacao__c`. Nada de edição, `ViewAllData` ou `ModifyAllData`.

### Versões e ativação

Nenhum Flow, agente Agentforce ou classe Apex é criado ou alterado: a regra "versão nova, depois ativação" não se aplica. Campo fórmula, relatório e painel não têm versão na plataforma: a alteração vale no deploy. A versão anterior de cada XML fica no git (commit de partida da rodada 3) e é o rollback (seção 11).

---

## 2. Reaproveita / cria / altera — item a item (regra 3)

| Item | Ação | Prova de que existe (ou não) | Observação |
|---|---|---|---|
| `Lead.LeadSource` (13 valores, não restrita) | Reaproveita, **sem alteração** de valor nem de dado | describe (recon) | Dado original preservado (resposta 2 e 5) |
| `Opportunity.LeadSource`, `CampaignId`, `Amount`, `IsWon` | Reaproveita | `FieldDefinition` nesta sessão | — |
| `Campaign.ActualCost`, `BudgetedCost`, `StartDate`, `NumberOfLeads`, `NumberOfConvertedLeads`, `NumberOfWonOpportunities`, `AmountWonOpportunities` | Reaproveita | `FieldDefinition` nesta sessão | Base das colunas do tipo `CampaignList` |
| `Lead.MKT_Origem_Agrupada__c` | **Altera** (D1) | `CustomField` Id `00NHa00000B8xvpMAB` | Fórmula reescrita; `Description` nova |
| `Opportunity.MKT_Origem_Agrupada__c` | **Cria** (D2, E2) | Não existe: 0 campos custom em Opportunity (recon) | Fórmula gêmea |
| `Campaign.MKT_ROI_Situacao__c` | **Cria** (D5, E2) | Não existe: 0 campos custom em Campaign (recon) | Fórmula texto |
| `MKT_Leads_por_Origem` | **Altera** (D4) | `Report` (recon) | Só período |
| `MKT_Conversao_Leads_por_Origem` | **Altera** (D4) | idem | Só período |
| `MKT_Oportunidades_por_Origem` | **Altera** (D2, D4) | idem | Grupo e período |
| `MKT_Desempenho_Campanhas` | **Altera** (D4, D5) | idem | Sai a fórmula própria; entra o grupo de situação; período por `START_DATE` |
| `MKT_Resposta_Membros_Campanha` | **Altera** (D4) | idem | Só período (ou nada, no fallback) |
| `MKT_Origem_Original_por_Grupo` | **Cria** (D3) | Nenhum relatório da pasta mostra o valor original por grupo (recon, item 22) | — |
| Painel `MKT_Origem_e_Retorno_Campanhas` | **Altera** (D6) | `Dashboard` (recon) | 2 componentes |
| Pastas `Marketing_Origem_Retorno` e `Marketing_Origem_Retorno_Dash` | Reaproveita | `Folder` (recon) | — |
| Grupo `Marketing_Origem_Retorno` | Reaproveita | repo (recon) | Membros: passo pós-deploy (PA-07) |
| `PS_Marketing_AnaliseCampanhas` | **Altera** (D7) | `PermissionSet` nesta sessão | +2 FLS de leitura |
| Campos da EPLAST-45 em Lead (`MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c`, `MKT_Nutricao_*`) | Não toca | `FieldDefinition` (recon) | Mesmo prefixo `MKT_`, outra demanda |
| Agente `SFAgent2` | Não se aplica | 1 `BotDefinition` (recon) | A demanda não pede assistente, resumo nem recomendação |
| Objetos e Flows `et4ae5`/`MCC_*` | Não toca | recon seção 4 | — |
| Outros 400+ relatórios e 20 painéis da org | Não toca (CA-10) | `COUNT()` (recon: 419 e 21) | Linha de base nova: medir no início do build |
| Flow, trigger, Apex, e-mail | **Nada criado** | — | CA-12 |

---

## 3. Objetos e campos envolvidos (confirmados)

| Objeto | Campos lidos | Campos criados/alterados | Escrita em registro |
|---|---|---|---|
| Lead | `LeadSource`, `IsConverted`, `CreatedDate`, `HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` | `MKT_Origem_Agrupada__c` (altera fórmula) | Nenhuma |
| Opportunity | `LeadSource`, `CampaignId`, `Amount`, `IsWon`, `CreatedDate` | `MKT_Origem_Agrupada__c` (cria fórmula) | Nenhuma |
| Campaign | `ActualCost`, `BudgetedCost`, `StartDate`, campos estatísticos padrão | `MKT_ROI_Situacao__c` (cria fórmula) | Nenhuma |
| CampaignMember | `Status` (pelo tipo `CampaignLead`) | — | Nenhuma |

---

## 4. Automação concorrente e ordem de execução

- **Nada desta demanda grava registro.** Campo fórmula não dispara trigger, Flow nem validation rule; relatório e painel só leem. Lead, Campaign e CampaignMember têm 0 triggers (recon); Flows nesses objetos não confirmados (recon, incerteza 1), mas irrelevantes porque não há gravação.
- **Opportunity ganha um campo fórmula.** Opportunity tem triggers custom (`OpportunityBefore`, `OpportunityAfter`, `OpportunityTrigger`), triggers CPQ e Flows (assessment, achado 1). Fórmula não entra na ordem de execução; a ordem entre eles **não foi mapeada e não é necessária** para este desenho. Único cuidado: código que monte SOQL dinâmico com todos os campos do objeto passaria a ler um campo a mais — sem efeito de gravação.
- **Account e Order:** não tocados. O defeito conhecido de `UpdateAccountCompanyInfo` e o limite de 50 jobs da `AccountTrigger` (EPLAST-47) não se aplicam ao desenho, só à massa de teste (seção 7).
- **Volume e CPU:** sem código e sem automação, limites de governador não se aplicam. Relatório Summary agrega no servidor; a QA tinha 712 leads na rodada 1. O cenário "um pai com muitos filhos" não existe (nada recalcula pai). Campo fórmula em Campaign só usa campo do próprio registro.

---

## 5. Riscos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Ajuste do de-para feito em Configuração (sem deploy, como o cliente pediu) diverge do git; o próximo deploy da esteira sobrescreve o ajuste | Média | Roteiro e `Description` dizem: ajuste em Configuração é comunicado à Konecta, que o traz para o repositório na demanda seguinte. Antes de cada deploy desses componentes, o builder compara a fórmula da org com a do repo |
| R2 | As duas fórmulas (Lead e Opportunity) divergem com o tempo | Média | `Description` cruzada; QA compara os dois textos (seção 9) |
| R3 | Os valores de `Lead.MKT_Origem_Agrupada__c` mudam; quem filtra pelos valores antigos (relatório fora da pasta, list view, segmento no Marketing Cloud) quebra | Média | No repo, só os relatórios e o painel desta demanda usam o campo; a EPLAST-43 agrupa por `LEAD_SOURCE`, não por ele (RAG, design EPLAST-43). `MetadataComponentDependency` devolveu 0 dependências, mas também não lista os 2 relatórios do repo que sabidamente o usam — **não prova ausência** de outro uso na org. Item para quem opera o Marketing Cloud (seção 6) |
| R4 | Enum do intervalo "mês atual" e sintaxe de filtro relativo em `CampaignList`/`CampaignLead` não confirmados | Média | Copiar de relatório da org; 2 tentativas por relatório; fallback PA-05b |
| R5 | Coluna de campo novo invisível para o usuário que implanta (achado EPLAST-43, D6: administrador sem FLS não enxerga a coluna e o relatório falha no deploy) | Média | Implantar campo e PS antes dos relatórios; atribuir o PS ao usuário da esteira **só na dev**, desfazer ao final (mesmo procedimento já usado pelo QA desde 16/11) |
| R6 | Usuário sem o PS vê erro nos componentes que usam campo novo (painel `LoggedInUser`) — antes só nos de Lead, agora também nos de oportunidade e campanha | Baixa | Decisão do card de 16/11 (opção 1): acesso pelo PS; atribuição pós-deploy (PA-07) |
| R7 | "Mês atual" deixa o painel vazio nos primeiros dias do mês | Baixa | Comportamento do pedido; usuário troca para trimestre/ano no relatório |
| R8 | Massa sintética barrada por validation rule ou trigger de Account/Opportunity | Média | Seção 7 |
| R9 | Limite de caracteres da fórmula | Baixa | ~1.800 de 3.900; builder confere no deploy |

**Riscos do assessment que tocam a demanda:**
- Achado 1 (automação concorrente em Account/Opportunity/Order): o desenho só acrescenta fórmula em Opportunity (não dispara nada); aplica-se à massa de teste (seção 7).
- Achado 2 (cobertura Apex ~10%) e 5 (nome de classe de teste): não se aplicam, sem Apex.
- Achado 3 (validation rules de Order): não se aplica, sem Order.
- Achado 4 (campos sem descrição): aplica-se aos 3 campos; todos saem com `Description` (D1, D5).
- Achado 6 (dev × QA): resolvido pela regra 5 da conta.
- Achados 7, 8 (perfis) e 9 (versão de API de classe): não se aplicam; nenhum perfil alterado.
- Achado 10 (nome de trigger duplicado com SBQQ): não se aplica.

---

## 6. Preparação do Sales Cloud para o Marketing Cloud

Nada é feito no Marketing Cloud (regra 2): sem conexão, configuração, jornada, público ou envio, e sem alterar o conector. O build entrega só o lado do CRM.

| Tema | No CRM (objeto.campo) | Situação |
|---|---|---|
| Dados que o MC vai ler | `Lead.MKT_Origem_Agrupada__c` (10 origens + "Sem origem"), `Lead.LeadSource` (valor original), `Lead.IsConverted`; `Campaign` (custos, datas) e `CampaignMember.Status` | Existentes; o campo agrupado muda de valores nesta rodada |
| Como o público fica identificável | Pela origem padronizada (`Lead.MKT_Origem_Agrupada__c`, ex.: "Sem origem" para campanha de qualificação, "Eventos/feiras" para nutrição pós-evento) e por Campanha + Membro de campanha com `Status`. O relatório `MKT_Origem_Original_por_Grupo` mostra o que compõe cada origem. Nenhuma lista, segmento ou campo de público novo nesta demanda | Desenho |
| O que o MC devolve e onde é gravado | Pelo conector `et4ae5`: objeto `et4ae5__IndividualEmailResult__c` (existe, recon) e status do membro de campanha (lido por `MKT_Resposta_Membros_Campanha`); engajamento consolidado nos campos da EPLAST-45 (`Lead.MKT_MC_Engajamento__c`, `MKT_MC_EngajamentoData__c`). Esta demanda não reporta métricas de envio | Existente |
| Consentimento e opt-out | `Lead.HasOptedOutOfEmail` (padrão) e `Lead.et4ae5__HasOptedOutOfMobile__c` (conector), ambos confirmados no recon. Nenhum campo de consentimento novo | Existentes |
| O que fica para quem opera o MC | (1) Se o Lead é sincronizado (Synchronized Data Sources), incluir `MKT_Origem_Agrupada__c` e **revisar qualquer segmento ou filtro que use os valores antigos do campo** (os 13 valores crus ou "Fora da lista"), que deixam de existir (R3). (2) Respeitar `HasOptedOutOfEmail` e o opt-out de celular. (3) Usar Campanha/Membro de campanha como público e garantir que o retorno volte ao status do membro, para o relatório de respostas refletir. (4) Registrar o custo real da campanha no CRM (`Campaign.ActualCost`), senão o ROI fica "Não calculável" | Passo de quem opera o MC |

---

## 7. Massa de teste (dev vazia: 0 Lead, Campaign, CampaignMember, Opportunity)

Sintética e fictícia, pelos scripts de `fixtures/` do cliente; prefixo `EPLAST39-TESTE` no nome; apagada por quem criou ao fim da etapa, com contagem antes/depois no artefato. Mínimo:
- Leads criados no mês corrente com: cada um dos 13 valores ativos; `LeadSource` vazio; sinônimos soltos gravados pela API (picklist não restrita) — ao menos "Site", "Meta Ads", "Parceiros", "feiras" (minúsculo, prova o `UPPER`) e " SDR " (prova o `TRIM`); um valor não reconhecido ("Origem Inventada XYZ"); parte convertida.
- Oportunidades com `LeadSource` de grupos diferentes (inclusive vazio), parte ganha, vinculadas por `CampaignId`; Conta com o desvio `TriggerUtility.bypassTrigger`, CNPJ fictício com dígito válido, nome com TESTE (card de 15/11). A fixture preenche todo campo exigido por validation rule ativa (Lead: `Celular`, `Telefone`; Opportunity: 8 ativas). Falha por automação existente é registrada, não contornada desligando automação.
- 2 campanhas com início no mês corrente (uma com `ActualCost > 0`, uma com custo vazio ou 0) e 1 com início em mês anterior (prova o filtro de período), com membros.

---

## 8. Impacto em permissões

- `PS_Marketing_AnaliseCampanhas`: +FLS leitura em `Opportunity.MKT_Origem_Agrupada__c` e `Campaign.MKT_ROI_Situacao__c`. `RunReports` já existe. Continua sem edição.
- Perfis: não alterados. OWD de Lead, Campaign e Opportunity não conferido e não alterado (recon, incerteza 10): o relatório respeita o compartilhamento de quem o abre.
- Pós-deploy manual (PA-07): atribuir o PS e incluir membros no grupo `Marketing_Origem_Retorno`.
- Usuário de teste da regra 6: o ativo é `005bJ00000piKAaQAM` (Administrador do sistema, recon). Por ser administrador, **não serve como prova de acesso negado**; o caso sem permissão segue o procedimento do card de 16/11 (antes da atribuição do PS ao usuário de execução).

---

## 9. O que o QA deve testar (critérios revistos) — com foco onde há fragilidade

Os CAs da análise valem, com estas revisões trazidas pelas respostas do cliente:

| # | Critério | Como provar | Fragilidade que cobre |
|---|---|---|---|
| CA-01' | Soma das origens (10 + "Sem origem") = total de leads do período | Analytics API, contagens | — |
| CA-02 | "Sem origem" para vazio; nenhuma linha "-" | idem | rodada 1 |
| CA-03' | Sinônimo cai no grupo certo (inclusive minúsculo e com espaço); não reconhecido cai em "Outros" | Massa com sinônimos | picklist não restrita (doutrina SOMOSAGILITY-21) |
| CA-04' | Cada um dos 13 valores ativos tem destino no de-para (tabela de D1) | describe × texto da fórmula | manutenção da fórmula |
| CA-05' | Período padrão = mês atual nos relatórios (exceto os que caírem no fallback PA-05b, declarados no plano); lead/campanha de mês anterior não aparece; trocar para trimestre/ano recalcula | Analytics API com filtro alterado na requisição | enum não confirmado (R4) |
| CA-08' | ROI exibido = coluna nativa `ROI`; não há segunda coluna de "retorno" | Relatório | — |
| CA-09' | Campanha sem custo mostra "Não calculável" e ROI em branco, sem erro | Relatório | — |
| CA-15 (novo) | Oportunidades por origem usam os mesmos 10 grupos + "Sem origem"; texto das fórmulas de Lead e Opportunity idêntico | Relatório + Tooling `CustomField` dos dois campos | R2 |
| CA-16 (novo) | `LeadSource` original intacto: o relatório de rastreabilidade mostra cada valor original dentro do grupo, inclusive em "Outros" | `MKT_Origem_Original_por_Grupo` | resposta 2 |
| CA-17 (novo) | Texto "Não é faturamento" visível no componente de desempenho e no `description` do relatório | Analytics API do painel | resposta 4 |
| CA-07 | Todos os componentes do painel com dado, sem `errorCode` (atualizar por `PUT`) | Analytics API | rodada 1 (209 e `NO_DATA`); R5, R6 |
| CA-10 | Nada fora da pasta, dos 3 campos e do PS foi alterado | diff de metadata; linha de base nova de relatórios/painéis medida no início | contagem mudou de 380/20 para 419/21 (recon) |
| CA-11 | Usuário só com o PS lê relatórios e não edita Lead, Opportunity nem Campaign | procedimento do card de 16/11 | usuário de teste é admin |
| CA-12, CA-13 | Sem Flow/trigger/Apex/e-mail; relatórios sem dado pessoal | inspeção do pacote | — |

CA-14 (ambiente) está resolvido pela regra 5 da conta.

---

## 10. O que NÃO será feito

- Nada no Marketing Cloud; nenhum envio, template, alerta de e-mail ou Flow de disparo (regra 2, CA-12).
- Nenhuma alteração na picklist `LeadSource` (valores ou ativação) e nenhuma regravação ou correção de lead existente (resposta 5).
- Nenhum Flow, trigger ou Apex; nenhuma escrita em Account, Opportunity, Order, Lead ou Campaign.
- Sem filtro de período no painel; sem faturamento efetivo (fica no ERP); sem `CampaignInfluence` nem atribuição multitoque; sem UTM.
- Sem extensão do `SFAgent2`.
- Sem alteração nos relatórios e painéis fora da pasta da demanda.

---

## 11. Premissas assumidas (validar na homologação)

Herdadas da análise e ainda válidas: P3 (não corrigir dado), P4 (`LeadSource` como fonte), P6 (primeiro toque, agora como PA-13), P8 (Marketing, visão agregada), P9 (complementar, não alterar existentes), P10 (sem métricas do MC), P11 (massa sintética). **Substituídas pelas respostas do cliente de 17/11:** P1 → "Sem origem" (confirmada); P2/PA-01 → D1 (10 origens + "Outros" + rastreabilidade); P5/PA-05 → D4 (mês atual); P7/PA-02 → D5 (ROI nativo); PA-03 → "Não calculável"; PA-04 → D2. P12 (ambiente) resolvida pela regra 5. Mantidas do design anterior: PA-06 (`RunReports` no PS, já implantado) e PA-07.

- [x] **PA-07 — Quem entra no grupo e no PS.** Decisão: atribuição manual pela Eplast após o deploy. Evidência: 0 atribuições e 0 membros (recon); padrão do squad de não fixar Id de usuário em metadata. Como mudar: lista de usuários informada pela Eplast.
- [x] **PA-08 — Onde fica o de-para.** Pergunta: como deixar a consolidação "configurável sem deploy"? Decisão: no texto das fórmulas, editável em Configuração pelo administrador. Evidência: fórmula não lê Custom Metadata por valor dinâmico; a alternativa exigiria automação e regravação de lead (vedado). Como mudar: editar as duas fórmulas juntas e avisar a Konecta (R1).
- [x] **PA-09 — De-para dos 13 valores atuais.** Decisão: tabela de D1. Evidência: lista do cliente (17/11) e a frase "WhatsApp, telefone e e-mail são canais de contato". Como mudar: trocar o destino do valor nas duas fórmulas.
- [x] **PA-10 — Valores sem correspondente na picklist** (Site/formulário, Meta Ads, Parceiros). Decisão: não criar valores na picklist nesta demanda; os sinônimos já estão no de-para. Evidência: criar valor muda a tela do Comercial e o conjunto padrão compartilhado por Lead, Opportunity e Contact; regra de não sobrepor. Como mudar: o administrador acrescenta o valor em `LeadSource`; ele cai no grupo sem alterar a fórmula.
- [x] **PA-11 — Instagram e Facebook.** Decisão: "Redes sociais orgânicas". Evidência: a picklist separa pago e orgânico só para Google ("Google Ads" × "Google Orgânico"); não há valor de anúncio Meta. Como mudar: mudar o destino para "Meta Ads" nas duas fórmulas.
- [x] **PA-05b — Período nos relatórios de campanha e fallback.** Decisão: "mês atual" pela data de início da campanha (`StartDate`); se a plataforma recusar a sintaxe em 2 tentativas, o relatório fica sem período padrão (como hoje) e o plano de build declara qual. Evidência: `timeFrameFilter` recusado em `CampaignList` e `CampaignLead` (plano de build anterior); os números da campanha são acumulados desde o início, então o período escolhe quais campanhas aparecem, não quais conversões. Como mudar: trocar a coluna de data do filtro na tela do relatório.
- [x] **PA-12 — Uma só medida de retorno.** Decisão: só a coluna nativa `ROI`; a fórmula própria (receita ÷ custo) sai. Evidência: o cliente pediu "cálculo nativo"; duas colunas de retorno com números diferentes confundem. Como mudar: recriar a fórmula de resumo na tela do relatório.
- [x] **PA-13 — Regra de atribuição.** Decisão: campanha principal da oportunidade (`Opportunity.CampaignId`), primeiro toque, padrão da plataforma. Evidência: `CampaignInfluence` não suportado na org (recon). Como mudar: ativar Influência de Campanha na org e refazer o relatório sobre ela (outra demanda).
- [x] **PA-14 — Período de oportunidades por data de criação.** Decisão: mantém `CREATED_DATE` (coluna atual do relatório). Evidência: metadata em `force-app/`. Como mudar: trocar para data de fechamento no filtro do relatório.

Pendências de caso 3 (bloqueiam): **nenhuma**. O cliente marcou o cálculo do ROI como "condicionado à validação de custos, vínculos com oportunidades e regra de atribuição": isso é validação de homologação (PA-13), não bloqueio.

---

## 12. Rollback

Redeploy, a partir do git (commit de partida da rodada 3), dos 5 relatórios, do painel, da fórmula de Lead e do PS; apagar `MKT_Origem_Original_por_Grupo`; depois apagar `Opportunity.MKT_Origem_Agrupada__c` e `Campaign.MKT_ROI_Situacao__c` (só quando nenhum relatório os referenciar). Sem dado a restaurar.

## 13. Ordem do build (para o builder declarativo)

0. Medir a linha de base de relatórios e painéis da org (`COUNT()`) e comparar a fórmula de Lead da org com a do repo.
1. Campos: fórmula de Lead (reescrita), Opportunity e Campaign (novos), com `--dry-run` antes. PS com as 2 FLS. Atribuir o PS ao usuário da esteira só na dev (R5).
2. Describe dos tipos `LeadList`, `Opportunity` e `CampaignList` para os nomes das colunas novas.
3. Retrieve de relatório da org com filtro relativo de mês (enum de `timeFrameFilter` e sintaxe de `criteriaItems` com data relativa).
4. Relatórios: período (D4), grupo de oportunidades (D2), desempenho de campanhas (D5), relatório novo (D3). Duas tentativas por item.
5. Painel (D6).
6. Massa sintética (seção 7), `PUT` de atualização do painel, verificação de cada componente e de cada CA da seção 9 pela Analytics API, apagar a massa, desfazer a atribuição do PS.

---

## Respostas do cliente (2026-11-17) — origem das mudanças desta rodada

Registradas por Leonardo Barbosa ("Respostas Konecta/Eplast", recebido em 17/11), que mandou redesenhar com elas. Onde divergem de premissa anterior, valem as respostas.

- Sem origem: mostrar "Sem origem" em vez de "-". → mantido (já entregue).
- Origens fora da lista: manter a visibilidade, padronizar os valores e consolidar sinônimos, preservando o dado original. → D1, D3.
- Lista inicial: prospecção ativa/SDR, indicação, site/formulário, busca orgânica, Google Ads, Meta Ads, redes sociais orgânicas, eventos/feiras, parceiros e outros; WhatsApp, telefone e e-mail são canais de contato. → D1, PA-09 a PA-11.
- Período padrão: mês atual, com filtros mensal, trimestral e anual. → D4, PA-05b.
- Retorno de campanha: cálculo nativo; investimento, leads, convertidos, oportunidades ganhas e receita atribuída, distinguindo de faturamento; sem custo = ROI não calculável. → D5, PA-12, PA-13.
- Não corrigir nem regravar dado de lead existente. → seção 10.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
