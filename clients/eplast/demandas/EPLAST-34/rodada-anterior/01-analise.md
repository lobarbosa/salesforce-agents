# EPLAST-34 — Resumos automáticos para reuniões comerciais, GDD, S&OP e Board

**Cliente:** Eplast · **Tipo:** projeto · **Onda:** 3 (Comercial), não contratada no projeto atual (Ondas 1–2)
**Origem:** Solicitação de Proposta Konecta — Implantação de IA no Salesforce Sales e Marketing
**Status:** análise para validação humana. **Não pronta para design.** Há perguntas que mudam a arquitetura (seção 5); enquanto não forem respondidas, os critérios da seção 4 são rascunho.

Fontes usadas: `demandas/EPLAST-34/demanda.md` (história do consultor, três linhas), `assessment.md` (onboarding, 2026-09-30), `contrato.md` (materializado pelo Squad OS, Status Report semana 05), e o RAG de delivery (análises anteriores do mesmo cliente citadas abaixo). O documento de origem (Solicitação de Proposta) não está no workspace.

---

## 1. Contexto de negócio

Segundo a demanda, a Eplast quer gerar automaticamente resumos para quatro tipos de reunião — comercial, GDD, S&OP e Board — a partir dos dados do CRM. O item pertence à Onda 3 (Comercial) do roteiro de seis ondas. Pelo `contrato.md`, as Ondas 3, 4 e 5 ainda não foram contratadas; o projeto atual cobre Ondas 1 e 2 (120 h, fim previsto em 2026-11-30).

Três entregáveis contratados ou em andamento tocam o mesmo território e precisam ser comparados com esta demanda antes de qualquer design:

- `eplast-ent-10` — "Qual o resumo completo de determinado cliente?" (contatos, negociações, pedidos e ocorrências), peso 3, Onda 2, em construção fora da esteira. É um resumo de CRM por cliente, com geração assistida.
- `eplast-ent-08` — Consulta rápida ao CRM via assistente de IA, concluído.
- `eplast-ent-09` — Agente "Quais clientes precisam de acompanhamento hoje?", peso 2, em homologação.

Demandas anteriores do mesmo cliente tratam de painéis e recortes comerciais sobre os mesmos objetos (`[demandas/EPLAST-32/01-analise.md]` — painel meta × carteira × faturamento × pedidos; `[demandas/EPLAST-26/01-analise.md]` — scoring de leads e oportunidades). Já houve alerta de sobreposição com o entregável contratado nesta mesma linha (`[demandas/EPLAST-33/01-analise.md]`): dois artefatos com regras diferentes para o mesmo conceito geram retrabalho e divergência de números em reunião.

O assessment da org está em **vermelho** (`assessment.md`). Os riscos que tocam esta demanda estão na seção 7.

## 2. Objetivo (provisório)

Reduzir o trabalho manual de preparação das reuniões comerciais, de GDD, de S&OP e de Board, entregando a cada uma um resumo gerado a partir do CRM.

Este objetivo é deliberadamente genérico. Quem consome cada resumo, com que frequência, em que formato e com quais números não está definido (seção 5). Não será usado para dimensionar nada até essas respostas existirem.

## 3. Regra de negócio

**Não definida pela demanda.** O que se sabe:

- A fonte declarada é "os dados do CRM" (sem objeto, campo ou relatório).
- Há quatro tipos de reunião, sem indicação de que compartilham conteúdo.

Qualquer regra de cálculo, recorte, período ou hierarquia de visibilidade fica pendente de resposta. Não será inferida.

## 4. Critérios de aceite (rascunho — não aceitar até a seção 5 ser respondida)

Os critérios abaixo são testáveis e valem independentemente da resposta (bloco A). Os do bloco B dependem de definições pendentes e são só esqueleto.

### Bloco A — independentes da resposta

