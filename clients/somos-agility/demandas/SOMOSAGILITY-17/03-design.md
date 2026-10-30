# Design — SOMOSAGILITY-17: Ajuste no fluxo de aprovação do JOB de investimento - Usuario Cyber

Tipo: **sustentação** (design enxuto). Base: `01-analise.md` (aprovada) + `02-recon.md`
(coleta de 2026-10-30 em `sbx-somos-agility-dev`).

## Respostas do recon às dúvidas da análise

| Dúvida | Resposta |
|---|---|
| 1. O que é "JOB de investimento" | objeto `JOB_de_Solicita_o_de_Investimento__c` |
| 2. Mecanismo atual | Approval Process nativo `JOB_de_solicitacoes_de_investimento` (ativo, processOrder 2) — é ajuste, não criação do zero |
| 3. Quem são | todos são **usuários** individuais ativos; "Cyber" é o usuário compartilhado `Grupo Cyber Salesforce` (não é fila) |
| 4. Criado vs. atualizado | o processo filtra por `CreatedBy`; o design mantém isso |
| 5. Rejeição | **sem resposta** — o design segue o padrão vigente (qualquer rejeição encerra como Rejeitado). Premissa a confirmar na homologação |
| 6. Outros criadores | não mudam — o design não altera o caminho de nenhum outro criador |

Hoje um JOB do Cyber vai: Diretor(a) Pós-vendas → Walmor → Aprovado.
Pedido: Gustavo → Wanderley → Walmor.

## Decisão

**Configuração: novo Approval Process exclusivo para o Cyber, colocado antes do processo
geral na ordem de avaliação.** Sem Flow, sem Apex, sem mudança de modelo de dados.

`JOB_Investimento_Cyber` (label "JOB de Investimento - Cyber"):

- Entrada: `CreatedBy = Grupo Cyber Salesforce` **AND** `Status_da_Qualificaco__c != Aprovado`
  (mesmo filtro de status do processo geral).
- `processOrder = 2`; o processo geral `JOB_de_solicitacoes_de_investimento` passa para `3`.
  `Aprova_o_JOB` fica em `1` (o critério dele não cruza com o Cyber).
- Passos, todos com aprovador usuário, sem critério de passo, sem delegação:
  1. `Aprovacao_Gustavo` — Gustavo (rejeição = rejeição final, padrão do 1º passo)
  2. `Aprovacao_Wanderley` — Wanderley, `rejectBehavior = RejectRequest`
  3. `Aprovacao_Walmor` — Walmor, `rejectBehavior = RejectRequest`
- Igual ao processo geral para não mudar a experiência: submissor `owner`,
  `recordEditability = AdminOrCurrentApprover`, sem recall, `finalApprovalRecordLock = false`,
  template `Job_de_Investimentos/Solicita_o_de_JOB_de_Investimento`, mesmos campos na página
  de aprovação, mesmas ações (`Status_Qualificacao` na submissão; `Aprova_o_de_JOB` +
  `Status_Qualificacao_Aprovacao` na aprovação final; `Rejei_o_de_JOB` +
  `Status_Qualificacao_Rejeicao` na rejeição; `Status_Qualificacao_Recall` no recall).

### Por que não alterar o processo geral no lugar

A plataforma **não deixa adicionar, remover nem reordenar passos** de um Approval Process
depois que ele foi ativado. O pedido precisa de um passo novo (Wanderley) e de outro aprovador
no 1º passo, que hoje é compartilhado com outros 5 criadores. Mudar o processo geral exigiria
clonar e reativar o processo que atende 17 criadores, com risco de regressão para todos eles.
O processo dedicado só afeta o Cyber, e a entrada por ordem de avaliação é o mecanismo nativo
para isso (é o que `Aprova_o_JOB` já faz para outro criador).

### Por que não descer para Flow/Apex

Approval Process atende tudo: sequência fixa, só o aprovador da vez age (atende o 2º cenário
Gherkin por comportamento nativo), histórico de aprovação e reaproveitamento das ações que
já existem. Flow Orchestration ou Apex só trariam complexidade e um segundo mecanismo de
aprovação no mesmo objeto.

## Componentes

| Ação | Tipo | API name |
|---|---|---|
| Criar | ApprovalProcess | `JOB_de_Solicita_o_de_Investimento__c.JOB_Investimento_Cyber` |
| Alterar (só `processOrder` 2 → 3) | ApprovalProcess | `JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento` |
| Reaproveitar (sem alteração) | WorkflowFieldUpdate | `Status_Qualificacao`, `Status_Qualificacao_Aprovacao`, `Status_Qualificacao_Rejeicao`, `Status_Qualificacao_Recall` |
| Reaproveitar (sem alteração) | WorkflowAlert | `Aprova_o_de_JOB`, `Rejei_o_de_JOB` |
| Reaproveitar (sem alteração) | EmailTemplate | `Job_de_Investimentos/Solicita_o_de_JOB_de_Investimento` |
| Depreciar | — | nada. O critério `Grupo Cyber Salesforce` no processo geral (entrada e passo 1) vira inalcançável, mas **não é removido** nesta demanda (ver "O que não será feito") |

