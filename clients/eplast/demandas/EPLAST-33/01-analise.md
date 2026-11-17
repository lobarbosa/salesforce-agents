# EPLAST-33 — Cross-sell, aumento de volume e recuperação de clientes

Análise refeita em 2026-11-15 pela regra 4 da conta Eplast (pergunta de negócio sem resposta não trava; decide-se pela org, depois pelo padrão, e registra-se como premissa assumida). Artefatos da rodada anterior em `rodada-anterior/` foram usados só como referência.

**Org conferida:** `sbx-eplast-dev` (alias de dev, conectado hoje por `sf org list`). Atenção ao risco 6 abaixo: o username da conexão ainda traz o sufixo `eplast2.qa`. Todas as consultas foram de metadata e contagens agregadas. Nenhum registro real foi lido.

---

## 1. Contexto de negócio

A demanda vem da Solicitação de Proposta Konecta ("Implantação de IA no Salesforce Sales e Marketing (Eplast)"). O item pede identificar oportunidades comerciais de três tipos:

- **Aumento de volume:** contas cujas compras mudam de patamar em relação ao próprio histórico.
- **Venda cruzada (cross-sell):** produtos que clientes parecidos compram e que a conta ainda não comprou.
- **Recuperação:** contas que deixaram de comprar.

A Eplast já tem o agente `SFAgent2` (Agentforce, piloto anterior) e, na org, um fluxo agendado de oportunidade que calcula valor de compras e ranking de contas (ver seção 3). Os pedidos vêm do Protheus e chegam ao Salesforce em `Order`, com `Order.ProtheusId__c`.

## 2. Objetivo

Gerar, por conta, uma lista de oportunidades classificadas por tipo (recuperação, nunca comprou, queda de volume, alta de volume, cruzada por produto), com o motivo de cada uma, para que o responsável comercial decida a ação. A demanda não pede ação automática.

**Métrica de sucesso (proposta, a validar na homologação):** a lista bate com a amostra que o Comercial confirma no Protheus (critério CA-18). Não há métrica de negócio no card; ver premissa PA-13.

## 3. O que a org já cobre (regra 3 da conta)

Confirmado hoje via `sf`, salvo onde indicado.

| Pedido | O que já existe | Decisão |
|---|---|---|
| Recuperação e "clientes sem compra" | Agente `SFAgent2`: `GenAiPlannerDefinition` `SFAgent2_v1` a `v4` confirmados hoje. A régua de 60 dias e o ranking de "há mais tempo sem comprar" vêm da recon anterior, via RAG `[demandas/EPLAST-33/rodada-anterior/02-recon.md]`. Relatórios de pedido por conta com nomes próximos: `PEDIDOS POR CLIENTE`, `CONTAS COM PEDIDOS - EM CRIAÇÃO`, `ARI F (OPORTUDNIDADES COM PEDIDOS)`, `Pedidos Concluídos HOJE` (só nomes confirmados; filtros e colunas não lidos) | Não cria agente. Reaproveita a régua do `SFAgent2`. O recon confere se algum relatório existente já entrega a lista |
| Queda de volume | `SFAgent2` (queda > 30%, 3 meses contra os 3 anteriores, `SUM(TotalAmount)`, recon anterior via RAG). Campos em Account confirmados: `TotalPurchasesThisYear__c`, `AveragePurchasesThisYear__c`, `LastMonthPurchaseValue__c`, `LastPurchase__c`. Sem `Description` (assessment, achado 4) | Calcula a partir de `Order`, não desses campos custom. O design diz se reaproveita algum deles |
| Valor de compras e ranking por conta | Flow `ScheduledFlowOpportunity` ("Fluxo Agendado - Oportunidade") confirmado na org. A demanda EPLAST-47 descreve que ele calcula valor de compras e ranking das contas todo dia 14 (via RAG `[demandas/EPLAST-47/demanda.md]`; a lógica não foi lida em disco nesta sessão) | **Sobreposição forte.** O design é obrigado a dizer se a lista consome o cálculo desse Flow ou se o substitui, e a coordenar com EPLAST-47. Dois rankings com regras diferentes é o risco central aqui |
| Pedido agendado | Flow `OrderScheduledFlow` ("Pedido - Fluxo Agendado") confirmado na org, ligado a Order. Função não lida | Recon lê antes do design |
| Cruzada por grupo de referência | Não existe no `SFAgent2` (recon anterior). Nenhuma classe Apex custom com nome `Cross`, `Recup`, `Sugest` ou `Oportun` (contagem 0, confirmada hoje) | Cria. Componente novo, justificado no design |
| Aumento de volume para cima | Não existe no `SFAgent2` | Cria (PA-6) |
| Sem Industry | `Account.Industry` é campo padrão e existe. Na dev há 0 contas, então o preenchimento não foi verificado | Ver PA-7 e incerteza I-4 |

