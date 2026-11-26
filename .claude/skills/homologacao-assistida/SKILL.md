---
name: homologacao-assistida
description: Prepara a sessão de homologação ao vivo com o cliente — classifica a fila de demandas em homologação, aponta o que precisa ser reconferido antes e monta a pauta. Use quando a fila de homologação de um cliente estiver parada ou antes de uma reunião de aceite. Para o time de delivery.
---

# Homologação assistida

Demanda pronta e não homologada é estoque: consome hora do contrato, ocupa a sandbox e
envelhece. Esperar o cliente abrir o card sozinho não funcionou. A homologação passa a ser
uma sessão marcada, conduzida pelo consultor da conta, com a fila preparada antes.

A sessão não substitui o aceite: quem aprova no portal é o cliente, com o próprio usuário.
Ninguém do time clica por ele, e não existe aceite por decurso de prazo.

## 1. Classificar a fila

Liste as demandas do cliente em `aguardando_homologacao` (skill `status-da-esteira`,
`.claude/skills/status-da-esteira/SKILL.md`) e, para cada uma, responda com o que o card e
a branch registram:

| Pergunta | Onde olhar | Se a resposta for não |
|---|---|---|
| O cliente ainda quer isto? | comentários do card, data do pedido | propor cancelamento na sessão |
| O teste é recente? | data de `05-testes.md` | mais de 7 dias, ou outra demanda entrou na QA depois: reconferir (passo 2) |
| O cliente consegue testar? | usuário de teste na sandbox de QA, licença livre | resolver o acesso antes; sem acesso, a sessão não rende |
| As horas estão aprovadas? | `ea` igual a `ec` | aprovar as horas na mesma sessão |
| Depende de outra demanda? | `00-preflight.md`, design | ordenar a pauta; homologar a dependência primeiro |
| É entrega manual? | `entrega_manual_em` | levar a evidência anexada, não o roteiro de QA |

A causa da espera não se presume. Se o card não diz por que o cliente não homologou, essa é
a primeira pergunta da sessão.

## 2. Reconferir o que envelheceu

Sandbox de QA é compartilhada: o que foi aprovado há uma semana pode ter sido alterado por
outra demanda (achado real: a ordem de processos de aprovação foi invertida pelo deploy de
outra demanda). Para o que envelheceu, peça uma nova rodada de QA antes da sessão. Não leve
ao cliente um roteiro que talvez não reproduza.

## 3. Montar a pauta

Uma página por cliente, na ordem em que será testado:

- código e título, em linguagem do cliente;
- o que muda para quem usa (duas linhas, do roteiro do cliente);
- o roteiro (`05-roteiro-cliente.md`, o PDF do card) e o usuário com que testar;
- o que precisa ser decidido além do aceite (horas, cancelamento, dúvida de negócio).

Limite a sessão a 45 minutos e ao que cabe nela; o resto fica para a semana seguinte, no
mesmo horário.

## 4. Depois da sessão

- Aprovado: o cliente homologa no portal durante a sessão.
- Reprovado: a observação do cliente vai para o card com as palavras dele, e a demanda volta
  para correção.
- Não quer mais: cancelar com o motivo.
- Registre no card de cada demanda o que foi combinado. O que subir para produção segue a
  skill `subir-producao` (`.claude/skills/subir-producao/SKILL.md`).

Não abra build novo para um cliente com mais de 5 demandas em homologação: é produzir para
uma fila que não anda.
