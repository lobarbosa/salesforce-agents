# EPLAST-26 — Score e faixa de prioridade para leads e oportunidades

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial). Escopo autorizado pelo responsável da conta (card, 2026-11-13, regra 1 do briefing da Eplast). Não é pendência.
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast). O documento de origem não está no workspace; a análise parte do resumo de `demanda.md`.
**Org confirmada:** `sbx-eplast-dev`, tipo Sandbox, status Connected (`sf org list`, nesta sessão).
**Rodada:** 2. Refeita pela regra 4 da conta (2026-11-15). Substitui a análise anterior, guardada em `rodada-anterior/`.

---

## 0. O que mudou nesta rodada

- Cada pergunta de negócio que a rodada 1 deixou aberta (P1 a P14) está resolvida aqui como premissa assumida (`- [x]`), com evidência na org ou no padrão da plataforma. Nenhuma pergunta de negócio ficou como pendência.
- Achado novo: a org de dev já tem o campo `Previs_o_Eintein__c` ("Previsão Einstein", tipo double, sem descrição) em Opportunity. A rodada 1 não o tinha visto. Ver PA-02.
- Achado novo: os estágios de ganho existem em inglês e em português (`Closed Won` e `Fechado/Ganho`). Ver PA-12.
- Confirmado por `sf`: não existe campo de score em Lead nem em Opportunity.

---

## 1. Contexto de negócio

A Eplast contratou a Konecta para implantar IA no Salesforce em Sales e Marketing. Este item é da Onda 3 (Comercial). As demandas vizinhas tratam de outros pedaços do mesmo bloco: alertas para oportunidade parada (`[demandas/EPLAST-28/demanda.md]`), apoio a propostas com IA (`[demandas/EPLAST-30/demanda.md]`) e origem de leads com retorno de campanha (`[demandas/EPLAST-39/demanda.md]`). Distribuição e aprovação de leads ficam na EPLAST-35 (`[demandas/EPLAST-35/01-analise.md]`).

Todas as demandas usariam a mesma base de Lead e Opportunity. Por isso o score é definido aqui, uma vez, e as outras o consomem (PA-11).

## 2. Objetivo

Classificar leads e oportunidades pela chance de conversão em três faixas (Alta, Média e Baixa), e ordenar as listas por essa chance, para que o time comercial atue primeiro nos registros com maior chance.

Fora do escopo desta entrega: distribuição de leads, alertas, geração de texto com IA e qualquer envio de mensagem. Envio de marketing é feito pelo Marketing Cloud (regra 2 do briefing).

## 3. Regra de negócio (proposta assumida, validar na homologação)

"Chance de conversão" é lido como pontuação declarativa de 0 a 100, calculada no próprio registro por campos que já existem na org (PA-01, PA-03). Os valores abaixo são propostos. São o ponto que mais tende a mudar na homologação (PA-13).

**Lead** (score = soma dos critérios):

| Critério | Pontos |
|---|---|
| `Sector` preenchido (campo custom de Lead) | 30 |
| `LeadSource` preenchido | 30 |
| `Status` = "Contatado" | 40 |

**Oportunidade** (score = soma dos critérios):

| Critério | Pontos |
|---|---|
| `Probability` × 0,4 (ex.: 90% gera 36) | até 40 |
| `Amount` maior que zero | 20 |
| `CloseDate` em até 60 dias a partir de hoje | 20 |
| `LeadSource` preenchido | 20 |

**Faixas (ambos os objetos):** Alta, score ≥ 70. Média, de 40 a 69. Baixa, abaixo de 40.

**Casos especiais:**
- Lead sem `Sector` e sem `LeadSource`: faixa "Sem dados suficientes" e score 0. Nunca recebe faixa Alta.
- Oportunidade encerrada (`IsClosed` = verdadeiro): faixa "Encerrada" e score 0.

## 4. Critérios de aceite (Gherkin)

Todos os cenários são testáveis em sandbox de QA com registros sintéticos (PA-10). O último é de negócio e é medido após o go-live.

