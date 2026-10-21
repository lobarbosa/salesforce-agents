# 03 — Design: SOMOSAGILITY-22 — Relatório de Jobs do painel de controle financeiro

**Cliente:** somos-agility
**Tipo:** sustentação, design enxuto
**Org consultada:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, sandbox, confirmada com `sf org list`). Única org conectada. Nada foi lido de produção.
**Entradas:** `demanda.md`, `comentarios-do-card.md`, `01-analise.md` (aprovada em 2026-10-21), `02-recon.md`, mais o recon complementar desta etapa (seção 1).
**Data:** 2026-10-21

---

## 0. Resumo para quem aprova

O recon encontrou uma causa possível (H4: o filtro de período do relatório). Esta etapa encontrou uma **segunda causa, mais forte e que bate melhor com a queixa** (H5): **o Processo de Aprovação ativo principal do Job não marca o Job como "Pendente" quando ele é enviado para aprovação.** O Job fica em "Não Enviado" (valor padrão) durante toda a aprovação, e só muda quando sai a decisão final (Aprovado ou Rejeitado). No relatório, que agrupa por `Status_da_Qualificaco__c`, os Jobs que estão de fato aguardando aprovação aparecem no grupo "Não Enviado". É isso que o financeiro vê como "o filtro de qualificação não puxa corretamente os status". O anexo mostra o histórico de aprovação com a etapa "Pendente" destacada, o que reforça essa leitura.

**Decisão:** correção **100% declarativa (configuração)**, sem Flow e sem Apex:
1. Incluir a ação de envio inicial que **já existe** (`Status_Qualificacao`, que grava "Pendente") no Processo de Aprovação ativo `JOB_de_solicitacoes_de_investimento`.
2. Filtro de período do relatório (`timeFrameFilter`): **não mexo sem decisão de negócio** (pergunta G2).

**Isto muda o escopo aprovado na análise.** A análise dizia que alterar o processo de aprovação estava fora do objetivo, salvo se as respostas mudassem o escopo. Mudaram: a causa está no processo. O humano precisa aceitar essa mudança no gate (G1).

---

## 1. Recon complementar (confirmado nesta etapa via `sf` CLI)

Tudo o que está abaixo foi conferido em `sbx-somos-agility-dev`. **Não confirmei que produção está igual** (ver risco R1).

### 1.1 Processos de Aprovação do objeto `JOB_de_Solicita_o_de_Investimento__c`

Seis processos foram recuperados (`ApprovalProcess`). Dois estão ativos:

| API name | Ativo | Ordem | Ação de envio inicial (`initialSubmissionActions`) | Aprovação final | Rejeição final | Recall |
|---|---|---|---|---|---|---|
| `Aprova_o_JOB` | sim | 1 | **`Status_Qualificacao` (→ Pendente)** | `Status_Qualificacao_Aprovacao` | `Status_Qualificacao_Rejeicao` | `Status_Qualificacao_Recall` |
| `JOB_de_solicitacoes_de_investimento` (descrição "v1.3.1") | sim | 2 | **nenhuma** | `Status_Qualificacao_Aprovacao` | `Status_Qualificacao_Rejeicao` | `Status_Qualificacao_Recall` |
| `JOBSolicitacaoInvestimento`, `_v1_1`, `_v1_2`, `JOB_de_solicitacoes_de_investimentos` | não | — | nenhuma | (idem) | (idem) | (idem) |

- `Aprova_o_JOB` tem critério de entrada restrito a **um único criador** (`CreatedBy` igual a um usuário específico). Ou seja, na prática quase todos os Jobs entram pelo processo de ordem 2, que não grava "Pendente".
- O processo de ordem 2 tem como critério de entrada, entre outros, `Status_da_Qualificaco__c` diferente de `Aprovado`. Gravar "Pendente" no envio não interfere nisso, porque o critério de entrada é avaliado antes das ações de envio.
- Os dois ativos têm `allowRecall = false`. Por isso o valor "Recall" quase não aparece (só em recall feito por administrador). Isso não é bug desta demanda, só explica por que o gráfico não tem esse grupo.
- Nenhuma das versões anteriores (inativas) tinha ação de envio inicial. Parece ser uma lacuna antiga desde que o processo geral substituiu o `Aprova_o_JOB`, e não uma regressão recente. Isso responde em parte a Q5: provavelmente não houve mudança recente, o problema sempre existiu nesse caminho.

### 1.2 Atualizações de campo (`Workflow:JOB_de_Solicita_o_de_Investimento__c`)

Recuperado e versionado em `force-app/main/default/workflows/JOB_de_Solicita_o_de_Investimento__c.workflow-meta.xml`.

