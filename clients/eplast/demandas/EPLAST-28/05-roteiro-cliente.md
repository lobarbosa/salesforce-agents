# EPLAST-28 — Alerta de oportunidade parada: roteiro de teste

Foi entregue um aviso automático, uma vez por dia, para o responsável por uma oportunidade aberta que ficou parada além do prazo. O aviso chega como notificação dentro do Salesforce (o sino), sem e-mail, e não altera nenhuma oportunidade, conta ou pedido.

**Situação do teste automático:** o time montou dados de teste e armou a execução na QAS, mas não conseguiu comprovar que o aviso foi gerado e entregue (nenhuma notificação apareceu para o responsável de teste). Por isso nenhum dos testes abaixo está comprovado: todos ficam para quem segue este roteiro. Prazo de 14 dias, repetição no dia seguinte, gestor e volume também não foram exercitados.

## Antes de começar
- Ambiente: QAS (sandbox da Eplast com cópia parcial). Perfil: o de um vendedor que seja dono de oportunidades.
- O aviso roda uma vez por dia, às 07:00 (horário de Brasília). Os testes precisam ser conferidos depois dessa hora.
- Dado de teste: use só oportunidades de teste (nome começando por "TESTE EPLAST-28"). Uma oportunidade nova nasce com a data de hoje, então para provar o prazo de 14 dias use uma oportunidade de teste que o time tenha deixado parada, ou combine com o time uma data de teste.
- Pergunte ao time qual prazo está configurado no momento (o normal é 14 dias).

## Teste 1 — Oportunidade aberta e parada gera aviso
1. Entre como dono de uma oportunidade de teste aberta, sem nenhuma atividade registrada e sem mudança de estágio há mais dias que o prazo.
2. No dia seguinte, depois das 07:00, clique no sino no topo da tela.

**Resultado esperado:** uma notificação "Oportunidade parada" com o nome da oportunidade, o nome da conta, o estágio atual e há quantos dias está sem atividade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade com atividade recente não gera aviso
1. Em uma oportunidade de teste aberta, registre uma tarefa concluída com a data de hoje.
2. Depois das 07:00 do dia seguinte, abra o sino.

**Resultado esperado:** nenhuma notificação sobre essa oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Oportunidade fechada nunca gera aviso
1. Use uma oportunidade de teste com estágio "Fechado/Perdido" ou "Fechado/Ganho" e última atividade antiga.
2. Depois das 07:00, abra o sino.

**Resultado esperado:** nenhuma notificação sobre essa oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade sem atividade conta a partir da criação
1. Use uma oportunidade de teste aberta que nunca teve atividade, criada há mais dias que o prazo.
2. Depois das 07:00, abra o sino.

**Resultado esperado:** notificação, contando os dias a partir da data de criação. Se foi criada há menos dias que o prazo, nenhuma notificação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Sem aviso repetido
1. Depois do Teste 1, não mexa na oportunidade.
2. No dia seguinte, depois das 07:00, abra o sino.

**Resultado esperado:** nenhuma segunda notificação para a mesma oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — O aviso não altera nada e não sai por e-mail
1. Antes do horário, anote a data "Última modificação" da oportunidade de teste do Teste 1.
2. Depois do aviso, abra a oportunidade e a caixa de e-mail do responsável.

**Resultado esperado:** "Última modificação" igual à anotada, nenhuma tarefa nova criada pelo aviso e nenhum e-mail recebido.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Dono inativo não recebe aviso
1. Use uma oportunidade parada cujo dono está inativo (combine com o time, pois só o administrador consegue montar).

**Resultado esperado:** ninguém é notificado e o dono não é trocado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Parada** é a oportunidade aberta sem atividade e sem mudança de estágio há 14 dias. Você concorda com 14 dias e com essa regra? (Muda sem programação.)
- **Tarefas criadas automaticamente** pelo sistema contam como acompanhamento, então podem impedir o aviso mesmo sem contato real.
- O prazo é **único**, igual para todos os estágios.
- Recebe o **dono**. O gestor só é avisado se a configuração for ligada, e hoje está desligada.
- O aviso é só **notificação interna**, uma vez por dia. E-mail ou mensagem, se quiserem, sairia pelo Marketing Cloud, por quem o opera.
- O alerta **só avisa**: não cria tarefa nem troca o dono.
- Entram oportunidades de todos os tipos de registro; só ficam de fora as fechadas.
- O aviso mostra nome da oportunidade, conta, estágio e dias parada, sem dado de contato.

## O que não dá para conferir pela tela
Volume grande de oportunidades, a execução agendada em si (job) e a ausência de e-mail ou chamadas externas só o time técnico comprova. A evidência e as falhas estão em `05-testes.md`.
