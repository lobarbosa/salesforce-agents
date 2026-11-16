# EPLAST-41 · Roteiro de teste: rascunho de texto com IA

Foi entregue um botão "Rascunho com IA" nas contas e nas oportunidades. Com ele, o vendedor pede à IA um rascunho de mensagem de relacionamento ou de texto comercial, revisa na tela e, se quiser, salva como tarefa no registro. O sistema não envia nada: o envio continua sendo feito pelo Marketing Cloud.

**Situação do teste automático:** o time abriu a tela na QA e confirmou que o botão aparece no menu da conta. Não conseguiu comprovar a geração do texto nem o salvamento, porque a tela não avançou do primeiro passo e a geração de texto retornou erro. Todos os testes abaixo ficam para quem segue o roteiro, depois da correção. O caso de oportunidade/comercial não foi testado por falta de licença de cotação para o usuário do time.

## Antes de começar
- Ambiente: sandbox QAS (a "QAS" da Eplast).
- Perfil: um usuário que recebeu o acesso "Rascunho com IA" (pedir ao administrador).
- Dados de teste: crie uma conta chamada "TESTE EPLAST-41 Conta A" e, nela, uma oportunidade aberta "TESTE EPLAST-41 Opp aberta". Crie também uma conta "TESTE EPLAST-41 Conta B" sem nenhuma oportunidade. Use só dados fictícios.

## Teste 1 — O botão aparece
1. Abra a conta "TESTE EPLAST-41 Conta A".
2. Clique na seta ao lado de "Excluir" (mais ações).

**Resultado esperado:** aparece "Rascunho com IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Gerar mensagem de relacionamento
1. Na conta A, clique em "Rascunho com IA".
2. Marque "Mensagem de relacionamento" e clique em "Próximo".
3. Em "Tipo e objetivo da mensagem", escreva "agradecimento pós-venda" (sem nomes, e-mail ou telefone) e avance.

**Resultado esperado:** em até 30 segundos aparece "Rascunho gerado" com um texto editável que você consegue selecionar e copiar. Nada foi criado no registro até agora (confira a linha do tempo da conta: nenhuma tarefa nova).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Salvar como tarefa
1. Na tela do texto, escolha "Salvar como tarefa" e finalize.
2. Volte para a conta e abra a linha do tempo.

**Resultado esperado:** mensagem "Tarefa criada no registro com o texto do rascunho. Nenhum envio foi feito." Existe uma única tarefa "Rascunho de relacionamento (IA)", aberta, sem data, com o texto na descrição.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Fechar sem salvar
1. Gere um novo rascunho na conta A.
2. Escolha "Fechar sem salvar" e finalize.

**Resultado esperado:** aparece "Nada foi gravado." e nenhuma tarefa nova na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Texto comercial a partir da conta
1. Na conta A, clique em "Rascunho com IA", marque "Texto comercial (proposta, follow-up, argumentos)" e avance.
2. Escolha a oportunidade "TESTE EPLAST-41 Opp aberta" se for pedido.

**Resultado esperado:** o texto comercial é gerado a partir da oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta sem oportunidade
1. Abra a conta "TESTE EPLAST-41 Conta B".
2. Clique em "Rascunho com IA", marque "Texto comercial" e avance.

**Resultado esperado:** "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." Nada é criado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — A partir da oportunidade
1. Abra "TESTE EPLAST-41 Opp aberta" e clique em "Rascunho com IA".
2. Gere um texto comercial e salve como tarefa.

**Resultado esperado:** tarefa "Rascunho comercial (IA)" criada na oportunidade, com o texto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nenhum envio
1. Depois dos testes 3 e 7, procure e-mails enviados no registro (aba de atividades).

**Resultado esperado:** nenhum e-mail foi criado ou enviado por esta função.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- "Textos comerciais" são os três já existentes (proposta, follow-up e argumentos). Não há um quarto tipo.
- Na mensagem de relacionamento, quem escreve decide livremente o tipo e o objetivo, em texto livre. Não há lista fixa de tipos.
- O texto só pode ser gerado a partir de conta e oportunidade (não de pedido nem de contato).
- O texto aprovado vira uma tarefa no registro, aberta e sem data, com assunto "Rascunho de relacionamento (IA)" ou "Rascunho comercial (IA)". Nada é enviado.
- A IA não recebe nome de contato, e-mail, telefone nem CPF; só dados comerciais da conta. Na mensagem de relacionamento, não vão valores de oportunidade.
- Quem usa é quem receber o grupo de acesso "Rascunho com IA", definido pelo administrador.
- O sistema não bloqueia a geração para quem pediu para não receber e-mails. Essa regra é aplicada no envio, pelo Marketing Cloud.
- A IA generativa está habilitada na QAS.
- Se alguma dessas decisões não servir, avise na homologação.

## O que não dá para conferir pela tela
- Que a conexão com o Marketing Cloud não foi alterada e que o agente "SFAgent2" continua intacto: o time conferiu por contagem e lista de componentes (`05-testes.md`).
