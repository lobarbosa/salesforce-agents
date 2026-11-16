# EPLAST-30 · Roteiro de teste — Rascunho comercial na oportunidade

Foi entregue uma aba "Rascunho IA" na página da oportunidade. Nela o vendedor pede um texto de proposta, de follow-up ou de argumentos comerciais, feito a partir dos dados da oportunidade. O texto é só um rascunho para editar: nada é gravado, nada é enviado e nenhum e-mail ou tarefa é criado.

**Situação do teste automático:** comprovei, na sandbox de testes, que os três modelos de texto respondem certo (data de fechamento citada no follow-up, "[dado ausente: ...]" e "[a preencher]" na proposta, argumentos com fonte, sem e-mail nem telefone). **Não** consegui exercitar a aba "Rascunho IA" em si: o usuário de teste do time não pôde receber a permissão do recurso, que exige a licença de Cotação (CPQ). Os Testes 3 a 9 abaixo ficam para quem seguir o roteiro com um usuário que tenha essa licença. A negativa de acesso para quem não tem a permissão (Teste 1) foi comprovada.

## Antes de começar
- **Ambiente:** a sandbox "QAS" da Eplast.
- **Perfis:** (a) um vendedor com o grupo de permissões "Rascunho IA Comercial" e licença de Cotação; (b) um usuário sem esse grupo; (c) um usuário sem acesso à oportunidade "Y" (Teste 8).
- **Dados de teste** (nunca use cliente real): crie uma conta "TESTE EPLAST-30 Conta" e, nela, a oportunidade "TESTE EPLAST-30 Opp" na etapa Qualificação, com data de fechamento 31/12/2026, e um contato "TESTE Contato" com e-mail e telefone fictícios. Para o Teste 5 crie uma segunda oportunidade sem data de fechamento (se o sistema exigir a data, apague-a depois de criada, se permitido). Para o Teste 6 crie uma cotação primária com valor total R$ 1.234,56.

## Teste 1 — Quem não tem permissão não vê a aba
1. Entre com o usuário (b), sem o grupo de permissões.
2. Abra a oportunidade "TESTE EPLAST-30 Opp".

**Resultado esperado:** a aba "Rascunho IA" não aparece; só "Detalhes" e "Histórico Da Oportunidade" (entre outras já existentes).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Proposta pelo vendedor autorizado
1. Entre com o usuário (a). Abra "TESTE EPLAST-30 Opp".
2. Clique na aba "Rascunho IA".
3. Escolha "Proposta" e peça o rascunho. Conte o tempo.

**Resultado esperado:** em até 15 segundos aparece um texto editável com o nome "TESTE EPLAST-30 Conta" e a etapa "Qualificação".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Follow-up
1. Na mesma aba, escolha "Follow-up" e peça o rascunho.

**Resultado esperado:** texto editável com "TESTE EPLAST-30 Conta" e a data de fechamento 31/12/2026. Sem e-mail, telefone nem nome do contato (aparece "[nome do contato]").
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Argumentos comerciais com fonte
1. Escolha "Argumentos" e peça o rascunho.

**Resultado esperado:** cada argumento indica de onde veio, por exemplo "(fonte: Etapa)" ou o nome do produto da cotação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Dado que falta não é inventado
1. Abra a oportunidade sem data de fechamento e peça a "Proposta".

**Resultado esperado:** onde iria a data aparece "[dado ausente: data de fechamento]", nenhuma data inventada, e há a lista dos campos usados e dos campos vazios.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Preço sem cotação e com cotação
1. Na oportunidade sem cotação, peça a "Proposta".
2. Na oportunidade com cotação de R$ 1.234,56, peça a "Proposta".

**Resultado esperado:** (1) preço, desconto, prazo e condição de pagamento aparecem como "[a preencher]". (2) o valor citado é exatamente R$ 1.234,56, sem conta nem arredondamento.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Sem dados pessoais do contato
1. Com o contato "TESTE Contato" (e-mail e telefone fictícios) na oportunidade, peça os três rascunhos.

**Resultado esperado:** o texto usa "[nome do contato]"; nenhum e-mail ou telefone aparece.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem não vê a oportunidade não gera rascunho
1. Entre com o usuário (c), sem acesso à oportunidade "Y".
2. Tente abrir "Y" e, se souber o endereço, tente chamar o rascunho por ele.

**Resultado esperado:** a mesma mensagem de acesso negado que o Salesforce já mostra; nenhum texto é gerado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Nada é gravado nem enviado; o registro segue editável
1. Gere um rascunho e feche a aba sem copiar.
2. Confira Atividades, e-mails e histórico da oportunidade e da conta.
3. Edite um campo da oportunidade e salve.

**Resultado esperado:** nenhuma tarefa, evento ou e-mail novo e nenhuma alteração nos dados. O salvamento funciona normalmente. Se o serviço de IA estiver indisponível, aparece mensagem de falha e o registro continua editável.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — A página da oportunidade segue com o que já existia
1. Abra "TESTE EPLAST-30 Opp" e confira os campos e seções de prioridade (outra entrega recente) e a aba "Detalhes".

**Resultado esperado:** tudo continua visível, além da nova aba "Rascunho IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Motor:** usamos a IA já disponível no Salesforce da Eplast, sem sistema externo; o rascunho é um recurso separado do assistente `SFAgent2`.
- **Três saídas, só texto:** proposta, follow-up e argumentos; o texto é editável e não é enviado nem gravado. Quem revisa é o próprio vendedor.
- **Dados usados:** campos da oportunidade, da conta e da cotação primária. Preço só vem da cotação.
- **Quem usa:** quem receber o grupo de permissões "Rascunho IA Comercial" (exige licença de Cotação). O gestor não vê o rascunho.
- **Onde aparece:** aba "Rascunho IA" na página da oportunidade.
- **Tempo:** até 15 segundos é aceitável.
- **Dados pessoais:** o texto não cita nome, e-mail nem telefone do contato.
- **Tom e modelo:** texto comercial formal em português, sem modelo oficial da Eplast.
- **Custo de IA:** segue o consumo da licença atual da conta; não confirmado.
- **Documento de origem:** a demanda do card; a Solicitação de Proposta não precisa ser anexada.
Se discordar de algum item, diga na homologação.

## O que não dá para conferir pela tela
- Que o rascunho não dispara gatilhos, Flows de gravação nem grava dados: só o registro de execução comprova. O desenho não grava nada (verificação da dev em `04-verificacao.md`); não executado dinamicamente na QA.
- Limite de 50 linhas de cotação: exige cotação grande; ver `05-testes.md`.
