# Roteiro de teste — Total de despesas realizadas do projeto

Foi corrigido o campo **Total de despesas realizadas** do projeto, que não somava corretamente quando só a etapa da Solicitação de Reembolso (SR) mudava. Agora o total acompanha a aprovação, rejeição e recolhimento das SR.

**Situação do teste automático:** testes automáticos foram executados na QA (11 de 11 passaram: soma, projeto sem despesa, rejeição, recolhimento, lote de 200). Não foi feito teste pela tela com aprovação real; é o que este roteiro cobre.

## Antes de começar
- Ambiente: sandbox de QA (`sbx-somos-agility-qa`).
- Perfil: Gerente de Projeto (GP) que aprova SR, e um solicitante.
- Crie um projeto de teste chamado "TESTE SOMOSAGILITY-10 Projeto A" e outro "TESTE SOMOSAGILITY-10 Projeto B" (este sem nenhuma despesa). Crie duas SR de teste com lançamentos de despesa vinculados ao Projeto A, valores 100 e 50.

## Teste 1 — Soma ao aprovar
1. Abra a SR de teste com despesa de 100 e envie para aprovação.
2. Entre como GP e aprove.
3. Abra o "TESTE SOMOSAGILITY-10 Projeto A" e olhe o campo **Total de despesas realizadas**.

**Resultado esperado:** 100.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Segunda SR soma
1. Repita o teste 1 para a SR de valor 50.
2. Reabra o Projeto A.

**Resultado esperado:** Total de despesas realizadas = 150.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Rejeição retira da soma
1. Rejeite (ou recolha) a SR de valor 50.
2. Reabra o Projeto A.

**Resultado esperado:** Total = 100.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Projeto sem despesa
1. Abra "TESTE SOMOSAGILITY-10 Projeto B".

**Resultado esperado:** o campo Total de despesas realizadas mostra 0 (e não fica em branco) depois que alguma SR do projeto é alterada; sem nenhuma SR, não há mudança.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Carga de 200 SR de uma vez e limites do sistema: evidência em `05-testes.md` (caso T7).
- Recálculo de projetos antigos: não faz parte desta entrega (decisão do design).
- Valores enviados ao MS Project mudam em projetos com SR rejeitada: confirmar com o time técnico.
