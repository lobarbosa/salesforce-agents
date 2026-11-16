# Roteiro de teste — SOMOSAGILITY-21: Origem do Lead vinda do site

Esta demanda trata de Leads que chegam do site da Agility. O esperado é que o campo **Origem do lead** venha como **Web Site Agility Networks**, e que Leads de outros canais não mudem.

**Situação do teste automático:** o time só comprovou o comportamento do Salesforce ao criar Leads direto na QA (sem origem: assume "Prospecção - Gerente de Contas"; com "Web Site Agility Networks": mantém). A correção em si ainda não está entregue (depende do ajuste no envio do site ou de decisão pendente), então os testes abaixo valem para quando ela existir.

## Antes de começar
- Ambiente: sandbox de QA, com um perfil que crie Leads.
- Crie 2 Leads de teste: "TESTE SOMOSAGILITY-21 Manual" (pela tela, sem alterar a Origem) e use o envio de teste do site, com dados fictícios, para o segundo.

## Teste 1 — Lead vindo do site
1. Dispare o envio de teste do formulário do site com dados fictícios.
2. Abra o Lead criado e veja o campo **Origem do lead**.

**Resultado esperado:** Origem do lead = **Web Site Agility Networks**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Lead criado manualmente não muda
1. Clique em Novo na lista de Leads.
2. Preencha só os campos obrigatórios com dados fictícios, sem mexer na Origem do lead, e salve.

**Resultado esperado:** Origem do lead continua **Prospecção - Gerente de Contas** (padrão), e não "Web Site Agility Networks".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Origem escolhida à mão é respeitada
1. Crie um Lead fictício escolhendo **Email Marketing** em Origem do lead e salve.

**Resultado esperado:** Origem do lead = **Email Marketing**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
O formato exato do envio do site (valor enviado pelo sistema do site) e o comportamento em produção só o time técnico e a TI Agility comprovam. Evidência da parte feita na plataforma está em `05-testes.md`.
