# SOMOSAGILITY-10 — Análise (BA)

Tipo: sustentação (bug). Etapas aplicáveis: 1, 2, 3 (design enxuto), 4, 5, 7.
Fonte: `demanda.md` (texto do consultor, sem alteração).
Status desta análise: **INCOMPLETA — bloqueada por perguntas abertas (seção 5).**

---

## 1. Contexto de negócio

A demanda relata um erro no campo de **total de despesas realizadas**, no contexto
"PRJ" (título: "Erro no campo total de despesas realizadas - PRJ"). Segundo o relato, o
campo **não está realizando a somatória das SR**: o valor exibido/armazenado não
corresponde à soma esperada dos registros "SR" relacionados.

O impacto de negócio não foi descrito. Não sabemos se o problema afeta relatório,
acompanhamento financeiro do projeto, faturamento ou decisão de equipe, nem quantos
projetos/usuários estão afetados.

## 2. Objetivo

Fazer o campo de total de despesas realizadas do PRJ passar a refletir a soma correta
dos registros SR associados, conforme a regra de soma que o cliente considera correta.

Objetivo **não fechado**: a regra de soma correta e o escopo exato ("SR" = quais
registros) dependem de respostas do cliente (seção 5).

## 3. Regra de negócio

Regra **conhecida** (apenas o que a demanda afirma):

- RN-01: o total de despesas realizadas do PRJ deve ser a somatória das SR.

Regras **não conhecidas** (precisam ser respondidas antes do design):

- RN-02: o que é uma "SR" neste contexto (objeto, nome técnico, tipo de registro).
- RN-03: como a SR se relaciona ao PRJ (lookup, master-detail, hierarquia, outro).
- RN-04: quais SR entram na soma (todas? só status X? só do período? exclui canceladas?).
- RN-05: o que é "despesa realizada" no vocabulário do cliente, e se é o mesmo
  conceito que um campo de "despesa prevista/orçada".
- RN-06: o campo é calculado (roll-up, fórmula, Apex) ou preenchido por processo?
  Hoje, a soma é feita por qual mecanismo?
- RN-07: como tratar o histórico: recalcular registros antigos ou só valer dali em diante?
- RN-08: o que acontece quando não há SR (zero ou vazio).

## 4. Critérios de aceite (Gherkin)

**Status: provisórios.** Os cenários abaixo são a forma testável do que a demanda pede,
mas os termos entre `<colchetes>` ainda não têm nome técnico confirmado e a regra de
soma depende de RN-02 a RN-04. Nenhum nome de objeto/campo foi confirmado na org — isso
é trabalho do recon (etapa 2), não desta análise.

```gherkin
Funcionalidade: Total de despesas realizadas do PRJ soma as SR corretamente

  Cenário: PRJ com várias SR válidas
    Dado que o PRJ "<PRJ-A>" possui as SR "<SR-1>" com valor "<v1>" e "<SR-2>" com valor "<v2>"
    E todas as SR atendem à condição de inclusão definida em RN-04
    Quando o total de despesas realizadas do PRJ é lido (tela, relatório ou API)
    Então o total exibido é "<v1> + <v2>"

  Cenário: PRJ sem SR
    Dado que o PRJ "<PRJ-B>" não possui nenhuma SR
    Quando o total de despesas realizadas é lido
    Então o total é "<valor definido em RN-08>"

  Cenário: SR fora do critério de inclusão não entra na soma
    Dado que o PRJ "<PRJ-C>" possui a SR "<SR-3>" que não atende RN-04
    Quando o total de despesas realizadas é lido
    Então "<SR-3>" não contribui para o total

  Cenário: Alteração de valor de SR recalcula o total do PRJ
    Dado que o PRJ "<PRJ-D>" tem total "<T>" calculado a partir das SR
    Quando o valor de uma SR associada é alterado de "<a>" para "<b>"
    Então o total do PRJ passa a ser "<T> - <a> + <b>"

  Cenário: Inclusão e remoção de SR recalculam o total
    Dado que o PRJ "<PRJ-E>" tem total "<T>"
    Quando uma SR que atende RN-04 é associada ao PRJ
    Então o total passa a incluir o valor dessa SR
    Quando essa SR é desassociada ou excluída
    Então o total volta a "<T>"

  Cenário: Registros históricos (a confirmar RN-07)
    Dado que o PRJ "<PRJ-F>" tem SR criadas antes da correção
    Quando a correção é publicada
    Então o total do PRJ "<PRJ-F>" é "<valor esperado conforme RN-07>"
```

