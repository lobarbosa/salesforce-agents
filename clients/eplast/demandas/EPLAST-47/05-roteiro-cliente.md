# EPLAST-47 — Roteiro de teste: classificação da conta ao salvar a oportunidade

Agora a classificação da conta (MP, PP, P, M, G, GG, 3G) é atualizada no momento em que uma oportunidade ganha é salva, em vez de uma rotina mensal em lote. A conta recebe as novas faixas de valor, o campo "Valor da última compra" mostra a soma das compras ganhas do ano, e o histórico da classificação fica registrado. A rotina mensal antiga foi desativada.

**Situação do teste automático:** o time já comprovou, na sandbox de homologação, as faixas (incluindo as bordas 10.000, 35.000,01 e 1.000.000,01), a soma, o histórico, a ausência de erros de limite e a desativação da rotina antiga. Ficou para quem segue este roteiro o teste 5 (comportamento em caso de falha), que não dá para provocar no ambiente do time.

## Antes de começar
- Ambiente: sandbox de homologação (QAS da Eplast). Perfil: o de vendas que salva oportunidades.
- Use só contas de teste. Crie uma conta com o nome "TESTE EPLAST-47 Conta 1" e uma oportunidade de indústria vinculada a ela, com valor 3.000, em fase anterior à ganha, com forma de pagamento "À vista".
- O proprietário da conta precisa ter o campo "ID Usuário Protheus" preenchido.
- Para a classificação ser calculada, a oportunidade precisa de uma cotação aprovada ligada a ela (é assim que a média do ano é calculada hoje).

## Teste 1 — Classificação ao ganhar a oportunidade
1. Abra a oportunidade de teste de 3.000.
2. Mude a fase para "Fechado/Ganho" e salve.
3. Abra a conta de teste.

**Resultado esperado:** campo "Classificação" = MP e "Valor da última compra" = 3.000.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Limites das faixas
1. Crie contas de teste, cada uma com uma única oportunidade ganha com os valores abaixo.
2. Confira a "Classificação" de cada conta.

**Resultado esperado:** 10.000 = MP; 10.000,01 = PP; 35.000 = PP; 35.000,01 = P; 80.000 = P; 80.000,01 = M; 160.000 = M; 160.000,01 = G; 500.000 = G; 500.000,01 = GG; 1.000.000 = GG; 1.000.000,01 = 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Soma das compras do ano
1. Na conta de teste, tenha uma ganha de 3.000.
2. Crie outra oportunidade para a mesma conta com 2.000 e marque como ganha.
3. Crie uma terceira de 9.000 e marque como perdida.

**Resultado esperado:** "Valor da última compra" = 5.000; a perdida não entra.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Ganha que vira perdida
1. Numa conta de teste com uma única ganha de 10.000, mude essa oportunidade para "Fechado/Perdido".

**Resultado esperado:** "Valor da última compra" = 0, e a classificação não vira GG (continua a anterior).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Histórico, relatório e lista de classificações
1. Na conta de teste, abra o histórico do campo "Classificação".
2. Abra o relatório "AccountRankingChanges" (pasta EPLAST47) e localize a conta de teste.
3. Abra o campo "Classificação" e veja as opções.

**Resultado esperado:** o histórico mostra o valor anterior e o novo; o relatório mostra a mudança da conta de teste; as opções são MP, PP, P, M, G, GG e 3G.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Falha na classificação não barra a venda
Este teste só é possível com apoio do time técnico, porque exige provocar uma falha na gravação da conta.
1. Com o time, provoque uma falha na gravação da conta ao salvar uma oportunidade ganha de teste.

**Resultado esperado:** a oportunidade é salva normalmente; a falha fica registrada no log de integração; e-mail só se houver destinatário configurado (hoje vazio, então sem e-mail).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Rotina mensal antiga desligada
1. Peça ao time para confirmar em Configuração > Fluxos que "ScheduledFlowOpportunity" não tem versão ativa.

**Resultado esperado:** nenhuma versão ativa e nenhuma execução agendada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- A base é a soma das oportunidades "Fechado/Ganho" do ano (data de criação da oportunidade), como hoje.
- A classificação usa a média do ano já calculada pelo sistema; sem média calculada, a classificação não muda (nunca vira GG). Média 0 vira MP.
- Conta sem compra: "Valor da última compra" = 0.
- Aviso de falha: só registro no log; e-mail somente se a Eplast informar um destinatário (hoje vazio).
- Troca de conta numa oportunidade ganha: só a conta nova é recalculada. Exclusão ou restauração de oportunidade não recalcula.
- Oportunidades de anos anteriores não disparam o cálculo.
- A rotina mensal antiga foi desativada (não apagada) e pode ser reativada.
- O relatório fica provisoriamente na pasta EPLAST47.
- O envio ao ERP (Protheus) não muda e não usa a classificação.

## O que não dá para conferir pela tela
- Ausência de erros de limite de fila e de bloqueio de registro ao salvar várias oportunidades, e o estado do agendamento: evidência em `05-testes.md` (consultas na sandbox de homologação).
- Carga em volume: não aplicável nesta demanda (decisão registrada no desenho).
