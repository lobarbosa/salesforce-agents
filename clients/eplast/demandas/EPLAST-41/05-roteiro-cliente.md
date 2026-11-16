# EPLAST-41 · Roteiro de teste — Rascunho de mensagem de relacionamento com IA

**O que foi entregue.** Na tela da Conta (e da Oportunidade), a ação **Rascunho com IA** gera, a partir de dados comerciais da conta, um texto de mensagem de relacionamento ou um texto comercial. O texto é só um rascunho: você edita, copia e, se quiser, salva como tarefa. Nada é enviado pelo Salesforce; o envio continua sendo feito pelo Marketing Cloud.

**Situação do teste automático:** comprovado na sandbox de QA: a ação aparece na Conta, o texto é gerado e exibido na tela, e escolher "Fechar sem salvar" não grava nada. **Ficou para quem segue o roteiro:** o salvamento como tarefa (Teste 3), a tela de erro quando a IA falha (Teste 5) e o caminho de texto comercial (Teste 6), porque a ferramenta de teste não consegue marcar a opção "Salvar como tarefa" nem escolher item de lista, e a falha da IA não dá para provocar.

## Antes de começar
- Ambiente: sandbox QAS da Eplast (a "QAS").
- Perfil: usuário com o acesso "Rascunho de relacionamento" atribuído (peça ao administrador). Para o Teste 6, também o acesso de rascunho comercial.
- Dados de teste: crie uma Conta chamada `TESTE EPLAST-41 Conta A` (preencha os campos obrigatórios com valores fictícios), com uma Oportunidade aberta `TESTE EPLAST-41 Opp aberta`. Crie também `TESTE EPLAST-41 Conta B sem oportunidade`, sem oportunidade. Use só dados fictícios.

## Teste 1 — A ação aparece na Conta
1. Abra a Conta `TESTE EPLAST-41 Conta A`.
2. Clique em **Mostrar mais ações**.

**Resultado esperado:** aparece a opção **Rascunho com IA**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Gerar a mensagem de relacionamento
1. Clique em **Rascunho com IA**.
2. Marque **Mensagem de relacionamento** e clique em **Avançar**.
3. No campo **Tipo e objetivo da mensagem**, escreva `Reativação: lembrar a conta sobre novidades de portfólio` e clique em **Avançar**.
4. Espere o texto aparecer.

**Resultado esperado:** em até 30 segundos aparece a tela "Rascunho gerado" com o aviso "Rascunho gerado por IA. Revise antes de usar. O envio é feito pelo Marketing Cloud, não por aqui." e o texto numa caixa que você pode editar e copiar. A opção "Fechar sem salvar" vem marcada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Salvar como tarefa
1. Repita o Teste 2 até aparecer o texto.
2. Marque **Salvar como tarefa** e clique em **Avançar**.
3. Feche a janela e abra a conta; veja a linha do tempo de atividades.

**Resultado esperado:** a tela mostra "Tarefa criada no registro com o texto do rascunho. Nenhum envio foi feito." Na conta há uma tarefa **Rascunho de relacionamento (IA)**, aberta, sem data, com o texto na descrição. Não há e-mail registrado no histórico.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Fechar sem salvar não grava nada
1. Repita o Teste 2 até aparecer o texto.
2. Deixe **Fechar sem salvar** marcado e clique em **Avançar**.
3. Veja a linha do tempo da conta.

**Resultado esperado:** a tela diz "Nada foi gravado." e nenhuma tarefa "(IA)" nova existe na conta.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Falha da IA
Só se o time técnico conseguir simular a indisponibilidade da IA.
1. Peça o texto como no Teste 2 durante a indisponibilidade.

**Resultado esperado:** aparece "Não foi possível gerar o texto agora. Tente novamente mais tarde. Nenhum texto foi gerado e nada foi gravado." e nenhuma tarefa é criada.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Texto comercial e conta sem oportunidade
1. Abra `TESTE EPLAST-41 Conta B sem oportunidade`, clique em **Rascunho com IA**, marque **Texto comercial (proposta, follow-up, argumentos)** e **Avançar**.
2. Depois, na Conta A, repita e, na tela "Escolha a oportunidade", selecione `TESTE EPLAST-41 Opp aberta`.

**Resultado esperado:** passo 1: "Esta conta não tem oportunidade aberta. O rascunho comercial depende de uma oportunidade. Nenhum texto foi gerado." Passo 2: a lista mostra a oportunidade aberta da conta e o fluxo segue para o texto comercial.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Textos comerciais** são os três já existentes (proposta, follow-up e argumentos); não foi criado um quarto tipo.
- **Relacionamento**: você digita o tipo e o objetivo em texto livre; não há lista fixa de tipos.
- **Onde o rascunho sai**: Conta e Oportunidade. Contato e Pedido ficaram de fora.
- **Onde o texto fica**: como tarefa na conta ou oportunidade, aberta e sem data (para não contar como contato com o cliente), só depois de você escolher salvar.
- **Dados pessoais**: a IA não recebe nome, e-mail, telefone nem documento de contato, só dados comerciais da conta e da oportunidade.
- **Quem usa**: quem receber o grupo de acesso comercial de rascunho com IA, atribuído pelo administrador.
- **Opt-out**: a tela não bloqueia o rascunho para quem recusou comunicação; o Marketing Cloud respeita isso no envio.
- **IA habilitada** na org: assumido porque os modelos já existem.
Se algum ponto não for o que vocês querem, registre em "Não conforme".

## O que não dá para conferir pela tela
- Que nenhum e-mail ou envio agendado foi criado pelo CRM e que nada mudou no Marketing Cloud: o time técnico conferiu por contagem (805 e-mails antes e depois), evidência em `05-testes.md`.
- Que o assistente existente (SFAgent2) e os componentes do conector Marketing Cloud ficaram intactos: conferido pelo time técnico, mesma evidência.
