# EPLAST-26 — Design: score e faixa de prioridade em Lead e Opportunity (rodada 3, respostas do cliente de 17/11)

**Bloqueio (caso 3 da regra 4): nenhum.** Há três decisões para o arquiteto humano neste gate (seção 14). Elas não bloqueiam o build do que está desenhado aqui.
**Rodada:** 3. O design da rodada 2 foi construído, aprovado no QA e levado à homologação (`rodada-anterior/premissas-assumidas/`). A Eplast respondeu em 17/11, e este design ajusta o que já existe às respostas. As respostas estão transcritas no fim deste arquivo e valem acima de qualquer premissa.
**Org consultada:** `sbx-eplast-dev`, Sandbox, Connected (`sf org list`, nesta sessão, 2026-11-17). Só leitura: metadata e contagens agregadas. Nenhum registro lido.
**Insumos:** `01-analise.md` (gate aprovado em 15/11), `02-recon.md` (rodada 3, 17/11), `comentarios-do-card.md`, `00-preflight.md`, regras 1 a 6 do `CLAUDE.md` da Eplast, `assessment.md` (achados 1, 2, 4, 6 e 10), skill `salesforce-doutrina`, RAG (designs da EPLAST-27 e da EPLAST-46, padrão `<Tema>Setting__mdt`).

---

## 1. Solução em uma frase

Os quatro campos de fórmula que já existem (`PriorityScore__c` e `PriorityBand__c` em Lead e em Opportunity) recebem os critérios e as faixas da Eplast (AA, A, B, C, D, "Não classificado"). Os pesos, o limite de dias e os cortes das faixas passam a ser lidos de um **tipo de Custom Metadata novo**, que o administrador altera em Setup, sem deploy. Critério sem campo na org vale 0 ponto e entra na lista "depende de campo a criar ou preencher" (seção 5).

**Consequência que o gate precisa ver antes de aprovar.** Com os campos que a org tem hoje, o score máximo possível é **15 no Lead** (faixa D) e **45 na Opportunity** (faixa C). As faixas AA, A e B ficam inalcançáveis até que os campos da seção 5 existam e sejam preenchidos. O desenho segue a instrução do responsável ("critério sem campo não é inventado") e deixa a decisão sobre os campos novos para este gate.

## 2. Decisão: configuração (nível 1), sem descer de nível

| Alternativa | Nível | Decisão |
|---|---|---|
| **(a) Fórmula que lê os parâmetros de Custom Metadata (`$CustomMetadata`)** | Configuração | **Escolhida.** O cliente pediu regra em fórmula, transparente e configurável sem deploy. Registro de Custom Metadata se edita em Setup, inclusive em produção, e viaja por deploy entre sandboxes. É o padrão que a org já usa para parâmetros: `RankingRange__mdt`, `AlertaOportunidadeParadaSetting__mdt`, `CommercialSignalSetting__mdt`, `NextBestActionSetting__mdt` (8 tipos `__mdt` na dev, `EntityDefinition`, nesta sessão). Fórmula continua fora da ordem de execução |
| (b) Pesos como literais na fórmula (decisão PD-02 da rodada 2) | Configuração | Rejeitada. O cliente pediu parâmetros configuráveis, e o responsável confirmou "sem deploy para ajustar". **É o plano B do build** se a plataforma recusar `$CustomMetadata` nesta fórmula (I-1) |
| (c) Custom Setting hierárquico (`$Setup`) | Configuração | Rejeitada. O valor de Custom Setting é dado, não metadata: não vai por deploy de dev para QA e para produção, e teria de ser digitado à mão em cada ambiente |
| (d) Flow ou Apex que grava o score | Declarativo / código | Rejeitada. Nada na regra exige gravação. Em Opportunity já existem 2 triggers custom e CPQ, 1 Flow before-save e 4 Flows after-save no mesmo evento (`02-recon.md`, seção 4; assessment, achado 1). Gravar o score acrescentaria mais um ponto de concorrência |
| (e) Einstein / modelo preditivo | Recurso de plataforma | Rejeitada. O cliente decidiu: "Preditivo fica para depois". A dev tem 0 Lead e 0 Opportunity |

## 3. Item a item: o que reaproveita, o que altera e o que cria (regra 3)

### Reaproveita sem alterar

| Componente | Confirmado | Uso |
|---|---|---|
| `Lead.MKT_MC_Engajamento__c` (picklist: `Sem engajamento`, `Baixo`, `Médio`, `Alto`) | describe, nesta sessão | Único critério de Lead com campo na org (engajamento) |
| `Opportunity.StageName` (11 estágios abertos ativos, `SortOrder` 1 a 11) | `OpportunityStage`, nesta sessão | Critério de estágio |
| `Opportunity.Discovery_Completed__c`, `Budget_Confirmed__c` (checkbox, padrão falso) | describe | Evidências de avanço. O significado está confirmado pelo uso no Flow `Opportunity_BeforeSave_QualificaOportunidade` da EPLAST-40 |
| `Opportunity.LastActivityDate`, `NextStep` (padrão) | describe | Interação recente e próximo passo |
| `Opportunity.IsClosed` | describe | Encerrada vira "Não classificado" (PD-13) |
| `PS_Comercial_ScorePrioridade` | `02-recon.md`, seção 7 | Leitura dos 4 campos. **Não é alterado**, porque os API names não mudam. Assim não há conflito com a EPLAST-45 (preflight) |
| Layouts `Lead-Lead Layout`, `Opportunity-Opportunity Layout`, páginas `Lead_Record_Page`, `Opportunity_Record_Page` | `02-recon.md`, seção 1 | **Não são alterados.** Os campos já estão neles e os rótulos não mudam. Assim não há conflito com as EPLAST-30, 35, 38, 40 e 41 (preflight) |
| List view `Leads_Prontos_Abordagem` (EPLAST-45) | `ListView`, nesta sessão | Não é alterada. Depende de A6 |
| Fixtures `fixtures/lead.apex` e `fixtures/opportunity.apex` | disco | Base dos registros sintéticos de verificação e QA. Já passaram no QA da rodada 2 |

