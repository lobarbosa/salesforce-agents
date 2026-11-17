# EPLAST-29 · Roteiro de teste: assistente que cria tarefas

O assistente de IA (o mesmo que já consulta pedidos) passa a criar **tarefas** para você, por conversa: ligadas a um lead, a um cliente ou a uma oportunidade. Antes de gravar, ele mostra um resumo e espera o seu "sim". E-mails e mensagens viram só **rascunho** dentro da tarefa; nada é enviado pelo Salesforce.

**Situação do teste automático:** o time exercitou o assistente na sandbox de QA. Comprovado: criar tarefa de lead com confirmação, lista de nomes repetidos, pedido de data faltante, recusa de criar oportunidade, recusa de assunto "Check In @", rascunho de e-mail sem envio, e as consultas que já existiam. **Ainda com defeito, em correção pelo time:** em alguns pedidos o assistente diz "tarefa criada" sem criar, em outros não acha o lead, e o resumo antes do "sim" não mostra o registro nem o responsável. **Não conferido por falta de usuário comum na QA:** o acesso negado (Teste 8). Este roteiro descreve o comportamento esperado.

## Antes de começar
- **Ambiente:** a sandbox de QA da Eplast (a "QAS"), nunca produção.
- **Perfil:** use um usuário comercial comum com acesso ao assistente. Para o Teste 8, um segundo usuário **sem** o conjunto de permissões "PS Comercial Assistente Ações" (peça ao administrador).
- **Dados de teste:** crie, pelo menu Leads, os leads: "REG-TESTE-LEAD-01" (empresa "REG-TESTE Empresa 01"); dois leads com o mesmo nome "REG-TESTE-DUP". Use só esses nomes, nunca um cliente real.
- Abra o assistente (ícone de IA da Lightning) e use frases como as dos testes.

## Teste 1 — Criar tarefa com confirmação
1. Digite: "criar tarefa de follow-up para o lead REG-TESTE-LEAD-01 com vencimento em 2026-12-01".
2. Leia o resumo que o assistente mostra.
3. Abra o lead, aba Atividades, e confira que ainda **não há** tarefa.
4. Volte ao assistente e responda "sim, confirmo".
5. Atualize o lead e abra a aba Atividades.

**Resultado esperado:** o resumo mostra assunto "Follow-up", o lead (nome e tipo), responsável "você", descrição (ou "sem descrição") e vencimento 01/12/2026. Só depois do "sim" aparece uma tarefa "Follow-up", vencimento 01/12/2026, responsável você, e a descrição termina com "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Peça uma tarefa "ligar de volta" para REG-TESTE-LEAD-01 com vencimento em 2026-12-02.
2. Responda "não, cancela".
3. Confira as Atividades do lead.

**Resultado esperado:** o assistente diz que a tarefa não foi criada e nenhuma tarefa nova aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Nome repetido
1. Digite: "criar tarefa para REG-TESTE-DUP com vencimento em 2026-12-03".

**Resultado esperado:** o assistente lista os candidatos (nome, tipo e identificador) e pede que você escolha. Nenhuma tarefa é criada até a escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Falta a data
1. Digite: "criar tarefa de follow-up para o lead REG-TESTE-LEAD-01" (sem data).

**Resultado esperado:** o assistente pergunta a data de vencimento e não cria nada. Se você só responder "sim", ele **não** pode dizer que criou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Rascunho de e-mail
1. Digite: "enviar e-mail de proposta para o contato do lead REG-TESTE-LEAD-01, vencimento 2026-12-07, texto padrão de proposta comercial".
2. Confirme com "sim".
3. Abra a tarefa criada.

**Resultado esperado:** tarefa "Rascunho de e-mail - proposta comercial" com o texto na descrição e "Origem: assistente de IA". O assistente avisa que nada foi enviado e que o envio é feito fora do Salesforce. Nenhum e-mail aparece como enviado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — O que o assistente não faz
1. Digite: "criar oportunidade para REG-TESTE-LEAD-01".
2. Digite: "criar tarefa com assunto Check In @ cliente para REG-TESTE-LEAD-01 com vencimento em 2026-12-09".
3. Digite: "criar tarefa para o lead REG-TESTE-LEAD-01 amanhã, responsável Maria".

**Resultado esperado:** o assistente recusa criar oportunidade (diz que não está disponível nesta etapa), recusa o assunto "Check In @" e recusa criar tarefa para outra pessoa. Nada é gravado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — O que já existia continua funcionando
1. Pergunte "quantos pedidos abertos temos?".
2. Pergunte "qual a próxima ação para a conta" de um cliente de teste.

**Resultado esperado:** respostas normais, como antes da mudança (sem erro).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Usuário sem permissão
1. Entre com o usuário que não tem o conjunto "PS Comercial Assistente Ações".
2. Peça a criação de uma tarefa para REG-TESTE-LEAD-01.

**Resultado esperado:** o assistente recusa com mensagem de permissão, não cria tarefa e não mostra dados de registros que o usuário não enxerga.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- [ ] **Só tarefas.** O assistente cria apenas tarefas, ligadas a lead, cliente ou oportunidade. Compromisso, conta, oportunidade e pedido ficam fora. Para mudar, é uma nova demanda.
- [ ] **E-mail e mensagem são só rascunho.** O texto vai na descrição da tarefa; o envio é feito pelo Marketing Cloud (comunicação de marketing) ou pelo próprio usuário (contato individual). O Salesforce não envia.
- [ ] **Sempre pede confirmação** antes de gravar. Dá para afrouxar depois para tarefas simples.
- [ ] **Quem usa:** SDR, vendedores e executivos, pós-vendas e gestão comercial, com as permissões de cada um. O acesso é dado pelo conjunto "PS Comercial Assistente Ações", atribuído pelo administrador.
- [ ] **A tarefa fica sempre com você** como responsável; não é possível criar para outra pessoa.
- [ ] **A origem fica registrada** na descrição ("Origem: assistente de IA"); não há campo novo.
- [ ] **Lead já convertido** não recebe tarefa pelo assistente; peça na conta.
- [ ] **Regras ajustáveis sem programação** (pelo administrador, em Configurações): ligar ou desligar a criação, quais tipos de registro aceitos, se a descrição é obrigatória e o texto da marca de origem.
- [ ] **Uso de baixo volume** e conversas guardadas pelo padrão da plataforma; sem registro próprio.

## O que não dá para conferir pela tela
A ativação das versões na QA e as contagens de tarefa e de e-mail antes e depois estão registradas em `05-testes.md`, que também traz os defeitos em correção. Volume e tempo de resposta não foram medidos.
