# EPLAST-29 · Roteiro de teste: assistente que cria tarefas

O assistente de IA (SFAgent2) passa a criar tarefas de leads, clientes (contas) e oportunidades a partir de uma frase, sempre mostrando um resumo e só gravando depois do seu "sim". Para quem usa, muda que não é preciso abrir o registro e preencher a tarefa à mão. O assistente não envia e-mail nem mensagem: guarda o texto como rascunho dentro da tarefa.

**Situação do teste automático:** nesta rodada o time **não conseguiu comprovar** as correções. A versão corrigida do assistente (v17) ainda não está no ambiente de testes (QA), então os testes 1, 4 e 6 abaixo podem apresentar os defeitos já conhecidos até ela ser colocada lá. Na rodada anterior foram comprovados: criação com confirmação, recusa sem gravar, registro duplicado, data faltando, oportunidade recusada e responsável fixo. Não foi comprovado o teste com usuário comum (Teste 7), que fica para quem segue este roteiro.

## Antes de começar
- Ambiente: o de testes (QAS), nunca produção.
- Perfis: um usuário comum da área comercial (que não seja administrador) com o conjunto de permissões "Assistente de ações comerciais" atribuído, e outro sem ele.
- Dados de teste: lead "REG-TESTE-LEAD-01"; dois leads chamados "REG-TESTE-DUP" e uma conta "REG-TESTE-DUP"; um lead convertido "REG-TESTE-LEAD-CONV". Já existem na QAS; se faltar, peça ao time técnico para recriá-los.
- Abra o assistente pelo painel do Salesforce.

## Teste 1 — Criar tarefa com confirmação
1. Digite: "criar tarefa de follow-up para REG-TESTE-LEAD-01 com vencimento em 01/12/2026".
2. Leia o resumo antes de responder.
3. Responda "sim, confirmo".
4. Abra o lead e veja as atividades.

**Resultado esperado:** antes do "sim", o resumo mostra assunto "Follow-up", o registro (REG-TESTE-LEAD-01, tipo lead), responsável "você", descrição ("sem descrição") e prazo 01/12/2026, e nenhuma tarefa nova existe. Depois do "sim", há uma tarefa nova com vencimento 01/12/2026, dona é você, descrição com "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Peça "criar tarefa de ligar de volta para REG-TESTE-LEAD-01 com vencimento amanhã".
2. Responda "não, cancela".

**Resultado esperado:** o assistente diz que a tarefa não foi criada e o lead não ganha tarefa nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Nome repetido
1. Digite "criar tarefa para REG-TESTE-DUP com vencimento em 03/12/2026".

**Resultado esperado:** o assistente lista 3 opções (2 leads e 1 cliente) com o tipo e o identificador de cada uma, pede para escolher e não grava nada antes disso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Tarefa sem descrição
1. Digite "criar tarefa de revisar contrato para REG-TESTE-LEAD-01 com vencimento em 05/12/2026, sem descrição" e responda "sim, confirmo".
2. Abra a tarefa criada.

**Resultado esperado:** o campo de descrição traz só "Origem: assistente de IA", sem o texto "sem descrição".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Falta a data
1. Digite "criar tarefa de follow-up para REG-TESTE-LEAD-01".

**Resultado esperado:** o assistente pergunta a data de vencimento e não cria tarefa.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Pedido de e-mail
1. Digite "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01" (sem data e sem texto) e responda "sim".
2. Depois digite o mesmo pedido com "vencimento hoje, texto padrão de proposta comercial" e confirme.

**Resultado esperado:** no passo 1 o assistente pede a data (não diz que criou nada). No passo 2 cria uma tarefa com o texto do e-mail como rascunho na descrição e avisa que nada foi enviado e que o envio é feito fora do Salesforce. Nenhum e-mail sai.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Usuário sem permissão
1. Entre com um usuário comum sem o conjunto "Assistente de ações comerciais".
2. Peça uma tarefa para REG-TESTE-LEAD-01.
3. Repita com um usuário comum que tenha o conjunto.

**Resultado esperado:** sem o conjunto, o assistente recusa sem mostrar dados de registros que o usuário não vê; com ele, cria normalmente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Fora do escopo e responsável
1. Digite "criar oportunidade para REG-TESTE-LEAD-01".
2. Digite "criar tarefa ... amanhã, responsável Maria".
3. Peça a tarefa para o lead convertido REG-TESTE-LEAD-CONV.

**Resultado esperado:** 1) recusa, só tarefa está disponível; 2) recusa criar tarefa para outra pessoa; 3) não grava (orienta pedir pela conta).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — O que já existia continua funcionando
1. Pergunte "quantos pedidos abertos temos?" e "qual a próxima ação para a conta REG-TESTE-DUP?".

**Resultado esperado:** respostas normais, sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Tarefa de lead fica ligada só ao lead (a plataforma não permite ligar a outro campo).
- Lead já convertido é recusado; o assistente orienta pedir na conta ou oportunidade.
- O resumo sempre mostra a descrição, mas ela não é obrigatória (dá para mudar em configuração, sem desenvolvimento).
- O responsável é sempre quem pede; não dá para atribuir a outra pessoa.
- O acesso é dado pessoa a pessoa pelo administrador (SDR, vendedores, pós-vendas e gestão comercial), sem grupo automático.
- Quando você não diz o tipo, o assistente procura em lead, cliente e oportunidade e lista os candidatos com o tipo.
- Regras (ligar/desligar, prefixos aceitos, prioridade padrão, texto de origem) ficam numa configuração que o administrador edita.

## O que não dá para conferir pela tela
- Se a versão correta do assistente está ativa e se o e-mail realmente não foi enviado: evidência técnica em `05-testes.md` (e `05-testes-rodada-1.md` para os resultados anteriores).
