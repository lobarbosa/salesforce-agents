# SOMOSAGILITY-18 — Recon da org

- **Data da coleta:** 2026-10-21 (vence em 2026-10-28)
- **Org:** `sbx-somos-agility-dev` (sandbox, `IsSandbox = true`, Org ID `00DHa0000070wxfMAA`, API 68.0)
- **Método:** `sf sobject describe`, `sf project retrieve start` (CustomObject, Flow, Workflow,
  ApexClass) e queries de Tooling API (FlowDefinitionView, FlowDefinition, ValidationRule,
  CustomField, MetadataComponentDependency). Dados: só `COUNT()`. Nenhum registro de cliente
  foi lido.

## 0. Limite deste recon (ler primeiro)

- **A sandbox de dev não tem dados**: `SELECT COUNT() FROM Marcos__c` = 0,
  `SELECT COUNT() FROM Lancamento_de_Atividades__c` = 0. O registro do chamado
  (`a0zU400000ASbVAIA1`) **não existe** em dev (`COUNT()` = 0). Ele vive na produção do cliente,
  onde o agente não entra (guardrail #1).
- Consequência: **não foi possível reproduzir o erro nem ver quais lançamentos compõem o total
  do marco**. Tudo abaixo é metadata confirmada; a causa raiz é hipótese ranqueada, não
  diagnóstico.
- Também não foi confirmado que a metadata de dev é idêntica à de produção. As datas de
  modificação abaixo são as de dev (podem refletir a data de deploy/refresh, não a de produção).

## 1. Objetos e relacionamentos (confirmados)

| Objeto | Rótulo | Papel |
|---|---|---|
| `Marcos__c` | Marco | Pai. Lookup `ID_do_Projeto__c` → `PPM_Project__c` (Projeto Agility) |
| `Lancamento_de_Atividades__c` | Lançamento de Atividades | Filho, **Master-Detail** `Marcos__c` → `Marcos__c` (relationship `Lancamento_de_Atividades__r`) |
| `Atividade_financeira_do_marco__c` | — | Filho de `Marcos__c` (rollups de HC e horas extras, **não** de HNC) |
| `Executor_atividade__c`, `Status_do_Marco__c`, `Lancamento_de_Creditos_no_Marco__c` | — | Outros filhos de `Marcos__c`, sem relação encontrada com HNC |

## 2. Cadeia de cálculo de HNC (confirmada)

```
Lancamento_de_Atividades__c (Inicio/Fim_da_atividade_1..3__c, um par por executor)
  │  Flow Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades
  │    (record-triggered, After Save, só Update, v1 Active)
  │    → Apex invocável BusinessHoursFlowHelper (BusinessHours "Padrão 5 x 8")
  ▼
Horas_nao_comerciais_da_atividade_1/2/3__c   (Number, gravado pelo Flow)
  ▼  fórmula
Horas_nao_comerciais_totais_da_atividade__c  (exclui exec. 2/3 se Shadow_2/3__c = true)
Horas_nao_comerciais_totais_shadow__c        (soma só exec. 2/3 marcados como shadow)
  ▼  roll-up SUM, filtro Status__c = "Aprovado"
Marcos__c.RealizadoHNCAtividades__c          ("Realizado HNC em atividades")
Marcos__c.Realizado_HNC_em_atividades_shadow__c
  ▼  fórmulas
Realizado_HC_HNC_debitaveis__c  = RealizadoHCAtividades__c + RealizadoHNCAtividades__c
Realizado_HC_HNC_total_geral__c = debitáveis + shadow HC + shadow HNC
Realizado_HC_HNC_shadow__c      = shadow HC + shadow HNC
```

**P1 confirmada em dev**: o HNC do marco é calculado dentro da org (Flow + Apex + fórmula +
roll-up). Não foi encontrada integração escrevendo nesses campos.
**P3 confirmada em dev**: `Marcos__c` existe. O "campo de HNC" mais provável é
`RealizadoHNCAtividades__c`, que está no layout "Layout de Marcos". A demanda não diz qual
campo o cliente lê; ver ambiguidade em 2.3.

### 2.1 Flow `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades`
- Objeto `Lancamento_de_Atividades__c`, `RecordAfterSave`, `recordTriggerType = Update`
  (não roda no Create). Uma versão só (v1, Active, modificada em 2026-04-30 em dev).
- Filtro de entrada: `(Inicio_1 e Fim_1 preenchidos) OU (par 2) OU (par 3)`. **Sem** "só quando
  mudou": roda em toda edição que atende ao filtro.
- Para cada executor com início e fim, chama `BusinessHoursFlowHelper` com BusinessHours
  `01m50000000H2KIAA0` e grava `Horas_comerciais_da_atividade_N__c` e
  `Horas_nao_comerciais_da_atividade_N__c` no próprio `$Record` (update no próprio registro em
  after-save, o que reexecuta os demais after-save do objeto).
- **Não lê** `Qtd_de_executores__c`, `Shadow_N__c` nem `pausaAlmoco__c`.

### 2.2 Apex `BusinessHoursFlowHelper` (+ `BusinessHoursFlowHelperTest`, API 65/66, 2026-04-30 em dev)
Lógica confirmada:
```
businessHours    = BusinessHours.diff(id, start, end) / 1h
totalHours       = (end - start) / 1h          // tempo corrido de relógio
nonBusinessHours = totalHours - businessHours
```
BusinessHours `01m50000000H2KIAA0`: nome "Padrão 5 x 8", ativo, fuso `America/Sao_Paulo`,
segunda 09:00–18:00, sábado e domingo sem expediente. A org tem 9 `Holiday` cadastrados; **não
confirmado** se estão associados a esse BusinessHours.

Implicação direta do código: **todo tempo corrido fora de 09h–18h em dia útil vira HNC**. Um
lançamento que começa num dia e termina no outro (ou na semana seguinte) conta a noite, o fim de
semana e o feriado inteiros como hora não comercial.

### 2.3 Campos em `Marcos__c` relacionados a HNC (confirmados)

| API name | Tipo | Definição |
|---|---|---|
| `RealizadoHNCAtividades__c` | Roll-up SUM | `Lancamento_de_Atividades__c.Horas_nao_comerciais_totais_da_atividade__c`, filtro `Status__c = Aprovado` |
| `Realizado_HNC_em_atividades_shadow__c` | Roll-up SUM | `...Horas_nao_comerciais_totais_shadow__c`, filtro `Status__c = Aprovado` |
| `Realizado_HNC_em_atividades__c` | Number (legado) | **Mesmo rótulo** "Realizado HNC em atividades" do roll-up acima. Era alimentado pelos Flows `Somatoria_das_atividades_HNC_no_Marco*`, hoje **todos sem versão ativa**. Usado por `HNC_previsto_X_realizado__c` |
| `Previsto_HNC_no_Marco__c` | Number | — |
| `HNC_previsto_X_realizado__c` | Fórmula | `Previsto_HNC_no_Marco__c - Realizado_HNC_em_atividades__c` (lê o campo **legado**) |
| `Previsto_HC_HNC__c` | Fórmula | `Previsto_HC_no_Marco__c + (Previsto_HNC_no_Marco__c*2)` |
| `Resultado_HC_HNC__c` | Fórmula | `HC_previsto_X_realizado__c + (HNC_previsto_X_realizado__c*2)` |
| `Realizado_HC_HNC_debitaveis__c`, `Realizado_HC_HNC_total_geral__c`, `Realizado_HC_HNC_shadow__c` | Fórmula | ver seção 2 |

Ambiguidade real na tela: existem **dois campos com o mesmo rótulo** "Realizado HNC em
atividades" (um roll-up vivo, um Number legado congelado), e algumas fórmulas multiplicam HNC
por 2. Sem saber qual número o cliente lê, não dá para afirmar qual está "errado".

### 2.4 Fórmula `Horas_nao_comerciais_totais_da_atividade__c` (confirmada)
```
IF(ISBLANK(HNC_1), 0,
   HNC_1 + IF(Shadow_2__c == false, HNC_2, 0) + IF(Shadow_3__c == false, HNC_3, 0))
BlankAsZero
```
- **`Shadow_1__c` existe mas não é referenciado por nenhuma fórmula** (MetadataComponentDependency
  não retorna nenhum uso). Se o executor 1 for shadow, as horas dele entram no total debitável.
- Se `HNC_1` estiver vazio, o total é 0 mesmo com HNC nos executores 2/3 (subcontagem, não
  sobrecontagem).
- `Horas_comerciais_totais_da_atividade__c` tem a mesma estrutura (mesmos dois pontos).

## 3. Automação no mesmo objeto/evento

`Lancamento_de_Atividades__c` — **ativos**, sem Apex trigger (query em `ApexTrigger` = 0):

| Componente | Tipo | Evento | Campos que escreve |
|---|---|---|---|
| `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` | Flow | After Save, Update | HC/HNC 1..3 |
| `Atualiza_o_status_final_de_aprovacao_do_LAT` | Flow | After Save, Update | `Status__c`, `Status_de_aprovacao_1..3__c` |
| `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` | Flow | After Save, Update | `Status_de_aprovacao_1..3__c` |
| `Subtrai_Horario_de_Almo_o` | Flow | After Save, Create/Update | `Duracao_da_atividade__c` |
| `Notifica_os_analistas_sobre_a_atividade_e_a_necessidade_de_preenchimento_do_regi` | Flow | After Save, Create | e-mails de executor/GP (campos Flow_*) |
| `Lancamento_de_Atividades_GP` | Process Builder | — | `Gerente_de_Projetos_Contato__c` |

Workflow rules do objeto: as 5 regras estão **inativas**. Flows inativos no objeto:
`Dura_o_da_atividade`, `Tipo_Horario_Comercial`, `Tipo_Horario_Inv_lido`,
`Tipo_Horario_N_o_Comercial`.

Nenhum dos Flows escreve em campo de HNC além do primeiro. Mas **quatro after-save no mesmo
objeto e evento, nenhum com "só quando mudou" no Flow de horas, e o Flow de horas faz update no
próprio registro**: risco de ordem de execução e de reentrada.

`Marcos__c` — Flows ativos `Altera_Layout_do_Marco_Financeiro`, `Atualiza_o_record_type_ID_dos_marcos_financeiros`,
`Condicoes_de_Pagamento` (nenhum toca HNC); sem workflow rule; sem Apex trigger.

## 4. Validation rules em `Lancamento_de_Atividades__c`

Ativas: `Checa_a_edicao_dos_campos_previstos`, `Checa_preenchimento_unitario_do_executor`,
`Checa_se_hora_fim_maior_que_hora_inicio`, `Executor_1/2/3_deve_preencher_a_propria_hora`
(bloqueiam alterar início/fim de executor já aprovado), `Executor_n_pode_preencher_mais_de_lanc`,
`Impede_o_GP_de_editar_horas_de_analistas`.

Inativas (2026-04-30 em dev): `M01_Hora_inicial_maior_que_final`, `M02_Lancamento_hora_comercial`
(o texto comentado da versão antiga limitava lançamento a 10h e à janela 8h–18h),
`M03_ValidaExecutorAtividade`. Inativa em 2026-06-24: `NaoPreencheAtividadeMarcoFinalizado`.

**Nenhuma regra ativa limita a duração de um lançamento** nem impede que início e fim caiam em
dias diferentes.

## 5. Indícios de causa (hipóteses, não confirmadas — sem dado em dev)

| # | Hipótese | Evidência na metadata | Como confirmar |
|---|---|---|---|
| H1 | Lançamento atravessando noite/fim de semana/feriado conta todo o tempo corrido fora do expediente como HNC | `nonBusinessHours = total − business` no Apex; nenhuma validação limita duração; validação antiga de 10h/8h–18h está inativa | Olhar os lançamentos aprovados do marco em produção: algum com início e fim em dias diferentes? |
| H2 | Executor 1 marcado como shadow entra no HNC debitável | `Shadow_1__c` não é usado em nenhuma fórmula | Algum lançamento do marco com `Shadow_1__c = true`? |
| H3 | Horas residuais do executor 2/3 (Qtd reduzida depois de preenchido) | Flow calcula os 3 pares sem olhar `Qtd_de_executores__c` | Algum lançamento com `Qtd_de_executores__c` menor que o nº de pares preenchidos? |
| H4 | O cliente lê um campo que pesa HNC em dobro ou o campo legado | `*2` em `Previsto_HC_HNC__c` e `Resultado_HC_HNC__c`; dois campos com o mesmo rótulo | Perguntar qual número/campo da tela está errado (pergunta 1 da análise) |

Duplicidade (pergunta 3 da análise) não pode ser medida em dev (0 registros).

## 6. Premissas da análise depois do recon

| Premissa | Status |
|---|---|
| P1 — cálculo dentro da org | **Confirmada** (em dev) |
| P2 — restrito ao PRJ 1384 | **Não verificável em dev** (0 marcos). Pela metadata, H1–H3 afetariam qualquer marco com lançamento nas mesmas condições |
| P3 — objeto/campo existem | **Confirmada** para `Marcos__c` e campos acima; qual campo o cliente lê ainda é dúvida |
| P4 — correção sem alterar apontamentos | **Depende da causa**: H2 (fórmula) recalcula sozinho; H1/H3 exigem regravar lançamentos existentes |
| P5 — sem correção retroativa | **Não verificável** (pergunta 7) |

## 7. Volume
Dev: 0 marcos, 0 lançamentos. Volume de produção desconhecido; o agente não acessa produção.
