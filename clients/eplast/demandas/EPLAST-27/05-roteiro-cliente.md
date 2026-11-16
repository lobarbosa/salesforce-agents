# Roteiro de teste — Próxima melhor ação por cliente

O assistente de IA (SFAgent2) agora sugere ao vendedor a próxima ação para uma conta, a partir do que o Salesforce já sabe dela (risco, oportunidades paradas, última compra). A sugestão é só uma leitura: não altera nada, não envia e-mail e não mostra CPF, e-mail ou telefone.

**Situação do teste automático:** o time executou em `sbx-eplast-qa` os cenários 1 a 7 e 9 a seguir (2 consultas por cenário, todas corretas), com contas fictícias, e confirmou que nada foi gravado. Ficaram para quem segue o roteiro: o Teste 8 (mudar o limite de dias) e a observação do Teste 10.

## Antes de começar
- Ambiente: a sandbox QAS (a de homologação). Perfil: vendedor com o conjunto de permissões "Comercial - Próxima Ação" atribuído.
- Crie 6 contas de teste com você como responsável (nome começando por "TESTE EPLAST-27"), com estas situações:
  1. **Risco:** campo Risco com valor E, e uma oportunidade aberta sem atividade há 45 dias.
  2. **Parada:** sem risco, oportunidade aberta sem atividade há 31 dias.
  3. **Sem compra recente:** oportunidade Fechado/Ganho com data de fechamento há 91 dias, sem outra oportunidade aberta parada.
  4. **Em dia:** oportunidade Fechado/Ganho há 10 dias e oportunidade aberta com atividade há 5 dias, sem risco.
  5. **Conta nova:** sem oportunidades.
  6. **De outro vendedor:** conta que pertence a outra pessoa.
- Abra o assistente de IA. Em cada teste, pergunte: "Qual a próxima ação para a conta <nome da conta>?"

## Teste 1 — Risco vence oportunidade parada
1. Pergunte pela conta "Risco".
Resultado esperado: "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." Não aparece "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada
1. Pergunte pela conta "Parada".
Resultado esperado: "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente
1. Pergunte pela conta "Sem compra recente".
Resultado esperado: "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação
1. Pergunte pela conta "Em dia".
Resultado esperado: "Nenhuma ação prioritária no momento." Nenhuma ação inventada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta nova
1. Pergunte pela conta "Conta nova".
Resultado esperado: "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Sem mensagem de erro técnica.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta de outro vendedor
1. Pergunte pela conta "De outro vendedor".
Resultado esperado: o assistente diz que você não é o responsável pela conta e não mostra dado dela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — A consulta não altera nada
1. Anote a data de "Última modificação" da conta "Risco" e da sua oportunidade.
2. Faça 3 consultas sobre essa conta.
3. Abra de novo a conta e a oportunidade.
Resultado esperado: as datas de última modificação não mudaram e nenhuma tarefa nova apareceu. Nenhum e-mail foi enviado. As respostas não trazem CPF, e-mail nem telefone.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Mudar o limite de dias (não executado pelo time)
1. Peça ao time técnico para trocar o limite de "oportunidade parada" de 30 para 60 dias.
2. Pergunte pela conta "Risco" sem risco (ou crie uma conta com oportunidade parada há 45 dias).
Resultado esperado: a sugestão "Retomar oportunidade parada" deixa de aparecer.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Conta com risco menor que E
1. Crie uma conta com Risco A e oportunidade parada há 45 dias. Pergunte por ela.
Resultado esperado: "Retomar oportunidade parada ... 45 dias." (só o risco E conta como risco).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Pergunta de continuação (limitação conhecida)
1. Pergunte pela conta "Conta nova", e em seguida "E então, qual é a ação?".
Resultado esperado: idealmente repete "Dados insuficientes". Sabemos que o assistente pode sugerir uma ação própria (por exemplo, entrar em contato) nesse caso. Isso foi aceito como limitação; marque o que ocorrer para decidirmos se a regra precisa ser mais rígida.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Ações possíveis e ordem:** dados insuficientes, depois risco, depois oportunidade parada, depois sem compra recente. Confirma esta ordem?
- **Prazos:** 30 dias sem atividade para oportunidade parada; 90 dias sem compra para cliente inativo (o mesmo prazo de "Inativo" que a conta já usa). Confirma?
- **Risco:** só o valor E do campo Risco conta como risco (é o que já leva a oportunidade para análise financeira).
- **Quem vê:** só o vendedor dono da conta; gestores não veem a sugestão nesta versão.
- **Fonte dos dados:** contas e oportunidades; pedidos ficam fora desta versão.
- **Só no assistente:** não há aviso na página da conta.
- **Regra fixa:** a sugestão não é gerada por IA, o assistente só apresenta o texto.

## O que não dá para conferir pela tela
- Que a consulta não dispara automações nem chamadas externas (contagem do registro de integração igual antes e depois) e a limpeza da massa: evidência em `05-testes.md`.
- Que EPLAST-28 e o item de clientes sem compra recente usarão a mesma regra: não testável nesta entrega.
