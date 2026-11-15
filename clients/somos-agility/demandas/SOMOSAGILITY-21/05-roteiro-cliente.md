# Roteiro de teste — Origem do Lead vinda do site

**O que foi entregue:** Leads que chegam do site da Agility devem aparecer com o campo **Origem do lead** igual a **Web Site Agility Networks**. Para quem usa, isso permite relatórios de Marketing por canal sem Leads vindos do site "perdidos" em outra origem.

**Situação do teste automático:** a equipe criou Leads de teste na sandbox de QA. Eles comprovaram que, hoje, um Lead sem origem informada fica com **Prospecção - Gerente de Contas**. A correção em si (o site passar a enviar a origem certa) depende de ajuste fora do Salesforce e ainda não pôde ser comprovada. Os Testes 1 a 3 ficam para quem segue este roteiro, depois que o ajuste do site estiver feito.

## Antes de começar
- Ambiente: sandbox de QA (nunca produção).
- Perfil: usuário com permissão de criar e ver Leads.
- Dado de teste: use só Leads com nome e empresa começando por "TESTE SOMOSAGILITY-21", sem dados reais.
- Para o Teste 1, peça à TI Agility que dispare um envio de teste do formulário do site para a sandbox de QA, com o nome "TESTE SOMOSAGILITY-21 Site".

## Teste 1 — Lead vindo do site chega com a origem correta
1. Peça o envio de teste do formulário do site (veja "Antes de começar").
2. No Salesforce de QA, abra a aba **Leads**.
3. Procure por "TESTE SOMOSAGILITY-21 Site" e abra o Lead.
4. Olhe o campo **Origem do lead**.

**Resultado esperado:** **Web Site Agility Networks**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Leads criados à mão continuam como antes
1. Na aba **Leads**, clique em **Novo**.
2. Preencha Sobrenome e Empresa com "TESTE SOMOSAGILITY-21 Manual". Não mexa na Origem do lead.
3. Salve.
4. Veja o campo **Origem do lead**.

**Resultado esperado:** **Prospecção - Gerente de Contas** (o valor padrão de sempre), e não Web Site Agility Networks.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Outro canal escolhido manualmente não é alterado
1. Crie outro Lead de teste ("TESTE SOMOSAGILITY-21 Evento").
2. Escolha **Evento** em Origem do lead e salve.
3. Reabra o Lead e veja a Origem do lead.

**Resultado esperado:** **Evento**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

Ao terminar, exclua os Leads de teste.

## O que não dá para conferir pela tela
- O ajuste no envio do formulário do site é feito fora do Salesforce, pela TI Agility. Só o time técnico confirma que ele está em produção.
- A evidência da checagem automática (valor padrão e valores de origem) está em `05-testes.md`.
