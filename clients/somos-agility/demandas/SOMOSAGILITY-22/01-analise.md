# 01 — Análise: SOMOSAGILITY-22 — Relatório de Jobs do painel de controle financeiro

**Cliente:** somos-agility
**Tipo:** sustentação (bug/melhoria) — fluxo reduzido
**Fontes lidas:** `demanda.md`, `comentarios-do-card.md`, anexo `z2zjyb-Relatorio-Job---Painel-controle-financeiro.pdf` (liberado por delivery como sem dado pessoal; lido só como imagem, com legibilidade baixa — ver seção de limites abaixo)
**Status:** análise pendente de validação humana. Não há design nem build até as perguntas da seção "O que a demanda não diz" serem respondidas.

---

## 1. Contexto de negócio

O financeiro da Somos Agility acompanha os Jobs de Solicitação de Investimento (objeto de aprovação com etapas e status de aprovação) por meio de um Relatório de Jobs, que alimenta um Dashboard no painel de controle financeiro.

Segundo a demanda, o filtro de qualificação desse relatório não está trazendo os status corretamente, e por isso a equipe não consegue fazer o acompanhamento. O pedido chega pelo chamado interno Agility 20260303-055, aberto pelo departamento financeiro. Não há no card nenhum outro detalhe além desse número de chamado.

Referências (somente URLs, não acessadas via org nesta etapa):
- Dashboard: `01ZU4000000TSqXMAW`
- Relatório: `00OU400000XSSudMAH`

## 2. Objetivo

Fazer com que o relatório de Jobs do painel financeiro classifique e exiba cada job pelo status de qualificação correto, de modo que o financeiro consiga acompanhar os jobs pendentes, enviados, aprovados e reprovados sem perder registros.

Objetivo **não** inclui, nesta etapa: alterar o processo de aprovação em si, mudar regra de negócio de quem aprova, ou reprocessar dados históricos. Isso só entra se as respostas das perguntas mudarem o escopo.

## 3. Regra de negócio

Os fatos abaixo vêm do anexo (leitura parcial) e não são regra formal documentada:

- O relatório agrupa os jobs por um campo de "Status de Qualificação" e mostra um gráfico de rosca com essas categorias. Na leitura da imagem, aparecem grupos rotulados como "Não Enviado", "Pendente" e "Aprovado", com contagem total de 281 registros. A legibilidade não permite confirmar os rótulos exatos nem se há mais categorias (ex.: Reprovado).
- Cada job tem um "Histórico de aprovação" com etapas e status próprios (ex.: "Enviado", "Pendente", "Aprovado", "Reprovado"). Nos dois jobs mostrados no anexo, o status da etapa de aprovação está destacado em amarelo, o que sugere que é esse o ponto de atenção da equipe, mas o anexo não diz qual valor deveria aparecer no filtro.

**Hipóteses a validar (não são fatos):**
- H1: o filtro de qualificação não contempla todos os valores de status que existem no processo (por exemplo, valor novo ou valor de etapa que não está na lista selecionada).
- H2: o "Status de Qualificação" lido pelo relatório vem de um campo ou de uma etapa de aprovação diferente do status atual do job, então jobs com histórico em uma etapa aparecem em grupo errado.
- H3: o problema está no Dashboard (filtro do componente) e não no Relatório, ou está nos dois.

Nenhuma das três hipóteses foi confirmada via `sf` CLI. Confirmar objetos, campos e a definição do filtro é pré-requisito do recon (etapa 2).

## 4. Critérios de aceite (Gherkin)

Os critérios abaixo são testáveis sem depender de um valor de mapeamento ainda não definido. Onde o valor esperado depende da resposta à pergunta Q1, está marcado como pendente.

```gherkin
Funcionalidade: Relatório de Jobs classifica por status de qualificação

  Cenário: Nenhum job some do relatório após a correção
    Dado que o relatório `00OU400000XSSudMAH` tem N jobs antes da mudança, medidos em ambiente de dev a partir de uma cópia de referência
    Quando a correção é aplicada na sandbox de QA
    Então o total de jobs exibidos no relatório é igual a N
    E o total do gráfico de rosca é igual ao total de linhas

  Cenário: Job com status de qualificação válido aparece no grupo correto
    Dado um job cujo status de qualificação, segundo a regra validada em Q1, é "<status esperado>"
    Quando o relatório é aberto pelo usuário do financeiro
    Então o job aparece no grupo "<status esperado>"
    E não aparece em nenhum outro grupo
    # <status esperado> pendente de Q1

  Cenário: Todos os valores de status do processo estão no filtro
    Dado a lista completa de valores de status de qualificação validada em Q1
    Quando o filtro de qualificação do relatório é inspecionado
    Então cada valor da lista está selecionado no filtro ou coberto por regra explícita
    E nenhum valor válido está fora do filtro

  Cenário: Dashboard reflete o relatório corrigido
    Dado que o Dashboard `01ZU4000000TSqXMAW` usa o relatório corrigido
    Quando o componente de qualificação é atualizado
    Então a contagem por status do Dashboard é igual à contagem por status do relatório
    E a contagem de cada status é igual à contagem obtida por consulta agregada em QA (sem registros individuais)

  Cenário: Nenhum dado de cliente sai do ambiente de teste
    Dado que a validação é feita em sandbox
    Quando o roteiro de QA é executado
    Então as evidências (prints) não mostram nome, e-mail, CPF, telefone ou valor financeiro de pessoa ou fornecedor
    # regra do guardrail 2; prints precisam ser feitos com dado mascarado ou em registro de teste
```

