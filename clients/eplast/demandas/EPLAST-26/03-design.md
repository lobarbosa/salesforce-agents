# EPLAST-26 — Design: score e faixa de prioridade em Lead e Opportunity

**Rodada:** 2 (pela regra 4 da conta). Substitui o design de `rodada-anterior/03-design.md`, que fica só como referência.
**Org consultada:** `sbx-eplast-dev`, Sandbox, Connected (`sf org list`, nesta sessão, 2026-11-15). Só leitura: metadata e contagens agregadas, nenhum registro lido.
**Insumos:** `01-analise.md` (rodada 2, gate aprovado em 2026-11-15), `02-recon.md`, `comentarios-do-card.md`, regras 1 a 4 do `CLAUDE.md` da Eplast, `assessment.md` (resumo da sessão), skills `salesforce-doutrina` e `padrao-entrega`, RAG (designs de EPLAST-28 e EPLAST-30).
**Atenção do gate:** o card registra que a aprovação da análise foi dada em lote e que **as premissas da análise não foram revisadas uma a uma e devem ser conferidas neste gate**. Por isso a seção 9 repete todas, com a decisão final de design ao lado.

---

## 1. Solução proposta

Quatro **campos de fórmula** (dois em Lead, dois em Opportunity) calculam o score de 0 a 100 e a faixa (Alta, Média, Baixa, mais as faixas especiais) a partir de campos que já existem. Um **permission set** dá leitura nesses campos. Três **list views** novas mostram o score e a faixa para o vendedor ordenar e filtrar. Os campos entram nos **layouts de página** de Lead e Opportunity.

Nada grava em registro, nada dispara automação, nada sai do Salesforce, nada é enviado ao Marketing Cloud pela esteira.

## 2. Decisão: configuração (nível 1 da doutrina)

| Alternativa | Nível | Por que sim ou não |
|---|---|---|
| **(a) Campo de fórmula** (escolhida) | Configuração | Regra explicável, sem gravação, fora da ordem de execução. Lead tem 0 trigger e 0 Flow; Opportunity tem 3 triggers e 3 Flows (`02-recon.md`, seção 3): fórmula não acrescenta concorrência. Sem Apex, o deploy não esbarra na cobertura de 10% |
| (b) Flow record-triggered que grava o score | Declarativo | Rejeitada. Em Opportunity seria o 4º Flow e conviveria com `OpportunityTrigger`, `OpportunityBefore`/`OpportunityAfter` (SBQQ), `Oportunidade_Industria` e `OpportunityFlow` no mesmo evento: exatamente o achado 1 do assessment. Além disso, o critério de prazo depende de hoje e exigiria recálculo agendado |
| (c) Apex (trigger ou lote agendado) | Código | Rejeitada. Nada na regra exige Apex (não há rollback, callout, volume nem recursão). Somaria classe nova numa org com 10% de cobertura |
| (d) Einstein Lead/Opportunity Scoring ou Prediction Builder | Configuração de recurso | Rejeitada nesta versão (PA-01): a sandbox tem 0 Lead e 0 Opportunity, não há histórico para treinar, e não há definição de predição na org (`MLPredictionDefinition`: 0, nesta sessão) |
| (e) Pesos em Custom Metadata lidos pela fórmula | Configuração | Rejeitada (PD-02): mudar um literal da fórmula em Setup é o mesmo esforço de mudar um registro de Custom Metadata, e o tipo novo só aumentaria o que manter |

**Não desci de nível.** A decisão não depende da ordem de execução.

## 3. Item a item: o que reaproveita e o que cria (regra 3)

### Reaproveita, sem alterar