### Não reaproveita, com motivo

| Componente | Por quê |
|---|---|
| `Lead.Rating` ("Classificação", picklist `AA`, `A`, `B`, `C`, `D`) | Tem os mesmos rótulos que o cliente pediu, e por isso é provável que seja a "classificação atual". Mas nenhuma automação de Lead o grava (0 trigger, 1 Flow, de atribuição; `02-recon.md`), e não se sabe quem o preenche. Gravar a faixa nele exigiria Flow, e essa troca é decisão do cliente. A faixa usa **os mesmos rótulos**, então a comparação fica direta (PD-14) |
| `Account.Ranking__c` | Porte da conta por compras, não é prioridade (`02-recon.md`) |
| `Opportunity.Previs_o_Eintein__c` | O cliente pediu: "a validar; não aposentar". Não é lido nem alterado |
| `Opportunity.ROI_Analysis_Completed__c` | Sem descrição e sem uso na org. Não está provado que seja evidência de avanço (PD-11) |
| `Opportunity.CloseDate` | É previsão do vendedor, não "prazo confirmado pelo cliente". Pela regra "informação ausente não gera pontuação positiva", não pontua (PD-12) |
| `Lead.Sector__c`, `LeadSource`, `Status`; `Opportunity.Probability`, `Amount` | Critérios da rodada 2 que o cliente substituiu. Saem da fórmula. Os campos continuam existindo |

### Altera (já existe na dev, da rodada 2)

| # | Componente | O que muda |
|---|---|---|
| A1 | `Lead.PriorityScore__c` (fórmula Number) | Fórmula, descrição e texto de ajuda (seção 4.2) |
| A2 | `Lead.PriorityBand__c` (fórmula Text) | Fórmula, descrição e texto de ajuda (seção 4.2) |
| A3 | `Opportunity.PriorityScore__c` | Fórmula, descrição e texto de ajuda (seção 4.3). O build confere a precisão (org 18, repositório 3, `02-recon.md`) e grava Number(3,0) |
| A4 | `Opportunity.PriorityBand__c` | Fórmula, descrição e texto de ajuda (seção 4.3) |
| A5 | List views `Oportunidades_Prioridade_Alta`, `Oportunidades_Abertas_Prioridade`, `Leads_Abertos_Prioridade` (as três existem na dev, `ListView`, nesta sessão) | Filtro "Alta" passa a "AA, A". Colunas recebem as entradas novas (seção 4.4) |
| A6 | `Lead.MKT_Nutricao_ProntoAbordagem__c` (fórmula da **EPLAST-45**) | `"Alta"` literal passa a AA ou A. **Componente de outra demanda: ver seção 6 e decisão D2** |

Fórmula de campo não tem versão: alterar é substituir a fórmula. Não há Flow, agente nem classe nesta entrega, então a regra "nova versão primeiro" não se aplica. O rollback é redeployar a fórmula anterior, que está no git (seção 7).

### Cria

| # | Tipo | API name | Detalhe |
|---|---|---|---|
| C1 | Tipo de Custom Metadata (Public) | `PriorityScoreSetting__mdt` (rótulo "Score de prioridade - parâmetros") | Segue o padrão `<Tema>Setting__mdt` da org. Nome em inglês PascalCase, como `PriorityScore__c` (PD-01 da rodada 2) |
| C2 | 13 campos Number em C1 | seção 4.1 | Cada um com descrição |
| C3 | Registro de C1 | `PriorityScoreSetting.Default` | Um registro só, como `CommercialSignalSetting__mdt` (RAG: `[demandas/EPLAST-46/03-design.md]`, registro `Default`) |

**C1 é um tipo de metadata de configuração, não um objeto de negócio.** Não guarda registro de cliente e não muda o modelo de dados de Lead ou de Opportunity. Mesmo assim, por cautela, está na seção 14 (D1) para o aceite explícito do arquiteto humano.

## 4. Especificação para o build

### 4.1 Parâmetros (`PriorityScoreSetting__mdt`, registro `Default`)

Todos Number(3,0), obrigatórios, manageability `SubscriberControlled`. Valores iniciais:

