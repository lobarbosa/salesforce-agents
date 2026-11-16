# EPLAST-45 · Roteiro de teste: nutrição de leads até a abordagem comercial

Foi entregue, no Salesforce, a preparação para a nutrição de leads: o lead passa a ser marcado como "em nutrição" e, quando chega à prioridade Alta, como "pronto para abordagem". Há duas listas de público (e-mail e mensagem) que respeitam quem pediu para não receber, uma lista de leads prontos para o vendedor e campos para receber de volta o engajamento. O envio em si continua sendo do Marketing Cloud.

**Situação do teste automático:** o time já comprovou na QA, com leads de teste, a marcação de elegível e pronto, os opt-outs nas duas listas de público, a conversão, a manutenção do dono e a gravação do engajamento (ver `05-testes.md`). Não foi conferido pela tela do navegador nem com um usuário sem permissão: isso fica para quem segue este roteiro.

## Antes de começar
- Ambiente: sandbox de QA (QAS) da Eplast. Perfil: administrador ou comercial com acesso a Leads.
- Crie 4 leads de teste, com Empresa "TESTE EPLAST-45", Setor "Alimentos" e Origem do lead "Evento":
  - Lead A: Status "Aberto - Não contatado".
  - Lead B: Status "Contatado".
  - Lead C: Status "Contatado", marcando "Não receber e-mails" (opt-out de e-mail).
  - Lead D: Status "Contatado", marcando o opt-out de mensagem (celular). Preencha e-mail e celular fictícios (exemplo.com, (11)999990001).
- Ao final, apague os leads de teste.

## Teste 1 — Lead em nutrição aparece como elegível
1. Abra o Lead A e olhe o campo "Nutrição elegível" (se não aparecer, peça para adicionar ao layout).
2. Abra o Lead B.
**Resultado esperado:** os dois mostram "Nutrição elegível" marcado. Lead A mostra "Pronto para abordagem" desmarcado (faixa Média); Lead B, marcado (faixa Alta).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Opt-out de e-mail
1. Abra o relatório "Nutrição - Leads - E-mail" (pasta Marketing Cloud).
2. Procure por "TESTE EPLAST-45".
**Resultado esperado:** aparecem os leads A, B e D. O Lead C não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Opt-out de mensagem
1. Abra o relatório "Nutrição - Leads - Mensagem".
2. Procure por "TESTE EPLAST-45".
**Resultado esperado:** aparecem os leads A, B e C. O Lead D não aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Lead passa a pronto para abordagem sozinho
1. Abra a lista de leads "Leads prontos para abordagem". Confirme que o Lead A não está nela.
2. Edite o Lead A e mude o Status para "Contatado". Salve.
3. Atualize a lista.
**Resultado esperado:** o Lead A passa a aparecer na lista, sem nenhuma outra ação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — O dono do lead não muda
1. Anote o Proprietário do Lead A.
2. Repita o Teste 4, se ainda não o fez.
**Resultado esperado:** o Proprietário continua o mesmo.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Lead convertido sai da nutrição
1. Converta o Lead B (botão "Converter", sem criar oportunidade).
2. Abra a lista "Leads prontos para abordagem" e os dois relatórios.
**Resultado esperado:** o Lead B não aparece em nenhum.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Retorno de engajamento do Marketing Cloud
1. No Lead C, preencha "Engajamento (Marketing Cloud)" com "Alto" e a data de agora (exige permissão de edição desses dois campos).
2. Salve.
**Resultado esperado:** o valor é gravado. Status, faixa de prioridade e Proprietário ficam como estavam. As opções disponíveis são: Sem engajamento, Baixo, Médio e Alto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem não tem permissão
1. Entre com um usuário sem o conjunto de permissões de Marketing/Comercial desta entrega.
2. Abra um Lead de teste.
**Resultado esperado:** os campos novos não aparecem. Só quem tem o conjunto de permissões de retorno do Marketing Cloud consegue editar engajamento e data.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Plataforma de nutrição: Marketing Cloud.
- Quem entra na nutrição: lead não convertido com status "Aberto - Não contatado" ou "Contatado", de qualquer origem.
- "Pronto para abordagem": lead em nutrição com faixa de prioridade Alta (somada, se desejarem, ao engajamento).
- Opt-out de e-mail e de mensagem tira o lead da lista do canal correspondente.
- O lead pronto não muda de dono (as filas de lead ainda não têm membros).
- O vendedor é avisado por lista, sem e-mail do Salesforce.
- Volume de leads moderado (se for alto, o desenho muda).

## O que não dá para conferir pela tela
- Igualdade entre a contagem dos relatórios e a base (202 de e-mail e 148 de mensagem na QAS) e as permissões campo a campo: evidência em `05-testes.md`.
- Jornada, público, conteúdo e envio no Marketing Cloud: são passos de quem opera esse sistema e não fizeram parte do teste.
