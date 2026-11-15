# EPLAST-47 — Roteiro de teste: classificação das contas por faixa de compras

Foi entregue o ajuste da rotina que calcula, uma vez por mês, o valor de compras de cada conta e a Classificação (campo Ranking). A rotina processa cada conta uma única vez, usa sete faixas (MP, PP, P, M, G, GG e 3G), guarda o histórico de mudanças do Ranking e tem um relatório com as contas que mudaram de faixa. Para quem usa, muda a Classificação das contas e o valor de compras, que passam a seguir as faixas abaixo.

**Situação do teste automático:** o time comprovou a configuração (sete faixas, lista do campo Ranking com sete opções, relatório e histórico criados). O resultado da rotina sobre as contas depende da execução agendada, que foi programada para 15/11 às 17:10 (horário de Brasília) e será conferida pelo time numa segunda sessão. Até lá, os Testes 2 a 5 ficam para quem segue este roteiro, depois da execução.

## Antes de começar
- Ambiente: sandbox de QA (QAS). Perfil: administrador ou usuário que veja Contas e Relatórios.
- A rotina roda sozinha; para este teste foi programada para o dia 15/11. Faça os Testes 2 a 5 depois dela.
- Use só contas de teste. Se precisar de uma conta com valores conhecidos, peça ao time para criar "TESTE EPLAST-47 Conta A" com oportunidades ganhas de teste.

## Teste 1 — Lista do campo Ranking
1. Abra uma conta e clique em Editar.
2. Abra a lista do campo Ranking.

**Resultado esperado:** aparecem exatamente MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Classificação pelas faixas
1. Depois da execução, abra uma conta de teste cuja Média de compras do ano você conheça.
2. Veja os campos Média de compras este ano e Ranking.

**Resultado esperado:** até 10.000 = MP; até 35.000 = PP; até 80.000 = P; até 160.000 = M; até 500.000 = G; até 1.000.000 = GG; acima = 3G. O valor exato do limite fica na faixa de baixo (35.000 é PP; 35.000,01 é P).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Valor de compras soma só as ganhas
1. Abra uma conta de teste com oportunidades ganhas de 3.000 e 2.000 neste ano e uma perdida de 9.000.
2. Veja o campo Valor de Compras Último Mês.

**Resultado esperado:** 5.000,00 (a perdida não entra).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Conta sem compra e conta sem média
1. Abra uma conta de teste sem oportunidade ganha neste ano.
2. Veja Valor de Compras Último Mês e Ranking.
3. Abra uma conta com Média de compras vazia que já tinha Ranking.

**Resultado esperado:** conta sem ganha no ano fica com Valor de Compras zerado ou vazio; conta com média vazia mantém o Ranking que tinha (não vira GG).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Histórico e relatório de mudanças
1. Abra uma conta cujo Ranking mudou na execução.
2. Na aba Relacionado, abra o Histórico da conta e procure a linha do campo Ranking.
3. Vá em Relatórios, pasta "EPLAST-47 Relatorios (provisorio, P12)", e abra "Mudancas de Classificacao de Contas".

**Resultado esperado:** o histórico mostra uma única mudança de Ranking dessa conta, com valor anterior e novo; o relatório lista as contas que mudaram, com a classificação anterior e a nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Só contam compras do ano corrente com oportunidade em Fechado/Ganho (regra atual). Confirme que é essa a regra desejada.
- Conta com Média de compras vazia mantém o Ranking que tinha. Conta com média zero cai em MP. Confirme.
- Conta sem compra no ano fica com o valor configurado (zero ou vazio), como a rotina já fazia.
- O aviso de falha só sai se houver um destinatário configurado; hoje está vazio. Informe quem deve receber. A falha sempre fica registrada.
- O sistema Protheus precisa aceitar os valores MP e 3G no Ranking; confirmar com quem cuida da integração.
- A rotina continua diária, só classificando no dia 14 de cada mês.
- O relatório está numa pasta provisória; diga onde deve ficar.

## O que não dá para conferir pela tela
Execução agendada, ausência de erro de bloqueio de registro, volume e envio ao Protheus: o time confere por contagens na sandbox e registra em `05-testes.md`.
