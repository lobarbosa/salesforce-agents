# Análise — EPLAST-27: Próxima melhor ação por cliente

## Contexto de negócio

A Eplast contratou a Konecta para a "Implantação de IA no Salesforce Sales e Marketing",
dividida em 6 ondas. Hoje só as Ondas 1 (Diagnóstico e desenho) e 2 (Projeto-piloto) estão
contratadas e em andamento (`contrato.md`). Esta demanda — "sugerir ao vendedor a próxima
melhor ação para cada cliente, com base no histórico e na situação comercial" — é um item
da **Onda 3 · Comercial**, que o próprio `contrato.md` lista como **ainda não contratada**.

A sandbox de dev (`sbx-eplast-dev`) roda Salesforce CPQ (SBQQ) e Marketing Cloud Connect
como pacotes geridos, e tem integração própria com o ERP Protheus para Account/Order
(classes `ProtheusAPI`, `SendAccountToProtheus`, `SendOrderToProtheus`, conforme
`assessment.md`). "Situação comercial" de um cliente nesta org plausivelmente deriva de
Opportunity, Order e/ou dados vindos do Protheus via essa integração — mas isso é
suposição a confirmar, não fato: não consultei a org via `sf` para esta análise (guardrail
#3 — ver "Premissas a validar" abaixo).

## Objetivo

Dado um cliente (Account), sugerir ao vendedor qual é a próxima melhor ação a tomar com
ele, a partir do histórico e da situação comercial desse cliente.

## Regra de negócio

**Não especificada pela demanda.** O texto registrado em `demanda.md` é uma única frase
("sugerir ao vendedor a próxima melhor ação para cada cliente, com base no histórico e na
situação comercial") sem regra de decisão, sem lista de ações possíveis, sem fonte de dado
definida e sem canal de entrega. Não há regra de negócio para transcrever aqui — ela
precisa ser levantada com o cliente antes do design.

## Critérios de aceite (Gherkin)

Não é possível escrever critérios de aceite testáveis a partir do texto atual da demanda:
não há ação de usuário, tela, objeto ou resultado esperado definidos. Qualquer critério
escrito agora seria suposição disfarçada de critério — o que a regra deste agente proíbe
explicitamente. Os critérios abaixo são **esqueletos** que mostram a forma que a resposta
às perguntas de "Premissas a validar" vai preencher; nenhum deles é aceite real ainda.

```gherkin
# ESQUELETO — não testável até responder as perguntas abertas abaixo.
Funcionalidade: Próxima melhor ação por cliente

  Cenário: Vendedor consulta a próxima melhor ação sugerida para um cliente
    Dado que o vendedor está vendo o registro de <objeto a definir: Account?> de um cliente
    Quando <gatilho a definir: abre o registro? clica num botão? recebe notificação?>
    Então o sistema apresenta uma sugestão de próxima ação
    E a sugestão é baseada em <fontes a definir: Opportunity? Order? Protheus? atividades?>

  Cenário: Cliente sem histórico suficiente
    Dado um cliente recém-cadastrado, sem <dado-base a definir> suficiente
    Então <comportamento a definir: nenhuma sugestão? sugestão genérica? mensagem de dado insuficiente?>
```

## O que a demanda NÃO diz

1. **Está contratada?** `contrato.md` classifica a Onda 3 · Comercial — à qual este item
   pertence — como "ainda não contratada no projeto atual (Ondas 1–2)". Antes de qualquer
   desenho, é preciso confirmar com o consultor/gestor de conta se EPLAST-27 já tem
   aditivo/autorização comercial para entrar em esteira, ou se está sendo registrada em
   backlog como antecipação do escopo futuro.
2. **O que é "próxima melhor ação"?** Não há lista de ações candidatas (ligar, enviar
   proposta, oferecer desconto, agendar visita, renovar contrato, etc.) nem critério de
   priorização entre elas.
3. **O que é "histórico e situação comercial"?** Não diz quais objetos/fontes alimentam a
   sugestão: Opportunity (estágio, valor, data de fechamento)? Order (pedidos via
   integração Protheus)? Atividades (Task/Event)? Dados do CPQ (quotes)? Algum outro
   sistema fora do Salesforce?
4. **Onde a sugestão aparece?** Não diz canal: componente na página do registro (Lightning
   Record Page), campo calculado, relatório, notificação, e-mail, ou um agente de IA
   (Agentforce) — a conta já usa Agentforce no piloto da Onda 2, o que torna essa opção
   plausível, mas não confirmada aqui.
5. **É IA/modelo preditivo ou lógica de regras?** O título do projeto é "Implantação de IA",
   mas a demanda não diz se "próxima melhor ação" é um modelo de recomendação (que exigiria
   dados de treino, Data Cloud/Einstein, ou um LLM) ou uma árvore de regras determinística
   configurável em Flow. Isso muda a arquitetura inteira (declarativo vs. código vs.
   plataforma de IA) e é exatamente o tipo de ambiguidade que a regra deste agente manda
   não resolver por conta própria.
6. **Quem é o usuário final?** "Vendedor" é citado, mas não diz se é todo o time comercial,
   só um papel específico, ou se gestores também veem a sugestão agregada.
7. **Volume e frequência:** não diz se a sugestão é recalculada em tempo real, em batch
   diário/semanal, ou sob demanda ao abrir o registro.

## Premissas a validar

Nenhuma suposição foi usada para fechar os critérios de aceite acima — todas as lacunas
foram deixadas como pergunta aberta. As únicas afirmações factuais usadas nesta análise que
não vieram direto de `demanda.md` estão no assessment da org (`assessment.md`, 2026-09-30) e
no `contrato.md`; nenhuma delas foi confirmada de novo via `sf` CLI nesta sessão —
sinalizo como pendente de confirmação no momento do design, quando houver objeto/campo
concreto a verificar:

- [ ] **Contratual** — confirmar com o gestor de conta se a Onda 3 (Comercial) já está
  autorizada para esta demanda entrar em esteira de build, dado que `contrato.md` a lista
  como não contratada.
- [ ] **Fonte de dado** — confirmar com o cliente/PO quais objetos alimentam "histórico e
  situação comercial" (Opportunity? Order? Protheus? Atividades?).
- [ ] **Canal de entrega** — confirmar se a sugestão deve aparecer dentro do Salesforce
  (componente/Flow) ou via o assistente de IA (Agentforce) já em piloto na Onda 2.
  `demanda.md` da própria Onda 3 não indica preferência.
  que explica a "próxima melhor ação" ou se é regra configurável.

## Riscos do assessment que tocam esta demanda

`assessment.md` (saúde geral: **vermelho**) traz dois achados de severidade alta que tocam
diretamente esta demanda, caso a fonte de dado confirmada inclua Account, Opportunity ou
Order:

- **Achado 1 — Automação concorrente em Account/Opportunity/Order.** Os três objetos mais
  prováveis de alimentar "histórico e situação comercial" (Account, Opportunity, Order) já
  têm trigger custom + trigger do CPQ (SBQQ) + Flows disparando no mesmo evento, sem ordem
  de execução mapeada. Qualquer automação nova nesses objetos (ex.: um Flow ou trigger que
  calcule/grave a sugestão de ação) soma mais um ponto de entrada num evento já concorrido —
  o assessment recomenda mapear a ordem antes de qualquer demanda nova nesses três objetos,
  o que deveria acontecer no recon/design desta demanda antes de propor onde a automação
  entra.
- **Achado 2 — Cobertura de teste Apex em ~10%, sem rede de segurança na integração com o
  Protheus.** Se "situação comercial" incluir dados de Order que vêm do Protheus (a
  integração em si: `ProtheusAPI`, `SendOrderToProtheus`, `OrderAdapter` etc.), qualquer
  código novo que leia esses dados herda o risco de uma cadeia sem teste nenhum hoje. Se o
  design desta demanda exigir Apex novo tocando essa cadeia, o design precisa decidir
  explicitamente como lida com a falta de cobertura (testar a cadeia tocada como parte do
  escopo, não só o código novo) — não dá para assumir que a integração existente está
  coberta.

Achados de severidade média/baixa (Validation Rules de Order, campos sem descrição,
convenção de teste, alias dev/qa, perfis) não têm relação direta com o objetivo desta
demanda pelo que se sabe hoje; ficam fora do escopo desta análise a menos que o design
precise tocar em algum desses pontos especificamente.

## Estimativa de complexidade

**G** — mesmo sem contar o esforço de construção em si, a demanda tem ambiguidade de
arquitetura (IA/preditivo vs. regras determinísticas), múltiplas fontes de dado candidatas
não confirmadas, pelo menos dois achados de alta severidade do assessment que tocam os
objetos prováveis, e uma pendência contratual (Onda 3 não contratada) que pode travar a
demanda antes mesmo do design. Complexidade G aqui reflete risco e ambiguidade, não
necessariamente volume de metadata a criar — o design pode reduzir para M depois que as
perguntas abertas forem respondidas.

**Estimativa de esforço:** 8–24 h — faixa deliberadamente larga porque a demanda ainda não
tem regra de negócio, fonte de dado nem canal definidos; a ponta baixa assume lógica de
regras simples sobre um único objeto já mapeado, a ponta alta assume necessidade de
consolidar a automação concorrente do achado 1 do assessment como pré-requisito e/ou cobrir
com teste a cadeia do Protheus tocada. O arquiteto refina esta faixa no design, depois de as
perguntas abertas serem respondidas.

## Encerramento

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
