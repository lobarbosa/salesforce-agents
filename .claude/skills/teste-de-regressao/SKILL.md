---
name: teste-de-regressao
description: Como o verificador e o QA conferem que a mudança não quebrou o que já funcionava no mesmo objeto — escolher o que retestar, rodar os testes Apex vizinhos e registrar a evidência. Use na verificação e no QA de toda demanda que altera objeto, Flow, classe ou agente que já existe, e em toda correção de sustentação.
---

# Teste de regressão

Os critérios de aceite dizem o que a demanda deve fazer. Não dizem o que ela não pode
estragar. Numa org em uso, a mudança entra num objeto que já tem automação, e o defeito
mais caro é o que aparece em produção num processo que ninguém pediu para mexer.

## Quando fazer

- A demanda altera algo que existe (Flow, classe, agente, validation rule, campo em uso).
- A demanda acrescenta automação a um objeto que já tem automação.
- É correção de sustentação: sempre.

Objeto novo, sem vizinhos, não tem regressão a testar: diga isso em uma linha e siga.

## 1. Escolha o que retestar

Não é para testar a org inteira. Monte uma lista curta a partir de:

- **`02-recon.md`**: as automações no mesmo objeto e evento, e quem usa o que foi alterado
  (seção "Impacto cruzado", quando houver);
- **`03-design.md`**: os riscos que o arquiteto apontou;
- **`01-analise.md`**: os critérios de regressão, quando a demanda é de sustentação;
- **`00-preflight.md`**: outras demandas abertas que mexem no mesmo componente;
- **o histórico do cliente** (`rag_consultar` com o objeto): o que demandas entregues
  antes fazem ali, e os casos que o QA delas aprovou.

De cada fonte, tire o comportamento que mais importa para o negócio e que divide gatilho
com a mudança. Em geral são de três a seis casos. Escreva a lista antes de testar, com o
motivo de cada um.

## 2. Os casos que quase sempre entram

| Caso | Por quê |
|---|---|
| O caminho principal do objeto, sem relação com a demanda | Criar e avançar um registro comum continua funcionando? |
| Registro que **não** atende ao critério da automação nova | A automação nova ficou quieta? |
| A automação vizinha mais importante | Continua disparando, e na ordem certa? |
| Gravação em lote no objeto | A soma das automações cabe nos limites? |
| Outro perfil afetado | Quem não é o público da demanda perdeu algo? |
| Quando é agente: uma ação de outra demanda no mesmo agente | A versão nova manteve o que já existia? |

## 3. Testes Apex vizinhos

Se a demanda toca objeto que tem trigger ou classe, rode os testes das classes vizinhas,
não só os da demanda, na sandbox da etapa e com a org explícita no comando. Teste que
passava e passou a falhar é falha crítica de construção, mesmo que a classe não seja da
demanda.

Teste vizinho que já falhava **antes** da demanda não é regressão: prove (o deploy
anterior, ou a versão ativa de antes) e registre como dívida, com origem `ambiente`.

## 4. Compare com o antes

Regressão só se afirma comparando. Quando der, registre o comportamento com a versão
anterior ativa (o que o registro tinha, o que a automação fez) e depois com a versão nova.
Quando não der para voltar a versão, compare com o que a entrega anterior documentou.

## 5. Registre

No `04-verificacao.md` ou no `05-testes.md`, uma seção "Regressão":

- a lista do que foi retestado e por quê;
- por caso, a evidência (comando ou tela, e o que voltou), como em qualquer caso;
- o que **não** foi retestado e deveria, com o motivo.

Regressão encontrada é `### FALHA` como outra qualquer, com `**Origem:** construção`, e
diz qual comportamento existente quebrou e em qual demanda ele foi entregue.

No roteiro do cliente, inclua um ou dois passos de regressão em linguagem de usuário: "crie
uma oportunidade como sempre fez e confira que nada mudou".

## O que não muda

Só a sandbox da etapa, só dado de teste criado por você
(`.claude/skills/dados-de-teste/SKILL.md`), nenhuma consulta que devolva dado real.