## 4. Escopo

**Incluído (v1):**
- Classificação por conta dos cinco tipos da seção 2, a partir de `Order`, `OrderItem` e `Account`.
- Parâmetros configuráveis: janelas, limiares, status que contam como compra, tamanho mínimo de grupo.
- Saída em relatório ou lista sobre dados existentes, exportável com ID e tipo da conta, para o Marketing Cloud montar público.
- Recálculo agendado (PA-14).
- Acesso pelo compartilhamento do próprio usuário (PA-8).

**Fora (v1):**
- Escrita em Account, Opportunity, Order ou OrderItem (PA-9). Não cria trigger, Flow nem e-mail no CRM.
- Disparo de e-mail, mensagem, campanha ou jornada. Isso é do Marketing Cloud (regra 2 da conta, PA-10).
- Extensão do `SFAgent2` e resposta em conversa (fase 2, PA-1). Não cria agente novo.
- Notificação ao vendedor (não pedida no card).
- Integração nova com o Protheus.
- Cruzada pelo catálogo CPQ (PA-7 usa histórico de pedidos).

**Escopo de onda:** não é critério de bloqueio. Pelas diretrizes da conta, a demanda segue mesmo fora das Ondas 1–2 de `contrato.md`.

## 5. Requisitos funcionais

- **RF-1.** Classificar cada conta em: Recuperação, Nunca comprou, Queda de volume, Alta de volume e, por produto, Cruzada.
- **RF-2.** Para cada oportunidade, mostrar o motivo: a métrica, a janela, a data de referência da última compra e o valor de comparação.
- **RF-3.** Só listar contas que o usuário pode ver pelo compartilhamento.
- **RF-4.** Recalcular em agenda diária (PA-14). Recuperação e volume podem também ser lidos a qualquer momento no relatório.
- **RF-5.** Parâmetros (janelas, limiares, status, tamanho mínimo de grupo) ficam em um único lugar configurável, sem alterar código.
- **RF-6.** Não escrever em objetos comerciais do CRM.
- **RF-7.** A saída traz só identificação da conta (ID e nome), tipo, métrica e datas. Sem contato (PA-13).

## 6. Critérios de aceite (Gherkin)

Os testes rodam em fixture sintética na sandbox de QA. Os valores das fixtures são exemplos que fixam os limites; não são dados de cliente. "Hoje" é a data da execução.

