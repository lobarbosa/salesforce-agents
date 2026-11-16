# Roteiro de teste — Rascunho de texto com IA (EPLAST-41)

**O que foi entregue.** Na tela de uma Conta (e de uma Oportunidade) há uma nova ação, "Rascunho com IA". Ela gera um texto de mensagem de relacionamento, ou um texto comercial (proposta, follow-up, argumentos), para o vendedor revisar. O texto é só um rascunho: nada é enviado por aqui (o envio é feito pelo Marketing Cloud) e só vira registro se a pessoa escolher "Salvar como tarefa".

**Situação do teste automático:** comprovado pelo time: a ação aparece na Conta, a tela agora tem o botão "Avançar" e chega à tela de objetivo, e a Conta sem oportunidade mostra o aviso certo. Ficou para quem segue este roteiro: digitar o objetivo, ver o texto gerado e salvar como tarefa (Testes 2 a 4), porque a ferramenta automática não consegue digitar nesse campo; e o texto comercial (Teste 5), que depende de licença de Cotação.

## Antes de começar
- **Ambiente:** a sandbox "QAS" (ambiente de homologação). Não use produção.
- **Perfil:** um usuário com o grupo de permissões "Rascunho com IA" (PSG_Comercial_RascunhoIA) ou o conjunto "PS_Comercial_RascunhoRelacionamento". Peça ao administrador para atribuir.
- **Dados de teste:** duas contas.
  - "TESTE EPLAST-41 Conta A", com uma oportunidade aberta "TESTE EPLAST-41 Opp aberta".
  - "TESTE EPLAST-41 Conta B sem oportunidade", sem nenhuma oportunidade.
  O time técnico cria as duas com o script `fixtures/eplast41_dados_teste.apex`. Se criar à mão, preencha os campos obrigatórios com valores inventados.

## Teste 1 — A ação aparece e abre
1. Abra a conta "TESTE EPLAST-41 Conta A".
2. Clique em "Mostrar mais ações".
3. Clique em "Rascunho com IA".

**Resultado esperado:** abre uma janela com "Tipo de texto" (duas opções: "Mensagem de relacionamento" e "Texto comercial (proposta, follow-up, argumentos)") e o botão "Avançar" no rodapé.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Gerar mensagem de relacionamento
1. Na janela do Teste 1, marque "Mensagem de relacionamento".
2. Clique em "Avançar".
3. No campo "Tipo e objetivo da mensagem", digite: `TESTE EPLAST-41 agradecer a parceria e manter contato`.
4. Clique em "Avançar".

**Resultado esperado:** em até 30 segundos aparece "Rascunho gerado", com o aviso "Rascunho gerado por IA. Revise antes de usar. O envio é feito pelo Marketing Cloud, não por aqui." e o texto da mensagem num campo editável. O texto não traz e-mail, telefone ou CPF.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — O texto pode ser editado e copiado, e nada é gravado sem salvar
1. Na tela do texto, altere uma palavra no campo e selecione o texto para copiá-lo.
2. Em "O que fazer com o texto?" deixe marcado "Fechar sem salvar" e clique em "Avançar" (ou "Concluir").
3. Volte à conta e abra a aba "Atividade".

**Resultado esperado:** aparece "Nada foi gravado." e não existe tarefa nova com o assunto "Rascunho de relacionamento (IA)" na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Salvar como tarefa
1. Repita os passos 1 a 4 do Teste 2.
2. Em "O que fazer com o texto?" marque "Salvar como tarefa".
3. Clique em "Avançar" (ou "Concluir").
4. Volte à conta e abra a aba "Atividade".

**Resultado esperado:** aparece "Tarefa criada no registro com o texto do rascunho. Nenhum envio foi feito." Na conta há uma tarefa aberta, sem data, com assunto "Rascunho de relacionamento (IA)" e o texto no campo Descrição. Nenhum e-mail foi enviado e nada aparece como e-mail enviado na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Texto comercial a partir da conta
1. Abra "TESTE EPLAST-41 Conta A", "Mostrar mais ações", "Rascunho com IA".
2. Marque "Texto comercial (proposta, follow-up, argumentos)" e clique em "Avançar".
3. Em "Oportunidade aberta da conta", escolha "TESTE EPLAST-41 Opp aberta" e clique em "Avançar".
4. Siga as telas do rascunho comercial (proposta, follow-up, argumentos) até o texto.

**Resultado esperado:** a lista mostra a oportunidade aberta da conta e o texto comercial é gerado, usando os mesmos modelos de texto comerciais que já existiam (sem versão duplicada). Se houver "Salvar como tarefa", a tarefa fica no registro da oportunidade com o assunto "Rascunho comercial (IA)".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Conta sem oportunidade aberta
1. Abra "TESTE EPLAST-41 Conta B sem oportunidade", "Mostrar mais ações", "Rascunho com IA".
2. Marque "Texto comercial (proposta, follow-up, argumentos)" e clique em "Avançar".

**Resultado esperado:** aparece "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." com o botão "Concluir".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Ação a partir da oportunidade
1. Abra a oportunidade "TESTE EPLAST-41 Opp aberta".
2. Procure "Rascunho com IA" nas ações do topo (ou em "Mostrar mais ações").
3. Clique nela e escolha "Mensagem de relacionamento".

**Resultado esperado:** a ação existe e abre a mesma janela. A tarefa salva fica na oportunidade.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
Decidimos estes pontos com o que a org já mostra e com o padrão da plataforma. Se discordar, diga na homologação.
- "Textos comerciais" são os três que já existem (proposta, follow-up e argumentos). Não há um quarto tipo.
- A mensagem de relacionamento tem tipo e objetivo digitados livremente, sem lista fixa.
- A ação existe em Conta e Oportunidade. Pedido e Contato ficaram de fora.
- O texto salvo vira uma tarefa aberta, sem data, no registro de origem, com assunto fixo "Rascunho de relacionamento (IA)" ou "Rascunho comercial (IA)". Sem data, para não contar como contato com o cliente.
- O texto de relacionamento não leva dado pessoal (nome de contato, e-mail, telefone, CPF) nem valores de oportunidade.
- Não há bloqueio por opt-out de e-mail na geração: quem respeita o opt-out é o Marketing Cloud, no envio.
- Quem pode usar: quem receber o grupo "Rascunho com IA", atribuído pelo administrador. Hoje ninguém tem.
- Assume-se que a IA generativa está habilitada na org.
- O layout "CPQ Opportunity Layout" é de pacote de terceiros e não foi alterado; a ação aparece pela página Lightning da Oportunidade. Confirme onde o vendedor vê o botão.

## O que não dá para conferir pela tela
- Que nenhum e-mail ou item do Marketing Cloud foi criado: contagem de e-mails registrados (805 antes e depois) e inspeção do pacote, em `05-testes.md`.
- Que o conjunto de modelos de texto não foi duplicado e que o agente existente (SFAgent2) continua único: consultas ao catálogo da org, em `05-testes.md`.
