# SOMOSAGILITY-7 — Recon da org

**Org:** `sbx-somos-agility-dev` (confirmado `Organization.IsSandbox = true`, Enterprise Edition)
**Data da coleta:** 2026-10-21 (vence em 2026-10-28)
**Método:** `sf sobject describe`, `sf project retrieve start` (CustomObject, Flow, ApprovalProcess,
Workflow, ApexTrigger, ApexClass, LWC) num projeto temporário fora do repositório, `sf data query`
somente sobre metadata (FlowDefinitionView, Flow via Tooling, FieldPermissions, PermissionSet) e
`COUNT()`. Nenhum registro de negócio foi lido.

Entradas: `demanda.md`, `01-analise.md` (aprovada em `gates.md`) e `comentarios-do-card.md`
(respostas P1, P2 e P3 da equipe, 2026-10-21).

---

## 1. Modelo de dados envolvido (confirmado)

### `Lancamento_de_Atividades__c` (label "Lançamento de Atividades")

Um único registro de LAT carrega **até 3 posições de executor** em colunas paralelas (`_1`, `_2`,
`_3`). Não existe objeto filho de "posição": as posições são campos do próprio LAT.

| Campo | Tipo | Papel na demanda |
|---|---|---|
| `Status__c` | Picklist restrita, `trackHistory=true` | **Status Geral** |
| `Status_de_aprovacao_1__c` / `_2__c` / `_3__c` | Picklist restrita | **Status secundários** (um por executor) |
| `Qtd_de_executores__c` | Picklist restrita (`1`, `2`, `3`) | Quantas posições estão em uso |
| `Executor_da_atividade_1__c` / `_2__c` / `_3__c` | Lookup(Contact) | Executor de cada posição |
| `Inicio_da_atividade_N__c` / `Fim_da_atividade_N__c` | DateTime | Horas preenchidas pelo executor N |
| `Perfil_do_executor_N__c` | Fórmula texto | Usada pela auto aprovação do GP |
| `Possui_pendencia_de_aprovacao__c` | Fórmula texto | "Sim" se algum secundário = Pendente - Gerente de projetos |
| `Possui_analistas_pendentes__c`, `Executores_pendentes__c`, `Analista_aguardando_aprovacao__c` | Fórmula texto | Exibição derivada dos secundários |
| `Marcos__c` | Master-detail/lookup para `Marcos__c` (cascade delete) | Marco do projeto |
| `Executor_atividade__c` | Lookup para `Executor_atividade__c` | Legado (modelo de 1 executor) |

**Valores de `Status__c` (Status Geral):** Rascunho (default), Pendente - Preenchimento do(s)
executor(es), Pendente - Gerente de projeto, Aprovado, Rejeitado, Recall, Pendente, Aguardando
Aprovação.

**Valores de `Status_de_aprovacao_N__c` (secundários):** Rascunho (default), Pendente -
Preenchimento do executor, Pendente - Gerente de projetos, Aprovado, Rejeitado, Recall.

