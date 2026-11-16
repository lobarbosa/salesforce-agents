# Roteiro de teste — Resumos para reuniões (Comercial, GDD, S&OP e Board)

O assistente SFAgent2 passa a gerar, quando você pede, um resumo de números para as reuniões Comercial, GDD, S&OP e Board, com base no que já está no Salesforce. O resumo só mostra o que o seu perfil já pode ver, informa a data e hora em que foi gerado e de onde veio cada número, não grava nada no sistema e não envia e-mail.

**Situação do teste automático:** o time comprovou, na sandbox de QA, o cálculo dos quatro resumos com dados de teste (5 oportunidades somando R$ 15.000,00), data de corte, ausência de gravação e de envio, erro para pedido inválido e período padrão. **Não comprovado:** a conversa com o assistente (se cada frase abre o resumo certo e se ele mostra o texto sem alterar números), porque a tela de teste do assistente não pôde ser operada pela automação. Os testes 1 a 5 abaixo são para quem segue o roteiro.

## Antes de começar
- Ambiente: sandbox QAS da Eplast (a de homologação).
- Perfil: um usuário Comercial (ex.: "Comercial - Analista" ou "Gerente de soluções") com o conjunto de permissões "Resumo de reunião comercial" atribuído; e, para o Teste 6, um usuário sem permissão de ver Oportunidades.
- Dados: já existem na QAS uma conta `TESTE EPLAST-34 Conta A` e 5 oportunidades `TESTE EPLAST-34 Opp 1` a `5` com fechamento em março de 2031 e valores de R$ 1.000 a R$ 5.000 (soma R$ 15.000,00), mais 1 pedido da mesma conta. Se não existirem, crie-os com esses nomes e datas.
- Abra o assistente SFAgent2.

## Teste 1 — Resumo Comercial
1. No assistente, escreva: "Resumo para a reunião comercial de 01/03/2031 a 31/03/2031".
2. Leia a resposta.

**Resultado esperado:** título "Resumo para reuniao Comercial - periodo 01/03/2031 a 31/03/2031"; duas partes, "Oportunidades abertas por etapa" (Qualificação: 5 oportunidade(s), R$ 15.000,00) e "Oportunidades abertas por vendedor" (5 oportunidade(s), R$ 15.000,00); o assistente mostra os números exatamente como estão.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Resumos GDD, S&OP e Board
1. Peça: "Resumo GDD de 01/03/2031 a 31/03/2031".
2. Peça: "Resumo S&OP de 01/03/2031 a 31/03/2031".
3. Peça: "Resumo Board de 01/03/2031 a 31/03/2031".

**Resultado esperado:** GDD traz oportunidades por conta (TESTE EPLAST-34 Conta A: 5, R$ 15.000,00) e pedidos por conta (1). S&OP traz pedidos por status (1 pedido em "Revisao de Pedido") e o total do período. Board traz pipeline por vendedor (5, R$ 15.000,00), pedidos por vendedor e total geral, sem nome de conta. Cada resumo só tem as partes do seu tipo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Data de corte e origem dos números
1. Em qualquer resumo gerado, confira cada parte e o rodapé.

**Resultado esperado:** cada parte indica o campo de origem entre parênteses (por exemplo, "Opportunity.Amount") e o rodapé mostra "Dados ate" com data e hora; valores em reais no formato brasileiro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Período padrão
1. Peça: "Resumo S&OP" (sem informar datas).

**Resultado esperado:** o resumo usa o mês atual e mostra o período no título (do dia 1 ao último dia do mês corrente).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Números conferem com o relatório
1. Em Relatórios, monte (ou use) um relatório de Oportunidades abertas com Data de fechamento entre 01/03/2031 e 31/03/2031.
2. Compare quantidade e soma com o Teste 1.

**Resultado esperado:** 5 oportunidades e R$ 15.000,00 nos dois lugares.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Usuário sem permissão
1. Entre com um usuário sem permissão de ver Oportunidades.
2. Peça: "Resumo para a reunião comercial".

**Resultado esperado:** mensagem de acesso insuficiente; nenhum nome, valor, etapa ou data de oportunidade aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Pedido inválido ou período longo
1. Peça: "Resumo da reunião XYZ".
2. Peça: "Resumo comercial de 01/01/2000 a 01/01/2040".

**Resultado esperado:** mensagem de erro clara (tipo inválido; período maior que 366 dias), sem resumo parcial.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nada é gravado nem enviado
1. Anote quantas oportunidades e pedidos a conta de teste tem e a data da última modificação.
2. Gere os quatro resumos.
3. Confira de novo a conta, as oportunidades e os pedidos e a caixa de e-mails enviados.

**Resultado esperado:** nenhum número nem data de modificação mudou; nenhum e-mail foi enviado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — O assistente continua com as ações anteriores
1. Peça ao assistente uma consulta de pedidos, uma identificação de conta, uma próxima ação de cliente e uma tarefa, como já fazia.

**Resultado esperado:** todas respondem como antes; as frases de resumo não são desviadas para a consulta de pedidos.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Os quatro resumos são um só mecanismo com quatro recortes, geridos por esta entrega (não é um agente novo). O resumo por cliente com contatos é outra entrega.
- Conteúdo de cada tipo (a Eplast ajusta se for outro): Comercial = oportunidades abertas por etapa e por vendedor; GDD = por conta (20 maiores) com oportunidades e pedidos; S&OP = pedidos por status e total; Board = consolidado por vendedor, sem conta.
- Os números vêm só do Salesforce; meta, carteira e pedido imputado do Protheus não entram porque não há campo para isso.
- Resumo sob demanda, na tela do assistente; não há envio, PDF nem agendamento.
- Período padrão: mês atual, com possibilidade de informar outro; data de corte é o momento do pedido.
- Sem contato (nome, e-mail, telefone, CPF) no resumo.
- O resumo circula sem revisão humana; quem usa responde pelo número.
- Idioma português, sem modelo de documento próprio.
- Siglas GDD, S&OP e Board seguem a tabela acima; confirme se correspondem ao que a Eplast espera.

## O que não dá para conferir pela tela
Teste unitário (10 testes, cobertura de 93%), volume (34 consultas de 100 permitidas, 72 linhas de 50.000) e contagens antes/depois de gravação e e-mail estão em `05-testes.md`. A versão 8 do assistente foi ativada na QAS e fica ativa.
