# EPLAST-28 — Roteiro de teste: alerta de oportunidade parada

Foi entregue um aviso automático, uma vez por dia, que notifica o dono de cada oportunidade aberta que ficou parada (sem atividade e sem mudança de estágio) por mais tempo que o prazo configurado. O aviso aparece no sino do Salesforce. Nada é alterado nas oportunidades, contas ou pedidos.

**Situação do teste automático:** comprovado pelo time na sandbox de QA: o aviso é gerado só para a oportunidade aberta parada no prazo (registrado no log de integração), não para as recentes nem para as fechadas, e nada nas oportunidades muda. Ficou para quem segue este roteiro: ver o aviso no sino, o dia seguinte sem repetição e o aviso ao gestor, porque o time não consegue ver a tela do sino do dono nem esperar até o dia seguinte.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a "QAS").
- Perfil: o dono das oportunidades de teste (as de nome "TESTE EPLAST-28") ou um administrador.
- Dado de teste: existem 4 oportunidades "TESTE EPLAST-28". Para criar outra: crie uma oportunidade aberta, registre uma atividade (tarefa ou evento) com data de 3 dias atrás e peça ao time técnico para ajustar a data de referência, pois a tela não permite datas de criação no passado. O prazo hoje está em 14 dias na versão final, e em 3 dias durante o teste.

## Teste 1 — Oportunidade parada recebe o aviso
1. Entre como o dono da oportunidade "TESTE EPLAST-28" com última atividade há 3 dias.
2. Clique no sino de notificações no topo da tela.
3. Procure o aviso "Oportunidade parada".

**Resultado esperado:** um aviso com nome da oportunidade, nome da conta, estágio, quantos dias parada e link para abrir a oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade recente ou fechada não gera aviso
1. No sino, confira as oportunidades "TESTE EPLAST-28" com atividade há 1 ou 2 dias e a fechada.

**Resultado esperado:** nenhum aviso para elas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Sem repetição no dia seguinte
1. No dia seguinte ao aviso, abra o sino de novo.

**Resultado esperado:** o aviso da mesma oportunidade parada não aparece de novo se nada mudou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — A oportunidade não é alterada
1. Abra a oportunidade que recebeu o aviso e olhe o histórico e a data de última modificação.

**Resultado esperado:** nenhuma alteração causada pelo aviso (sem tarefa nova, sem campo mudado).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Oportunidade parada = sem atividade e sem mudança de estágio por N dias; vale a mais recente das duas.
- Tarefas criadas automaticamente também contam como acompanhamento.
- Prazo único de 14 dias, ajustável sem desenvolvimento.
- Aviso só dentro do Salesforce (sino), uma vez por episódio, avaliado uma vez por dia; nada de e-mail.
- Só o dono é avisado; o aviso ao gestor vem desligado.
- Toda oportunidade aberta entra, de qualquer tipo de registro.
- O aviso só avisa: não cria tarefa nem altera campos.
- O aviso mostra nome da oportunidade, conta, estágio, dias e link, sem dados de contato.
- O alerta complementa o assistente de acompanhamento de clientes e não o substitui.

## O que não dá para conferir pela tela
Execução agendada, carga sobre toda a base e ausência de falhas: evidência em `demandas/EPLAST-28/05-testes.md`.