```gherkin
Funcionalidade: Oportunidades comerciais por conta (EPLAST-33, v1 somente leitura)

  Cenário: CA-01 Conta com última compra válida há 61 dias entra como recuperação
    Dado uma conta com um único pedido em "Faturamento" com EffectiveDate há 61 dias
    Quando a lista de oportunidades é gerada
    Então a conta aparece com tipo "Recuperação" e dias sem compra igual a 61

  Cenário: CA-02 Conta com última compra válida há 59 dias não entra em recuperação
    Dado uma conta com um único pedido em "Concluido" com EffectiveDate há 59 dias
    Quando a lista de oportunidades é gerada
    Então a conta não aparece como "Recuperação"

  Cenário: CA-03 Conta sem nenhum pedido válido aparece como "Nunca comprou"
    Dado uma conta sem pedidos
    Quando a lista de oportunidades é gerada
    Então a conta aparece com tipo "Nunca comprou" e não aparece como "Recuperação"

  Cenário: CA-04 Pedido cancelado ou em processo não conta como compra
    Dado uma conta com um pedido "Cancelado" de 5 dias atrás e um pedido em "Revisao de Pedido" de 3 dias atrás
    Quando a lista de oportunidades é gerada
    Então a conta aparece como "Nunca comprou"

  Cenário: CA-05 Queda de volume exige mais de 30%
    Dado uma conta com soma de TotalAmount de 10.000 nos 3 meses anteriores
    E soma de 7.000 nos 3 meses atuais (queda de 30%, exatamente o limite)
    Quando a lista de oportunidades é gerada
    Então a conta não aparece como "Queda de volume"
    Dado que a soma atual passa a ser 6.900 (queda de 31%)
    Quando a lista de oportunidades é gerada
    Então a conta aparece como "Queda de volume" com o percentual 31

  Cenário: CA-06 Alta de volume exige mais de 30%
    Dado uma conta com soma de 10.000 nos 3 meses anteriores e 13.000 nos 3 meses atuais (alta de 30%)
    Quando a lista de oportunidades é gerada
    Então a conta não aparece como "Alta de volume"
    Dado que a soma atual passa a ser 13.100 (alta de 31%)
    Quando a lista de oportunidades é gerada
    Então a conta aparece como "Alta de volume"

  Cenário: CA-07 Conta sem pedidos na base de comparação não entra em volume
    Dado uma conta com pedidos apenas nos 3 meses atuais
    Quando a lista de oportunidades é gerada
    Então a conta não aparece como "Queda de volume" nem como "Alta de volume"

  Cenário: CA-08 Cruzada exige 30% ou mais das contas do grupo
    Dado um grupo de 10 contas com o mesmo Industry, das quais 4 compraram o produto P nos últimos 12 meses
    E uma conta do grupo que não comprou P nos últimos 180 dias
    Quando a lista de oportunidades é gerada
    Então a conta aparece com tipo "Cruzada" e produto P
    Dado que apenas 2 das 10 contas compraram P
    Quando a lista de oportunidades é gerada
    Então nenhuma conta do grupo aparece com cruzada para P

  Cenário: CA-09 Conta que comprou o produto recentemente não recebe cruzada para ele
    Dado uma conta do grupo que comprou P há 90 dias
    Quando a lista de oportunidades é gerada
    Então a conta não aparece com cruzada para P

  Cenário: CA-10 Conta sem Industry fica fora da cruzada e segue nos demais tipos
    Dado uma conta sem Industry com pedido "Faturamento" há 61 dias
    Quando a lista de oportunidades é gerada
    Então a conta não aparece com cruzada
    E a conta aparece como "Recuperação"

  Cenário: CA-11 Grupo com menos de 5 contas não gera cruzada
    Dado um grupo de 4 contas com o mesmo Industry, com 4 compras do produto P
    Quando a lista de oportunidades é gerada
    Então nenhuma conta desse grupo aparece com cruzada para P

  Cenário: CA-12 A execução não escreve em objetos comerciais
    Dado a contagem e o maior LastModifiedDate de Account, Opportunity, Order e OrderItem antes da execução
    Quando a lista de oportunidades é gerada
    Então a contagem e o maior LastModifiedDate são iguais depois da execução
    E nenhum EmailMessage ou EmailAlert foi criado

  Cenário: CA-13 Carteira respeita o compartilhamento do usuário
    Dado o usuário A sem acesso à conta X e o usuário B com acesso à conta X
    Quando cada usuário abre a lista
    Então A não vê a conta X e B vê

  Cenário: CA-14 Saída não traz dado de contato
    Dado a lista gerada para um usuário
    Quando as colunas são inspecionadas
    Então existem ID, nome da conta, tipo, métrica e datas
    E não existe e-mail, telefone nem CPF

  Cenário: CA-15 Execução repetida é idempotente
    Dado a lista gerada duas vezes sobre a mesma base
    Quando as duas saídas são comparadas
    Então contêm os mesmos registros, sem duplicatas

  Cenário: CA-16 Pedido novo tira a conta da recuperação na execução seguinte
    Dado uma conta em recuperação
    Quando um pedido "Faturamento" com EffectiveDate de hoje é criado e a lista é recalculada
    Então a conta deixa de aparecer como "Recuperação"

  Cenário: CA-17 Parâmetro muda a classificação sem alterar código
    Dado a janela de recuperação alterada de 60 para 90 dias
    Quando a lista é gerada sobre a fixture do CA-01
    Então a conta de 61 dias não aparece como "Recuperação"

  Cenário: CA-18 Comercial valida a amostra na homologação
    Dado uma amostra de contas escolhida pelo Comercial na homologação
    Quando o Comercial compara a lista com o histórico do Protheus
    Então o Comercial aprova a amostra ou aponta as divergências para correção da regra de fonte

  Cenário: CA-19 Marketing recebe a lista sem disparo pelo CRM
    Dado a lista exportada com ID e tipo da conta
    Quando a exportação é usada para montar público no Marketing Cloud
    Então o CRM não dispara nenhum envio e nenhum Flow ou Apex de e-mail foi criado

  Cenário: CA-20 Cobertura de teste e nomenclatura
    Dado as classes Apex novas da entrega
    Quando a suíte roda na sandbox de QA
    Então cada classe tem uma classe `<Classe>Test` com cobertura de 85% ou mais, e a suíte passa

  Cenário: CA-21 Sem trigger ou Flow novo em objetos comerciais
    Dado o inventário de metadata de Account, Opportunity e Order antes e depois da entrega
    Quando a entrega é comparada
    Então nenhum trigger, Flow ou validation rule novo existe nesses objetos
```

