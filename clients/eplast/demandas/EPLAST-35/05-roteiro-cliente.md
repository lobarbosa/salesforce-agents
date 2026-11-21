# Roteiro de teste: distribuição de Leads por região, dono da conta e rodízio

Foi entregue a nova distribuição de Leads. Todo Lead novo, criado com a caixa de distribuição marcada, vai para a fila da sua região (agora com RJ e ES juntos na fila "Leads_RJ_ES"). Se o CNPJ do Lead pertence a exatamente uma conta já cadastrada, o Lead vai direto para o dono dessa conta. Caso contrário, é sorteado um vendedor entre os membros da fila da região, em rodízio.

**Situação do teste automático:** a equipe executou na QAS, com dados de teste e já apagados, a distribuição por região (inclusive RJ e ES), o dono da conta pelo CNPJ (com e sem pontuação), o rodízio, a fila sem vendedor, a caixa desmarcada, a transferência manual e um lote de 200 Leads (dentro dos limites). Ficaram para quem segue este roteiro: o teste com o perfil Comercial - Analista pela tela, o desligamento da distribuição pelos interruptores e o caso de dono de conta inativo. Pela tela, nenhum teste abaixo depende de código.

## Antes de começar
- **Ambiente:** a sandbox QAS (Sandbox QAS da Eplast). Nunca em produção.
- **Perfil:** um administrador para montar o teste e o preparo (Testes 1 a 7). Para o Teste 7, um usuário com o perfil Comercial - Analista.
- **Dados de teste (criar e depois apagar):**
  1. Duas contas de teste: "TESTE EPLAST-35 Conta A", CNPJ `99000000000100` (só números), dono: você; e "TESTE EPLAST-35 Conta B", CNPJ `99.000.000/0002-00` (com pontuação), dono: um vendedor.
  2. Duas contas de teste com o mesmo CNPJ `99000000000003`, donos diferentes ("TESTE EPLAST-35 Conta C" e "Conta D"), para o Teste 4.
  3. Em Configuração, Filas, abra "Leads_RJ_ES" e inclua como membros dois usuários ativos de teste.
- Ao criar cada Lead, deixe marcada a caixa "Atribuir usando regras de atribuição ativas" (salvo no Teste 6). Nome: "TESTE EPLAST-35 ..."; Empresa: "TESTE EPLAST-35".

## Teste 1 — Lead de RJ ou ES vai para a fila nova e para um vendedor
1. Crie um Lead com Estado "RJ".
2. Crie outro Lead com Estado "ES".
3. Abra cada um e olhe o campo Proprietário do lead.

**Resultado esperado:** o proprietário é um dos dois vendedores membros de "Leads_RJ_ES", não a fila "Leads_RJ" nem "Leads_ES". Criando mais Leads de RJ/ES um após o outro, os dois vendedores se revezam.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Região sem vendedor deixa o Lead na fila
1. Crie um Lead com Estado "SP" (a fila de SP não tem vendedor membro direto na QAS).
2. Crie um Lead com Estado "GO".

**Resultado esperado:** o proprietário do primeiro é a fila "Leads_SP" e do segundo a fila "Leads_CO".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead com CNPJ de uma conta vai para o dono da conta
1. Crie um Lead com Estado "RS" e CNPJ `99.000.000/0001-00` (com pontuação; a Conta A foi cadastrada só com números).
2. Crie um Lead com Estado "RS" e CNPJ `99000000000200` (só números; a Conta B foi cadastrada com pontuação).
3. Crie um Lead sem Estado, com o CNPJ `99000000000100`.

**Resultado esperado:** o proprietário dos Leads 1 e 3 é o dono da Conta A; o do Lead 2 é o dono da Conta B. Em nenhum caso é a fila "Leads_Sul".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — CNPJ em mais de uma conta não escolhe dono
1. Crie um Lead com Estado "RS" e CNPJ `99000000000003`.

**Resultado esperado:** o Lead fica com a fila "Leads_Sul", não com o dono da Conta C nem da D.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Lead sem Estado e sem CNPJ conhecido vai para a Triagem
1. Crie um Lead sem Estado e sem CNPJ.

**Resultado esperado:** o proprietário é a fila "Leads_Triagem".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Caixa de distribuição desmarcada
1. Crie um Lead com Estado "RJ", desmarcando a caixa "Atribuir usando regras de atribuição ativas".

**Resultado esperado:** o proprietário é você, quem criou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Perfil Comercial - Analista cria Lead pela tela
1. Entre com um usuário de perfil Comercial - Analista.
2. Crie um Lead com Estado "RJ" e caixa marcada.

**Resultado esperado:** o Lead é salvo sem mensagem de erro e recebe um dono da fila "Leads_RJ_ES".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Transferência manual para uma fila
1. Abra um Lead de teste e use "Alterar proprietário" para a fila "Leads_RJ_ES".

**Resultado esperado:** o Lead passa para um dos vendedores dessa fila. Se transferir para uma fila sem vendedores, como "Leads_MG", ele fica na fila.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Como casar o Lead com a conta:** só pelo CNPJ, com ou sem pontuação. Na QAS, todas as 1221 contas com CNPJ usam uma dessas duas formas. Se preferirem outro critério, avisem.
- **Como é a vez no rodízio:** o vendedor sai do número sequencial do Lead dividido pela quantidade de vendedores da fila. É aproximado: em volume equilibra (200 Leads, 35 para cada um), mas se os Leads chegarem alternando duas regiões, todos de uma região podem cair no mesmo vendedor (nos nossos testes, 20 de 20). Confirmem se aceitam, ou se querem uma regra mais justa.
- **Dono da conta inativo ou integração:** dono inativo é ignorado e o Lead entra no rodízio.
- **Transferência manual:** sempre redistribui para um vendedor da fila. Para deixar um Lead parado, use "Leads_Triagem", que não faz rodízio.
- **Lead criado antes desta entrega** que volta a uma fila: o dono da conta vale; sem conta, fica na fila.
- **Falha na distribuição** (por exemplo, vendedor sem acesso a Lead): o Lead fica na fila e a criação não é desfeita.
- **Interruptor geral:** a distribuição nova chega ligada na QAS, para homologar junto com a entrega da distribuição por região (EPLAST-38). Desmarcar a opção de distribuição ativa desliga tudo, sem nova entrega.

## O que não dá para conferir pela tela
- Lote de 200 Leads (carga) e lote da integração sem tela: evidência em `05-testes.md` (casos T3 e T7; o lote assíncrono da integração ficou sem execução).
- Desligar o interruptor geral ou o rodízio exige alterar a configuração e ficou sem execução.
- Um job de envio ao Protheus foi criado porque converter um Lead de teste atualizou uma conta de teste (comportamento já existente da conta; detalhe em `05-testes.md`).
- Ao terminar, apague os Leads e as contas de teste e retire os membros de teste da fila "Leads_RJ_ES".
