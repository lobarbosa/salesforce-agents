# Roteiro de teste — SOMOSAGILITY-22: status de qualificação dos Jobs no painel financeiro

Foi entregue o ajuste no processo de aprovação dos Jobs de Solicitação de Investimento e no relatório e painel (dashboard) de Jobs do financeiro. Para quem usa: ao enviar um Job para aprovação, o campo de status de qualificação passa a mostrar o valor correto, e o relatório e o painel contam todos os Jobs por esse status.

**Situação do teste automático:** comprovei só que os itens existem na QA e que a configuração grava "Pendente" no envio. Não consegui enviar um Job de teste para aprovação (o processo só se aplica a pessoas e grupos específicos do cliente) nem abrir relatório e painel (a QA tem dados reais copiados). Os Testes 1 a 5 abaixo ficam para quem segue o roteiro.

## Antes de começar
- Ambiente: sandbox de QA (`sbx-somos-agility-qa`), nunca produção.
- Perfil: use um usuário do financeiro que possa criar Jobs e que conste entre os solicitantes do processo de aprovação (pergunte ao time qual usuário de teste usar). Para aprovar, use o aprovador da etapa.
- Crie um Job de teste: aba Jobs de Solicitação de Investimento, botão Novo, e no campo Observação escreva "TESTE SOMOSAGILITY-22 manual". Preencha os campos obrigatórios com valores inventados. Crie dois: "TESTE ... A" e "TESTE ... B".

## Teste 1 — Enviar para aprovação grava "Pendente"
1. Abra o Job de teste A.
2. Confira que o campo Status da Qualificação está "Não Enviado".
3. Clique em "Enviar para aprovação".
**Resultado esperado:** o envio é aceito e o campo Status da Qualificação mostra "Pendente". O campo de status da previsão de gastos não muda.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Aprovar leva a "Aprovado"
1. Entre como aprovador da etapa e abra o item de aprovação do Job A.
2. Clique em Aprovar (todas as etapas, se houver mais de uma).
**Resultado esperado:** Status da Qualificação "Aprovado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rejeitar e reenviar
1. Envie o Job B para aprovação.
2. Como aprovador, clique em Rejeitar.
3. Confira o status e reenvie o Job.
**Resultado esperado:** após rejeitar, "Rejeitado"; após reenviar, "Pendente".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Relatório de Jobs não perde registros
1. Abra Relatórios, pasta Financeiro, relatório "JOBs de Investimento".
2. Anote o total de linhas e o total do gráfico de rosca.
3. Compare os grupos (Pendente, Aprovado, Rejeitado, Não Enviado, Recall) com os Jobs de teste A e B.
**Resultado esperado:** total de linhas igual ao total da rosca; cada Job de teste aparece só no grupo do seu status atual; nenhum status válido fica de fora.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Painel bate com o relatório
1. Abra o painel de Projetos Atuais que usa esse relatório e clique em Atualizar.
2. Compare a contagem de cada status com a do Teste 4.
**Resultado esperado:** as contagens são iguais.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
O resultado do envio de teste feito pelo time técnico e as contagens por status na QA estão em `05-testes.md`. O pedido de 30/10 (tornar "Classificação gerencial" e "Denominação" obrigatórias na aprovação) não foi construído e depende de decisão do time; por isso não há teste dele aqui.
