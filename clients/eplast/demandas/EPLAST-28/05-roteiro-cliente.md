# EPLAST-28 — Roteiro de teste: aviso de oportunidade parada

Foi entregue um aviso automático: todo dia de manhã o Salesforce confere as oportunidades abertas e, quando uma completa o prazo sem atividade registrada, o dono recebe um aviso no sino. O aviso não cria tarefa, não altera a oportunidade e não envia e-mail.

**Situação do teste automático:** o time rodou o aviso na sandbox QAS em 17/11 e comprovou pelos registros do sistema que ele saiu para as oportunidades certas (parada, sem atividade, com estágio ou valor alterado, com tarefa aberta) e não saiu para as outras (fechada, tarefa concluída recente). Não conferimos o aviso pela tela do sino, nem o gestor, nem o dono inativo, nem o segundo dia. Isso fica para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox **QAS** (`eplast--qas`). Nunca em produção.
- Perfil: Administrador do sistema, ou o dono das oportunidades de teste.
- Dados de teste: só oportunidades com nome começando por **TESTE EPLAST-28** (conta "TESTE EPLAST-28 Conta"). Elas já existem. Não use oportunidades de clientes reais; no sino, ignore avisos de outras oportunidades.
- No teste o prazo está em **2 dias** (valor de produção: 7). O aviso sai no dia em que a oportunidade completa exatamente o prazo, e não repete.

## Teste 1 — Oportunidade parada gera aviso ao dono
1. Abra a oportunidade "TESTE EPLAST-28 G tarefa aberta".
2. Clique no sino, no topo da tela.
3. Procure o aviso com o nome dessa oportunidade.

**Resultado esperado:** aviso "Oportunidade sem atividade há 2 dias" com o nome da oportunidade; ao clicar, abre a oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — O texto do aviso é só o essencial
1. Leia o título e o texto do aviso do Teste 1.

**Resultado esperado:** só o número de dias e o nome da oportunidade. Não aparecem conta, estágio, valor, e-mail nem telefone.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Mudar estágio ou valor não reinicia o prazo
1. Procure no sino o aviso de "TESTE EPLAST-28 F estagio alterado" (estágio e valor alterados hoje).

**Resultado esperado:** o aviso aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Tarefa aberta não reinicia o prazo
1. Na oportunidade G, veja em Atividades a tarefa "Amostra", ainda aberta.
2. Confira o aviso da G no sino.

**Resultado esperado:** há aviso. Só tarefa concluída reinicia a contagem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Tarefa concluída recente evita o aviso
1. Procure no sino aviso de "TESTE EPLAST-28 H tarefa concluida recente".

**Resultado esperado:** não há aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Sem atividade, conta da criação
1. Procure no sino aviso de "TESTE EPLAST-28 C sem atividade" (criada há 2 dias).

**Resultado esperado:** aviso "Oportunidade sem atividade há 2 dias".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Oportunidade fechada não gera aviso
1. Procure no sino aviso de "TESTE EPLAST-28 D fechada parada" (perdida).

**Resultado esperado:** não há aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Sem repetição no dia seguinte
1. No dia seguinte ao aviso, abra o sino e procure outro aviso da G.

**Resultado esperado:** não chega aviso novo da mesma oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — O aviso não altera a oportunidade
1. Na oportunidade G, veja "Última modificação" e Atividades.

**Resultado esperado:** nenhuma tarefa nova, mesmo dono, nenhum campo alterado pelo aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Tarefa automática:** tarefa aberta não reinicia o prazo; tarefa concluída reinicia, mesmo se criada pelo sistema. Se uma tarefa automática concluída sem contato real adiar o aviso, diga se isso é aceitável.
- **Oportunidades avaliadas:** todas as abertas, de todos os tipos de registro.
- **Agente de IA:** o aviso complementa o assistente que já existe; nenhum assistente novo foi criado.
- **Volume:** não consultamos produção; se houver dezenas de milhares de oportunidades abertas, avise antes de ligar em produção.
- **Horário:** 07:00, uma vez por dia.
- **Registro do aviso:** cada aviso fica gravado num registro de log interno.
- **Dono inativo:** não recebe nem redireciona o aviso; o gestor (se ligado) segue independente.
- **Gestor:** só recebe se ativo e diferente do dono. Aos 14 dias o aviso vai só ao gestor, o dono não recebe de novo. Sem gestor cadastrado, nada é enviado a ninguém e fica só o registro. Começa desligado.
- **Texto igual** para dono e gestor.
- **Hierarquia:** hoje nenhum usuário tem gestor cadastrado; é preciso cadastrar antes de ligar o gestor.

## O que não dá para conferir pela tela
O disparo agendado, os registros de log e os totais de oportunidades, contas, pedidos e tarefas (iguais antes e depois) estão em `05-testes.md`. O ramo do gestor com gestor real e o dono inativo não puderam ser testados na sandbox.