| FieldUpdate | Campo | Valor literal |
|---|---|---|
| `Status_Qualificacao` | `Status_da_Qualificaco__c` | **Pendente** |
| `Status_Qualificacao_Aprovacao` | `Status_da_Qualificaco__c` | Aprovado |
| `Status_Qualificacao_Rejeicao` | `Status_da_Qualificaco__c` | Rejeitado |
| `Status_Qualificacao_Recall` | `Status_da_Qualificaco__c` | Recall |
| `Status_Previs_o_de_Gastos_JOB` | `Status_Previs_o_de_Gastos__c` | Fechado (fora do escopo) |

A única regra de workflow do objeto (`Status Previsão de Gastos JOB`) está **inativa** e não toca no status de qualificação.

### 1.3 Outras automações no objeto

- **Flow disparado por registro:** só `Status_Previs_o_de_Gastos_JOB` (before-save, ativo). Consultei `FlowDefinitionView`. Ele só grava `Status_Previs_o_de_Gastos__c` e **não toca** `Status_da_Qualificaco__c`.
- **Triggers Apex:** nenhum (`ApexTrigger` com `TableEnumOrId = JOB_de_Solicita_o_de_Investimento__c` retornou 0).
- **Conflito de ordem de execução:** existe um Flow before-save no mesmo objeto, e a atualização de campo do processo de aprovação dispara um novo update no registro, que roda o Flow before-save de novo. **Esse risco já existe hoje** nas ações de aprovação e rejeição final, que fazem a mesma coisa. Como o Flow não lê nem grava o campo de qualificação, o risco é **baixo**. A ação usa `reevaluateOnChange = false`, então não há recursão em regra de workflow.

### 1.4 Quem mais depende de `Status_da_Qualificaco__c` (impacto da mudança)

Encontrado com grep no `force-app` versionado e confirmado contra a org onde dava:

| Componente | Como usa o campo | Efeito da correção |
|---|---|---|
| `Lancamento_de_Despesas__c.Relacionado_ao_Job__c` e `Lancamento_Despesas__c.Relacionado_ao_Job__c` | Filtro de lookup: só Jobs com status `Aprovado` | Nenhum. Nada muda para Jobs aprovados. Jobs pendentes já não passavam no filtro como "Não Enviado" e continuam não passando como "Pendente". |
| `Previsao_de_Gastos_Job_Investimentos__c.Status_da_Qualificacao__c` | Fórmula `TEXT(JOB...__r.Status_da_Qualificaco__c)` | Passa a mostrar "Pendente" em vez de "Não Enviado" para Jobs em aprovação. Efeito desejado. |
| Report types `JOB_de_Solicita_o_de_Investimento_com_Previs_o_de_Gastos_com_Previs_o_de_Gast` e `...Gast2` | Expõem o campo | Relatórios baseados neles passam a mostrar a distribuição correta. |
| List view `My_Jobs`, layout `...Layout de JOB de Solicitação de Investimento - CEO`, permission sets `jobsAprovacao`, `DiretorComercial`, `Comunidade_TI` | Exibem ou dão acesso ao campo | Nenhuma mudança de configuração necessária. |
| **Outros relatórios do objeto na org** | `SELECT ... FROM Report` pelo nome achou **45 relatórios** ligados a Job ou Investimento, por exemplo `Financeiro/JOBs_de_Investimento_AprovadosPendente_bzL` e `Job's/JOBs_de_Investimento_AprovadosPendente_MCs` | Não abri o filtro de cada um. Qualquer relatório que filtre `Status_da_Qualificaco__c = Pendente` passa a trazer **mais** Jobs (os que estavam errados como "Não Enviado"). Para o negócio isso é a correção, mas os números vão mudar e o financeiro precisa ser avisado (R3). |

### 1.5 Filtro de período do relatório (H4, já no recon)

- `timeFrameFilter`: `dateColumn = Data__c` (fórmula = `CreatedDate`), `interval = INTERVAL_PREVCUR2FY`.
- O ano fiscal da org começa em **janeiro** (`Organization.FiscalYearStartMonth = 1`). Hoje a janela vai de **01/01/2024 a 31/12/2026**. Jobs criados antes de 2024 ficam fora do relatório inteiro, qualquer que seja o status.
- A descrição do relatório é "Relatorio de acompanhamento de Jobs Pendentes". Se o objetivo é acompanhar pendências, um Job pendente criado em 2023 deveria aparecer. Mas se a janela foi uma escolha consciente do financeiro (limitar o histórico), mudar isso é decisão de negócio e não correção técnica. **Não altero sem G2.**

---

## 2. Decisão e justificativa

**Nível escolhido: configuração** (metadata de Approval Process e, se G2 pedir, de Report). Nada de Flow nem de Apex.

