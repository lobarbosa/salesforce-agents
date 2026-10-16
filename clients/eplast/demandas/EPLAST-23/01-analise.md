# Análise — EPLAST-23: Resumo inteligente de cliente (Agentforce)

## Contexto de negócio

Usuários de vendas e atendimento ao cliente precisam preparar reuniões, acompanhar oportunidades e resolver questões operacionais com base em uma visão consolidada de cada cliente. Atualmente, essa informação está espalhada em múltiplos registros no Salesforce (Account, Contact, Opportunity, Order, Case) e requer navegação manual entre telas. A consolidação sob demanda via linguagem natural reduz tempo de preparação e diminui riscos de decisão baseada em informação incompleta.

## Objetivo

Construir um agente no Agentforce capaz de responder em linguagem natural solicitações como "Resuma o cliente [nome]" e apresentar informações consolidadas de:
- Identificação e dados cadastrais da conta
- Contatos vinculados (nomes, cargos, canais de contato)
- Negociações em andamento e recentes
- Pedidos recentes
- Casos de atendimento abertos e recentes
- Síntese de pontos de atenção (oportunidades que vencerão em breve, casos pendentes críticos)

Tudo sem criar ou alterar registros, respeitando permissões de acesso do usuário.

## Regra de negócio

1. **Consulta sob demanda:** o agente responde apenas quando solicitado, sem agendamento ou notificações proativas.
2. **Respeito a permissões:** não expõe registros, campos ou dados que o usuário não tem permissão de ler (via Force.com security model ou regras adicionais).
3. **Sem invenção de dados:** baseia as conclusões nos registros consultados; não deduz, não estima, não preenche lacunas.
4. **Sem efeitos colaterais:** apenas leitura — nenhuma criação, alteração ou exclusão de registros durante a consulta.
5. **Esclarecimento de ambiguidade:** se múltiplas contas correspondem ao nome fornecido, solicita confirmação antes de consolidar dados.
6. **Sinalização de ausência:** categorias sem dados são marcadas explicitamente, não omitidas.
7. **Rastreabilidade:** as informações são acompanhadas de referências aos registros de origem (para que o usuário possa aprofundar).

## Critérios de aceite

```gherkin
Funcionalidade: Resumo inteligente de cliente via Agentforce

Cenário: Solicitar resumo de cliente por nome (caminho feliz)
  Dado que o usuário está no Agentforce
  Quando o usuário digita "Resuma o cliente [nome]"
  E existe exatamente uma conta correspondente
  Então o agente apresenta seções de:
    | Visão geral        |
    | Contatos           |
    | Negociações        |
    | Pedidos            |
    | Ocorrências        |
    | Síntese de atenção |
  E cada seção contém dados ou a indicação "Sem registros nesta categoria"
  E as referências aos registros permitem acesso direto
  E nenhum registro foi criado ou alterado

Cenário: Ambiguidade na identificação do cliente
  Dado que múltiplas contas correspondem ao nome fornecido
  Quando o usuário solicita o resumo
  Então o agente lista os clientes potenciais
  E pede ao usuário que confirme qual deles deseja resumir

Cenário: Respeito a permissões de acesso
  Dado que o usuário não tem permissão de leitura em um registro
  E esse registro seria incluído no resumo
  Então o agente não o expõe
  E a categoria correspondente reflete apenas os registros acessíveis

Cenário: Categoria sem dados
  Dado que o cliente não tem registros em uma categoria
    (ex.: nenhuma negociação aberta)
  Quando o agente gera o resumo
  Então a seção sinaliza claramente: "Sem negociações em andamento"
  E não omite a categoria

Cenário: Recuperação de falha na identificação
  Dado que o cliente mencionado não existe
  Quando o agente procura pela conta
  Então retorna mensagem clara: "Cliente não encontrado"
  E oferece buscar por critérios alternativos (ex.: CNPJ, código interno)
```

## O que a demanda NÃO diz (gaps de especificação)

### Dados e estrutura

1. **Quais campos integram a "Visão geral"?**
   - Apenas nome e tipo de conta? Ou inclui faturamento, segmento, localização, pessoa de contato designada?
   - Há campos custom que devem estar ali?

2. **Quais campos para cada Contato?**
   - Apenas nome e cargo? Ou email, telefone, LinkedIn, data da última interação?
   - Deve mostrar todos os contatos ou apenas os ativos/com papel definido?

3. **Quais campos para cada Negociação (Opportunity)?**
   - Além de etapa, valor, previsão de fechamento: inclui produto/linha? Probabilidade? Competidores? Motivo de perda (se encerrada)?
   - Quantas negociações recentes? Últimos 90 dias? Últimas 10 abertas + últimas 5 fechadas?

4. **Que tipo de objeto representa "Pedidos"?**
   - `Order` (Salesforce Order Cloud)? `Quote`? Ambos?
   - Quantos pedidos recentes? (Últimos 30 dias? Últimas 10?)
   - Quais campos? (Valor total, status, data de entrega, itens, descontos aplicados?)

