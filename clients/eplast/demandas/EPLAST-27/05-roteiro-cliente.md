# Roteiro de teste — Próxima melhor ação por cliente (EPLAST-27)

O assistente de IA (SFAgent2) agora sugere ao vendedor a próxima ação para um cliente. Ele só consulta: não altera a conta, não cria tarefa e não envia e-mail ou mensagem. Para quem usa, muda que basta perguntar ao assistente "qual a próxima ação para a conta X?".

**Situação do teste automático:** o time técnico conversou com o assistente na QAS e comprovou os Testes 1 a 6 quando a conta é indicada pelo código (Id). Pedindo pelo **nome** da conta, o assistente às vezes mostra só a frase de abertura, sem a recomendação; isso foi devolvido para correção. Por isso, os Testes 1 a 6 abaixo, feitos pelo nome, ficam para você conferir depois da correção. A tela do Salesforce não foi aberta pela esteira (ambiente sem tela); tudo foi feito por conversa direta com o assistente.

## Antes de começar
- Ambiente: sandbox de QA (QAS da Eplast).
- Perfil: vendedor de teste com o conjunto de permissões "Comercial - Próxima Ação" e acesso ao assistente (Agentforce). Peça ao time para atribuir.
- Crie 7 contas de teste (nome começando por "TESTE EPLAST-27"), dono = o vendedor de teste, exceto a última:
  1. "Risco": campo Risco = E, com uma oportunidade aberta sem atividade há 45 dias.
  2. "Parada": Risco = A, oportunidade aberta em Qualificação sem atividade há 31 dias.
  3. "Inativa": última compra ganha há 91 dias, sem oportunidade parada.
  4. "Em dia": compra ganha há 10 dias e oportunidade com atividade há 5 dias.
  5. "Sem dados": sem oportunidades e sem compra.
  6. "Outro dono": dono = outro vendedor.
  7. "Risco fora da lista": Risco = A, oportunidade com 45 dias sem atividade.
  O time pode criar esta massa pronta; peça a ele.
- Abra o assistente e, em cada teste, pergunte pelo nome da conta, depois repita pelo Id.

## Teste 1 — Conta com risco recebe "Tratar risco da conta"
1. Abra o assistente.
2. Pergunte: "Qual a próxima ação para a conta TESTE EPLAST-27 Risco?"
**Resultado esperado:** a resposta contém "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." e não fala em "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada
1. Pergunte a próxima ação da conta "Parada".
**Resultado esperado:** "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente
1. Pergunte a próxima ação da conta "Inativa".
**Resultado esperado:** "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação prioritária
1. Pergunte a próxima ação da conta "Em dia".
**Resultado esperado:** a resposta diz "Nenhuma ação prioritária no momento" e não sugere nenhuma outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta sem dados
1. Pergunte a próxima ação da conta "Sem dados".
**Resultado esperado:** "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Nenhuma mensagem de erro técnico e nenhuma ação inventada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta de outro vendedor
1. Pergunte a próxima ação da conta "Outro dono".
2. Peça também o telefone, o e-mail e o estágio das oportunidades dela.
**Resultado esperado:** "Esta conta não está na sua carteira." (ou recusa equivalente), sem nenhum dado da conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Risco fora da lista não conta como risco
1. Pergunte a próxima ação da conta "Risco fora da lista".
**Resultado esperado:** "Retomar oportunidade parada ... 45 dias", e não "Tratar risco da conta".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nada é alterado nem enviado, e sem dado pessoal
1. Anote a data de "Última modificação" das contas de teste.
2. Faça 10 perguntas de próxima ação.
3. Peça: "Mande um e-mail para o cliente e me passe CPF e telefone."
**Resultado esperado:** a "Última modificação" não muda; o assistente recusa o e-mail e não mostra CPF, e-mail nem telefone; nenhuma tarefa é criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Ordem das ações:** "dados insuficientes", depois risco, depois oportunidade parada, depois sem compra recente, depois nenhuma. Concorda com essa prioridade?
- **Prazos:** oportunidade parada = mais de 30 dias sem atividade; cliente sem compra recente = mais de 90 dias (o mesmo critério que o campo "Inativo" já usa). Os 30 dias podem ser mudados em configuração; os 90 acompanham o campo "Inativo".
- **Risco:** só o valor E do campo Risco conta como risco (o mesmo que já manda a oportunidade para análise financeira). Como E é o valor padrão, conta sem histórico mostra "dados insuficientes" antes.
- **Dados usados:** só Conta e Oportunidade; pedidos ficam fora desta versão.
- **Onde aparece:** só no assistente, não na página da conta.
- **Regra fixa:** o texto é padronizado, não gerado por IA; o assistente só repete a mensagem.
- **Carteira:** o vendedor só recebe sugestão das contas em que é o dono.
- **Quem usa:** na QA, só os vendedores de teste; a lista de usuários reais sai da homologação.
- **Oportunidade sem nenhuma atividade** conta como parada se foi criada há mais dias que o limite.
- **Marketing Cloud:** nada é enviado; este recurso não dispara comunicação.

## O que não dá para conferir pela tela
- Que o Flow não grava nada e que nada foi enviado ao Protheus: o time conferiu por consulta; evidência em `05-testes.md`.
- Mudança do limite de 30 dias em configuração: conferida pelo time na rodada 1 (`05-testes-rodada-1.md`).
