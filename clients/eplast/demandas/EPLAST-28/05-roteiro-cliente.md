# EPLAST-28 — Roteiro de teste: alerta de oportunidade parada

Foi entregue um aviso automático: todo dia de manhã o Salesforce confere as oportunidades abertas e, quando uma passa do prazo sem nenhuma atividade registrada, o responsável recebe uma notificação no sino do Salesforce. O aviso não muda a oportunidade, a conta nem o pedido, e não sai e-mail.

**Situação do teste automático:** o time armou o teste na sandbox de QA para 20:55 de 15/11 e confere o resultado em seguida. Ainda não está comprovado: o envio da notificação, que o aviso não se repete no dia seguinte, o aviso ao gestor e o caso de dono inativo. Os testes abaixo ficam para quem segue o roteiro. O prazo de teste ficou em 2 dias, só para a conferência; o prazo combinado é 14 dias.

## Antes de começar
- Ambiente: sandbox de QA (QAS) da Eplast. Nunca produção.
- Perfil: usuário que seja dono da oportunidade de teste.
- Dado de teste: crie uma conta e oportunidades com o nome começando por `TESTE EPLAST-28`. A oportunidade precisa de conta com endereço de cobrança, CNAE e loja preenchidos, e de dono com "ID Usuário Protheus" preenchido.
- O aviso sai no horário combinado (07:00). Para ver o resultado no mesmo dia, peça ao time técnico para antecipar o horário e informe a hora.

## Teste 1 — Oportunidade parada alerta o dono
1. Crie a oportunidade `TESTE EPLAST-28 parada`, aberta, e registre uma tarefa concluída com data de 14 dias atrás.
2. Aguarde o horário do aviso.
3. Clique no sino de notificações.

**Resultado esperado:** notificação "Oportunidade parada ha 14 dias" com nome da oportunidade, nome da conta, estágio e a data da última atividade. Ao clicar, abre a oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Atividade recente não alerta
1. Crie `TESTE EPLAST-28 recente`, aberta, com tarefa concluída de 3 dias atrás.
2. Aguarde o horário do aviso e abra o sino.

**Resultado esperado:** nenhuma notificação para essa oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Oportunidade fechada não alerta
1. Crie `TESTE EPLAST-28 fechada` no estágio Fechado/Perdido, com tarefa de 14 dias atrás.
2. Aguarde o horário do aviso e abra o sino.

**Resultado esperado:** nenhuma notificação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade sem nenhuma atividade
1. Crie `TESTE EPLAST-28 sem atividade` e não registre tarefa nem evento. Ela só alerta 14 dias depois de criada; peça ao time técnico para simular essa data.

**Resultado esperado:** o dono recebe o aviso, contando a partir da data de criação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — O aviso não se repete
1. Depois do Teste 1, aguarde o dia seguinte sem registrar atividade nem mudar o estágio.
2. Abra o sino.

**Resultado esperado:** nenhuma nova notificação para a mesma oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nada muda nos registros
1. Antes do aviso, anote a data de "Última modificação" da oportunidade de teste e da conta.
2. Depois do aviso, confira de novo.

**Resultado esperado:** as datas são as mesmas; nenhuma tarefa nova apareceu e nenhum e-mail chegou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Gestor só recebe se ligado
1. Com a opção de avisar o gestor desligada (padrão), repita o Teste 1 com dono que tenha gestor.
2. Peça ao time técnico para ligar a opção e repita.

**Resultado esperado:** desligada, só o dono recebe; ligada, o gestor direto também recebe, e só se estiver ativo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Oportunidade parada = sem tarefa ou evento e sem mudança de estágio há 14 dias. Está certo?
- Tarefas criadas automaticamente pelo sistema contam como acompanhamento, então uma oportunidade com tarefa automática recente pode não alertar. Aceitável?
- Prazo único de 14 dias para todos os estágios, ajustável sem desenvolvimento.
- Aviso só dentro do Salesforce (sino), uma vez por episódio de parada, às 07:00. Nada por e-mail; se quiserem e-mail, sai pelo Marketing Cloud, por quem o opera.
- Só o dono é avisado. O gestor é opcional e começa desligado.
- Oportunidades fechadas não alertam; todos os tipos de oportunidade entram.
- Dono inativo não recebe aviso e a oportunidade fica registrada no log de integração, sem troca de dono.
- Na entrada em produção, pode haver uma varredura única das oportunidades já paradas, numa data a definir. Sem data, não há.
- O aviso não cria tarefa nem altera nada; não usa o assistente SFAgent2.

## O que não dá para conferir pela tela
Que nenhum objeto foi alterado em massa, o registro de execução do job e o log de dono inativo são conferidos pelo time técnico; evidência em `05-testes.md`. A carga com muitas oportunidades não foi simulada.
