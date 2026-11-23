# Roteiro de teste — Aprovação de JOB de investimento criado pelo Cyber (SOMOSAGILITY-17)

Foi criado um processo de aprovação exclusivo para os JOBs de investimento criados pelo usuário "Grupo Cyber Salesforce". Esses JOBs passam a seguir a ordem: Gustavo, depois Wanderley, depois Walmor. JOBs criados por outras pessoas continuam no caminho de hoje.

**Situação do teste automático:** o time conferiu a configuração do processo na sandbox de QA (processo ativo, critério de entrada, três aprovadores na ordem). A conferência apontou que a ordem de avaliação entre o processo novo e o processo geral estava invertida na QA, e a demanda voltou para ajuste. Os testes abaixo, que exigem entrar como o usuário Cyber e como cada aprovador, não foram executados pelo time (decisão do responsável): ficam para quem segue este roteiro, depois do ajuste.

## Antes de começar
- Ambiente: sandbox de QA (`sbx-somos-agility-qa`).
- Você precisa entrar com: o usuário "Grupo Cyber Salesforce" (para criar), e com Gustavo, Wanderley e Walmor (para aprovar). Também um usuário de outro criador que já tenha processo de aprovação (por exemplo, o criador atendido pelo processo "Aprova JOB").
- Dado de teste: ao criar o JOB, preencha o nome com `TESTE SOMOSAGILITY-17` e os demais campos obrigatórios com valores fictícios. Não use JOB real.

## Teste 1 — Primeiro aprovador é o Gustavo
1. Entre como Grupo Cyber Salesforce.
2. Abra a aba "JOB de Solicitação de Investimento" e clique em Novo.
3. Preencha com dados de teste e salve.
4. Clique em "Enviar para aprovação".
5. Abra a seção "Histórico de aprovação" do registro.

**Resultado esperado:** o histórico mostra uma etapa pendente, atribuída ao Gustavo. Não aparece Diretor(a) de Pós-vendas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Wanderley e Walmor não agem antes da vez
1. Com o JOB do Teste 1 aguardando o Gustavo, entre como Wanderley e procure o JOB em "Itens para aprovar".
2. Repita como Walmor.

**Resultado esperado:** o JOB não aparece pendente para Wanderley nem para Walmor.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Segunda e terceira aprovações
1. Entre como Gustavo, abra "Itens para aprovar" e aprove o JOB de teste.
2. Entre como Wanderley, confirme que o JOB agora está pendente para ele e aprove.
3. Entre como Walmor, confirme que o JOB está pendente para ele e, antes de aprovar, confira o campo "Status da Qualificação".
4. Aprove.

**Resultado esperado:** a cada aprovação o próximo da fila recebe o item. Antes da aprovação do Walmor o status não é "Aprovado". Depois dela o campo "Status da Qualificação" mostra "Aprovado" e o histórico traz as três aprovações.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Rejeição
1. Como Grupo Cyber Salesforce, crie outro JOB `TESTE SOMOSAGILITY-17` e envie para aprovação.
2. Como Gustavo, aprove. Como Wanderley, rejeite.

**Resultado esperado:** o JOB fica com status "Rejeitado" e o processo encerra (não volta para o Gustavo). Se o negócio quiser outro comportamento, informe agora.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — JOB de outro criador não muda
1. Entre com um usuário de outro criador, crie um JOB `TESTE SOMOSAGILITY-17` e envie para aprovação.
2. Abra o "Histórico de aprovação".

**Resultado esperado:** o aprovador é o mesmo de antes desta mudança; Gustavo e Wanderley não aparecem.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
A ordem em que o Salesforce avalia os processos de aprovação (o do Cyber antes do geral) e o conteúdo de cada passo foram conferidos pelo time por consulta de configuração. A evidência e a falha encontrada estão em `05-testes.md`.
