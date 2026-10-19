# SOMOSAGILITY-14 — Recon da org

- Cliente: somos-agility
- Demanda: Erro fluxo de reembolso - Usuario Simone (sustentação / bug)
- Data do recon: 2026-10-19
- Executado por: agente `arquiteto` (skill `org-recon`), somente leitura

## 0. Org conectada

`sf org list` (2026-10-19):

| Tipo | Alias | Org Id | Status |
|------|-------|--------|--------|
| Sandbox | `sbx-somos-agility-dev` | `00DHa0000070wxfMAA` | Connected |

Só uma org conectada, do tipo **Sandbox**. Nenhuma produção à vista. Todo o recon abaixo foi
feito contra `sbx-somos-agility-dev`. Nada foi escrito na org (só retrieve de metadata, que
vai para um diretório temporário fora do repositório, e queries de metadata/`COUNT()`).

**Limitação importante:** a sandbox de dev tem **0 registros** de `Solicitacao_de_Reembolso__c`,
**0** de `Lancamento_de_Despesas__c` e **0** `ProcessInstance` de reembolso (`COUNT()`). A SR
citada no relato não está aqui. Tudo o que vem abaixo é **metadata da dev**, e não dá para afirmar
que a org onde o erro aconteceu (P3, ainda sem resposta) tem a mesma configuração.

## 1. Objeto principal

`Solicitacao_de_Reembolso__c` (label "Solicitação de Reembolso"). Foi confirmado por
`sf sobject list` e pelo retrieve de `CustomObject`. São 61 campos custom. Os que importam para
o envio para aprovação:

| Campo | Tipo | Observação |
|-------|------|------------|
| `Status__c` | Picklist | Valores: Rascunho, Pendente, Aprovado, Rejeitado, Recall |
| `Status_de_Aprovacao_e_Etapas__c` | Picklist | Rascunho, Pendente - Gerente de Projetos, Pendente - Gestor, Pendente - Diretor, Pendente - Operações, Aprovado, Rejeitado, Recall |
| `Solicitante__c` | Lookup(Contact) | |
| `aprovadorCordGerente__c` | Lookup(User) | É o aprovador dinâmico usado como `relatedUserField` nas etapas dos APs |
| `TotalDespesaProjeto__c` | Roll-up Summary **COUNT** de `Lancamento_de_Despesas__c.Solicitacao_de_Reembolso__c` | O nome sugere valor, mas o campo é uma contagem |
| `PIN__c` | EncryptedText, obrigatório | Comparado com `Contact.PIN__c` em validation rule |
| `Gerente__c` | Fórmula texto | `Solicitante__r.ReportsTo.FirstName & ' ' & LastName` |
| `Email_Gestor__c` | Email | Preenchido por Flow |

Objetos relacionados confirmados: `Lancamento_de_Despesas__c` (lookup `Solicitacao_de_Reembolso__c`,
picklist `Relacionado_a_entrega__c`) e `Contact.AprovadorReembolso__c` (Lookup(User)), que é a
origem do aprovador dinâmico.

Nesta org não existe RecordType para `Solicitacao_de_Reembolso__c` (a query retornou 0).

## 2. Approval Processes em `Solicitacao_de_Reembolso__c`

`ProcessDefinition` lista **49 versões** de Approval Process no objeto, quase todas `Obsolete`.
Ficam de fora as `Inactive` (`Solicitacao_de_Novo_Reembolso_v23`, `Z_Solicitacao_de_Novo_Reembolso_v11`,
`Z_Solicitacao_de_Novo_Reembolso_v17`) e as **4 ativas** abaixo, que foram retrieved e lidas:

| processOrder | DeveloperName | Label do processo | Lock | Etapas |
|---|---|---|---|---|
| 1 | `SolicitacaoReembolsoBackofficeRHGov4` | Solic. Reembolso - Backoffice/ RH&Dv4 | AdminOnly | 4 |
| 2 | `ReembolsoMarketing4` | Reembolso - Marketing4 | AdminOnly | 3 |
| 3 | `ReembolsoPosVenda5` | Reembolso - Pós Venda5 | AdminOnly | 6 |
| 4 | `Reembolso_Comercial_pre_vendas_e_CS` | Reembolso - Comercial, pré-vendas e CS | AdminOrCurrentApprover | 3 |

Os quatro têm o mesmo desenho:

- **Critério de entrada (nível do processo) usa só `CreatedBy equals <nome de usuário>`**, combinado
  por OR. Os quatro processos somam **32 valores distintos**: alguns são usuários nominais, outros
  parecem contas de grupo ("Grupo …"). Os nomes não foram copiados para cá (guardrail #2), mas
  estão no XML do AP.
  - `SolicitacaoReembolsoBackofficeRHGov4`: 5 critérios
  - `ReembolsoMarketing4`: 2 critérios
  - `ReembolsoPosVenda5`: 12 critérios
  - `Reembolso_Comercial_pre_vendas_e_CS`: 13 critérios
- Nenhum processo tem critério de entrada por perfil, papel, área ou campo do registro. **Não
  existe processo "catch-all"**: um usuário que não está nominalmente em nenhuma das listas não
  entra em processo nenhum.
- `allowedSubmitters` = `owner` (só o proprietário do registro pode enviar).
- Ação inicial de envio: Field Update `Status_Pendente` (`Status__c` = Pendente).
- Etapas: a primeira usa critério `TotalDespesaProjeto__c > 0` → usuário de grupo GP. As
  intermediárias usam `aprovadorCordGerente__c` (relatedUserField) ou usuários fixos. A última vai
  para o usuário de grupo de Operações.
- Ações finais: Alert `Aprovacao_de_Reembolso`, Field Updates `Status_Aprovado` e `Status_e_Etapa_Aprovado*`.

### Checagem do usuário "Simone" (feita sem trazer dado pessoal para o contexto)

Na dev existe **1** usuário ativo com `FirstName LIKE 'Simone%'` (`COUNT()`). O nome dele foi
comparado por script com os 32 valores de `CreatedBy` dos 4 APs ativos, e só o booleano saiu do
script:

- **Não aparece em nenhum critério de entrada de AP ativo.**
- Perfil: `Gerente de Contas`. Tem papel atribuído e tem `ManagerId` preenchido.
- O perfil `Gerente de Contas` tem Read/Create/Edit em `Solicitacao_de_Reembolso__c`, o que bate
  com o relato de que ela "consegue abrir a solicitação".

Não está confirmado que esse usuário da dev é a mesma pessoa do relato (P2/P3/P4).

## 3. Automações no mesmo objeto (`Solicitacao_de_Reembolso__c`)

| Tipo | API name | Evento | Ativo | O que faz |
|------|----------|--------|-------|-----------|
| Apex Trigger | `TrgSolicitacaoReembolso` | before/after insert, update, delete, undelete | Active | Chama `SolicitacaoReembolsoTriggerHandler` (extends `TriggerHandler`) |
| Apex Class | `SolicitacaoReembolsoTriggerHandler` | afterInsert/afterUpdate | — | Chama `SolicitacaoReembolsoBO.updateLancamentosDespesas` |
| Apex Class | `SolicitacaoReembolsoBO` | — | — | Se `Status__c = 'Rejeitado'`, faz update nos `Lancamento_de_Despesas__c` filhos. Bulkificado: 1 SOQL e 1 DML fora de loop |
| Apex Class | `SolicitacaoReembolsoBOTest` | — | — | Teste existente (API 48) |
| Flow | `Status_Etapa_Aprova_o_Gestor` | RecordBeforeSave, CreateAndUpdate | Active (API 55) | Se `Status__c = Aprovado` e há despesas, faz `Etapa_de_Aprovacao__c` = "1 - Gerente" |
| Flow | `Email_Gestor_4` | RecordBeforeSave, CreateAndUpdate | Active (API 55) | Faz `Email_Gestor__c` = `Solicitante__r.ReportsTo.Email` |
| Flow | `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` | RecordAfterSave, Update, filtro `Status__c = Pendente` | Active (API 66) | Faz update do próprio `$Record`: `Status_de_Aprovacao_e_Etapas__c` = "Pendente - Gerente de Projetos" ou "Pendente - Gestor". Não tem fault connector |
| Flow (inativos) | `Email_Gestor`, `Email_Gestor_7`, `Envia_email_gerente_de_projetos` | — | false | — |
| Workflow Rule | `Email Gestor`, `Status Etapa Aprovação Gestor` | — | **inativas** | Workflow do objeto tem 51 field updates, usados como ações dos APs |

Validation Rules ativas (5):

| API name | Condição (resumo) |
|----------|-------------------|
| `PIN` | `Solicitante__r.PIN__c <> PIN__c` → "PIN Incorreto" |
| `Aprovar_Vencido_Gestor` | `Aprovado_Reembolso_Vencido__c = TRUE` e nome do `$User` ≠ `Gerente__c` |
| `Reembolso_Vencido` | `Aprovado_Reembolso_Vencido__c = TRUE` e `Motivo__c` em branco |
| `campo_datapgmto_apenas_operacoes` | perfil ≠ "Compras Financeiro" e `ISCHANGED(Data_do_Pagamento__c)` |
| `campo_pago_apenas_operacoes` | perfil ≠ "Compras Financeiro" e `ISCHANGED(Pago__c)` |

Automação relacionada em outro objeto:

| Tipo | API name | Objeto | O que faz |
|------|----------|--------|-----------|
| Flow | `atualizaAprovadorReembolso` | `Lancamento_de_Despesas__c` (AfterSave, CreateAndUpdate, Active) | Faz `Solicitacao_de_Reembolso__c.aprovadorCordGerente__c` = `Solicitante__r.AprovadorReembolso__c` (Contact) para "Suporte/Outros", ou = o usuário de nome "Gerente de Projetos" para "Projeto" |

**Conflito de execução no envio:** quando a SR é enviada, a ação inicial `Status_Pendente`
(field update) faz rodar de novo o trigger `TrgSolicitacaoReembolso` e os Flows record-triggered.
O after-save `Atualiza_o_status_de_aprovacao_e_etapas_da_SR` então faz mais um update no próprio
registro, e nesse update as validation rules são avaliadas.

## 4. Observações laterais (fora do escopo, só registradas)

- `SolicitacaoReembolsoTriggerHandler.afterUpdate` retorna cedo quando
  `Trigger.oldMap.keySet().equals(Trigger.newMap.keySet())`. Num update essa condição é sempre
  verdadeira, então a lógica de "Rejeitado" pelo afterUpdate parece nunca rodar. Não tem relação
  com o sintoma reportado.
- São 49 versões de AP no mesmo objeto (o assessment já aponta excesso de metadata obsoleta).
- `TotalDespesaProjeto__c` é COUNT de lançamentos, mas os APs o usam como se indicasse "tem
  despesa de projeto".

## 5. O que não foi possível verificar

- O erro exato (P1). Não há print em texto.
- A SR afetada e o owner dela (P2). Na dev não há SR nenhuma.
- Se a org do erro é a dev, a QA ou produção (P3). Produção não é acessível ao agente, por regra.
- Se o usuário "Simone" da dev é a pessoa do relato (P4).
- Qual AP deveria atender a área/papel dela (P5). Não é algo que se infere da metadata.
- Se o `Contact` vinculado como `Solicitante__c` da Simone tem `AprovadorReembolso__c` preenchido.
  Seria leitura de dado de registro, então fica com o consultor.
- Layout e botão "Enviar para aprovação" não foram inspecionados. O relato indica que a ação
  existe e retorna erro.