| Componente | Confirmado em | Uso |
|---|---|---|
| `Lead.Sector__c` (picklist restrita, 8 valores) | describe, nesta sessão | Entrada do score de Lead. **O API name é `Sector__c`**, não `Sector` como na análise |
| `Lead.LeadSource` (picklist não restrita, 13 valores) | describe | Entrada |
| `Lead.Status` (valor de API "Contatado" confirmado, igual ao rótulo) | describe | Entrada |
| `Lead.IsConverted` | describe | Entrada (PD-05) |
| `Opportunity.Probability`, `Amount`, `CloseDate`, `LeadSource`, `IsClosed` | describe | Entrada |
| Layouts `Lead Layout`, `Opportunity Layout`, `CPQ Opportunity Layout` | Tooling `Layout`, nesta sessão | Recebem os campos novos |
| Páginas Lightning `Lead_Record_Page`, `Lead_Record_Page_Three_Column`, `Opportunity_Record_Page`, `Opportunity_Record_Page_Three_Column` | Tooling `FlexiPage`, nesta sessão | Só se usarem Dynamic Forms (ver seção 7, B3) |
| Relatórios "Oportunidades Abertas no Pipeline", "Oportunidades ganhas AF/T", "Taxa de Conversão de Leads" e painel "Leads & Oportunidades" | `02-recon.md`, seção 1 | Base para análise depois do go-live. Não são alterados nesta entrega |
| Agente `SFAgent2` (v4: 4 tópicos, 3 ações) | `02-recon.md`, seção 1 | **Não é estendido.** O pedido é campo de score, não assistente. Uma ação que leia `PriorityBand__c` fica para EPLAST-30 ou demanda própria |
| Conector `et4ae5` (264.1.0.1) e `Lead.HasOptedOutOfEmail`, `Lead.et4ae5__HasOptedOutOfMobile__c` | `02-recon.md`, seção 2 | Seção 6 (Marketing Cloud). Nada criado do lado do conector |

### Não reaproveita, com motivo

| Componente | Por quê |
|---|---|
| `Opportunity.Previs_o_Eintein__c` (rótulo "Previsão Einstein", Number(3,0), sem descrição) | Origem desconhecida. Nesta sessão: não é fórmula, não é gravável pelo usuário da esteira (FLS só leitura nas 2 permissões que o citam), e não há `MLPredictionDefinition`, `MLDataDefinition` nem `AIApplication` na org. O formato (inteiro de 0 a 999, só leitura) é compatível com um campo de predição do Einstein cujo modelo foi removido, mas isso **não está provado**. Sem saber quem o alimenta e com 0 Opportunity, não dá para usá-lo como score (PA-02). Não é alterado |
| `IsPriorityRecord` (rótulo "Importante", padrão) | Flag manual do usuário, não score. Não é tocado; o rótulo dos campos novos foi escolhido para não confundir com ele |
| List views existentes (`AllOpenLeads`, `AllOpportunities` etc.) | Mudar colunas de vistas gerais altera o que todo usuário vê, e o critério de aceite pede vistas criadas nesta entrega. As 6 cópias pessoais de Opportunity não são tocadas |

### Cria

| # | Tipo | API name | Rótulo | Detalhe |
|---|---|---|---|---|
| C1 | Campo fórmula Number(3,0) | `Lead.PriorityScore__c` | Score de prioridade | Seção 4.1 |
| C2 | Campo fórmula Text | `Lead.PriorityBand__c` | Faixa de prioridade | Seção 4.1 |
| C3 | Campo fórmula Number(3,0) | `Opportunity.PriorityScore__c` | Score de prioridade | Seção 4.2 |
| C4 | Campo fórmula Text | `Opportunity.PriorityBand__c` | Faixa de prioridade | Seção 4.2 |
| C5 | Permission Set | `PS_Comercial_ScorePrioridade` | Comercial - Score de prioridade | Leitura em C1 a C4. Sem permissão de objeto (o objeto já vem do perfil) |
| C6 | List view de Lead | `Leads_Abertos_Prioridade` | Leads abertos por prioridade | Seção 4.3 |
| C7 | List view de Opportunity | `Oportunidades_Abertas_Prioridade` | Oportunidades abertas por prioridade | Seção 4.3 |
| C8 | List view de Opportunity | `Oportunidades_Prioridade_Alta` | Oportunidades de prioridade alta | Seção 4.3 |
| A1 | Alteração de layout | `Lead-Lead Layout`, `Opportunity-Opportunity Layout`, `Opportunity-CPQ Opportunity Layout` | — | Incluir os 2 campos, só leitura, numa seção "Prioridade". O layout de aprovação ("Análise financeira") não é tocado |

**Nomes:** o `CLAUDE.md` da Eplast não define prefixo e os custom da org não usam prefixo (`Sector__c`, `CompanyDocument__c`, inglês em PascalCase). Sigo a prática da org (PD-01). Os mesmos nomes nos dois objetos facilitam o consumo pelas EPLAST-28, -30 e -39 (PA-11). Nenhum campo com esses nomes existe hoje (describe, nesta sessão).

