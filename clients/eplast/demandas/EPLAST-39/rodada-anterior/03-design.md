# EPLAST-39 — Design: Origem dos leads e retorno das campanhas

**Etapa:** design (gate bloqueante do arquiteto humano)
**Entradas:** `demanda.md`, `01-analise.md` (aprovada em `gates.md`, bloco `aguardando_gate_analise`), `comentarios-do-card.md`, `assessment.md` (2026-09-30), `02-recon.md` (coleta de 2026-11-10 em `sbx-eplast-dev`), RAG do cliente.
**Org consultada:** `sbx-eplast-dev` (sandbox, API 68.0). `sbx-eplast-qa` não estava autenticada nesta sessão.

---

## 0. Pendências que o gate precisa enxergar antes de liberar o build

1. **Escopo contratual não foi respondido.** A análise abriu um bloqueador (Onda 4 não contratada; opções: aditivo, aguardar a Onda 4 ou só levantamento). O gate da análise foi aprovado, mas `comentarios-do-card.md` registra só a aprovação, sem dizer qual opção foi escolhida. **Este design não decide isso.** Ele está dimensionado para o caso "aditivo ou recorte contratado". Se a resposta for "só levantamento", o build não acontece e o que fica desta etapa é o diagnóstico de `02-recon.md` e a seção 7. A aprovação da estimativa pelo cliente no Squad OS continua sendo pré-requisito para o build.
2. **Achado 6 do assessment (dev x QA), reconfirmado hoje.** A instance do alias `sbx-eplast-dev` tem "qa" no nome. Antes do build, alguém da Konecta ou da Eplast confirma se `sbx-eplast-dev` e `sbx-eplast-qa` são sandboxes distintas. Se forem a mesma, o build e o roteiro de QA disputam o mesmo ambiente.
3. **Definições de negócio em aberto** (dúvidas 2, 4, 5 e 6 da análise): período padrão, lista oficial de origens, modelo de atribuição e fórmula de ROI. O desenho abaixo funciona sem elas, porque período e fórmula são parâmetros de relatório e não exigem metadata nova. Os critérios de aceite de conversão e ROI, porém, só fecham com essas respostas.

O RAG do cliente não trouxe design anterior sobre Lead, Campaign ou Marketing. Os únicos trechos relevantes são a própria análise desta demanda e o contrato. Não há decisão anterior pesando nesta.

---

## 1. Decisão

**Nível 1: configuração nativa.** São relatórios e um dashboard sobre os objetos padrão (Lead, Campaign, CampaignMember, Opportunity), além da influência de campanha nativa, que já está ligada na org, e de um permission set de leitura. **Sem Flow, sem Apex, sem campo novo.**

### Justificativa

- O pedido é **medição**. Não há regra de processo a automatizar. A plataforma já calcula, nos campos padrão de Campaign, tudo que o painel de campanha pede: `ActualCost`, `BudgetedCost`, `NumberOfLeads`, `NumberOfConvertedLeads`, `NumberOfOpportunities`, `NumberOfWonOpportunities`, `AmountWonOpportunities` e `NumberOfResponses` (todos confirmados no describe).
- A origem do lead já tem fonte: `LeadSource`, com 13 valores, em Lead, CampaignMember e Opportunity, e a conversão leva o valor para a oportunidade.
- A atribuição de receita a campanha **já está ligada**: `CampaignSettings.enableCampaignInfluence2 = true`, associação automática ativa e modelo `primaryModel` ativo e padrão. Isso responde "qual campanha influenciou a oportunidade" sem construir nada.
- O ROI é uma **fórmula de relatório** (row-level ou summary). Por isso não precisa de campo de fórmula em Campaign, e a fórmula pode mudar quando a Eplast decidir (H3) sem novo deploy de modelo de dados.
- "Sem origem" e "fora da lista" saem de **bucket field** no relatório. Não é preciso campo nem automação para normalizar.

### Por que não descer para Flow ou Apex

Nenhum dos critérios da `salesforce-doutrina` para descer de nível aparece aqui. Não há escrita, rollback, callout, volume transacional, recursão nem regra que precise de teste unitário. Descer de nível só faria sentido se o escopo incluísse **captura** (UTM, formulário) ou **atribuição própria** (primeiro/último toque gravado em registro). As duas ficam fora (seção 5) e as duas exigem mudança de modelo de dados, que é escalada (seção 6).

---

## 2. Componentes

Convenção: skill `padrao-entrega`. O `CLAUDE.md` da Eplast não define convenção própria (prefixo de campo em branco). Todo componente sai com `description` preenchida (achado 4 do assessment).

