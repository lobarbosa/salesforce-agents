# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

O vendedor passa a poder perguntar ao assistente do Salesforce "qual a próxima ação para esta conta?" e recebe uma única sugestão curta, baseada na situação comercial da conta (risco, oportunidade parada, tempo sem compra). A consulta só lê dados: não altera nenhum registro e não envia e-mail.

**Situação do teste automático:** a regra que decide a sugestão foi comprovada pelo time na sandbox de testes (todos os casos abaixo, exceto a conversa em si, deram o resultado esperado, e nenhuma conta foi alterada). A **conversa com o assistente não pôde ser executada pelo time** (a sessão automática não consegue abrir o chat), por isso os testes abaixo, que usam o chat, ficam para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de homologação (QAS da Eplast). Nunca em produção.
- Perfil: vendedor com o conjunto de permissões "Comercial Próxima Ação" e acesso ao assistente (SFAgent2). Se a opção do assistente não aparecer, avise o time.
- Dados de teste: crie contas chamadas "TESTE EPLAST-27 ..." de que você seja o proprietário, com:
  - Conta A: classificação de risco "E" e uma oportunidade aberta com última atividade há 45 dias.
  - Conta B: sem risco, uma oportunidade aberta com última atividade há 31 dias.
  - Conta C: sem risco, sem oportunidade aberta, última compra ganha há 91 dias.
  - Conta D: sem risco, compra ganha há 10 dias e atividade há 5 dias.
  - Conta E: conta nova, sem oportunidade nem compra.
  - Conta F: proprietário diferente de você.
  - Conta G: risco "A" e oportunidade aberta parada há 45 dias.
- Nos testes, pergunte ao assistente: "Qual a próxima ação para a conta <nome da conta>?"

## Teste 1 — Risco tem prioridade
1. Abra o assistente.
2. Pergunte pela Conta A.

**Resultado esperado:** "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." Não deve aparecer "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada
1. Pergunte pela Conta B.

**Resultado esperado:** "Retomar oportunidade parada: há uma oportunidade em <etapa> sem atividade há 31 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente
1. Pergunte pela Conta C.

**Resultado esperado:** "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação necessária
1. Pergunte pela Conta D.

**Resultado esperado:** "Nenhuma ação prioritária no momento."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta nova
1. Pergunte pela Conta E.

**Resultado esperado:** "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Sem mensagem de erro técnico.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta de outro vendedor
1. Pergunte pela Conta F.

**Resultado esperado:** "Esta conta não está na sua carteira." O assistente não mostra nenhum dado da conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Risco fora da lista de risco alto
1. Pergunte pela Conta G.

**Resultado esperado:** "Retomar oportunidade parada: ... sem atividade há 45 dias." (não a mensagem de risco).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nada é alterado e nada é enviado
1. Anote a data da "Última modificação" das Contas A a D.
2. Faça a pergunta de cada conta mais duas vezes.
3. Reabra cada conta.

**Resultado esperado:** "Última modificação" igual à anotada; nenhum e-mail ou mensagem enviado; a resposta não mostra CPF, e-mail nem telefone.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Perguntas variadas
1. Para a Conta B, faça 6 perguntas de jeitos diferentes (ex.: "O que devo fazer com a conta X?", "Preciso ligar para X?").

**Resultado esperado:** o assistente sempre repete a mesma sugestão e não inventa ação nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Ações possíveis e prioridade: dados insuficientes, depois risco, depois oportunidade parada, depois cliente sem compra recente, depois "nenhuma ação". A ordem é fixa; mudar exige ajuste técnico.
- Oportunidade parada: mais de 30 dias sem atividade (ajustável pelo time sem desenvolvimento). Cliente sem compra recente: mais de 90 dias, o mesmo critério do campo "Inativo" que a org já usa.
- Só contas e oportunidades entram na regra (pedidos ficam de fora).
- A sugestão aparece só no assistente, sob demanda, sem gravar nada.
- Vendedor só vê sugestão das contas de que é proprietário.
- "Risco alto" significa classificação de risco "E".
- Oportunidade aberta sem nenhuma atividade conta como parada quando foi criada há mais de 30 dias.
- Na sandbox, só os vendedores de teste recebem a permissão; a lista real de usuários é definida por vocês.
- O tempo de resposta do assistente não tem limite definido: informem qual é aceitável.

## O que não dá para conferir pela tela
- Que a consulta não dispara automações da conta e da oportunidade, e o volume (conta com 150 oportunidades): feito pelo time, evidência em `05-testes.md` e `05-testes-rodada-1.md`.
- Que as demais demandas do assistente continuam funcionando com esta versão ativa: a ativação desta versão desligou outra versão do assistente na QA, ponto de atenção do time.