**Todo componente sai com `description`** (Definition of Done e achado 4 do assessment). C1 a C4 levam também `inlineHelpText` com a regra em linguagem de usuário (PA-09).

## 4. Especificação para o build

### 4.1 Lead

`Lead.PriorityScore__c` (Number, 3 casas inteiras, 0 decimais, `formulaTreatBlanksAs` = `BlankAsZero`):

```
IF(
  AND(ISBLANK(TEXT(Sector__c)), ISBLANK(TEXT(LeadSource))),
  0,
  IF(ISBLANK(TEXT(Sector__c)), 0, 30)
  + IF(ISBLANK(TEXT(LeadSource)), 0, 30)
  + IF(OR(ISPICKVAL(Status, "Contatado"), IsConverted), 40, 0)
)
```

`Lead.PriorityBand__c` (Text):

```
IF(
  AND(ISBLANK(TEXT(Sector__c)), ISBLANK(TEXT(LeadSource))),
  "Sem dados suficientes",
  IF(PriorityScore__c >= 70, "Alta",
    IF(PriorityScore__c >= 40, "Média", "Baixa"))
)
```

Texto de ajuda (C1): "Soma de pontos: Setor preenchido 30, Origem do lead preenchida 30, Status Contatado (ou lead convertido) 40. Sem setor e sem origem, o score é 0." Texto de ajuda (C2): "Alta: 70 ou mais. Média: 40 a 69. Baixa: abaixo de 40. Sem dados suficientes: lead sem setor e sem origem."

### 4.2 Opportunity

`Opportunity.PriorityScore__c` (Number(3,0), `BlankAsZero`):

```
IF(
  IsClosed,
  0,
  ROUND(BLANKVALUE(Probability, 0) * 40, 0)
  + IF(BLANKVALUE(Amount, 0) > 0, 20, 0)
  + IF(AND(NOT(ISBLANK(CloseDate)), CloseDate >= TODAY(), CloseDate - TODAY() <= 60), 20, 0)
  + IF(ISBLANK(TEXT(LeadSource)), 0, 20)
)
```

`Opportunity.PriorityBand__c` (Text):

```
IF(IsClosed, "Encerrada",
  IF(PriorityScore__c >= 70, "Alta",
    IF(PriorityScore__c >= 40, "Média", "Baixa")))
```

`Probability` é percentual: na fórmula, 90% vale 0,9, então 0,9 × 40 = 36. Conferência dos cenários da análise: 90%/valor/30 dias/origem = 36+20+20+20 = **96, Alta**; 50%/valor/61 dias/sem origem = 20+20 = **40, Média**; 10%/valor zero/200 dias/sem origem = **4, Baixa**.

Texto de ajuda (C3): "Soma de pontos: Probabilidade × 0,4 (até 40), Valor maior que zero 20, Fechamento entre hoje e 60 dias 20, Origem do lead preenchida 20. Oportunidade encerrada: 0." C4: mesmo texto de faixa de C2, trocando "Sem dados suficientes" por "Encerrada: oportunidade fechada, ganha ou perdida".

A org tem multimoeda ativa só com BRL (`CurrencyIsoCode` restrita, um valor ativo). O critério `Amount > 0` não depende de moeda.

### 4.3 List views

| API name | Filtro | Colunas mínimas | Visível para |
|---|---|---|---|
| `Leads_Abertos_Prioridade` | `Status` diferente de "Fechado - Convertido" e "Fechado - Não convertido" | Nome, Empresa, Setor, Origem do lead, Status, Score de prioridade, Faixa de prioridade, Proprietário | Todos os usuários internos |
| `Oportunidades_Abertas_Prioridade` | Oportunidade não encerrada | Nome, Conta, Fase, Probabilidade, Valor, Data de fechamento, Score, Faixa, Proprietário | Todos os usuários internos |
| `Oportunidades_Prioridade_Alta` | Não encerrada e `PriorityBand__c` = "Alta" | As mesmas de C7 | Todos os usuários internos |

