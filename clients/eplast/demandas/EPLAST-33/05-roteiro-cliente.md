# EPLAST-33 — Roteiro de teste: Sinais comerciais

Foi entregue um cálculo diário que gera "sinais comerciais" por conta: conta que não compra há mais de 90 dias (recuperação), conta que nunca comprou, queda de volume por família de produto, histórico insuficiente para comparar e sugestão de venda cruzada por segmento. Eles aparecem no relatório "Sinais Comerciais por Conta". Para quem usa: o time comercial passa a ter uma lista pronta de contas para abordar, sem montar planilha. A consulta por assistente (chat) não faz parte desta entrega.

**Situação do teste automático:** comprovado pelo time na sandbox de QA: o cálculo e os limites (91/90/89 dias, queda de 20,0% e 19,99%, histórico insuficiente, unidades misturadas, segmento pequeno), a ausência de alteração em contas, pedidos e oportunidades, a ausência de e-mails e as colunas do relatório. Ficou para quem segue este roteiro: ver os sinais pela tela, a visibilidade por usuário (o usuário de teste existente está inativo) e a conferência de uma amostra contra o ERP (Protheus).

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a "QAS"). Perfil: o seu usuário comercial, com o conjunto de permissões "Comercial - Sinais Comerciais" atribuído pelo administrador.
- Não precisa criar dado: o cálculo já rodou sobre as contas da QAS. Escolha, no relatório, uma conta que você conheça e anote o último pedido faturado dela.
- Quem agenda o cálculo diário precisa ter o mesmo conjunto de permissões (ou ser administrador); sem isso o cálculo roda e não grava nada.

## Teste 1 — O relatório mostra os sinais com as colunas novas
1. No menu, abra Relatórios e procure "Sinais Comerciais por Conta".
2. Abra o relatório.
3. Confira as colunas.

**Resultado esperado:** aparecem conta, segmento, UF de cobrança, tipo do sinal, família, produto, dias sem compra, valores e quantidades do período atual e da base, unidade, variação percentual, data da última compra, motivo e data do cálculo. Não aparece e-mail, telefone nem CPF.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Recuperação só com mais de 90 dias
1. No relatório, filtre o tipo "Recuperação".
2. Ordene por "Dias sem compra" do menor para o maior.

**Resultado esperado:** o menor valor é 91. Nenhuma conta com 90 dias ou menos.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Queda de volume por família
1. Filtre o tipo "Queda de volume".
2. Escolha uma conta e olhe família, valor do último mês fechado e média dos três meses anteriores.

**Resultado esperado:** cada linha tem família preenchida; a variação mostra queda de 20% ou mais; família com unidades diferentes (UN e KG) mostra "MISTA" na unidade. Na QAS não há pedidos faturados em outubro, então as quedas aparecem como 100%; isso é esperado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Histórico insuficiente e conta sem sobreposição
1. Filtre o tipo "Histórico insuficiente".
2. Pegue uma conta dessa lista e procure-a na lista de Recuperação e de "Nunca comprou".

**Resultado esperado:** a conta tem família preenchida (comprou a família em menos de 2 dos 3 meses da base) e não aparece como recuperação nem como "nunca comprou". Nenhuma conta aparece em recuperação ou "nunca comprou" junto com sinal de volume.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Venda cruzada por segmento
1. Filtre o tipo "Venda cruzada".
2. Escolha uma conta e veja a família sugerida e o motivo.
3. Use o filtro de segmento e de UF.

**Resultado esperado:** a família sugerida é diferente das que a conta já compra; nunca aparece "Sem familia"; no máximo 3 sugestões por conta; os filtros de segmento e UF funcionam.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Não aparece alta de volume
1. Filtre o tipo "Alta de volume".

**Resultado esperado:** nenhum resultado (a alta está desligada por configuração).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Conferir com o ERP (Protheus)
1. Escolha 3 contas de Recuperação.
2. No Protheus, veja a data do último pedido faturado de cada uma.
3. Compare com "Data da última compra" e "Dias sem compra".

**Resultado esperado:** as datas batem com o último pedido faturado (status Faturamento ou Concluído, sem cancelados).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem não tem permissão não vê
1. Entre com um usuário comercial que não tenha o conjunto "Comercial - Sinais Comerciais" (o usuário de teste existente está inativo; peça ao administrador um usuário comum).
2. Procure o relatório e a aba "Sinais Comerciais".

**Resultado esperado:** o usuário não vê os sinais. Com o conjunto atribuído, vê só as contas da sua carteira.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Data de faturamento:** usamos a "Data de emissão" do pedido (`EffectiveDate`). O campo "Data emissão" alternativo está vazio em todos os 8095 pedidos faturados da QAS. Confirme se a data usada é a que vocês consideram. Dá para trocar sem deploy.
- **Status "faturado":** contam "Faturamento" e "Concluído". Se "Faturamento" significar "em faturamento", troca-se para só "Concluído".
- **Valor e quantidade:** o alerta dispara pelo valor (sem imposto e sem devolução); a quantidade aparece ao lado, e "MISTA" quando as unidades diferem.
- **Família:** o campo "Grupo" do produto (PREF, TAMP, RESI, ALCA, GPET); produto sem grupo entra como "Sem familia" e nunca é sugerido na venda cruzada. O significado dos códigos foi inferido pelo nome.
- **Histórico insuficiente:** a conta precisa ter comprado a família em pelo menos 2 dos 3 meses da base.
- **Sobreposição:** conta em recuperação ou "nunca comprou" não recebe sinal de volume.
- **Venda cruzada:** sugerimos a família, não o item, porque a org não tem tabela de compatibilidade técnica; o vendedor escolhe o item compatível.
- **Região:** a UF de cobrança da conta, só como filtro do relatório.
- **90 dias:** recuperação a partir de 91 dias sem compra.
- Mantidos da rodada anterior: sem contato automático com o cliente, cálculo diário às 04:00 UTC, sem notificação, até 10 sugestões cruzadas no cálculo (3 por conta nesta configuração), todas as contas, "nunca comprou" desligável.

## O que não dá para conferir pela tela
- Execução agendada e jobs, carga e limites: evidência em `05-testes.md` (execução das 14:41 UTC, que falhou por falta de permissão de quem agendou, e a reexecução com permissão, sem erro).
- Que contas, pedidos e oportunidades não foram alteradas e que nenhum e-mail saiu: contagens em `05-testes.md`.