```gherkin
Funcionalidade: Score e faixa de prioridade em Lead e Opportunity (EPLAST-26)

  Cenário: Lead com setor, origem e status contatado recebe faixa Alta
    Dado um Lead com Sector preenchido, LeadSource preenchido e Status "Contatado"
    Quando o registro é aberto
    Então o score é 100
    E a faixa é "Alta"

  Cenário: Lead com apenas setor preenchido recebe faixa Baixa
    Dado um Lead com Sector preenchido, LeadSource vazio e Status "Aberto - Não contatado"
    Quando o registro é aberto
    Então o score é 30
    E a faixa é "Baixa"

  Cenário: Lead sem setor e sem origem não recebe faixa de prioridade
    Dado um Lead com Sector vazio, LeadSource vazio e Status "Contatado"
    Quando o registro é aberto
    Então o score é 0
    E a faixa é "Sem dados suficientes"

  Cenário: alteração de status atualiza score ao reabrir o registro
    Dado um Lead com Sector e LeadSource preenchidos e Status "Aberto - Não contatado"
    E a faixa exibida é "Média" com score 60
    Quando o Status é alterado para "Contatado"
    E o registro é reaberto
    Então o score é 100 e a faixa é "Alta"

  Cenário: Oportunidade em Negociação com valor, prazo curto e origem recebe faixa Alta
    Dado uma Opportunity com Probability 90, Amount maior que zero, CloseDate em 30 dias e LeadSource preenchido
    Quando o registro é aberto
    Então o score é 96
    E a faixa é "Alta"

  Cenário: Oportunidade com prazo em 61 dias não ganha o ponto de prazo
    Dado uma Opportunity com Probability 50, Amount maior que zero, CloseDate em 61 dias e LeadSource vazio
    Quando o registro é aberto
    Então o score é 40
    E a faixa é "Média"

  Cenário: Oportunidade em Qualificação sem valor e com fechamento distante recebe faixa Baixa
    Dado uma Opportunity com Probability 10, Amount zero, CloseDate em 200 dias e LeadSource vazio
    Quando o registro é aberto
    Então o score é 4
    E a faixa é "Baixa"

  Cenário: Oportunidade encerrada não recebe faixa de prioridade
    Dado uma Opportunity com IsClosed verdadeiro, seja em "Closed Won", "Fechado/Ganho", "Closed Lost" ou "Fechado/Perdido"
    Quando o registro é aberto
    Então a faixa é "Encerrada"
    E o score é 0

  Cenário: campos de score e faixa são somente leitura
    Dado um usuário com permissão de edição no Lead e na Opportunity
    Quando tenta editar o campo de score ou o campo de faixa
    Então o campo está bloqueado para edição

  Cenário: lista ordena por score
    Dado a list view de Leads criada nesta entrega, com leads de score 100, 30 e 0
    Quando a list view é ordenada por score de forma decrescente
    Então os registros aparecem na ordem 100, 30, 0

  Cenário: lista filtra por faixa
    Dado a list view de Opportunities criada nesta entrega
    Quando o filtro de faixa é "Alta"
    Então só aparecem oportunidades com faixa "Alta"

  Cenário: entrega não cria trigger, Flow nem Apex em Opportunity ou Lead
    Dado o pull request da entrega
    Quando o diff de metadata é revisado
    Então não há ApexTrigger novo, Flow novo nem classe Apex nova ou alterada em Opportunity ou Lead
    E as automações existentes de Opportunity (OpportunityTrigger, OpportunityBefore e OpportunityAfter do CPQ, Flows "Oportunidade Indústria" e "Fluxo Oportunidade") não têm alteração de código

  Cenário: regressão de Opportunity passa em QA
    Dado a entrega instalada na sandbox de QA
    Quando uma Opportunity é criada e depois alterada com Amount, StageName e CloseDate
    Então as automações existentes executam como antes
    E as classes de teste Apex existentes que cobrem Opportunity passam sem alteração

  Cenário: cálculo não envia dado para fora do Salesforce
    Dado a entrega revisada
    Quando o código e o metadata são revisados
    Então não há Named Credential, callout, Flow HTTP nem chamada a serviço externo relacionada ao score

  Cenário: score não dispara envio de mensagem pelo CRM
    Dado a entrega revisada
    Quando o metadata é revisado
    Então não há email alert, Flow de e-mail nem Apex de e-mail criados por esta entrega

  Cenário: taxa de ganho por faixa (critério de negócio, medido após o go-live, não bloqueia a entrega)
    Dado seis meses de oportunidades com faixa calculada
    Quando o relatório de oportunidades por faixa é executado para o período
    Então a taxa de oportunidades ganhas na faixa "Alta" é maior que na faixa "Baixa"
```