5. **Qual objeto é "Ocorrências"?**
   - `Case` (Service Cloud)? Há outro nome na org?
   - Status "aberto": vale apenas Status = 'Open'? Ou inclui 'In Progress', 'On Hold'?
   - Quantos "recentes": últimos 30 dias? Últimas 20 casos?

6. **Quais dados compõem a "Síntese de atenção"?**
   - "Negociações próximas do fechamento" = Expected Close Date <= próximos 7 dias? 14 dias? 30 dias?
   - "Ocorrências pendentes" = todos os abertos? Apenas Priority = 'High'?
   - Há outros critérios além desses dois? (Contatos sem telefone? Pedidos não pagos? Negociações sem movimento há 30 dias?)

### Contexto técnico

7. **Qual é a versão do Salesforce e o tipo de Agentforce em uso?**
   - Einstein Copilot com custom actions (prompt + Flow + Apex)?
   - AI Research (agente autônomo)?
   - Skills do Agentforce (nova IA generativa do Salesforce)?
   - Há documentação ou setup pronto na sandbox `sbx-eplast-dev`?

8. **Como os dados são recuperados: SOQL nativo ou via Apex/API?**
   - O agente consulta diretamente via SOQL ou via uma classe Apex que encapsula as queries?
   - Há um action/skill já pronto que o agente chama, ou o action é ser construído inteiramente?

9. **Renderização e limites:**
   - A resposta tem limite de tamanho/caracteres? (Agentforce trunca após N caracteres?)
   - Como renderizar "referências": apenas número do registro (Account Name, Opportunity Name)? Ou links/IDs do Salesforce?
   - Se um cliente tem 50 contatos, o agente mostra todos ou apenas top 10?

### Regras de negócio e validação

10. **Quem pode usar e em que contexto?**
    - Qualquer usuário com login Salesforce, ou apenas roles específicas (Vendedor, Gerente, Agente)?
    - O agente respeita apenas o Force.com security model, ou há regras adicionais (ex.: vendedor vê só seus clientes)?

11. **Tratamento de nomes ambíguos:**
    - Se o usuário digita "Acme", e há "Acme Corp", "Acme Ltda", "Acme Distribuidora" — quantas opções o agente mostra?
    - Pode usar CNPJ, código de cliente ou ID direto se o usuário fornecer?

12. **Frequência e histórico:**
    - O agente mantém histórico de resumos gerados (para auditoria)?
    - Há limite de chamadas por usuário/hora?

### Dados sensíveis e conformidade

13. **Mascaramento ou exposição de valores sensíveis:**
    - Valores de pedido/negociação são expostos completamente, ou há cliente com política de mascaramento?
    - CPF/CNPJ é exposto ou mascarado nos dados cadastrais?
    - Há dados que devem ser redacted mesmo com permissão?

14. **Auditoria e conformidade:**
    - As consultas feitas pelo agente geram log para LGPD/conformidade?
    - Há critérios de retenção de dados no histórico de resumos?

### Performance e escala

15. **Volume esperado e performance:**
    - Qual é o volume típico de registros por cliente? (100 contatos? 1.000 negociações abertas?)
    - Há SLA de tempo de resposta? (5 segundos? 30 segundos?)

---

## Premissas a validar

Essas suposições estão **pendentes de confirmação** antes que o arquiteto desenhe a solução:

| # | Premissa | Status | Validação esperada |
|---|----------|--------|-------------------|
| P1 | A org usa Agentforce (Skills/Einstein Copilot) e está conectada na sandbox `sbx-eplast-dev` | ❓ PENDENTE | Confirmar via `sf org list` e setup da org |
| P2 | Os objetos principais são Account, Contact, Opportunity, Order/Quote e Case | ❓ PENDENTE | Validar schema da org (assessment.md ou `sf sobject describe`) |
| P3 | "Negociações recentes" abrange os últimos 90 dias | ❓ PENDENTE | Alinhar com padrão operacional do cliente |
| P4 | "Síntese de atenção" refere-se apenas a negociações com Expected Close Date ≤ 7 dias e casos Priority='High' abertos | ❓ PENDENTE | Definir com stakeholder comercial/atendimento |
| P5 | O agente respeita apenas o Force.com security model standard (Field-Level Security + Object-Level Security), sem regras custom adicionais | ❓ PENDENTE | Confirmar se há Sharing Rules, Territory Management ou políticas de acesso custom |
| P6 | Nenhum mascaramento de dados é necessário (valores, CPF, email são expostos conforme permissão) | ❓ PENDENTE | Validar com compliance/setor de eplast |
| P7 | O agente mostra todos os registros de cada categoria, sem limite de top N | ❓ PENDENTE | Definir estratégia se categoria tiver volume alto |
| P8 | "Referências aos registros" = nomes/IDs dos records que o usuário pode clicar para abrir (não é necessário gerar URLs) | ❓ PENDENTE | Validar capacidade do Agentforce de renderizar links |

