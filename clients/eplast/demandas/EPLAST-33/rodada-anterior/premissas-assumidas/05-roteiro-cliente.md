# EPLAST-33 — Roteiro de teste: oportunidades comerciais por conta

Foi entregue uma lista que mostra, para cada conta, uma oportunidade comercial: **Recuperação** (parou de comprar), **Nunca comprou**, **Queda de volume**, **Alta de volume** e **Cruzada** (produto que contas parecidas compram e esta ainda não). A lista é só para consulta e exportação: nada é alterado em contas, pedidos ou oportunidades, e nenhuma mensagem é enviada pelo Salesforce.

**Situação do teste automático:** o time comprovou na QAS: os testes técnicos (41 de 41 passam, com os limites de 59/60/61 dias, 30%/31% e grupos de 4/5 contas); a geração da lista sobre a base da QAS (637 contas "Nunca comprou", 530 "Recuperação", 169 "Queda de volume", 22 "Alta de volume", todas dentro das regras); e que contas, pedidos e e-mails não mudaram. Ficaram para quem segue este roteiro: ver a lista e o relatório na tela (a QAS só tem contas reais, que o time não abre), a visibilidade por usuário e a conferência do Comercial com o Protheus. Nenhuma conta ficou com "Cruzada" na QAS: nenhum produto chega a 30% de um grupo; a regra foi comprovada só por teste técnico, por isso o Teste 8 usa dados de teste.

## Antes de começar
- Ambiente: sandbox QAS da Eplast.
- Perfil: usuário comercial com o conjunto de permissões "Sinais Comerciais" (peça ao administrador). Sem ele a lista não aparece, e isso também é um teste (Teste 5).
- Dado de teste: crie uma conta chamada "TESTE EPLAST-33 A" com o campo Setor preenchido (ex.: Bebidas) e um pedido com data de início de 61 dias atrás e status "Faturamento". Crie outra, "TESTE EPLAST-33 B", sem pedidos. A lista é recalculada uma vez por dia (de madrugada, 04:00 UTC, 01:00 em Brasília); os testes que dependem de dados novos só aparecem depois do recálculo seguinte.

## Teste 1 — Conta que parou de comprar aparece como Recuperação
1. Abra a aba "Sinais Comerciais" (ou o relatório "Sinais Comerciais por Conta" na pasta "EPLAST33 Sinais Comerciais").
2. Procure por "TESTE EPLAST-33 A".

**Resultado esperado:** tipo "Recuperação", dias sem compra igual a 61 (ou mais, conforme o dia), com a data da última compra e o motivo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Conta com compra há 59 dias não é Recuperação
1. Crie uma conta de teste com um pedido "Concluido" de 59 dias atrás.
2. Após o recálculo, procure a conta na lista.

**Resultado esperado:** a conta não aparece como "Recuperação".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conta sem pedidos aparece como Nunca comprou
1. Procure "TESTE EPLAST-33 B" na lista.
2. Crie outra conta de teste só com pedidos "Cancelado" ou "Revisao de Pedido" e procure-a depois do recálculo.

**Resultado esperado:** tipo "Nunca comprou" nas duas contas; nenhuma aparece como "Recuperação".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Queda e alta de volume só acima de 30%
1. Conta de teste com pedidos somando 10.000 nos 3 meses anteriores e 7.000 nos últimos 3 meses (queda de exatamente 30%). Confira a lista após o recálculo.
2. Altere o valor atual para 6.900 (queda de 31%) e confira após o recálculo seguinte.
3. Repita com alta: 13.000 (30%) e depois 13.100 (31%).

**Resultado esperado:** 30% não gera nada; 31% gera "Queda de volume" (percentual 31) ou "Alta de volume". Conta sem pedidos nos 3 meses anteriores não entra em volume.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Quem não tem permissão não vê a lista
1. Entre com um usuário sem o conjunto de permissões "Sinais Comerciais".
2. Tente abrir a aba "Sinais Comerciais" e o relatório.
3. Entre com um usuário com a permissão que não tenha acesso à "TESTE EPLAST-33 A" e procure-a na lista.

**Resultado esperado:** passo 2: a aba não aparece ou nenhum registro é mostrado. Passo 3: a conta que ele não vê não aparece na lista. Quem tem acesso à conta vê os sinais dela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Colunas sem dado de contato
1. Abra o relatório "Sinais Comerciais por Conta".
2. Exporte para Excel.

**Resultado esperado:** colunas de conta (ID e nome), Classificação, produto, dias sem compra, valores, variação, datas, motivo e tipo. Sem e-mail, telefone ou CPF, tanto na tela quanto na exportação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Pedido novo tira a conta da Recuperação
1. Na conta "TESTE EPLAST-33 A", crie um pedido "Faturamento" com data de hoje.
2. Após o recálculo seguinte, confira a lista.

**Resultado esperado:** a conta deixa de aparecer como "Recuperação". A conta não aparece duplicada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Cruzada por produto
1. Num grupo de 10 contas do mesmo Setor (use um Setor de teste), 4 compraram o produto P nos últimos 12 meses; uma conta do grupo não comprou P há mais de 180 dias.
2. Após o recálculo, confira essa conta.

**Resultado esperado:** tipo "Cruzada" com o produto P. Se só 2 de 10 compraram, nada de cruzada para P; grupo com menos de 5 contas, também não; conta sem Setor, não; conta que comprou P há 90 dias, não.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Os dados da conta não mudam
1. Anote o "Última modificação" de uma conta de teste antes e depois do recálculo.

**Resultado esperado:** igual; nenhum e-mail enviado pelo Salesforce.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — A lista bate com o Protheus (homologação do Comercial)
1. O Comercial escolhe uma amostra de contas e compara com o histórico do Protheus.

**Resultado esperado:** o Comercial aprova ou aponta as divergências.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Compra = pedido com status "Faturamento" ou "Concluido"; "Cancelado" e os estágios de processo não contam. Data da compra = data de início do pedido.
- Recuperação: mais de 60 dias sem compra. Conta que nunca comprou aparece em categoria separada, que pode ser desligada.
- Volume: soma do valor dos pedidos, 3 meses atuais (móveis, a partir do dia do cálculo) contra os 3 anteriores; queda ou alta só acima de 30% (30% exato não entra).
- Cruzada: contas parecidas = mesmo Setor; 30% ou mais do grupo comprou o produto nos últimos 12 meses; a conta não comprou nos últimos 180 dias; grupo mínimo de 5 contas; no máximo 10 sugestões por conta. Conta sem Setor fica fora da cruzada. Com esses números, hoje nenhuma conta da QAS recebe "Cruzada": confirme se a régua de 30% é adequada.
- Todas as contas entram, inclusive as que nunca compraram (prospects).
- Cada pessoa vê só as contas a que já tem acesso; o cálculo usa a base inteira.
- A lista é só leitura e é recalculada todo dia às 04:00 UTC (01:00 em Brasília); o envio de e-mail ou jornada é feito pelo Marketing Cloud, por quem o opera, a partir da lista exportada.
- Sem notificação ao vendedor e sem assistente de IA nesta versão.
- Todos os números acima podem ser mudados por configuração, sem programação.

## O que não dá para conferir pela tela
Cobertura de testes técnicos, a execução agendada de 16/11 às 01:20 UTC, a conferência de que contas, pedidos e e-mails não mudaram e a ausência de Flow ou gatilho novo: evidência em `05-testes.md`.
