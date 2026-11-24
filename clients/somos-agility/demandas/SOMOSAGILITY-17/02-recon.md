# Recon da org — SOMOSAGILITY-17

- **Data da coleta:** 2026-10-30
- **Org:** `sbx-somos-agility-dev` (Org ID `00DHa0000070wxfMAA`, API v68.0, `Organization.IsSandbox = true`)
- **Método:** `sf sobject describe`, `sf org list metadata`, `sf project retrieve start` para
  `/tmp/recon` (nada foi trazido para `force-app/`), Tooling API e `SELECT COUNT()`. Nenhuma
  query retornou registro de negócio. Usuários foram identificados só por `COUNT()` com filtro
  de primeiro nome/papel; nenhum username ou e-mail aparece aqui.

## 1. O que é o "JOB de investimento"

| Item | Confirmado |
|---|---|
| Objeto | `JOB_de_Solicita_o_de_Investimento__c` (label "JOB de Solicitação de Investimento"), custom |
| Record types | só `Mestre` |
| Campo de status da aprovação | `Status_da_Qualificaco__c` (picklist: Não Enviado, Pendente, Aprovado, Rejeitado, Recall) |
| OWD | `sharingModel = ReadWrite` (interno e externo): todo usuário com permissão de objeto vê o registro |
| Volume na dev | `SELECT COUNT()` = **0** registros; `ProcessInstance` do objeto = 0 |

Objetos parecidos que **não** são o alvo: `JOB_de_Solicitacao_de_Treinamentos__c`,
`Previsao_de_Gastos_Job_Investimentos__c`, `Previsao_de_Gasto_Investimento_Realizado__c`
(este último é o "PGR" relacionado, citado na SOMOSAGILITY-5).

## 2. Mecanismo de aprovação atual — Approval Process nativo

6 Approval Processes no objeto (de 245 na org). **2 ativos:**

| API name | Ativo | processOrder | Para quem |
|---|---|---|---|
| `Aprova_o_JOB` | sim | 1 | criador = um usuário individual específico (1 passo, 1 aprovador) |
| `JOB_de_solicitacoes_de_investimento` (label "JOB de solicitações de investimentos", descrição "v1.3.1") | sim | 2 | lista de 17 criadores (usuários individuais e usuários de grupo), **inclui `Grupo Cyber Salesforce`** |
| `JOB_de_solicitacoes_de_investimentos` | não | 2 | versão anterior |
| `JOBSolicitacaoInvestimento`, `_v1_1`, `_v1_2` | não | 1 | versões anteriores |

O padrão de versionamento (clonar → ativar a nova → desativar a antiga) já é usado nesta org.

### `JOB_de_solicitacoes_de_investimento` (o que o Cyber usa hoje)

- Entrada: `(CreatedBy em lista de 17 usuários) AND Status_da_Qualificaco__c != Aprovado`
- Submissor permitido: `owner`. `recordEditability = AdminOrCurrentApprover`, sem recall,
  sem delegação, `finalApprovalRecordLock = false`.
- Ações: inicial `Status_Qualificacao` (→ Pendente); aprovação final `Aprova_o_de_JOB` (alerta)
  + `Status_Qualificacao_Aprovacao` (→ Aprovado); rejeição final `Rejei_o_de_JOB` (alerta) +
  `Status_Qualificacao_Rejeicao` (→ Rejeitado); recall `Status_Qualificacao_Recall`.
- Template: `Job_de_Investimentos/Solicita_o_de_JOB_de_Investimento`.

| # | Passo (API name) | Critério do passo | Aprovador | Se rejeitar |
|---|---|---|---|---|
| 1 | `Pendente_Diretor_a_Pos_vendas` | CreatedBy em 6 usuários (inclui `Grupo Cyber Salesforce`) — senão pula | usuário Diretor(a) Pós-vendas (não é Gustavo/Wanderley/Walmor) | padrão do 1º passo = rejeição final |
| 2 | `Pendente_Diretor_a_Comercial` | CreatedBy em 3 usuários de grupo — senão pula | usuário Diretor(a) Comercial | rejeição final |
| 3 | `Pendente_Diretor_a_Financeiro` | `CreatedBy != (vazio)` — sempre verdadeiro | **Walmor** (papel `Diretor_Financeiro`) | rejeição final |
| 4 | `Pendente_CEO` | CreatedBy em 3 usuários de grupo — último passo | usuário CEO | rejeição final |

**Caminho atual de um JOB criado pelo Cyber:** Diretor(a) Pós-vendas → (Comercial pulado) →
Walmor → (CEO não se aplica; último passo sem critério atendido aprova) → Aprovado.
**Caminho pedido:** Gustavo → Wanderley → Walmor. Diferença: o 1º aprovador muda e entra um
passo intermediário (Wanderley).

## 3. Usuários citados na demanda

| Na demanda | Na org | Ativo | Papel (UserRole) |
|---|---|---|---|
| Cyber | usuário `Grupo Cyber Salesforce` (User, tipo Standard, perfil `PO EA`) — único User com "Cyber" no nome; **não** existe Group/Queue com "Cyber" | sim | `Coordenador_de_Suporte_DC_C_SEG_MS` |
| Gustavo | usuário individual (1 ativo com esse primeiro nome; é o mesmo que já aparece como criador nos critérios do passo 1) | sim | `Coordenador_de_Suporte_DC_C_SEG_MS` (mesmo papel do usuário Cyber) |
| Wanderley | usuário individual (1 ativo com esse primeiro nome; aparece como criador na entrada do processo) | sim | `Coordenador_SA` |
| Walmor | usuário individual (1 ativo) — **já é o aprovador do passo 3** do processo atual | sim | `Diretor_Financeiro` |

Os três aprovadores têm leitura no objeto via permission set/perfil atribuído (2 concessões de
Read cada); o usuário Cyber tem Create (1 concessão). Com OWD ReadWrite, não há bloqueio de
visibilidade para aprovar.

## 4. Outras automações no objeto

| Tipo | Componente | Estado | Relação com a demanda |
|---|---|---|---|
| Flow before-save (create/update) | `Status_Previs_o_de_Gastos_JOB` | ativo | grava `Status_Previs_o_de_Gastos__c`; campo diferente do da aprovação |
| Workflow Rule | "Status Previsão de Gastos JOB" | **inativa** | — |
| Field updates (workflow) | `Status_Qualificacao`, `_Aprovacao`, `_Rejeicao`, `_Recall`, `Status_Previs_o_de_Gastos_JOB` | existem | os 4 primeiros são reaproveitados pela aprovação |
| Email alerts | `Aprova_o_de_JOB`, `Rejei_o_de_JOB`, `Solicitaco_de_Mapeamento_Pendente` | existem | reaproveitáveis |
| Apex trigger | nenhum | — | — |
| Apex class referenciando o objeto | nenhuma (`MetadataComponentDependency`) | — | sem submissão automática por código |
| Validation rules | `Checa_o_Preenchimento_dos_Campos_CEO`, `Classificacao_Gerencial`, `_2`..`_5`, `Formato_CNPJ` | ativas | validam preenchimento; não olham status de aprovação nem criador |

Dependências do objeto (`MetadataComponentDependency`): 5 email templates, WebLink `Voltar`,
Flow `Status_Previs_o_de_Gastos_JOB`. Nada mais.

## 5. Incertezas que o recon não resolve

- Se há aprovações **pendentes** de JOBs do Cyber em produção (dev tem 0 registros; o agente
  não consulta produção).
- Comportamento esperado em rejeição (dúvida 5 da análise) — sem resposta no card.
