# SOMOSAGILITY-18 — Análise: soma de HNC indevida no marco "Execução - Fase de entrega" (PRJ 1384)

Tipo: **sustentação (bug)**. Etapas aplicáveis: 1, 2, 3 (design enxuto), 4, 5, 7.
Chamado interno do cliente: `Agility 20260911-026`.
Registro afetado: `Marcos__c` `a0zU400000ASbVAIA1` (marco "Execução - Fase de entrega", PRJ 1384).

## 1. Contexto de negócio

O marco "Execução - Fase de entrega" do projeto PRJ 1384 acumula horas não comerciais
(HNC). O cliente reportou, no chamado de 2026-09-11, que o valor do marco está somando
horas não comerciais de forma indevida. Hoje não sabemos, pela demanda, se o problema é
de **mais horas** do que deveria entrar, de **horas de outro escopo/marco** entrando, ou
de **duplicidade** de registros. Esse ponto muda a correção inteira e precisa ser
respondido antes do design (ver seção 5).

Como o marco é usado para acompanhamento de consumo/entrega do projeto, um total inflado
distorce a leitura de progresso e pode afetar o que o cliente vê como horas já consumidas.
O impacto financeiro e de faturamento **não está descrito** na demanda (ver seção 4).

## 2. Objetivo

Fazer o total de HNC do marco "Execução - Fase de entrega" do PRJ 1384 refletir apenas as
horas que a regra de negócio define como não comerciais e que pertencem a esse marco,
sem alterar o comportamento de outros marcos, projetos ou clientes.

Objetivo **não mensurável ainda**: falta a definição de "correto" (seção 4, perguntas 1 e 2).

## 3. Regra de negócio

Regra **declarada hoje**: o marco soma HNC. Regra **implícita** (a confirmar):

- Entram na soma: horas classificadas como HNC, vinculadas a este marco/projeto.
- Não deveriam entrar (hipótese, **não confirmada**): horas comerciais, horas de outros
  marcos ou projetos, e possivelmente apontamentos duplicados ou fora do período do marco.

Nenhuma dessas hipóteses está validada. Nenhuma regra nova será codificada sem resposta.

## 4. Critérios de aceite

Os critérios abaixo são **provisórios**: o resultado esperado (valores e quais registros
entram) depende das respostas da seção 5. Não são testáveis como estão e ficam bloqueados
até a resposta.

```gherkin
Funcionalidade: Soma de HNC do marco "Execução - Fase de entrega" do PRJ 1384

  Cenário: Marco soma somente as HNC que pertencem a ele
    Dado que o marco "Execução - Fase de entrega" do PRJ 1384 possui apontamentos
      de HNC vinculados a ele e a outros marcos ou projetos
    Quando o total de HNC do marco é recalculado
    Então o total é igual à soma apenas dos apontamentos que atendem à regra de negócio
      definida na pergunta 2 da seção 5
    # BLOQUEADO: depende da resposta à pergunta 2 (quais registros entram)

  Cenário: Apontamento que não é HNC não entra na soma
    Dado um apontamento de horas comerciais vinculado ao marco
    Quando o total de HNC do marco é recalculado
    Então esse apontamento não altera o total de HNC
    # BLOQUEADO: confirmar se "comercial" é a classificação excluída

  Cenário: Duplicidade não infla o total
    Dado que existe o mesmo apontamento de HNC registrado mais de uma vez
    Quando o total de HNC do marco é recalculado
    Então cada apontamento é contado uma única vez
    # BLOQUEADO: confirmar se há duplicidade de fato (pergunta 3)

  Cenário: Outros marcos e projetos não mudam
    Dado que a correção foi aplicada ao marco do PRJ 1384
    Quando o total de HNC de qualquer outro marco ou projeto é consultado
    Então o valor é igual ao valor anterior à correção
    # Testável já: vira teste de não regressão com amostra antes/depois

  Cenário: Valor corrigido é reconciliado com a fonte
    Dado o total de HNC do marco após a correção
    Quando é comparado com a soma manual dos apontamentos elegíveis exportados pela
      equipe de delivery
    Então os dois valores são iguais
    # BLOQUEADO: depende das perguntas 1 e 2
```

Critério não bloqueado (já testável): o marco continua exibindo o campo de HNC sem erro e
nenhum registro é apagado ou alterado fora do cálculo de HNC.