| Campo | Rótulo | Valor | Origem |
|---|---|---|---|
| `LeadEngagementHighPoints__c` | Lead - pontos engajamento Alto | 15 | Peso do cliente para engajamento |
| `LeadEngagementMediumPoints__c` | Lead - pontos engajamento Médio | 10 | PD-10 |
| `LeadEngagementLowPoints__c` | Lead - pontos engajamento Baixo | 5 | PD-10 |
| `OppDiscoveryPoints__c` | Oportunidade - pontos descoberta concluída | 10 | PD-11 (parte dos 25 do estágio) |
| `OppBudgetPoints__c` | Oportunidade - pontos orçamento confirmado | 10 | PD-11 |
| `OppAdvancedStagePoints__c` | Oportunidade - pontos estágio avançado | 5 | PD-11 |
| `OppRecentActivityPoints__c` | Oportunidade - pontos interação recente | 10 | PD-12 (parte dos 20) |
| `OppRecentActivityDays__c` | Oportunidade - dias de interação recente | 30 | PD-12 |
| `OppNextStepPoints__c` | Oportunidade - pontos próximo passo | 10 | PD-12 |
| `BandAAMin__c` | Faixa AA - score mínimo | 90 | Cliente |
| `BandAMin__c` | Faixa A - score mínimo | 75 | Cliente |
| `BandBMin__c` | Faixa B - score mínimo | 60 | Cliente |
| `BandCMin__c` | Faixa C - score mínimo | 40 | Cliente. Abaixo de C é D |

Para ajustar, o administrador abre Setup > Tipos de metadados personalizados > Score de prioridade - parâmetros > Gerenciar registros > Default. Precisa de "Personalizar aplicativo". **Critério novo** (quando existir o campo da seção 5) exige campo em C1 e fórmula nova: isso é deploy, com demanda e gate.

### 4.2 Lead

Abaixo, `P.` abrevia `$CustomMetadata.PriorityScoreSetting__mdt.Default.` (no XML vai por extenso).

`Lead.PriorityScore__c`:

```
MIN(100,
  CASE(MKT_MC_Engajamento__c,
    "Alto",  P.LeadEngagementHighPoints__c,
    "Médio", P.LeadEngagementMediumPoints__c,
    "Baixo", P.LeadEngagementLowPoints__c,
    0)
)
```

`Lead.PriorityBand__c`:

```
IF(ISBLANK(TEXT(MKT_MC_Engajamento__c)), "Não classificado",
  IF(PriorityScore__c >= P.BandAAMin__c, "AA",
  IF(PriorityScore__c >= P.BandAMin__c,  "A",
  IF(PriorityScore__c >= P.BandBMin__c,  "B",
  IF(PriorityScore__c >= P.BandCMin__c,  "C", "D")))))
```

"Não classificado" no Lead é o lead em que nenhum critério tem informação. Hoje isso quer dizer `MKT_MC_Engajamento__c` vazio (PD-13). Quando entrar um critério novo, a condição passa a ser "todos os campos de critério vazios".

O valor de API dos itens da picklist (`Médio`, com acento) foi conferido no describe, nesta sessão. O build confirma que o `CASE` sobre a picklist compila. Se não compilar, usa `ISPICKVAL` encadeado.

Texto de ajuda (A1, até 510 caracteres): "Prioridade comercial de 0 a 100, não é probabilidade de fechamento. Soma: potencial de compra mensal (até 30), aderência ao portfólio (25), prazo da primeira compra (20), engajamento (15), cadastro qualificado e decisor (10). Hoje só o engajamento devolvido pelo Marketing Cloud tem campo no CRM. Os demais valem 0 até existir o campo. Pesos configurados pelo administrador." A2: "AA 90-100, A 75-89, B 60-74, C 40-59, D 0-39 (cortes configuráveis). Não classificado: lead sem nenhuma informação de critério."

### 4.3 Opportunity

`Opportunity.PriorityScore__c`:

```
IF(IsClosed, 0,
  MIN(100,
      IF(Discovery_Completed__c, P.OppDiscoveryPoints__c, 0)
    + IF(Budget_Confirmed__c,    P.OppBudgetPoints__c, 0)
    + IF(CASE(StageName,
          "Cotação", 1, "Execução técnica do projeto", 1, "Envio Cotação", 1,
          "Amostra", 1, "Análise Fiscal", 1, "Análise Financeira", 1,
          "Negociação Comercial", 1, 0) = 1, P.OppAdvancedStagePoints__c, 0)
    + IF(AND(NOT(ISBLANK(LastActivityDate)),
             LastActivityDate >= TODAY() - P.OppRecentActivityDays__c),
         P.OppRecentActivityPoints__c, 0)
    + IF(ISBLANK(NextStep), 0, P.OppNextStepPoints__c)
  )
)
```

`Opportunity.PriorityBand__c`:

```
IF(IsClosed, "Não classificado",
  IF(PriorityScore__c >= P.BandAAMin__c, "AA",
  IF(PriorityScore__c >= P.BandAMin__c,  "A",
  IF(PriorityScore__c >= P.BandBMin__c,  "B",
  IF(PriorityScore__c >= P.BandCMin__c,  "C", "D")))))
```

Estágios "avançados" são os de `SortOrder` 5 a 11 (de "Cotação" a "Negociação Comercial"), conferidos em `OpportunityStage` nesta sessão. A lista fica na fórmula, não no Custom Metadata, porque fórmula não percorre lista configurável. Mudar a lista é editar a fórmula em Setup (PD-11).

