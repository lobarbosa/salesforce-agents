# EPLAST-35 — Análise: fluxos de aprovação, distribuição de leads e encaminhamento

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 · Comercial (ainda não contratada; Ondas 1–2 em andamento)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing (Eplast)
**Org confirmada:** alias `sbx-eplast-dev`, tipo Sandbox, conectada via `sf org list` nesta sessão. A instância se identifica como `qa` no nome (ver seção 3, risco de confusão dev/qa — assessment, achado 6).
**Status:** esta análise NÃO fecha o escopo. Há decisões de arquitetura pendentes (seção 4) que precisam de resposta do consultor/cliente antes do design.

---

## 1. Contexto de negócio

A proposta cita três processos, em uma só linha de item:

1. **Fluxos de aprovação** — descontos, condições comerciais ou liberações que hoje exigem passar por alguém.
2. **Distribuição de leads** — atribuir Leads a vendedores ou filas de forma automática.
3. **Encaminhamento de demandas** — o texto não define o que é "demanda" nesse contexto comercial (ver dúvida D6).

A demanda chega como item de escopo de proposta, sem história de usuário, sem personas, sem regra de negócio e sem critério de aceite. Por isso esta análise separa o que é fato confirmado na org do que é hipótese a validar.

## 2. O que a org já tem (confirmado via `sf` nesta sessão)

Essas confirmações mudam o desenho: parte do que a demanda pede pode já existir.

| Item | Situação confirmada | Como foi confirmado |
|---|---|---|
| Processos de aprovação | **3 ativos**: `Quote.AssignPricing` ("Atribuir ao Pricing", CPQ/Quote), `Opportunity.FinancialAnalysis` ("Análise financeira"), `Order.LiberationFinancial` ("Liberação Financeiro") | `sf org list metadata --metadata-type ApprovalProcess` e `SELECT ... FROM ProcessDefinition` |
| Último ajuste em aprovação | `Quote.AssignPricing` modificado em 2026-08-31; os outros dois em 2024-09 e 2025-01 | mesma consulta |
| Regra de atribuição de Lead | Existe `AssignmentRules` para Lead e Case, criados pelo usuário de integração "Konecta2" com data 1970-01-01 (indício de metadado importado, não de configuração manual) | `sf org list metadata --metadata-type AssignmentRules` |
| Filas (Queue) | Consulta `Group WHERE Type='Queue'` retornou 0. **Não confirmado** — pode ser restrição de acesso do usuário técnico; revalidar | `sf data query` |
| Leads na sandbox | `COUNT()` retornou 0. Esperado: sandbox sem dados de negócio (assessment) | `sf data query` (agregado, sem dado pessoal) |
| Flows custom | Assessment (2026-09-30): 25 Flows custom, 23 ativos. **Não reconfirmado hoje**: `FlowDefinitionView` não é consultável por `sf data query` nesta versão | assessment.md |
| Regra de negócio de desconto/aprovação | **Não encontrada na org nem no RAG** (`rag_consultar` sem resultado para o cliente) | — |

**Consequência direta:** antes de propor qualquer aprovação nova, precisamos decidir se ela substitui, complementa ou duplica o `Quote.AssignPricing`, o `Opportunity.FinancialAnalysis` e o `Order.LiberationFinancial`. Criar um quarto processo de aprovação sobre Opportunity ou Quote sem essa decisão é o cenário que o assessment (achado 1) descreve como risco alto.

## 3. Riscos do assessment que tocam este pedido

Assessment de 2026-09-30, saúde geral **vermelho**. Os itens abaixo tocam diretamente EPLAST-35:

- **[alta] Automação concorrente em Opportunity, Quote/Order (CPQ) e Account.** Hoje Opportunity tem trigger custom `OpportunityTrigger` + triggers do CPQ + dois Flows `RecordAfterSave` no mesmo evento. Order tem trigger custom, trigger SBQQ e Flows before/after. **Qualquer fluxo de aprovação ou de atribuição de Lead que toque esses objetos corre risco de recursão, race condition ou quebra do CPQ.** Recomendação do assessment: mapear a ordem de execução antes da próxima demanda nesses objetos. Este é pré-requisito, não opcional.
- **[alta] Cobertura de teste Apex em 10%.** A integração com o ERP Protheus (que move Account e Order) não tem teste identificável. Qualquer Apex novo desta demanda precisa de `<Classe>Test` com cobertura mínima de 85% por classe (padrão do squad). Não é possível fazer deploy de produção com a cobertura atual; o gate de 75% da Salesforce já não é atingido.
- **[média] Confirmação de dev vs qa.** O alias `sbx-eplast-dev` aponta para uma sandbox cujo usuário e instância se identificam como `qa`. Isso importa para esta demanda: se os testes de aprovação e de atribuição de Lead rodarem na mesma sandbox que a homologação, os dados e as configurações competem. **Premissa bloqueante para a etapa de QA**, até o cliente/BASIS confirmar as duas sandboxes.
- **[média] 68% dos campos custom de Account, Order e Opportunity sem descrição.** Qualquer campo novo desta demanda (ex.: status de aprovação, responsável da fila) sai com `Description` preenchida.
- **[baixa] Perfis.** Há quatro variações do perfil comercial (`Comercial`, `Comercial - Analista`, `Comercial - Analistas`, `Comercial Padrão`). Atribuir aprovadores e filas por perfil fica frágil até essa consolidação. Preferir permission set.

