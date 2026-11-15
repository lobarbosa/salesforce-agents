# EPLAST-39 — Análise: Origem dos leads e retorno das campanhas

**Status:** análise para validação humana. Não aciona design.
**Fontes:** `demandas/EPLAST-39/demanda.md` (história do consultor), `contrato.md`, `assessment.md` (2026-09-30), consulta `sf` à `sbx-eplast-dev` em 2026-11-10 (metadata e contagens agregadas; nenhum registro de cliente lido), RAG do cliente (sem resultado relevante).

---

## Bloqueador de escopo contratual (ler antes de tudo)

Esta demanda está **fora do escopo contratado hoje**:

- O contrato (`contrato.md`) cobre as Ondas 1 (Diagnóstico) e 2 (Projeto-piloto), 120 h. Marketing é a **Onda 4**, "ainda não contratada".
- A própria `demanda.md` declara: "Onda 4 · Marketing — ainda não contratada no projeto atual (Ondas 1–2)".
- O projeto tem fim previsto em 2026-11-30. Hoje é 2026-11-10.

**Pergunta obrigatória para o gate desta análise:** como o humano quer proceder?

1. **Aditivo de escopo** — contratar a Onda 4 (ou o recorte desta demanda) e só então seguir para design e build;
2. **Aguardar a Onda 4** — a demanda fica em `backlog` como projeto futuro, sem consumir o saldo de 120 h;
3. **Somente levantamento** — registrar a análise, o diagnóstico de dados (seção "Premissas") e o roteiro, sem build, sem horas de construção e sem tocar na org além de leitura.

Enquanto isso não for respondido, **nenhuma etapa de design ou build deve ser acionada**, e as horas desta análise não devem ser debitadas do escopo Ondas 1–2.

---

## Contexto de negócio

A Eplast quer saber de onde vêm os leads, quais campanhas de marketing geram conversão e quanto retorno cada ação traz. A demanda pede medição, não automação de processo: análise de desempenho de campanhas, conversões e origem dos leads.

Ela nasce da proposta da Konecta para implantação de IA no Salesforce Sales e Marketing, dentro da Onda 4.

## Objetivo

Dar ao time de Marketing da Eplast uma visão confiável de:

- **origem** de cada lead (de qual canal ou campanha ele veio);
- **desempenho** de cada campanha (leads gerados, leads convertidos, oportunidades, valor ganho, custo);
- **conversão** lead → oportunidade → ganho, por origem e por campanha.

O objetivo não está fechado quanto à forma: pode ser relatório, dashboard ou pacote de métricas. Ver "o que a demanda NÃO diz".

## Regra de negócio (o que se sabe e o que é hipótese)

Confirmado na org (`sf`, sandbox de dev):

- **Lead.LeadSource** (padrão, "Origem do lead") tem picklist com 13 valores: Campanha, WhatsApp, Indicação, Evento, Google Ads, Google Orgânico, Instagram, Facebook, Prospecção ativa, Prospecção passiva, Econodata, E-mail MKT, SDR. Esta é a fonte de origem disponível hoje.
- **Não existem campos UTM** em Lead, Campaign, CampaignMember nem Opportunity. A origem por UTM, se for requisito, precisa de captura nova (build).
- **Campaign** não tem campo custom de canal, tipo de origem ou ROI. Usa os campos padrão: `ActualCost`, `BudgetedCost`, `NumberOfLeads`, `NumberOfConvertedLeads`, `NumberOfOpportunities`, `NumberOfWonOpportunities`, `AmountWonOpportunities`.
- **Opportunity** tem `LeadSource` e `CampaignId` (padrão). Não há campo custom de origem.
- **CampaignMember** tem `Status`, `HasResponded`, `FirstRespondedDate`, `LeadSource` e o campo custom `et4ae5__Activity__c` (Marketing Cloud Connect).
- **Campaign Influence** existe como objeto (`CampaignInfluenceModel`) e a sandbox tem 1 registro. Não confirmei se o modelo está ativo nem qual é.
- **Relatórios já existentes na org** (38 com nomes ligados a campanha, lead, origem ou conversão), entre eles "Marketing Exec Leads by Source", "Marketing Exec Campaign ROI by Camp Type", "Marketing Exec Leads Converted", "Taxa de Conversão de Leads", "Leads Converted by FQ" e a pasta "MARKETING CLOUD" com relatórios de LEADS por UF. Não confirmei se estão em uso, se estão corretos nem se usam campos calculados. Parte do que a demanda pede pode já existir.