Escopo de registros: "Todos" (o sharing continua valendo: cada usuário só vê o que já vê hoje; OWD Lead interno ReadWriteTransfer, Opportunity interno Read, `02-recon.md` seção 5).

**Ordenação:** a metadata de list view não guarda ordenação. "Ordenar por score" é o usuário clicar na coluna, e a escolha fica salva para ele. Isso atende o cenário "lista ordena por score" da análise, que já descreve a ordenação como ação do usuário. Ver incerteza I-3.

### 4.4 Permissões

- `PS_Comercial_ScorePrioridade`: `fieldPermissions` de leitura (sem edição, que fórmula não aceita) em C1 a C4.
- A esteira atribui o permission set só ao usuário de teste, na dev (build) e na QA (QA). Na QA, sem criar usuário novo (RAG: licenças `Salesforce` em 14/14, design de EPLAST-30, R13).
- Atribuir aos usuários reais é **passo manual pós-deploy** do administrador da Eplast, por ambiente, aos usuários dos perfis da PD-07.
- Nenhum perfil é alterado por metadata (evita mexer em perfis duplicados, item do assessment).

## 5. Impacto em objetos e automações, ordem de execução e CPQ

| Objeto | Automação existente (recon) | Impacto desta entrega |
|---|---|---|
| Lead | 0 trigger, 0 Flow, 2 validation rules (`Celular`, `Telefone`) | Nenhum. Fórmula é calculada na leitura |
| Opportunity | `OpportunityBefore` e `OpportunityAfter` (SBQQ), `OpportunityTrigger` (custom, after insert/update), Flows after-save `Oportunidade_Industria` e `OpportunityFlow`, Flow agendado `ScheduledFlowOpportunity`, 16 validation rules ativas | Nenhum na execução. **A ordem de execução em Opportunity continua não mapeada (achado 1 do assessment) e esta entrega não depende dela**: campo de fórmula não grava, não dispara trigger nem Flow e não entra na sequência before/after. Nenhuma automação existente é alterada |
| Account, Order, OrderItem, Quote | `OrderTrigger`, CPQ, integração Protheus | Não tocados |

**Convivência com o CPQ.** O CPQ pode escrever `Amount` (sincronização da cotação primária) e a fase muda `Probability`. A fórmula só lê esses campos e recalcula na próxima leitura; não há escrita de volta, então não há recursão nem disputa com `OpportunityBefore`/`OpportunityAfter`.

**Governador e escala.**
- Transação: fórmula não consome SOQL, DML nem CPU de gravação. O cenário "um pai com muitos filhos" (achado SOMOSAGILITY-10) não se aplica: a fórmula não lê `OpportunityLineItem` nem cotação, e nenhuma automação nova reage a filho.
- Leitura: `PriorityScore__c` e `PriorityBand__c` de Opportunity usam `TODAY()`, então não são indexáveis. Em volume grande, o filtro por faixa em C8 e em relatório faz varredura. Volume de produção desconhecido (dev com 0 registro). Risco R4.
- Tamanho compilado das fórmulas: pequeno (poucos campos, nenhum cross-object). O build confirma ao salvar.

## 6. Preparação do Sales Cloud para o Marketing Cloud

A demanda toca lead, origem e status, então esta seção vale. **A esteira não faz nada no Marketing Cloud.**

| Ponto | No CRM | Observação |
|---|---|---|
| Dados que o Marketing Cloud pode ler | `Lead.PriorityScore__c`, `Lead.PriorityBand__c` (novos), mais `Lead.Sector__c`, `Lead.LeadSource`, `Lead.Status` (existentes) | Score de Opportunity não é dado de marketing; fica fora |
| Como o público fica identificável | Campo `Lead.PriorityBand__c` (valores fixos: Alta, Média, Baixa, Sem dados suficientes). Sem campanha nem membro de campanha nesta entrega (Campaign e CampaignMember têm 0 registros; origem e campanha são da EPLAST-39) | Segmento por faixa é filtro sobre o Lead sincronizado |
| O que o Marketing Cloud devolve e onde fica | Nada desta entrega. O retorno de envio já cai nos objetos do conector (`et4ae5__IndividualEmailResult__c` etc.) e em `CampaignMember.et4ae5__Activity__c` | Engajamento não entra no score (PA-03) |
| Consentimento e opt-out | `Lead.HasOptedOutOfEmail` e `Lead.et4ae5__HasOptedOutOfMobile__c` (existentes, não alterados) | Faixa Alta não sobrepõe opt-out. O filtro de opt-out é obrigação do público montado no Marketing Cloud |
| O que fica para quem opera o Marketing Cloud | 1) Incluir `PriorityScore__c` e `PriorityBand__c` no Lead sincronizado do Marketing Cloud Connect, se quiser segmentar por faixa. 2) Montar o segmento excluindo opt-out. 3) Conferir se o sincronismo traz o valor de campo de fórmula (incerteza I-5) | Passos fora da esteira |

