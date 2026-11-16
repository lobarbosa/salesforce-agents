# EPLAST-30 — Roteiro de teste: rascunho comercial com IA

Foi entregue, na página da oportunidade, a aba **Rascunho IA**. Ela gera, a partir dos dados da própria oportunidade e da conta, um rascunho de proposta, de follow-up ou de argumentos comerciais. O texto é só uma sugestão para o vendedor revisar: nada é gravado e nada é enviado. Para o vendedor, muda que não precisa começar do zero. Nesta versão o rascunho **não usa a cotação**.

**Situação do teste automático:** comprovado pelo time: a aba aparece só para quem tem o acesso (grupo "Rascunho Comercial com IA"); sem o acesso, o endereço direto do fluxo mostra "Privilégios insuficientes"; a geração da **proposta** funciona na tela e não criou tarefa nem compromisso. Ficou para quem segue este roteiro: ler o texto completo da proposta, gerar **follow-up** e **argumentos** (a ferramenta de teste não conseguiu escolher essas opções), acesso negado a quem não vê a oportunidade e comportamento se a IA falhar.

## Antes de começar
- Ambiente: sandbox de QA (QAS) da Eplast.
- Perfil: usuário comercial que tenha o grupo de permissões **PSG_Comercial_RascunhoIA**. Peça ao administrador para atribuir.
- Dado de teste: oportunidade "TESTE EPLAST-30 Opp" (já existe, data de fechamento 31/12/2026, sem Valor e sem cotação). Para o teste 5, crie outra oportunidade de teste, com Valor 1000,50 e etapa Qualificação.
- Um segundo usuário de teste **sem** o grupo de permissões, e outro sem acesso a uma oportunidade de teste.

## Teste 1 — A aba aparece só para quem tem acesso
1. Entre com o usuário que tem o grupo e abra "TESTE EPLAST-30 Opp".
2. Entre com o usuário sem o grupo e abra a mesma oportunidade.

**Resultado esperado:** com o grupo, a aba "Rascunho IA" aparece ao lado de "Detalhes" e "Histórico Da Oportunidade". Sem o grupo, só essas duas abas aparecem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Rascunho de proposta
1. Abra a aba "Rascunho IA".
2. Marque "Proposta comercial" e clique em Avançar.
3. Conte o tempo até o texto aparecer.
4. Leia o texto na caixa "Texto gerado".

**Resultado esperado:** o texto aparece em até 15 segundos, com aviso "Rascunho gerado por IA: revise antes de usar. Nenhum campo deste registro foi alterado." Cita o nome da oportunidade, o nome da conta e a etapa; a data 31/12/2026; o contato aparece como "[nome do contato]"; preço, desconto, prazo e condição aparecem como "[a preencher]"; o Valor ausente aparece como "[dado ausente: ...]" e nenhum valor é inventado. Há a lista de campos usados e a de campos vazios. A caixa pode ser editada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rascunho de follow-up
1. Na aba "Rascunho IA", marque "Follow-up" e clique em Avançar.

**Resultado esperado:** texto com o nome da conta e a data de fechamento 31/12/2026, sem e-mail, telefone nem nome de contato (aparece "[nome do contato]").
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Argumentos comerciais
1. Marque "Argumentos comerciais" e clique em Avançar.

**Resultado esperado:** cada argumento indica de qual campo veio, por exemplo "(fonte: ...)".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Valor sai do registro
1. Abra a oportunidade de teste com Valor 1000,50.
2. Gere a proposta.

**Resultado esperado:** o valor citado é exatamente 1000,50 com a moeda do registro, sem arredondar nem somar.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Sem dado pessoal
1. Na oportunidade, cadastre um contato de teste com e-mail e telefone fictícios.
2. Gere os três rascunhos.

**Resultado esperado:** o texto usa "[nome do contato]" e não contém o e-mail nem o telefone cadastrados.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Quem não vê a oportunidade
1. Com o usuário que tem o grupo, mas não tem acesso à oportunidade "Y", tente abrir a oportunidade e gerar o rascunho.

**Resultado esperado:** a mesma negativa de acesso que o Salesforce já mostra; nenhum texto é gerado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Nada é gravado nem enviado
1. Depois de gerar os rascunhos, veja a linha do tempo da oportunidade e a conta.
2. Clique em Concluir e confira o histórico da oportunidade.

**Resultado esperado:** nenhuma tarefa, compromisso ou e-mail novo; nenhum campo alterado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Se a IA falhar
1. Peça ao administrador para desativar temporariamente o modelo de texto de proposta e gere uma proposta.

**Resultado esperado:** aparece mensagem de falha e você continua editando a oportunidade normalmente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — A página da oportunidade continua inteira
1. Abra a oportunidade e confira o Caminho, os painéis laterais e os campos de prioridade que já existiam.

**Resultado esperado:** tudo o que já existia continua visível, além da aba nova.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Sem cotação.** O rascunho não cita a cotação (decisão de 16/11). Se quiser, entra em demanda própria, com licença de cotação para quem usa.
- **Valor e condições.** Só o Valor da oportunidade aparece; desconto, prazo, condição comercial e quantidade de itens ficam "[a preencher]".
- **Produtos.** Os produtos da oportunidade não entram no texto.
- **Texto neutro e editável.** O tom é neutro; ajuste com a equipe de vendas. A assinatura traz "[Seu Nome]" e "[Seu Cargo]" para preencher.
- **Oportunidade fechada.** Também gera rascunho; o texto informa a etapa.
- **Sem conta.** Gera o rascunho mesmo assim, com "[dado ausente: ...]" nos dados da conta.
- **Quem usa.** Só quem recebe o grupo de permissões; vale para os perfis comerciais.
- **Aba.** Aparece na página padrão da oportunidade; a de três colunas não foi alterada.
- **Nada sai do CRM.** Nenhum envio. E-mail de follow-up, se desejado, é passo do Marketing Cloud, fora desta entrega.
- **Custo de IA.** Fica por conta da licença da Eplast.

## O que não dá para conferir pela tela
O registro de execução do sistema (nenhum gatilho ou automação disparado ao gerar o texto) e a execução em volume só o time técnico comprova. Estão pendentes; o que já foi provado está em `05-testes.md`.
