# Roteiro de teste — SOMOSAGILITY-8: ajuste no fluxo de aprovação da DEPV

Foi entregue (1) um bloqueio que impede aprovar a DEPV na etapa financeira (Operações) sem a **Classificação gerencial** preenchida e (2) um novo modelo de avisos por e-mail para a 1ª/2ª aprovação, a 3ª aprovação e a aprovação final. Para quem aprova, muda que o botão Aprovar da etapa financeira só funciona com o campo preenchido; para quem recebe os avisos, muda o conteúdo e os destinatários.

**Situação do teste automático:** o time já comprovou na sandbox de QA o bloqueio (Testes 1 a 3), inclusive aprovando pelo processo real, e que os três modelos de e-mail são gerados com todos os campos, comentários e link (conferido sem enviar). **Não foi comprovado** o envio real dos e-mails (Testes 4 a 6) porque o novo processo de aprovação está desativado de propósito e ativá-lo troca o processo em uso; esses testes só dá para fazer depois que ele for ativado. A mensagem de erro na tela (Teste 1) também não foi vista pela interface.

## Antes de começar

- Ambiente: sandbox de QA (não use produção).
- Perfil: quem aprova a etapa financeira (perfil Compras Financeiro) e um usuário administrador para criar o dado de teste.
- Dado de teste: crie uma Despesa Extraordinária de Pré-Venda com Justificativa do Investimento "TESTE SOMOSAGILITY-8" e envie para aprovação. Aprove as etapas 1 e 2 até chegar na etapa de Operações (financeira). Apague o registro ao final.
- Para os Testes 4 a 6, confirme com o time que o novo processo de aprovação (versão v7_7) está ativo.

## Teste 1 — Não aprova sem Classificação gerencial
1. Abra a DEPV de teste que está aguardando a etapa de Operações, com o campo Classificação gerencial vazio.
2. Como o aprovador financeiro, clique em Aprovar.
**Resultado esperado:** a aprovação não conclui e aparece a mensagem "Preencha a Classificação Gerencial antes de aprovar."; a DEPV continua aguardando Operações.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Aprova com Classificação gerencial
1. Na mesma DEPV, edite o campo Classificação gerencial e escolha "Despesas Agility". Salve.
2. Clique em Aprovar.
**Resultado esperado:** a aprovação conclui e a DEPV fica com status Aprovado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Outras etapas e rejeição não são bloqueadas
1. Crie outra DEPV de teste, sem Classificação gerencial, e envie para aprovação.
2. Aprove a etapa 1 e a etapa 2.
3. Em outra DEPV de teste, na etapa de Operações, sem Classificação gerencial, clique em Rejeitar.
**Resultado esperado:** as etapas 1 e 2 são aprovadas sem pedir o campo, e a rejeição na etapa de Operações funciona normalmente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Aviso de 1ª e 2ª aprovação
1. Envie uma DEPV de teste para aprovação e depois aprove a etapa 1.
2. Abra a caixa de teste que recebe os avisos.
**Resultado esperado:** o e-mail traz ID da solicitação, Proprietário, Oportunidade, Justificativa do Investimento, Recuperação do Investimento, Valor Total Nominal Terceiros, Valor Total Nominal Agility, Valor Total e um link que abre a DEPV; os destinatários combinados recebem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Aviso de 3ª aprovação
1. Aprove a etapa 2 da DEPV de teste.
2. Abra o e-mail recebido.
**Resultado esperado:** o e-mail traz os mesmos campos do Teste 4, mais Comentários (o comentário digitado ao aprovar a etapa 2), o destaque "Atenção Grupo Operações" lembrando de preencher a Classificação Gerencial e o link para a DEPV.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Aviso final de aprovação
1. Preencha a Classificação gerencial e aprove a etapa de Operações.
2. Abra o e-mail enviado ao solicitante.
**Resultado esperado:** e-mail de "Aprovada" com saudação, comentários e link para a DEPV.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela

- Comportamento técnico do bloqueio sobre a gravação feita pelo processo de aprovação, regra antiga desativada e ligações do processo novo: evidência em `05-testes.md` (casos C5 a C10).
- Decisões do cliente em aberto: se a etapa financeira é mesmo a 3ª etapa, o texto final da mensagem de erro e quem recebe cada aviso.
