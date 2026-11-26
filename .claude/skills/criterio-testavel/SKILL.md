---
name: criterio-testavel
description: Como o BA escreve critério de aceite que o verificador e o QA conseguem provar, e fecha as perguntas de negócio na análise em vez de deixá-las para o build. Use na etapa de análise, antes de fechar o 01-analise.md.
---

# Critério que dá para provar, pergunta que não sobra

Seis builds voltaram bloqueados por pergunta que só o cliente responde. Cada um custou uma
análise, um recon e um design antes de alguém perceber que faltava a regra. A pergunta
estava visível na demanda desde o primeiro dia; ninguém a fez.

A análise não termina em "o que o cliente pediu". Termina em "o que será aceito, como se
confere, e o que ainda ninguém respondeu".

## Cada critério responde a quatro coisas

| Parte | Pergunta | Exemplo |
|---|---|---|
| Quem | Qual perfil ou papel faz a ação? | vendedor interno |
| Estado de partida | O registro está como, antes? | oportunidade aberta, sem produto |
| Ação | O que a pessoa (ou o sistema) faz? | muda a fase para "Proposta" |
| Resultado observável | O que dá para ver ou contar depois? | o campo X fica preenchido; uma tarefa é criada para o dono |

Se falta uma das quatro, o critério não é testável. "O sistema deve funcionar
corretamente", "melhorar a visibilidade" e "ser rápido" não são critérios: reescreva ou
transforme em pergunta.

## O que sempre vira critério, mesmo que a demanda não diga

- **O caso que não deve acontecer.** Para cada "quando X, faz Y", escreva o "quando não X,
  não faz Y". É o critério que pega automação disparando para todo mundo.
- **Valor vazio e valor fora da lista.** O que aparece quando o campo está em branco?
- **Quem não pode.** Qual perfil não deve ver ou alterar, e o que ele vê no lugar.
- **Registro que já existe.** A regra vale só para o que for criado daqui em diante, ou
  também para o que já está na base? Se vale para o que existe, é carga, e isso muda o
  esforço.
- **Em lote.** A ação acontece em um registro por vez ou também por importação, lista ou
  integração?

## Perguntas de negócio: feche aqui

Antes de escrever "Premissas a validar", percorra a lista. Cada resposta que você não
encontra na demanda, nos comentários do card ou no histórico do cliente vira **pergunta em
destaque no topo da análise**, não premissa escondida no meio.

- Quem é o dono da regra do lado do cliente, para responder?
- Qual é o valor exato? Prazo em dias corridos ou úteis, percentual sobre o quê, faixa com
  limite incluído ou não.
- O que acontece na exceção? Aprovador ausente, registro sem dono, valor zerado.
- A mensagem ou o texto que o usuário vê: quem escreve, em que idioma, com que nome de campo.
- Há comunicação para fora (e-mail, mensagem, integração)? Para quem, por qual canal, em
  qual horário.
- O que já existe hoje e o cliente espera que continue igual?

Escreva a pergunta de um jeito que caiba numa resposta curta: com as opções, quando houver.
"Como deve funcionar a aprovação?" não é pergunta; "Acima de qual valor a proposta precisa
de aprovação, e quem aprova: o gestor do dono ou um aprovador fixo?" é.

Pergunta que muda a arquitetura (canal de notificação, sistema de origem do dado, volume)
para a análise: diga no encerramento que a demanda não deve ir ao design sem a resposta.

## O que só o cliente confere

Alguns critérios não se provam em sandbox: aparência num dispositivo dele, texto que
depende de gosto, dado que só existe em produção. Não os transforme em critério de teste.
Liste-os numa seção própria, "O que o cliente confere na homologação", para o QA levar ao
roteiro do cliente.

## Antes de entregar a análise

- [ ] Todo critério tem quem, estado de partida, ação e resultado observável.
- [ ] Há pelo menos um critério negativo por regra.
- [ ] Ficou dito se a regra alcança registros que já existem.
- [ ] Perguntas de negócio estão no topo, com dono e com opções de resposta.
- [ ] O que só o cliente confere está separado do que o QA prova.