O score de Lead não depende de `TODAY()`: ele só muda quando o próprio Lead é gravado, o que em tese mantém o valor sincronizado coerente. O de Opportunity depende da data e não deve ser usado como dado de marketing.

## 7. O que o builder constrói

Branch `feature/EPLAST-26`, sandbox `sbx-eplast-dev`. Só metadata declarativa: **nenhum ApexTrigger, ApexClass ou Flow** (critério de aceite da análise).

- **B0 (pré-build, checagem técnica):** registrar em `04-plano-build.md` como foi conferido que a org de dev e a de QA são sandboxes distintas (achado 6 do assessment; host e username do alias dev contêm "qa", `02-recon.md` seção 6). Se não der para provar, registrar a incerteza. **Não é pergunta de negócio e não bloqueia o build** (a análise já a tratou como checagem). Não transcrever username nem URL.
- **B1:** C1 a C4 com fórmula, descrição e texto de ajuda da seção 4. Fórmula de faixa referencia o campo de score do mesmo objeto.
- **B2:** C5 com leitura nos 4 campos; atribuir ao usuário da esteira na dev para exercitar.
- **B3:** A1. Antes, verificar se as páginas Lightning ativas de Lead e Opportunity usam Dynamic Forms (seção de campos na FlexiPage). Se usarem, colocar os campos na FlexiPage ativa em vez do layout; se não, só no layout. Registrar qual página está ativa.
- **B4:** C6 a C8. Conferir na dev se a coluna de score é ordenável e se o filtro por `PriorityBand__c` é aceito (I-3). Se a ordenação por fórmula não for permitida, registrar e propor relatório tabular ordenado como alternativa, sem construí-lo sem voltar ao gate.
- **B5:** deploy com `--dry-run` antes do real. Sem Apex no pacote, o nível de teste é o padrão sem execução de testes; não usar `RunAllTestsInOrg`.
- **Verificação (agente `verificador`):** criar na dev um Lead sintético por cenário de Lead e conferir C1/C2 pela API (só os campos da entrega, nenhum dado pessoal: nomes como "Teste EPLAST26 01"). Opportunity sintética: ver seção 8, fixture.
- **Rollback:** remover C6 a C8, A1, C5 e C1 a C4, nessa ordem (destructive changes). Nenhum dado é perdido, porque fórmula não guarda valor.

## 8. O que o QA testa

Os 16 cenários Gherkin da análise (seção 4 de `01-analise.md`), com estes ajustes:

- O campo do cenário de Lead é `Sector__c` ("Setor").
- Acrescentar: **lead convertido** mantém score 100 e faixa Alta quando tinha setor e origem (PD-05); **Opportunity com fechamento ontem** (vencida) não ganha o ponto de prazo (PD-03); **fechamento exatamente em 60 dias** ganha o ponto; **Probability 55%** dá 22 pontos de probabilidade (arredondamento, PD-04).
- Cenário "somente leitura": conferir que os campos aparecem como não editáveis no layout e que a API recusa escrita.
- Cenário "não cria trigger, Flow nem Apex": revisão do diff do PR.
- O cenário de taxa de ganho por faixa **não é testável** e não é medível com esta solução (R5). Fica registrado, não reprova a entrega.

