# EPLAST-36 — Roteiro de teste: públicos de marketing

Foi entregue um conjunto de 58 relatórios na pasta MARKETING CLOUD que formam os públicos de marketing (por região, tipo de cliente, segmento, histórico de compra e produto), mais um perfil de acesso chamado "PS_Marketing_Publicos" para quem trabalha com marketing. Os públicos sempre deixam de fora quem pediu para não receber e-mail, e os relatórios de "Recorrentes (ativos)" agora só trazem clientes do tipo Recorrente. Nada é gravado nas Contas, Oportunidades ou Pedidos.

**Situação do teste automático:** o time executou os testes 1 a 7 na sandbox de QA com dados de teste criados e já apagados, e todos passaram. Ficaram para quem segue este roteiro os testes 8 e 9 (permissão por usuário e campanha), porque dependem de usuários de Marketing reais que o time não tem. O disparo de e-mail é feito pelo Marketing Cloud e não faz parte deste teste.

## Antes de começar
- Ambiente: sandbox de QA (a "QAS" da Eplast). Ela tem dados reais copiados; use só os dados de teste abaixo e não altere nenhum registro real.
- Perfil: para os testes 1 a 7, um administrador. Para os testes 8 e 9, um usuário de Marketing (com o perfil de acesso "PS_Marketing_Publicos" atribuído pelo administrador) e um usuário comum sem esse acesso.
- Dados de teste, criados à mão (nome sempre começando por "TESTE EPLAST-36"):
  - Conta A1: tipo Recorrente, estado de cobrança SP, setor Alimentos; Oportunidade Fechado/Ganho com data de fechamento há 30 dias. Crie nela dois Contatos: um normal e um com "Não enviar e-mail" marcado.
  - Conta A2: Recorrente, MG, setor Bebidas, Oportunidade ganha há 120 dias, um Contato.
  - Conta A3: Inativo, SP, Alimentos, Oportunidade ganha há 200 dias, um Contato.
  - Conta A4: Sazonal, RJ, setor Industrial, Oportunidade ganha há 400 dias, um Contato.
  - Conta A5: Recorrente, SP, Alimentos, sem Oportunidade ganha, um Contato.
  - Lead L1: SP, setor Alimentos. Lead L2: SP, Alimentos, com "Não enviar e-mail" marcado. Lead L3: MG, setor Bebidas.
  - Ao terminar, apague todos esses registros.

## Teste 1 — Público por região e tipo
1. Abra Relatórios e a pasta MARKETING CLOUD.
2. Abra "RECORRENTES (ATIVOS) - SP" e leia a lista.
3. Abra "RECORRENTES (ATIVOS) - MG" e depois "RECORRENTES (ATIVOS) - RJ".

**Resultado esperado:** SP mostra os contatos de A1 e A5 (o contato com "Não enviar e-mail" não aparece). MG mostra o contato de A2. RJ não mostra nenhum contato de teste (A4 é Sazonal).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Sazonais
1. Abra "SAZONAIS - RJ", depois "SAZONAIS - SP".

**Resultado esperado:** RJ mostra o contato de A4. SP não mostra nenhum contato de teste.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Segmento de Contas e de Leads
1. Abra "SEGMENTO - ALIMENTOS", "SEGMENTO - BEBIDAS" e "SEGMENTO - INDUSTRIAL".
2. Abra "LEADS - SEGMENTO - ALIMENTOS", "LEADS - SEGMENTO - BEBIDAS", "LEADS - SP" e "LEADS - MG".

**Resultado esperado:** Alimentos traz os contatos de A1, A3 e A5. Bebidas traz o de A2. Industrial traz o de A4. Leads: Alimentos e SP trazem só L1; Bebidas e MG trazem só L3. L2 não aparece em nenhum.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Clientes inativos
1. Abra "INATIVOS - GERAL".

**Resultado esperado:** aparece o contato de A3 (e nenhum de A1, A2, A4 ou A5).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Histórico de compra por faixa
1. Abra "COMPRA - ÚLTIMOS 90 DIAS", "SEM COMPRA - 91 A 180 DIAS", "SEM COMPRA - 181 A 365 DIAS" e "SEM COMPRA - MAIS DE 365 DIAS".

