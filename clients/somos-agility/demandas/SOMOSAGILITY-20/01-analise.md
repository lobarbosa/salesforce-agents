# 01 — Análise: Automatização de criação de oportunidades de renovações

**Demanda:** SOMOSAGILITY-20 · **Cliente:** somos-agility · **Tipo:** sustentação
**Fontes:** `demanda.md` (história do consultor) e `comentarios-do-card.md` (conversa do card, até 2026-10-19).
**Status:** análise **incompleta** — não passa para design enquanto as perguntas da seção 6 não forem respondidas.

---

## 1. Contexto de negócio

O departamento de **Renovações** do cliente (demandante registrado no card, chamado interno Agility 20260922-039) quer que a criação de oportunidades de renovação deixe de ser manual e passe a acontecer automaticamente no Salesforce.

Além disso, o card não diz nada sobre o processo atual: hoje quem cria essas oportunidades, em que momento, a partir de qual dado, e o que acontece com elas depois. Sem isso não dá para saber o tamanho real do ganho nem o que a automação substitui.

## 2. Objetivo

Gerar automaticamente um registro de oportunidade de renovação no Salesforce quando a condição de negócio de renovação for atingida, eliminando a criação manual pelo time de Renovações.

**Observação:** a condição de disparo, o objeto de origem e o resultado esperado ainda não estão definidos (ver seção 6). O objetivo acima é a leitura mínima do título; não é um critério validado.

## 3. Regra de negócio

**Não definida.** A demanda não informa nenhum dos pontos abaixo, e nenhum deles será inferido aqui:

- Evento ou processo que dispara a criação (data, mudança de status, criação de contrato, ação de usuário, etc.).
- Antecedência em relação ao fim da vigência/contrato (ex.: X dias antes).
- Critérios de elegibilidade (produto, tipo de conta, valor mínimo, região, carteira etc.).
- Relação com registros existentes: a oportunidade nasce a partir de uma oportunidade-mãe, de um contrato/ativo, ou é independente? Pode haver mais de uma por conta/ciclo?
- Dono (Owner) da oportunidade criada: regra fixa, usuário específico, ou herdado do registro de origem/carteira.
- RecordType, Stage inicial, Close Date e demais campos obrigatórios da oportunidade criada.
- Tratamento de duplicidade: o que fazer se já existir uma renovação aberta para o mesmo ciclo.
- O que acontece quando a condição deixa de valer (cancelamento, renovação já fechada, mudança de dono).

## 4. Critérios de aceite

Pelo critério do ba-discovery, critério que depende de regra não definida não é testável. Por isso os cenários abaixo são **esqueleto bloqueado**: a estrutura está registrada, os valores entre `< >` só podem ser preenchidos depois das respostas da seção 6. Nada aqui deve ser lido como regra aprovada.

```gherkin
# BLOQUEADO — aguarda respostas 6.1 a 6.6

Funcionalidade: Criação automática de oportunidade de renovação

  Cenário: Oportunidade criada quando a condição de renovação é atingida
    Dado que a conta/contrato <elegível pela regra 6.x> existe na org de dev/qa
    Quando <evento de disparo definido em 6.1> acontece <com antecedência definida em 6.2>
    Então existe exatamente 1 oportunidade de renovação vinculada a esse registro
    E ela tem RecordType "<definido em 6.5>", Stage "<definido em 6.5>" e Owner "<definido em 6.4>"
    E os campos <lista definida em 6.5> estão preenchidos com os valores da regra

  Cenário: Conta fora da regra não gera oportunidade
    Dado que a conta/contrato não atende <critério de elegibilidade 6.3>
    Quando <evento de disparo 6.1> acontece
    Então nenhuma oportunidade de renovação é criada para esse registro

  Cenário: Não duplica renovação já existente
    Dado que já existe uma oportunidade de renovação aberta para o mesmo <ciclo definido em 6.6>
    Quando <evento de disparo 6.1> acontece novamente
    Então nenhuma nova oportunidade é criada
    E a existente não é alterada

  Cenário: Carga em lote não quebra a operação
    Dado um lote de <N> registros, sendo <X> elegíveis
    Quando o processo roda para o lote inteiro
    Então exatamente <X> oportunidades são criadas e nenhum registro do lote falha por causa dos demais

  Cenário: Falha de criação não passa despercebida
    Dado que a criação falha por validação ou campo obrigatório
    Quando o processo roda
    Então o erro fica registrado de forma consultável <mecanismo definido em 6.7>
    E o registro de origem não fica em estado inconsistente
```

Critérios de aceite que **precisarão de decisão própria** antes de fechar: o cenário de lote e o de falha dependem de como o cliente quer ser avisado (6.7) e do volume real (6.8).

## 5. O que a demanda NÃO diz

