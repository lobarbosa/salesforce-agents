---
name: provar-criterio
description: Como o verificador e o QA transformam "não consegui exercitar" em prova, e como registram a origem de cada falha (construção, ambiente ou não exercitado) para ela chegar a quem resolve. Use na verificação e no QA, antes de marcar um critério como não executado e antes de escrever uma falha.
---

# Provar o critério, e dizer de quem é a falha

Medição de 2026-11-25: de 71 falhas de QA, cerca de 27 eram "não consegui executar" e 14
eram de ambiente ou ativação. Só umas 30 eram defeito de construção. E 22 de 54
verificações saíram inconclusivas. Reprovar por não ter exercitado devolve a demanda ao
builder, que não tem o que corrigir, e ela volta igual: SOMOSAGILITY-22, SOMOSAGILITY-27 e
EPLAST-40 repetiram a mesma falha em duas rodadas seguidas.

## Antes de escrever "não executado"

Percorra a lista. Só depois dela o caso é não executável.

| O que impediu | O que fazer |
|---|---|
| Não há dado para o caso | Crie. Comece pelas fixtures de `clients/<cliente>/fixtures/`; se a validation rule recusar, leia a fórmula e preencha o que ela exige. Tentar a criação mínima e desistir não é teste. |
| A versão da demanda está inativa | Ative na sandbox do teste (Flow, agente, modelo de prompt), confira na org e registre a versão de antes e a de depois. É parte do teste, não precisa de autorização no card. |
| O componente não está na org | Confira `05-deploy-qa.md`. Componente listado e ausente é falha crítica de deploy, não "não executado". |
| A tela não abre ou a ferramenta de navegador recusa | Prove pela chamada direta (Flow, classe, consulta) e deixe a parte de tela no roteiro do cliente, dizendo o que ficou para ele. |
| A automação só roda por agendamento | QA em duas fases (`.claude/skills/teste-em-sandbox/agendada.md`). Não reprove. |
| O teste precisa de permissão que você não tem | No seu usuário de execução, atribua o permission set que a própria demanda criou, e desfaça ao final. |
| O teste estoura limite de consultas | Uma transação por coisa: crie os dados numa execução e chame a automação em outra. |
| O agente não responde como esperado | Teste a ação direto, para separar ação de modelo (`.claude/skills/agentforce/SKILL.md`). |
| Falta licença, usuário de teste, membro de fila, acesso | Isso você não resolve. É falha de **ambiente**: registre com a origem certa (abaixo). |

## Evidência por caso

Cada caso aprovado tem o comando ou a tela que provou, e o que voltou: contagem, mensagem,
código de resultado, nome do arquivo de captura. "Testado e funcionando" não é evidência.
Critério principal sem evidência reprova.

Comportamento intermitente (resposta de modelo, concorrência): repita e registre a
proporção, "passou 3 de 4". Uma execução boa não aprova um caso que falha às vezes.

## Diga a origem de cada falha

Logo abaixo do título `### FALHA <n> (crítica|média|branda) — <resumo>`, uma linha:

`**Origem:** construção` | `ambiente` | `não exercitado`

- **construção**: o que foi construído não faz o que o critério pede. Quem corrige é o
  builder. Escreva como reproduzir, o obtido, o esperado e a causa provável, com o nome do
  componente quando souber.
- **ambiente**: a construção pode estar certa, mas a org não permite provar (licença, fila
  sem membro, usuário inativo, dado que só existe em produção, outra demanda que alterou o
  mesmo componente). Quem resolve é uma pessoa. Diga exatamente o que falta e quem pode
  providenciar. **Não devolva isto ao builder como se fosse defeito.**
- **não exercitado**: você percorreu a lista acima e ainda não conseguiu. Diga o que
  tentou, em que passo parou e o que destravaria.

O título continua no formato que o Squad OS lê; a linha de origem vem abaixo e não muda
isso. Quem lê o roteiro reprovado (o builder, o operador, o responsável) decide por ela
para onde a demanda vai.

## Nova rodada

Se existe `05-testes-rodada-<n>.md` ou `04-verificacao-rodada-<n>.md`, comece retestando
cada falha anterior e diga, uma a uma: corrigida, persiste ou mudou de causa. Falha que
persiste pela segunda vez com origem `ambiente` ou `não exercitado` não é para mais uma
rodada de build: diga no topo do roteiro que a demanda precisa de uma pessoa.

## O que não muda

- Só a sandbox da etapa (dev na verificação, QA no QA), com a org alvo explícita.
- Só dado de teste que você criou. Nenhuma consulta que devolva dado pessoal ou de negócio
  de cliente; nenhuma captura de registro real.
- Falha é falha: não arredonde para "passou com ressalva".