## 4. Objetivo

Reduzir o tempo e o risco de três processos comerciais manuais: aprovação de exceções, atribuição de Leads e encaminhamento de solicitações internas. **O objetivo exato depende das decisões da seção 6.** Não é possível escrever um objetivo mensurável sem saber o que é "aprovar" e "encaminhar".

## 5. Regras de negócio

**Nenhuma regra de negócio está definida pela demanda.** O que existe é a intenção:

- Aprovação deve ocorrer antes de algo ser liberado — o texto não diz o quê.
- Leads devem ser distribuídos automaticamente — o texto não diz por quê critério.
- Demandas devem ser encaminhadas — o texto não diz a quem nem de quê.

Qualquer regra abaixo marcada como **[pendente]** é hipótese, não requisito.

- **RN-1 [pendente]:** a aprovação é disparada por um critério mensurável (ex.: desconto acima de X%, valor total acima de Y, margem abaixo de Z). Sem critério, não há regra.
- **RN-2 [pendente]:** o aprovador é determinado por uma regra (cargo, alçada, território, fila). Sem isso, não há destinatário.
- **RN-3 [pendente]:** a distribuição de Lead segue um critério (round robin, território/região, produto, capacidade, score). Sem isso, não há algoritmo.
- **RN-4 [pendente]:** a aprovação tem prazo de resposta e tratamento de vencimento (escalar, rejeitar automaticamente, manter pendente).
- **RN-5 [pendente]:** a decisão de aprovação fica registrada (quem, quando, justificativa) e é auditável.

## 6. Dúvidas que precisam de resposta antes do design

Estas dúvidas mudam a arquitetura. Não escolho por conta própria (regra do squad).

**Bloqueantes para o design:**

- **D1 — Qual objeto recebe a aprovação?** Opportunity, Quote (CPQ), Order, ou outro? Já existem três processos ativos (seção 2). A nova aprovação substitui algum deles, complementa ou é independente? Resposta muda se usamos o motor de aprovação nativo, Flow de aprovação ou Apex.
- **D2 — Qual motor de aprovação?** Approval Process nativo (já usado nas três aprovações existentes), Flow com aprovação, ou Apex. Recomendação inicial a validar: manter o motor nativo para ser coerente com o que já existe, mas isso só se D1 for complemento.
- **D3 — Qual é o critério de disparo da aprovação?** Ver RN-1. Com valor, percentual, margem ou tipo de produto? Quais campos e de qual objeto?
- **D4 — Qual é a régua de distribuição de Leads?** Round robin, território, região, produto, score ou capacidade? Existe lista de vendedores e territórios hoje? A `AssignmentRules` de Lead já existe na org (seção 2) — vamos reutilizar, substituir ou criar nova?
- **D5 — Existe Flow ou automação de Lead hoje?** A org não tem dado de Lead na sandbox, então não é possível inspecionar o comportamento real. Precisamos de descrição do processo atual em produção (feita pelo cliente, sem dado pessoal).
- **D6 — O que significa "encaminhamento de demandas" no contexto comercial?** Pode ser: (a) encaminhar Lead/Opportunity entre vendedores, (b) encaminhar pedido de cliente para área interna (ex.: pricing, logística, financeiro), (c) encaminhar via Case, (d) outra coisa. Cada resposta muda o objeto e a fila.
- **D7 — Os aprovadores e as filas de encaminhamento são usuários, grupos (Queue) ou perfis?** Dado o achado de perfis (seção 3), pedimos a lista de quem aprova e quem recebe.

**Importantes, não bloqueiam o desenho mas bloqueiam o aceite:**