```gherkin
Funcionalidade: Resumo para reunião não expõe dado que o usuário não vê no CRM

  Cenário: usuário sem acesso a uma Oportunidade não a vê no resumo
    Dado um usuário do perfil "Comercial - Analista" sem acesso à Oportunidade "X" (conta de teste sintética)
    Quando ele gera o resumo do tipo "comercial" para o período de teste
    Então o texto do resumo não contém o nome, o valor nem a etapa da Oportunidade "X"

  Cenário: resumo informa a data de corte e a origem dos números
    Dado um resumo gerado em uma data de referência D
    Então o resumo exibe a data D e o nome da fonte de cada número apresentado

  Cenário: nenhum dado real de cliente é usado no desenvolvimento e nos testes
    Dado a sandbox de dev (sem registros de negócio, conforme assessment)
    Quando a equipe valida o resumo
    Então todos os registros usados são sintéticos e identificados como tal

  Cenário: falha na geração não grava nada no CRM e não quebra o processo de quem pediu
    Dado uma falha simulada na geração do resumo
    Quando o usuário solicita o resumo
    Então o usuário vê uma mensagem de erro
    E nenhum registro novo ou campo alterado é criado nos objetos Account, Opportunity ou Order
```

### Bloco B — esqueleto, depende da seção 5

```gherkin
  Cenário: números do resumo conferem com o relatório de referência (valor a definir)
    Dado um conjunto sintético de N Oportunidades com soma S, conforme a regra definida em [pergunta 7]
    Quando o resumo do tipo "<tipo>" é gerado
    Então os valores numéricos citados no resumo são iguais aos do relatório de referência indicado em [pergunta 7]
    # Observação: se o texto for gerado por modelo de linguagem, a comparação é campo a campo
    # (checklist de valores), nunca por igualdade de string.

  Cenário: cada tipo de reunião recebe o conteúdo e o público definidos para ele
    Dado a definição do público e do conteúdo de "<tipo>" (pergunta 5)
    Quando o resumo do tipo "<tipo>" é gerado para um usuário desse público
    Então o resumo contém exatamente as seções definidas para "<tipo>"

  Cenário: gatilho e formato de entrega
    Dado o gatilho e o formato definidos (perguntas 4 e 6)
    Quando o gatilho ocorre
    Então o resumo é entregue no formato e no canal definidos
```

## 5. O que a demanda NÃO diz (precisa ser respondido antes do design)

Ordenado pelo quanto cada pergunta muda o trabalho. As marcadas **[bloqueante]** impedem o arquiteto de desenhar qualquer coisa.

### A. Escopo e contrato

1. **[bloqueante] Escopo comercial.** A Onda 3 não está contratada (`contrato.md`). A demanda entra no escopo com aditivo, fica como backlog para contratação futura, ou é descartada? Decisão comercial, não técnica; esta análise não decide.
2. **[bloqueante] Sobreposição com `eplast-ent-10` e `eplast-ent-08`.** Resumo completo de cliente já é um entregável contratado (peso 3). Esta demanda é: (a) extensão dele para os outros três públicos, (b) entregável separado com regra própria, ou (c) já coberta? Sem essa resposta há risco de cobrar o mesmo trabalho duas vezes ou de manter dois resumos de cliente com regras diferentes. Cruza com `[demandas/EPLAST-33/01-analise.md]`, que já levantou o mesmo problema para outro item.
3. **Sobreposição com demandas da esteira de análise.** EPLAST-26 (scoring), EPLAST-32 (painel meta × carteira) e EPLAST-33 usam os mesmos conceitos (carteira, pedidos, oportunidade parada). Os números de um resumo de S&OP ou de Board precisam bater com esses painéis? Se sim, qual é a fonte única?

### B. Natureza da entrega (muda arquitetura)

