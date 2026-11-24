# Roteiro de teste — Relatório de Jobs do painel financeiro

Foi corrigido o processo de aprovação do Job de Solicitação de Investimento: quando o Job é enviado para aprovação, o campo "Status da Qualificação" passa a ficar como "Pendente" (antes continuava "Não Enviado" até a decisão final). Com isso o relatório "JOBs de Investimento" e o painel financeiro passam a mostrar os Jobs em aprovação no grupo "Pendente". O relatório e o painel não tiveram o filtro nem o período alterados.

**Situação do teste automático:** comprovado na sandbox de QA que o processo, as ações (Pendente no envio, Aprovado, Rejeitado e Recall), o relatório e o painel estão instalados como o previsto, e que a soma por status bate com o total da janela do relatório. NÃO foi executado o envio real de um Job, nem a abertura das telas de relatório e painel (a QA tem dados reais copiados e o time de testes não pode usá-los nem se passar por outra pessoa). Por decisão do responsável, os Testes 1 a 5 são feitos por vocês, do financeiro.

## Antes de começar
- Ambiente: sandbox de QA (não é produção).
- Perfil: um usuário real que consiga enviar Job para aprovação (o processo só aceita determinados criadores). Os aprovadores devem poder aprovar e rejeitar.
- Crie um Job de teste: na aba Jobs de Solicitação de Investimento, clique em Novo, preencha os campos obrigatórios e use no nome "TESTE SOMOSAGILITY-22 - 1". Crie três: "- 1", "- 2" e "- 3". Não use Jobs reais.
- Ao tirar prints, mostre apenas os Jobs de teste; esconda valores e nomes reais.

## Teste 1 — Enviar para aprovação grava "Pendente"
1. Abra o Job "TESTE SOMOSAGILITY-22 - 1". Confira que o campo Status da Qualificação está "Não Enviado".
2. Clique em Enviar para aprovação.
3. Atualize a página e olhe o campo Status da Qualificação.

**Resultado esperado:** o campo mostra "Pendente".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Aprovar leva a "Aprovado"
1. Com o Job do Teste 1 pendente, entre como aprovador e aprove todas as etapas.
2. Abra o Job e olhe o Status da Qualificação.

**Resultado esperado:** "Aprovado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rejeitar leva a "Rejeitado" e reenviar volta a "Pendente"
1. Envie o Job "TESTE SOMOSAGILITY-22 - 2" para aprovação.
2. Como aprovador, rejeite.
3. Confira o Status da Qualificação.
4. Reenvie o Job para aprovação e confira de novo.

**Resultado esperado:** após rejeitar, "Rejeitado"; após reenviar, "Pendente".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — O status da previsão de gastos não muda no envio
1. No Job "TESTE SOMOSAGILITY-22 - 3", anote o valor do campo Status Previsão de Gastos.
2. Envie o Job para aprovação.
3. Compare o campo com o valor anotado.

**Resultado esperado:** o Status Previsão de Gastos continua com o mesmo valor.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Relatório e painel mostram o Job no grupo certo
1. Abra o relatório "JOBs de Investimento" (pasta Financeiro).
2. Localize os Jobs de teste e confira o grupo de cada um (por exemplo, o Job do Teste 3 reenviado em "Pendente" e o do Teste 2 em "Aprovado").
3. Confira que o total de linhas é igual à soma dos grupos e ao total do gráfico de rosca.
4. Abra o painel de controle financeiro e atualize o componente do relatório "JOBs de Investimento".
5. Compare a contagem por status do painel com a do relatório.

**Resultado esperado:** cada Job de teste aparece só no grupo do seu status; nenhum Job sumiu; painel e relatório mostram as mesmas contagens. O relatório continua mostrando só Jobs com data de 2024 a 2026 (janela inalterada).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Que as ações do processo estão instaladas na QA como o previsto e a soma por status no período (265 Jobs na janela: Aprovado 242, Rejeitado 11, Não Enviado 11, Pendente 1): comprovado pelo time técnico, em `05-testes.md`.
- Ficam fora desta entrega: o pedido de 30/10 (tornar "Classificação gerencial" e "Denominação" obrigatórias na aprovação), que pode virar demanda própria se o financeiro confirmar; a correção de Jobs que já estão em aprovação hoje (continuam como estão); e a janela de datas do relatório.
- Atenção: os números de "Pendente" no painel e nos demais relatórios de Job sobem para os envios feitos daqui em diante. Há outra demanda (SOMOSAGILITY-17) alterando o mesmo processo de aprovação; confirme com o time a ordem de entrega.
