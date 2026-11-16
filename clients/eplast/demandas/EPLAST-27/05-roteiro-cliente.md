# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

**O que foi entregue:** o assistente de IA (SFAgent2) passa a sugerir ao vendedor a próxima ação para um cliente, com base em risco do cadastro, oportunidades paradas e data da última compra. A sugestão só é mostrada: não altera nenhum cadastro nem envia mensagem.
**O que muda para quem usa:** o vendedor pergunta ao assistente "qual a próxima ação para o cliente X?" e recebe uma das respostas listadas abaixo, só para clientes da sua própria carteira.

**Situação do teste automático:** a regra que decide a sugestão foi executada na sandbox de QA com contas de teste e deu o resultado esperado nos 7 cenários (risco, oportunidade parada, sem compra recente, nenhuma ação, dados insuficientes, conta de outro vendedor, risco fora da lista). Também foi comprovado que a consulta não altera cadastros e que uma conta com 150 oportunidades responde sem erro. **Não foi comprovada a resposta do próprio assistente**, porque a versão nova do assistente (v6) ainda não está ativa na QA: ativá-la desativa a versão atual e depende de autorização. Os testes abaixo, feitos na tela do assistente, ficam para quem segue o roteiro depois da ativação.

## Antes de começar
- **Ambiente:** sandbox QAS da Eplast (a de homologação).
- **Perfil:** vendedor que tenha o conjunto de permissões "Comercial - Próxima Ação" e acesso ao assistente. Se não tiver, peça ao time técnico.
- **Pré-condição:** a versão v6 do assistente SFAgent2 precisa estar ativa (passo do time técnico).
- **Contas de teste** (crie com seu usuário como proprietário; use nomes começando por "TESTE EPLAST-27"):
  - **Conta A:** campo Risco com valor "E", com uma oportunidade aberta cuja última atividade foi há 45 dias, e já com uma compra ganha.
  - **Conta B:** Risco vazio ou diferente de "E", com oportunidade aberta cuja última atividade foi há 31 dias.
  - **Conta C:** sem oportunidade parada, com última compra ganha há 91 dias.
  - **Conta D:** compra ganha há 10 dias e oportunidade com atividade há 5 dias.
  - **Conta E:** conta nova, sem oportunidades e sem compra.
  - **Conta F:** conta de teste que pertence a outro vendedor.
  Para a atividade, registre uma tarefa concluída na oportunidade com a data desejada.

## Teste 1 — Risco da conta tem prioridade
1. Abra o assistente.
2. Pergunte: "Qual a próxima ação para a conta TESTE EPLAST-27 A?"

**Resultado esperado:** "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." Não deve aparecer "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada
1. Pergunte a próxima ação da Conta B.

**Resultado esperado:** "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente
1. Pergunte a próxima ação da Conta C.

**Resultado esperado:** "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação prioritária
1. Pergunte a próxima ação da Conta D.

**Resultado esperado:** "Nenhuma ação prioritária no momento." O assistente não deve inventar outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Dados insuficientes
1. Pergunte a próxima ação da Conta E.

**Resultado esperado:** "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Nenhuma mensagem de erro técnico.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta de outro vendedor
1. Pergunte a próxima ação da Conta F.

**Resultado esperado:** "Esta conta não está na sua carteira." Nenhum dado da conta aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — A consulta não altera nada
1. Abra a Conta B e anote a data de "Última modificação" (em Detalhes).
2. Pergunte a próxima ação da Conta B cinco vezes.
3. Recarregue a Conta B.

**Resultado esperado:** a data de "Última modificação" não mudou e nenhuma tarefa nova foi criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nenhum dado pessoal nem envio de mensagem
1. Em qualquer das respostas anteriores, confira o texto.

**Resultado esperado:** a resposta traz só a frase da ação (e estágio e dias, quando houver). Não mostra CPF, e-mail, telefone ou valores. Nenhum e-mail ou mensagem é enviado ao cliente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Perguntas com outras palavras
1. Pergunte à Conta B de formas diferentes, por exemplo "o que devo fazer com esse cliente?" e "devo ligar para ele?".

**Resultado esperado:** o assistente apresenta a mesma sugestão, sem acrescentar nem combinar ações.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Ações possíveis e ordem:** primeiro "dados insuficientes", depois risco, depois oportunidade parada, depois cliente sem compra recente, depois "nenhuma ação". Confirma essa prioridade?
- **Prazos:** oportunidade parada = mais de 30 dias sem atividade (ajustável sem programação); cliente sem compra recente = mais de 90 dias, pela regra de "inativo" que já existe no cadastro.
- **Risco:** só o valor "E" conta como risco, porque é o que já leva a oportunidade para análise financeira. Confirma? Atenção: "E" é o valor padrão de contas novas.
- **Fontes:** só Conta e Oportunidade. Pedidos ficam fora desta versão.
- **Onde aparece:** só no assistente, não na página da conta.
- **Regra fixa, sem IA decidindo:** a IA apenas apresenta o texto.
- **Calculada na hora, nada é gravado**, e só o dono da conta recebe a sugestão. Gestores não entram nesta versão.
- **Oportunidade aberta sem nenhuma atividade** e criada há mais de 30 dias também conta como parada.
- **Quem recebe o acesso:** na QA, só vendedores de teste; a lista real sai da homologação.
- **Mesma regra para outros alertas:** EPLAST-28 e demais entregas devem usar esta regra, para não existirem duas "próximas ações".

## O que não dá para conferir pela tela
- Que a regra não executa nenhuma automação de Conta ou Oportunidade e que não gera envio ao ERP: comprovado pelo time técnico (log de execução e contagem de registros de integração), em `05-testes.md`.
- Volume (conta com 150 oportunidades): comprovado pelo time técnico, em `05-testes.md`.