## 7. Riscos do assessment que tocam o pedido

Lido em `clients/eplast/assessment.md`, saúde vermelha. Só os achados que tocam o pedido:

1. **Automação concorrente em Order (achado 1, alta).** Confirmado hoje: 2 triggers em Order (`OrderTrigger` custom e o do CPQ) e Flows em Order, incluindo `OrderScheduledFlow`. A v1 é somente leitura (PA-9), então não entra na cadeia de escrita. **Tratamento no design:** mapear a ordem de execução antes de qualquer DML e garantir que o batch não escreva em Order.
2. **Cobertura Apex de 10% (achado 2, alta).** A cruzada exige Apex batch. **Tratamento no design:** `<Classe>Test` com 85% por classe nova (CA-20). Não usar as classes de integração Protheus (`OrderAdapter`, `OrderUtility` e similares) como fonte da lista.
3. **Validation rules de Order (achado 3, média).** Confirmado: 23 regras em Order, com obrigatoriedade duplicada. **Impacto nos testes:** criar pedido na fixture de QA exige preencher os campos que essas regras pedem. **Tratamento:** o roteiro de fixture lista esses campos antes do build.
4. **Campos sem descrição (achado 4, média).** `Volume1__c` e `Branch__c` não têm descrição. **Tratamento:** a v1 não usa campos custom sem descrição. Usa `TotalAmount`, `EffectiveDate`, `Status`, `OrderItem.Product2Id` e `Account.Industry` (padrões). Os campos `LastPurchase__c` e similares ficam de fora até a Eplast confirmar o significado.
5. **Nomenclatura de teste (achado 5).** Classe de teste com `<Classe>Test` (CA-20).
6. **Alias de dev aponta para sandbox que se identifica como qa (achado 6, média).** Reconfirmado hoje: `sf org list` mostra `sbx-eplast-dev` com username `...eplast2.qa`. **Condição para o build, não para esta análise:** antes de construir, confirmar que dev e QA são sandboxes distintas. Sem isso, build e roteiro de QA podem competir no mesmo ambiente.
7. **Perfis (achado 7 e 8).** A carteira depende de perfil e permission set (PA-8). Não há regra de acesso própria nesta demanda.
8. **Nome duplicado de `OrderTrigger` (achado 10, baixa).** Se o design criar Apex, evitar colisão de nome.

**Não medido pelo assessment e que pesa aqui:** OWD e compartilhamento, volume real de pedidos e qualidade dos dados do Protheus. Como a dev está vazia e produção não é consultada, nenhuma regra de limiar foi testada com dado real.

## 8. Premissas assumidas (validar na homologação)

