# EPLAST-29 · Roteiro de teste — Criar tarefas pelo assistente de IA

O assistente de IA (SFAgent2) passa a criar **tarefas** vinculadas a um lead, cliente (conta) ou oportunidade, a partir de um pedido escrito, sempre mostrando um resumo e pedindo sua confirmação antes de gravar. E-mail e mensagem não são enviados pelo Salesforce: o assistente grava o texto como rascunho dentro de uma tarefa.

**Situação do teste automático:** nada foi comprovado nesta rodada. A versão corrigida do assistente (v17) não chegou ao ambiente de teste, então os testes abaixo não foram executados pelo time e todos ficam para quem segue o roteiro, depois que a versão estiver instalada. O Teste 5 (usuário sem permissão) só pode ser feito por quem tiver usuário comum.

## Antes de começar
- Ambiente: sandbox de QA da esteira (na Eplast, a "QAS").
- Perfil: usuário com acesso ao assistente e com o conjunto de permissões "Assistente de Ações Comerciais" atribuído.
- Dados de teste: um lead chamado `REG-TESTE-LEAD-01`, dois leads chamados `REG-TESTE-DUP`, uma conta `REG-TESTE-DUP`. Se não existirem, peça ao time técnico para criá-los. Não use registros reais.
- Anote quantas tarefas o `REG-TESTE-LEAD-01` tem antes (aba Atividades do registro).

## Teste 1 — Criar tarefa com confirmação
1. Abra o assistente de IA.
2. Digite: "criar tarefa de follow-up para REG-TESTE-LEAD-01 com vencimento em [uma data futura]".
3. Leia o resumo mostrado, antes de responder.
4. Confira que o número de tarefas do registro ainda é o mesmo.
5. Responda "sim".
6. Abra o registro e veja a aba Atividades.

**Resultado esperado:** o resumo traz assunto, registro (nome e tipo), responsável (você), descrição e vencimento, e aparece antes da gravação. Depois do "sim", há uma tarefa a mais, com a data informada, você como responsável e, na descrição, "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Repita o pedido do Teste 1.
2. Quando o resumo aparecer, responda "não".
3. Confira as tarefas do registro.

**Resultado esperado:** nenhuma tarefa nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Nome repetido
1. Digite: "criar tarefa para REG-TESTE-DUP".

**Resultado esperado:** o assistente lista os candidatos com tipo e identificador e pede que você escolha; nenhuma tarefa é criada antes da escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Falta informação
1. Digite: "criar tarefa para REG-TESTE-LEAD-01" (sem data).
2. Responda "sim" se pedir confirmação.

**Resultado esperado:** o assistente pergunta a data; nenhuma tarefa parcial é criada e ele não diz que criou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Usuário sem permissão
1. Entre com um usuário comum, sem o conjunto "Assistente de Ações Comerciais".
2. Peça a criação de uma tarefa para REG-TESTE-LEAD-01.

**Resultado esperado:** o pedido é recusado com mensagem de permissão, sem nenhuma tarefa criada e sem mostrar nomes ou dados de registros que o usuário não vê.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — E-mail não é enviado
1. Digite: "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01" e informe o texto e a data, se pedir.
2. Confirme.
3. Veja a tarefa criada e o histórico de e-mails do registro.

**Resultado esperado:** nenhum e-mail enviado; a tarefa guarda o texto como rascunho na descrição; o assistente avisa que o envio é feito fora do Salesforce e pede revisão.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Pedido fora do escopo
1. Digite: "criar oportunidade para REG-TESTE-LEAD-01".

**Resultado esperado:** o assistente informa que criar oportunidade não está disponível; nada é criado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — O que já existia continua funcionando
1. Pergunte: "quais clientes precisam de acompanhamento hoje?" e faça uma consulta de pedidos.

**Resultado esperado:** respostas iguais às de antes da mudança.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só tarefas são criadas (lead, conta e oportunidade); evento, conta, oportunidade e pedido ficam de fora.
- Todo pedido pede confirmação antes de gravar.
- E-mail e mensagem não saem pelo Salesforce: ficam como rascunho na tarefa; o envio é pelo Marketing Cloud ou pelo próprio usuário.
- Quem usa: quem tem o conjunto de permissões "Assistente de Ações Comerciais"; nenhum perfil novo.
- A marca "Origem: assistente de IA" na descrição indica a origem; o responsável é quem fez o pedido. Não há campo novo.
- Uso de baixo volume; sem meta de negócio definida por ora.
- O conteúdo fica só na tarefa; retenção da conversa segue o padrão da plataforma.

## O que não dá para conferir pela tela
- Que nada saiu por e-mail em nível de sistema, e que a versão correta do assistente está ativa: só o time técnico confere. Evidência em `05-testes.md`.