## 5. O que a demanda não diz e como ficou resolvido

| O que faltou na demanda | Resolvido em |
|---|---|
| Mecanismo: regra com pesos, modelo preditivo ou ambos | PA-01 |
| Existência de um campo de previsão já na org | PA-02 |
| Dados de entrada (quais campos) | PA-03 |
| Onde o resultado aparece e quem vê | PA-04 |
| O que significa "priorizar" | PA-05 |
| Frequência de atualização | PA-06 |
| Objetos cobertos (Lead, Opportunity, Account, Order) | PA-07 |
| Integração com ERP ou outro sistema | PA-08 |
| Governança: quem pode ver, editar ou ajustar pesos | PA-09 |
| Como validar a qualidade sem dado real | PA-10 |
| Relação com EPLAST-28, -30 e -39 | PA-11 |
| Definição de conversão e de oportunidade ganha | PA-12 |
| Critérios e pesos (pergunta do card de 2026-11-13, item 2) | PA-13 |
| Quem são os usuários-alvo | PA-04 |

## 6. Premissas assumidas (validar na homologação)

Cada item traz a pergunta, a decisão, a evidência e como mudar se a Eplast discordar. A evidência de org foi confirmada por `sf` nesta sessão, com metadata e contagens agregadas. Nenhum dado de registro foi lido.

- [x] **PA-01 — Mecanismo (P1).** Pergunta: "classificar pela chance de conversão" é regra com pesos, modelo preditivo ou ambos?
  - Decisão: regra declarativa com pesos (seção 3). Nenhum modelo preditivo nem serviço externo nesta entrega.
  - Evidência: Lead tem 12 campos custom e Opportunity tem 28; nenhum é campo de score ou de probabilidade calculada (lista completa de nomes conferida). A única previsão existente é `Previs_o_Eintein__c` (PA-02). Sandbox sem registros (0 Lead, 0 Opportunity, 0 Lead convertido, contagem agregada): não há histórico para treinar modelo. Padrão da plataforma: campo de fórmula antes de modelo, pois a regra é explicável e não grava nada.
  - Como mudar: trocar a fórmula por modelo em demanda própria, com licença, dados e acordo sobre quem processa os dados. Os campos de score e faixa permanecem.

- [x] **PA-02 — Campo "Previsão Einstein" (regra 3).** Pergunta: o campo existente já cobre o pedido?
  - Decisão: não é reaproveitado como score nesta versão. A faixa é construída ao lado, e o campo existente não é alterado.
  - Evidência: `Previs_o_Eintein__c` (rótulo "Previsão Einstein", tipo double, sem texto de ajuda). Não há Flow nem Apex no repositório que o escreva. Ele aparece como coluna só na list view `AllOpportunities`. Sandbox sem registros, então não é possível ver o que ele guarda. Sem essa informação, não dá para afirmar que ele atende ao pedido.
  - Como mudar: se a Eplast confirmar que é a mesma métrica, o arquiteto troca a entrada da fórmula e o campo passa a ser a base da faixa. No recon, confirmar por `sf` quem alimenta o campo (Flow, Apex ou pacote).

- [x] **PA-03 — Campos de entrada (P3).** Pergunta: quais campos entram no score?
  - Decisão: Lead usa `Sector`, `LeadSource` e `Status`. Opportunity usa `Probability`, `Amount`, `CloseDate` e `LeadSource`. Atividades e engajamento do Marketing Cloud ficam fora.
  - Evidência: `Lead.LeadSource`, `Lead.Status`, `Opportunity.Probability`, `Opportunity.Amount`, `Opportunity.CloseDate`, `Opportunity.LeadSource` e `Opportunity.StageName` existem (describe). `Lead.Sector` existe como campo custom. Atividades exigiriam contagem por lote, e engajamento de Marketing Cloud (pacote `et4ae5`) é dado do Marketing Cloud, fora do CRM (regra 2).
  - Como mudar: incluir atividades muda a entrega para lote agendado (ver PA-06). Incluir engajamento de Marketing Cloud depende de quem opera o Marketing Cloud (passo fora da esteira).