Cada item é decisão tomada com evidência, pela regra 4 da conta. Pergunta, decisão, evidência e como mudar estão em cada um.

- [x] **PA-1. Canal e natureza da entrega (card 2026-11-13, itens 2 e 3; Q1, Q2 e Q14).**
  Pergunta: é entrega própria ou parte do assistente; relatório/lista ou assistente de IA?
  Decisão: v1 entrega lista ou relatório, sem IA generativa. O `SFAgent2` entra depois como extensão de tópico ou ação, nunca como agente novo.
  Evidência: `SFAgent2_v1` a `v4` existem (confirmado hoje). O tópico `insights_comerciais` responde sob demanda por conversa, não lista a carteira inteira (recon anterior via RAG). Regra 3 da conta.
  Como mudar: se a Eplast quiser conversa já na v1, a extensão do `SFAgent2` entra como fase 2, e aí o envio de dados ao LLM vira decisão LGPD própria.

- [x] **PA-2. Entidade que representa a compra (card item 4).**
  Pergunta: pedido ou oportunidade ganha?
  Decisão: pedido (`Order`).
  Evidência: `Opportunity` tem 0 registros na dev, enquanto `Order` tem `ProtheusId__c` (vínculo com o ERP) e status próprio (confirmado hoje).
  Como mudar: trocar a entidade na regra de compra, mantendo a janela e a classificação.

- [x] **PA-3. Status que contam como compra (card item 4).**
  Pergunta: quais status contam?
  Decisão: `Order.Status` em `Faturamento` ou `Concluido`. Excluídos: `Cancelado` e os estágios de processo (`Revisao de Pedido`, `Liberacao Financeiro`, `Liberacao Estoque`).
  Evidência: picklist de `Order.Status` confirmado hoje. O significado dos valores foi inferido pelo nome (incerteza I-1). `Faturamento` como marco de compra é coerente com o relatório `PEDIDOS FATURADOS - GARRAFA`.
  Como mudar: a lista de status fica em parâmetro (RF-5).

- [x] **PA-4. Data da compra (card item 4).**
  Pergunta: qual data vale?
  Decisão: `Order.EffectiveDate`.
  Evidência: campo padrão confirmado hoje. A recon anterior indica que o `SFAgent2` usa `MAX(EffectiveDate)`.
  Como mudar: trocar o campo de data no parâmetro.

- [x] **PA-5. Janela de recuperação e categoria "nunca comprou" (card item 4).**
  Pergunta: qual a janela e como tratar contas inativas?
  Decisão: 60 dias sem compra válida gera "Recuperação". Conta sem nenhuma compra válida vai para "Nunca comprou", separada.
  Evidência: CENÁRIO 9 do `SFAgent2` usa 60 dias. CENÁRIO 4 separa "nunca comprou" (recon anterior via RAG). Regra 3 da conta.
  Como mudar: parâmetro de janela (CA-17). Se o `eplast-ent-11` definir outra régua, muda o parâmetro (PA-12).

- [x] **PA-6. Volume: métrica, base e limiar (Q6).**
  Pergunta: qual métrica, base de comparação e limiar?
  Decisão: métrica é a soma de `Order.TotalAmount` (valor). Base é 3 meses atuais contra 3 meses anteriores. Limiar é 30%, com comparação estrita (mais de 30%), para queda e para alta. Conta sem pedidos na base não entra em volume.
  Evidência: queda acima de 30% e `SUM(TotalAmount)` são da régua do `SFAgent2` (STEP 7D, recon anterior via RAG). A **alta** não existe no agente. Ela é simétrica à queda, sem evidência direta na org. Por isso fica marcada.
  Como mudar: limiar e direção (queda, alta ou ambas) são parâmetros. `Volume1__c` não é usado, porque não tem descrição nem unidade confirmada.