Conta de verificação (valores iniciais): descoberta, orçamento, "Negociação Comercial", atividade há 5 dias e próximo passo preenchido dão 10+10+5+10+10 = **45, C**. "Qualificação" sem evidência, sem atividade e sem próximo passo dá **0, D**. Encerrada dá **0, "Não classificado"**. Atividade há 31 dias não pontua. Atividade há 30 dias pontua.

Texto de ajuda (A3): "Prioridade comercial de 0 a 100, não é probabilidade de fechamento. Soma: estágio com evidências de avanço (até 25: descoberta, orçamento, estágio a partir de Cotação), interação recente e próximo passo (20), prazo confirmado pelo cliente (20), margem (20), viabilidade de atendimento (15). Prazo, margem e viabilidade valem 0 até existir campo no CRM. Pesos configurados pelo administrador." A4: igual a A2, com "Não classificado: oportunidade encerrada".

### 4.4 List views (A5)

| API name | Mudança |
|---|---|
| `Oportunidades_Prioridade_Alta` | Filtro `PriorityBand__c equals "AA,A"` (no XML de list view, valores separados por vírgula valem como "ou"; o build confirma na dev). Rótulo: "Oportunidades de prioridade AA e A". **Fica vazia** até as faixas AA e A serem alcançáveis (seção 1) |
| `Oportunidades_Abertas_Prioridade` | Acrescentar as colunas `NextStep` e `LastActivityDate`. Mantém as demais colunas |
| `Leads_Abertos_Prioridade` | Acrescentar a coluna `MKT_MC_Engajamento__c` |

Ordenação por score continua sendo ação do usuário na coluna. Já passou no QA da rodada 2.

### 4.5 Permissões

- Nenhum perfil e nenhum permission set alterado. `PS_Comercial_ScorePrioridade` já dá leitura nos 4 campos.
- C1 é Public. Pelo comportamento padrão, a fórmula lê o Custom Metadata sem o usuário precisar de acesso ao tipo. **O verificador confirma** com o usuário de teste da regra 6 (Id resolvido na org do job; cite só o `005…`), que tem o permission set e não tem "Personalizar aplicativo". Se a leitura falhar, o build para e volta ao gate, porque a correção mexeria em `PS_Comercial_ScorePrioridade`, compartilhado com a EPLAST-45 (I-2).
- Editar os parâmetros: só quem tem "Personalizar aplicativo" (administrador da Eplast).

## 5. Critérios do cliente: o que entra e o que depende de campo

| Objeto | Critério (peso do cliente) | Nesta versão | Campo usado | Para pontuar, falta |
|---|---|---|---|---|
| Lead | Potencial de compra mensal (30) | **0** | — | Campo em Lead (ex.: número "Potencial de compra mensal" ou faixa em picklist) e regra de pontos |
| Lead | Aderência ao portfólio (25) | **0** | — | Campo que diga a aderência (ex.: picklist "Aderência ao portfólio"). `Sector__c` é candidato, mas sem descrição e sem prova de que mede aderência |
| Lead | Prazo da primeira compra (20) | **0** | — | Campo de data ou picklist "Prazo previsto da primeira compra" |
| Lead | Engajamento (15) | **até 15** | `MKT_MC_Engajamento__c` | Parcial: mede o retorno do Marketing Cloud. Reunião e pedido de cotação não estão no CRM, e Task e Event têm 0 registros |
| Lead | Cadastro qualificado e contato com o decisor (10) | **0** | — | Regra do que é "cadastro qualificado" e campo que marque o decisor (ex.: checkbox "Contato com o decisor") |
| Opportunity | Estágio com evidências de avanço (25) | **até 25** | `StageName`, `Discovery_Completed__c`, `Budget_Confirmed__c` | — |
| Opportunity | Interação recente e próximo passo confirmado (20) | **até 20** | `LastActivityDate`, `NextStep` | Parcial: "confirmado" não é registrado. `NextStep` preenchido conta como próximo passo |
| Opportunity | Prazo de compra confirmado pelo cliente (20) | **0** | — | Checkbox "Prazo confirmado pelo cliente" (usado com `CloseDate`) |
| Opportunity | Margem em relação à política (20) | **0** | — | Margem na Opportunity (hoje só há `SBQQ__GrossProfit__c` na linha de cotação do CPQ) e a política de margem (não existe na org) |
| Opportunity | Disponibilidade e viabilidade de atendimento (15) | **0** | — | Campo de viabilidade. `FinancialAnalysis__c` e `TaxAnalysis__c` são análise financeira e fiscal, não viabilidade |

**Máximo hoje:** Lead 15 de 100, Opportunity 45 de 100. A lista acima vai ao roteiro do cliente, como "depende de campo a criar ou preencher". **Criar esses campos é mudança de modelo de dados e é decisão do responsável (D3)**: não está neste build.

## 6. Impacto em quem consome `PriorityBand__c`

