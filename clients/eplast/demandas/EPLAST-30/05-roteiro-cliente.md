# EPLAST-30 · Roteiro de teste — Rascunho comercial na oportunidade

Foi entregue uma aba chamada "Rascunho IA" na página da oportunidade. Nela, o vendedor pede um rascunho de proposta, de follow-up ou de argumentos comerciais, e recebe um texto que ele pode editar e copiar. O sistema só lê os dados: não grava nada na oportunidade, não cria tarefa e não envia e-mail.

**Situação do teste automático:** comprovado pelo time na sandbox QAS: a aba não aparece, e o acesso direto à tela é negado, para quem não tem a permissão; os três textos saem a partir de dados de teste, sem inventar preço ou data ausente e sem e-mail ou telefone. Ficou para quem segue este roteiro: o uso da aba pelo usuário com permissão, a regra de compartilhamento, o comportamento em caso de falha e a confirmação da data de fechamento no follow-up, porque o login de teste do time não tem a permissão do rascunho.

## Antes de começar
- Ambiente: sandbox QAS (Sandbox Eplast "QAS"). Nunca em produção.
- Perfil: um vendedor ao qual o time atribuiu o grupo de permissões "PSG Comercial Rascunho IA". Peça ao administrador para atribuir. Para os Testes 8 e 9 você precisa também de um usuário sem esse grupo.
- Dados de teste (já existem): oportunidade "TESTE EPLAST-30 Opp", da conta "TESTE EPLAST-30 Conta", etapa Qualificação, data de fechamento 31/12/2026, sem cotação.
- Para os testes com cotação, crie uma cotação CPQ primária de teste nessa oportunidade, com valor preenchido e algumas linhas.
- Para o Teste 4, crie uma segunda oportunidade de teste e deixe a data de fechamento vazia, se o sistema permitir. Se não permitir, anote.
- Use só dados de teste.

## Teste 1 — Proposta a partir da oportunidade
1. Abra a oportunidade "TESTE EPLAST-30 Opp".
2. Clique na aba "Rascunho IA".
3. Escolha o rascunho de proposta e confirme.
4. Conte o tempo até o texto aparecer.

**Resultado esperado:** texto editável que cita a conta "TESTE EPLAST-30 Conta" e a etapa "Qualificação", em até 15 segundos. Ao fim, as listas "Campos usados / campos vazios".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Follow-up com conta e data de fechamento
1. Na aba "Rascunho IA", escolha o rascunho de follow-up.
2. Leia o texto.

**Resultado esperado:** o texto cita a conta "TESTE EPLAST-30 Conta" e a data de fechamento "31/12/2026". Não há e-mail, telefone nem nome de pessoa; o contato aparece como "[nome do contato]".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Argumentos com fonte
1. Na aba "Rascunho IA", escolha argumentos comerciais.

**Resultado esperado:** cada argumento indica de onde veio, por exemplo "(fonte: Oportunidade.Etapa)" ou a linha da cotação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Dado ausente não é inventado
1. Abra a oportunidade de teste sem data de fechamento.
2. Peça o rascunho de proposta.

**Resultado esperado:** o trecho da data aparece como "[dado ausente: data de fechamento]". Nenhuma data inventada. A lista de campos vazios cita a data de fechamento.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Preço sem cotação
1. Abra "TESTE EPLAST-30 Opp" (sem cotação).
2. Peça o rascunho de proposta.

**Resultado esperado:** preço, desconto, prazo e condição de pagamento aparecem como "[a preencher]". Nenhum valor em reais aparece no texto.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Preço com cotação
1. Crie uma cotação primária de teste com valor total conhecido (por exemplo R$ 1.234,56).
2. Peça o rascunho de proposta.

**Resultado esperado:** o valor no texto é exatamente o da cotação, sem arredondar nem recalcular.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Cotação com muitas linhas
1. Numa cotação de teste com mais de 50 linhas, peça a proposta.

**Resultado esperado:** o texto traz 50 linhas e a indicação "e mais N itens" para o restante. Se não for viável criar tantas linhas, marque "não testado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Usuário sem a permissão não vê a aba
1. Entre com um usuário sem o grupo "PSG Comercial Rascunho IA".
2. Abra "TESTE EPLAST-30 Opp".

**Resultado esperado:** a página abre com "Detalhes" e "Histórico Da Oportunidade", sem a aba "Rascunho IA". Se tentar abrir o endereço direto da tela de rascunho, aparece "Privilégios insuficientes".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Respeito ao acesso do registro
1. Com um vendedor que tem a permissão do rascunho, mas não enxerga uma oportunidade de teste (peça ao administrador uma oportunidade privada), tente abrir o rascunho para ela.

**Resultado esperado:** a mesma mensagem de acesso negado que o Salesforce já mostra; nenhum texto gerado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 10 — Nada é gravado nem enviado
1. Depois de gerar os rascunhos, volte à oportunidade e à conta de teste.
2. Confira Atividades e Histórico.

**Resultado esperado:** nenhuma tarefa, evento ou e-mail novo; nenhum campo alterado; nada no histórico além do que você mesmo editou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 11 — Falha do serviço de IA
1. Se o administrador puder simular indisponibilidade do serviço de IA, peça um rascunho.

**Resultado esperado:** mensagem de falha clara; a oportunidade continua editável. Se não for possível simular, marque "não testado".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
Estas decisões foram tomadas sem resposta do cliente, a partir do que a org já mostra e do padrão. Se discordar, o ponto é ajustável.
- **Motor de IA:** o recurso nativo de IA generativa do Salesforce; nenhum serviço externo.
- **Relação com o assistente `SFAgent2`:** o rascunho é uma tela à parte, não uma ação do assistente.
- **Saídas:** proposta, follow-up e argumentos são texto para revisar; não geram PDF nem e-mail.
- **Fontes:** dados da oportunidade, da conta e da cotação primária.
- **Quem revisa e vê:** o próprio vendedor, que edita; sem aprovação do gestor. Cada um vê só o que já vê no Salesforce.
- **Público:** perfis comerciais com o grupo de permissões atribuído.
- **Depois de gerar:** o texto só aparece na tela; nada é gravado.
- **Onde aparece:** aba "Rascunho IA" na página da oportunidade.
- **Tempo aceitável:** 15 segundos.
- **Dado pessoal:** nome, e-mail e telefone do contato não entram; o texto usa "[nome do contato]".
- **Tom:** profissional e neutro, sem modelo oficial de proposta.
- **Custo de IA:** consumo pela licença atual; licença não confirmada.
- **Documento de origem:** a demanda do card.
- **Follow-up por e-mail:** se precisar sair por e-mail, é passo da equipe do Marketing Cloud; nada é enviado pelo CRM.

## O que não dá para conferir pela tela
- Que nenhuma automação do registro (gatilhos, Flows) dispara ao gerar o rascunho: só com registro de execução técnico. Hoje há prova estática (a tela não faz gravação) em `04-verificacao.md`.
- O detalhe dos testes técnicos está em `05-testes.md`.