- **D8 — Quais são os SLAs?** Tempo máximo de aprovação e de primeiro contato com Lead.
- **D9 — Haverá integração com o ERP Protheus** para liberação de pedido ou de crédito após aprovação? Se sim, a cadeia Account/Order → Protheus entra no escopo e o teste precisa cobri-la (assessment, achado 2).
- **D10 — A sandbox de QA (`sbx-eplast-qa`) existe como distinta?** Ver assessment, achado 6. Sem essa resposta, o roteiro de homologação não pode ser executado com segurança.
- **D11 — Quem homologa?** Nome e papel do homologador do cliente, e como ele quer ser acionado (campo `Contatos principais` do `CLAUDE.md` do cliente está vazio).
- **D12 — Os dados de Lead e de cliente que serão usados em teste** são sintéticos? Precisamos confirmar que não serão dados reais de cliente (guardrail #2).

## 7. Critérios de aceite

Os critérios abaixo são testáveis **quando** as dúvidas bloqueantes forem respondidas. Onde a resposta ainda falta, o critério está marcado com a dúvida que o destrava. Nenhum é aceito como final antes disso.

**Aprovação**

```gherkin
Funcionalidade: Aprovação de condição comercial acima da alçada

  Cenario: Solicitação dentro da alçada não gera aprovação
    Dado que a condição comercial está dentro do critério de alçada definido em RN-1 [depende de D3]
    Quando o vendedor salva a condição
    Então nenhum registro de aprovação é criado
    E a condição segue sem bloqueio

  Cenario: Solicitação acima da alçada entra em aprovação com o aprovador correto
    Dado que a condição comercial ultrapassa o critério de RN-1 [depende de D3]
    Quando o vendedor submete a condição para aprovação
    Então um único registro de aprovação é criado no objeto definido em D1
    E o aprovador é o definido por RN-2 [depende de D7]
    E o status fica "Pendente de aprovação"

  Cenario: Aprovação registra quem decidiu, quando e a justificativa
    Dado uma aprovação pendente
    Quando o aprovador aprova ou rejeita com justificativa
    Então o registro guarda o usuário, a data e a justificativa (RN-5)
    E o vendedor recebe notificação da decisão

  Cenario: Aprovação vencida segue a regra de tratamento de prazo
    Dado uma aprovação pendente que ultrapassou o prazo de RN-4 [depende de D8]
    Quando o prazo vence
    Então a aprovação é escalada, rejeitada ou mantida conforme RN-4

  Cenario: Nova aprovação não duplica as três aprovações já existentes
    Dado que a condição já está em um dos processos ativos (Quote.AssignPricing, Opportunity.FinancialAnalysis ou Order.LiberationFinancial)
    Quando o vendedor submete para aprovação
    Então não há segunda aprovação em paralelo para o mesmo registro
    [A regra de precedência depende de D1]
```

**Distribuição de Leads**

```gherkin
Funcionalidade: Distribuição automática de Lead

  Cenario: Lead novo recebe responsável pela régua definida
    Dado que a régua de distribuição (RN-3 [depende de D4]) está ativa
    Quando um Lead é criado com os campos necessários para o critério
    Então o campo Owner recebe o responsável definido pela régua
    E a atribuição fica registrada

  Cenario: Lead sem critério para atribuição cai na fila de fallback
    Dado um Lead que não atende nenhum critério da régua
    Quando é salvo
    Então ele é atribuído à fila de fallback [fila a definir, depende de D7]
    E não fica sem responsável

  Cenario: Atribuição não dispara recursão nem altera Opportunity ou Account
    Dado a automação de Lead ativa
    Quando um Lead é convertido ou atribuído
    Então nenhum trigger ou Flow de Account/Opportunity/Order é disparado além do esperado
    [Depende do mapeamento de ordem de execução, pré-requisito do assessment, achado 1]
```

**Encaminhamento de demandas**

```gherkin
Funcionalidade: Encaminhamento de demandas

  Cenario: Demanda é encaminhada para o destino definido
    Dado que a demanda do tipo [a definir, D6] foi registrada
    Quando é salva com o motivo de encaminhamento
    Então ela aparece para o grupo ou usuário destino definido em D7
    E a origem do encaminhamento fica registrada

  Cenario: Demanda encaminhada não some sem dono
    Dado uma demanda encaminhada
    Quando o destinatário não a aceita ou não a trata dentro de D8
    Então ela é escalada conforme regra a definir [depende de D8]
```

**Qualidade transversal (aplica-se a qualquer escopo)**

```gherkin
Funcionalidade: Qualidade de entrega

  Cenario: Apex novo tem teste dedicado com cobertura mínima
    Dado uma classe Apex nova ou alterada desta demanda
    Quando o pipeline de validação roda
    Então existe classe <Classe>Test
    E a cobertura da classe é de pelo menos 85%

  Cenario: Campos novos têm descrição
    Dado um campo custom criado por esta demanda
    Quando o metadado é revisado
    Então o campo tem Description preenchida

  Cenario: Nenhum dado real de cliente é usado em teste
    Dado o roteiro de QA
    Quando os registros de teste são criados
    Então são registros sintéticos, sem CPF, e-mail, telefone ou valor real de cliente
```

## 8. O que a demanda NÃO diz

Lista do que precisa ser respondido antes do design. Cada item corresponde a uma dúvida da seção 6.

1. Qual objeto recebe a aprovação (D1), e como ela convive com os três processos existentes.
2. Qual motor de aprovação usar (D2).
3. Qual critério dispara a aprovação, com valores e campos (D3, RN-1).
4. Quem é o aprovador e como é determinado (D7, RN-2).
5. Qual régua de distribuição de Lead (D4, RN-3) e o estado atual da régua na org.
6. O processo de Lead que existe hoje em produção (D5).
7. O que é "encaminhamento de demandas" e para quem (D6).
8. Prazos e SLAs (D8, RN-4).
9. Se há integração com o Protheus no fluxo de aprovação (D9).
10. Existência e identidade da sandbox de QA (D10).
11. Quem homologa e como é acionado (D11).
12. Origem dos dados de teste (D12).
13. Se o escopo é as três frentes ou apenas uma. A demanda não separa.
14. Se a consolidação da automação concorrente (assessment, achado 1) entra neste escopo ou é projeto separado.

## 9. Premissas a validar (todas pendentes)

- **P1 [pendente]:** o escopo cobre as três frentes (aprovação, Lead e encaminhamento). Se for só uma, o esforço cai bastante.
- **P2 [pendente]:** a aprovação usa o motor nativo, coerente com os três processos existentes. Não foi decidido.
- **P3 [pendente]:** nenhuma integração com Protheus entra na Onda 3. Se entrar, o esforço sobe e exige a cobertura de teste da cadeia ERP antes de tudo.
- **P4 [pendente]:** o pré-requisito de mapear a ordem de execução (assessment, achado 1) é feito como parte desta demanda, não como projeto separado. Se for separado, não está incluído na estimativa.
- **P5 [pendente]:** a cobertura de 85% por classe de Apex nova é exigida, e a cobertura de classes de Apex existentes tocadas por esta demanda é elevada junto.
- **P6 [pendente]:** a sandbox `sbx-eplast-dev` é a usada para build. A sandbox de QA não foi confirmada como distinta (D10).
- **P7 [pendente]:** as regras de atribuição de Lead existentes (`AssignmentRules`, criadas com data 1970-01-01) são reutilizáveis ou serão substituídas. Não foram inspecionadas em detalhe.
- **P8 [pendente]:** o `CLAUDE.md` do cliente tem o bloco de contatos e regras específicas em branco. Assumo que não há regra de horário de deploy ou aprovador obrigatório além do guardrail raiz; precisa de confirmação.

## 10. Complexidade

**L (grande), com possível quebra em três entregas.** Justificativa: três frentes com motores diferentes, em objetos (Opportunity, Quote/Order do CPQ e Lead) que o assessment marca como de automação concorrente e cobertura de teste baixa.

## 11. Estimativa de esforço

**Estimativa de esforço:** 120–260 h

Premissas que mais pesam na faixa:

- Escopo de uma demanda ampla e ainda não detalhada (as três frentes de uma vez). Se o cliente confirmar apenas aprovação, a faixa cai para algo perto de 40–80 h. Se apenas Lead, perto de 30–60 h.
- Inclui o mapeamento da ordem de execução em Opportunity/Order (assessment, achado 1) e a cobertura de teste das classes tocadas (85%). Se a consolidação da automação concorrente virar projeto separado, o número sobe e o desta demanda cai.
- Não inclui integração com Protheus (P3). Se incluir, somar 40–80 h adicionais para teste da cadeia.
- Inclui configuração, revisão, testes e homologação pelo consultor/dev. Não inclui o tempo do agente.
- Faixa larga é honesta: sem as respostas de D1–D7, não há como estreitar. O arquiteto refina no design.

## 12. Próximos passos

1. O consultor leva D1–D12 ao cliente e registra as respostas nos comentários do card (entram em `comentarios-do-card.md` na próxima execução).
2. Confirmação de sandbox dev/qa com o BASIS do cliente (D10, assessment achado 6).
3. Decisão de escopo: uma, duas ou três frentes (D6, P1).
4. Só depois disso o `arquiteto` desenha, e nesse momento precisa do mapeamento de ordem de execução de Opportunity e Order.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