**Fixture de Opportunity (ponto frágil, achado 1 do assessment e histórico de EPLAST-28 e EPLAST-30).** Criar Opportunity nesta org passa pelas 16 validation rules ativas: `CheckAccountHasBillingAddress`, `CheckAccountHasCNAE`, `CheckAccountHasCompanyName`, `CheckAccountHasEmail`, `CheckAccountHasPhone`, `CheckAccountHasStore`, `CheckAccountOwnerHasProtheusSellerId`, `CheckHasAccount`, `CheckOppHasBranch`, `CheckOppHasPaymentMethods`, `CheckOppHasPaymentTermId`, `FinancialAnalysis`, `Industria_Fase_Cotacao_Sem_Catalogo`, `LossReason`, `PriceBook`, `TaxAnalysis` (Tooling, nesta sessão). A fixture preenche todos os campos que elas exigem, com valores fictícios (conta, dono com ID de vendedor Protheus, filial, forma e condição de pagamento, catálogo de preços, motivo de perda para os cenários de perda). Pelo histórico do RAG (`[demandas/EPLAST-30/03-design.md]`, R13), criar Opportunity **dispara o `OpportunityFlow`, que cria cotação CPQ e pode submeter aprovação**, e a cadeia pode chegar à integração Protheus (`[demandas/EPLAST-39/rodada-anterior/03-design.md]`). Use o menor número de registros que cobre os cenários, confirme antes qual endpoint a sandbox de QA usa, e não use bypass global de automação. Esse DML é do QA na sandbox, nunca da solução. Apagar os registros sintéticos ao fim.

**Regressão em Opportunity:** criar e depois alterar `Amount`, `StageName` e `CloseDate` de uma Opportunity sintética e confirmar que as automações existentes se comportam como antes (cotação criada, sem erro novo). Rodar as classes de teste Apex existentes de Opportunity (`FlowOpportunityControllerTest` e outras que cubram `OpportunityTriggerHandler`/`Helper`) e registrar o resultado **antes e depois** do deploy: se já falham antes, isso é achado da org, não reprovação desta entrega.

**Roteiro do cliente:** repetir as premissas da seção 9 em "O que assumimos e você precisa confirmar", em linguagem de usuário, com destaque para pesos, faixas e lead convertido.

## 9. Premissas assumidas (validar na homologação)

Todas resolvidas. Nenhuma fica como pendência.

### Da análise, com a decisão de design

- [x] **PA-01 — Mecanismo.** Regra com pesos em fórmula. Mantida (seção 2). Evidência acrescida: nenhuma definição de predição na org, nesta sessão. Mudar: substituir a fórmula de C1/C3; os campos e as faixas ficam.
- [x] **PA-02 — "Previsão Einstein".** Não reaproveitado. Mantida. O design acrescenta que o campo não é gravável pelo usuário da esteira e que não há modelo definido na org (seção 3). Mudar: se a Eplast disser que é a mesma métrica e quem o alimenta, C3 passa a ler `Previs_o_Eintein__c` no lugar dos pontos de probabilidade.
- [x] **PA-03 — Campos de entrada.** Mantida, com o API name corrigido para `Lead.Sector__c`.
- [x] **PA-04 — Onde aparece e quem vê.** Layout, list views; leitura via permission set (PD-07).
- [x] **PA-05 — Priorizar.** Ordenação pelo usuário e filtro por faixa (seção 4.3).
- [x] **PA-06 — Frequência.** Recalculado a cada leitura. Mantida.
- [x] **PA-07 — Objetos.** Só Lead e Opportunity. Lead convertido: ver PD-05, que torna "mantém o score" concreto.
- [x] **PA-08 — Integração.** O score não sai do Salesforce. Mantida.
- [x] **PA-09 — Governança.** Fórmulas só leitura; regra no texto de ajuda; pesos alterados pelo administrador (PD-02).
- [x] **PA-10 — Validação.** Funcional, com dado sintético. **Ajustada:** a métrica "taxa de ganho por faixa" não é medível com relatório existente (R5).
- [x] **PA-11 — Relação com EPLAST-28, -30, -39.** Elas consomem `PriorityScore__c`/`PriorityBand__c`. Mantida.
- [x] **PA-12 — Conversão e ganho.** `IsWon`, `IsClosed`, `IsConverted`. Mantida; a fórmula usa `IsClosed`, então os dois idiomas de estágio contam igual.
- [x] **PA-13 — Critérios e pesos.** Os da seção 3 da análise, sem mudança.

### Novas, do design