Hipóteses — **não confirmadas, pendentes de validação**:

- H1. A origem dos leads de produção é preenchida majoritariamente via `LeadSource` (manual ou por integração). Não confirmável aqui: **a sandbox tem 0 Leads, 0 Campaigns e 0 CampaignMembers**.
- H2. Os valores de `LeadSource` são usados com disciplina. A lista tem "Campanha" genérico ao lado de "Google Ads" e "E-mail MKT", o que sugere sobreposição (um lead de campanha de e-mail pode cair em "Campanha" ou em "E-mail MKT").
- H3. O ROI de campanha = (AmountWonOpportunities − ActualCost) / ActualCost, ou outra fórmula. A fórmula não foi definida.
- H4. Os leads de produção vêm também do Protheus ou do Marketing Cloud, e não só do Salesforce. Não confirmado.

## Saúde da org — riscos do `assessment.md` que tocam esta demanda

Saúde geral **vermelha**. Relação com o pedido:

| Achado do assessment | Toca esta demanda? | Como |
|---|---|---|
| **1. Automação concorrente em Account, Opportunity e Order** (severidade alta) | **Sim, se a conversão for medida por Opportunity e a solução escrever nela.** | Leitura de Opportunity para relatório não dispara automação. Qualquer campo novo gravado em Opportunity (ex.: origem consolidada, flag de atribuição) ou Flow que reaja a conversão de Lead passa pela cadeia CPQ + trigger custom + 2 Flows. **Não identifiquei trigger ou Flow em Lead ou Campaign** (ver abaixo), então medição só de leitura não piora o achado 1. |
| **2. Cobertura Apex de 10%** (severidade alta) | **Só se houver Apex novo.** | Um relatório ou dashboard não exige Apex. Captura de UTM via Apex ou atribuição automática exigiria teste com `<Classe>Test` e ≥85%. |
| **3. Validation Rules do Order** | Não. | Fora do escopo. |
| **4. Campos custom sem descrição** (68,6% em Account/Order/Opportunity) | **Sim, marginalmente.** | Qualquer campo novo (origem consolidada, UTM) sai com `Description`. Campos existentes de Opportunity usados aqui (`LeadSource`, `CampaignId`) são padrão. |
| **6. Alias `sbx-eplast-dev` aponta para sandbox cuja identificação interna sugere ser a de QA** (severidade média, bloqueante para confiar na separação dev/qa) | **Sim, para o build, não para esta análise.** | Ver nota abaixo. |

