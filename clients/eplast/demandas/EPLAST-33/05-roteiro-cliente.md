# EPLAST-33 — Roteiro de teste: oportunidades comerciais por conta

**O que foi entregue.** Uma lista diária de oportunidades por conta, gravada no objeto "Sinal Comercial", com um relatório pronto. Cada conta é classificada como Recuperação (mais de 90 dias sem compra faturada), Nunca comprou, Queda de volume (por família de produto, mês fechado contra a média dos 3 meses anteriores, queda de 20% ou mais), Histórico insuficiente ou Cruzada (família que o segmento da conta compra e ela não). Nada é enviado ao cliente: a lista é só leitura e serve de base para o Marketing montar público no Marketing Cloud.

**Situação do teste automático:** comprovado na QAS: os componentes estão na org, os parâmetros estão nos valores combinados (90 dias, 20%) e a suíte de testes automáticos passa sem falhas, com cobertura acima de 96%. **Ainda não comprovado:** o cálculo diário sobre as contas da QAS. Ele foi agendado para 17/11 às 11:41 (horário de Brasília) e será conferido pelo time depois disso. Os testes abaixo, feitos por quem homologa, só valem depois dessa conferência. A ação do assistente (agente) ficou fora desta entrega.

## Antes de começar
- Ambiente: sandbox QAS da Eplast.
- Perfil: usuário do Comercial com o conjunto de permissões "Sinais Comerciais Comercial" atribuído. Para o Teste 6, um segundo usuário sem acesso a uma das contas.
- Dado de teste: escolha 3 contas de teste (nome começando por "TESTE EPLAST-33") com: (a) um pedido "Faturamento" há mais de 90 dias e nenhum depois; (b) nenhum pedido; (c) pedidos "Cancelado" ou "Revisão de Pedido" apenas. Peça ao time técnico para criá-las, se não existirem, e para rodar o cálculo depois.

## Teste 1 — Conta sem compra há mais de 90 dias aparece como Recuperação
1. Abra a aba "Sinais Comerciais".
2. Procure pela conta de teste (a).
3. Confira o tipo e os dias sem compra.

**Resultado esperado:** tipo "Recuperação"; dias sem compra maior que 90; data da última compra igual à do pedido faturado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Conta sem pedido faturado aparece como Nunca comprou
1. Na mesma aba, procure as contas de teste (b) e (c).
2. Confira o tipo.

**Resultado esperado:** as duas aparecem como "Nunca comprou", e nenhuma como "Recuperação". Pedido cancelado ou em processo não conta como compra.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Queda de volume por família
1. Abra o relatório "Sinais Comerciais por Conta" (pasta "Sinais Comerciais").
2. Filtre pelo tipo "Queda de volume".
3. Escolha uma linha de conta de teste e confira as colunas família, valor do período atual, valor da base, quantidade, unidade e variação.

**Resultado esperado:** a variação é de 20% ou mais de queda (20,0% entra; 19,99% não); família e unidade preenchidas; quando a família mistura unidades, a unidade aparece como "MISTA" e a quantidade fica em branco. Não aparece "Alta de volume" (está desligada).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Histórico insuficiente
1. No relatório, filtre pelo tipo "Histórico insuficiente".
2. Escolha uma conta de teste que comprou a família em menos de 2 dos 3 meses de base.

**Resultado esperado:** a conta aparece como "Histórico insuficiente" e não recebe queda de volume para essa família. Conta em Recuperação ou Nunca comprou não recebe sinal de volume.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Venda cruzada por segmento
1. No relatório, filtre pelo tipo "Cruzada" e agrupe por segmento.
2. Escolha uma conta e confira a família sugerida.

**Resultado esperado:** a família sugerida é comprada por 30% ou mais das contas do mesmo segmento (grupos de 5 contas ou mais) e a conta não a comprou em 180 dias; conta sem segmento não aparece em Cruzada; nunca é sugerida a família "Sem família". Você pode filtrar por estado (UF de cobrança) na tela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Cada usuário vê só as contas a que tem acesso
1. Com o usuário que tem acesso à conta X, abra a lista e procure a conta X.
2. Com o usuário sem acesso à conta X, repita.

**Resultado esperado:** o primeiro vê a conta X; o segundo não.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — A lista não traz dado de contato
1. Abra o relatório e veja as colunas disponíveis.

**Resultado esperado:** só identificação da conta, tipo, métricas e datas. Sem e-mail, telefone nem CPF.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Conferência da amostra com o Protheus (Comercial)
1. Escolha 5 contas da lista (Recuperação e Nunca comprou).
2. Compare com o histórico de pedidos faturados no Protheus.

**Resultado esperado:** a data da última compra e a classificação batem. Se não baterem, anote a conta e a diferença.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- A "data da compra" é a "Data de emissão" do pedido. Se o campo de data da nota for mais fiel, é troca de parâmetro, sem programação.
- "Faturado" significa pedido em status Faturamento ou Concluído. Se "Faturamento" for "em faturamento", basta tirá-lo.
- O alerta de queda usa o valor; a quantidade aparece ao lado. Famílias com unidades misturadas mostram "MISTA".
- Família de produto é o campo "Grupo" do produto (PREF, TAMP, RESI, ALCA, GPET); produto sem grupo entra como "Sem família".
- Histórico insuficiente: a conta comprou a família em menos de 2 dos 3 meses de base.
- Conta em Recuperação ou Nunca comprou não recebe alerta de volume.
- Venda cruzada sugere a família, não o item; a compatibilidade técnica (rosca, gargalo) fica com o vendedor, pois a org não tem essa tabela.
- Região é a UF de cobrança, usada só como filtro no relatório.
- Recuperação a partir de 91 dias. Cálculo diário, sem notificação, até 10 cruzadas por conta.
- Marketing: o disparo é do Marketing Cloud, feito por quem o opera. O CRM só traz a lista.

## O que não dá para conferir pela tela
O cálculo diário (agendamento), a ausência de escrita em contas e pedidos, a cobertura dos testes automáticos e a ausência de e-mail disparado pelo CRM são conferidos pelo time técnico. A evidência está em `05-testes.md`.