- [x] **PA-04 — Onde aparece e quem vê (P4).** Pergunta: em qual tela o resultado aparece e para quem?
  - Decisão: campo de score (número) e campo de faixa (texto) em Lead e Opportunity, no layout da página e em colunas e filtros das list views. Visível para quem já lê o objeto. Usuários-alvo: vendedor e gestor.
  - Evidência: padrão de campo de fórmula com segurança de campo padrão. A org tem 20 dashboards e 53 relatórios, e nenhum deles tem score no nome. O perfil exato dos usuários não foi confirmado por `sf` e fica para o recon.
  - Como mudar: segurança de campo e layout, sem código.

- [x] **PA-05 — "Priorizar" na prática (P5).** Pergunta: priorizar é ordenação, campo, fila, alerta ou notificação?
  - Decisão: ordenação por score e filtro por faixa nas list views. Sem alerta, sem fila e sem notificação. Distribuição fica na EPLAST-35.
  - Evidência: padrão de list view. A list view ordena por uma coluna só. Por isso empates seguem a ordem padrão do Salesforce, e uma segunda ordenação, se a Eplast pedir, é configuração.
  - Como mudar: configuração de list view ou nova demanda para alerta.

- [x] **PA-06 — Frequência (P6).** Pergunta: o score é atualizado a cada save ou em lote?
  - Decisão: fórmula recalculada a cada leitura. Sem trigger, sem Flow e sem lote na versão 1.
  - Evidência: fórmula não grava nada e não dispara automação. Lead não tem nenhum trigger (consulta de `ApexTrigger`). Opportunity tem `OpportunityTrigger` custom, `OpportunityBefore` e `OpportunityAfter` do CPQ, e Flows no mesmo evento. Gravar score ali criaria mais um ponto de concorrência (assessment, achado 1).
  - Como mudar: se a Eplast precisar do score gravado (histórico ou valor fixo em relatório), vira lote agendado. Isso é decisão de design e aumenta o esforço (seção 10).

- [x] **PA-07 — Escopo de objetos (P7).** Pergunta: Account e Order entram?
  - Decisão: só Lead e Opportunity. Account, Order e OrderItem ficam fora. Lead convertido mantém o score do lead, em somente leitura. A oportunidade criada calcula o próprio score, sem herança.
  - Evidência: a demanda cita leads e oportunidades. O assessment concentra o risco de concorrência de automação em Account e Order. Lead convertido: contagem agregada zero na sandbox.
  - Como mudar: incluir Account exige revisar antes a automação do CPQ nesse objeto.

- [x] **PA-08 — Integração (P8).** Pergunta: o score vai para o Protheus ou outro sistema?
  - Decisão: não. O score não sai do Salesforce.
  - Evidência: as classes de integração com o Protheus citadas no assessment são de Account e Order (`SendAccountToProtheus`, `SendOrderToProtheus`). Não há integração identificada para Lead ou Opportunity.
  - Como mudar: nova demanda, com gate.

- [x] **PA-09 — Governança (P9).** Pergunta: quem vê, quem ajusta os pesos e como o vendedor entende a faixa?
  - Decisão: campos de fórmula são somente leitura para todos. Pesos e faixas mudam por administrador, com deploy de metadata, e não por usuário. A regra fica no texto de ajuda do campo, o que responde "por que este lead tem esta faixa". Dono após o go-live: administrador Salesforce da Eplast, a confirmar.
  - Evidência: comportamento padrão de campo de fórmula.
  - Como mudar: se a Eplast quiser ajustar pesos sem deploy, os valores vão para Custom Metadata (decisão do arquiteto).