Nome do novo processo segue a convenção padrão do squad (o `CLAUDE.md` do cliente não define
convenção própria); o builder confere na skill `padrao-entrega`.

## Permissões

Nenhuma mudança. Gustavo, Wanderley e Walmor já leem o objeto; o Cyber já cria; OWD é
ReadWrite. Approval Process não depende de perfil nem de permission set para o aprovador.

## Conflito de automação

**No mesmo objeto e evento existe o Flow before-save `Status_Previs_o_de_Gastos_JOB`
(create/update). As field updates da aprovação disparam um novo ciclo de save e o Flow roda
de novo.** Isso já acontece hoje com o processo geral e as ações são as mesmas; o Flow grava
`Status_Previs_o_de_Gastos__c`, um campo diferente de `Status_da_Qualificaco__c`. Severidade
baixa, mas o QA deve conferir que os dois status ficam corretos depois de cada aprovação.

Não há trigger Apex nem Apex que submeta o registro para aprovação. A Workflow Rule do
objeto está inativa.

## Limites e escala

Sem impacto de governor: não tem código, SOQL nem loop. A aprovação é por registro, submetida
manualmente pelo dono. A dev tem 0 registros do objeto; o QA vai precisar criar registros de
teste como o usuário Cyber.

## Riscos técnicos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | Mudar `processOrder` do processo geral pela Metadata API pode ser recusado por ele estar ativo, ou não ser aplicado | Média | `sf project deploy validate` antes do deploy. Se falhar, reordenar em Setup › Approval Processes › Reorder, registrado no plano de build e no release como passo manual. O QA confirma que um JOB do Cyber entra em `JOB_Investimento_Cyber`. |
| R2 | Aprovações **já pendentes** de JOBs do Cyber continuam no caminho antigo (Pós-vendas → Walmor). Só submissões novas pegam o caminho novo | Média | Não dá para consultar em produção. O consultor confirma com o cliente antes do release se há pendências e se devem ser recolhidas e submetidas de novo (o recall não é permitido ao submissor; só o admin pode). |
| R3 | O aprovador é gravado no XML pelo username. Entre dev, qa e prod o sufixo de sandbox muda | Baixa | A Metadata API faz a conversão de sufixo entre sandboxes. O `deploy validate` na qa confirma. Nenhum username aparece em artefato `.md`. |
| R4 | Regra de rejeição assumida (qualquer rejeição encerra). Se o negócio quiser "voltar ao aprovador anterior", muda o `rejectBehavior` | Baixa | Confirmar na homologação. A mudança é um atributo dos passos 2 e 3 e precisa ser feita **antes** da primeira ativação na qa (depois de ativado, o comportamento de rejeição fica travado). |
| R5 | Se o novo processo for desativado no futuro, o Cyber volta ao caminho antigo, porque o critério dele continua no processo geral | Baixa | Documentar na entrega (etapa 7). |
| R6 | Ativar o Approval Process trava os passos daí em diante | Baixa | Validar a definição em dev antes da primeira ativação. Na qa, deploy já com a versão homologada. |

## O que NÃO será feito

- Não muda o caminho de nenhum outro criador e não altera passos, critérios ou ações do
  processo geral. Só o `processOrder` muda.
- Não remove o usuário `Grupo Cyber Salesforce` dos critérios do processo geral. Isso
  exigiria mexer no processo ativo de 17 criadores. Pode virar uma demanda de limpeza.
- Não cria fila, papel, permission set, campo nem regra de validação.
- Não automatiza a submissão. Continua manual, pelo dono, como hoje.
- Não trata as aprovações pendentes que já existem em produção (R2). Isso é decisão do cliente.
- Não muda modelo de dados. **Não há decisão de arquitetura sênior a escalar.**

## Estimativa

**Estimativa de esforço:** 2–4 h

Mudanças em relação à análise (2–6 h): o recon confirmou as três premissas que mais pesavam.
O mecanismo já é Approval Process nativo, os quatro envolvidos já são usuários ativos com
acesso ao objeto, e não há regra de rejeição própria a replicar (vale o padrão vigente). O
topo da faixa caiu porque não há provisionamento nem código. Ficam no topo: o eventual passo
manual de reordenação (R1) e o teste com três aprovadores diferentes na qa, que exige logar
como cada um ou ter usuários de teste.

---
Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