## 5. O que a demanda NÃO diz (perguntas a responder antes do design)

1. **Qual é o valor esperado** do marco? (ex.: qual total o cliente considera correto,
   mesmo que aproximado — e em que data.)
2. **Quais horas devem entrar** na soma? Definição exata de "hora não comercial" e de
   quais apontamentos pertencem ao marco (por projeto, por marco, por período, por
   tipo de atividade).
3. **O que está inflando o valor?** O cliente identificou algum apontamento específico
   errado, ou só percebeu que o total está alto? Há duplicidade, horas de outro marco,
   horas comerciais classificadas como HNC, ou horas fora do período?
4. **Desde quando** o total está errado? Houve alguma mudança recente (campo, Flow, regra
   de cálculo, carga de dados, migração) que coincida com o início do problema?
5. **O erro afeta outros marcos ou projetos** além do PRJ 1384 e do marco "Execução -
   Fase de entrega"? Há outros marcos com o mesmo nome em outros projetos?
6. **Quem consome o valor** do marco? Há integração, relatório, faturamento ou
   automação que leia esse total? Isso define a urgência e se é preciso comunicar a
   correção a outro time.
7. **O valor já foi usado** em fechamento, faturamento ou relatório ao cliente? Se sim,
   há necessidade de correção retroativa ou só do valor atual?
8. **Como o marco é recalculado hoje?** Por campo de rollup, fórmula, Flow, Apex ou
   manualmente? (Esta é a pergunta central para o recon; não há como inferir daqui.)
9. **Quem valida a correção** do lado do cliente e em qual prazo? O chamado tem data de
   2026-09-11 e o último comentário é de 2026-10-19; o prazo acordado não está registrado.
10. **Existe um número de referência** (planilha, relatório, extrato) com o total
    correto, para usar como gabarito na homologação?

Observação de conteúdo: os comentários do card e o e-mail anexo trazem apenas o número do
chamado e a mesma descrição de `demanda.md`. Nenhuma das perguntas acima foi respondida
pelo cliente até agora.

## 6. Premissas a validar

Todas **pendentes**; nenhuma foi confirmada na org nem com o cliente.

- **P1 — Pendente.** O campo de HNC do marco é calculado dentro da org (rollup, fórmula ou
  Flow/Apex), e não vem de integração externa. Validação: recon na org (`sf` CLI).
- **P2 — Pendente.** O problema está restrito ao PRJ 1384. Validação: consultar, com
  agregados apenas (sem dado de cliente), outros marcos com o mesmo nome.
- **P3 — Pendente.** O objeto `Marcos__c` e o campo de HNC existem com o nome usado pela
  demanda. Nenhum nome de campo foi confirmado; **não referenciar nenhum campo ou Flow
  nas etapas seguintes sem confirmação via `sf` CLI**.
- **P4 — Pendente.** A correção pode ser feita sem alterar os apontamentos de horas
  existentes (só a regra de cálculo). Se for preciso corrigir dados, a demanda muda de
  escopo e precisa de nova análise.
- **P5 — Pendente.** Não há necessidade de correção retroativa em fechamento já emitido.
  Validação: pergunta 7.

## 7. Complexidade

**M.** A causa é desconhecida e pode estar em rollup, fórmula, Flow ou dado. Se for uma
regra de agregação simples, cai para P; se envolver mais de um componente ou correção de
dados, vai para G.

## 8. Estimativa de esforço humano

**Estimativa de esforço:** 6–14 h

Premissas que mais pesam na faixa:
- Recon e identificação da causa na org (4–6 h), que pode ser curto se o erro for uma
  fórmula ou rollup óbvio e longo se for Flow ou Apex com lógica própria.
- Respostas do cliente às perguntas 1 a 3 e 10 da seção 5. Sem elas, a faixa não fecha e
  o esforço de validação com o cliente pode dobrar.
- Correção e teste de não regressão em amostra (outros marcos e projetos).
- Faixa larga porque a demanda é vaga; o arquiteto refina no design.

## Próximo passo

Antes do arquiteto, é preciso responder as perguntas 1, 2 e 3 da seção 5 com o consultor
ou com o cliente, e o recon (etapa 2) precisa confirmar P1 e P3 na org de dev.

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