**Por que alguns critérios estão pendentes:** sem a lista de status e o valor esperado por job (Q1, Q2), não existe critério de "aparece no grupo certo" que possa ser testado de forma honesta. Não vou inventar a tabela de mapeamento.

## 5. O que a demanda não diz (precisa ser respondido antes do design)

As perguntas estão em ordem de prioridade. Q1 a Q4 mudam a arquitetura da solução e bloqueiam o design.

- **Q1 (bloqueante):** Quais são todos os valores válidos de "status de qualificação" que o financeiro considera, e qual grupo cada um deve ocupar no relatório? Hoje não existe essa lista no card.
- **Q2 (bloqueante):** Qual job (ID do registro, sem dado pessoal) está hoje no grupo errado, qual grupo aparece e qual deveria aparecer? Um caso concreto por grupo basta.
- **Q3 (bloqueante):** O "filtro de qualificação" é o filtro do Relatório, o filtro do Dashboard, ou um campo de agrupamento/fórmula do relatório? A correção muda configuração de relatório (declarativo) ou lógica no processo de aprovação e no campo de status (pode exigir Flow ou Apex)?
- **Q4 (bloqueante):** A regra de qualificação é definida por campo, por status de etapa de aprovação ou pelo status do job? Se por etapa, qual etapa vale quando um job passou por várias?
- **Q5:** Desde quando o relatório apresenta o problema? Houve mudança recente no processo de aprovação, nova etapa, novo valor de status, ou mudança no relatório?
- **Q6:** O chamado 20260303-055 é o mesmo problema? A data do chamado (03/03/2026) e a data do comentário (19/10/2026) estão distantes; confirme se o problema continua o mesmo ou se o escopo mudou.
- **Q7:** O painel deve mostrar os 281 registros do relatório ou só os pendentes e enviados? Algum filtro de período ou de responsável deve ser mantido?
- **Q8:** O problema é só no Dashboard, só no Relatório, ou nos dois? Existe outro dashboard ou relatório que usa o mesmo filtro e deveria ser verificado junto?
- **Q9:** Existe prazo ou impacto de fechamento financeiro que determine a ordem de entrega?
- **Q10:** Há alguma correção feita manualmente hoje (ex.: pessoa ajustando status à mão) que precise ser considerada ou desfeita?
- **Q11:** Confirmar que a mudança deve ir apenas para sandbox dev e QA, com aprovação humana antes de qualquer migração. (Produção não é alvo de agente; confirmação só registra o combinado.)

## 6. Premissas a validar

Todas abaixo estão **pendentes**. Não foram confirmadas pelo cliente nem pela org.

- **P1 (pendente):** o problema é de configuração do relatório ou do dashboard, sem mudança de código. Se for mudança em processo de aprovação ou campo calculado, a complexidade sobe.
- **P2 (pendente):** o objeto correto é o de Solicitação de Investimento (nome sugerido pelo cabeçalho do relatório), e o relatório é o do Job de Solicitação de Investimento. Nenhum objeto ou campo foi confirmado via `sf`.
- **P3 (pendente):** não há dado de cliente que precise ser lido via SOQL para entender o problema. A análise de causa deve usar metadata e contagens agregadas.
- **P4 (pendente):** a correção não altera processo de aprovação em produção, e a validação ocorre em sandbox dev e QA.
- **P5 (pendente):** as duas telas de job mostradas no anexo são registros reais de produção; por isso não serão usadas como evidência de teste.

## 7. Limites desta leitura

- O anexo é uma imagem do relatório. Os rótulos de grupo e os números estão em tamanho muito pequeno e não foram confirmados com precisão. Qualquer lista de status daqui é provisória e precisa ser refeita a partir da definição do filtro no org (etapa 2).
- Nomes de pessoas, fornecedores e valores financeiros que aparecem no anexo foram deliberadamente não transcritos para este artefato (guardrail 2).
- Nenhuma consulta foi feita na org. Nenhum objeto, campo ou valor foi confirmado.

## 8. Complexidade

**M (provisória).** Se a causa for só a seleção de valores no filtro do relatório, seria P. Não é possível afirmar isso antes de confirmar a definição do filtro e o campo de qualificação (Q3, Q4). Há risco de a causa estar no processo de aprovação, o que sobe para M ou G.

## 9. Estimativa de esforço

**Estimativa de esforço:** 2–8 h

Premissas que mais pesam na faixa:
- Se a causa for só filtro do relatório/dashboard (P1), fica perto de 2–3 h, incluindo validação em QA e homologação pelo financeiro.
- Se a qualificação depender de campo calculado ou de regra no processo de aprovação, sobe para 6–8 h, com revisão de impacto em outros relatórios.
- A faixa está larga porque a lista de status (Q1) e a causa (Q3, Q4) não foram informadas. O arquiteto refina no design.

---

Análise pronta. Preciso da sua validação antes de acionar o arquiteto.
