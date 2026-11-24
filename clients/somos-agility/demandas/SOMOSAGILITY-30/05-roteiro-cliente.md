# Roteiro de teste — Total de despesas realizadas do projeto

Foi entregue a mudança no cálculo do **Total de despesas realizadas** do projeto: agora ele só soma os Lançamentos de Despesa de uma Solicitação de Reembolso quando ela chega em **Aprovado**. Etapas pendentes e solicitações rejeitadas ou recolhidas não entram no total.

**Situação do teste automático:** comprovado na sandbox de QA, com dados de teste: os testes automáticos (12 de 12) e a sequência de etapas com total 0, 150, 0, 150, 0. Não foi conferido pela tela. Quem segue este roteiro confere o que aparece no registro do projeto.

## Antes de começar
- Ambiente: sandbox de QA. Perfil: o de quem aprova e cadastra reembolsos.
- Crie um projeto de teste ("TESTE homologação") e uma Solicitação de Reembolso de teste na etapa **Pendente - Gestor**, com dois Lançamentos de Despesa ligados a esse projeto, valores **100** e **50**. Use somente dados de teste.

## Teste 1 — Etapas pendentes não somam
1. Abra o projeto de teste e anote o campo **Total de despesas realizadas** (deve ser 0).
2. Abra a Solicitação e mude a etapa para **Pendente - Diretor**.
3. Volte ao projeto e atualize a página.
4. Repita os passos 2 e 3 com **Pendente - Gerente de Projetos** e **Pendente - Operações**.

**Resultado esperado:** o total do projeto continua **0** em todas as etapas.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 2 — Aprovado soma
1. Mude a etapa da Solicitação para **Aprovado**.
2. Abra o projeto e atualize a página.

**Resultado esperado:** o total é **150**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 3 — Recolhimento tira do total
1. Com a Solicitação aprovada (total 150), mude a etapa para **Recall**.
2. Atualize o projeto.

**Resultado esperado:** o total volta para **0**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 4 — Rejeição não soma
1. Volte a Solicitação para **Aprovado** (total 150) e depois mude para **Rejeitado**.
2. Atualize o projeto.

**Resultado esperado:** o total é **0**.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 5 — Várias solicitações no mesmo projeto
1. Crie uma segunda Solicitação no mesmo projeto, com um Lançamento de **40**, na etapa **Pendente - Diretor**.
2. Deixe a primeira em **Aprovado** (Lançamentos 100 e 50).

**Resultado esperado:** o total do projeto é **150** (a pendente de 40 não entra).
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## Teste 6 — Lançamento sem projeto
1. Crie uma Solicitação com um Lançamento de **80** sem projeto e mude para **Aprovado**.

**Resultado esperado:** nenhum projeto muda de total por causa dele.
- [ ] Conforme
- [ ] Não conforme — o que apareceu:

## O que não dá para conferir pela tela
- Carga (50 solicitações de uma vez) e cobertura dos testes automáticos: evidência em `05-testes.md`.
- Casos de "volta atrás" a partir de Aprovado além de Recall e Rejeitado: dependem de resposta do cliente (P5) e não foram testados.