- **Por que não um Flow:** a informação "está em aprovação" vive no `ProcessInstance`, que não dispara Flow nem pode ser lido por fórmula. Um Flow agendado copiando o status do `ProcessInstance` para o campo seria uma segunda fonte de verdade, com atraso, para fazer o que o próprio processo de aprovação faz nativamente com uma ação de envio inicial. O FieldUpdate `Status_Qualificacao` já existe e já é usado no outro processo ativo. É só ligá-lo.
- **Por que não Apex:** nenhum requisito pede lógica que a configuração não cubra.
- **Por que não "corrigir só o relatório":** nenhum filtro de relatório consegue mostrar "Pendente" se o campo gravado é "Não Enviado". O filtro de qualificação do relatório já está correto (H1 refutada no recon). Mexer só no relatório não resolve a queixa.
- **Sem mudança de modelo de dados:** nenhum campo, objeto ou valor de picklist é criado ou alterado. Não há escalonamento de arquitetura sênior por esse motivo. A escalada aqui é de **escopo de processo** (G1).

---

## 3. Componentes

### A alterar (condicionado a G1)

| Tipo | API name | Mudança |
|---|---|---|
| ApprovalProcess | `JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento` | Adicionar `<initialSubmissionActions><action><name>Status_Qualificacao</name><type>FieldUpdate</type></action></initialSubmissionActions>`. **Nenhuma outra alteração**: etapas, aprovadores, critérios de entrada e bloqueio de registro ficam iguais. |

O arquivo do processo só entra no repositório no build, na branch `feature/SOMOSAGILITY-22`. Nesta etapa só versionei o Workflow (seção 1.2). Os demais `approvalProcesses/` recuperados pelo recon (244 arquivos, quase todos de outros objetos) continuam fora do commit.

### A alterar (condicionado a G2: só se o financeiro pedir)

| Tipo | API name | Mudança possível |
|---|---|---|
| Report | `Financeiro/JOBs_de_Investimento_HsY` (`force-app/main/default/reports/PMOAtualizados/Financeiro/JOBs_de_Investimento_HsY.report-meta.xml`) | Opção (a): manter. Opção (b): trocar `interval` para "todo o período" (`INTERVAL_CUSTOM` sem datas). Opção (c): outra janela definida pelo financeiro. |

### A criar / depreciar
Nada. **Não** vou desativar nem apagar os 4 processos inativos, por mais que sejam lixo técnico (fora do escopo).

### Permissões
Nenhum impacto. O FieldUpdate roda em contexto de sistema, sem depender de FLS do usuário que envia. Nenhum perfil ou permission set muda.

---

## 4. Correção dos dados que já existem (fora do build do agente)