4. **[bloqueante] Geração por modelo de linguagem ou agregação determinística?** "Resumo" pode ser (a) texto gerado por IA generativa (Agentforce, prompt template ou provedor externo), (b) relatório ou painel com totais e listas, sem texto livre, ou (c) combinação. Cada opção tem custo, risco de número errado e exigência de LGPD diferentes. A licença e o consumo de créditos de IA foram avaliados no entregável `eplast-ent-04`, mas o resultado não está no workspace (ver pergunta 13).
5. **[bloqueante] Formato e canal de saída.** Documento (PDF, Word), e-mail, slide, tela no Lightning, campo em objeto, Chatter ou outro? **Se a saída for gravada em registro do CRM** (campo ou objeto em Account, Opportunity ou Order), o risco de automação concorrente do assessment (achado 1) passa a ser bloqueante — ver seção 7.
6. **[bloqueante] Público e conteúdo de cada tipo.** Quem recebe comercial, GDD, S&OP e Board? O conteúdo é o mesmo, com recortes diferentes, ou são quatro resumos distintos? O Board vê consolidado de todas as equipes? Quem vê o quê segue a hierarquia de perfis e de compartilhamento atual (OWD não foi medido no assessment).
7. **[bloqueante] Definição das fontes e das métricas.** Quais objetos e campos entram em cada resumo? Os conceitos de meta, carteira, faturamento e pedido imputado não estão definidos (ver `[demandas/EPLAST-32/01-analise.md]`). A demanda cita "reuniões de GDD" e "S&OP" sem explicar essas siglas: o cliente precisa dizer o que cada reunião consome. Para resumos de carteira e de pedidos, a fonte é o Salesforce ou o Protheus via integração? Pedido vindo do Protheus já tem risco de qualidade de dados (`contrato.md`, `eplast-ent-11`).
8. **Gatilho e periodicidade.** Sob demanda (botão), agendado (ex.: véspera de cada reunião), ou por evento? Qual a periodicidade de cada reunião?
9. **Janela de dados.** Período coberto (mês corrente, trimestre, acumulado)? Dado de até que hora?

### C. Dado pessoal, dados e licenças

10. **[bloqueante] LGPD e envio a terceiros.** Se houver texto gerado por IA, o conteúdo sai da Salesforce para um provedor de modelo? Resumos de cliente com contatos (como em `eplast-ent-10`) incluem dado pessoal. O cliente precisa definir se contatos entram no resumo e quem valida isso (jurídico ou DPO da Eplast).
11. **Aprovação do conteúdo.** O resumo é enviado direto ou passa por revisão humana antes de circular? Quem responde por número errado em Board?
12. **Idioma, tamanho e modelo.** Há template padrão da Eplast para cada reunião? Quantas páginas ou quantas linhas?
13. **Licenças e créditos.** Quem paga o consumo de créditos ou licenças de IA? O resultado do `eplast-ent-04` não está no workspace. O assessment mediu licença Salesforce só na sandbox (14 de 14 usadas), não em produção.

### D. Infra e processo

