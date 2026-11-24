# SOMOSAGILITY-18 — Design (sustentação, enxuto)

Soma de HNC indevida no marco "Execução - Fase de entrega" do PRJ 1384 (`Marcos__c`
`a0zU400000ASbVAIA1`). Recon de 2026-10-21 em `sbx-somos-agility-dev`: ver `02-recon.md`.
Toda metadata citada aqui foi confirmada nessa org.

## 1. Situação em uma frase

O recon mostrou **como** o HNC é calculado, mas **não mostra por que este marco está errado**.
A sandbox de dev não tem nenhum marco nem lançamento, e o registro do chamado só existe em
produção, onde o agente não entra. Há quatro causas plausíveis pela metadata (H1–H4), cada uma
com uma correção diferente. **Este design não escolhe uma causa sem evidência.** Ele define o
diagnóstico que falta, já deixa decidida a correção de cada hipótese e trava o build até a
causa ser confirmada.

## 2. Como o HNC é calculado hoje (confirmado)

1. Flow `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` (After Save,
   Update, em `Lancamento_de_Atividades__c`) chama o Apex invocável `BusinessHoursFlowHelper`
   para cada um dos 3 executores e grava `Horas_nao_comerciais_da_atividade_1/2/3__c`.
2. O Apex calcula `HNC = tempo corrido (fim − início) − BusinessHours.diff(...)` sobre o
   BusinessHours "Padrão 5 x 8" (dias úteis, 09h–18h, America/Sao_Paulo).
3. A fórmula `Horas_nao_comerciais_totais_da_atividade__c` soma os executores, excluindo 2 e 3
   quando `Shadow_2__c`/`Shadow_3__c`.
4. O roll-up `Marcos__c.RealizadoHNCAtividades__c` soma essa fórmula dos lançamentos com
   `Status__c = Aprovado`.

## 3. Hipóteses de causa e o que confirma cada uma

| # | Hipótese | Evidência na metadata | Sinal no registro (produção) |
|---|---|---|---|
| **H1** | Lançamento que atravessa noite, fim de semana ou feriado conta **todo** o tempo fora do expediente como HNC | Fórmula do Apex; nenhuma validação ativa limita duração; a validação antiga (10h, 8h–18h) `M02_Lancamento_hora_comercial` está inativa | Lançamento aprovado do marco com início e fim em dias diferentes, ou HNC desproporcional à atividade |
| **H2** | Executor 1 marcado como shadow entra no HNC debitável | `Shadow_1__c` não é referenciado em nenhuma fórmula | Lançamento do marco com o 1º "Shadow?" marcado |
| **H3** | Horas residuais dos executores 2/3 depois de reduzir a quantidade de executores | O Flow calcula os 3 pares sem olhar `Qtd_de_executores__c` | Lançamento com "Qtd. de executores" menor que o nº de pares início/fim preenchidos |
| **H4** | O cliente está lendo outro número: campo legado com o mesmo rótulo, ou fórmula que pesa HNC em dobro | `Realizado_HNC_em_atividades__c` (Number, sem Flow ativo que o atualize) tem o mesmo rótulo de `RealizadoHNCAtividades__c`; `Previsto_HC_HNC__c` e `Resultado_HC_HNC__c` usam `HNC*2` | Resposta à pergunta 1 da análise: qual campo da tela está errado e qual valor era o esperado |

**Diagnóstico (pré-requisito do build, feito por humano com acesso à produção, sem o agente):**
o consultor abre o marco `a0zU400000ASbVAIA1`, olha a related list de Lançamentos de Atividades
aprovados e responde as quatro perguntas da coluna "Sinal no registro". Não precisa exportar
nem colar dado: a resposta é sim/não por hipótese, mais o nome do campo que o cliente
considera errado. Se nenhuma hipótese bater, o design volta para revisão.

## 4. Decisão por hipótese

Ordem de preferência: configuração → Flow → código. Nenhuma das opções muda modelo de dados.