- [x] **PA-10 — Validação de qualidade (P10).** Pergunta: como medir se o score funciona e quem fornece a amostra?
  - Decisão: o aceite de QA é funcional. Cada cenário da seção 4 é conferido com registros sintéticos criados na sandbox, sem dado real. A métrica de negócio (taxa de ganho por faixa) é medida depois do go-live com relatório existente, e não bloqueia a entrega.
  - Evidência: sandbox com 0 Lead, 0 Opportunity e 0 Lead convertido (contagem agregada). A LGPD (regra 2) impede usar dado real de cliente no contexto ou nos testes. Relatórios que servem à medição já existem: "Oportunidades Abertas no Pipeline", "Oportunidades ganhas AF/T" e "MKT Conversao de Leads por Origem".
  - Como mudar: se a Eplast enviar amostra agregada, a calibração dos pesos entra na homologação.

- [x] **PA-11 — Relação com EPLAST-28, -30 e -39 (P11).** Pergunta: são a mesma solução?
  - Decisão: a EPLAST-26 cria os campos de score. As EPLAST-28, -30 e -39 os consomem depois, cada uma com seu gate.
  - Evidência: histórico do RAG descreve as três na mesma base de Lead e Opportunity.
  - Como mudar: se uma delas precisar de outro cálculo, ela cria campo próprio.

- [x] **PA-12 — Definição de conversão (P13).** Pergunta: o que conta como conversão de lead e como oportunidade ganha?
  - Decisão: oportunidade ganha = `IsWon` verdadeiro (hoje: "Closed Won" e "Fechado/Ganho"). Oportunidade encerrada = `IsClosed` verdadeiro (inclui "Closed Lost" e "Fechado/Perdido"). Lead convertido = `IsConverted` verdadeiro ("Fechado - Convertido").
  - Evidência: `OpportunityStage` e `LeadStatus` conferidos por `sf` (metadata). Os dois estágios de ganho contam, porque o flag é o mesmo. O estágio "Closed" tem `IsClosed` falso e fica sem papel definido, a confirmar com a Eplast.
  - Como mudar: alterar o flag do estágio na configuração. A fórmula não muda.

- [x] **PA-13 — Critérios e pesos (pergunta do card, 2026-11-13, item 2).** Pergunta: quais critérios somam pontos e com que peso?
  - Decisão: os critérios e pesos da seção 3.
  - Evidência: nenhum histórico na org para calibrar (sandbox vazia). O card não trouxe critério do cliente até hoje. Os campos citados existem (PA-03). Padrão: pesos somando 100 e três faixas, para leitura simples.
  - Como mudar: os valores ficam num lugar só (fórmula ou Custom Metadata, decisão do arquiteto). A calibração é feita na homologação.

**Pendências bloqueantes (caso 3 da regra 4): nenhuma.** Considerei como candidata a pendência a escolha de mecanismo preditivo (PA-01), porque errá-la é custoso. Não é o caso: a org não tem histórico para treinar modelo, e a troca futura substitui só a fórmula, sem mudar campos nem faixas.

## 7. Riscos do assessment e da org que tocam o pedido

O assessment (`assessment.md`) tem saúde vermelha. Ele não cobre Lead. Os riscos abaixo são o que ele diz sobre Opportunity, mais o que a consulta da sandbox trouxe.

| # | Risco | Origem | Como toca a EPLAST-26 | Tratamento |
|---|---|---|---|---|
| 1 | Automação concorrente em Opportunity (trigger custom, triggers do CPQ e Flows no mesmo evento) | Assessment, achado 1 (alta) | Score gravado em Opportunity criaria novo ponto de concorrência | Fórmula, sem gravação, sem trigger e sem Flow novos (PA-06). Regressão no critério da seção 4 |
| 2 | Cobertura Apex de 10% | Assessment, achado 2 (alta) | Não há Apex nesta versão | Se o design precisar de Apex, classe de teste própria com 85% por classe |
| 3 | Campos sem descrição (Opportunity: 19 de 28; Lead: não medido) | Assessment, achado 4 (média) | Campos de entrada podem ser usados sem saber o que significam | Descrição validada antes de usar (PA-03). Campos novos saem com descrição |
| 4 | Alias dev aponta para sandbox com host "qa" | Assessment, achado 6 (média), confirmado agora | Build e homologação podem colidir | Pré-requisito de build (seção 8) |
| 5 | Sandbox vazia (0 Lead, 0 Opportunity) | Assessment, e confirmado por contagem | Não há dado para testar nem calibrar | Dados sintéticos e medição pós-go-live (PA-10) |
| 6 | Campo "Previsão Einstein" já existente | Achado desta rodada | Risco de criar dois conceitos de previsão na mesma tela | PA-02, com confirmação no recon |

