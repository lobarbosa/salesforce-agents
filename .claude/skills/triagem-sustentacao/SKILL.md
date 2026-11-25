---
name: triagem-sustentacao
description: Como o BA analisa uma demanda de sustentação (bug ou melhoria) — separar defeito de dúvida de uso e de mudança de regra, descrever a reprodução, medir o alcance e classificar a severidade pelo contrato. Use na etapa de análise quando a demanda é de sustentação ou relata algo que "parou de funcionar".
---

# Triagem de sustentação

Projeto parte de um pedido novo. Sustentação parte de uma queixa: algo não faz o que a
pessoa esperava. A primeira pergunta não é "o que construir", é "o que está acontecendo, e
isso é defeito?".

## 1. O que é esta demanda

Classifique antes de escrever critérios, e diga a classe no topo da análise:

| Classe | Como reconhecer | O que a análise entrega |
|---|---|---|
| **Defeito** | Já funcionou, ou foi entregue para funcionar assim, e não funciona | Reprodução, alcance, comportamento esperado com a fonte |
| **Dúvida de uso** | O sistema faz o que foi configurado; a pessoa esperava outra coisa ou não sabe o caminho | Explicação do comportamento atual; pode não haver nada a construir |
| **Mudança de regra** | O sistema faz o que foi pedido antes; o negócio quer diferente agora | Critérios novos; é melhoria, com estimativa própria |
| **Dado** | A configuração está certa; um registro ou um grupo deles está errado | O que precisa ser corrigido e por quem; correção de dado em produção é do consultor |
| **Acesso** | Falta permissão, licença ou visibilidade para alguém | Quem, a quê, e quem do cliente autoriza |

"Comportamento esperado" tem de ter fonte: a entrega anterior (`rag_consultar` com o objeto
e o processo), o `CLAUDE.md` do cliente ou a resposta escrita de alguém. Se a única fonte é
a queixa, é pergunta, não defeito confirmado.

Dúvida de uso e pedido de dado não precisam de design nem de build. Diga isso com todas as
letras no encerramento, para quem aprova o gate decidir se a demanda segue.

## 2. Reprodução, sem dado real

Escreva o caminho que leva ao problema em passos que outra pessoa repete:

- perfil ou papel de quem faz;
- objeto e tipo de registro;
- estado do registro antes (fase, campos preenchidos que importam);
- a ação;
- o que acontece e o que deveria acontecer.

Não copie da demanda nome de pessoa, documento, e-mail, telefone ou valor de cliente
(guardrail #2). Descreva o registro pelas características: "oportunidade do tipo Indústria,
fase Proposta, sem produto".

Se a demanda não traz o bastante para reproduzir, isso é a primeira pergunta ao consultor.
Não deduza o caminho.

## 3. Desde quando, e o que mudou

- Sempre foi assim, ou começou numa data?
- O que mudou perto dessa data: uma entrega deste cliente (procure no histórico por
  demandas que tocaram o mesmo objeto), uma atualização da plataforma, uma carga de dados,
  uma troca de perfil.

Uma entrega recente no mesmo objeto é a primeira suspeita. Cite a demanda, para o recon e
o arquiteto olharem primeiro para ela.

## 4. Alcance

Peça ao recon, ou registre como pergunta, o tamanho do problema em contagem agregada:
quantos registros estão no estado afetado, quantos usuários têm o perfil. Só `COUNT()`;
nunca a lista dos registros.

Diga também se há contorno: a pessoa consegue fazer o trabalho por outro caminho enquanto
a correção não chega?

## 5. Severidade

Use a escala do contrato do cliente (`contrato.md`, seção de SLA), se houver. Se o contrato
não define, use esta e diga que é a escala padrão:

| Severidade | Critério |
|---|---|
| Crítica | Processo de negócio parado, sem contorno |
| Alta | Processo prejudicado para muitos, com contorno trabalhoso |
| Média | Afeta poucos, ou tem contorno simples |
| Baixa | Incômodo, texto, aparência |

Escreva a severidade e a justificativa em uma linha. Não a escolha pelo tom da queixa.

## 6. Critérios de aceite de uma correção

Uma correção tem sempre dois grupos de critério:

- **O defeito some**: o caminho da reprodução passa a dar o resultado esperado.
- **O resto continua**: o que já funcionava no mesmo objeto segue funcionando. Liste os
  comportamentos vizinhos que o QA deve retestar (`.claude/skills/teste-de-regressao/SKILL.md`).

Se a correção deixa registros antigos errados, diga: corrigir o que já foi gravado é
escopo separado e precisa de decisão.

## Antes de entregar a análise

- [ ] Classe da demanda no topo, com a fonte do comportamento esperado.
- [ ] Reprodução em passos, sem dado real.
- [ ] Desde quando e a entrega suspeita, se houver.
- [ ] Alcance em contagem e se há contorno.
- [ ] Severidade pela escala do contrato.
- [ ] Critérios do defeito e critérios de regressão.
