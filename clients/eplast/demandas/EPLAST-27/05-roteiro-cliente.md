# Roteiro de teste — EPLAST-27: Próxima melhor ação por cliente

Foi entregue ao assistente de vendas (o chat do Salesforce) a capacidade de dizer qual é a próxima ação sugerida para uma conta da sua carteira. Para quem usa, basta perguntar, com o nome da conta, e o assistente responde com uma de três ações (tratar risco, retomar oportunidade parada, reativar cliente), ou informa que não há ação prioritária ou que faltam dados.

**Situação do teste automático:** o time já comprovou na QA, com contas de teste, as cinco respostas possíveis perguntando pelo nome da conta (21 de 21 corretas), a recusa para conta de outro vendedor, a ausência de dado pessoal e de gravação de dados pela consulta. **Não comprovado:** o assistente ainda inventa uma recomendação própria quando a pessoa faz uma segunda pergunta sem citar a conta (Teste 7); a mudança do limite de dias pela configuração não foi executada. Por isso este roteiro serve também para reconferir esses pontos depois da correção.

## Antes de começar
- Ambiente: sandbox QAS da Eplast (a de homologação).
- Perfil: vendedor do time Comercial com o acesso "Comercial - Próxima Ação" atribuído.
- Crie 6 contas de teste suas (você como responsável), com nome começando por "TESTE EPLAST-27":
  - **Conta A**: Risco preenchido com "E" e uma oportunidade aberta cuja última atividade foi há 45 dias.
  - **Conta B**: sem risco; oportunidade aberta cuja última atividade foi há 31 dias.
  - **Conta C**: sem risco; sem oportunidade parada; última compra ganha há 91 dias.
  - **Conta D**: sem risco; oportunidade com atividade há 5 dias; compra há 10 dias.
  - **Conta E**: sem risco, sem oportunidade e sem compra.
  - **Conta F**: pertencente a outro vendedor.
- Abra o assistente (Agentforce) pelo ícone do assistente no Salesforce.

## Teste 1 — Risco tem prioridade
1. No assistente, escreva: "Qual a próxima ação para a conta TESTE EPLAST-27 Conta A?" (use o nome exato da conta).
2. Leia a resposta.

**Resultado esperado:** "Tratar risco da conta: o cadastro está com risco E, que leva novas oportunidades para análise financeira." A resposta não sugere "Retomar oportunidade parada".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade parada
1. Pergunte a próxima ação da Conta B, pelo nome.

**Resultado esperado:** "Retomar oportunidade parada: há uma oportunidade em Qualificação sem atividade há 31 dias." (cita a etapa da oportunidade).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cliente sem compra recente
1. Pergunte a próxima ação da Conta C, pelo nome.

**Resultado esperado:** "Reativar cliente sem compra recente: a última compra ganha foi há mais de 90 dias."
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Nenhuma ação prioritária
1. Pergunte a próxima ação da Conta D, pelo nome.

**Resultado esperado:** "Nenhuma ação prioritária no momento." O assistente não inventa outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Conta nova, sem dados
1. Pergunte a próxima ação da Conta E, pelo nome.

**Resultado esperado:** "Dados insuficientes: esta conta ainda não tem oportunidades nem compra ganha registradas." Nenhuma mensagem de erro técnico aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta de outro vendedor
1. Pergunte a próxima ação da Conta F, pelo nome.

**Resultado esperado:** o assistente informa que você não é o responsável pela conta ou não tem permissão, e não mostra nenhum dado dela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Segunda pergunta não inventa ação
1. Faça o Teste 5 (Conta E).
2. Na mesma conversa, escreva: "E então, qual é a ação?"

**Resultado esperado:** o assistente repete que há dados insuficientes (ou consulta de novo) e não propõe uma ação própria como "entrar em contato com o cliente".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Sem dado pessoal e sem envio de comunicação
1. Na conversa da Conta A, escreva: "Mande um e-mail para o cliente e me passe o CPF, e-mail e telefone dele."

**Resultado esperado:** o assistente não mostra CPF, e-mail nem telefone, e nenhum e-mail é enviado. (Ele pode oferecer criar uma tarefa; recuse.)
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Consultar não altera a conta
1. Anote a data de "Última modificação" da Conta A e da oportunidade dela.
2. Faça várias consultas à Conta A no assistente.
3. Reabra a conta e a oportunidade.

**Resultado esperado:** as datas de "Última modificação" continuam iguais; nenhuma tarefa nova foi criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Ações e prioridade:** assumimos três ações, nesta ordem: tratar risco da conta, retomar oportunidade parada, reativar cliente sem compra recente. Confirme se é a lista e a ordem que o Comercial quer.
- **Prazos:** assumimos 30 dias sem atividade para oportunidade parada e 90 dias sem compra para reativação. São valores iniciais, e dá para mudar pela configuração, sem nova entrega. Confirme se servem.
- **Quais riscos contam:** assumimos que só o risco "E" aciona "Tratar risco da conta".
- **Fontes dos dados:** só contas e oportunidades. Pedidos ficam de fora desta versão.
- **Onde aparece:** só no assistente, e não como aviso na página da conta.
- **Texto fixo, sem inteligência artificial na decisão:** a regra é objetiva e a frase é sempre a mesma.
- **Quem vê:** o vendedor dono da conta. Gestores não entram nesta versão, e a sugestão é calculada na hora, sem ficar gravada.
- **Uma só regra:** as próximas demandas que usarem "próxima ação" devem usar esta mesma regra.

## O que não dá para conferir pela tela
- Que a consulta não chamou sistema externo e que a limpeza dos dados de teste foi feita: evidência em `05-testes.md` (contagens antes e depois).
- A versão ativa do assistente e do fluxo na QAS: também em `05-testes.md`.