- [x] **PA-7. Cruzada: grupo, produto e limiar (Q7 e Q8).**
  Pergunta: qual grupo de referência, qual fonte de produto e qual frequência conta?
  Decisão: grupo é `Account.Industry`. Produto vem do histórico de pedidos (`OrderItem.Product2Id`), não do CPQ. Oportunidade quando 30% ou mais das contas do grupo compraram o produto P nos últimos 12 meses e a conta não comprou P nos últimos 180 dias. Conta sem Industry fica fora. Grupo com menos de 5 contas não gera cruzada.
  Evidência: `Account.Industry` é campo padrão e existe. Fonte por histórico evita depender de catálogo CPQ, que não foi verificado. A dev tem 0 contas com Industry, então o preenchimento e a distribuição não foram verificados (incerteza I-4). Os números 30%, 12 meses, 180 dias e 5 contas são defaults provisórios, sem número na org.
  Como mudar: grupo (região ou canal, se a Eplast preferir) e todos os limiares são parâmetros.

- [x] **PA-8. Carteira e acesso (Q10).**
  Pergunta: como se define a carteira?
  Decisão: a lista respeita o compartilhamento do próprio usuário (`WITH USER_MODE` e sharing padrão). Não há hierarquia própria nesta versão.
  Evidência: padrão do Salesforce. O OWD não foi medido pelo assessment (risco 7 acima).
  Como mudar: se a Eplast quiser visão por gestor, a hierarquia de papéis entra como regra nova.

- [x] **PA-9. Somente leitura na v1 (RN-5 da análise anterior).**
  Pergunta: a identificação só lê ou gera registros?
  Decisão: só lê. Não cria, altera nem exclui Account, Opportunity, Order ou OrderItem. Não cria trigger, Flow nem e-mail no CRM. A saída é relatório ou lista sobre dados existentes. Se o design precisar de tabela própria, isso volta ao gate do arquiteto como decisão de design.
  Evidência: achado 1 do assessment (automação concorrente em Order) e o padrão de guarda do squad.
  Como mudar: escrita (por exemplo, tarefa para o vendedor) só entra em fase posterior, com a ordem de execução mapeada.

- [x] **PA-10. Marketing (regra 2 da conta; card item 2).**
  Pergunta: a recuperação inclui envio de mensagem?
  Decisão: a lista é o público ou segmento. O envio (e-mail, jornada, nutrição) é do Marketing Cloud, operado pela Eplast. O CRM não dispara nada.
  Evidência: regra 2 da conta e o card de 2026-11-13. O pacote Marketing Cloud Connect (`et4ae5`) está instalado (assessment, inventário). Quem opera o Marketing Cloud está fora da esteira, que só alcança as sandboxes do CRM.
  Como mudar: não aplicável. Só muda a forma de exportar a lista.

- [x] **PA-11. Qualidade dos pedidos do Protheus (Q12).**
  Pergunta: os pedidos chegam completos e atualizados?
  Decisão: assume-se que sim. A validação é feita pelo Comercial sobre amostra na homologação (CA-18).
  Evidência: `Order.ProtheusId__c` existe. A dev não tem pedidos, então não é possível verificar agora, e produção não é consultada por guardrail.
  Como mudar: se a amostra falhar, corrige-se a regra de fonte ou o status, sem mudar o desenho.

- [x] **PA-12. Relação com `eplast-ent-11` e demais demandas (Q1 e Q5).**
  Pergunta: EPLAST-33 é entrega própria, extensão de `eplast-ent-11` ou parte de outra demanda?
  Decisão: entrega própria, que usa a mesma régua de 60 dias do `SFAgent2` para não gerar duas listas de "sem compra" diferentes. A sobreposição com EPLAST-26, 27, 28, 32 e 47 vai para o recon e o design (seção 3).
  Evidência: `eplast-ent-11` citado na análise anterior via RAG. Não foi lido nesta sessão (incerteza I-6).
  Como mudar: se `eplast-ent-11` definir outra régua, muda o parâmetro. Se definir a lista inteira, EPLAST-33 vira extensão dela.

- [x] **PA-13. Métrica de sucesso e dados na saída (Q9 e Q11).**
  Pergunta: qual o critério de negócio e quais campos a saída pode mostrar?
  Decisão: o aceite técnico é por fixture (CA-01 a CA-17). O aceite de negócio é a amostra do Comercial (CA-18). A saída mostra ID e nome da conta, tipo, métrica e datas. Não mostra e-mail, telefone nem CPF (CA-14).
  Evidência: guardrail 2 do squad (LGPD) e minimização. Não há métrica de negócio no card.
  Como mudar: a Eplast pode aprovar outros campos ou pedir métrica de negócio adicional (taxa de conversão, por exemplo) em homologação.

