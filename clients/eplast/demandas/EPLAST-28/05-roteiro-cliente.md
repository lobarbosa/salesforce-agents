# EPLAST-28 — Roteiro de teste: aviso de oportunidade parada

Foi entregue um aviso automático: todo dia de manhã o Salesforce confere as oportunidades abertas e, quando uma chega ao prazo sem atividade registrada, o dono recebe um aviso no sino do Salesforce. Para quem usa, muda que o vendedor passa a ser lembrado sozinho; o aviso não cria tarefa, não muda a oportunidade e não envia e-mail.

**Situação do teste automático:** a conferência automática foi armada em 17/11 e depende de um disparo agendado, que será conferido numa segunda sessão da equipe técnica. O que já foi comprovado: o pacote está na sandbox de testes, a configuração está no lugar, a tarefa aberta não reinicia o prazo e a tarefa concluída sem data de vencimento não conta como atividade. O resultado do aviso em si (e o que aparece no sino) fica para a segunda sessão e para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de testes **QAS** (`eplast--qas`). Nunca em produção.
- Perfil: Administrador do sistema, ou o vendedor dono das oportunidades de teste.
- Dados de teste: usar apenas oportunidades com nome começando por **TESTE EPLAST-28** (a conta de teste é "TESTE EPLAST-28 Conta"). Elas já existem. Para criar uma nova, crie a oportunidade com essa conta, o estágio "Qualificado", e registre uma tarefa **concluída** com data de vencimento no passado (isso define a "última atividade"). Não use oportunidades de clientes reais.
- Prazo de teste: durante o teste o prazo do aviso está em 2 dias (em produção será 7 dias, como pedido). O aviso sai no dia em que a oportunidade completa exatamente o prazo sem atividade, e depois não repete.

## Teste 1 — Oportunidade parada gera aviso ao dono
1. Abra a oportunidade "TESTE EPLAST-28 G tarefa aberta" (última atividade concluída há 2 dias).
2. Clique no sino, no topo da tela, depois do horário do aviso.
3. Procure o aviso com o nome dessa oportunidade.

**Resultado esperado:** aparece o aviso "Oportunidade sem atividade há 2 dias", com o nome da oportunidade. Ao clicar, abre a oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — O texto do aviso é só o essencial
1. No aviso do Teste 1, leia o título e o texto.

**Resultado esperado:** só o título com o número de dias e o nome da oportunidade. Não aparecem conta, estágio, valor, e-mail nem telefone.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Mudar de estágio ou alterar dados não reinicia o prazo
1. Abra "TESTE EPLAST-28 F estagio alterado" (estágio e valor foram alterados hoje; última atividade concluída há 2 dias).
2. Procure o aviso dessa oportunidade no sino.

**Resultado esperado:** o aviso aparece, igual ao do Teste 1. Mudança de estágio ou de valor não conta como atividade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Tarefa aberta (inclusive as criadas automaticamente) não reinicia o prazo
1. Na oportunidade "TESTE EPLAST-28 G tarefa aberta", veja em Atividades a tarefa "Amostra", ainda aberta, com vencimento ontem.
2. Confira que existe aviso dessa oportunidade no sino.

**Resultado esperado:** há aviso, mesmo com a tarefa "Amostra" aberta. Só tarefa **concluída** (ou evento já realizado) reinicia a contagem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Tarefa concluída recentemente evita o aviso
1. Abra "TESTE EPLAST-28 H tarefa concluida recente" (tarefa concluída ontem).
2. Procure aviso dessa oportunidade no sino.

**Resultado esperado:** não há aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Oportunidade sem nenhuma atividade conta da criação
1. Abra "TESTE EPLAST-28 C sem atividade" (criada há 2 dias, sem atividade).
2. Procure o aviso no sino.

**Resultado esperado:** há aviso "Oportunidade sem atividade há 2 dias".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Oportunidade fechada não gera aviso
1. Abra "TESTE EPLAST-28 D fechada parada" (perdida, última atividade há 4 dias).
2. Procure aviso no sino.

**Resultado esperado:** não há aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Só um aviso, sem repetir todo dia
1. No dia seguinte ao aviso, abra o sino e procure outro aviso da mesma oportunidade (por exemplo a G).

**Resultado esperado:** continua só o aviso do dia anterior. Não chega aviso novo para a mesma oportunidade parada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — O aviso não altera a oportunidade nem cria tarefa
1. Abra a oportunidade G e veja "Última modificação" e a lista de Atividades.

**Resultado esperado:** nenhuma mudança causada pelo aviso: nenhuma tarefa nova, o dono continua o mesmo, nenhum campo foi alterado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Nenhum e-mail
1. Confira a caixa de entrada do usuário de teste depois do horário do aviso.

**Resultado esperado:** nenhum e-mail sobre a oportunidade parada. O aviso só existe no sino.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 11 — Aviso ao gestor (só quando houver gestor cadastrado)
1. Peça ao administrador para cadastrar o campo "Gestor" do vendedor de teste e ligar o aviso ao gestor (configuração "Notificar gestor", prazo 14 dias).
2. Use uma oportunidade de teste parada há exatamente 14 dias.

**Resultado esperado:** o gestor recebe o aviso no dia 14; o vendedor não recebe um segundo aviso. Se o vendedor não tiver gestor cadastrado, ninguém recebe nada no lugar (fica só o registro interno).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Tarefa automática:** a regra considera "atividade" só o que está concluído. Tarefas criadas automaticamente pelos fluxos da Eplast ("Amostra", "Cotação/Negociação", "Precificação" etc.) só reiniciam o prazo quando o vendedor as conclui. Se concluírem tudo em massa sem ter feito a atividade, o prazo reinicia. Distinguir a origem da tarefa de forma exata exigiria outra demanda. Confirma?
- **Tarefa concluída sem data de vencimento** não conta como atividade (medimos). Confirma?
- **No dia 14 o aviso vai só ao gestor,** sem repetir ao dono. Confirma?
- **Gestor ligado sem gestor cadastrado:** ninguém recebe aviso no lugar; só fica um registro interno. Confirma?
- **Todas as oportunidades abertas entram,** de qualquer tipo de registro. Confirma?
- **Horário:** uma conferência por dia, às 7h (horário da org). Confirma?
- **Volume em produção:** o número de oportunidades abertas é validado pela Eplast fora desta entrega.
- O aviso não aparece no agente de IA (SFAgent2); isso fica para demanda própria.

## O que não dá para conferir pela tela
- Disparo agendado, contagens antes e depois (nada criado ou alterado nos dados de negócio) e o registro interno de avisos: evidência em `05-testes.md`.
- Limites de volume do disparo diário: não medidos em carga grande; ver `05-testes.md`.
