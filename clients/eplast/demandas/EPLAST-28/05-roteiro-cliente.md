# Roteiro de teste — Aviso de oportunidade parada (EPLAST-28)

**O que foi entregue.** Todo dia, às 7h (horário de Brasília), o Salesforce confere as oportunidades abertas. Quando uma oportunidade completa 14 dias sem nenhuma atividade registrada e sem mudança de estágio, o dono dela recebe um aviso no sino de notificações do Salesforce. O aviso só aparece dentro do Salesforce: não sai e-mail nem mensagem, e nada na oportunidade, na conta ou no pedido é alterado.

**O que muda para quem usa.** O vendedor passa a receber um aviso, uma vez, no dia em que a oportunidade completa o prazo. Não precisa fazer nada para ligar.

**Situação do teste automático:** a automação roda por agendamento e só pôde ser armada na rodada de QA em andamento; o resultado do disparo está sendo conferido pelo time na sessão seguinte (veja `05-testes.md`). Nada abaixo está comprovado ainda: este roteiro é para você conferir pela tela. A regra de 14 dias com "atividade e estágio" não dá para ser exercitada na sandbox sem esperar 14 dias, por isso os testes 1 a 4 usam um prazo curto de teste, e o time informa antes qual prazo está configurado.

## Antes de começar
- **Ambiente:** a sandbox de QA da esteira, que a Eplast chama de QAS (eplast--qas). Nunca em produção.
- **Perfil:** Administrador do sistema, ou qualquer usuário que seja dono de oportunidade. Para o teste 5, um usuário que não seja dono de nenhuma oportunidade de teste.
- **Dados de teste:** a Conta "TESTE EPLAST-28 Conta" e as oportunidades "TESTE EPLAST-28 A parada...", "B atividade...", "C sem atividade" e "D fechada parada" já existem. Se precisar recriá-las: crie a conta com nome "TESTE EPLAST-28 Conta"; crie oportunidades abertas no estágio Qualificado com você como dono, e para cada uma uma Tarefa concluída com a data desejada (a data da tarefa é o que conta como "atividade"). Peça ao time para confirmar quantos dias de prazo estão configurados e a data em que o aviso será gerado.

## Teste 1 — Oportunidade parada recebe o aviso
1. Entre na sandbox de QA com o usuário dono das oportunidades de teste.
2. Clique no sino de notificações, no alto da tela.
3. Procure um aviso com o título "Oportunidade parada há N dias" (N é o prazo de teste).

**Resultado esperado:** um aviso para a oportunidade cuja última atividade completa exatamente N dias, com nome da oportunidade, "TESTE EPLAST-28 Conta", "Estágio: Qualificado" e a data da última atividade. Ao clicar, abre a própria oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Atividade recente não gera aviso
1. No sino de notificações, procure um aviso para uma oportunidade de teste com atividade mais recente que o prazo (a "C sem atividade", criada hoje, ou a "B" quando estiver abaixo do prazo).

**Resultado esperado:** nenhum aviso para ela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Oportunidade fechada não gera aviso
1. Abra a oportunidade "TESTE EPLAST-28 D fechada parada" e confira que o estágio é "Fechado/Perdido".
2. No sino de notificações, procure aviso para ela.

**Resultado esperado:** nenhum aviso, mesmo com a última atividade antiga.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Sem atividade nenhuma
1. Abra "TESTE EPLAST-28 C sem atividade" e veja a data de criação.
2. Só quando ela completar o prazo desde a criação, confira o sino.

**Resultado esperado:** o aviso sai no dia em que a oportunidade completa o prazo contado da data de criação, e não antes.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Aviso só para o dono e sem repetição
1. Entre com outro usuário que não é dono e abra o sino.
2. Volte com o dono, no dia seguinte ao aviso, e abra o sino.

**Resultado esperado:** o outro usuário não recebe aviso das oportunidades de teste. No dia seguinte o dono não recebe um segundo aviso da mesma oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nada foi alterado, nada foi enviado por e-mail
1. Abra uma oportunidade de teste que recebeu aviso e vá à aba de histórico de campos e à lista de atividades.
2. Confira a caixa de e-mail do dono.

**Resultado esperado:** nenhuma alteração de campo nem atividade nova criada pelo aviso, e nenhum e-mail sobre ele.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Prazo e gestor configuráveis
1. Peça ao time para, na configuração do aviso, mudar o prazo e ligar a opção de avisar o gestor (hoje desligada), para um dono que tenha gestor preenchido.
2. Depois do próximo disparo, confira o sino do gestor.

**Resultado esperado:** com a opção ligada o gestor também recebe o aviso; desligada, só o dono.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
Decidimos estes pontos sem resposta de vocês. Se discordarem, é possível mudar na configuração, quase sempre sem refazer a entrega.
1. **Parada** quer dizer: sem nenhuma atividade registrada e sem mudança de estágio há 14 dias (vale a mais recente das duas). Dá para trocar para só atividade ou só estágio.
2. **Tarefas criadas automaticamente pelo Salesforce contam como atividade.** Uma oportunidade com tarefa automática recente pode não alertar mesmo sem contato real.
3. **Prazo único de 14 dias** para todos os estágios. Prazo por estágio fica para depois.
4. **O aviso é uma notificação dentro do Salesforce, uma vez por episódio**, avaliada todo dia às 7h. Não há e-mail; mensagem ao cliente seria pelo Marketing Cloud, por quem o opera.
5. **Só o dono recebe.** O aviso ao gestor vem desligado e só vale se o gestor estiver preenchido, ativo e for outra pessoa.
6. **O aviso só avisa:** não cria tarefa nem altera nada.
7. **Valem todas as oportunidades abertas**, de qualquer tipo de registro.
8. **O aviso mostra** nome da oportunidade, conta, estágio, dias parada e link; nenhum dado de contato.
9. **Dono inativo não é substituído:** ninguém é avisado e o caso fica registrado no log de integrações.
10. **Oportunidades que já estiverem paradas na entrada no ar** só avisam se o time preencher uma data de carga inicial; por padrão, não.
11. **O aviso sai no dia exato** em que completa o prazo; quem já passou desse dia não é avisado depois.
12. O agente SFAgent2 não foi alterado; o aviso complementa a pergunta "quais clientes precisam de acompanhamento".

## O que não dá para conferir pela tela
O disparo agendado das 7h, o registro do job, a não alteração dos dados em volume (contagens antes e depois), o comportamento com muitas oportunidades e os limites de notificação por hora da plataforma são comprovados pelo time técnico; a evidência fica em `05-testes.md`. Dono inativo e carga inicial também dependem de preparo do time.
