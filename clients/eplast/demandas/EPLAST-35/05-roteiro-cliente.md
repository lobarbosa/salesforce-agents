# EPLAST-35 — Roteiro de teste: distribuição de Leads

Foi entregue a distribuição automática de Leads: o Lead novo vai para a regional pela UF, e se o CNPJ dele já for de uma conta da Eplast, o Lead vai para o dono dessa conta. Sem conta, ele vai para um vendedor da fila da região, em rodízio. Aprovação e encaminhamento interno não foram construídos (os 3 processos de aprovação continuam como estão).

**Situação do teste automático:** comprovamos só que os itens chegaram à QAS (campo, fila nova `Leads RJ/ES`, regra nova inativa, configuração desligada). O comportamento em si (dono da conta, rodízio, regional) **não foi comprovado**: ele só funciona com a regra nova ativa e a configuração ligada, o que depende de a homologação da outra demanda de Leads (EPLAST-38) fechar, ou do aceite do responsável para homologar as duas juntas. Todos os testes abaixo ficam para quem segue este roteiro, depois que o time avisar que a distribuição foi ligada.

## Antes de começar
- Ambiente: sandbox de QA (a "QAS" da Eplast).
- Perfil: um usuário comercial (por exemplo "Comercial - Analista") e um administrador.
- Peça ao time que confirme que a distribuição está ligada e que a fila "Leads RJ/ES" tem pelo menos 2 vendedores de teste (ativos).
- Dados de teste: crie contas com nome "TESTE EPLAST-35 ..." e CNPJ fictício; uma com CNPJ só em números e outra com pontos e barra. Use só dados inventados; não use cliente real.
- Leads de teste: sobrenome "TESTE EPLAST-35", empresa fictícia, sem telefone ou com telefone válido de teste.

## Teste 1 — Lead vai para a região pela UF
1. Abra Leads e clique em Novo.
2. Preencha sobrenome "TESTE EPLAST-35 SP", empresa fictícia, UF "SP".
3. Marque a caixa "Atribuir usando regras ativas" e salve.
**Resultado esperado:** o Proprietário do Lead é um vendedor da fila "Leads SP", não a fila. No histórico de proprietário aparece a fila e depois o vendedor.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — RJ e ES caem na mesma fila
1. Crie dois Leads de teste, um com UF "RJ" e outro com UF "ES", caixa marcada.
**Resultado esperado:** os dois ficam com vendedor de "Leads RJ/ES" (ou na própria fila, se ela estiver sem vendedores). Nenhum em "Leads RJ" ou "Leads ES".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rodízio entre vendedores da região
1. Crie 4 Leads de teste seguidos, todos com UF "MG", caixa marcada.
**Resultado esperado:** os vendedores da fila de MG se alternam (A, B, A, B), desde que não entre outro Lead no meio. O rodízio é aproximado: com Leads de outras regiões intercalados, dois seguidos da mesma região podem cair no mesmo vendedor.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Conta existente manda o Lead para o dono dela
1. Crie uma conta "TESTE EPLAST-35 Conta" com CNPJ fictício, tendo você ou um colega ativo como dono.
2. Crie um Lead de teste com o mesmo CNPJ e UF de outra região (por exemplo "PR"), caixa marcada.
**Resultado esperado:** o Proprietário do Lead é o dono da conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — CNPJ com e sem pontuação
1. Repita o Teste 4 com o CNPJ do Lead com pontos e barra e o da conta só números, e depois o inverso.
**Resultado esperado:** nos dois casos o dono é o da conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Duas contas com o mesmo CNPJ, ou dono inativo
1. Crie duas contas de teste com o mesmo CNPJ e donos diferentes; depois um Lead com esse CNPJ.
2. Crie uma conta cujo dono esteja inativo e um Lead com esse CNPJ.
**Resultado esperado:** nenhum dos dois usa o dono da conta; os Leads vão para o rodízio da região.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — UF vazia e fila sem vendedor
1. Crie um Lead sem UF e sem conta casada. Depois um sem UF com conta casada.
2. Crie um Lead de uma região cuja fila só tenha vendedor inativo.
**Resultado esperado:** sem UF e sem conta, fica em "Leads Triagem". Com conta, vai para o dono dela. Fila sem vendedor ativo: o Lead fica na fila.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Caixa desmarcada
1. Crie um Lead de teste sem marcar "Atribuir usando regras ativas".
**Resultado esperado:** o Proprietário é você.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Transferência manual e interruptor
1. Transfira um Lead de teste para a fila "Leads MG" (Alterar proprietário).
2. Peça ao time para desligar a distribuição e repita.
**Resultado esperado:** com ela ligada, o Lead vai para um vendedor da fila. Desligada, não acontece nada (ele fica na fila).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Usuário comercial sem acesso especial
1. Entre como "Comercial - Analista" e crie um Lead de teste de uma região com vendedores.
**Resultado esperado:** o Lead é distribuído e nenhum erro de acesso aparece. Se o vendedor sorteado não puder ver Leads, o Lead fica na fila e é salvo sem erro.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 11 — Nada acontece em Contas, Oportunidades e Pedidos
1. Antes e depois dos testes, veja o total de contas, oportunidades e pedidos (relatório simples).
**Resultado esperado:** os totais só mudam pelas contas de teste que você criou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Como casar Lead e conta:** só pelo CNPJ, com ou sem pontuação, e só quando há exatamente uma conta. Se a Eplast quiser outro critério, o time ajusta. Já conferimos na QAS que todas as contas com CNPJ usam uma dessas duas formas.
- **Como é a vez no rodízio:** pelo número sequencial do Lead dividido pelos vendedores da fila. É aproximado: dois Leads seguidos da mesma região podem ir para o mesmo vendedor; em volume, equilibra. Dá para trocar a fórmula.
- **Dono da conta inativo (ou usuário de integração):** é ignorado e o Lead vai para o rodízio.
- **Transferência manual para fila regional:** sempre redistribui. Para deixar um Lead parado numa fila, use "Leads Triagem", que não tem rodízio.
- **Lead antigo, sem o número de rodízio:** o dono da conta vale; sem conta, ele fica na fila.
- **Falha na distribuição:** o Lead fica na fila e o salvamento não é desfeito.
- **Interruptor geral:** a distribuição chega desligada; o time liga depois. Entra em vigor na QAS só depois de fechar a homologação da outra demanda de Leads (EPLAST-38), ou com aceite para homologar as duas juntas.
- Quem entra no rodízio: vendedores ativos que são membros diretos da fila regional. Sem rodízio na "Leads Triagem". As filas "Leads RJ" e "Leads ES" saem da distribuição (não foram apagadas).

## O que não dá para conferir pela tela
- Consumo de limites da plataforma em lote de 200 Leads, e comportamento do usuário de integração: o time técnico mede depois que a distribuição estiver ligada; a evidência ficará em `05-testes.md`.
- Que os 3 processos de aprovação, o Flow antigo e as classes da outra demanda não mudaram: conferência técnica registrada em `05-testes.md`.