Observação de testabilidade: os cenários de alteração e de histórico só podem ser
fechados depois de RN-07. O cenário de "PRJ sem SR" depende de RN-08.

## 5. O que a demanda NÃO diz (precisa ser respondido antes do design)

**Bloqueantes para o design (arquitetura muda com a resposta):**

1. **Qual é o objeto/campo exato do "total de despesas realizadas"?** Nome técnico ou
   rótulo na tela, e em qual objeto (PRJ? outro objeto com rótulo "PRJ"?).
2. **O que é "SR"?** Objeto, nome técnico e significado de negócio. Não é termo
   Salesforce padrão; precisa ser definido pelo cliente.
3. **Como SR se relaciona ao PRJ?** Lookup, master-detail, hierarquia, ou outra forma.
   Isso decide se a soma é roll-up nativo, fórmula, Flow ou Apex.
4. **Qual a regra de soma esperada?** Quais SR entram (filtros de status, tipo, período,
   aprovação) e qual campo de valor de cada SR é somado.
5. **Como o total é calculado hoje?** Roll-up summary, fórmula, Flow, trigger/Apex, ou
   integração externa. Sem isso não sabemos se o defeito é de configuração ou de código.
6. **Qual é o comportamento errado observado?** Valor exibido vs. valor esperado, com um
   exemplo real anonimizado (sem dado pessoal — guardrail #2). Qual a diferença (soma a
   menos, a mais, zero, duplicado)?

**Não bloqueantes, mas precisam de resposta antes do build:**

7. Desde quando o problema existe? Foi alguma mudança recente (deploy, novo campo, nova
   regra, integração)? Isso orienta o recon.
8. Afeta todos os PRJ ou um subconjunto (por tipo, cliente, data, usuário)?
9. Histórico: recalcular registros antigos é desejado, ou só corrigir daqui para frente?
10. Impacto e urgência: quem usa o total, há prazo (fechamento, relatório, faturamento)?
11. O que é "PRJ" no título: objeto, tipo de registro ou sigla de projeto? (o título
    menciona PRJ, mas o corpo não.)
12. Existe ambiente de homologação com dados representativos para reproduzir sem usar
    dado real de cliente?
13. **Anexo:** o corpo diz "Detalhamento no documento anexo". O anexo **não estava
    disponível nesta sessão** (pasta `demandas/SOMOSAGILITY-10/anexos/` inexistente —
    nenhum anexo foi liberado por delivery). Precisa ser (a) liberado no card com
    declaração de ausência de dado pessoal, ou (b) descrito por texto. Até lá, o
    conteúdo do anexo é **desconhecido** e nenhuma suposição foi feita a partir dele.

## 6. Premissas a validar

Todas pendentes. Nenhuma foi assumida como verdadeira para o design.

- P-01 (pendente): "SR" é um objeto custom ou um registro de objeto padrão com nome
  de negócio diferente.
- P-02 (pendente): o total é um campo de soma (roll-up/fórmula) no PRJ e não um campo
  preenchido manualmente ou por integração.
- P-03 (pendente): o problema é reproduzível em sandbox dev/qa, sem depender de dado real.
- P-04 (pendente): o escopo é sustentação (correção de defeito), não mudança de regra
  de negócio. Se a regra precisar mudar, vira projeto/melhoria e o escopo muda.
- P-05 (pendente): não há outras integrações lendo esse total que sejam afetadas pela
  correção (a validar com recon).

## 7. Estimativa de complexidade

**M (provisória).**

Justificativa: a causa pode ser tanto uma configuração simples (ex.: filtro ou regra de
roll-up, P) quanto lógica de código sobre muitos registros, com cenário de histórico e
impacto em integrações (G). Sem RN-03, RN-06 e RN-07 não há como cravar P ou G.

Reavaliar após as respostas da seção 5.

---

## Próximo passo

Esta análise **não** deve seguir para o arquiteto enquanto as perguntas 1 a 6 da
seção 5 e o anexo (item 13) não forem respondidos, ou pelo menos o anexo liberado.

## Estimativa de esforço

**Estimativa de esforço:** 6–16 h

Esforço humano (consultor configurando, revisando, testando e homologando — não o tempo do agente). M provisória: entre ajuste de roll-up/filtro (ponta baixa) e lógica sobre muitos registros com histórico (ponta alta).

_Estimativa acrescentada em 2026-10-21 a pedido de Leonardo, a partir do que este artefato já registra (o artefato foi gerado antes de a esteira pedir esta linha). É faixa provisória: o consultor lança a estimativa oficial no card._
