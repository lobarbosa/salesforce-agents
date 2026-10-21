# 02 — Recon da org: SOMOSAGILITY-12

**Data da coleta:** 2026-10-20 (vence em 2026-10-27, refaça depois disso)
**Org:** `sbx-somos-agility-dev`, Org Id `00DHa0000070wxfMAA`, `https://agilitynetworks--sbxdev.sandbox.my.salesforce.com`
**Sandbox confirmada:** `SELECT IsSandbox FROM Organization` retornou `true` (Enterprise Edition)
**Método:** `sf sobject describe`, SOQL de metadata (Tooling e data API), `sf project retrieve start` para um projeto
temporário fora do repositório (`/tmp`). Nenhum registro de negócio foi lido, só `COUNT()` e metadata.
Nomes de usuários que aparecem como valor de critério em processos de aprovação **não** foram copiados para cá
(guardrail #2). A única exceção é o primeiro nome que a própria demanda já cita.

---

## 1. Resposta à D-01: qual objeto

**Objeto: `JOB_de_Solicitacao_de_Treinamentos__c` ("JOB de Solicitação de Treinamentos", prefixo `a1b`).**

A demanda não diz o objeto, mas o título começa com "JST". A org confirma essa sigla em quatro pontos:

| Evidência | Fonte |
|---|---|
| A descrição do processo de aprovação ativo `Aprovacao_do_JOB_de_Treinamentos_v7` diz: *"Alteração das etapas de aprovação para JST"* | retrieve `ApprovalProcess` |
| Objetos filhos têm lookups chamados `Capacitacoes__c.JST__c`, `Lancamento_Despesas__c.Relacionado_ao_JST__c` e `Lancamento_de_Despesas__c.Relacionado_ao_JST__c`, todos apontando para este objeto | `describe` → `childRelationships` |
| O processo de aprovação ativo `JobSTGeral_v2` tem o label "Job de ST Geral - v2" (ST = Solicitação de Treinamento) | `ProcessDefinition` |
| A etapa final de `JobSTGeral_v2` ("Aprovação do diretor financeiro") tem como aprovador o usuário cujo nome bate com o "Walmor" da demanda | retrieve `ApprovalProcess` (conferido por script, sem imprimir o username) |

**Candidato descartado:** `JOB_de_Solicita_o_de_Investimento__c` também tem `Classificacao_Gerencial__c` (e mais as
versões `_2` a `_5`) e `Denomina_o_do_JOB__c`, e tem processos de aprovação ativos (`Aprova_o_JOB`,
`JOB_de_solicitacoes_de_investimento`). Nada nele cita "JST". Os aprovadores dele não foram inspecionados.
**Confiança na escolha: alta, mas é inferência a partir de evidência e não resposta do consultor.**
O consultor precisa confirmar (ver 03-design, seção 2).

## 2. Campos

| API name | Label | Tipo | Obrigatório hoje | Histórico | Observação |
|---|---|---|---|---|---|
| `Classificacao_Gerencial__c` | Classificação Gerencial | Picklist | não (`required=false`, `nillable=true`) | sim | Valores ativos: `Investimento 2019` até `Investimento 2026`. Não existe `Investimento 2027` |
| `Denomina_o_do_Treinamento__c` | Denominação do Treinamento | **LongTextArea(5000)** | não | sim | Ser LongTextArea limita onde o campo pode entrar como critério (ver design, R-05) |
| `Status_da_Qualifica_o__c` | Status da Qualificação | Picklist | não | sim | Valores: `Pendente` (**default**), `Rejeitado`, `Cancelado`, `Aprovado`, `Recall`. Não existe um valor "Não Enviado" (o objeto de Investimento tem) |

**Consequência importante:** como o default de `Status_da_Qualifica_o__c` é `Pendente`, um registro recém-criado e
um registro recém-submetido para aprovação têm o mesmo status. **Pelo status não dá para saber se o registro já foi
submetido.**

Registro de tipo: só `Mestre` (master). Nenhum record type de negócio.

## 3. Processos de aprovação no objeto

`SELECT ... FROM ProcessDefinition WHERE TableEnumOrId = 'JOB_de_Solicitacao_de_Treinamentos__c'` retornou 13
definições. **2 estão ativas:**

| DeveloperName | Label | processOrder | Critério de entrada | Etapas | Edição durante a aprovação | Lock final |
|---|---|---|---|---|---|---|
| `JobSTGeral_v2` | Job de ST Geral - v2 | **1** | `CreatedBy` igual a um de 15 usuários/grupos (OR) | 1) "Enviado para para aprovação Pós Venda" (condicional por `CreatedBy`, senão pula); 2) **"Aprovação do diretor financeiro"** (aprovador fixo, é o "Walmor" da demanda) | `AdminOrCurrentApprover` | não |
| `Aprovacao_do_JOB_de_Treinamentos_v7` | Aprovação do JOB de Treinamentos v7 | **2** | `Tentativa__c` em (1a, 2a, 3a ou acima) **OU** `Objetivo__c = Treinamento` | 1) "Qualificação Gerenciador" (hierarquia `Manager`); 2) **"Qualificação Diretoria Executiva"** (aprovador fixo, **não** é o Walmor) | `AdminOnly` | sim |