- [x] **PD-01 — Nome dos campos.** Pergunta: qual prefixo usar? Decisão: sem prefixo, `PriorityScore__c` e `PriorityBand__c`. Evidência: `CLAUDE.md` da Eplast sem prefixo; custom da org sem prefixo (`Sector__c`, `CompanyDocument__c`). Mudar: renomear antes do deploy em produção; depois disso, só criando campo novo.
- [x] **PD-02 — Onde ficam os pesos.** Decisão: literais na fórmula, documentados no texto de ajuda. Evidência: padrão (opção mais simples); alterar fórmula em Setup não exige código. Mudar: mover para Custom Metadata se a Eplast quiser que alguém sem "Personalizar aplicativo" ajuste.
- [x] **PD-03 — Fechamento vencido.** Pergunta: oportunidade aberta com data de fechamento no passado ganha o ponto de prazo? Decisão: não; a janela é de hoje até hoje + 60 dias, inclusive. Evidência: a análise fala em "em até 60 dias a partir de hoje"; data vencida em oportunidade aberta indica registro desatualizado (tema da EPLAST-28). Mudar: retirar `CloseDate >= TODAY()` da fórmula.
- [x] **PD-04 — Arredondamento.** Decisão: pontos de probabilidade arredondados para inteiro (`ROUND`, 0,5 para cima). Evidência: score é inteiro de 0 a 100 na análise. Mudar: trocar por `FLOOR`.
- [x] **PD-05 — Lead convertido.** Pergunta: como "manter o score" se o status muda para "Fechado - Convertido"? Decisão: lead convertido conta os 40 pontos de contato (`IsConverted` equivale a contatado) e segue a faixa normal. Evidência: todo lead convertido foi contatado; sem isso, a fórmula baixaria o score na conversão. Mudar: retirar `IsConverted` da fórmula ou criar faixa "Convertido".
- [x] **PD-06 — Lead "Fechado - Não convertido".** Decisão: sem faixa especial; fica fora de C6 pelo filtro de status. Evidência: padrão (menos regras); não há flag de encerrado em Lead. Mudar: acrescentar faixa "Encerrado" na fórmula de C2.
- [x] **PD-07 — Quem recebe a leitura.** Decisão: `PS_Comercial_ScorePrioridade`, atribuído pelo administrador da Eplast aos usuários dos perfis `Comercial`, `Comercial Padrão`, `Comercial - Analista`, `Comercial - Analistas`, `Marketing`, `Usuário do Marketing` e administradores. Evidência: perfis com leitura em Lead e Opportunity (`02-recon.md`, seção 5); permission set é o padrão do squad e não mexe nos perfis duplicados. Mudar: atribuir a outros usuários, sem deploy.
- [x] **PD-08 — Visibilidade das list views.** Decisão: as três para todos os usuários internos. Evidência: o sharing do objeto continua filtrando os registros. Mudar: restringir a grupo, em Setup.

## 10. Riscos técnicos

| # | Risco | Severidade | Tratamento |
|---|---|---|---|
| R1 | Automação concorrente em Opportunity (achado 1) torna a **fixture de teste** cara e pode disparar cotação CPQ e integração | **Média** (esforço de QA) | Seção 8. A solução em si não toca a ordem de execução |
| R2 | Dev e QA podem ser a mesma sandbox (achado 6) | **Média** | B0. Checagem técnica registrada no build |
| R3 | `Previs_o_Eintein__c` com origem desconhecida; dois "conceitos de previsão" na tela de Opportunity | Baixa | Rótulos distintos; campo existente fora dos layouts alterados por esta entrega (só está na list view `AllOpportunities`); PA-02 |
| R4 | Fórmula com `TODAY()` não indexável: filtro por faixa lento com muito volume em produção | Baixa (volume desconhecido) | Se a Eplast tiver volume grande de Opportunity aberta, avaliar campo gravado em demanda própria |
| R5 | **A métrica de negócio "taxa de ganho por faixa" não é medível**: fórmula não congela valor, e oportunidade fechada vira "Encerrada" | Média (expectativa) | Não bloqueia (a análise já a pôs fora do aceite). Medir exige foto periódica da faixa, por exemplo relatório de snapshot (*reporting snapshot*) gravando num objeto custom. **Objeto novo é mudança de modelo de dados: escalo ao arquiteto humano**, como demanda futura |
| R6 | Ordenação ou filtro de list view por fórmula com `TODAY()` não aceito | Baixa | B4 confere na dev; alternativa volta ao gate |
| R7 | Cobertura Apex de 10% | Não se aplica | Sem Apex. Deploy em produção de metadata sem Apex não exige execução de testes |

