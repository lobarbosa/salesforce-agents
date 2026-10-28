# SOMOSAGILITY-18 — Plano de build

**Status: BUILD BLOQUEADO. Nenhum metadata foi criado ou alterado.**

## Por que está bloqueado

`03-design.md`, seção 3, é explícito: "Este design não escolhe uma causa sem evidência" e
"trava o build até a causa ser confirmada". O design mapeia quatro hipóteses (H1–H4) para
quatro correções diferentes (seção 4) — configuração, Flow, Apex, ou nenhuma mudança — e cada
uma tem efeito, risco e escopo distintos (ver seção 8 do design, especialmente o risco "Alta"
de corrigir a hipótese errada). Escolher uma hipótese sem confirmação para "ter algo pronto"
contrariaria o próprio design já aprovado pelo gate.

Reler os artefatos em disco antes deste plano (01-analise.md, 02-recon.md, 03-design.md,
comentarios-do-card.md, e o anexo do card) não encontrou em nenhum lugar a confirmação de qual
hipótese é a causa real. O que existe registrado:

- `gates.md` registra aprovação humana (Leonardo Barbosa) de `01-analise.md` e, depois, de
  `02-recon.md` + `03-design.md`. Essas aprovações validam o **raciocínio e o plano de ação
  condicional** descritos nesses documentos — não substituem o diagnóstico que os próprios
  documentos dizem estar pendente.
- `comentarios-do-card.md` só traz o número do chamado interno do cliente e registros
  mecânicos de aprovação de gate/estimativa. Nenhuma resposta às perguntas 1, 2 ou 3 da seção 5
  de `01-analise.md`.
- O anexo do card (PDF) é o mesmo e-mail que originou `demanda.md`, sem informação de
  diagnóstico adicional.
- `02-recon.md`, seção 7: a sandbox de dev tem 0 marcos e 0 lançamentos — o registro do
  chamado (`a0zU400000ASbVAIA1`) só existe em produção, fora do alcance do agente (guardrail
  #1). Não há como confirmar a causa pela org de dev.

## O que falta para destravar o build

Um humano com acesso à produção precisa abrir o marco `a0zU400000ASbVAIA1` ("Execução - Fase
de entrega", PRJ 1384), olhar a related list de Lançamentos de Atividades aprovados, e
responder, com sim/não por hipótese (sem exportar nem colar dado de cliente):

### Perguntas da seção 3 de `03-design.md`

| # | Pergunta (sinal no registro) | Confirma/descarta |
|---|---|---|
| 1 | Há lançamento aprovado do marco com início e fim em dias diferentes, ou HNC desproporcional à duração da atividade? | H1 |
| 2 | Há lançamento do marco com o 1º "Shadow?" (`Shadow_1__c`) marcado? | H2 |
| 3 | Há lançamento com "Qtd. de executores" (`Qtd_de_executores__c`) menor que o número de pares início/fim preenchidos? | H3 |
| 4 | Qual campo da tela o cliente considera errado, e qual valor ele esperava ver? (distingue H4 — campo legado/fórmula `*2` — das demais) | H4 |

### Perguntas da seção 5 de `01-analise.md` ainda abertas e que bloqueiam o build

| # | Pergunta |
|---|---|
| 1 | Qual é o valor esperado do marco (total que o cliente considera correto, e em que data)? |
| 2 | Quais horas devem entrar na soma — definição exata de "hora não comercial" e de pertencimento ao marco? |
| 3 | O que está inflando o valor — duplicidade, horas de outro marco, horas comerciais mal classificadas, ou horas fora do período? |

Pergunta 7 da análise (valor já usado em fechamento/faturamento) também importa se a causa
confirmada for H2, porque a correção de fórmula recalcula o histórico inteiro automaticamente
(seção 6 e seção 8 do design).

## Recomendação

Devolver a demanda para uma rodada de análise com o consultor/cliente antes de qualquer
construção: levar exatamente as quatro perguntas acima (seção 3 do design) ao registro do
chamado em produção. Com a hipótese confirmada, a correção correspondente já está decidida em
`03-design.md`, seção 4, e o build pode seguir sem precisar de novo gate de design (a menos que
a resposta aponte para uma causa fora de H1–H4, caso em que o design volta para revisão,
conforme a própria seção 3 prevê).

## O que NÃO foi feito nesta sessão

- Nenhuma branch foi criada.
- Nenhum metadata (Flow, fórmula, Apex, validation rule) foi criado ou alterado em
  `force-app`.
- Nenhum PR foi aberto.
- `gates.md` e `status.yaml` não foram tocados — são mecânicos, fora do escopo deste agente.
