# Roteiro de teste — Alerta de oportunidade parada (EPLAST-28)

Foi entregue um aviso diário dentro do Salesforce (sino de notificações): quando uma oportunidade aberta fica parada, sem atividade registrada e sem mudança de etapa, durante o número de dias configurado (padrão 14), o dono da oportunidade recebe uma notificação com o nome da oportunidade, a conta, a etapa e os dias parada. O aviso não altera nenhuma oportunidade, não envia e-mail e sai uma única vez por período de parada.

**Situação do teste automático:** a configuração do aviso para teste (3 dias, só atividade) foi armada na sandbox de QA, com disparo às 04:05 UTC de 16/11/2026. Até a escrita deste roteiro nada tinha sido comprovado: o resultado do disparo é conferido pelo time em uma segunda sessão (veja `05-testes.md`). Os testes abaixo, feitos à mão, não foram executados por mim. O comportamento do dia seguinte (Teste 5) e do gestor (Teste 6) só se conferem à mão.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a "QAS"). Perfil: o usuário dono das oportunidades de teste, ou um usuário comum de vendas.
- Dados de teste: na Conta "TESTE EPLAST-28" existem quatro oportunidades de teste (nomes começam por "TESTE EPLAST-28"). Se precisar recriar, crie uma conta e quatro oportunidades com esse prefixo. Registre uma tarefa (atividade) com data de 13/11 na primeira e na quarta, e outra com data de 14/11 na segunda. Deixe a terceira sem atividade. Feche a quarta como "Fechado/Perdido".
- Os avisos só saem na hora do disparo agendado; depois dele, abra o sino de notificações no topo do Salesforce.

## Teste 1 — Oportunidade parada alerta o dono
1. Entre como dono das oportunidades de teste.
2. Clique no sino de notificações.
3. Procure o aviso "Oportunidade parada há 3 dias".
4. Clique no aviso.

**Resultado esperado:** aviso mostrando o nome da oportunidade parada (a de atividade em 13/11), a conta, a etapa "Qualificado" e "3 dias"; o clique abre essa oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Oportunidade com atividade recente não alerta
1. No sino de notificações, procure aviso para a oportunidade com atividade em 14/11.

**Resultado esperado:** nenhum aviso para ela.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Oportunidade sem atividade
1. No sino, procure aviso para a oportunidade criada sem atividade.

**Resultado esperado:** nenhum aviso enquanto ela tiver menos dias que o prazo (3). Com prazo vencido, o aviso usa a data de criação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Oportunidade fechada nunca alerta
1. No sino, procure aviso para a oportunidade "Fechado/Perdido".

**Resultado esperado:** nenhum aviso.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Sem repetição no dia seguinte
1. No dia seguinte ao Teste 1, abra o sino.

**Resultado esperado:** nenhum segundo aviso para a mesma oportunidade parada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Gestor só recebe se ligado
1. Com a opção de avisar o gestor desligada (padrão), confira que o gestor do dono não recebe aviso.
2. Peça ao time para ligar a opção "Notificar gestor" e repita no disparo seguinte.

**Resultado esperado:** desligada, só o dono recebe; ligada, o gestor direto também.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Nada é alterado nas oportunidades
1. Abra a oportunidade parada e veja "Última modificação" no histórico.

**Resultado esperado:** a data não mudou por causa do aviso; nenhuma tarefa nova apareceu.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- "Parada" significa sem atividade registrada e sem mudança de etapa há N dias; qualquer atividade conta, inclusive tarefa criada automaticamente.
- Prazo único de 14 dias, ajustável sem desenvolvimento.
- O aviso é só interno (sino), uma vez por período de parada, ao dono; gestor desligado por padrão.
- O aviso só informa: não cria tarefa nem altera a oportunidade.
- Fechadas nunca alertam; todos os tipos de registro de oportunidade entram.
- Cada aviso enviado fica registrado em um log técnico, sem nome nem valor.
- Dono inativo não recebe aviso; fica registrado no log, sem reatribuição.
- O aviso não substitui a pergunta ao assistente de acompanhamento de clientes; os dois se complementam.

## O que não dá para conferir pela tela
Volume (dezenas de oportunidades paradas de uma vez), limites da plataforma, o registro técnico dos avisos enviados e a ausência de e-mail ficam com o time técnico; a evidência estará em `05-testes.md` (rodada 3, fase 2).