**Regra 3 (não sobrepor).** O agente SFAgent2 existe (`BotDefinition` confirmado, com 4 versões de planner de rótulo SFAgent2). Não confirmei por `sf` a contagem de tópicos e ações citada no briefing, porque os objetos de Gen AI não são consultáveis por esta API. Esta entrega não estende o agente, porque o pedido é um campo de score, não um assistente. Se a Eplast quiser que o assistente responda "quais leads priorizar", isso estende o SFAgent2 em demanda própria (EPLAST-30 ou nova). Existem Prompt Flows de Opportunity ("Dados da Oportunidade", "Cotação Primária") e o Flow agendado "Fluxo Agendado - Oportunidade". Nenhum deles calcula score. Não criei relatório de conversão novo: reaproveito os existentes (PA-10).

## 8. Antes do build (não bloqueia esta análise)

- **Dev e QA separados (risco 4).** O `instanceUrl` de `sbx-eplast-dev` tem host `eplast--qa`. Confirmar, antes de qualquer deploy, que dev e QA são sandboxes distintas. Isso é checagem técnica, não pergunta de negócio.
- **Recon (etapa 2):** confirmar por `sf` o OWD e os layouts de Lead e Opportunity, a descrição de `Lead.Sector` e `Subsector`, e quem alimenta `Previs_o_Eintein__c` (PA-02).
- **Registros de teste:** sintéticos, sem nome, e-mail ou telefone reais (LGPD).

## 9. Complexidade

**M.** Sem código e sem integração, mas toca dois objetos, sendo que um deles tem automação concorrente, e os pesos precisam de validação com o comercial.

## 10. Estimativa de esforço humano

**Estimativa de esforço:** 16–36 h

Premissas que mais pesam na faixa (esforço do consultor e do dev para configurar, revisar, testar e homologar):

1. **Só campos de fórmula e layout (PA-01, PA-06).** Sem Apex e sem Flow. Se o design pedir score gravado ou atividades (PA-03, PA-06), soma 16 a 24 h, porque vira lote com teste próprio.
2. **Pesos e faixas (PA-13).** Uma rodada de ajuste na homologação cabe na faixa. Duas ou mais rodadas puxam para o topo.
3. **Campos de entrada (PA-03).** Validar a descrição e o preenchimento de `Lead.Sector` e dos campos de Opportunity pesa mais do que a configuração.
4. **Teste funcional com dados sintéticos (PA-10)** e homologação com o comercial, cada um com a sua sessão.
5. **Não incluído:** a remediação do assessment (mapear ordem de execução em Opportunity, consolidar triggers). Se o design achar necessário antes de mexer em Opportunity, soma horas.

A faixa é de configuração, não de desenvolvimento. O arquiteto refina no design.

---

## Fontes

- `demandas/EPLAST-26/demanda.md` e `demandas/EPLAST-26/comentarios-do-card.md` (card, inclusive decisões de 2026-11-13 e 2026-11-15).
- `assessment.md` (achados 1, 2, 4 e 6; sandbox vazia). Foto de 2026-09-30.
- `CLAUDE.md` do cliente, regras 1 a 4.
- `sf` na `sbx-eplast-dev`: metadata (describe de Opportunity e Lead, `OpportunityStage`, `LeadStatus`, `ApexTrigger`, Flow via Tooling, `BotDefinition`, `CustomField`) e contagens agregadas. Nenhum registro real foi lido.
- RAG: `[demandas/EPLAST-28/demanda.md]`, `[demandas/EPLAST-30/demanda.md]`, `[demandas/EPLAST-39/demanda.md]`, `[demandas/EPLAST-35/01-analise.md]`.
- Repositório: `force-app/main/default/objects/Opportunity/fields/Previs_o_Eintein__c.field-meta.xml` e a list view `AllOpportunities`.
- Rodada anterior (`rodada-anterior/01-analise.md`): usada como referência das perguntas, não como decisão.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