- [x] **PA-14. Frequência de atualização (Q13).**
  Pergunta: sob demanda, diária ou semanal?
  Decisão: recálculo diário, agendado fora do horário comercial. Recuperação e volume também podem ser lidos a qualquer hora no relatório.
  Evidência: a org já usa agendamento para cálculo de Order e Opportunity (`OrderScheduledFlow` e `ScheduledFlowOpportunity`, confirmados hoje).
  Como mudar: periodicidade é parâmetro do agendamento.

- [x] **PA-15. Notificação e orçamento de IA (Q14, Q16).**
  Pergunta: há notificação ao vendedor? Há orçamento de créditos de IA?
  Decisão: sem notificação na v1, porque o card não pede. Sem IA generativa na v1 (PA-1), então o orçamento de créditos não bloqueia.
  Evidência: escopo do card e PA-1.
  Como mudar: notificação entra como demanda própria, com canal definido. Se o `SFAgent2` entrar na fase 2, o orçamento volta a ser verificado.

**Pendências (`- [ ]`):** nenhuma. Nenhuma pergunta de negócio está sem resposta, sem caminho na org ou no padrão, e com erro caro ou difícil de desfazer (caso 3 da regra 4). As decisões acima são fáceis de mudar por parâmetro.

## 9. Perguntas de negócio

Nenhuma bloqueante. As perguntas Q1 a Q16 da análise anterior foram resolvidas nas premissas PA-1 a PA-15. Ficam para a homologação com a Eplast: os limiares de cruzada, a alta de volume e a amostra de CA-18.

## 10. Incertezas declaradas

- **I-1.** Significado dos valores de `Order.Status` inferido pelo nome. Sem descrição confirmada.
- **I-2.** Dev vazia (0 Account, 0 Order, 0 Opportunity, confirmado hoje). Nenhuma regra foi testada com dado real. Os limiares são exemplos de fixture.
- **I-3.** Régua de 60 dias e de 30% do `SFAgent2` vem da recon anterior, via RAG. Não foi relida no metadata do agente nesta sessão. Status `Inactive` das versões do agente (EPLAST-25 e 27) também não foi reconfirmado hoje, porque `BotDefinition` não é consultável nesta org.
- **I-4.** `Account.Industry` existe, mas o preenchimento e a distribuição por grupo não foram verificados.
- **I-5.** Conteúdo dos relatórios de pedido e a lógica de `ScheduledFlowOpportunity` e `OrderScheduledFlow` não foram lidos. A sobreposição (seção 3) depende de leitura no recon.
- **I-6.** `contrato.md` e `eplast-ent-11` não foram lidos nesta sessão. A informação sobre eles vem da análise anterior, via RAG.
- **I-7.** Alias `sbx-eplast-dev` com username `...eplast2.qa` (risco 6). Não resolvido. Condição para o build.
- **I-8.** OWD, compartilhamento e volume real de pedidos não foram medidos (assessment).

## 11. Complexidade e esforço

**Complexidade: G.** Três regras de cálculo sobre Order e OrderItem. A cruzada exige agregação grupo por produto em batch, com teste de cobertura, numa org com cobertura de 10% e dois triggers em Order. Se a cruzada sair da v1, a complexidade cai para M.

**Estimativa de esforço:** 60–110 h
Premissas que mais pesam na faixa:
- Fixture de Order e Account em QA com as 23 validation rules de Order (dev vazia). Pode ficar na ponta alta.
- Batch Apex da cruzada, com `<Classe>Test` a 85% e revisão de ordem de execução em Order.
- Homologação com amostra do Comercial e uma rodada de ajuste de limiar.
- Não inclui a extensão do `SFAgent2` (fase 2) nem a notificação.
- Não inclui a resolução do alias dev/qa (risco 6), que é um passo de verificação antes do build.

O arquiteto refina no design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
