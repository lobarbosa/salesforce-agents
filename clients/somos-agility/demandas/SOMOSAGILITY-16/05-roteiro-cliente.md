# Roteiro de teste — SOMOSAGILITY-16

Foi pedido que Fabio Soto deixe de receber por e-mail o relatório "Leads Semanais" que é enviado toda semana. Os demais destinatários continuam recebendo. Para quem usa, nada muda na tela do relatório.

**Situação do teste automático:** não comprovado. A alteração foi feita à mão no ambiente de produção, e o time de testes não pode acessá-lo. Os testes abaixo ficam para quem tem acesso e permissão ali. Registre só contagens e perfis, sem nomes ou e-mails.

## Antes de começar
- Ambiente: o mesmo em que a alteração foi feita (produção).
- Perfil: administrador ou quem pode ver os agendamentos de relatórios.
- Nada a criar: o teste usa o relatório existente.

## Teste 1 — Fabio Soto não está mais entre os destinatários
1. Abra a aba Relatórios e procure "Leads Semanais".
2. Abra o relatório e clique na seta ao lado de "Editar" e depois em "Agendar futuras execuções".
3. Veja a lista de destinatários.

**Resultado esperado:** Fabio Soto não aparece na lista.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Os demais destinatários continuam
1. Na mesma tela, conte os destinatários.

**Resultado esperado:** 3 destinatários (1 grupo ou papel e 2 usuários), o mesmo que havia antes menos Fabio Soto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — O relatório continua agendado
1. Na mesma tela, confira o status do agendamento e a data da próxima execução.

**Resultado esperado:** o agendamento está ativo, com próxima execução futura, e o relatório abre normalmente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Que nenhuma etapa automática escreveu em produção: está em `05-testes.md`, caso 5.
- O estado "antes" da lista: não foi registrado; peça a quem fez a alteração.
