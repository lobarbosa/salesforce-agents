# EPLAST-38 · Roteiro de teste: lead vai para a fila da região certa

O que foi entregue: todo lead novo passa a ir sozinho para a fila da sua região, conforme o estado (UF). Lead sem estado reconhecido vai para a fila "Leads Triagem". O que muda para quem usa: o responsável do lead deixa de ser quem o cadastrou e passa a ser a fila da região.

**Situação do teste automático:** o time já comprovou, no ambiente de homologação, com leads de teste criados e depois apagados: o encaminhamento por estado (todas as regiões), o lead sem estado, o responsável informado à mão, a pontuação de prioridade (60 e 100), o cadastro de 200 leads de uma vez e a ausência de envio de e-mail. Ficou para quem segue este roteiro conferir pela tela, e a entrada de leads por integração externa (não testada no ambiente de homologação por exigir alterar permissão da conta de serviço).

## Antes de começar
- Ambiente: a sandbox de homologação (QAS), com um perfil que pode criar Lead (por exemplo Administrador do sistema ou Comercial - Analista).
- Crie leads de teste com Sobrenome começando por `TESTE EPLAST-38`, Empresa "Empresa Ficticia" e sem dado de cliente real. Apague-os ao final.
- Para cada teste, use a opção de lista "Leads" > "Novo".

## Teste 1 — Lead de São Paulo vai para a fila SP
1. Abra Leads e clique em Novo.
2. Preencha Sobrenome `TESTE EPLAST-38 SP`, Empresa, Status "Aberto - Não contatado", Estado/Província `SP`.
3. Deixe marcada a caixa "Atribuir usando regra de atribuição ativa".
4. Salve e abra o lead.

**Resultado esperado:** campo Proprietário do lead = "Leads SP".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Cada região na sua fila
Repita o Teste 1 com os estados abaixo.
1. RJ. 2. MG. 3. ES. 4. SC. 5. DF. 6. BA.

**Resultado esperado:** RJ = "Leads RJ"; MG = "Leads MG"; ES = "Leads ES"; SC = "Leads Sul (PR, SC, RS)"; DF = "Leads Centro-Oeste"; BA = "Leads Norte e Nordeste".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Lead sem estado ou com estado por extenso vai para Triagem
1. Crie um lead sem preencher Estado/Província.
2. Crie outro com Estado/Província `São Paulo` (por extenso).
3. Crie um terceiro com `sp` em minúsculo.

**Resultado esperado:** o primeiro e o segundo ficam com Proprietário "Leads Triagem"; o terceiro fica com "Leads SP".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Responsável escolhido à mão é mantido
1. Crie um lead com Estado `SP`.
2. Desmarque a caixa "Atribuir usando regra de atribuição ativa".
3. Em Proprietário, deixe você mesmo. Salve.

**Resultado esperado:** Proprietário continua sendo você, não a fila.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Prioridade do lead
1. Crie um lead com Estado `SP`, Setor "Alimentos", Origem do lead "Evento" e Status "Aberto - Não contatado". Salve.
2. Veja os campos de pontuação e faixa de prioridade.
3. Edite o lead e mude o Status para "Contatado".

**Resultado esperado:** primeiro 60 e faixa "Média"; depois da mudança, 100 e faixa "Alta".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nenhum e-mail sai
1. Após criar os leads dos testes anteriores, confira com quem faz parte das filas se alguém recebeu e-mail de aviso de novo lead.

**Resultado esperado:** nenhum e-mail de aviso chega.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Quem atende a fila (passo do administrador)
1. Em Configuração > Filas, abra cada uma das 8 filas de Lead: Leads SP, RJ, MG, ES, Sul, Centro-Oeste, Norte e Nordeste e Triagem.
2. Veja se há pelo menos um membro.

**Resultado esperado:** cada fila tem ao menos um membro (hoje nenhuma tem; sem isso o lead chega à fila, mas ninguém o recebe). Triagem é a mais importante.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- A região vem do Estado/Província do lead, e quem atende é a fila da região, não um vendedor específico.
- O lead é encaminhado na criação, e não quando muda de status ou de pontuação.
- Se o usuário desmarcar a caixa de regra e escolher o responsável, o escolhido é mantido. Se a caixa estiver marcada, vale a fila. Lead que chega por integração sempre vai para a fila.
- Estado por extenso (ex.: "São Paulo") ou em branco vai para Triagem. Não normalizamos o texto.
- O vendedor não recebe aviso ao receber um lead; qualquer aviso seria feito pelo Marketing Cloud.
- A prioridade (60 / 100) é a que já existe, calculada na hora, sem gravar histórico.
- Quem monta os membros das filas é o administrador da Eplast. Não há relatório para Norte e Nordeste.

## O que não dá para conferir pela tela
- Carga de 200 leads de uma vez e a integração externa de leads: evidência em `05-testes.md` (QA) e `04-verificacao.md` (dev).
- Que o pacote não envia e-mail: conferência de metadata, em `05-testes.md`.