> Atenção: os rótulos **não são iguais** entre geral e secundário ("do(s) executor(es)" vs "do
> executor"; "Gerente de projeto" vs "Gerente de projetos"). Qualquer lógica de consolidação tem
> de mapear valor a valor, não copiar texto.

### Objetos relacionados
- `Marcos__c` — pai do LAT; recebe somas de horas (`Realizado_HC_em_atividades__c`,
  `Realizado_HNC_em_atividades__c`, rollups). Não participa do Status Geral.
- `Executor_atividade__c` — filho de `Marcos__c`, lookup no LAT. Não participa do Status Geral.

### Achado de FLS (afeta build e QA)
O usuário autenticado no alias **não tem FLS** em `Status_de_aprovacao_N__c`,
`Qtd_de_executores__c`, `Executor_da_atividade_N__c` e demais campos do modelo de 3 executores:
eles aparecem no retrieve de metadata, mas não no `describe` nem em SOQL ("Invalid field").
FLS desses campos é concedida pelos permission sets `Lancamento_de_atividades_admin` (leitura e
edição), `Lancamento_de_atividades_gerente_de_projetos` e `Lancamento_de_atividades_analista`
(leitura), e pelo perfil "Diretor de Projetos" (leitura).

## 2. Automações no objeto (confirmadas)

### Flows record-triggered em `Lancamento_de_Atividades__c` (FlowDefinitionView)

| API name | Evento | Ativo | Última alteração | Escreve em |
|---|---|---|---|---|
| `Atualiza_o_status_final_de_aprovacao_do_LAT` (v4 ativa) | After save, Update | sim | 2026-06-08 | `Status__c` |
| `Fluxo_de_auto_aprovacao_de_atividades_dos_gerentes_de_projetos` (v5 ativa) | After save, Update | sim | 2026-05-15 | `Status_de_aprovacao_1/2/3__c` |
| `Atualiza_horas_comerciais_e_nao_comerciais_dos_lancamentos_de_atividades` | After save, Update | sim | 2026-04-30 | `Horas_*_da_atividade_N__c` |
| `Subtrai_Horario_de_Almo_o` | After save, Create e Update | sim | 2022-09-20 | `Duracao_da_atividade__c` |
| `Notifica_os_analistas_sobre_a_atividade_e_a_necessidade_de_preenchimento_do_regi` | After save, Create (+5 scheduled paths) | sim | 2026-06-09 | `Flow_e_mail_*`; envia alertas |
| `Dura_o_da_atividade`, `Tipo_Horario_Comercial`, `Tipo_Horario_Inv_lido`, `Tipo_Horario_N_o_Comercial` | After save | **não** | — | — |

**Nenhum** dos flows ativos tem `triggerOrder` definido: a ordem entre eles no mesmo evento é
indeterminada.

### Outros flows que tocam o objeto
- `Notifica_o_1_executor_sobre_o_preenchimento_da_atividade` — Screen Flow ativo. Só roda com
  `Status__c` em Rascunho ou Rejeitado; grava `Status__c = Pendente - Preenchimento do(s)
  executor(es)` e os secundários das posições em uso (1..Qtd) = Pendente - Preenchimento do
  executor, as outras = Rascunho. Dispara o alerta `Alerta_inicial`. É a transição
  Rascunho → Pendente - Preenchimento descrita em P1.
- `Lancamento_de_Atividades_GP` — Process Builder (`processType=Workflow`) **ativo**, critério
  sempre verdadeiro, grava `Gerente_de_Projetos_Contato__c` a cada save (gera um save extra).
- `Somatoria_das_atividades_HC_no_Marco`, `Somatoria_das_atividades_HC_no_Marco_Tipo_Horario`,
  `Somatoria_das_atividades_HNC_no_Marco`, `Somatoria_das_atividades_HNC_no_Marco_Nao_Comercial`,
  `Somatoria_atividades_HC_HNC_no_Marco` — **todos inativos nesta sandbox** (nenhuma versão
  ativa, última alteração em 2019). Escrevem horas em `Marcos__c`, não em `Status__c`.
  Ver divergência D1 abaixo.
- `Atualiza_opp_na_meta` — Draft, não ativo.

### Lógica atual do Status Geral — `Atualiza_o_status_final_de_aprovacao_do_LAT` v4
- Entrada: Update, `Status__c` = Pendente - Preenchimento do(s) executor(es) **OU** Rascunho
  **OU** Pendente - Gerente de projeto. Sem "somente quando mudou".
- Decisão por `Qtd_de_executores__c` (3, 2, 1); para cada caso, um único Update Records no
  `$Record` com filtro "todos os secundários em uso = Aprovado" que grava
  `Status__c = Aprovado`.
- **É a única saída do flow.** Ele nunca grava nenhum outro valor em `Status__c`.

### Approval Processes em `Lancamento_de_Atividades__c`

| API name | Ativo | Entrada | Ao submeter | Aprovação final | Rejeição final |
|---|---|---|---|---|---|
| `Fluxo_de_aprovacao_1_executor` (ordem 1) | sim | Qtd 1/2/3, secundário 1 ∈ {Pendente - Preenchimento do executor, Rejeitado}, horas 1 preenchidas | sec.1 = Pendente - Gerente de projetos; **geral = Pendente - Gerente de projeto** | alerta; sec.1 = Aprovado | alerta; sec.1 = Rejeitado |
| `Fluxo_de_aprovacao_2_executor` (ordem 2) | sim | idem para posição 2 (Qtd 2/3) | sec.2 = Pendente - GP; geral = Pendente - GP | sec.2 = Aprovado | sec.2 = Rejeitado |
| `Fluxo_de_aprovacao_3_executor` (ordem 3) | sim | idem para posição 3 (Qtd 3) | sec.3 = Pendente - GP; geral = Pendente - GP | sec.3 = Aprovado | sec.3 = Rejeitado |
| `Solicitacao_de_aprovacao_para_atividade` | **não** | legado (modelo de 1 executor) | — | — | — |

Os três ativos têm `recordEditability = AdminOnly` (o registro fica travado enquanto há aprovação
pendente — é o "bloqueio" descrito em P1), `allowRecall = false`, um passo com aprovador fixo
(um usuário específico, não citado aqui) e submissão restrita a uma lista de usuários
específicos. **Nem a aprovação final nem a rejeição final tocam em `Status__c`.**

Field updates relevantes (Workflow `Lancamento_de_Atividades__c`): `Status_geral_Pendente_GP`
(geral = Pendente - Gerente de projeto), `Status_e_Etapa_Aprovado_0/1/2`,
`Status_e_Etapa_Rejeitado_0/1/2`, `Status_e_etapa_Pendente_GP_0/1/2`. As 5 workflow rules do
objeto estão inativas.

### Validation rules ativas
`Checa_a_edicao_dos_campos_previstos`, `Checa_preenchimento_unitario_do_executor` (no máximo 1
posição com horas e não aprovada, exceto perfis Administração e Gerente de Projetos),
`Checa_se_hora_fim_maior_que_hora_inicio`, `Executor_1/2/3_deve_preencher_a_propria_hora`
(trava horas de posição aprovada), `Executor_n_pode_preencher_mais_de_lanc`,
`Impede_o_GP_de_editar_horas_de_analistas`. Inativas: `M01_*`, `M02_*`, `M03_*`,
`NaoPreencheAtividadeMarcoFinalizado`. Nenhuma referencia `Status__c`.

### Código
- **Nenhum** Apex trigger em `Lancamento_de_Atividades__c`, `Marcos__c` ou `Executor_atividade__c`.
- **Nenhuma** classe Apex (190 retrievadas) nem LWC referencia o objeto ou os campos de status.

## 3. Diagnóstico — por que o Status Geral não acompanha os secundários

Juntando P1 (regra de negócio) com o que está na org:

| Transição esperada (P1) | Quem faz hoje | Situação |
|---|---|---|
| Rascunho → Pendente - Preenchimento | Screen Flow `Notifica_o_1_executor_...` | OK |
| Executor envia → Pendente - Gerente de projeto | Approval process (submissão) | OK |
| GP aprova um executor e **ainda há executor pendente** → volta para Pendente - Preenchimento | **ninguém** | **Falha: geral fica preso em Pendente - Gerente de projeto** |
| GP aprova o último executor → Aprovado | Flow `Atualiza_o_status_final_...` v4 | Implementado (depende de o flow rodar após o field update do approval — a confirmar em teste) |
| GP rejeita um executor → ? | **ninguém** | Geral fica em Pendente - Gerente de projeto. Regra não informada |

Causa raiz mais provável: o flow v4 só implementa o caso "todos aprovados". Não há automação ativa
que recalcule o geral em aprovação parcial ou rejeição. Isso bate com o relato ("Status geral não
está sendo atualizado de acordo com os status secundários") e com a regra P1 ("o status geral
voltará para Pendente - Preenchimento do(s) executor(es) para que o próximo executor faça o
lançamento").

## 4. Volume

| Objeto | `COUNT()` visível ao usuário do alias |
|---|---|
| `Lancamento_de_Atividades__c` | 0 |
| `Marcos__c` | 0 |
| `Executor_atividade__c` | 0 |
| `PPM_Project__c` | 0 |

A sandbox de dev não tem dados do processo LAT. A reprodução vai exigir massa de teste criada do
zero (Projeto → Marco → LAT com contatos executores), com um usuário que tenha o permission set
`Lancamento_de_atividades_admin` e esteja entre os submissores/aprovador dos approval processes.

## 5. Permissões
- Objeto/campos: `Lancamento_de_atividades_admin`, `Lancamento_de_atividades_gerente_de_projetos`,
  `Lancamento_de_atividades_analista` + perfis com leitura em `Status__c` (dezenas; só
  `adminPMO` e o permission set de admin editam `Status__c`).
- Flows record-triggered rodam em contexto de sistema: a correção não depende de FLS do usuário
  final para gravar `Status__c`.

## 6. Divergências e incertezas

- **D1 — "Somatória" inativa.** P3 cita flows de somatória de HC/HNC no Marco como parte do
  cálculo. Nesta sandbox eles estão **inativos desde 2019**, e quando existiam escreviam em
  `Marcos__c`, não em `Status__c`. Ou a sandbox não reflete produção, ou a resposta P3 descreve o
  processo como um todo (horas + status). Não conferido em produção (proibido ao agente).
- **D2 — Paridade dev x produção não verificada.** A versão ativa do flow de status (v4,
  2026-06-08) e da auto aprovação (v5, 2026-05-15) são recentes nesta sandbox; não há como o
  agente confirmar que são as mesmas de produção.
- **D3 — Disparo do flow pelo field update do approval.** O caminho "último executor aprovado →
  Aprovado" assume que o record-triggered flow roda quando o approval process grava o
  secundário. Esperado pela plataforma, mas não reproduzido (sandbox sem dados).
