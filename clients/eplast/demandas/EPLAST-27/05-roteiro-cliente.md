# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

O assistente (SFAgent2) passa a responder qual é a próxima ação comercial recomendada para uma conta, com base nas oportunidades e na atividade dela. Quem usa pode perguntar pelo nome da conta, pelo identificador do Salesforce ou pelo código da conta no Protheus (o campo "ID da Conta no Protheus"). A resposta é uma só e não altera nenhum dado.

**Situação do teste automático:** o time executou na QAS, com contas de teste, todos os casos abaixo (identificador, nome, código de uma conta, código de duas contas, código de outro vendedor, código inexistente, texto qualquer, e a conversa com o assistente) e todos passaram. Ficam para você a conferência pela tela e a validação das premissas no fim.

## Antes de começar
- Ambiente: a sandbox de homologação (QAS da Eplast), com um usuário do perfil comercial que tenha o acesso "Próxima ação (Comercial)" e o campo de código de vendedor Protheus preenchido.
- Crie contas de teste (nome começando por "TESTE EPLAST-27"), sendo você o proprietário:
  - Conta A: com uma oportunidade aberta sem atividade há mais de 30 dias e "Classificação de risco" diferente de "E". Preencha "ID da Conta no Protheus" com 927101.
  - Conta B e Conta C: ambas com "ID da Conta no Protheus" 927102 e loja (campo "Loja") 001 e 002.
  - Conta D: de outro vendedor, com "ID da Conta no Protheus" 927104.
- Pergunte sempre ao assistente, com as palavras que usaria no dia a dia.

## Teste 1 — Pergunta pelo nome da conta
1. Abra o assistente.
2. Pergunte: "Qual a próxima ação para a conta TESTE EPLAST-27 A?" (use o nome exato da Conta A).

**Resultado esperado:** "Retomar oportunidade parada", com a etapa e os dias sem atividade, sem pedir mais dados.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Pergunta pelo identificador do Salesforce
1. Abra a Conta A e copie o identificador da barra de endereço (começa por 001).
2. Pergunte ao assistente a próxima ação para esse identificador.

**Resultado esperado:** a mesma recomendação do Teste 1, sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Pergunta pelo código da conta (uma conta)
1. Pergunte: "Qual a próxima melhor ação para a conta com código 927101?"

**Resultado esperado:** a recomendação da Conta A ("Retomar oportunidade parada"), sem pedir que você escolha conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Código que existe em mais de uma conta
1. Pergunte: "E para o código 927102?"

**Resultado esperado:** o assistente diz que encontrou mais de uma conta com esse código, lista as duas (nome e loja 001 e 002) e pede que você diga qual quer. Ele não escolhe sozinho.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Código de conta de outro vendedor
1. Pergunte a próxima ação para o código 927104.

**Resultado esperado:** "Esta conta não está na sua carteira.", sem nenhum dado da conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Código que não existe, ou texto qualquer
1. Pergunte a próxima ação para o código 927999.
2. Pergunte a próxima ação para "abc-xyz".

**Resultado esperado:** nos dois casos, "Não encontrei conta com esse código que você possa ver.", sem mensagem de erro técnico.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Conta com risco e conta sem histórico
1. Crie uma conta nova sem oportunidades e pergunte a próxima ação dela.
2. Altere a "Classificação de risco" da Conta A para "E" (perfil administrador ou Financeiro) e pergunte de novo.

**Resultado esperado:** 1) "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas."; 2) "Tratar risco da conta: o cadastro está com risco E...".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — A consulta não altera a conta
1. Anote a data de "Última modificação" da Conta A.
2. Faça três perguntas sobre ela ao assistente.
3. Recarregue a conta.

**Resultado esperado:** a data de "Última modificação" continua a mesma.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Ordem das recomendações:** primeiro "dados insuficientes", depois risco, depois oportunidade parada (mais de 30 dias sem atividade), depois cliente sem compra há mais de 90 dias, por fim "nenhuma ação". Confirma essa prioridade?
- **Risco:** só a classificação "E" conta como risco. Confirma?
- **Prazos:** 30 dias para oportunidade parada; 90 dias para cliente inativo (o mesmo critério do campo "Inativo" que já existe). Confirma?
- **Carteira:** o vendedor só recebe sugestão das contas das quais é proprietário. Gestores e equipe de conta não são tratados. Confirma?
- **Oportunidade sem nenhuma atividade** criada há mais de 30 dias conta como parada. Confirma?
- **Código da conta:** é o campo "ID da Conta no Protheus", e o assistente procura o valor exato. Quando o código vale para mais de uma conta (lojas diferentes), ele lista e pede a escolha. Confirma?
- **Quem usa:** na QAS, só os vendedores de teste têm o acesso "Próxima ação (Comercial)"; a lista de usuários reais sai da homologação.
- **Só o assistente** responde isso, por enquanto; não há botão na tela da conta.
- Depois de listar as contas (Teste 4), o assistente pode não "lembrar" qual você escolheu se a conversa for longa; é uma limitação conhecida e aceita.

## O que não dá para conferir pela tela
- Que a chamada do assistente não executa nenhuma automação de gravação nem envia e-mail: leitura do Flow e teste de "última modificação" estão em `05-testes.md` (casos 11 e "O que pode ter saído da org").
- Versão ativa do assistente na QAS: a v17 (reúne as demandas EPLAST-27, 29, 34 e 46); a conferência está em `05-testes.md`.
