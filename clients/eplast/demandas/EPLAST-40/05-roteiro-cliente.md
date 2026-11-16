# EPLAST-40: Roteiro de teste, ciclo Marketing, SDR, Comercial e Pós-vendas

**O que foi entregue:** a Oportunidade passa sozinha de "Qualificação" para "Qualificado" quando dois itens estão marcados, e, ao ser ganha, gera um caso de Pós-vendas numa fila própria. O Lead de marketing segue o fluxo atual, sem envio de e-mail pelo CRM.

**Situação do teste automático:** comprovado na QA: Lead novo, mudança para Contatado, qualificação da Oportunidade, criação do caso de Pós-vendas sem duplicar e preservação dos opt-outs. Não comprovado: conversão do Lead em Oportunidade (barrada pela regra de catálogo de preço), tela do layout e acesso por perfil não administrador. Esses ficam para quem segue o roteiro. Veredito do time técnico: reprovado nesta rodada, pela conversão sem evidência.

## Antes de começar
- Ambiente: sandbox QAS (eplast--qas). Perfil: Administrador, com o conjunto de permissões "Atendimento Pós-vendas" para ver o campo Oportunidade no Caso.
- Crie uma Conta de teste "TESTE EPLAST-40 Conta" com um catálogo de preços próprio da conta, e um Lead "TESTE EPLAST-40 Lead" com origem "E-mail MKT". Marque nele os opt-outs de e-mail e de celular.

## Teste 1 — Lead de marketing entra no funil
1. Abra Leads e clique em Novo.
2. Preencha sobrenome, empresa e origem "E-mail MKT". Salve.

**Resultado esperado:** Status "Aberto - Não contatado" e origem "E-mail MKT".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — SDR marca primeiro contato
1. No Lead, altere o Status para "Contatado". Salve.

**Resultado esperado:** Status "Contatado", sem Oportunidade criada, opt-outs iguais aos de antes.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conversão gera a Oportunidade
1. No Lead "Contatado", clique em Converter, usando a Conta de teste.
2. Abra a Oportunidade criada.

**Resultado esperado:** Oportunidade na etapa "Qualificação", com a mesma origem do Lead; Lead com Status "Fechado - Convertido". Se aparecer "Catálogo de preço selecionado inválido", anote abaixo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Qualificado só com os dois critérios
1. Crie uma Oportunidade na etapa "Qualificação".
2. Marque só "Discovery Completed" e salve.
3. Marque também "Budget Confirmed" e salve.

**Resultado esperado:** após o passo 2 continua "Qualificação"; após o passo 3 passa para "Qualificado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Oportunidade ganha gera caso de Pós-vendas
1. Leve uma Oportunidade "Qualificado" (com os campos obrigatórios) para "Fechado/Ganho".
2. Abra a lista "Pós-vendas" em Casos.

**Resultado esperado:** 1 caso "Pós-vendas: <nome da Oportunidade>", Status "New", proprietário "Pós-vendas", Conta preenchida. Nenhuma Order nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Sem duplicar
1. Volte a Oportunidade para "Qualificado" e feche de novo como "Fechado/Ganho".

**Resultado esperado:** continua 1 só caso para essa Oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Tela da Oportunidade
1. Abra a Oportunidade de teste do Teste 5.

**Resultado esperado:** a lista relacionada de Casos (campo Oportunidade) aparece no layout "Opportunity Layout" e mostra o caso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Fila com atendente
1. Em Configuração, abra Filas, "Pós-vendas".

**Resultado esperado:** pelo menos 1 membro. Hoje a fila está sem membros: a Eplast precisa defini-los antes da homologação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Estágios: usamos os existentes (Status do Lead, Etapa da Oportunidade, Status do Caso), sem estágio SDR novo.
- Passagem SDR para Comercial é a conversão do Lead.
- Oportunidade vira "Qualificado" com "Discovery Completed" e "Budget Confirmed" marcados.
- Pós-vendas começa quando a Oportunidade é "Fechado/Ganho"; a venda continua registrada pela Order.
- Casos de Pós-vendas vão para uma fila nova "Pós-vendas"; quem a atende vocês definem.
- Sem aviso ao vendedor e sem prazo (SLA) nesta versão.
- A data da passagem para Pós-vendas é a data de criação do caso.
- Disparos de e-mail e nutrição ficam com o Marketing Cloud; nada é enviado pelo CRM.

## O que não dá para conferir pela tela
Volume (200 Oportunidades em lote) e consumo de processamento foram medidos na dev, em `04-verificacao.md`. Detalhes técnicos da QA estão em `05-testes.md`.