Nota sobre o achado 6, confirmada agora com `sf org display`: o alias `sbx-eplast-dev` está `Connected`, na instance `eplast--qa.sandbox.my.salesforce.com` — o próprio nome de instância sugere QA, não dev, ecoando o achado 6 do assessment. **Não consigo afirmar, a partir daqui, se esta é a sandbox de dev ou a de QA da esteira.** Se for a mesma de QA, qualquer build feito aqui compete com o roteiro de homologação. Esta análise é só leitura, então não é afetada. Antes de qualquer build, o humano precisa confirmar qual sandbox é cada um. (Username da conexão omitido aqui de propósito — guardrail #2.)

Nota de metadata: a `sf org display` retornou API **68.0**, e o assessment registrou **v67** em 2026-09-30. Não investiguei; é diferença de leitura ou de upgrade da org. Não muda a análise.

### Achados de automação em Lead e Campaign (verificado agora)

- **Não há Apex Trigger** em Lead, Campaign nem CampaignMember (consulta à Tooling API).
- Consulta a `FlowDefinitionView` por objeto Lead ou Campaign retornou **0 linhas**. Ressalva: não confirmei se a view expõe o rótulo de objeto da forma que eu filtrei, então isso precisa de checagem mais direta (describe/metadata por Flow) antes do design.
- **Marketing Cloud Connect** (`et4ae5`) está instalado: existem objetos `et4ae5__Automated_Send__c`, `et4ae5__AggregateLink__c` e outros, com **0 registros** `Automated_Send` na sandbox. O assessment registra 17 Workflow Rules 100% do pacote `et4ae5`. **Não confirmei se existe automação própria do cliente que dependa do conector.** Antes de supor, o design precisa mapear isso com `sf` (ex.: Flows e Apex que referenciem `et4ae5__`).

## Critérios de aceite (Gherkin)

Estes critérios são **condicionais**: só valem se o humano confirmar o escopo (ver bloqueador) e fechar as dúvidas de "o que a demanda NÃO diz". Onde falta definição, o critério diz o que falta.

```gherkin
Funcionalidade: Origem dos leads

  Cenário: todo lead do período tem uma origem contável
    Dado que existem leads criados no período [PERÍODO A DEFINIR]
    Quando eu abro o relatório de leads por origem
    Então a soma dos leads por origem é igual ao total de leads criados no período
    E os leads sem LeadSource aparecem em uma linha própria "Sem origem"

  Cenário: a origem usa a lista controlada
    Dado a lista de valores de LeadSource na sandbox de dev
    Quando eu comparo com a lista acordada com a Eplast [LISTA A VALIDAR]
    Então não há valor em uso fora da lista acordada, ou o desvio está registrado como pendência

Funcionalidade: Conversão

  Cenário: conversão lead → oportunidade por origem
    Dado uma amostra de leads convertidos no período [TAMANHO DA AMOSTRA A DEFINIR]
    Quando eu comparo o relatório de conversão com a amostra
    Então a taxa por origem bate com a contagem de IsConverted = true para a mesma amostra

Funcionalidade: Retorno de campanha

  Cenário: painel por campanha
    Dado uma campanha com ActualCost maior que zero
    Quando eu abro o painel de campanhas
    Então vejo custo, leads, leads convertidos, oportunidades, oportunidades ganhas e valor ganho
    E o ROI é calculado pela fórmula acordada [FÓRMULA A DEFINIR]

  Cenário: campanha sem custo não gera ROI
    Dado uma campanha com ActualCost igual a zero ou vazio
    Quando eu abro o painel de campanhas
    Então o ROI aparece como "não se aplica", e não como zero ou infinito

Funcionalidade: Restrições

  Cenário: nenhum dado pessoal aparece no painel
    Dado que o painel é exibido para o time de Marketing
    Quando eu inspeciono colunas e filtros
    Então não há nome, e-mail, telefone ou CPF de Lead ou Contact, somente agregados

  Cenário: nenhuma escrita em objeto de automação concorrente sem análise
    Dado que a solução foi desenhada
    Quando o arquiteto revisa o desenho
    Então nenhuma escrita nova em Account, Opportunity ou Order existe sem que o achado 1 do assessment tenha sido tratado no design

  Cenário: sem alteração em org fora da esteira
    Dado que a solução é implantada
    Então a implantação acontece somente em sbx-eplast-dev ou sbx-eplast-qa, após a confirmação de qual é cada uma
```

**Observação:** os critérios de "dados pessoais" e de "escrita em Opportunity" são testáveis no design e no QA; os de conversão e ROI dependem de definição (período, amostra, fórmula) e de dados de produção que a sandbox não tem.

## O que a demanda NÃO diz (precisa de resposta antes do design)

1. **Escopo e contrato.** É aditivo, espera da Onda 4 ou só levantamento? (bloqueador, ver acima)
2. **Período de análise.** Mensal, trimestral, histórico completo?
3. **Fonte de verdade para origem.** Só `LeadSource`? Ou também UTM, formulário, integração com Marketing Cloud ou Protheus?
4. **Lista de origens.** A lista de 13 valores é a oficial? "Campanha" e "E-mail MKT" são disjuntas? Quem governa a lista?
5. **Atribuição.** Primeiro toque, último toque, multi-toque? Usa Campaign Influence?
6. **Fórmula de ROI.** Qual? Receita ganha, margem, ticket médio? Custo é `ActualCost`, `BudgetedCost` ou custo externo?
7. **Quem é o público.** Marketing, Comercial, diretoria? Qual o nível de detalhe?
8. **Relação com os relatórios que já existem.** Os 38 relatórios são para substituir, complementar ou ignorar?
9. **Papel de Marketing Cloud.** O relatório precisa de dados de envio e clique (Marketing Cloud) ou só de Salesforce? Isso muda a arquitetura (conector, DE, Analytics).
10. **Decisão de plataforma de Marketing (eplast-ent-05).** O entregável diz "concluído", mas o conteúdo não está nesta workspace. Qual plataforma foi decidida e isso limita o escopo?
11. **Volume e dados reais.** A sandbox de dev não tem Lead, Campaign nem Opportunity. Medir a qualidade atual de `LeadSource` exige amostra de produção, e produção não pode ser consultada pelo agente. Como o time da Eplast fornece essa amostra (agregada, sem dado pessoal)?
12. **Responsável pela qualidade do dado.** Se `LeadSource` estiver vazio em boa parte da base, quem corrige: processo comercial, integração, ou a demanda?
13. **Sandbox correta.** Qual é a sandbox de dev e qual é a de QA? (achado 6 do assessment)

## Premissas a validar (todas pendentes)

- **P1 (pendente, bloqueador).** Esta demanda não está no escopo contratado. Não é debitada das 120 h das Ondas 1–2.
- **P2 (pendente).** A solução é preferencialmente de **leitura** (relatórios, dashboards, painel de campanha) sobre os objetos padrão. Escrita nova em Lead, Opportunity ou Campaign é build, precisa de nova estimativa e passa pelo achado 1.
- **P3 (pendente).** Nenhum Apex novo. Se for necessário, a demanda sobe de complexidade e exige teste com ≥85% (`<Classe>Test`).
- **P4 (pendente).** `LeadSource` é a fonte primária de origem. UTM fica fora, a menos que a Eplast confirme que é requisito.
- **P5 (pendente).** Os relatórios existentes ajudam, mas o uso e a correção deles não foram verificados.
- **P6 (pendente).** Marketing Cloud Connect não é usado como fonte para este pedido. Se for, a estimativa sobe.
- **P7 (pendente).** As contagens de 0 Lead/Campaign/CampaignMember na sandbox refletem que a sandbox não tem dado de produção, e não que os objetos não estão em uso.

## Complexidade

**M.** Justificativa: o pedido é de leitura sobre objetos padrão, mas a qualidade da origem depende da governança de `LeadSource` (13 valores, sem UTM), a conversão passa por Opportunity (objeto com automação concorrente no assessment) e o escopo, se incluir captura ou atribuição, sobe para G.

## Estimativa de esforço

**Estimativa de esforço:** 24–60 h

Premissas que mais pesam na faixa:

- **Escopo levantamento + painel sobre objetos padrão (P2, sem Apex)** puxa para o piso (~24–30 h): mapeamento dos relatórios existentes, dashboard de origem e campanha, validação com a amostra, testes e homologação.
- **Captura de UTM ou atribuição multi-toque, ou escrita em Opportunity** puxa para o teto (~50–60 h): campos novos com descrição, Flow ou Apex com teste, análise de ordem de execução com o CPQ.
- **Marketing Cloud como fonte (P6)** pode acrescentar horas de mapeamento do conector, não incluídas na faixa.
- **Qualidade do dado de origem** (sem amostra de produção) é o maior fator de incerteza; pode dobrar o esforço de saneamento se o `LeadSource` estiver vazio em boa parte da base, e isso não entra na faixa.
- A faixa é larga porque a demanda é vaga e o escopo contratual ainda não foi decidido. O arquiteto refina no design.

---

## Próximo passo

Responder o bloqueador de escopo (aditivo, espera ou levantamento) e as questões 1 a 6 e 13 do bloco "o que a demanda NÃO diz". Sem isso, o design não tem base.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
