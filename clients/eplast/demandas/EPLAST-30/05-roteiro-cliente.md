# EPLAST-30 · Roteiro de teste — Rascunho comercial com IA

Foi entregue uma aba nova, "Rascunho IA", na página da Oportunidade. Ela gera, a partir dos dados da própria oportunidade, um rascunho de proposta, de follow-up ou de argumentos comerciais. O texto é só uma sugestão para o vendedor revisar: nada é gravado, nenhum e-mail é enviado e não entram cotação nem dados do contato.

**Situação do teste automático:** comprovei na QAS que a aba aparece com o acesso concedido, que a geração da proposta pela tela funciona (texto em cerca de 10 segundos, citando a conta) e que follow-up e argumentos geram o texto correto quando o modelo de IA é chamado diretamente. Não consegui escolher "Follow-up" e "Argumentos comerciais" pela tela (limite da ferramenta de teste) e não pude testar o acesso de outro usuário, a falha da IA nem o registro técnico de execução. Esses pontos estão nos testes abaixo, para quem segue o roteiro.

## Antes de começar
- Ambiente: sandbox QAS (eplast--qas).
- Perfil: usuário comercial com o acesso "Rascunho Comercial IA" atribuído (o time técnico atribui). Para os testes 7 e 8, um segundo usuário sem esse acesso e um terceiro sem acesso à oportunidade "Y".
- Dado de teste: use a oportunidade "TESTE EPLAST-30 Opp" (conta "TESTE EPLAST-30 Conta", etapa Qualificação, data de fechamento 31/12/2026, sem Valor). Para o teste 4, crie outra oportunidade de teste sem data de fechamento preenchida, se o sistema permitir, ou use uma sem Valor. Nunca use oportunidade de cliente real.

## Teste 1 — A aba aparece e gera a proposta
1. Abra a oportunidade "TESTE EPLAST-30 Opp".
2. Clique na aba "Rascunho IA".
3. Deixe marcada "Proposta comercial" e clique em "Avançar" (o botão dentro da aba).
**Resultado esperado:** em até 15 segundos aparece o aviso "Rascunho gerado por IA: revise antes de usar. Nenhum campo deste registro foi alterado." e um texto editável que cita a conta "TESTE EPLAST-30 Conta" e a etapa "Qualificação".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Follow-up
1. Na aba "Rascunho IA", marque "Follow-up" e clique em "Avançar".
**Resultado esperado:** texto editável com o nome da conta e a data de fechamento (31/12/2026). Sem e-mail, telefone ou nome de contato: aparece "[nome do contato]".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Argumentos comerciais com fonte
1. Na aba, marque "Argumentos comerciais" e clique em "Avançar".
**Resultado esperado:** lista de argumentos em que cada item indica de qual campo veio, entre parênteses (por exemplo "fonte: Etapa"). Campo vazio não vira argumento.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Dado ausente não é inventado
1. Use uma oportunidade de teste sem data de fechamento (ou sem Valor).
2. Gere a proposta.
**Resultado esperado:** o trecho aparece como "[dado ausente: data de fechamento]" (ou "[dado ausente: valor]"), nenhuma data ou valor inventado, e o texto traz a lista de campos usados e de campos vazios.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Preço, desconto, prazo e condição sem fonte
1. Na oportunidade de teste sem Valor, gere a proposta.
**Resultado esperado:** desconto, prazo e condição de pagamento aparecem como "[a preencher]", sem nenhum número inventado. Se a oportunidade tiver Valor, o texto cita exatamente esse valor, sem arredondar.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Nada é gravado nem enviado
1. Depois de gerar os rascunhos, confira a oportunidade, a conta e a linha do tempo de atividades.
**Resultado esperado:** nenhuma tarefa, compromisso ou e-mail novo; o campo "Última modificação" da oportunidade não mudou.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 7 — Usuário sem o acesso não vê a aba
1. Entre com o usuário sem o acesso "Rascunho Comercial IA".
2. Abra qualquer oportunidade de teste.
**Resultado esperado:** só aparecem as abas "Detalhes" e "Histórico Da Oportunidade"; não existe "Rascunho IA".
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 8 — Quem não vê a oportunidade não gera rascunho
1. Entre com o usuário que tem o acesso, mas não enxerga a oportunidade "Y" (de teste).
2. Tente abrir "Y" e gerar o rascunho.
**Resultado esperado:** a mesma mensagem de acesso negado que o Salesforce já mostra; nenhum texto é gerado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 9 — Falha da IA não trava o registro
1. Com apoio do time técnico, simule o serviço de IA indisponível e peça um rascunho.
**Resultado esperado:** mensagem de falha na aba e a oportunidade continua editável normalmente.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que assumimos e você precisa confirmar
- **Texto livre fora:** os campos de descrição e "próximo passo" da oportunidade não entram no rascunho (podem ter dado pessoal ou instruções soltas). Se quiserem, dá para incluir depois de revisar.
- **Sem cotação:** o rascunho não usa a cotação (CPQ). O único valor citado é o Valor da própria oportunidade; o resto fica "[a preencher]". Confirmem se isso atende ou se querem cotação em uma versão futura.
- **Sem dado do contato:** o nome vem sempre como "[nome do contato]"; e-mail e telefone nunca entram.
- **Somente leitura:** nada é salvo nem enviado; o vendedor copia o texto. Qualquer envio por e-mail seria passo do Marketing Cloud, fora desta entrega.
- **Quem usa:** os perfis comerciais, por atribuição manual do acesso.
- **Tempo:** 15 segundos é considerado aceitável.
- **Tom:** neutro e profissional; a Eplast ajusta o texto na homologação.
- **Custo de IA:** fica com a licença da Eplast, a confirmar antes de ir para produção.
- **Assistente existente:** o agente SFAgent2 não foi alterado; a nova aba é independente dele.

## O que não dá para conferir pela tela
- Ausência de gravação, gatilhos e automações disparadas pelo rascunho (só pelo registro técnico de execução): o time técnico confere na homologação. Evidência parcial (contagens de tarefas e eventos) está em `05-testes.md`.
- Conteúdo de Follow-up e Argumentos gerado diretamente pelo modelo na QAS: evidência em `05-testes.md`.
- Aviso: a demanda EPLAST-41 mexe nos mesmos componentes; se algo no Rascunho IA falhar junto com a tarefa de relacionamento, avise o time.