| Consumidor | Onde está | Efeito da mudança | Tratamento |
|---|---|---|---|
| `Lead.MKT_Nutricao_ProntoAbordagem__c` (EPLAST-45) | Na dev (`AND(MKT_Nutricao_Elegivel__c, PriorityBand__c = "Alta")`, describe nesta sessão) | Com "Alta" literal, a fórmula fica sempre falsa | **A6**: `AND(MKT_Nutricao_Elegivel__c, OR(PriorityBand__c = "AA", PriorityBand__c = "A"))`. A6 troca o rótulo, mas **não resolve o efeito de negócio**: com o máximo de 15 no Lead, nenhum lead chega a AA ou A, e `Leads_Prontos_Abordagem` e os relatórios `NUTRICAO_LEADS_*` ficam vazios. Ver D2 |
| List view `Oportunidades_Prioridade_Alta` | Na dev | Filtro sem correspondência | A5 |
| Relatórios `LEADS_PROSPECCAO_PRIORIDADE` e `LEADS_PROSPECCAO_ORIGEM_PRIORIDADE` (EPLAST-42, 43) | Só nas branches remotas (não confirmado na org) | O filtro `notEqual "Sem dados suficientes"` deixa de excluir os sem dado, e o grupo "Não classificado" aparece | **Não alterado aqui.** Componente de outra demanda e não confirmado na org. Fica registrado para as donas trocarem o valor do filtro para "Não classificado" |
| Relatório `LEADS_BOAS_VINDAS` (EPLAST-44) | Só na branch | Só coluna, os valores mudam | Nada a fazer |
| `Opportunity_Record_Page` (EPLAST-30) | Branch dela | Só exibe o campo, os valores mudam | Nada a fazer. Página não alterada |
| EPLAST-28, 39 | — | Não leem o campo (`02-recon.md`, seção 6) | Nada a fazer |

## 7. O que o builder constrói

Branch `feature/EPLAST-26`, sandbox `sbx-eplast-dev`. Só metadata declarativa: **nenhum ApexTrigger, ApexClass ou Flow**.

- **B1.** C1, C2 e C3, com descrição em cada campo e no tipo.
- **B2.** A1 a A4, partindo do XML que está na org (retrieve), não do repositório, por causa da diferença de precisão. Antes do deploy real, `--dry-run`. **Se a plataforma recusar `$CustomMetadata` na fórmula (I-1)**, usar o plano B: literais com os mesmos valores da seção 4.1 e C1 fora do pacote. Registrar isso em `04-plano-build.md` e seguir, porque a regra e os valores não mudam e a configurabilidade passa a ser editar a fórmula em Setup. Se o tamanho compilado da fórmula de faixa estourar, o mesmo plano B vale só para ela.
- **B3.** A5.
- **B4.** A6, conforme a decisão D2 do gate. Sem decisão registrada, aplicar A6 (padrão: não deixar quebra silenciosa) e avisar no plano de build.
- **B5.** Deploy sem execução de testes (não há Apex no pacote). Não usar `RunAllTestsInOrg`.
- **Verificação (`verificador`), na dev:** Leads e Opportunities sintéticos pelas fixtures (nome com "Teste EPLAST26"), um por cenário da seção 8, conferindo score e faixa pela API. **Faixas AA, A e B:** com os valores iniciais ninguém chega a elas. O verificador faz deploy, só na dev, de uma cópia do registro `Default` com cortes baixos (ex.: AA 15, A 10, B 5, C 1), confere as quatro faixas e redeploya o `Default` original. Isso prova que a faixa lê o parâmetro. Na QA o registro não é mexido.
- **Rollback:** redeployar as fórmulas e list views da rodada 2 (estão no git, `rodada-anterior/premissas-assumidas/` e histórico da branch) e remover C1 a C3 por destructive change. Fórmula não guarda valor, então nada se perde.

## 8. O que o QA testa (sandbox de QA, registros sintéticos criados pelo agente)

1. Lead com engajamento "Alto": score 15, faixa D.
2. Lead com engajamento "Sem engajamento": score 0, faixa D.
3. Lead com engajamento vazio: score 0, "Não classificado".
4. Lead com setor, origem e status "Contatado", sem engajamento: score 0. Prova que os critérios antigos saíram.
5. Opportunity aberta com descoberta, orçamento, "Negociação Comercial", atividade recente e próximo passo: 45, C.
6. Opportunity "Qualificação" sem nada: 0, D.
7. Opportunity com atividade há 31 dias e o resto do cenário 5: 35, D. Com 30 dias: 45, C.
8. Opportunity "Fechado/Ganho" e "Fechado/Perdido": 0, "Não classificado".
9. Campos somente leitura (tela e API).
10. List view `Oportunidades_Prioridade_Alta` filtra AA e A (vazia com os dados atuais; conferir o filtro no XML ou na tela).
11. `MKT_Nutricao_ProntoAbordagem__c` falso para os leads de teste (consequência esperada, D2).
12. Regressão em Opportunity como na rodada 2: criar e alterar uma Opportunity sintética, as automações existentes se comportam como antes.
13. Revisão do diff: nenhum Apex, Flow, e-mail, callout ou Named Credential. Nenhuma alteração em layout, página ou permission set.

Na QAS (Partial Copy, dado real), as fórmulas passam a calcular sobre os registros existentes. Isso está autorizado pela regra 5, mas o QA não lê esses registros. A métrica de taxa de ganho por faixa continua não medível (R4).

**Roteiro do cliente:** a seção "O que assumimos e você precisa confirmar" repete as premissas da seção 9 e a tabela da seção 5, em linguagem de usuário, com destaque para "hoje nenhum lead passa de D".

## 9. Premissas assumidas (validar na homologação)

