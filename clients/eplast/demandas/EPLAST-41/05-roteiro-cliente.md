# EPLAST-41 · Roteiro de teste: rascunho de texto com IA

Foi entregue a ação **Rascunho com IA** na tela da Conta (e da Oportunidade). O vendedor pede um texto de relacionamento ou comercial, a IA escreve um rascunho, a pessoa revisa e escolhe entre salvar como tarefa ou fechar sem salvar. O sistema não envia nada: o envio continua sendo feito pelo Marketing Cloud.

**Situação do teste automático:** o time executou na sandbox de QA os testes 1, 2, 3 e 5 (rascunho de relacionamento, salvar como tarefa, nada gravado ao fechar, conta sem oportunidade) e conferiu que nenhum e-mail foi criado. O Teste 4 (texto comercial de uma conta com oportunidade aberta) não foi executado: exige um perfil comercial que o time não consegue atribuir a si. Fica para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (QAS).
- Perfil: usuário comercial com o grupo de permissões "Comercial Rascunho IA" (ou o conjunto de relacionamento).
- Dados de teste: crie uma conta com nome "TESTE EPLAST-41 Conta A", com os campos obrigatórios preenchidos, e nela uma oportunidade aberta "TESTE EPLAST-41 Opp aberta". Crie também a conta "TESTE EPLAST-41 Conta B sem oportunidade", sem nenhuma oportunidade. Use só dados fictícios.

## Teste 1 — Gerar um rascunho de relacionamento
1. Abra a conta "TESTE EPLAST-41 Conta A".
2. Clique em "Mostrar mais ações" e depois em "Rascunho com IA".
3. Em "Tipo de texto", marque "Mensagem de relacionamento" e clique em "Avançar".
4. No campo de objetivo, escreva "Agradecer a parceria e apresentar novidades do catálogo" e clique em "Avançar".
5. Aguarde até 30 segundos.

**Resultado esperado:** aparece o aviso "Rascunho gerado por IA. Revise antes de usar. O envio é feito pelo Marketing Cloud, não por aqui." e a caixa "Texto (edite e copie como precisar)" com um texto de mensagem. Você consegue editar e copiar o texto. Não aparece nome, e-mail nem telefone de contato inventado por você.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Salvar o texto como tarefa
1. Continue na tela do Teste 1, com o texto na tela.
2. Em "O que fazer com o texto?", marque "Salvar como tarefa" e clique em "Avançar".
3. Feche a janela e veja a linha do tempo de atividades da conta.

**Resultado esperado:** existe uma tarefa "Rascunho de relacionamento (IA)", em aberto, ligada à conta "TESTE EPLAST-41 Conta A", e a descrição da tarefa traz o texto gerado. Nenhum e-mail aparece registrado na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Fechar sem salvar não grava nada
1. Na conta "TESTE EPLAST-41 Conta A", abra "Rascunho com IA" e gere um novo texto de relacionamento (passos 2 a 5 do Teste 1).
2. Em "O que fazer com o texto?", deixe "Fechar sem salvar" e clique em "Avançar".

**Resultado esperado:** a tela diz "Nada foi gravado." e nenhuma tarefa nova com "(IA)" aparece na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Texto comercial a partir de uma oportunidade aberta
1. Na conta "TESTE EPLAST-41 Conta A", abra "Rascunho com IA".
2. Marque "Texto comercial (proposta, follow-up, argumentos)" e clique em "Avançar".
3. Escolha a oportunidade "TESTE EPLAST-41 Opp aberta" e o tipo de texto (proposta, follow-up ou argumentos), se solicitado, e avance até o texto aparecer.
4. Marque "Salvar como tarefa" e avance.

**Resultado esperado:** aparece um texto comercial; ao salvar, existe uma tarefa "Rascunho comercial (IA)" ligada ao registro de origem, com o texto na descrição.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta sem oportunidade
1. Abra a conta "TESTE EPLAST-41 Conta B sem oportunidade".
2. Abra "Rascunho com IA", marque "Texto comercial (proposta, follow-up, argumentos)" e clique em "Avançar".

**Resultado esperado:** a tela diz "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." e nenhuma tarefa é criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nada é enviado por e-mail
1. Depois dos testes 1 a 4, abra a conta e veja a linha do tempo e a lista de e-mails.

**Resultado esperado:** nenhum e-mail enviado ou registrado pelo uso de "Rascunho com IA". A mensagem só será enviada se alguém a copiar para o Marketing Cloud.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- O texto de relacionamento tem tipo e objetivo escritos livremente pela pessoa (não há lista fechada de tipos). Se preferirem uma lista, avise.
- O texto salvo vai para uma tarefa, não para um e-mail. A tarefa nasce em aberto e sem data; quem usar o texto a conclui. Se preferirem que nasça concluída, avise (pode contar como acompanhamento da oportunidade).
- Os títulos das tarefas são "Rascunho de relacionamento (IA)" e "Rascunho comercial (IA)".
- A mensagem de relacionamento usa só dados da conta e da oportunidade (nome, etapa, tipo, datas); não usa valores nem dados pessoais de contatos. O texto comercial usa os mesmos dados que já usava.
- A IA não confere se o contato recusou e-mail: quem respeita essa recusa é o Marketing Cloud, no envio.
- Quem vê a ação é quem receber o grupo de permissões "Comercial Rascunho IA", atribuído pelo administrador da Eplast depois da entrega.
- O recurso de IA generativa está habilitado na organização.

## O que não dá para conferir pela tela
- Que nenhum componente do conector do Marketing Cloud foi alterado e que não existe cópia de modelos de texto: comprovado pelo time em `05-testes.md` (casos C6 e C10).
- A quantidade de e-mails registrados antes e depois do teste (805 e 805) e o conteúdo exato da tarefa criada: `05-testes.md`, caso C2 e C4.