### 2.1 Criar

| # | Tipo | API name (proposto) | O que faz |
|---|---|---|---|
| C1 | ReportFolder | `Marketing_Origem_Retorno` | Pasta dos relatórios desta demanda. Compartilhada em leitura com o grupo C3. Separada das pastas de amostra da Salesforce e da pasta `MARKETINGCLOUD`. |
| C2 | DashboardFolder | `Marketing_Origem_Retorno_Dash` | Pasta do dashboard, compartilhada com C3. |
| C3 | Group (público) | `Marketing_Origem_Retorno` | Destino do compartilhamento de pasta. Os membros são adicionados manualmente pela Eplast após o deploy (passo manual, sem ID fixo no código). |
| C4 | PermissionSet | `PS_Marketing_AnaliseCampanhas` | Leitura em Campaign, Lead e Opportunity, mais FLS de leitura em `Campaign.ActualCost`, `Campaign.BudgetedCost`, `Campaign.ExpectedRevenue`, `Lead.LeadSource`, `Opportunity.LeadSource`, `Opportunity.CampaignId`. Sem create/edit e sem "Marketing User". Ver seção 3. |
| R1 | Report (LeadList) | `MKT_Leads_por_Origem` | Leads criados no período, agrupados por bucket de origem × mês de criação. Bucket sobre `LeadSource`: os 13 valores, mais "Sem origem" (vazio) e "Fora da lista" (qualquer valor solto, já que a picklist não é restrita). Sem linhas de detalhe. |
| R2 | Report (LeadList) | `MKT_Conversao_Leads_por_Origem` | Mesmo bucket de origem, com fórmula de resumo `CONVERTED:SUM / RowCount`, o mesmo padrão já usado em `Marketing_Exec_Conversion_Rate`. |
| R3 | Report (Opportunity) | `MKT_Oportunidades_por_Origem` | Oportunidades por `LeadSource`: quantidade, ganhas (`IsWon`), valor ganho (`Amount`) e taxa de ganho (fórmula de resumo). |
| R4 | Report (CampaignList) | `MKT_Desempenho_Campanhas` | Uma linha por campanha: custo real e orçado, leads, leads convertidos, respostas, oportunidades, ganhas e valor ganho. Inclui **ROI em fórmula row-level** com proteção `ActualCost > 0`. Sem custo, o resultado é vazio, exibido como "não se aplica", e nunca zero ou infinito. A expressão final depende de H3 (rascunho: `(AmountWonOpportunities − ActualCost) / ActualCost`). |
| R5 | Report (influência de campanha, tipo padrão) | `MKT_Influencia_Campanha_Oportunidade` | Receita influenciada por campanha no modelo `primaryModel`. **Condicional:** o build confirma primeiro que o report type padrão de influência está disponível (lacuna 3 do recon). Se não estiver, R5 sai do escopo e isso é registrado no PR, sem buscar contorno em código. |
| R6 | Report (CampaignLead / campanhas com membros) | `MKT_Resposta_Membros_Campanha` | Membros e respondentes (`HasResponded`) por campanha e por status de membro. **Sem coluna de nome, e-mail ou telefone.** Sem linhas de detalhe. |
| D1 | Dashboard | `MKT_Origem_e_Retorno_Campanhas` | Painel com R1 a R6 (até 6 componentes, mais KPIs). Tipo **`LoggedInUser`** (ver nota). |

