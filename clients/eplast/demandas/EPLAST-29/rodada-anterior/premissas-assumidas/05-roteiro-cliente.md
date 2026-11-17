# EPLAST-29 · Roteiro de teste: criar tarefas pelo assistente de IA

O assistente de IA (SFAgent2) agora cria **tarefas** por comando em texto, ligadas a uma conta ou oportunidade. Antes de gravar, ele mostra um resumo e espera a sua confirmação. Ele **não envia** e-mail nem mensagem: guarda o texto como rascunho dentro da tarefa. Não cria contas, oportunidades nem pedidos.

**Situação do teste automático:** o time executou na QAS os testes 1 a 6 e 8 (criar com confirmação, recusar, conta repetida, pedido sem data, rascunho de e-mail sem envio, pedido fora do escopo), com contas sintéticas, e passaram. O **Teste 7 (usuário sem permissão)** não foi executado: não há na QAS um usuário comercial comum com licença do assistente. Fica para quem segue este roteiro. A consulta de pedidos foi só verificada por amostra.

## Antes de começar
- Ambiente: sandbox QAS da Eplast.
- Perfil: um usuário comercial (ex.: Comercial - Analista) com o conjunto de permissões "Assistente de ações comerciais" e licença do assistente. Para o Teste 7, outro usuário comercial **sem** esse conjunto.
- Dados: crie 3 contas de teste: uma chamada "TESTE EPLAST-29 Conta Unica" e duas chamadas "TESTE EPLAST-29 Conta Dup" (mesmo nome). Apague-as ao final.
- Abra o assistente de IA pelo ícone do assistente no Salesforce.

## Teste 1 — Criar tarefa com confirmação
1. Digite: "Criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 20/11/2026".
2. Leia o resumo. Abra a conta e confira a aba Atividades: ainda não há tarefa nova.
3. Responda "sim" (e confirme se aparecer um cartão de confirmação).
4. Atualize a conta e veja Atividades.

**Resultado esperado:** o resumo mostra assunto "Follow-up" e vencimento 20/11/2026. Após confirmar, existe 1 tarefa "Follow-up", vencimento 20/11/2026, relacionada à conta, com você como responsável e, na descrição, "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Digite: "Criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 25/11/2026".
2. Quando aparecer o resumo, responda "não, cancela".

**Resultado esperado:** o assistente diz que a tarefa não foi criada. Na conta não surge tarefa com vencimento 25/11/2026.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Duas contas com o mesmo nome
1. Digite: "Criar tarefa para TESTE EPLAST-29 Conta Dup".

**Resultado esperado:** o assistente lista as duas contas com identificador e pede para escolher. Nenhuma tarefa é criada até a escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Pedido sem data
1. Digite: "Criar tarefa de ligar para TESTE EPLAST-29 Conta Unica".
2. Responda "sem data".

**Resultado esperado:** o assistente pede a data (pode sugerir a de hoje) e insiste nela. Ele não diz que criou a tarefa e nenhuma tarefa aparece na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Rascunho de e-mail, sem envio
1. Digite: "Preciso de um rascunho de e-mail de proposta comercial em tarefa para TESTE EPLAST-29 Conta Unica, vencimento em 11/12/2026. Texto: Prezado, segue proposta de 100 kg de resina."
2. Responda "sim" e, se pedido, confirme.
3. Abra a conta e a tarefa criada.

**Resultado esperado:** a tarefa "Rascunho de e-mail - ..." existe, vencimento 11/12/2026, com o texto na descrição e "Origem: assistente de IA". Nenhum e-mail é enviado (nada em e-mails enviados da conta) e o assistente avisa que o envio é feito fora do Salesforce.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Pedido fora do escopo
1. Digite: "Criar oportunidade para TESTE EPLAST-29 Conta Unica".

**Resultado esperado:** o assistente informa que criar oportunidades, contas ou pedidos não está disponível e oferece criar uma tarefa. Nenhuma oportunidade nova na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Usuário sem permissão
1. Entre com o usuário comercial **sem** o conjunto "Assistente de ações comerciais".
2. Peça: "Criar tarefa de follow-up para TESTE EPLAST-29 Conta Unica com vencimento em 20/11/2026" e confirme.

**Resultado esperado:** o pedido é recusado com mensagem de permissão, sem criar tarefa e sem mostrar nomes ou dados de registros que esse usuário não enxerga.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Consultas já existentes continuam
1. Pergunte: "quantos pedidos a conta TESTE EPLAST-29 Conta Unica tem?".
2. Pergunte sobre uma conta real que você pode ver, por exemplo um total de pedidos.

**Resultado esperado:** o assistente responde normalmente, como antes.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Só tarefas:** o assistente cria apenas tarefas, ligadas a conta ou oportunidade. Contas, oportunidades, pedidos e eventos ficam de fora. Concorda?
- **E-mail e mensagem não saem pelo Salesforce:** viram rascunho na tarefa; o envio é feito pelo Marketing Cloud (marketing) ou pelo próprio usuário. Concorda?
- **Sempre confirmar antes de gravar.** Pode ser afrouxado depois, para tarefas simples.
- **Responsável é sempre quem pede:** não dá para atribuir a outra pessoa pelo assistente.
- **Campos obrigatórios:** assunto, registro relacionado e vencimento. Prioridade "Normal" e status "Aberta" por padrão.
- **Tarefa de check-in não é criada pelo assistente** (ela altera a conta e entra na cadeia de integração).
- **Marca de origem:** "Origem: assistente de IA" na descrição, sem campo novo.
- **Acesso:** por um conjunto de permissões novo, atribuído por usuário, mais a licença do assistente. Nenhum perfil novo.
- **Volume baixo de uso** e sem métrica de negócio no aceite; sem log próprio das conversas.

## O que não dá para conferir pela tela
O comportamento do assistente varia um pouco de conversa para conversa. O time repetiu os pedidos 14 vezes na QAS e registrou o que apareceu em `05-testes.md`. Se numa conversa o assistente disser "criada" e a tarefa não existir, anote como não conforme.