**Resultado esperado:** A1 só na primeira; A2 só na segunda; A3 só na terceira; A4 só na quarta. A5 (sem compra registrada) não aparece em nenhuma das quatro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Quem pediu para não receber e-mail
1. Em cada relatório dos testes 1 a 5, procure o contato de A1 com "Não enviar e-mail" e o Lead L2.

**Resultado esperado:** eles não aparecem em nenhum relatório da pasta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Público por produto
1. Crie um Pedido da Conta A1 com um produto de teste (nome começando por "TESTE EPLAST-36").
2. Abra "PRODUTO - CONTAS POR PRODUTO COMPRADO" e filtre pelo nome da Conta "TESTE EPLAST-36" (sem salvar o filtro).

**Resultado esperado:** aparece o produto de teste e, dentro dele, a Conta A1. Número do pedido, data, status, família e quantidade aparecem; não aparece nenhum valor em reais.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Acesso por perfil
1. Entre com o usuário de Marketing (com "PS_Marketing_Publicos") e abra Relatórios, pasta MARKETING CLOUD.
2. Abra um relatório, por exemplo "SEGMENTO - ALIMENTOS".
3. Entre com o usuário comum, sem o acesso, e tente abrir a mesma pasta.

**Resultado esperado:** o usuário de Marketing vê e roda os relatórios, sem ver valores de compra e sem conseguir editar Contas. O usuário comum não vê a pasta nem os públicos (ou recebe acesso negado).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Público congelado numa campanha
1. Com o usuário de Marketing, crie uma Campanha chamada "PUB - TESTE EPLAST-36".
2. Abra "RECORRENTES (ATIVOS) - SP" e use "Adicionar à campanha", escolhendo essa campanha.
3. Mude o tipo da Conta A5 de Recorrente para Sazonal.
4. Veja os membros da campanha e rode o relatório de novo.

**Resultado esperado:** os membros ficam como estavam ao adicionar (congelados); o relatório "RECORRENTES (ATIVOS) - SP" deixa de mostrar o contato de A5.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Segmentação é por filtros combináveis em relatório e campanha, sem inteligência artificial.** A Eplast já segmenta assim. Se quiserem linguagem natural ou pontuação, é outra demanda.
- **Os públicos ficam no Salesforce (relatório ou campanha) e o Marketing Cloud os lê.** Não há exportação por arquivo.
- **Relatório é público dinâmico; campanha é público congelado.** O usuário escolhe qual usar.
- **Histórico de compra** = data da última compra, em quatro faixas: até 90, 91 a 180, 181 a 365 e mais de 365 dias. Confirmem se as faixas servem.
- **Região** = as 7 regiões comerciais (CO, ES, MG, NO/NE, RJ, SP, SUL) pela UF de cobrança da Conta e pela UF do Lead. Não existe o relatório "LEADS - NO/NE" (lacuna conhecida).
- **Segmento** = o campo Setor da Conta e do Lead. Campanha de público começa com "PUB -" e tem tipo "Outro".
- **Quem pediu para não receber e-mail não entra em nenhum público**, inclusive nos relatórios que já existiam (isso reduz a contagem deles).
- **Valores de compra não entram nos públicos.** Só categoria, setor, região e datas.
- **Quem usa:** usuários de Marketing, com o acesso "PS_Marketing_Publicos" atribuído por um administrador.
- **A data da última compra é usada como está.** Não confirmamos quem a mantém atualizada em produção.
- **Os relatórios "RECORRENTES (ATIVOS) - <região>" estavam sem o filtro de tipo; corrigimos** para trazer só clientes Recorrentes. A contagem desses relatórios muda.

## O que não dá para conferir pela tela
- Todas as contagens, a ausência de gravação em Contas, Oportunidades e Pedidos e as permissões do perfil de acesso foram comprovadas pelo time com consultas; a evidência está em `05-testes.md`.
- O relatório "PRODUTO - CONTAS POR PRODUTO COMPRADO" salvo traz só as primeiras 10.000 linhas na QAS; use filtro de período ou produto.
- A leitura dos públicos pelo Marketing Cloud e o envio de e-mails são feitos por quem opera o Marketing Cloud, fora deste teste.
