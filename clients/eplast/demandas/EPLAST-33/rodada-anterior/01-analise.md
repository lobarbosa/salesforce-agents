# EPLAST-33 — Cross-sell, aumento de volume e recuperação de clientes

**Cliente:** Eplast · **Tipo:** projeto · **Etapa:** 1 (análise, ba-discovery)
**Org confirmada via `sf`:** `sbx-eplast-dev` → `https://eplast--qa.sandbox.my.salesforce.com`, usuário de integração `...eplast2.qa` (nome mascarado aqui — guardrail #2), API 68.0, isSandbox=true. Ver risco 6 abaixo: o alias de dev aponta para uma instância cujo host e usuário se identificam como qa. Continua valendo hoje.

**Status deste documento:** rascunho para validação humana. Nada aqui foi aprovado. Esta análise não substitui o refinamento com o consultor.

---

## 0. Pontos que bloqueiam a decisão de prosseguir

1. **Escopo não contratado.** A demanda é "Onda 3 · Comercial", e o `contrato.md` diz que as Ondas 3, 4 e 5 ainda não foram contratadas. Registrar a demanda antes do contrato cobrir o trabalho é uma decisão de negócio. Esta análise não decide se a demanda segue. Fica para o humano decidir no gate.
2. **Sobreposição com escopo já contratado.** O entregável `eplast-ent-11` ("Quais clientes estão há mais tempo sem comprar?", peso 2, Onda 2, a iniciar nas semanas 6–7) cobre o mesmo tema de **recuperação de clientes**. Também há sobreposição com EPLAST-26 (scoring de leads e oportunidades), EPLAST-27 (próxima melhor ação por cliente), EPLAST-28 (alertas de oportunidade parada) e EPLAST-32 (painel meta × carteira × pedidos). Antes do design, é preciso decidir se EPLAST-33 é um entregável separado, uma extensão de `eplast-ent-11` ou parte de uma demanda que já existe. Sem essa decisão há risco de cobrar o mesmo trabalho duas vezes ou de construir duas listas de "clientes sem compra" com regras diferentes.
3. **Canal de apresentação e natureza da entrega não definidos.** Relatório, list view, campo em Account/Opportunity, tarefa, ou resposta de assistente de IA são arquiteturas diferentes. Essa escolha muda o design (declarativo ou código, Agentforce ou não). Por isso a análise **para e pergunta** (ver seção 6).

---

## 1. Contexto de negócio

A demanda vem da Solicitação de Proposta Konecta, "Implantação de IA no Salesforce Sales e Marketing (Eplast)". O item pede identificar três tipos de oportunidade comercial:

- **Aumento de volume:** contas que compram mais, ou menos, do que o próprio histórico sugere.
- **Venda cruzada (cross-sell):** produtos que clientes com um padrão de compra parecido costumam levar e que a conta ainda não leva.
- **Recuperação:** contas que deixaram de comprar.

O histórico do projeto mostra que a Eplast já tem um piloto de IA no Salesforce (Agentforce no perímetro do piloto, `eplast-ent-07`, concluído). Também tem agentes de consulta de clientes em construção (`eplast-ent-09`, `eplast-ent-10`) e um agente de "clientes sem compra" a iniciar (`eplast-ent-11`). Os dados de pedido, segundo o próprio contrato, vêm do Protheus, e a qualidade deles é um risco já registrado no entregável `eplast-ent-11`.

## 2. Objetivo

**Objetivo declarado pelo consultor (literal):** "Identificar oportunidades de aumento de volume, venda cruzada e recuperação de clientes."

**Objetivo refinado (proposta, a validar):** dado o histórico comercial já existente no Salesforce, gerar uma lista de oportunidades por conta e tipo (volume, cruzada, recuperação), com o motivo de cada uma, para que o responsável comercial decida o que fazer. O objetivo é apoiar a decisão do vendedor. A demanda não diz que a ação deve ser automática.

**Métrica de sucesso:** não definida. Ver pergunta 9.

## 3. Regras de negócio

A demanda não traz nenhuma regra. As regras abaixo são **candidatas**. Cada uma depende de resposta do cliente antes de virar regra:

- **RN-1 (recuperação):** conta é "sem compra" quando o último pedido faturado ou concluído é anterior a N meses. N e o status de pedido que conta são pendentes. O `eplast-ent-11` pode já definir isso.
- **RN-2 (aumento de volume):** a conta entra quando o volume do período atual varia além de um limiar em relação a uma base de comparação. Métrica (valor, quantidade, litros, ou outra), janela e limiar são pendentes.
- **RN-3 (cruzada):** para uma conta, um produto P é oportunidade quando a conta não comprou P nos últimos M meses e um grupo de referência (segmento, região, ou carteira) comprou P com frequência acima de um limiar. Critério de grupo, base de produto (catálogo CPQ ou histórico de pedidos) e limiar são pendentes.
- **RN-4 (carteira):** o responsável só vê contas da própria carteira. A forma de hierarquia (owner, equipe, região) é pendente.
- **RN-5 (não escrita, proposta):** a identificação não cria, altera nem exclui registros de Account, Opportunity, Order ou OrderItem. Essa é uma proposta de guarda, derivada do assessment (achado 1). Só vale se o cliente confirmar que a saída é apenas leitura ou um objeto próprio.

## 4. Critérios de aceite (Gherkin)

Os cenários abaixo são testáveis sobre **fixture de teste** (dados fictícios em sandbox). Os que dependem de decisão pendente estão marcados `[PENDENTE: Qn]`. Os números e limiares são placeholders, não valores acordados.

```gherkin
Funcionalidade: Identificação de oportunidades comerciais (EPLAST-33)

  Cenário: Conta sem compra há mais de N meses é listada como recuperação
    [PENDENTE: Q4, Q5, sobreposição com eplast-ent-11]
    Dado um conjunto de contas de fixture, com N = <valor acordado>
    E uma conta cujo último pedido concluído é anterior a hoje menos N meses
    E uma conta cujo último pedido concluído está dentro da janela de N meses
    Quando a identificação de recuperação é executada
    Então a primeira conta aparece na lista de recuperação com o motivo "sem compra desde <data>"
    E a segunda conta não aparece na lista de recuperação

  Cenário: Conta sem histórico suficiente não entra como aumento de volume
    [PENDENTE: Q6]
    Dado uma conta com menos de <K> períodos de histórico
    Quando a identificação de aumento de volume é executada
    Então a conta não aparece como oportunidade de aumento de volume
    E aparece na lista de "sem base de comparação" (ou fica fora de tudo, conforme Q6)

  Cenário: Conta com variação acima do limiar entra como aumento de volume
    [PENDENTE: Q6, métrica e limiar]
    Dado uma conta cujo volume do período atual é <X>% acima da base de comparação, com X >= limiar acordado
    Quando a identificação de aumento de volume é executada
    Então a conta aparece na lista de aumento de volume com a variação calculada
    E uma conta com variação abaixo do limiar não aparece

  Cenário: Produto de cruzada aparece para conta que não o comprou
    [PENDENTE: Q7, Q8]
    Dado que o grupo de referência da conta comprou o produto P com frequência acima do limiar
    E que a conta não comprou P nos últimos M meses
    Quando a identificação de venda cruzada é executada
    Então o produto P aparece como oportunidade para a conta com o motivo da regra
    E um produto que a conta já comprou nos últimos M meses não aparece

  Cenário: Responsável vê somente a própria carteira
    [PENDENTE: Q10]
    Dado um usuário vendedor associado à carteira A
    E oportunidades identificadas para as carteiras A e B
    Quando o usuário consulta a lista
    Então vê apenas as oportunidades da carteira A
    E um usuário sem permissão no registro não consegue abrir a conta pela lista

  Cenário: A identificação não altera registros comerciais
    [PENDENTE: Q2, confirmar que a saída é só leitura ou objeto próprio]
    Dado a contagem de Account, Opportunity, Order e OrderItem na fixture antes da execução
    Quando a identificação é executada inteira
    Então a contagem e o conteúdo desses registros são iguais aos de antes
    E nenhum trigger ou Flow de Account, Opportunity ou Order é disparado pela execução

  Cenário: Saída não contém campo fora da lista aprovada
    [PENDENTE: Q11]
    Dado a lista de campos aprovada pelo cliente para a saída
    Quando a saída é gerada
    Então ela contém somente os campos da lista aprovada
    E não contém CPF, e-mail ou telefone, salvo se o cliente aprovar explicitamente

  Cenário: Código Apex novo atende ao padrão de teste do squad
    Dado qualquer classe Apex criada pela demanda
    Quando o deploy de validação roda na sandbox de dev
    Então existe uma classe <Classe>Test dedicada
    E a cobertura da classe é >= 85%
    E a cobertura org-wide não fica abaixo do valor medido antes da demanda (10% no assessment)
```

**Observação sobre testabilidade:** o cenário de cobertura é o único que pode ser verificado hoje, porque não depende de decisão de negócio. Os demais só viram critério testável depois das respostas. Por isso a seção 6 pede as respostas antes do design.

## 5. Premissas a validar (todas PENDENTES)

| # | Premissa assumida para escrever a análise | Estado |
|---|---|---|
| P1 | A identificação é apoio à decisão, não ação automática sobre o registro. | PENDENTE (Q2, Q3) |
| P2 | O volume vem dos pedidos do Salesforce (Order/OrderItem), que chegam do Protheus. Não foi confirmado que esses dados estão completos e atualizados. | PENDENTE (Q12). Dado do Protheus não foi lido: sandbox de dev está vazia (0 Account, 0 Opportunity no assessment). |
| P3 | A recuperação pode reaproveitar a regra de `eplast-ent-11`. | PENDENTE (Q1) |
| P4 | Os objetos Account, Opportunity, Order e Lead existem e são os de referência. Confirmado hoje via `sf sobject describe` (Account 136 campos, 90 custom; Opportunity 77, 28 custom; Order 111, 64 custom; Lead 63, 12 custom). Os campos específicos de volume e produto **não foram confirmados**. | Objetos confirmados. Campos PENDENTES de mapeamento no design. |
| P5 | Produto de cruzada pode vir do catálogo CPQ (SBQQ) ou do histórico de pedidos. Não foi verificado se o CPQ já expõe o que é necessário. | PENDENTE (Q7). Nenhum objeto SBQQ foi descrito nesta análise. |
| P6 | Não há dados pessoais do cliente no escopo. Se houver, a saída deve ser limitada aos campos que o cliente aprovar. | PENDENTE (Q11). Guardrail #2: nenhuma consulta com dado real foi feita para esta análise. |
| P7 | A demanda segue o fluxo completo (projeto, etapas 1 a 7). | PENDENTE: depende da decisão de contrato (ponto 0.1). |

## 6. O que a demanda NÃO diz (perguntas a responder antes do design)

**Bloqueantes para o design (mudam arquitetura):**

- **Q1.** A demanda é um entregável novo, uma extensão de `eplast-ent-11` ou parte de outra demanda (EPLAST-26, 27, 28, 32)?
- **Q2.** Qual é a natureza da entrega: relatório, list view, campo calculado, tarefa criada para o vendedor, ou resposta de conversa no assistente de IA? Se for assistente, é o Agentforce do piloto (`eplast-ent-07`) ou outra plataforma?
- **Q3.** A identificação é só leitura, ou gera registros (tarefa, oportunidade, campo)? Se gera, em qual objeto?
- **Q4.** Qual a janela de "sem compra" (N meses)? Qual status de pedido conta como compra?
- **Q5.** A regra de recuperação é a mesma de `eplast-ent-11`? Quem é a fonte da regra?
- **Q6.** Qual métrica de volume (valor, quantidade, litros, pedidos)? Qual base de comparação (média de quantos períodos)? Qual limiar? O que acontece com conta sem histórico suficiente?
- **Q7.** Qual a fonte de produto para cruzada: catálogo CPQ, histórico de pedidos, ou regra de negócio manual? Quais produtos entram?
- **Q8.** Qual o grupo de referência para cruzada (segmento, região, canal, carteira)? Qual frequência conta como "comum"?

**Importantes, mas não bloqueiam o design:**

- **Q9.** Qual métrica de sucesso e critério de aceite de negócio (quantas oportunidades, taxa de conversão, tempo economizado)?
- **Q10.** Quem usa e como se define a carteira (owner, equipe, região, hierarquia de papéis)? Quais perfis e permission sets?
- **Q11.** Quais campos a saída pode mostrar? Há dados pessoais? A saída pode ser exportada?
- **Q12.** Os pedidos do Protheus chegam completos e atualizados no Salesforce? Qual a amostra validada pelo Comercial (o `eplast-ent-11` já pede isso)?
- **Q13.** Qual a frequência de atualização esperada (sob demanda, diária, semanal)? Qual latência é aceitável? Qual volume de contas e pedidos?
- **Q14.** Há orçamento de créditos de IA ou licença Agentforce disponível para este item? (Ver também as perguntas da EPLAST-29.)
- **Q15.** Quem valida as regras de negócio com o cliente, e em qual momento (antes do design ou no gate do arquiteto)?
- **Q16.** Como o responsável é notificado, se for o caso? Por qual canal?

## 7. Riscos da org (assessment) que tocam este pedido

Lidos em `clients/eplast/assessment.md`, saúde geral **vermelha**:

1. **Automação concorrente em Account, Opportunity e Order (achado 1, alta).** Qualquer escrita ou gatilho nesses objetos entra numa ordem de execução que ninguém mapeou (trigger custom, trigger do CPQ, Flows RecordAfterSave/RecordBeforeSave). A recomendação do assessment é mapear a ordem antes de qualquer demanda que toque esses objetos. A RN-5 existe por esse motivo: se a identificação for só leitura, ela não entra nessa cadeia.
2. **Cobertura Apex de 10% (achado 2, alta).** Classes centrais do ERP Protheus, que move pedido e financeiro, não têm teste identificável. Se a identificação depender de lógica compartilhada com essa cadeia, a base de teste não existe hoje. Qualquer Apex novo precisa de `<Classe>Test` com 85% (ver cenário de cobertura).
3. **Validation rules de Order (achado 3, média).** 23 regras, 9 com mensagem genérica e 6 inativas. Se a demanda escrever em Order, essas regras podem bloquear o registro de forma inesperada.
4. **Campos sem descrição (achado 4, média).** 153 de 223 campos custom em Account, Order, Opportunity e OrderItem não têm `Description`. Mapear campos de volume e produto exige confirmação com o cliente. Não é aceitável inferir o significado pelo nome.
5. **Classes de teste fora da convenção (achado 5).** Ver cenário de cobertura.
6. **Alias `sbx-eplast-dev` aponta para sandbox de qa (achado 6, média).** Confirmado hoje via `sf org display`: host `eplast--qa` e usuário `...eplast2.qa`. A separação dev/qa que o `ambientes.py` assume não está verificada. Antes do build, este ponto precisa ser confirmado com o cliente. Sem isso, o build e o roteiro de QA podem usar o mesmo ambiente.
7. **Achados 9 e 10 (baixa).** API version das classes atrás da org e nome de trigger duplicado (`OrderTrigger`, no pacote SBQQ e no custom). Afetam a manutenção, não o escopo desta demanda.

**O que o assessment não conseguiu medir e que pesa aqui:** volume real de pedidos, qualidade dos dados do Protheus e OWD/sharing. Esses três pontos definem se o cruzamento é viável e se a carteira pode ser aplicada. A sandbox de dev está vazia, e a produção não é consultada por guardrail. Isso significa que o aceite de volume e de cruzada só pode ser validado com fixture de teste até o cliente liberar dado controlado.

## 8. Fontes de histórico (RAG)

- `[demandas/EPLAST-28/01-analise.md]`, `[demandas/EPLAST-29/01-analise.md]`, `[demandas/EPLAST-30/demanda.md]`: o RAG retornou esses trechos, mas no workspace atual a pasta EPLAST-28 tem só `demanda.md` e `status.yaml`, sem análise em disco. O que foi usado aqui é o conteúdo que o RAG devolveu. Não foi conferido em disco.
- `[contrato.md]`: escopo contratado (Ondas 1 e 2) e o entregável `eplast-ent-11`.
- `[assessment.md]`: achados 1 a 10 acima.

## 9. Complexidade

**G.** Três objetos com automação concorrente, integração com Protheus sem cobertura de teste, escopo e canal sem definição, e dependência de dado de pedido que ainda não foi validado. Se o cliente reduzir o escopo a um único relatório de uma regra, sem escrita, a complexidade cai para M. Essa decisão é do humano.

## 10. Estimativa de esforço humano

**Estimativa de esforço:** 24–120 h

Premissas que mais pesam na faixa:

- **Limite inferior (24 h):** um relatório ou list view com uma regra (recuperação, possivelmente reaproveitada de `eplast-ent-11`), sem escrita, sobre fixture de teste, com revisão e homologação por um consultor. Assume Q1 e Q2 respondidas cedo.
- **Limite superior (120 h):** três regras, canal integrado (assistente ou tarefa), mapeamento e consolidação da automação concorrente (assessment achado 1, esforço alto), `<Classe>Test` com 85% para o Apex novo, e validação de dado do Protheus com o Comercial.
- **O que mais move a faixa:** (a) se a identificação for só leitura (RN-5); (b) se o cruzamento usar catálogo CPQ ou histórico de pedidos; (c) se a sobreposição com `eplast-ent-11` e demandas como EPLAST-26/27/28 for resolvida antes ou depois.

Esta estimativa é de esforço humano (consultor e dev configurando, revisando, testando e homologando). Não inclui o tempo do agente. O arquiteto refina no design.

---

## Encerramento

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.

Pontos que precisam de decisão humana antes disso: (0.1) escopo não contratado, (0.2) sobreposição com `eplast-ent-11` e demandas EPLAST-26/27/28/32, (0.3) canal e natureza da entrega (Q2, Q3), e (6) respostas Q1 a Q8.
