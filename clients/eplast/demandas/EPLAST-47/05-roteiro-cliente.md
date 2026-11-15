# EPLAST-47 — Roteiro de teste: classificação das contas por faixa de compras

Foi entregue o ajuste da rotina que calcula, uma vez por mês, o valor de compras de cada conta e a Classificação. A rotina agora processa cada conta uma única vez, usa sete faixas novas (MP, PP, P, M, G, GG e 3G), grava o histórico de mudanças da Classificação e tem um relatório com essas mudanças.

**Situação do teste automático:** o time já comprovou a configuração (7 faixas, valores dos limites, lista de Classificação com 7 opções, relatório e histórico criados). O resultado da rotina sobre as contas depende de execução agendada em 15/11 às 15:47 (horário de Brasília) na sandbox de QA e será conferido pelo time em seguida; até lá, os testes 2 a 5 ficam para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de QA. Perfil: administrador ou usuário que veja Contas e Relatórios.
- A rotina roda sozinha uma vez por mês; para este teste foi programada para o dia 15/11.
- Para conferir faixas por tela, use uma conta existente na QA com valores de teste, ou crie uma conta chamada "TESTE EPLAST-47 Conta A" com uma oportunidade ganha de teste (a criação de oportunidade pode exigir dados de apoio; peça ao time).

## Teste 1 — Lista de Classificação
1. Abra uma conta e clique em Editar.
2. Abra a lista do campo Classificação.

**Resultado esperado:** aparecem exatamente MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Classificação pelas novas faixas
1. Depois da execução de 15/11, abra uma conta com média de compras do ano conhecida.
2. Veja os campos Média de compras este ano e Classificação.

**Resultado esperado:** até 10.000 = MP; até 35.000 = PP; até 80.000 = P; até 160.000 = M; até 500.000 = G; até 1.000.000 = GG; acima = 3G. O limite exato fica na faixa de baixo (35.000 é PP).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Valor de compras ignora perdidas
1. Use uma conta com oportunidades ganhas de 3.000 e 2.000 e uma perdida de 9.000 no ano.
2. Veja o campo Valor de Compras Último Mês.

**Resultado esperado:** 5.000,00.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Conta sem compra ganha
1. Abra uma conta que só tenha oportunidades perdidas ou nenhuma.
2. Veja Valor de Compras Último Mês.

**Resultado esperado:** zero ou vazio, e a Classificação não cai em GG.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Histórico e relatório de mudanças
1. Abra uma conta cuja Classificação mudou e clique em Histórico de Classificação (ou Visualizar histórico do campo).
2. Abra Relatórios, pasta "EPLAST-47 Relatorios", relatório "AccountRankingChanges".

**Resultado esperado:** o histórico mostra a Classificação anterior e a nova; o relatório lista as contas alteradas com anterior e nova (cerca de 451 contas na execução de 15/11 da QA).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
Uma atualização por conta, ausência de erros de bloqueio, aviso de falha por e-mail (destinatário ainda não informado pela Eplast) e volume: ficam com o time técnico. Evidência na fase 2 de `05-testes.md`.
