# EPLAST-29 · Roteiro de teste — Criar tarefas pelo assistente de IA

O assistente de IA (SFAgent2) passou a criar tarefas por comando em texto. O vendedor pede, o assistente mostra um resumo e só grava depois da confirmação. E-mail e mensagem não são enviados pelo Salesforce: o assistente grava o texto como rascunho dentro de uma tarefa.

**Situação do teste automático:** na QA, a nova versão do assistente está instalada, mas ainda não ativada; por isso o time não conseguiu executar os testes lá. Na sandbox de desenvolvimento, a maior parte passou (criar com confirmação, recusar, nome repetido, dado faltando, rascunho de e-mail, recusar oportunidade). O acesso negado e a comparação das consultas antigas não foram provados. Os testes abaixo só valem depois que a nova versão estiver ativa no ambiente.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (QAS).
- Perfil: usuário comercial que tenha o acesso "Assistente de ações comerciais"; e, para o Teste 4, um usuário sem esse acesso.
- Dado de teste: crie duas Contas "TESTE EPLAST-29 Conta Unica" (uma só) e duas com o nome "TESTE EPLAST-29 Conta Dup". Não use contas reais.

## Teste 1 — Criar tarefa com confirmação
1. Abra o assistente de IA.
2. Digite: "criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 01/12/2026".
3. Leia o resumo, sem confirmar. Abra a Conta e confira que não há tarefa nova.
4. Volte e responda "sim".
**Resultado esperado:** o resumo mostra assunto, conta, responsável (você) e vencimento 01/12/2026. Só depois do "sim" aparece uma tarefa "Follow-up" na conta, vencimento 01/12/2026, responsável você, com a descrição terminando em "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Peça outra tarefa para a mesma conta (vencimento 05/12/2026).
2. Quando o assistente pedir confirmação, responda "não, cancele".
**Resultado esperado:** o assistente informa o cancelamento e nenhuma tarefa nova aparece na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conta com nome repetido
1. Digite: "criar tarefa para TESTE EPLAST-29 Conta Dup".
**Resultado esperado:** o assistente lista as duas contas com identificador e pede para escolher. Nenhuma tarefa é criada antes da escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Usuário sem permissão
1. Entre com o usuário sem acesso e peça uma tarefa para "TESTE EPLAST-29 Conta Unica".
**Resultado esperado:** o assistente recusa com mensagem de permissão, não cria tarefa e não mostra dados de registros que o usuário não vê.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Informação faltando
1. Digite: "criar tarefa para TESTE EPLAST-29 Conta Unica" (sem assunto e sem data) e responda "confirmo".
**Resultado esperado:** o assistente pergunta o assunto e a data; nenhuma tarefa é gravada até informar.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Pedido de e-mail
1. Digite: "enviar e-mail de proposta para o contato de TESTE EPLAST-29 Conta Unica, vencimento 10/12/2026, texto: Olá, segue proposta de teste." e confirme.
**Resultado esperado:** nenhum e-mail é enviado. Aparece a tarefa "Rascunho de e-mail - Proposta" com o texto na descrição e "Origem: assistente de IA". O assistente avisa que o envio é feito fora do Salesforce.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Pedido fora do escopo
1. Digite: "criar oportunidade para TESTE EPLAST-29 Conta Unica".
**Resultado esperado:** o assistente recusa, dizendo que não está disponível nesta versão; nada é criado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Assunto "Check In @"
1. Peça uma tarefa com assunto "Check In @ visita".
**Resultado esperado:** o assistente recusa e pede outro assunto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Consultas que já existiam
1. Pergunte: "quais clientes precisam de acompanhamento hoje?".
2. Peça: "consultar pedidos da conta TESTE EPLAST-29 Conta Unica".
**Resultado esperado:** o assistente responde como antes da mudança (identifica a conta e consulta pedidos).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só tarefas ligadas a Conta ou Oportunidade; pedido para outros objetos (ex.: Pedido) fica fora.
- E-mail e mensagem viram rascunho dentro de uma tarefa; o envio é feito pelo Marketing Cloud ou pelo usuário, nunca pelo Salesforce.
- Assunto "Check In @" é bloqueado.
- O assistente só grava depois da confirmação, e a tarefa fica com você como responsável e traz "Origem: assistente de IA".
- O acesso é dado por um conjunto de permissões ("Assistente de ações comerciais"), que também libera a leitura das consultas do assistente.
- Sem Oportunidade, Conta ou Pedido criados ou alterados nesta versão.
Se algo disso não é como a Eplast trabalha, anote em "Não conforme".

## O que não dá para conferir pela tela
A ativação da versão do assistente e a conferência da licença de IA são do time técnico. Evidência da situação atual da QA: `05-testes.md`.