| Causa | Nível | Componente | O que muda | Por que não o nível acima |
|---|---|---|---|---|
| H2 | **Configuração** (fórmula) | `Lancamento_de_Atividades__c.Horas_nao_comerciais_totais_da_atividade__c` e `Horas_nao_comerciais_totais_shadow__c` (e as duas equivalentes de HC, `Horas_comerciais_totais_da_atividade__c` e `Horas_comerciais_totais_shadow__c`, para manter consistência) | Levar `Shadow_1__c` em conta igual a `Shadow_2/3__c` | É o nível mais alto possível. O roll-up recalcula a partir da fórmula, então não há regravação de lançamentos (verificar em QA) |
| H3 | **Flow** (nova versão do Flow existente) | `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` | Executor N só é calculado se `Qtd_de_executores__c >= N`. Se não, grava 0 | Uma fórmula sozinha poderia esconder o resíduo, mas o certo é não gravar valor inválido. O Flow já existe e já é o dono desses campos |
| H1 | **Código** (Apex já existente) + opcionalmente **configuração** (validação) | `BusinessHoursFlowHelper` (+ `BusinessHoursFlowHelperTest`); opcional: nova validation rule no lançamento | A regra de quanto da madrugada/fim de semana conta como HNC tem que vir do cliente (pergunta 2). Se a regra for "lançamento não pode passar de X h / atravessar o dia", basta uma validation rule (configuração) que impede novos casos | Business hours só se calcula em Apex (`BusinessHours.diff`); Flow não tem essa função. A lógica já está em código; mudar a regra é mudar a classe. Validação sozinha evita casos novos mas não corrige os já aprovados |
| H4 | **Nenhum build** | — | Explicar ao cliente qual campo é o realizado vivo. Renomear o rótulo do campo legado seria configuração, mas **não** está no escopo sem pedido | Não há defeito de cálculo a corrigir |