**Nota sobre o tipo de D1.** Um dashboard `SpecifiedUser` grava o username do running user no XML de metadata. Username tem formato de e-mail e bloqueia o push no scan de PII (guardrail #2, achado SOMOSAGILITY-18). Por isso D1 é dinâmico (`LoggedInUser`), o que também respeita o acesso de quem está vendo. Há 3 dashboards dinâmicos na org. **No build, conferir na documentação oficial o teto de dashboards dinâmicos da Enterprise Edition antes de criar o quarto.** Se não houver slot, D1 vira `SpecifiedUser` criado **manualmente** na sandbox, como passo pós-deploy documentado, fora de `force-app/`.

**Filtro de período.** R1 a R4 saem com filtro de data relativo e editável na tela, com padrão "este trimestre" até a Eplast responder a dúvida 2. Não é metadata nova.

### 2.2 Alterar

**Nada.** Nenhum relatório, dashboard, campo, perfil, Flow ou classe existente é modificado.

### 2.3 Depreciar

**Nada nesta demanda.** O recon encontrou relatórios de amostra da Salesforce que sobrepõem parte do pedido: `LeadsbySource`, `CampaignsbyROI`, `CampaignROIbyCampaignType`, `Marketing_Exec_Leads_by_Campaigns` e o dashboard `Best_Practice_Leads_Dashboard`. O `LastRunDate` desses relatórios na sandbox varia entre 2015 e 2025. Eles ficam **listados como candidatos** para a Eplast decidir (dúvida 8 da análise). Os relatórios `Marketing_Exec_Conversion_Rate` e `Marketing_Exec_Converted_and_Won_Amount` alimentam o dashboard "Leads & Oportunidades" da pasta `Eplast` e **não são tocados**.

---

## 3. Impacto em permissões

- **Achado do recon:** os perfis comerciais (`Comercial - Analista`, `Comercial`, `Comercial - Analistas`, `Comercial Padrão`), o perfil `Marketing` e `Financeiro` **não têm leitura em Campaign**. Sem ajuste, quem abrir D1 com esses perfis vê os componentes de campanha vazios ou com erro.
- **Decisão:** conceder por **permission set** (`PS_Marketing_AnaliseCampanhas`), **sem alterar perfil**. Isso segue a recomendação dos achados 7 e 8 do assessment (permissão por perfil é difícil de auditar, e há 4 variações de perfil comercial).
- O PS é **somente leitura**. Criar ou editar campanha exige o flag de usuário "Marketing User" (1 usuário ativo na sandbox), e isso não entra aqui.
- **Quem recebe o PS e quem entra no grupo C3** é decisão da Eplast (dúvida 7 da análise: público). A atribuição é passo manual pós-deploy, documentado em `06-entrega.md`. Nenhum ID de usuário vai para o código.
- **Visibilidade de registros:** os OWD internos são `Lead = ReadWriteTransfer`, `Opportunity = Read` e `Campaign = FullAccess`. Com o D1 dinâmico, cada pessoa vê os agregados do que já enxerga, e o painel não amplia acesso a dado.
- **LGPD / guardrail #2:** nenhum relatório traz coluna de nome, e-mail, telefone ou documento de Lead ou Contact. R1, R2 e R6 saem sem linhas de detalhe. O QA confere isso no critério "nenhum dado pessoal aparece no painel".

---

## 4. Conflito de automação e limites

### Objetos tocados x automação existente (confirmado no recon)

| Objeto | Trigger | Flow record-triggered | Esta demanda escreve? |
|---|---|---|---|
| Lead | nenhum | nenhum | não |
| Campaign | nenhum | nenhum | não |
| CampaignMember | nenhum | nenhum (os 13 `MCC_*` são de objetos do pacote `et4ae5`) | não |
| Opportunity | **`OpportunityTrigger` (custom) + `SBQQ.OpportunityAfter` + `SBQQ.OpportunityBefore`** | **`Oportunidade_Industria`, `OpportunityFlow` (after-save)** | **não** |

**Na solução em si, não há conflito de ordem de execução:** relatórios e dashboards só leem e não disparam trigger, Flow ou validation rule.

**Há risco de ordem de execução no teste.** A sandbox tem 0 Lead, 0 Campaign e 0 Opportunity, então o QA precisa criar dados sintéticos. **Converter um Lead ou criar uma Opportunity dispara a cadeia concorrente do achado 1 (trigger custom + dois triggers do CPQ + dois Flows after-save) e, via `OpportunityTriggerHelper` (Queueable com callout), uma chamada `ProtheusAPI.getClientByCNPJ` por conta envolvida.** A demanda não muda nada disso, mas o roteiro de QA precisa:
- usar o **mínimo** de oportunidades sintéticas (ordem de dezenas, não centenas) e nunca carga em massa numa transação. O helper faz um callout por conta dentro de loop, e o teto de callouts por transação é da plataforma (valor exato a confirmar na documentação oficial pelo QA);
- confirmar **antes** com o humano para qual endpoint do Protheus a sandbox de QA aponta (lacuna 7 do recon). Se for produtivo, os dados sintéticos não passam por conversão ou criação de Opportunity com conta e CNPJ, e a parte de Opportunity é validada só por metadata e revisão de fórmula;
- **não** ligar `TriggerUtility__mdt.TriggerExecution.BypassTrigger__c`. O bypass vale para a org inteira e desligaria a automação para todo mundo na sandbox. Se alguém quiser usá-lo, a decisão é humana.

A influência de campanha automática já está ligada e cria registros de influência quando há oportunidade e papel de contato. Isso não é DML em Opportunity e não redispara a cadeia acima. A demanda não altera essa configuração.

### Governador e escala

- **Transacional:** nada. Não há SOQL, DML nem CPU de código desta demanda. O cenário "um pai com muitos filhos" (achado SOMOSAGILITY-10) não se aplica: uma campanha com milhares de membros não executa automação nossa. As contagens de Campaign são calculadas pela plataforma.
- **Relatórios:** o volume de produção é desconhecido (sandbox vazia). R1 a R6 são de resumo, sem detalhe, o que evita o teto de linhas exibidas na tela. Dashboards dinâmicos têm limite de atualização (a org expõe `HourlyDashboardRefreshes = 200`). Para o público esperado (até dezenas de pessoas), isso não preocupa.
- **Qualidade do dado (H1/H2):** é o maior risco de resultado errado e não se resolve com código. O bucket "Sem origem / Fora da lista" deixa o problema **visível** no painel, em vez de escondê-lo.

---

## 5. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| 1 | Escopo contratual (Onda 4) sem resposta registrada | **Alta** (bloqueia build) | Seção 0. O build só começa com a opção escolhida e a estimativa aprovada pelo cliente. |
| 2 | Achado 6: `sbx-eplast-dev` pode ser a mesma sandbox que `sbx-eplast-qa` | **Alta** (bloqueia build/QA) | Confirmação humana antes do build. Sem isso, não se sabe onde o QA roda. |
| 3 | Dados sintéticos de Opportunity disparam cadeia CPQ + trigger custom + 2 Flows + callout Protheus (achado 1) | **Média** | Seção 4: volume mínimo, endpoint confirmado antes, sem bypass global. |
| 4 | `LeadSource` não restrita e com valores sobrepostos ("Campanha" x "E-mail MKT" x "Google Ads"); qualidade em produção desconhecida | **Média** | Bucket "Sem origem / Fora da lista". Tornar a picklist restrita ou revisar a taxonomia é **mudança de modelo de dados, escalada** (seção 6). |
| 5 | `Campaign.Type` com valores padrão em inglês, desalinhados da taxonomia de origem | **Média** | R4 agrupa por campanha, não por tipo, até a Eplast decidir. Revisar valores é **escalado** (seção 6). |
| 6 | Perfis comerciais e de Marketing sem leitura em Campaign | **Média** | C4 (permission set) + atribuição pela Eplast. |
| 7 | Report type padrão de influência de campanha não confirmado via API | **Baixa** | R5 condicional (seção 2.1). |
| 8 | Teto de dashboards dinâmicos da edição | **Baixa** | Conferir na documentação no build. Fallback: dashboard manual, fora de `force-app/`. |
| 9 | Fórmula de ROI, período e modelo de atribuição indefinidos (H3, dúvidas 2, 5, 6) | **Baixa** técnica / **Média** para aceite | São parâmetros de relatório e mudam sem novo modelo. O critério de aceite de ROI só fecha com a fórmula. |
| 10 | Expectativa de "retorno das ações de marketing" incluir envio e clique do Marketing Cloud | **Média** (expectativa) | Fora do escopo (seção 6). Precisa ficar explícito para a Eplast no gate. |
| 11 | Relatórios de amostra antigos convivendo com os novos e gerando números divergentes | **Baixa** | Candidatos a depreciação listados (2.3). A decisão é da Eplast. |

### Riscos do assessment: aplicabilidade

| Achado | Aplica? | Por quê / como |
|---|---|---|
| 1. Automação concorrente em Account/Opportunity/Order | **Não na solução, sim no teste** | A solução só lê. Os dados sintéticos de teste em Opportunity passam pela cadeia (risco 3). |
| 2. Cobertura Apex de 10% | **Não** | Não há Apex nesta demanda. O pacote é só de relatórios, dashboard, pasta, grupo e PS. A regra de cobertura sobre esse tipo de pacote numa eventual promoção a produção (feita por humanos, fora da esteira) fica para o `release` confirmar na documentação. |
| 3. Validation rules de Order | **Não** | Order não é tocado. |
| 4. Campos sem descrição | **Não diretamente** | Nenhum campo novo. Todo componente criado sai com `description`. |
| 5. Convenção `<Classe>Test` | **Não** | Sem Apex. |
| 6. Dev x QA | **Sim, bloqueante** | Risco 2. |
| 7 e 8. Perfis | **Sim, tangencial** | O acesso vai por permission set, sem perfil novo nem alteração de perfil. |
| 9 e 10. API version de classes / nome de trigger duplicado | **Não** | Nenhuma classe ou trigger é tocado. |

---

## 6. O que NÃO será feito nesta demanda

- **Captura de UTM** (campos em Lead/Opportunity, formulário, integração web). É mudança de modelo de dados e exige decisão de arquitetura sênior. **Escalada ao humano**, não decidida aqui.
- **Tornar `LeadSource` restrita, revisar ou fundir valores, ou alinhar `Campaign.Type` à taxonomia de origem.** Alterar a semântica de picklist usada por relatórios e integrações existentes é mudança de modelo de dados. **Escalada ao humano.** Se for aprovada, vira demanda própria, com levantamento das integrações que gravam `LeadSource`. O recon não achou código custom que grave o campo, mas o Marketing Cloud Connect e as integrações de produção não foram verificados.
- **Atribuição própria** (primeiro/último toque gravado em campo, multi-toque custom). Usa-se a influência nativa já ligada. Trocar ou ajustar o modelo de influência (`primaryModel` está bloqueado, `IsModelLocked = true`) não entra.
- **Dados de Marketing Cloud** (envios, aberturas, cliques, `et4ae5__*`) no painel.
- **Saneamento de `LeadSource` na base de produção** e qualquer carga de dados.
- **Qualquer escrita** em Lead, Campaign, CampaignMember, Opportunity, Account ou Order: nenhum Flow, trigger, campo ou validation rule.
- **Alterar ou remover** relatórios e dashboards existentes, inclusive o dashboard "Leads & Oportunidades" da pasta `Eplast`.
- **Alterar perfis** ou conceder "Marketing User".
- **Corrigir a dívida do `OpportunityTriggerHelper`** (callout em loop), achado lateral deste recon. Registrado para backlog, fora do escopo.
- **Deploy em produção** (guardrail #1).

---

## 7. Mapa critério de aceite → componente

| Critério (01-analise) | Componente | Observação |
|---|---|---|
| Todo lead do período tem origem contável, com "Sem origem" | R1 (bucket) | Período é parâmetro |
| Origem usa a lista controlada | R1 (bucket "Fora da lista") | Depende da lista acordada (dúvida 4) |
| Conversão lead → oportunidade por origem | R2, R3 | Amostra a definir (dúvida 11) |
| Painel por campanha com custo, leads, convertidos, opps, ganhas, valor | R4, D1 | — |
| ROI pela fórmula acordada; "não se aplica" sem custo | R4 (fórmula row-level) | Fórmula depende de H3 |
| Nenhum dado pessoal no painel | R1 a R6 sem colunas pessoais; D1 | QA inspeciona colunas e filtros |
| Nenhuma escrita em Account/Opportunity/Order sem tratar o achado 1 | Seção 4 | A solução não escreve |
| Implantação só em `sbx-eplast-dev`/`sbx-eplast-qa`, após confirmar qual é cada uma | Seção 0, item 2 | Bloqueante |

---

## 8. Estimativa

**Estimativa de esforço:** 18–32 h

Composição (esforço humano de consultor, com o agente construindo):
- Pastas, grupo e permission set (C1 a C4): 2–3 h
- Seis relatórios com buckets e fórmulas (R1 a R6): 6–10 h
- Dashboard (D1), incluindo a checagem do teto de dinâmicos e um eventual fallback manual: 2–4 h
- Massa sintética em QA com a cautela da seção 4 (endpoint Protheus, volume mínimo) e roteiro: 4–8 h
- Validação com a Eplast (lista de origens, fórmula de ROI, período) e homologação: 3–5 h
- Documentação de entrega e passos manuais (atribuição de PS, membros do grupo): 1–2 h

**O que mudou em relação à análise (24–60 h) e por quê:**
- **O teto caiu de 60 para 32 h.** O teto da análise previa captura de UTM, atribuição multi-toque ou escrita em Opportunity, com Flow ou Apex e análise de ordem de execução com o CPQ. O recon mostrou que a **influência de campanha nativa já está ligada** (modelo ativo e associação automática), o que elimina a atribuição construída. UTM e mudança de picklist foram **escaladas como mudança de modelo de dados** e saem desta demanda. Não há Apex nem Flow, então não há teste unitário nem exposição à cobertura de 10%.
- **O piso caiu de 24 para 18 h.** Não há report type custom a criar (os tipos padrão bastam) e nenhum componente existente é alterado.
- **Entrou um custo que a análise não previa:** a massa de teste em Opportunity passa pela cadeia CPQ e pelo callout ao Protheus (seção 4), o que pede cautela e coordenação no QA.
- **Continuam fora da faixa,** como na análise: saneamento de `LeadSource` em produção, dados de Marketing Cloud e qualquer item escalado na seção 6. Se algum entrar, a estimativa volta para revisão.

---

Design pronto. **Gate bloqueante**: preciso do aceite do arquiteto humano para liberar o build.
