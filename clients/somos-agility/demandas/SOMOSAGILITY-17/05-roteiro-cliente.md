# Roteiro de teste — SOMOSAGILITY-17: aprovação de JOB de Investimento criado pelo usuário Cyber

Foi entregue um processo de aprovação próprio para os JOBs de Investimento criados pelo usuário Cyber (Grupo Cyber Salesforce). Esses JOBs passam a ser aprovados nesta ordem: Gustavo, depois Wanderley, depois Walmor. JOBs criados por outras pessoas continuam no caminho de aprovação de hoje.

**Situação do teste automático:** reconferido em 24/11, depois da implantação da outra demanda no mesmo objeto: a ordem (Cyber antes do geral) segue correta. Comprovado na sandbox de QA, por consulta à configuração, que o processo existe, está ativo, vem antes do processo geral, tem a entrada (criado pelo Cyber e ainda não aprovado) e os três aprovadores na ordem certa. Não foi executado o envio e a aprovação de verdade, porque exige os usuários reais (Cyber, Gustavo, Wanderley, Walmor e outro criador); isso fica para os testes abaixo.

## Antes de começar
- Ambiente: sandbox de QA (`sbx-somos-agility-qa`).
- Você precisa entrar como: usuário Cyber (para criar e enviar), Gustavo, Wanderley, Walmor e uma pessoa que não seja o Cyber (para o Teste 5). Se não for possível entrar como cada um, peça ao administrador da sandbox que faça cada etapa com o usuário indicado.
- Dado de teste: crie um JOB de Investimento novo com nome "TESTE SOMOSAGILITY-17 A" (e outro "TESTE SOMOSAGILITY-17 B" para rejeição), preenchendo os campos obrigatórios com valores fictícios. Não use JOB real. O campo Status da Qualificação não pode estar "Aprovado".

## Teste 1 — Cyber envia e Gustavo é o primeiro aprovador
1. Entre como Cyber.
2. Crie o JOB "TESTE SOMOSAGILITY-17 A".
3. Clique em "Enviar para aprovação".
4. Abra o histórico de aprovação do registro.

**Resultado esperado:** a aprovação fica pendente para Gustavo, e só para ele.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Wanderley e Walmor não agem antes da vez
1. Entre como Wanderley e procure o item pendente do JOB "TESTE SOMOSAGILITY-17 A".
2. Repita como Walmor.

**Resultado esperado:** nenhum dos dois vê o item para aprovar nem consegue aprová-lo enquanto Gustavo não agiu.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Cadeia de aprovação até o fim
1. Entre como Gustavo e aprove o JOB.
2. Entre como Wanderley, confirme que o item chegou para ele e aprove.
3. Entre como Walmor, confirme que o item chegou para ele e aprove.
4. Abra o JOB e olhe o campo Status da Qualificação e o campo Status Previsão de Gastos.

**Resultado esperado:** o item passa por Gustavo, Wanderley e Walmor, nessa ordem. O JOB só fica aprovado depois de Walmor: Status da Qualificação "Aprovado" e Status Previsão de Gastos coerente com a aprovação.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Rejeição
1. Como Cyber, crie "TESTE SOMOSAGILITY-17 B" e envie para aprovação.
2. Como Gustavo, aprove.
3. Como Wanderley, rejeite com um comentário.

**Resultado esperado:** o JOB fica rejeitado (Status da Qualificação de rejeição) e não vai para Walmor. Obs.: a regra de rejeição foi assumida igual à do processo atual; confirme se é o desejado.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — JOB de outro criador não muda
1. Entre como uma pessoa que não seja o Cyber e que já cria JOBs hoje.
2. Crie um JOB de teste "TESTE SOMOSAGILITY-17 C" e envie para aprovação.

**Resultado esperado:** a aprovação segue o caminho de sempre para esse criador (não começa por Gustavo/Wanderley/Walmor, a menos que já fosse assim).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Ordem de avaliação dos processos, critérios de entrada, aprovadores e ações: comprovados por consulta à configuração da QA, registrados em `05-testes.md`.
- JOBs do Cyber já pendentes de aprovação antes da entrega seguem o caminho antigo; decisão do cliente antes do release.
- Em produção, o time confere a ordem dos processos e o usuário ativo do Gustavo depois da implantação.