---

## Ambiguidades que mudam a arquitetura (perguntas bloqueantes)

**PARAR AQUI.** As seguintes perguntas mudam fundamentalmente como a solução será desenhada. Não é possível escolher por conta — arquitecto precisará responder:

### Arquitetura do Agentforce

**A1. Tipo de implementação do agente:**

- **Opção A:** Custom Action + Flow que chama Apex (determinístico, sem IA generativa extra — apenas orquestra dados)
- **Opção B:** Einstein Copilot com prompt + Action (IA interpreta intenção, chama action, sintetiza resposta)
- **Opção C:** Agentforce Skills (nova IA nativa do Salesforce, acesso direto a metadados)

A escolha muda:
- Quanto de lógica fica em Apex vs. prompt do agente
- Como o agente acessa dados (Apex classes vs. API LLM-driven)
- Capacidade de síntese semântica ("pontos de atenção")

**Resposta esperada:** qual tipo está aprovado pela eplast?

---

### Escopo dos dados

**A2. Categorias opcionais:**

A demanda lista 6 categorias. Há alguma que o cliente quer desabilitar ou adicionar?

**Exemplos:**
- Incluir histórico de interações (Activity, Task, Event)?
- Incluir contatos de stakeholder (diferente de Contact — ex.: Influencer role)?
- Excluir negociações perdidas?
- Incluir documentos anexados (ContentDocument)?

**Resposta esperada:** lista definitiva de categorias e quais campos cada uma retorna.

---

### Performance e renderização

**A3. Limite de registros por categoria:**

Se um cliente tem 200 contatos ativos, o agente mostra todos em um resumo? Isso está viável na renderização Agentforce?

**Opções:**
- Mostrar todos (risco: resposta muito longa, truncamento)
- Top N por categoria (ex.: 10 contatos mais recentes, 5 negociações top value)
- Agregação com contagem (ex.: "89 contatos, mostrando 10 principais")

**Resposta esperada:** estratégia de renderização.

---

### Respeito a permissões

**A4. Nivel de segregação de dados:**

O "respeito a permissões" é apenas OLS/FLS padrão do Salesforce, ou há critérios adicionais?

**Exemplos:**
- Sharing Rules ou Territory Management (vendedor vê só seus clientes)?
- Política custom: vendedor não vê oportunidades perdidas?
- Política custom: conta inativa não mostra no resumo?

**Resposta esperada:** qual é a política de acesso na org? (Assessment pode responder isso.)

---

### Síntese inteligente

**A5. Como a "síntese de atenção" é calculada:**

A demanda menciona:
> "principais pontos de atenção identificados nos registros, como negociações próximas do fechamento ou ocorrências pendentes"

Isso é:
- Apenas regras explícitas (Expected Close Date ≤ 7 dias = atenção), ou
- Análise semântica pelo agente IA (ex.: agente detecta falta de movimento há 60 dias, padrão incomum, etc.)?

Se for análise semântica, o agente precisa de contexto histórico (movimentação anterior)?

**Resposta esperada:** critérios exatos de "atenção" + se há análise semântica ou apenas regras.

---

## Estimativa de complexidade

**MÉDIO (M)**

**Justificativa:** integração com Agentforce (aprendizado de plataforma) + orquestração de 5+ entidades (Account, Contact, Opportunity, Order, Case) + respeito a permissões + sem mutations, mas não requer business logic complexa, regras condicionais ou integrações externas.

---

## Resumo do que vai à mesa

| Artefato | Observação |
|----------|-----------|
| **Objetivo** | Consolidar informações de cliente sob demanda via Agentforce, sem criar/alterar dados |
| **Escopo** | 6 categorias (visão geral, contatos, negociações, pedidos, ocorrências, síntese) |
| **Restrições** | Read-only, respeita permissões, sem invenção de dados |
| **Gaps** | 15 perguntas de especificação (dados, volume, renderização) |
| **Bloqueadores** | 5 ambiguidades arquiteturais (A1–A5) que precisam resposta antes do design |
| **Premissas** | 8 premissas pendentes de validação (P1–P8) |
| **Complexidade** | Médio (M) — múltiplas entidades + permissões, sem business logic complexa |

---

## Próximos passos (gate ba-discovery)

1. **Você (humano) responde as 5 perguntas bloqueantes (A1–A5)** — principalmente:
   - Que tipo de Agentforce será usado?
   - Quais campos exatos em cada categoria?
   - Como renderizar se houver volume grande?
   - Qual é a política de acesso (segregação)?
   - Critérios de atenção (regras ou análise semântica)?

2. **Valida as 8 premissas** — lê assessment.md (ou pede assessment se não existir) para confirmar schema, versão do Salesforce, políticas de acesso.

3. **Define as 15 lacunas de especificação** — consolida em um documento para o arquiteto.

Depois dessa validação, a análise segue para o arquiteto escolher declarativo vs. código.

**Análise pronta. Preciso da sua validação antes de acionar o arquiteto.**
