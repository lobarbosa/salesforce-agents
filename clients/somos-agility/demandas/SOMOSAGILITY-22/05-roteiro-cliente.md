# Roteiro de teste — Status "Pendente" nos Jobs de Solicitação de Investimento

Foi ajustado o processo de aprovação dos Jobs: ao enviar um Job para aprovação, o campo Status da Qualificação passa a ficar "Pendente" (antes continuava "Não Enviado" até a decisão final). Com isso, o relatório de Jobs e o painel do financeiro passam a mostrar os Jobs em aprovação no grupo correto.

**Situação do teste automático:** comprovado que o ajuste está presente na sandbox de QA. Não foi comprovado o comportamento de envio, aprovação e rejeição: o usuário de teste do time não entra nos critérios do processo (a regra depende de quem criou o Job). Por isso os testes 1 a 4 ficam para quem segue o roteiro, com um usuário que crie Jobs normalmente. Relatório e painel não foram abertos, pois a QA tem dados reais copiados.

## Antes de começar
- Ambiente: sandbox de QA (nunca produção).
- Perfil: usuário do financeiro que costuma criar e enviar Jobs para aprovação, e um aprovador.
- Dado de teste: crie 1 Job novo com o texto "TESTE SOMOSAGILITY-22" no campo Observação e preencha os campos obrigatórios. Não use Jobs reais.

## Teste 1 — Enviar para aprovação grava "Pendente"
1. Abra o Job de teste.
2. Confira que o campo Status da Qualificação está "Não Enviado".
3. Clique em "Enviar para aprovação".
4. Atualize a página.

**Resultado esperado:** Status da Qualificação = "Pendente". O campo Status Previsão de Gastos não muda.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Aprovar
1. Com o aprovador, abra o Job de teste e clique em "Aprovar".
2. Atualize a página.

**Resultado esperado:** Status da Qualificação = "Aprovado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rejeitar e reenviar
1. Crie um segundo Job de teste e envie para aprovação.
2. Com o aprovador, clique em "Rejeitar".
3. Confira o status, depois reenvie o Job para aprovação.

**Resultado esperado:** após rejeitar, "Rejeitado"; após reenviar, "Pendente".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Relatório de Jobs mostra os pendentes
1. Abra o relatório "JOBs de Investimento" (pasta Financeiro).
2. Procure os Jobs de teste.

**Resultado esperado:** o Job de teste enviado e ainda em aprovação aparece no grupo "Pendente", e em nenhum outro. A soma dos grupos do gráfico é igual ao total de linhas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Painel financeiro bate com o relatório
1. Abra o painel de controle financeiro e atualize.
2. Compare a contagem de cada status com a do relatório do teste 4.

**Resultado esperado:** as contagens por status são iguais.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Campos obrigatórios na aprovação (pedido de 30/10)
1. Tente enviar um Job de teste para aprovação com "Classificação gerencial" e "Denominação" vazios.

**Resultado esperado:** o envio é bloqueado pedindo esses campos. Este item ainda não foi confirmado como parte da entrega; se não bloquear, informe ao time.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
A presença do ajuste no processo de aprovação da QA foi conferida pelo time técnico (ver `05-testes.md`). Apague os Jobs de teste ao terminar.