**Correção de dados existentes (P4):** em H1 e H3 os lançamentos já aprovados têm o HNC
errado **gravado** nos campos Number; corrigir o Flow/Apex não muda o passado, e as validações
`Executor_1/2/3_deve_preencher_a_propria_hora` impedem editar início/fim de lançamento aprovado.
Recalcular o histórico é carga de dados em produção: **fora do alcance do agente (guardrail #1)
e muda o escopo da demanda** (a análise já previa isso em P4). Se a causa for H1 ou H3, esse
ponto volta ao humano antes do build: corrigir só daqui para frente, ou planejar uma carga de
correção feita pelo time do cliente.

## 5. Conflito de automação

**`Lancamento_de_Atividades__c` tem quatro Flows After Save ativos no evento Update
(`Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades`,
`Atualiza_o_status_final_de_aprovacao_do_LAT`,
`Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos`, `Subtrai_Horario_de_Almo_o`)
mais o Process Builder `Lancamento_de_Atividades_GP`. O Flow de horas não tem condição "só
quando mudou" e faz update no próprio registro, o que reexecuta os demais after-save. Nenhum
outro escreve em campo de HNC, mas a aprovação (`Status__c = Aprovado`) é o filtro do roll-up.
Se a correção for H3 (Flow), não alterar a ordem nem a entrada dos outros Flows, e o teste de
QA tem que cobrir edição seguida de aprovação no mesmo lançamento.**

Sem Apex trigger em `Lancamento_de_Atividades__c` nem em `Marcos__c`.

## 6. Limites de governador e escala

- `BusinessHoursFlowHelper` é bulk-safe (loop sem SOQL/DML; `BusinessHours.diff` não consome
  SOQL). Mantém assim em qualquer mudança de H1.
- O Flow de horas faz um update no próprio registro por transação (after-save): é aceitável, e
  H3 não acrescenta elemento de dados.
- Mudança de fórmula referenciada por roll-up (H2) dispara recálculo em massa dos roll-ups dos
  marcos: assíncrono, mas em produção pode levar tempo dependendo do volume (desconhecido).
  Combinar a janela de deploy com o cliente.

## 7. Permissões

Nenhum campo novo, nenhuma mudança de FLS, perfil ou permission set em H2/H3/H1. Se H1 virar
validation rule, ela vale para todos os perfis. Conferir se o perfil "Administração" deve ficar
de fora, como era na versão antiga comentada em `M02_Lancamento_hora_comercial`.

## 8. Riscos

| Risco | Severidade |
|---|---|
| Corrigir a hipótese errada: o build muda o cálculo de todos os marcos e o do PRJ 1384 continua errado | **Alta**, mitigado pelo diagnóstico da seção 3 antes do build |
| Metadata de produção diferente da de dev (o recon só viu dev) | **Alta**. Antes do build, confirmar em QA ou produção (humano) que o Flow, a classe e as fórmulas citadas são as mesmas |
| Valores já usados em fechamento/faturamento mudam ao recalcular (H2 recalcula todo o histórico automaticamente) | **Alta** se a pergunta 7 for "sim". H2 não tem como recalcular só daqui para frente |
| Correção de dados históricos (H1/H3) exigida pelo cliente | Média (muda o escopo, ver seção 4) |
| Recálculo em massa de roll-up no deploy (H2) | Média |
| Reentrada/ordem entre os after-save do lançamento (H3) | Média |
| Sem dados em dev, QA depende de massa de teste criada à mão | Baixa |

## 9. Perguntas da análise que ainda estão abertas

Nenhuma das 10 perguntas da seção 5 de `01-analise.md` foi respondida (os comentários do card
só trazem o número do chamado e aprovações). O recon respondeu **em parte** só a pergunta 8.

| # | Pergunta | Situação | Bloqueia |
|---|---|---|---|
| 1 | Valor esperado / qual campo está errado | Aberta | **Build** (separa H4 das outras) |
| 2 | Quais horas entram (definição de HNC) | Aberta | **Build se for H1** |
| 3 | O que infla o valor | Aberta (o diagnóstico da seção 3 responde) | **Build** |
| 4 | Desde quando | Aberta. Indício: Flow, Apex e desativação das validações antigas têm data 2026-04-30 em dev, antes do chamado de 2026-09-11 (data de dev, não confirmada para produção) | Não |
| 5 | Afeta outros marcos | Aberta. Pela metadata, H1–H3 afetariam qualquer marco nas mesmas condições | Não (afeta comunicação) |
| 6 | Quem consome o valor | Aberta | Não |
| 7 | Valor já usado em fechamento | Aberta | **Build se for H2** (recálculo retroativo automático) |
| 8 | Como é recalculado | **Respondida pelo recon** (seção 2) | — |
| 9 | Quem valida e prazo | Aberta | Homologação |
| 10 | Número de referência | Aberta | Homologação |

## 10. O que NÃO será feito

- Nenhuma carga ou correção de dados em produção (nem em lançamentos históricos).
- Nenhuma mudança de modelo de dados (campo, objeto, relacionamento). Se a resposta do cliente
  exigir, escala ao arquiteto sênior.
- Não mexer nos Flows de aprovação, notificação ou almoço, nem no Process Builder.
- Não reativar os Flows `Somatoria_das_atividades_*` nem remover o campo legado
  `Realizado_HNC_em_atividades__c` (ele ainda é lido por `HNC_previsto_X_realizado__c`).
- Não alterar os pesos `*2` das fórmulas de previsto/resultado sem pedido explícito.
- Não mudar o BusinessHours "Padrão 5 x 8" nem os feriados.

## 11. Estimativa

**Estimativa de esforço:** 5–12 h

O que mudou em relação à análise (6–14 h) e por quê:
- Recon e localização do cálculo já feitos: saem 4–6 h de "descobrir onde calcula" e fica ~1 h
  de diagnóstico humano no registro em produção (seção 3).
- Ponta baixa (H2 ou H4): ajuste de 2–4 fórmulas ou só explicação, mais teste de não regressão
  em QA com massa criada à mão: ~5 h.
- Ponta alta (H1): mudança em `BusinessHoursFlowHelper` + teste Apex (cobertura ≥ 85%),
  validação opcional e homologação com o cliente sobre a regra nova: ~12 h.
- Fora da faixa: qualquer correção de dados históricos (seção 4). Se o cliente pedir, a
  estimativa volta a ser feita.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
