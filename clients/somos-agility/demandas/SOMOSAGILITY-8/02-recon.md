# SOMOSAGILITY-8 — Recon da org

- **Data da coleta:** 2026-10-30
- **Org:** `sbx-somos-agility-dev` (Org ID `00DHa0000070wxfMAA`, `Organization.IsSandbox = true`, API v68.0). Única org autenticada no runner.
- **Modo:** somente leitura. Metadata recuperada para `/tmp/recon/proj/` (projeto descartável), nunca para `force-app/`. SOQL só de metadata, perfis e `COUNT()`.
- **Dados pessoais:** os usernames que aparecem no XML do approval process e do workflow, os nomes gravados em field updates e descrições, e os nomes e e-mails do anexo **não** estão neste documento (guardrail #2). Usuários são citados pela etapa ou pelo perfil.

---

## 1. Objeto DEPV

| Item | Confirmado |
|---|---|
| API name | `Despesa_Extraordinaria_para_Pre_Venda__c` (objeto custom) |
| Label | "Despesa Extraordinária de Venda" |
| Key prefix | `a2C`, o mesmo do link do anexo |
| Sharing model | `ReadWrite` |
| Histórico de campos | habilitado no objeto (o campo Classificação Gerencial **não** está rastreado: `trackHistory=false`) |
| Volume na dev | `COUNT() = 0` registros de DEPV, 0 `Previsao_de_Gastos_da_DEPV__c`, 0 `ProcessInstance` pendente |
| Volume em produção | **não medido** (o agente não tem acesso a produção) |

### Campos usados pela demanda (todos existem)

| Rótulo no template do anexo | API name | Tipo |
|---|---|---|
| ID da solicitação | `Name` | Text (auto) |
| Proprietário | `OwnerId` | Lookup (User/Group) |
| Oportunidade | `Oportunidade__c` | Lookup (Opportunity) |
| Justificativa do Investimento | `Justificativa_do_Investimento__c` | Text Area |
| Recuperação do Investimento | `Recuperacao_do_Investimento__c` | Text Area |
| Valor Total Nominal Terceiros | **`Valor_Total__c`** | Currency (fórmula) |
| Valor Total Nominal Agility | `Valor_Efetivo_Agility__c` | Currency (fórmula) |
| Valor Total | **`Valor_Total_Integral__c`** | Currency (fórmula) |
| Classificação gerencial | `Classificacao_Gerencial__c` | Picklist: `Ofensor de caixa (Rentabilidade)`, `Despesas Agility` |
| (status do fluxo) | `Status_da_Qualificacao__c` | Picklist obrigatória: `Não Enviado` (default), `Pendente - Sales Op.`, `Pendente - CEO`, `Pendente - Operações`, `Aprovado`, `Rejeitado` |
| (status geral) | `Status__c` | Picklist dependente de `Status_da_Qualificacao__c`: `Aberto` / `Fechado` |
| (legado) | `NomeAprovadorEtapa__c` | Text(255), alimentado por field updates de versões antigas do processo |

> **Atenção para o build:** o API name não bate com o rótulo nos valores. `Valor_Total__c` é "Valor Total **Nominal Terceiros**". O "Valor Total" do template é `Valor_Total_Integral__c`.

### Classificação Gerencial na UI

- **Layout clássico** (`Despesa_Extraordinaria_para_Pre_Venda__c-Layout de Despesa Extraordinária para Pré Venda`): campo com `behavior = Required`.
- **Lightning record page** (`Despesa_Extraordin_ria_de_Venda_Record_Page`, Dynamic Forms): campo com `uiBehavior = required`, dentro da seção **"Exclusivo CEO"**, junto com `Status_da_Qualificacao__c`. A seção só aparece para quatro perfis: `Administração`, `Admin`, `adminPMO` e `Compras Financeiro`. Quem não vê a seção não é obrigado a preencher o campo na UI.
- **FLS:** leitura e edição liberadas em todos os perfis listados (`FieldPermissions`). Quem vê o campo é decidido pela visibilidade da seção, não pela FLS.

## 2. Processo de aprovação

13 versões de `ApprovalProcess` no objeto. **Só `Qualificacao_DEPV_v7_6` está ativa** (label "Qualificação DEPV - v7.6", descrição "Adiciona grupo operações como aprovador final - Alterado em 09/03/2026"). As outras 12 estão inativas.

### `Qualificacao_DEPV_v7_6` (ativa)

| # | Step (API) | Label | Aprovador | Perfil do aprovador (dev) | Ação ao aprovar |
|---|---|---|---|---|---|
| 1 | `Qualifica_o_Sales_Op` | Qualificação - Sales Op. | 1 usuário (conta funcional de Sales Operations) | `Sales Operations` | FU `Status_e_Etapa_Pendente_CEO` |
| 2 | `Qualificacao_CEO` | Qualificação - Diretor(a) comercial | 1 usuário nomeado | `Diretor Comercial` | FU `Status_DEPV_Pendente_Operacoes` |
| 3 | `Qualificacao_Operacoes_Financeiro` | Qualificação - Operações (Financeiro) | 1 usuário (conta funcional do grupo Operações) | `Compras Financeiro` | FU `Status_DEPV_Aprovado_Fechado` |

- Aprovadores são **usuários fixos** (tipo `user`), não fila, grupo ou hierarquia. `whenMultipleApprovers = FirstResponse`. Os três usuários estão ativos na dev.
- Entrada: `Status_da_Qualificacao__c` diferente de qualquer `Pendente - *` e de `Aprovado`.
- Submissão inicial: FU `Status_e_Etapa_Pendente_Sales_Op`.
- Aprovação final: alert `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda_Aprovada` + FUs `Status_da_Solicitacao_Fechado` e `Status_e_Etapa_Aprovado` (este grava `Aprovado`).
- Rejeição final: alert `Solicitacao_de_Nova_Despesa_Extraordin_ria_para_Pr_Venda_Rejeitada` + FUs de fechamento e `Rejeitado`.
- `recordEditability = AdminOrCurrentApprover`: o aprovador da vez pode editar o registro enquanto ele está travado.
- `finalApprovalRecordLock = true`: depois da aprovação final, só admin edita.
- `allowRecall = false`.
- `approvalPageFields` inclui `Classificacao_Gerencial__c` mas não `Valor_Total_Integral__c`.
- **Template da solicitação de aprovação (`emailTemplate`): ausente.** Os aprovadores recebem o e-mail padrão da Salesforce. As versões `Qualificacao_DEPV` a `v7_5` (exceto `v7_4`) apontavam para o template customizado `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda`. A v7_6 deixou de apontar, como a v7_4. É a causa mais provável do pedido de "ajustar layout da notificação de aprovações".

### Histórico relevante nas versões inativas

- `v6` e `v7` tinham um step `Qualificacao_df` com label **"Qualificação Diretor Financeiro"** e FU `Nome_aprovador_3`. **Nenhuma etapa da v7_6 se chama Diretor Financeiro.** Hoje a etapa financeira é a 3ª, "Operações (Financeiro)".
- Field updates legados `Aprovador_1`, `Nome_aprovador_2` e `Nome_aprovador_3` gravam nomes fixos de pessoas em `NomeAprovadorEtapa__c`. Nenhum deles é usado pela v7_6.

## 3. Notificações (Workflow `Despesa_Extraordinaria_para_Pre_Venda__c`)

Nenhuma **Workflow Rule** no objeto. O arquivo de workflow só guarda alerts e field updates usados pelo approval process.

| Email Alert | Template | Remetente | Destinatários hoje |
|---|---|---|---|
| `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda_Aprovada` | `.../Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda_Aprovada` | Org-Wide Email Address | owner + 3 usuários fixos: o aprovador da etapa 3 (Operações), o aprovador da etapa 1 (Sales Op) e 1 destinatário nomeado que o anexo também pede. 0 e-mails adicionais. |
| `Solicitacao_de_Nova_Despesa_Extraordin_ria_para_Pr_Venda_Rejeitada` | `.../..._Rejeitada` | usuário corrente | owner |

### Templates (pasta `Despesa_Extraordinaria_de_Pre_Venda`, todos Classic HTML `freeForm`, ISO-8859-1)

| Template | Usado pela v7_6? | Conteúdo hoje (estrutura) |
|---|---|---|
| `Solicitacao_de_Nova_Despesa_Extraordinaria_para_Pre_Venda` | **Não** (só pelas versões inativas) | "Prezado, existe uma nova Solicitação... para sua Qualificação": Justificativa, Recuperação, Valor Total Nominal Terceiros, Valor Total Nominal Agility, Valor Total, bloco **"Atenção CEO — não deixe de preencher Classificação Gerencial"** e `{!...Link}`. **Faltam** ID, Proprietário e Oportunidade em relação ao anexo. |
| `..._Aprovada` | Sim (aprovação final) | "Olá `{!CreatedBy}`, sua solicitação foi Aprovada!", `{!ApprovalRequest.Comments}`, `{!...Link}` e assinatura `{!ApprovalRequest.Process_Assignee}`. Praticamente igual ao bloco "Notificação final / Aprovada" do anexo. |
| `..._Rejeitada` | Sim (rejeição final) | fora do escopo |

- Org-Wide Email Addresses: 12 cadastradas. Nenhuma com "gov" ou "opera" no endereço.
- Entregabilidade na dev: 30 dos 32 usuários Standard ativos têm e-mail com sufixo `.invalid` (padrão de sandbox). Notificação para usuário **não chega** na caixa real dele na dev nem na qa, a menos que o e-mail seja ajustado para teste.

## 4. Grupos citados no anexo

- **"Agility GOV":** não existe como Public Group (27 grupos `Regular` listados, nenhum parecido). Nenhum usuário ativo com "gov" ou "governanca" no username ou e-mail. **Conclusão: é uma lista de distribuição externa ao Salesforce.**
- **"Operações":** não existe como Public Group. Existe um **usuário funcional** do grupo Operações (perfil `Compras Financeiro`), que é o aprovador da etapa 3 e já recebe o alert de aprovação final. Existe também o perfil `Grupo Operações`.
- Destinatários nomeados do anexo, sem nomes aqui:
  - Notificação de 1ª/2ª aprovação: **1 pessoa nomeada + Agility GOV**. A análise registrou "2 pessoas", mas o anexo pede 1 pessoa e 1 lista.
  - Notificação de 3ª / final: **3 pessoas nomeadas + Operações + Agility GOV**. A análise registrou "4 pessoas".
  - Situação de cada destinatário na dev, conferida sem expor username:
    - Pessoa A: pelo padrão do username, é o aprovador atual da etapa 2.
    - Pessoa B: já é destinatária do alert `..._Aprovada`.
    - Pessoa C: 1 usuário ativo bate pelo padrão de username. Precisa de confirmação humana.

## 5. Automação no objeto (conflito de execução)

| Tipo | Achado |
|---|---|
| Apex Trigger | **nenhum** em `Despesa_Extraordinaria_para_Pre_Venda__c` |
| Record-triggered Flow ativo | **nenhum**. `FlowDefinitionView` com trigger no objeto retornou 0. |
| Flows que citam o objeto | `Atualiza_o_status_da_DEPV` (after-save, create/update) e `Submete_DEPV_para_aprovacao` (after-save, update, submit). **Os dois sem versão ativa** (`ActiveVersionId = null`). |
| Process Builder | nenhum cita o objeto. Busca feita nos 335 Flows recuperados. |
| Apex | só `SolicitacaoMudancaTriggerHandlerTest` cria uma DEPV (insert simples, com `Oportunidade__c`) no setup do teste. Nenhuma classe de negócio usa o objeto. |
| Validation Rule | 1: `Checa_Classificacao_Gerencial_se_Soto` (ativa). Detalhe abaixo. |
| Workflow Rule | nenhuma |

### `Checa_Classificacao_Gerencial_se_Soto`: ativa, mas **nunca dispara**

Fórmula: `AND(ISPICKVAL(Classificacao_Gerencial__c, ''), ISPICKVAL(Status_da_Qualificacao__c, 'Pendente'), $Profile.Name = 'Admin')`. O valor `Pendente` **não existe** na picklist atual de `Status_da_Qualificacao__c` (só `Pendente - Sales Op.`, `- CEO` e `- Operações`). Ele só era gravado pelo FU legado `Status_Pendente`, que a v7_6 não usa. A regra é código morto: foi uma tentativa anterior de resolver exatamente o RN1. Duas razões impedem que ela funcione:
1. Ela depende de um valor de status que não existe mais.
2. Validation rule **não roda** sobre field update de approval process. Ela só pegaria uma edição manual.

## 6. Perfis

- `Admin`: 2 usuários ativos na dev.
- `Diretor Financeiro`: perfil existe, **0 usuários ativos** na dev.
- `Compras Financeiro`: perfil do aprovador da etapa 3, que vê a seção "Exclusivo CEO" e o campo.
- `Diretor Comercial`: perfil do aprovador da etapa 2, que **não** vê a seção "Exclusivo CEO".

## 7. O que não foi possível medir

- Volume de DEPVs e aprovações pendentes em **produção**, porque o agente não tem acesso. Na dev há 0.
- Se as configurações de produção são iguais às da dev (approval process ativo, usuários, perfil de quem aprova cada etapa). A dev pode estar defasada.
- Configuração de entregabilidade de e-mail (Setup > Deliverability) da dev e da qa. Não há SOQL para isso.
