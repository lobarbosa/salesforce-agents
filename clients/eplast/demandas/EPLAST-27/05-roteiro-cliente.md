# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

O assistente (SFAgent2) passa a responder qual é a próxima ação comercial recomendada para uma conta, com base nas oportunidades e na atividade dela. Quem usa pode perguntar pelo nome da conta, pelo identificador do Salesforce ou pelo código da conta (o "ID da Conta no Protheus", 6 dígitos). O assistente só apresenta a recomendação, não grava nada.

**Situação do teste automático:** o time executou, na QAS, as buscas por identificador, por nome, por código inexistente e por texto qualquer (passaram). A busca por código de uma conta ou de várias contas **ainda não funciona** e está em correção; os Testes 4 e 5 abaixo descrevem o comportamento esperado e só devem ser feitos pelo cliente depois do ajuste. A conversa com o assistente passando o código não foi exercitada. Nada foi conferido por tela.

## Antes de começar
- Ambiente: a sandbox de homologação (QAS da Eplast), com um usuário do perfil comercial que tenha o acesso "Próxima ação (Comercial)".
- Crie contas de teste (nome começando por "TESTE EPLAST-27"): uma com oportunidade aberta sem atividade há mais de 30 dias e Classificação de risco diferente de "E"; outra com o mesmo código no campo "ID da Conta no Protheus" mas em lojas diferentes (001 e 002); uma terceira de outro vendedor. Anote os códigos.
- Pergunte sempre ao assistente, com as palavras que usaria no dia a dia.

## Teste 1 — Pergunta pelo nome da conta
1. Abra o assistente.
2. Pergunte: "Qual a próxima ação para a conta TESTE EPLAST-27 (nome da conta com oportunidade parada)?"

**Resultado esperado:** "Retomar oportunidade parada", com a etapa e os dias sem atividade, sem pedir mais dados.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Pergunta pelo identificador do Salesforce
1. Abra a conta de teste e copie o identificador da barra de endereço (começa por 001).
2. Pergunte ao assistente a próxima ação para esse identificador.

**Resultado esperado:** a mesma recomendação da conta, sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conta com risco
1. Pergunte a próxima ação de uma conta de teste com Classificação de risco "E".

**Resultado esperado:** "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Pergunta pelo código da conta (depois do ajuste)
1. Pergunte: "Qual a próxima ação para a conta de código (código de 6 dígitos da conta de teste)?"

**Resultado esperado:** a recomendação da conta que tem esse código, igual à do Teste 1 ou 3.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Código que existe em duas contas (depois do ajuste)
1. Pergunte a próxima ação usando o código que está em duas contas de teste.

**Resultado esperado:** o assistente lista as duas contas (com a loja de cada uma) e pede que você diga qual quer, sem escolher sozinho.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Código ou texto que não existe
1. Pergunte a próxima ação para o código 927999.
2. Pergunte a próxima ação para "abc-xyz".

**Resultado esperado:** nos dois casos, "Não encontrei conta com esse código que você possa ver." (ou equivalente), sem mensagem de erro técnica.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Conta de outro vendedor
1. Com o usuário comercial, pergunte a próxima ação de uma conta de teste que pertence a outro vendedor.

**Resultado esperado:** o assistente informa que a conta não está na sua carteira e não mostra dados dela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Conversa de continuação (limitação conhecida)
1. Numa conta de teste sem oportunidades nem compras, pergunte a próxima ação.
2. Em seguida, pergunte: "E então, qual é a ação?"

**Resultado esperado:** o assistente repete "Dados insuficientes...". Pode acontecer de ele sugerir uma ação fora das previstas; é uma limitação aceita, a observar. Registre o que apareceu.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Código da conta:** assumimos que o código que a equipe usa é o campo "ID da Conta no Protheus" (6 dígitos; 1209 de 1210 contas preenchidas na QAS estão nesse formato). Se usarem outro código, avise.
- **Prioridade da recomendação:** sem dados, risco, oportunidade parada há mais de 30 dias, cliente sem compra há mais de 90 dias, nenhuma ação. Os prazos podem ser mudados em configuração.
- **Carteira:** o vendedor só consulta contas das quais é o responsável.
- **Código repetido em lojas:** o assistente lista as contas e pergunta qual, nunca escolhe sozinho.
- **Só consulta:** nenhuma tarefa, e-mail ou campanha é criada; disparos de marketing ficam no Marketing Cloud.

## O que não dá para conferir pela tela
- Que a consulta não grava nada e não chama sistema externo, e a distribuição dos formatos do código no cadastro: comprovados pelo time por consulta, em `05-testes.md`.
- Alteração do prazo de 30/90 dias na configuração: não executado pelo time.