14. **Dados de teste.** A sandbox de dev está vazia (0 Account, Contact e Opportunity). Proposta: dados sintéticos criados em dev, sem dado real da Eplast na sessão (guardrail #2). O consultor aceita essa forma de validação para um texto que depende de volume real?
15. **Documento de origem.** A Solicitação de Proposta Konecta pode ser anexada ao card, com liberação de dado pessoal, para conferir o escopo deste item?
16. **Onde o build acontece.** O alias `sbx-eplast-dev` aponta para uma sandbox cujo usuário e instância se identificam como "qa" (assessment, achado 6). Até confirmar a separação, não se sabe se um resumo validado em dev é o mesmo ambiente do roteiro de QA.

## 6. Premissas a validar

Todas **PENDENTES**. Nenhuma foi confirmada.

- **P1 (pendente)** — A solução é somente leitura nos objetos Account, Opportunity e Order. Se não for, o achado 1 do assessment vira bloqueante.
- **P2 (pendente)** — Se houver Apex novo, cada classe tem classe de teste `<Classe>Test` e cobertura ≥ 85%, padrão do squad.
- **P3 (pendente)** — Nenhum resumo depende de campo sem descrição sem antes passar por confirmação de uso com o negócio (68,6% dos campos de Account, Order e Opportunity não têm descrição).
- **P4 (pendente)** — Validação usa dados sintéticos em dev; nenhum dado real de cliente entra no contexto da sessão.
- **P5 (pendente)** — Os quatro tipos de resumo são uma demanda só, não quatro.
- **P6 (pendente)** — Nenhuma geração de texto por IA é contratada além do que já está licenciado para o projeto.
- **P7 (pendente)** — Esta demanda não é executada na esteira enquanto a pergunta 1 (escopo comercial) estiver em aberto.

## 7. Riscos do assessment que tocam esta demanda

Só os que se aplicam ao pedido. Os demais (achados 5, 7, 8, 9, 10) não tocam esta demanda.

- **Achado 1 — automação concorrente em Account, Opportunity e Order (alta).** Relevância **condicional à pergunta 5**. Leitura não dispara trigger nem Flow. Se o resumo for gravado em qualquer um desses objetos, o evento passa por `AccountTrigger`, `OpportunityTrigger`, `OrderTrigger` (custom e do CPQ) e pelos Flows `RecordAfterSave`/`RecordBeforeSave` listados no assessment. Para Account há ainda a integração com o Protheus (`SendAccountToProtheus`); se ela dispara em qualquer alteração de Account, gravar ali afeta o ERP. Se a saída for gravada, a ordem de execução precisa ser mapeada antes do design. Não é confirmado se a integração dispara nesse caso.
- **Achado 2 — cobertura de teste Apex em 10% (alta).** Relevância **condicional a Apex novo**. Sem Apex (solução só de relatório ou de prompt template), não se aplica diretamente. Com Apex, a classe nova precisa de teste próprio ≥ 85%, e a cadeia Protheus não tem nenhuma rede de teste. Para o release em produção, a org inteira precisa de 75%, o que é fora do escopo desta demanda mas bloqueia qualquer deploy futuro.
- **Achado 3 — validation rules de Order (média).** Baixa relevância: leitura não dispara validation rule. Só entra se a saída for gravada em Order.
- **Achado 4 — campos custom sem descrição (média).** **Relevante.** O resumo depende de escolher o campo certo. Com 153 de 223 campos sem descrição, a escolha vai depender de confirmação com o negócio (ver pergunta 7 e P3).
- **Achado 6 — alias de dev apontado para sandbox "qa" (média).** **Relevante.** Validação de resumo em ambiente que pode ser o mesmo do roteiro de QA. Confirmar antes do build (pergunta 16).
- **Não medido no assessment — OWD e regras de compartilhamento.** **Relevante** para o critério "não expõe dado que o usuário não vê". Não dá para assumir a visibilidade atual; ela precisa ser conferida com `sf` antes de qualquer desenho que dependa dela (guardrail #3).
- **Dados de negócio não lidos.** A sandbox de dev está vazia. Nenhum volume de produção foi inferido, e nenhum resumo pode ser validado com volume real em dev.

## 8. Complexidade

**M (provisório, pode ir a P ou G).** Quatro públicos, pelo menos três fontes (Opportunity, Account, Order/Protheus), natureza da saída e gatilho indefinidos. Vira **P** se for relatório ou prompt template sobre campos já existentes e sem gravação. Vira **G** se exigir Apex novo, geração por modelo externo, agendamento e cobertura de 85% com a cadeia Protheus de fora.

## 9. Estimativa de esforço humano

**Estimativa de esforço:** 24–120 h

Premissas que mais pesam na faixa:
- **Natureza da saída (pergunta 4 e 5):** relatório ou prompt template sobre campos existentes fica perto de 24–40 h; geração por modelo externo com Apex, testes e agendamento fica perto de 80–120 h. É o que mais pesa.
- **Número de tipos e conteúdo único ou não (pergunta 6):** quatro conteúdos distintos somam horas de configuração e de validação com cada público; conteúdo único com recortes reduz.
- **Mapeamento de fontes e curadoria de campos (pergunta 7 e achado 4):** inclui sessões de confirmação com o negócio, que não são só execução técnica.
- **Homologação com quatro públicos e cross-check de números:** pesa mais se houver Board e S&OP com números conciliados com painéis já existentes (pergunta 3).
- **Sobreposição com `eplast-ent-10` (pergunta 2):** se for extensão desse entregável, a faixa cai; se for paralela, sobe.

Faixa larga porque a demanda é uma linha. Não inclui horas de agente nem o tempo de espera por decisão comercial. O arquiteto refina no design.

## 10. Próximo passo recomendado

Não acionar o arquiteto ainda. Reunião curta com o consultor e o contato comercial da Eplast para responder as perguntas **1, 2, 4, 5, 6, 7, 10** (as marcadas bloqueantes). As demais podem ser respondidas no design. Se a pergunta 1 der "não contratado", a demanda fica no backlog e esta análise é só registro.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
