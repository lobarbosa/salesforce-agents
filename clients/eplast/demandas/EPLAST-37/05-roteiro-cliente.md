# Roteiro de teste — Classificação de clientes em Ativo, Inativo e Potencial

Foi entregue um campo novo na conta, "Classe de Relacionamento", que mostra sozinho se o cliente é Potencial (nunca comprou), Inativo (última compra há mais de 90 dias) ou Ativo (comprou nos últimos 90 dias). Há também dois relatórios novos na pasta "MARKETING CLOUD". Para quem usa, muda que a classe passa a ser calculada automaticamente e vista nos relatórios, sem preenchimento manual.

**Situação do teste automático:** o time já comprovou na sandbox de QA, com contas de teste, as três classes, o limite de 90 e 91 dias, a atualização automática quando uma compra é fechada e os dois relatórios. Não foi feita conferência visual pela tela, porque nela aparecem dados reais de clientes; essa parte fica para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (a "QAS"). Perfil: Administrador do sistema ou Marketing.
- Dado de teste: crie 3 contas com o nome começando por "TESTE EPLAST-37" (por exemplo "TESTE EPLAST-37 A", "B" e "C"), cada uma com um contato. Para a conta B, crie uma oportunidade no estágio "Fechado/Ganho" com data de fechamento de 30 dias atrás. Para a C, uma com data de 120 dias atrás. A conta A fica sem oportunidade ganha. Se não conseguir criar oportunidade ganha, peça ao time técnico.
- O campo "Classe de Relacionamento" não está na página da conta (decisão deste desenho); veja-o pelos relatórios.
- Apague os registros de teste ao final.

## Teste 1 — Conta sem compra aparece como Potencial
1. Abra Relatórios e a pasta "MARKETING CLOUD".
2. Abra "CLASSIFICAÇÃO - CONTAS POR CLASSE".
3. Procure a conta "TESTE EPLAST-37 A" (use a busca da página, ou expanda o grupo "Potencial").

**Resultado esperado:** a conta A aparece no grupo "Potencial".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Compra recente aparece como Ativo
1. No mesmo relatório, procure "TESTE EPLAST-37 B".

**Resultado esperado:** a conta B aparece no grupo "Ativo".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Compra antiga aparece como Inativo
1. No mesmo relatório, procure "TESTE EPLAST-37 C".

**Resultado esperado:** a conta C aparece no grupo "Inativo".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Limite de 90 dias
1. Crie duas contas "TESTE EPLAST-37 D" e "TESTE EPLAST-37 E", cada uma com um contato e uma oportunidade "Fechado/Ganho": D com fechamento há exatamente 90 dias e E com 91 dias.
2. Atualize o relatório "CLASSIFICAÇÃO - CONTAS POR CLASSE".

**Resultado esperado:** D aparece em "Ativo" e E em "Inativo".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — A classe muda sozinha quando uma compra é fechada
1. Na conta A (Potencial), crie uma oportunidade e feche como "Fechado/Ganho" com data de 5 dias atrás.
2. Atualize o relatório de classificação.

**Resultado esperado:** a conta A passa para o grupo "Ativo" sem nenhuma outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — O campo Tipo não decide a classe
1. Na conta B, deixe o campo "Tipo" como "Prospect".
2. Atualize o relatório de classificação.

**Resultado esperado:** a conta B continua em "Ativo" (a classe usa a data da última compra, não o Tipo). No relatório, dentro de "Ativo", a conta aparece sob "Prospect".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Relatório de públicos Potenciais, sem opt-out e sem dados pessoais
1. Crie um contato na conta A com a opção "Cancelou recebimento de e-mails" marcada (antes do Teste 5, ou use outra conta sem compra).
2. Abra o relatório "POTENCIAIS - SEM COMPRA" na pasta "MARKETING CLOUD".

**Resultado esperado:** aparecem contatos de contas sem compra que não cancelaram e-mail; o contato que cancelou não aparece. As colunas são Id do contato, nome, sobrenome, conta, Classe de Relacionamento e proprietário: não há e-mail nem telefone.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem enxerga o campo
1. Entre com um usuário de cada perfil que usa o relatório (por exemplo Marketing e Comercial).
2. Abra "CLASSIFICAÇÃO - CONTAS POR CLASSE".

**Resultado esperado:** a coluna/grupo "Classe de Relacionamento" aparece para quem já vê o campo "Inativo" das contas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Potencial** é a conta que nunca teve oportunidade ganha. Se preferirem outro critério, dizer.
- **Inativo** é mais de 90 dias sem compra, a regra que o campo "Inativo" já aplica hoje. Mudar a janela é ajuste em um lugar só.
- **Ativo** é quem comprou e não está inativo.
- **Compra** é oportunidade "Fechado/Ganho"; pedido do Protheus sem oportunidade não conta. Confirmem com o Comercial numa amostra de contas.
- O campo **Tipo** (Inativo, Prospect etc.) não define a classe; o relatório mostra as divergências e vocês decidem se o Tipo passa a ser fonte.
- O **porte** (campo Classificação) não entra na classe.
- A classe é calculada na hora; não é gravada na conta e não aparece na página da conta nesta entrega. Pode ser adicionada depois pelo administrador.
- Oportunidade ganha com data de fechamento futura conta como Ativo.
- O relatório de Potenciais não traz e-mail nem telefone. Se o Marketing Cloud precisar do e-mail para importar, é uma coluna a mais.
- Para os públicos Ativo e Inativo continuam valendo os relatórios existentes da pasta (COMPRA - ÚLTIMOS 90 DIAS e SEM COMPRA por faixas).
- Todo disparo (e-mail, jornada) é feito por quem opera o Marketing Cloud; nada foi configurado lá.

## O que não dá para conferir pela tela
- Volume: o relatório rodou na QAS sobre toda a base (1225 contas) sem erro; a evidência está em `05-testes.md` (caso 8).
- Que nada foi gravado em conta, Flow ou código novo, e que o fluxo de ranking continua intacto: caso 10 e 11 de `05-testes.md`.
- Que nada foi configurado no Marketing Cloud: caso 14.