1. **Gatilho:** nada sobre o evento ou data que dispara a criação.
2. **Antecedência:** nenhum número de dias/meses.
3. **Elegibilidade:** nenhum critério de quem entra e quem não entra.
4. **Owner:** quem fica responsável pela oportunidade criada.
5. **Estrutura da oportunidade:** RecordType, Stage, Close Date, produto/linha de itens, valor.
6. **Relação com outros registros:** oportunidade-mãe, contrato, ativo, conta, ou independente.
7. **Duplicidade:** o que fazer se já houver renovação aberta.
8. **Volume:** quantas contas/contratos por ciclo, e se há carga inicial retroativa.
9. **Notificação:** se alguém deve ser avisado (usuário, fila, e-mail, Chatter) quando a oportunidade nasce.
10. **Processo atual:** quem cria hoje, com que ferramenta, e se a automação substitui ou convive com esse processo.
11. **Integração:** se a origem da data/condição vem de sistema externo (ERP, faturamento, planilha), o que impacta diretamente a arquitetura.
12. **Ambiente de validação:** se o departamento de Renovações homologa em dev/qa, e quem é o homologador.
13. **Prazo e prioridade:** data alvo e se há impacto de negócio por atraso no ciclo de renovação.
14. **Comentários do card:** o único registro é o número do chamado e o departamento; não há resposta a dúvidas porque ainda não foram feitas.

## 6. Perguntas que precisam de resposta antes do design

As perguntas de 6.1 a 6.6 bloqueiam o design. As demais definem escopo e validação.

**Bloqueantes para o design (mudam a arquitetura):**

- **6.1 Gatilho.** O que dispara a criação? Data (cron/agendado), mudança de campo, criação/alteração de contrato ou de oportunidade-mãe, ou ação manual? A resposta decide entre Flow de registro, Flow agendado ou integração externa — são caminhos bem diferentes.
- **6.2 Antecedência.** Com quanto tempo antes do fim da vigência/contrato a oportunidade deve existir? Valor fixo ou parametrizável?
- **6.3 Elegibilidade.** Quais critérios exatos (campos, valores, tipo de conta, produto, carteira)? Pedimos a lista exata de campos e valores, não uma descrição.
- **6.4 Owner.** Quem é o dono da oportunidade criada: usuário fixo, fila, dono da conta, ou regra de carteira? Precisamos do nome de cada regra e do critério de cada uma, e confirmação do que a org tem hoje (usuários, filas, territórios).
- **6.5 Estrutura do registro criado.** RecordType, Stage inicial, Close Date (regra de cálculo), campos obrigatórios e valores padrão.
- **6.6 Relação e duplicidade.** A renovação nasce de uma oportunidade-mãe ou de contrato/ativo? Pode haver mais de uma por ciclo? Como identificar "o mesmo ciclo"?

**Escopo e validação:**

- **6.7 Erro e notificação.** Quem deve saber quando a criação falha ou quando uma oportunidade nasce? Por qual canal (e-mail, Chatter, relatório, tarefa)?
- **6.8 Volume e carga inicial.** Quantos registros por ciclo? Precisa retroagir (renovações já vencidas ou próximas) ou vale só para o futuro?
- **6.9 Processo atual.** Hoje quem cria, com que ferramenta? A automação substitui por completo ou convive (ex.: o time ainda ajusta manualmente)?
- **6.10 Origem dos dados.** A condição depende de algum dado vindo de sistema externo? Qual, e como chega ao Salesforce?
- **6.11 Homologação.** Quem do departamento de Renovações valida em qa? Há janela ou data alvo?
- **6.12 Prioridade.** Qual o impacto de atraso e há data-limite para entrega?

Observação de governança: como o registro de origem da demanda é um card com pouco texto, a resposta às perguntas 6.1 a 6.6 deve ser registrada no próprio card (comentário do cliente ou do consultor), para que entre na sessão de análise pelo `comentarios-do-card.md`.

## 7. Complexidade e estimativa

**Complexidade provisória: M.**

Justificativa: a criação de oportunidade envolve objeto central de vendas, que costuma ter validação, automação e campos obrigatórios existentes; e a regra ainda não existe, então a faixa de horas é ampla.

**Estimativa de esforço:** 10–28 h

Premissas que mais pesam na faixa:
- Solução declarativa (Flow) basta, sem Apex e sem integração externa. Se a condição depender de sistema externo, a faixa sobe e pode sair de sustentação.
- Regra de elegibilidade simples (até ~3 critérios sobre campos da org). Regras com muitas exceções por carteira ou produto estendem o levantamento e o teste.
- Uma única origem de disparo e uma única forma de dono.
- Um ciclo de homologação em qa com o departamento de Renovações; retrabalho de regra conta à parte.
- Carga inicial retroativa fora do escopo; se entrar, a faixa sobe.
- Estimativa de consultor/dev (configurar, revisar, testar, homologar), não tempo do agente. O arquiteto refina no design.

## 8. Premissas a validar

Nenhuma premissa foi assumida silenciosamente. As abaixo são **pendentes**, e cada uma precisa de confirmação humana:

- **P1 (pendente):** a oportunidade será criada no objeto Opportunity padrão (não em objeto customizado de renovação). Validar com 6.6.
- **P2 (pendente):** a org de dev do cliente já tem a estrutura de renovações (RecordTypes, Stages) que a regra vai usar. Confirmar via `sf` CLI contra a org antes do design (guardrail #3); ainda não foi verificado.
- **P3 (pendente):** não há Apex nem integração externa necessários. Depende de 6.1 e 6.10.
- **P4 (pendente):** o processo de criação é único para o cliente (não por unidade de negócio). Validar com 6.3 e 6.4.
- **P5 (pendente):** o ambiente de validação é o qa da esteira (`sbx-somos-agility-qa`), com homologação pelo departamento de Renovações. Validar com 6.11.

Nenhum dado de cliente foi consultado para escrever esta análise (guardrail #2). Nenhuma org foi acessada.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
