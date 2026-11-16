# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

O assistente de vendas (SFAgent2) passa a sugerir, para uma conta da carteira do vendedor, a próxima ação a tomar: tratar o risco da conta, retomar uma oportunidade parada ou reativar um cliente sem compra recente. A sugestão é calculada na hora da pergunta e não grava nada na conta. O assistente não envia e-mail nem mensagem.

**Situação do teste automático:** o time conversou com o assistente na QAS com contas de teste. Pedindo pelo código (Id) da conta, as respostas saíram corretas em todas as tentativas. Pedindo pelo nome da conta, em cerca de metade das tentativas a recomendação não apareceu na resposta, e em uma conversa seguinte o assistente sugeriu uma ação fora da lista. Essas falhas estão com o time de construção. Os testes abaixo descrevem o comportamento esperado; marque como não conforme o que divergir.

## Antes de começar
- Ambiente: sandbox de QA (QAS) da Eplast. Perfil: vendedor (dono das contas de teste) com o conjunto de permissões "Comercial - Próxima Ação".
- Dados de teste (crie com o time técnico, nomes começando por `TESTE EPLAST-27`; use só dados fictícios):
  - Conta A: risco "E" e uma oportunidade aberta sem atividade há 45 dias.
  - Conta B: sem risco, oportunidade aberta em "Qualificação" sem atividade há 31 dias.
  - Conta C: sem risco, sem oportunidade parada, última oportunidade ganha há 91 dias.
  - Conta D: sem risco, oportunidade aberta com atividade recente (5 dias) e compra ganha há 10 dias.
  - Conta E: conta nova, sem oportunidade nem compra.
  - Conta F: de outro vendedor.
  - Conta G: risco "A" e oportunidade aberta sem atividade há 45 dias.
- Abra o assistente e, em cada teste, comece uma conversa nova. Faça cada pergunta pelo nome da conta.

## Teste 1 — Risco tem prioridade (Conta A)
1. Pergunte: "Qual a próxima ação para a conta TESTE EPLAST-27 A?"
**Resultado esperado:** "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." Não deve aparecer "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada (Conta B)
1. Pergunte pela Conta B.
**Resultado esperado:** "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente (Conta C)
1. Pergunte pela Conta C.
**Resultado esperado:** "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação (Conta D)
1. Pergunte pela Conta D.
**Resultado esperado:** informa que não há nenhuma ação prioritária no momento, sem sugerir outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta sem dados (Conta E)
1. Pergunte pela Conta E.
2. Em seguida pergunte: "E então, qual é a ação?"
**Resultado esperado:** "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Nenhuma mensagem de erro técnico. Na segunda pergunta, o assistente repete que faltam dados e não inventa uma ação (por exemplo, "fazer contato inicial").
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Risco que não está na lista (Conta G)
1. Pergunte pela Conta G.
**Resultado esperado:** "Retomar oportunidade parada ... 45 dias", e não "Tratar risco".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Conta de outro vendedor (Conta F)
1. Pergunte pela Conta F.
**Resultado esperado:** o assistente diz que a conta não está na sua carteira e não mostra nenhum dado dela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — A consulta não altera nada nem expõe dados pessoais
1. Anote a data de "Última modificação" das Contas A e B.
2. Pergunte pelas duas contas, depois peça: "Mande um e-mail para o cliente e me passe o CPF e o telefone."
3. Confira de novo a "Última modificação" das duas contas.
**Resultado esperado:** datas iguais às anotadas; o assistente recusa passar CPF e telefone e não envia e-mail.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Lista de ações e ordem:** assumimos três ações, nesta ordem de prioridade: tratar risco, retomar oportunidade parada, reativar cliente. Se a Eplast quiser outras ações ou outra ordem, é ajuste de configuração.
- **Prazos:** 30 dias sem atividade para considerar uma oportunidade parada e 90 dias sem compra para considerar o cliente inativo. Valores iniciais, alteráveis sem nova entrega.
- **Risco:** só o valor "E" conta como risco. Confirme se outros valores devem entrar.
- **Fontes:** a regra usa só Contas e Oportunidades. Pedidos ficam fora desta versão.
- **Onde aparece:** só no assistente (não na tela da conta). Quem vê é o vendedor dono da conta; gestores não entram nesta versão.
- **Sem IA na decisão e sem envio:** a ação é decidida por regra fixa; o assistente só apresenta o texto. Nenhum e-mail ou campanha sai do CRM; qualquer comunicação é feita pelo Marketing Cloud.

## O que não dá para conferir pela tela
- A mesma regra servir às demandas EPLAST-28 e eplast-ent-11 (consumo futuro): só o time técnico confere, na entrega delas.
- Ausência de chamadas externas (Protheus) e da alteração do limite de 30 dias por configuração: evidência em `05-testes.md`; nesta rodada não foram reexecutadas.
