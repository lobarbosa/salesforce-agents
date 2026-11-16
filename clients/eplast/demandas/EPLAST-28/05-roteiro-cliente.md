# Roteiro de teste — Aviso de oportunidade parada (EPLAST-28)

**O que foi entregue.** Todo dia, às 7h (horário de Brasília), o Salesforce confere as oportunidades abertas. Quando uma oportunidade completa 14 dias sem atividade registrada e sem mudança de estágio, o dono dela recebe um aviso no sino de notificações. O aviso só aparece dentro do Salesforce: não sai e-mail nem mensagem, e nada na oportunidade, na conta ou no pedido é alterado.

**O que muda para quem usa.** O vendedor recebe um aviso, uma vez, no dia em que a oportunidade completa o prazo. Não precisa fazer nada para ligar.

**Situação do teste automático:** o agendamento foi armado na sandbox de QA e rodou uma vez (confirmado pelo time), e não houve alteração indevida em oportunidades, contas, pedidos, tarefas ou eventos. Mas o time não conseguiu comprovar que o aviso apareceu no sino, e por isso esta rodada ficou reprovada e volta para correção. Os testes 1 e 2 abaixo ainda precisam ser conferidos por você pela tela. Os demais dependem de data (dia seguinte) ou de usuário com gestor. A regra de 14 dias não dá para exercitar na sandbox sem esperar; os testes usam um prazo curto, e o time informa antes qual está configurado.

## Antes de começar
- **Ambiente:** sandbox de QA da esteira, que a Eplast chama de QAS (eplast--qas). Nunca em produção.
- **Perfil:** dono das oportunidades de teste. Para o teste 5, um usuário que não seja dono delas.
- **Dados de teste:** Conta "TESTE EPLAST-28 Conta" e oportunidades "TESTE EPLAST-28 A parada...", "B atividade...", "C sem atividade" e "D fechada parada". Se precisar recriar: crie a conta; crie oportunidades abertas no estágio Qualificado, com você como dono, e para cada uma uma Tarefa com a data desejada (a data da tarefa conta como atividade). Peça ao time o prazo configurado e a data em que o aviso será gerado.

## Teste 1 — Oportunidade parada recebe o aviso
1. Entre na sandbox de QA com o dono das oportunidades de teste.
2. Clique no sino de notificações, no alto da tela.
3. Procure um aviso "Oportunidade parada há N dias" (N é o prazo de teste).

**Resultado esperado:** um aviso para a oportunidade cuja última atividade completa exatamente N dias, com nome da oportunidade, "TESTE EPLAST-28 Conta", "Estágio: Qualificado" e a data da última atividade. Ao clicar, abre a oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Atividade recente e oportunidade fechada não geram aviso
1. No sino, procure aviso para a oportunidade "C sem atividade" (criada há pouco) e para "D fechada parada".

**Resultado esperado:** nenhum aviso para elas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Sem atividade nenhuma
1. Abra "C sem atividade" e veja a data de criação.
2. Quando ela completar o prazo desde a criação, confira o sino.

**Resultado esperado:** o aviso sai no dia em que completa o prazo contado da data de criação, e não antes.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Sem repetição
1. No dia seguinte ao aviso, abra o sino do dono.

**Resultado esperado:** nenhum segundo aviso da mesma oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Só o dono recebe
1. Entre com um usuário que não é dono das oportunidades de teste e abra o sino.

**Resultado esperado:** nenhum aviso das oportunidades de teste.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nada alterado, sem e-mail
1. Abra uma oportunidade que recebeu aviso; veja o histórico de campos e a lista de atividades.
2. Confira a caixa de e-mail do dono.

**Resultado esperado:** nenhuma alteração de campo nem atividade nova criada pelo aviso, e nenhum e-mail.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Aviso ao gestor (só se o gestor estiver ligado)
1. Peça ao time para ligar a opção de avisar o gestor e use um dono que tenha gestor cadastrado.
2. Confira o sino do gestor após o disparo.

**Resultado esperado:** o gestor também recebe o aviso. Com a opção desligada (padrão), não recebe.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Definição de parada:** sem atividade registrada e sem mudança de estágio por N dias, valendo a data mais recente das duas. Dá para mudar para "só atividade" por configuração.
- **Tarefas automáticas contam como atividade.**
- **Prazo único de 14 dias** para todos os estágios (configurável).
- **Canal e frequência:** só notificação dentro do Salesforce, avaliação diária, um aviso por oportunidade parada.
- **Gestor:** não recebe por padrão; pode ser ligado por configuração, e só tem efeito se o dono tiver gestor cadastrado.
- **O aviso não cria tarefa** nem altera nada na oportunidade.
- **Oportunidades elegíveis:** todas as abertas, de qualquer tipo de registro.
- **Conteúdo do aviso:** nome da oportunidade, conta, estágio, dias parada e link.
- **Complementa o assistente de IA (SFAgent2):** ele não foi alterado; a regra deste aviso passa a ser a referência.

## O que não dá para conferir pela tela
- Execução do agendamento e ausência de gravação nos objetos de negócio: evidência em `demandas/EPLAST-28/05-testes.md` (contagens e histórico do agendamento).
- Carga com muitas oportunidades e a regra completa de 14 dias com estágio: dependem de volume e de datas antigas; ficam para o time técnico.