As outras 11 estão `Inactive` ou `Obsolete`.

Ações compartilhadas (Workflow do objeto, retrieve `Workflow:JOB_de_Solicitacao_de_Treinamentos__c`):
- Submissão: field update `Status_Qualificacao` → `Pendente`
- Aprovação final: alert `Aprovacao_do_JOB_de_Treinamento` / `Aprovaco_do_JOB_de_Treinamento` e field update `Status_Qualificacao_Aprovacao` → `Aprovado`
- Rejeição: alert `Rejeicao_JOB_de_Treinamento` e field update `Status_Qualificacao_Rejeicao` → `Rejeitado`
- Recall: field update `Status_Qualificacao_Recall` → `Recall` (+ alert `Pendencia_de_JOB_de_Treinamentos` no v7)

`allowRecall=false` nos dois processos. Quem pode submeter é só o `owner`.

Observação lateral, fora do escopo: no v7, a etapa 1 usa `1 AND 2 AND 3` sobre `User.Manager` igual a três valores
diferentes. Isso nunca é verdadeiro, então o processo sempre pula direto para "Qualificação Diretoria Executiva".

**Resposta parcial à D-02:** o "gatilho de seguir com a aprovação" é o botão padrão **Submit for Approval**
(`platformActionList` do layout padrão inclui `Submit`). Não existe quick action nem botão custom no objeto
(`QuickActionDefinition` vazio). Os dois processos ativos terminam numa aprovação de diretoria, mas só o
`JobSTGeral_v2` termina no Walmor. **Não dá para saber pela org se a regra vale para os dois processos ou só para o
que vai ao Walmor.**

## 4. Automações no objeto

| Tipo | Resultado | Como foi verificado |
|---|---|---|
| Validation rules | **nenhuma** (nem ativa nem inativa) | Tooling `ValidationRule` por `EntityDefinitionId` = 0; retrieve de `CustomObject` sem pasta `validationRules` |
| Apex triggers | **nenhum** | Tooling `ApexTrigger` por `TableEnumOrId` = 0; grep do nome do objeto nos 16 triggers e 95 classes custom recuperados = 0 |
| Record-triggered Flow / Process Builder | **nenhum** | `FlowDefinitionView` por label do objeto = 0; grep do nome do objeto nos 335 Flows recuperados = 0 |
| Workflow rules clássicas | **nenhuma** (o arquivo `Workflow` tem só alerts e field updates usados pelos processos de aprovação) | Tooling `WorkflowRule` = 0 + retrieve |
| Visualforce | nenhuma referência | grep nas 57 páginas recuperadas |
| Lightning record page (FlexiPage) | **nenhuma** para o objeto | `sf org list metadata --metadata-type FlexiPage` (134 páginas, nenhuma do objeto). O Lightning usa o page layout |

**Não há conflito de ordem de execução com Flow ou trigger no mesmo objeto e evento.** Existe uma fonte indireta
de save no objeto, e ela é relevante:

