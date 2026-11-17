# Roteiro de teste — Assistente que cria tarefas

O assistente de IA (SFAgent2) passa a criar tarefas por pedido em linguagem natural, ligadas a um lead, a um cliente (conta) ou a uma oportunidade. Ele mostra um resumo, só grava depois da sua confirmação, e não envia e-mail nem mensagem: guarda o rascunho como tarefa.

**Situação do teste automático:** na sandbox de QA já conversei com o assistente e comprovei: criar com confirmação, recusar, nome repetido, falta de data, pedido de oportunidade, pedido para outra pessoa e rascunho de e-mail com data e texto informados. Ficaram com falha, a corrigir antes da homologação: o assistente afirmar que criou o rascunho de e-mail sem criar (quando falta data ou texto), a descrição gravada como "sem descrição" e o resumo completo só aparecer depois da confirmação. Não foi possível testar com usuário comum (sem perfil de administrador): isso fica com quem segue este roteiro (Teste 6).

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a chamada "QAS").
- Perfil: use um usuário comercial com o conjunto de permissões "Assistente de ações comerciais" (e, para o Teste 6, outro usuário sem ele).
- Dados de teste: crie um lead com sobrenome `REG-TESTE-LEAD-01`, dois leads com sobrenome `REG-TESTE-DUP` e uma conta chamada `REG-TESTE-DUP`. Use só dados inventados.
- Abra o assistente (painel do SFAgent2) em uma tela do Salesforce.

## Teste 1 — Criar tarefa com confirmação
1. Digite: "criar tarefa de follow-up para REG-TESTE-LEAD-01 com vencimento em 01/12/2026".
2. Leia o resumo e o cartão de confirmação.
3. Antes de confirmar, abra o lead e veja a lista de atividades: não deve haver a tarefa.
4. Volte ao assistente e confirme.
5. Abra o lead de novo.
**Resultado esperado:** o resumo mostra assunto "Follow-up", o lead (nome e tipo), responsável "você", descrição e prazo 01/12/2026. Depois de confirmar, existe uma tarefa nova no lead, com vencimento 01/12/2026, dono e criador iguais a você, e a descrição com "Origem: assistente de IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recusar o resumo
1. Peça "criar tarefa de ligar de volta para REG-TESTE-LEAD-01 com vencimento em 02/12/2026".
2. Recuse ("não, cancela") ou rejeite o cartão.
**Resultado esperado:** o assistente diz que não criou, e o lead não ganha tarefa nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Nome repetido
1. Peça "criar tarefa para REG-TESTE-DUP com vencimento em 03/12/2026".
**Resultado esperado:** o assistente lista os três registros (dois leads e uma conta) com o identificador de cada um e pede que você escolha. Nenhuma tarefa é criada até a escolha.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Falta a data
1. Peça "criar tarefa de follow-up para REG-TESTE-LEAD-01" (sem data).
**Resultado esperado:** o assistente pergunta a data de vencimento e não cria nada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Pedido de e-mail e pedido fora do escopo
1. Peça "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01, vencimento hoje, texto padrão de proposta comercial". Confirme.
2. Confira a tarefa criada no lead e a aba de e-mails enviados.
3. Em outra conversa, peça "enviar e-mail de proposta para o contato de REG-TESTE-LEAD-01", sem data, e responda apenas "sim".
4. Peça "criar oportunidade para REG-TESTE-LEAD-01".
**Resultado esperado:** passo 1: tarefa "Rascunho de e-mail - ..." com o texto na descrição, nenhum e-mail enviado, e o assistente diz que o envio é feito fora do CRM. Passo 3: o assistente pede a data e o texto, e só diz que criou se a tarefa aparecer no lead. Passo 4: o assistente recusa e diz que só cria tarefas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Usuário sem permissão
1. Entre com um usuário sem o conjunto de permissões "Assistente de ações comerciais" e sem permissão de criar tarefas.
2. Peça "criar tarefa de follow-up para REG-TESTE-LEAD-01 com vencimento em 01/12/2026" e confirme.
**Resultado esperado:** o assistente recusa com mensagem de permissão, nenhuma tarefa é criada e a mensagem não mostra nome nem campo de registro que o usuário não vê.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Descrição e responsável
1. Peça "criar tarefa de revisar contrato para REG-TESTE-LEAD-01 com vencimento em 05/12/2026, sem descrição" e confirme.
2. Abra a tarefa criada.
3. Peça "criar tarefa de follow-up para REG-TESTE-LEAD-01 amanhã, responsável Maria".
**Resultado esperado:** passo 2: a descrição tem só "Origem: assistente de IA" (sem o texto "sem descrição"). Passo 3: o assistente recusa, pois só cria tarefa para você.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — O que já existia continua funcionando
1. Pergunte "quantos pedidos abertos temos?" e "qual a próxima ação para a conta REG-TESTE-DUP?".
2. Peça um resumo de reunião Comercial e uma sugestão de campanha.
**Resultado esperado:** o assistente responde como antes, sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Tarefa de lead fica ligada só ao lead (não à conta).
- Lead já convertido não recebe tarefa: o assistente orienta a pedir na conta ou na oportunidade.
- A descrição sempre aparece no resumo, mas não é obrigatória (dá para tornar obrigatória por configuração, sem nova entrega).
- O responsável é sempre quem pede; tarefa para outra pessoa é recusada.
- Quatro públicos (SDR, vendedores e executivos, pós-vendas, gestão comercial) recebem o acesso uma pessoa por vez, atribuindo o conjunto de permissões.
- E-mail e mensagem nunca saem pelo CRM: o assistente só guarda o rascunho como tarefa; envio de marketing é feito pelo Marketing Cloud.

## O que não dá para conferir pela tela
Que nenhum e-mail foi enviado e que os registros foram gravados com os donos certos foi conferido por consulta pelo time técnico; a evidência está em `05-testes.md` (casos A1, A6 e A8).
