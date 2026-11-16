# EPLAST-41 · Roteiro de teste: rascunho de mensagem de relacionamento e texto comercial

Foi entregue um botão "Rascunho com IA" na Conta e na Oportunidade. Ele escreve um rascunho de mensagem de relacionamento ou de texto comercial. Nada é enviado pelo Salesforce, e nada é gravado até você clicar em salvar.

**Situação do teste automático:** comprovado: o modelo gera o texto em cerca de 3 segundos; o botão aparece no menu da Conta; nenhum e-mail é criado. Não comprovado: a navegação da tela, o salvamento e o caso de oportunidade, porque a tela da QA não mostrou botão para avançar. Os testes 1 a 6 ficam para quem segue o roteiro, depois da correção.

## Antes de começar
- Ambiente: sandbox QAS.
- Perfil: usuário com a permissão "Rascunho Comercial" (a mesma do rascunho comercial).
- Crie uma conta de teste chamada "TESTE EPLAST-41 Conta A" com uma oportunidade aberta, e outra chamada "TESTE EPLAST-41 Conta B" sem oportunidade. Use só dados fictícios.

## Teste 1 — Gerar mensagem de relacionamento
1. Abra "TESTE EPLAST-41 Conta A".
2. Clique em "Mostrar mais ações" e depois em "Rascunho com IA".
3. Marque "Mensagem de relacionamento".
4. Clique no botão para avançar e escreva o objetivo, por exemplo "agradecimento pós-venda".
5. Avance para gerar o texto.

**Resultado esperado:** o texto aparece na tela em até 30 segundos e pode ser copiado. Nenhuma tarefa nova aparece na conta ainda.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Salvar como tarefa
1. Com o texto na tela, clique em salvar.
2. Abra a aba de atividades da conta.

**Resultado esperado:** existe uma tarefa nova na conta, com o texto salvo na descrição. Nenhum e-mail foi registrado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Nada é enviado
1. Depois dos testes 1 e 2, olhe a conta e suas atividades.

**Resultado esperado:** nenhum e-mail enviado ou agendado, e nada novo no Marketing Cloud.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Conta sem oportunidade
1. Abra "TESTE EPLAST-41 Conta B".
2. Abra "Rascunho com IA", escolha "Texto comercial" e avance.

**Resultado esperado:** a tela avisa que não há oportunidade e não gera texto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Texto comercial a partir da oportunidade
1. Abra a oportunidade aberta da Conta A.
2. Clique em "Rascunho com IA" e escolha o texto comercial (proposta, follow-up ou argumentos).

**Resultado esperado:** o texto aparece e pode ser copiado. Pode ser salvo como tarefa na oportunidade quando a versão nova da tela comercial estiver ativa; antes disso, só copiar.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Quem não tem a permissão
1. Entre com um usuário sem a permissão "Rascunho Comercial".
2. Abra a Conta A.

**Resultado esperado:** o usuário não consegue gerar o rascunho.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- "Textos comerciais" são os três já existentes: proposta, follow-up e argumentos. Não há um quarto tipo.
- O tipo de mensagem de relacionamento é texto livre digitado pelo usuário, sem lista fixa.
- O rascunho sai de Conta e Oportunidade. Pedido e Contato ficam de fora.
- O texto salvo vira tarefa na Conta ou Oportunidade, sem e-mail registrado.
- O nome, e-mail, telefone e CPF do contato nunca vão para a IA.
- Quem usa o rascunho é quem tem a permissão "Rascunho Comercial", a mesma do rascunho comercial.
- O rascunho não é bloqueado para contato que pediu para não receber e-mail. O Marketing Cloud respeita isso no envio.
- A geração por IA está habilitada na organização.

## O que não dá para conferir pela tela
Contagem de e-mails (805 antes e depois), único agente SFAgent2 e ausência de alteração no pacote do Marketing Cloud foram conferidos pelo time técnico; a evidência está em `05-testes.md`.
