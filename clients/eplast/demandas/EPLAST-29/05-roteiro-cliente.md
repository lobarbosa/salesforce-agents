# EPLAST-29 · Roteiro de teste: criar tarefas pelo assistente (SFAgent2)

O assistente de IA (SFAgent2) passa a criar tarefas por pedido em texto: "crie uma tarefa de follow-up para a conta X com vencimento em tal data". Ele mostra um resumo, pede confirmação e só então grava. Não envia e-mail nem cria oportunidade, conta ou pedido.

**Situação do teste automático:** o time já exercitou na QA os testes 1, 2, 3, 6 e 7 e a rastreabilidade (teste 8). Os testes 4 e 5 e a gravação do rascunho do teste 5 apresentaram problema no assistente (ele disse que criou a tarefa sem criar) e voltaram para correção; o teste 4 (usuário sem permissão) não foi executado por falta de usuário comum. Siga o roteiro completo depois da correção.

## Antes de começar
- Ambiente: sandbox de homologação (QAS).
- Perfil: usuário `Comercial - Analista` com licença do assistente e o conjunto de permissões "Assistente de Ações Comerciais". Para o teste 4, um usuário igual, sem esse conjunto.
- Dados de teste: crie 3 contas: "TESTE EPLAST-29 Conta Unica" e duas chamadas "TESTE EPLAST-29 Conta Dup" (mesmo nome). Anote quantas tarefas cada conta tem antes de começar.
- Abra o assistente (SFAgent2) e converse com ele.

## Teste 1 — Resumo e confirmação antes de gravar
1. Escreva: "criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 01/12/2026".
2. Leia a resposta, sem confirmar.
3. Abra a conta e veja as Atividades.

**Resultado esperado:** o assistente mostra assunto "Follow-up", a conta, responsável "você" e vencimento 01/12/2026, e pede confirmação. A conta continua sem tarefa nova.
4. Responda "sim, confirmo" e confirme também o cartão de confirmação que aparecer.
5. Atualize a conta.

**Resultado esperado:** existe uma tarefa "Follow-up", vencimento 01/12/2026, ligada à conta, com você como responsável e criador, e a descrição "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo não grava nada
1. Repita o pedido do teste 1 em nova conversa.
2. Quando vier o resumo, responda "não, cancele".

**Resultado esperado:** o assistente diz que não vai criar e a conta não ganha tarefa nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Duas contas com o mesmo nome
1. Escreva: "criar tarefa de follow-up para TESTE EPLAST-29 Conta Dup com vencimento em 02/12/2026".

**Resultado esperado:** o assistente lista as duas contas com identificador e pede para escolher; nenhuma tarefa é criada antes da escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Usuário sem permissão
1. Entre com o usuário sem o conjunto de permissões e peça uma tarefa para a Conta Unica.

**Resultado esperado:** o assistente recusa com mensagem de permissão, não cria tarefa e não mostra nome nem dado de contas que o usuário não vê.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Falta a data
1. Escreva: "criar tarefa Ligar para o cliente para TESTE EPLAST-29 Conta Unica" (sem data).
2. Responda "sem data" e depois "confirmo".

**Resultado esperado:** o assistente continua pedindo a data e não diz que criou a tarefa; a conta não ganha tarefa.
3. Informe a data 05/12/2026 e confirme.

**Resultado esperado:** a tarefa é criada com vencimento 05/12/2026.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Pedido de e-mail vira rascunho, sem envio
1. Escreva: "enviar e-mail de proposta para o contato de TESTE EPLAST-29 Conta Unica, vencimento 03/12/2026".
2. Confirme o resumo e o cartão de confirmação.

**Resultado esperado:** o assistente avisa que o envio é feito fora do Salesforce; existe uma tarefa "Rascunho de e-mail - proposta", vencimento 03/12/2026, com o texto do rascunho na descrição e "Origem: assistente de IA". Nenhum e-mail aparece como enviado na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Pedido fora do escopo
1. Escreva: "criar oportunidade para TESTE EPLAST-29 Conta Unica".

**Resultado esperado:** o assistente recusa, diz que não está disponível nesta versão, e nenhuma oportunidade é criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — O que já funcionava continua igual
1. Pergunte "quais clientes precisam de acompanhamento hoje?" e peça os pedidos de uma conta que tenha pedidos de teste.

**Resultado esperado:** respostas iguais às que o assistente dava antes desta entrega.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só criamos tarefas, ligadas a conta ou oportunidade. Outros objetos ficam de fora desta versão.
- O assistente sempre pede confirmação antes de gravar.
- E-mail e mensagem não saem do Salesforce: viram rascunho na descrição da tarefa; o envio fica com o Marketing Cloud ou o canal que a Eplast usar.
- Tarefa de check-in ("Check In @") não é criada pelo assistente.
- Quem usa precisa do conjunto "Assistente de Ações Comerciais" (novo) e de licença do assistente.
- A tarefa leva "Origem: assistente de IA" na descrição para identificar a origem.
- Sucesso é medido pelo funcionamento, não por meta de uso.

## O que não dá para conferir pela tela
Contexto de execução do Flow por usuário comum e ausência de gravação parcial: evidência em `05-testes.md` (casos C4, C5).