Valem as respostas do cliente de 17/11. As premissas da rodada 2 que a resposta substituiu saíram. As que seguem são as que restam ou são novas.

- [x] **PA-01 — Mecanismo.** Regra com pesos em fórmula, de 0 a 100. **Confirmada pelo cliente.**
- [x] **PA-02 — Campo Einstein.** Não é lido nem alterado. **Confirmado pelo cliente** ("a validar; não aposentar").
- [x] **PA-06 — Frequência.** Recalculado a cada leitura. Mantida (consequência da fórmula).
- [x] **PA-07 — Objetos.** Só Lead e Opportunity. Mantida.
- [x] **PA-08 — Integração.** O score não sai do Salesforce. Mantida.
- [x] **PA-12 — Conversão e ganho.** Lead convertido = `IsConverted`. Oportunidade ganha = `IsWon` ("Fechado/Ganho"; "Closed Won" está inativo, `OpportunityStage`, nesta sessão). **Confirmada pelo cliente.**
- [x] **PD-09 — Parâmetros em Custom Metadata.** Pergunta: onde ficam os parâmetros "sem deploy"? Decisão: `PriorityScoreSetting__mdt.Default`. Evidência: padrão `<Tema>Setting__mdt` da org (8 tipos). Mudar: editar o registro em Setup.
- [x] **PD-10 — Engajamento por nível.** Pergunta: como converter o engajamento em pontos? Decisão: Alto 15, Médio 10, Baixo 5, "Sem engajamento" 0. Evidência: picklist de 4 níveis na org. O cliente deu só o máximo (15), e a escala linear é o padrão mais simples. Mudar: 3 campos do registro `Default`.
- [x] **PD-11 — Estágio com evidências (25).** Decisão: descoberta 10, orçamento 10, estágio a partir de "Cotação" 5. Evidência: `Discovery_Completed__c` e `Budget_Confirmed__c` são as evidências que a org já usa (Flow da EPLAST-40). `SortOrder` dos estágios. A evidência pesa mais que o estágio, porque o estágio é declarado pelo vendedor. `ROI_Analysis_Completed__c` não entra, por falta de prova do que significa. Mudar: pesos no `Default`; lista de estágios na fórmula, em Setup.
- [x] **PD-12 — Interação e próximo passo (20); prazo (20).** Decisão: atividade nos últimos 30 dias 10, `NextStep` preenchido 10. Prazo confirmado vale 0, porque `CloseDate` é previsão do vendedor. Evidência: campos padrão da org; regra do cliente "informação ausente não gera pontuação positiva". Mudar: pesos e dias no `Default`. Para prazo, criar o campo da seção 5.
- [x] **PD-13 — "Não classificado".** Decisão: Lead sem nenhuma informação de critério (hoje, engajamento vazio). Opportunity encerrada, com score 0. Lead convertido continua calculado normalmente. Evidência: resposta do cliente ("não avaliado"). Opportunity aberta sempre tem estágio, logo é avaliada. Mudar: condição da fórmula de faixa.
- [x] **PD-14 — Compatibilidade com a classificação atual.** Decisão: a faixa usa os rótulos AA a D, iguais aos da picklist `Lead.Rating` (e `Account.Rating`), mas não grava nesse campo nem o lê. Evidência: picklists conferidas. Nenhuma automação grava `Lead.Rating`. Mudar: se a Eplast confirmar que `Rating` é a classificação atual e quiser que a faixa o alimente, isso é Flow, em demanda própria.
- [x] **PD-15 — Risco e inadimplência.** Fora do score, como o cliente pediu. O score é só leitura e não interfere nas validation rules `FinancialAnalysis` e `TaxAnalysis` nem em bloqueio de crédito.

## 10. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca lead e engajamento. **A esteira não faz nada no Marketing Cloud.**

| Ponto | No CRM |
|---|---|
| Dados que o Marketing Cloud pode ler | `Lead.PriorityScore__c`, `Lead.PriorityBand__c` (valores AA, A, B, C, D, Não classificado), `Lead.MKT_Nutricao_ProntoAbordagem__c` |
| Como o público fica identificável | Por `Lead.PriorityBand__c` ou por `MKT_Nutricao_ProntoAbordagem__c` (EPLAST-45). Nenhuma campanha nova |
| O que o Marketing Cloud devolve e onde fica | `Lead.MKT_MC_Engajamento__c` e `MKT_MC_EngajamentoData__c` (existentes, "não editar à mão"). **Agora esse retorno alimenta o score do Lead.** Se o Marketing Cloud não devolver engajamento, o lead fica "Não classificado" |
| Consentimento e opt-out | `Lead.HasOptedOutOfEmail`, `et4ae5__HasOptedOutOfMobile__c` (existentes, não alterados). Faixa alta não sobrepõe opt-out |
| O que fica para quem opera o Marketing Cloud | 1) Trocar qualquer filtro de segmento que use "Alta", "Média", "Baixa" ou "Sem dados suficientes" pelos valores novos. 2) Confirmar que o retorno de engajamento é gravado em `MKT_MC_Engajamento__c` com os 4 valores da picklist. 3) Confirmar se o sincronismo traz o valor de campo de fórmula (incerteza herdada da rodada 2) |

## 11. Ordem de execução, automação concorrente e limites