## 11. Riscos e recomendações do assessment

| Item do assessment | Toca a demanda? | Como fica |
|---|---|---|
| Consolidar automação concorrente em Account/Opportunity/Order; mapear ordem de execução | Sim (Opportunity) | Não piora: nada é acrescentado à sequência. O mapeamento continua pendente da org, fora desta demanda |
| Elevar cobertura Apex | Não | Sem Apex. A regressão registra o estado das classes de Opportunity antes e depois |
| Validation rules de Order (8 obrigatoriedade, 6 inativas) | Não | Order não é tocado |
| 153 campos sem descrição | Sim | Campos novos com descrição e ajuda. `Lead.Sector__c` e `Previs_o_Eintein__c` seguem sem descrição: preencher é fora do escopo |
| Classes de teste fora do sufixo `<Classe>Test` | Não | Sem Apex |
| `sbx-eplast-dev` distinta de QA | Sim | B0 |
| Perfil Financeiro, perfis comerciais duplicados | Indireto | Nenhum perfil alterado; permission set em vez de FLS em perfil |
| API version antiga em classes | Não | Nenhuma classe tocada |
| `OrderTrigger` x pacote CPQ | Não | Order não é tocado |

## 12. Incertezas declaradas

- **I-1.** Quem alimenta `Previs_o_Eintein__c` (`02-recon.md`, item 1). O indício de campo de predição do Einstein não está provado.
- **I-2.** Eventos de `OpportunityBefore`/`OpportunityAfter` e corpo atual de `OpportunityTrigger` na org. Não afetam a solução; afetam a fixture.
- **I-3.** Se list view do Lightning ordena e filtra por campo de fórmula com `TODAY()` nesta org. Conferido no build (B4).
- **I-4.** Se as páginas Lightning de Lead e Opportunity usam Dynamic Forms e qual está ativa. Conferido no build (B3).
- **I-5.** Se o sincronismo do Marketing Cloud Connect traz o valor de campo de fórmula. É do operador do Marketing Cloud (seção 6).
- **I-6.** Contagem de custom de Opportunity (28 na análise, 41 linhas no recon com SBQQ). Não afeta a solução.

## 13. O que NÃO será feito nesta demanda

- Modelo preditivo, Einstein Scoring, Prediction Builder ou serviço externo.
- Score gravado, Flow, trigger, Apex, lote agendado.
- Score em Account, Order, Contact ou cotação.
- Alteração de `Previs_o_Eintein__c`, de automação de Opportunity, de perfis ou de list views existentes.
- Relatório, painel ou snapshot novos (R5 vai ao humano como demanda futura).
- Extensão do `SFAgent2`.
- Qualquer configuração, jornada, público ou envio no Marketing Cloud; e-mail alert ou envio pelo CRM.
- Descrição de campos antigos sem descrição.

## 14. Escalado ao arquiteto humano

1. **R5 — medir a taxa de ganho por faixa** exige objeto novo (modelo de dados). Não decidi. Não bloqueia o build desta entrega.
2. **Conferência das premissas da análise** (seção 9), porque a aprovação da análise foi em lote, segundo o card.

**Pendência bloqueante (caso 3 da regra 4): nenhuma.**

## 15. Estimativa

**Estimativa de esforço:** 18–30 h

O que mudou em relação à análise (16–36 h):
- **Topo cai de 36 para 30 h:** o design fecha em fórmula sem Custom Metadata, sem lote e sem Apex, então a hipótese de soma de 16 a 24 h da análise sai.
- **Base sobe de 16 para 18 h:** a fixture de Opportunity (16 validation rules, `OpportunityFlow` criando cotação CPQ) pesa mais no QA do que a análise previu, a julgar pelo histórico de EPLAST-28 e EPLAST-30.
- Distribuição aproximada: build e verificação 5–8 h; QA com fixture e regressão 7–12 h; homologação com uma ou duas rodadas de ajuste de pesos 4–7 h; revisão e passos manuais (permission set, layouts) 2–3 h.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