A mudança vale **só para envios feitos depois do deploy**. Os Jobs que já estão em aprovação agora vão continuar em "Não Enviado" (ou "Rejeitado", se foram reenviados depois de uma rejeição) até a decisão final. Corrigir esses registros é DML em dados de produção, que é proibido ao agente (guardrail #1). Pelo critério de aceite "nenhum job some/fica no grupo errado", isso tem que ser decidido (G3). Opções:
- (a) Não corrigir: o problema some sozinho conforme as aprovações em curso forem decididas.
- (b) Um admin do cliente corrige em produção, por exemplo com um relatório de "Processos de aprovação pendentes" e atualização em massa para "Pendente". Isso é feito fora da esteira.

---

## 5. Riscos

| # | Risco | Severidade | Mitigação |
|---|---|---|---|
| R1 | **A metadata de dev pode não ser igual à de produção.** O diagnóstico (falta de ação de envio inicial) foi feito em `sbx-somos-agility-dev`. Se produção já tem a ação, a causa é outra. | **Alta** | G4: alguém do cliente ou o consultor confirma em produção, em Setup > Processos de Aprovação > "JOB de solicitações de investimentos", se existe "Ações de envio inicial" com a atualização "Status Qualificação". Leitura de tela, sem agente. |
| R2 | Alterar um processo de aprovação **ativo** por deploy. A plataforma permite mudar ações, mas não etapas, num processo ativo. Se o deploy for recusado, seria preciso desativar, alterar e reativar, ou clonar como v1.3.2. | Média | Validar com `sf project deploy validate` (check-only) em dev antes do build real. Se recusar, voltar ao arquiteto. Não improvisar uma nova versão. |
| R3 | Os números do painel e dos 45 relatórios ligados a Job **vão mudar**. Jobs migram de "Não Enviado" para "Pendente". Quem acompanha pode ler isso como erro. | Média | Comunicar o financeiro antes do deploy em QA (texto no `06-entrega.md`). |
| R4 | O Flow before-save `Status_Previs_o_de_Gastos_JOB` roda de novo no update disparado pela ação de envio. | Baixa | Já acontece hoje nas ações finais. O Flow não usa o campo de qualificação. O QA confirma que `Status_Previs_o_de_Gastos__c` não muda no envio. |
| R5 | Sem dados nas sandboxes: dev tem 0 Jobs, então o teste precisa criar Job de teste e enviar. O processo tem critério por criador (`CreatedBy` de usuários e grupos específicos), então o usuário de teste precisa estar no critério. | Média | O QA usa em QA um usuário que atenda ao critério de entrada, ou um Job criado por ele. Não usar registro real (guardrail #2). |
| R6 | Se G2 ampliar a janela do relatório, o volume de linhas cresce, por exemplo Jobs desde 2013. | Baixa | Relatório Summary com agrupamento. O limite de 2.000 linhas só pesa na exibição de detalhes. Avaliar se o financeiro escolher (b). |

---

## 6. Plano de teste (alto nível, o `qa` detalha)

Em `sbx-somos-agility-qa`, com Job de teste e sem dado real:
1. Criar um Job com usuário que entra no processo de ordem 2 → status "Não Enviado".
2. Enviar para aprovação → **status vira "Pendente"**. Esse é o critério novo. Conferir que `Status_Previs_o_de_Gastos__c` não mudou.
3. Aprovar → "Aprovado". Repetir com rejeição → "Rejeitado". Reenviar o rejeitado → "Pendente".
4. Abrir o relatório `JOBs_de_Investimento_HsY` e o dashboard "Controle Financeiro": o Job aparece no grupo do status atual, e a contagem do dashboard é igual à do relatório.
5. Regressão: o lookup `Relacionado_ao_Job__c` em lançamento de despesa continua aceitando só Job aprovado.
6. Se G2 mudar a janela: conferir por contagem agregada (`COUNT()` agrupado por status, sem linhas) que o total do relatório é igual ao total do objeto no recorte acordado.
7. Prints só de registro de teste (guardrail #2).

---

## 7. O que NÃO será feito nesta demanda

- Mudança em etapas, aprovadores ou critérios de entrada dos processos de aprovação.
- Habilitar recall (`allowRecall`) ou qualquer outra mudança de comportamento do processo além da ação de envio inicial.
- Limpar ou desativar os 4 processos inativos e a regra de workflow inativa.
- Corrigir dados existentes em produção (seção 4; G3 decide se o cliente faz).
- Revisar os filtros dos outros 44 relatórios de Job.
- Qualquer mudança no componente JST do mesmo dashboard (outro objeto, outro processo).
- Deploy em produção (proibido ao agente).

---

## 8. Perguntas para o gate (respostas necessárias antes do build)

- **G1 (bloqueante): mudança de escopo.** Aceita que a correção seja no **Processo de Aprovação** `JOB_de_solicitacoes_de_investimento` (incluir a ação de envio inicial que grava "Pendente"), e não no relatório? A análise tinha isso como fora do objetivo.
- **G2 (bloqueante para a parte do relatório): regra de negócio.** O financeiro quer manter a janela "2 anos fiscais anteriores + atual por data de criação" (hoje 2024 a 2026) no relatório "JOBs de Investimento"? Ou quer ver todos os Jobs, ou outra janela? Sem resposta, o relatório **fica como está** e o build cobre só G1.
- **G3: dados atuais.** Os Jobs que já estão em aprovação e aparecem como "Não Enviado" devem ser corrigidos? Se sim, por um admin do cliente em produção, fora da esteira.
- **G4 (bloqueante): confirmar produção = dev.** Alguém confirma em produção que o processo "JOB de solicitações de investimentos" (v1.3.1) está ativo e **sem** "Ações de envio inicial"? Se produção já tiver a ação, este diagnóstico não vale e o design volta.
- Pendentes da análise que continuam úteis, mas não bloqueiam: Q2 (um ID de Job concreto em grupo errado confirmaria H5 de vez) e Q6 (se o chamado 20260303-055 é o mesmo problema).

---

## 9. Estimativa

**Estimativa de esforço:** 2–5 h

O que mudou em relação à análise (2–8 h): a causa foi localizada e é configuração de uma ação que já existe, sem campo calculado, Flow ou Apex. Isso tira o cenário de 6–8 h. A faixa inclui:
- ajuste do processo e validação check-only: ~0,5–1 h
- teste em QA com usuário que atenda ao critério de entrada: ~1–2 h
- homologação com o financeiro e comunicado sobre a mudança dos números: ~0,5–1 h
- se G2 pedir mudança no relatório: +0,5–1 h

A correção de dados existentes (G3), se feita pelo cliente, não está nesta conta.

---

Design pronto. **Gate bloqueante** — preciso do aceite do arquiteto humano para liberar o build.