**Roll-up summary: 7 campos `Summary` no objeto** (`Valor_Total_Gasto_por_Terceiros__c`, `Valor_Total_Pago_Reais__c`,
`Valor_Total_Reais__c`, `Valor_Total_de_Gastos_Previstos__c`, `Valor_Total_de_Gastos_Realizados__c`,
`Valor_Total_de_Patroc_nio_Realizado__c`, `Valor_Total_do_Patroc_nio_Previsto__c`). Todos somam do filho master-detail
`Previsao_de_Gastos_do_Treinamento__c` (`summaryForeignKey = Previsao_de_Gastos_do_Treinamento__c.JOB_de_Solicitacao_de_Treinamentos__c`).
**Quando um filho é salvo, o pai é recalculado e passa pelas validation rules dele.**

Flow no entorno, sem relação com o objeto: `atualiza_gasto_previsto` (after-save em `Previsao_Gastos_Treinamento_Realizado__c`)
atualiza o próprio registro, não o JOB.

## 5. Page layouts e atribuição

| Layout | Tem os dois campos? | Atribuído a |
|---|---|---|
| `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos` | **NÃO, nenhum dos dois** | **todos os 74 perfis recuperados** |
| `JOB_de_Solicitacao_de_Treinamentos__c-Layout de JOB de Solicitação de Treinamentos CEO` | sim, os dois como `Edit` | nenhum dos 74 perfis recuperados |

O retrieve do perfil `Admin` falhou (erro de nome duplicado no pacote de retrieve), então a atribuição de layout dele
não foi confirmada.

**Consequência: hoje, quase todo usuário não vê nem consegue preencher esses dois campos na tela do registro.**
Esse é provavelmente o motivo real de os registros chegarem vazios à diretoria.

## 6. Permissões (contagens e nomes de perfil, sem usuário)

- `ObjectPermissions` com create/edit no objeto: 28 containers (perfis + permission sets).
- `FieldPermissions` com edit nos dois campos: 15 containers. Com leitura apenas: 2.
- **Perfis que criam/editam o JOB mas não têm FLS de edição nos dois campos:** `PO DT`, `Marketing`, `Diretor  DT`, `PMO`,
  `Diretor de Marketing`, `Diretor Financeiro`, `Gerente de Suporte DC`, `Gerente de Suporte SEG`, `Diretor de Projetos`,
  `Service Delivery`, `Service Manager`, `Gerente de Suporte EA` (sem acesso) e `PO EA` (só leitura).
  - Usuários ativos nesses perfis: **5** (Marketing 1, Diretor de Projetos 1, PO EA 3), e 2 deles têm o permission set
    `jobsAprovacao`, que dá edit nos dois campos. **Até 3 usuários ativos** podem criar JOB sem conseguir preencher os campos.
- O permission set `jobsAprovacao` já existe e dá create/edit no objeto e edit nos dois campos. Tem 4 atribuições ativas.
  O resto do conteúdo dele não foi inspecionado.

## 7. Volume

- `SELECT COUNT() FROM JOB_de_Solicitacao_de_Treinamentos__c` = **0**
- `SELECT COUNT() FROM Previsao_de_Gastos_do_Treinamento__c` = 0
- `ProcessInstance` com alvo no objeto = 0

A sandbox de dev não tem massa de dados (bate com o assessment de 2026-09-30). **O volume de produção e o número de
registros legados com os campos vazios são desconhecidos.** Produção está fora do alcance (guardrail #1).

## 8. O que não pôde ser confirmado

- A data do último refresh da sandbox e se ela está igual a produção (`SandboxInfo` não é consultável deste usuário).
  Os layouts, FLS e processos de aprovação podem ser diferentes em produção.
- **D-09:** o "Detalhamento anexo" citado na demanda não existe no repositório (`demandas/SOMOSAGILITY-12/` contém só
  `demanda.md`, `status.yaml`, `01-analise.md` e `gates.md`). A org não tem como substituir esse anexo.
- A atribuição de layout do perfil `Admin` (falha no retrieve).
- O conteúdo completo do permission set `jobsAprovacao` além do objeto e dos dois campos.