- **Lead** (1 Flow after-insert da EPLAST-35, 0 trigger, 2 validation rules) e **Opportunity** (`OpportunityBefore`/`OpportunityAfter` do SBQQ, `OpportunityTrigger`, Flow before-save da EPLAST-40, 4 Flows after-save, 16 validation rules; `02-recon.md`, seção 4): **nenhuma automação nova e nenhuma alterada.** Fórmula não grava e não entra na ordem de execução. O Flow before-save da EPLAST-40 pode promover o estágio e marcar evidências. A fórmula lê o valor já gravado, sem disputa.
- **Governador:** fórmula não consome SOQL nem DML. O caso de "um pai com muitos filhos" (achado SOMOSAGILITY-10) não se aplica: a fórmula não lê filho e nenhuma automação reage a filho.
- **Tamanho compilado:** a fórmula de faixa compila junto com a de score (referência a outra fórmula). O build confere no `--dry-run` (B2).
- **Índice:** a fórmula de Opportunity usa `TODAY()` e não é indexável. Filtro por faixa com grande volume em produção faz varredura (R3).

## 12. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | **Faixas AA, A e B inalcançáveis com os campos de hoje.** A list view "AA e A" e a nutrição da EPLAST-45 ficam vazias | **Alta** (expectativa do cliente) | Seção 1, seção 5, D2 e D3. Roteiro do cliente explica |
| R2 | A6 altera um componente da EPLAST-45, que está em homologação na QA. O merge das duas branches conflita no mesmo arquivo | **Média** | D2. A esteira sobe a EPLAST-26 para a QA só depois de alinhar com a dona da EPLAST-45. Quem fizer o merge depois resolve o conflito mantendo `AA`/`A` |
| R3 | Fórmula com `TODAY()` não indexável | Baixa | Mantido da rodada 2 |
| R4 | Taxa de ganho por faixa não é medível: fórmula não congela valor e encerrada vira "Não classificado" | Média | Já escalado na rodada 2 (snapshot exige objeto novo). Não bloqueia |
| R5 | `$CustomMetadata` recusado em fórmula ou tamanho compilado estourado | Baixa | Plano B em B2 (I-1) |
| R6 | Leitura do Custom Metadata pelo usuário sem "Personalizar aplicativo" | Baixa | Verificador confere (I-2) |
| R7 | Relatórios das EPLAST-42 e 43 passam a mostrar "Não classificado" | Baixa | Seção 6, registrado para as donas |

## 13. Riscos do assessment

| Achado | Toca? | Como fica |
|---|---|---|
| 1. Automação concorrente em Account, Opportunity e Order | Sim (Opportunity) | Não piora: nada é gravado e nenhuma automação muda. O mapeamento da ordem real continua pendente da org |
| 2. Cobertura Apex de cerca de 10% | Não | Sem Apex. Padrão de 85% por classe não se aplica |
| 3. Validation rules de Order | Não | Order não é tocado |
| 4. Campos sem descrição | Sim | C1, C2 e todos os campos alterados saem com descrição. `Discovery_Completed__c` e `Budget_Confirmed__c` continuam sem descrição (fora do escopo). O significado veio do uso pela EPLAST-40 |
| 6. Alias dev com "qa" | Resolvido | Regra 5 da conta |
| 7, 8. Perfis | Não | Nenhum perfil alterado |
| 10. `OrderTrigger` × CPQ | Não | Order não é tocado |

## 14. Para o arquiteto humano decidir neste gate

- [x] **D1 — Tipo de Custom Metadata novo (`PriorityScoreSetting__mdt`).** É configuração, não modelo de dados de negócio. Atende "parâmetros configuráveis sem deploy". Recomendo aprovar. Se recusar, o build usa o plano B (literais), sem outra mudança.
- [x] **D2 — Alterar `MKT_Nutricao_ProntoAbordagem__c` (EPLAST-45) nesta demanda (A6).** Recomendo aprovar, para não deixar quebra silenciosa. Mesmo assim a nutrição fica vazia até os campos de Lead existirem. Alternativa: a EPLAST-45 muda o próprio critério (ex.: usar `MKT_MC_Engajamento__c` direto em vez da faixa), em revisão dela.
- [x] **D3 — Campos novos da seção 5 (modelo de dados).** **Não decidi e não estão no build.** Recomendo uma demanda própria, com o comercial da Eplast definindo cada campo, quem preenche e a escala. Até lá a entrega funciona, com o máximo de 15 e 45.

Os três itens têm recomendação e caminho padrão. Nenhum deles impede o build (por isso `- [x]`).

## 15. O que NÃO será feito nesta demanda

- Campos novos para os critérios sem campo (D3).
- Modelo preditivo, Einstein, Flow, trigger, Apex, score gravado.
- Gravar a faixa em `Lead.Rating` ou `Account.Rating`.
- Risco, inadimplência ou crédito no score.
- Alteração de `Previs_o_Eintein__c`, de layouts, páginas, perfis, permission sets ou automações existentes.
- Alteração dos relatórios das EPLAST-42, 43 e 44.
- Qualquer coisa no Marketing Cloud. Nenhum envio pelo CRM.

## 16. Estimativa

**Estimativa de esforço:** 14–24 h

