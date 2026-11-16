# EPLAST-40: Roteiro de teste, ciclo Marketing, SDR, Comercial e Pós-vendas

**O que foi entregue:** a Oportunidade passa sozinha de "Qualificação" para "Qualificado" quando dois itens estão marcados. Quando é ganha, cria um caso de Pós-vendas na fila "Pós-vendas". O Lead de marketing segue o fluxo atual, e o sistema não envia e-mail nenhum.

**Situação do teste automático:** comprovado na sandbox de QA: Lead novo, mudança para "Contatado", qualificação da Oportunidade (inclusive 20 de uma vez), criação do caso sem duplicar e preservação dos opt-outs. Não comprovado: conversão do Lead criando a Oportunidade (barrada pela regra de catálogo de preço para o tipo de registro padrão do usuário de teste), tela do layout e acesso de usuário sem permissão. Ficam para quem segue este roteiro. Veredito técnico: reprovado nesta rodada, pela conversão sem prova.

## Antes de começar
- Ambiente: sandbox de QA da Eplast (QAS). Perfil: administrador, mais um usuário comum para o Teste 6.
- Crie dados de teste com nome começando por "TESTE EPLAST-40": uma Conta completa (telefone, CNAE, razão social, e-mail, endereço de cobrança) e, em Conta, um Catálogo de preço ligado a ela.
- Crie um Lead "TESTE EPLAST-40 Lead" com Origem "E-mail MKT".

## Teste 1 — Lead de marketing entra no funil
1. Abra Leads e clique em Novo.
2. Preencha sobrenome, empresa e Origem "E-mail MKT". Marque os dois campos de não receber comunicação (e-mail e celular). Salve.
**Resultado esperado:** Status "Aberto - Não contatado", Origem "E-mail MKT", os dois campos de não receber comunicação continuam marcados.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — SDR marca o primeiro contato
1. No Lead do Teste 1, altere o Status para "Contatado" e salve.
**Resultado esperado:** Status "Contatado"; nenhuma Oportunidade nova aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Conversão do Lead gera Oportunidade
1. No Lead "Contatado", clique em Converter.
2. Escolha a Conta de teste e mantenha a criação da Oportunidade. Converta.
**Resultado esperado:** Oportunidade criada em "Qualificação", com a mesma Origem do Lead; Lead "Fechado - Convertido". Se aparecer "Catálogo de preço selecionado inválido", anote: é a regra atual de catálogo, e vale repetir com um usuário cujo tipo de registro padrão de Oportunidade seja "Indústria".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Qualificado só com os dois critérios
1. Crie uma Oportunidade de teste em "Qualificação" (tipo "Indústria") na Conta de teste.
2. Marque "Discovery concluído" e salve.
3. Confira o Estágio.
4. Marque também "Budget confirmado" e salve.
**Resultado esperado:** após o passo 3, "Qualificação"; após o passo 4, "Qualificado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Ganha gera caso de Pós-vendas
1. Preencha na Oportunidade os campos exigidos para fechar (catálogo da Conta, condição e forma de pagamento, filial, análises fiscal e financeira) e mude o Estágio para "Fechado/Ganho".
2. Aguarde cerca de 1 minuto e abra Casos, lista "Pós-vendas: fila".
**Resultado esperado:** 1 caso com Assunto "Pós-vendas: <nome da Oportunidade>", Status "New", proprietário "Pós-vendas". Na Oportunidade, a lista relacionada de Casos mostra o mesmo caso.
3. Volte o Estágio para "Qualificado" e feche de novo.
**Resultado esperado:** continua 1 caso só.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Usuário sem permissão
1. Entre com um usuário comum, sem o conjunto de permissões de Pós-vendas, e abra a lista de casos "Pós-vendas: fila".
**Resultado esperado:** não vê os campos/casos de Pós-vendas conforme a permissão (anote o que vê).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Sem e-mail pelo sistema
1. Nos testes 2 a 5, confira a caixa do e-mail de teste.
**Resultado esperado:** nenhum e-mail enviado pelo Salesforce por causa dessas mudanças.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- Entram no ciclo de marketing as origens Campanha, E-mail MKT, Evento, Google Ads, Google Orgânico, Instagram, Facebook e WhatsApp. Confirma?
- Usamos os estágios que já existem (sem estágio novo de SDR). Confirma?
- A passagem do SDR para a Comercial é a conversão do Lead, e a data fica no próprio Lead (data de conversão), sem campo novo. Confirma?
- "Qualificado" exige "Discovery concluído" e "Budget confirmado". Confirma?
- Oportunidade "Fechado/Ganho" gera caso de Pós-vendas; a venda continua pelo processo atual. A data da passagem é a data de criação do caso. Confirma?
- Os casos caem na fila "Pós-vendas", que nasce sem membros: a Eplast precisa definir quem atende antes da homologação.
- Sem aviso ao vendedor e sem prazo (SLA) nesta entrega; qualquer aviso por e-mail sairia pelo Marketing Cloud.
- A conversão continua sujeita às regras atuais de Conta e catálogo de preço.

## O que não dá para conferir pela tela
Que o sistema não envia e-mail (inspeção dos dois fluxos, 0 ações de envio) e o teste de 20 Oportunidades de uma vez: evidência em `05-testes.md`.