O que mudou em relação à análise (16–36 h) e à rodada 2 (18–30 h):
- **Menos:** os campos, o permission set, os layouts, as list views e as fixtures já existem e passaram no QA. A rodada troca fórmulas e filtros e não cria tela.
- **Mais:** o tipo de Custom Metadata (13 campos e um registro), a primeira fórmula da org que lê `$CustomMetadata` (com plano B), a prova das faixas AA a B por troca temporária do registro na dev e a coordenação com a EPLAST-45.
- Distribuição: build 3–5 h; verificação 2–4 h; QA com fixture de Opportunity e regressão 5–8 h; homologação e roteiro 3–5 h; coordenação com EPLAST-45, 42 e 43 1–2 h.

## Fontes

- `02-recon.md` (rodada 3) e, nesta sessão, por `sf` na `sbx-eplast-dev`: `OpportunityStage` (`SortOrder`, `IsActive`, `IsWon`), `ListView` (as 4 list views citadas), `EntityDefinition` (8 tipos `__mdt`), describe de Lead (`MKT_MC_Engajamento__c`, `Status`, `Rating`, fórmula de `MKT_Nutricao_ProntoAbordagem__c`) e de Opportunity (`Discovery_Completed__c`, `Budget_Confirmed__c`, `ROI_Analysis_Completed__c`, `LastActivityDate`, `NextStep`, `PriorityScore__c`).
- RAG: `[demandas/EPLAST-46/03-design.md]` e `[demandas/EPLAST-27/03-design.md]` (parâmetros em `<Tema>Setting__mdt` com registro `Default`).
- `rodada-anterior/premissas-assumidas/05-testes.md` (veredito aprovado da rodada 2) e `04-verificacao.md`.
- Nenhum registro real lido. Nada feito no Marketing Cloud.

## Incertezas declaradas

- **I-1.** Esta org não tem nenhuma fórmula de campo que leia `$CustomMetadata` (busca no `force-app` de todas as branches). Que a plataforma aceite isso e o tamanho compilado é conferido no `--dry-run`, com plano B.
- **I-2.** Se o usuário sem "Personalizar aplicativo" vê o valor calculado. O verificador confere.
- **I-3.** Se `Lead.Rating` é a "classificação atual" do cliente e quem a preenche.
- **I-4.** Se os relatórios das EPLAST-42, 43 e 44 estão na org (lidos só nas branches).
- **I-5.** Se o Marketing Cloud grava `MKT_MC_Engajamento__c` na QAS e em produção.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.

## Respostas do cliente (2026-11-17) — valem acima das premissas assumidas deste desenho

A Eplast respondeu por escrito ("Respostas Konecta/Eplast", recebido em 17/11) aos pontos que
este desenho tinha resolvido como premissa assumida. Registrado por Leonardo Barbosa, que
mandou redesenhar com as respostas. **Onde a resposta abaixo diverge de uma premissa deste
arquivo, vale a resposta.** O que o cliente marcou como "a validar" continua premissa, a
repetir no roteiro em "O que assumimos e você precisa confirmar". Os parâmetros ficam
configuráveis (pedido do cliente), sem deploy para ajustar. Reaproveite o que já foi
construído e passou no QA; mude só o que a resposta pede. Os artefatos de build e QA da
rodada anterior estão em `rodada-anterior/premissas-assumidas/` para consulta.

**Resposta do cliente (EPLAST-26 — scoring de leads e oportunidades):**
- Modelo: regras com pesos definidos pelo comercial, em campo fórmula, com critérios
  transparentes. Preditivo fica para depois. Escala de 0 a 100.
- Lead (peso máximo): potencial de compra mensal 30; aderência da demanda ao portfólio 25;
  prazo previsto para a primeira compra 20; engajamento (resposta, reunião, solicitação de
  cotação) 15; cadastro qualificado e contato com o decisor 10.
- Oportunidade (peso máximo): estágio comercial com evidências de avanço 25; interação
  recente e próximo passo confirmado 20; prazo de compra confirmado pelo cliente 20; margem
  em relação à política comercial 20; disponibilidade e viabilidade de atendimento 15.
- Informação ausente não gera pontuação positiva. O score é prioridade comercial, não
  probabilidade de fechamento.
- Conversão: lead efetivamente convertido e oportunidade efetivamente ganha ("Fechado/Ganho").
- Classificação: **AA 90–100; A 75–89; B 60–74; C 40–59; D 0–39**; não avaliado = "Não
  classificado". Validar compatibilidade com a classificação atual.
- Risco e inadimplência: alertas separados do score, depois de validados com o Financeiro.
  O score não libera venda bloqueada por crédito.
- Campo Einstein: a validar; não aposentar.

**O que muda neste desenho:**
1. Trocar critérios e pesos das fórmulas de score pelos acima. **Para cada critério, o recon
   confirma na org o campo que o representa.** Critério com campo existente entra; critério
   sem campo na org **não é inventado**: fica com 0 ponto nesta versão e listado no desenho
   e no roteiro como "depende de campo a criar ou preencher" (a criação de campo novo é
   decisão do responsável, pedir no gate com a lista).
2. Faixa: AA, A, B, C, D e "Não classificado" no lugar de Alta/Média/Baixa. Ajustar list
   views, texto de ajuda e o que as demandas 28, 30 e 39 leem de `PriorityBand__c`, se lerem.
3. Risco e inadimplência não entram no score. Campo Einstein não é tocado.
