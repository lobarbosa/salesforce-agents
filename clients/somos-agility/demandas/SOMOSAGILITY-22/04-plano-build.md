# 04 — Plano de build: SOMOSAGILITY-22 — Relatório de Jobs do painel de controle financeiro

**Cliente:** somos-agility
**Tipo:** sustentação, build declarativo (sem Flow, sem Apex)
**Org de build:** `sbx-somos-agility-dev` (orgId `00DHa0000070wxfMAA`, sandbox, confirmada com `sf org list`). Única org conectada.
**Gate de design:** aprovado por Leonardo Barbosa em 2026-10-21T01:49:50 (ver `gates.md`), cobrindo G1 (mudança de escopo para o Processo de Aprovação). G2, G3 e G4 continuam em aberto — ver seção "Fora de escopo" abaixo.
**Branch:** `feature/SOMOSAGILITY-22` (já existente, reusada; nenhuma branch nova criada).

---

## 1. Componente alterado

- **Tipo:** `ApprovalProcess`
- **API name:** `JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento`
- **Arquivo:** `force-app/main/default/approvalProcesses/JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento.approvalProcess-meta.xml`
- **Origem:** recuperado agora via `sf project retrieve start --target-org sbx-somos-agility-dev --metadata "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento"` — este processo nunca tinha sido versionado no repositório antes (o design só havia trazido o `Workflow` do objeto, seção 1.2 do `03-design.md`).

### Diff exato

Único bloco adicionado, logo após `<finalRejectionRecordLock>` e antes de `<label>` (posição confirmada contra o outro processo ativo do mesmo objeto, `Aprova_o_JOB`, que já tem esse mesmo bloco na mesma posição — recuperado só para checar a ordem correta do schema, **não commitado**, removido do disco em seguida):

```xml
    <finalRejectionRecordLock>false</finalRejectionRecordLock>
    <initialSubmissionActions>
        <action>
            <name>Status_Qualificacao</name>
            <type>FieldUpdate</type>
        </action>
    </initialSubmissionActions>
    <label>JOB de solicitações de investimentos</label>
```

Nenhuma outra linha do arquivo foi tocada: `approvalStep` (4 etapas), `entryCriteria` do processo e de cada etapa, `allowRecall`, `allowedSubmitters`, `recordEditability`, `finalApprovalActions`, `finalRejectionActions`, `recallActions`, `processOrder` — tudo idêntico ao que já estava ativo na org.

**Por que:** causa raiz identificada no design (`03-design.md`, seção 0 e 2) — o processo ativo que concentra quase todos os envios (ordem 2) não tinha ação de envio inicial, então o Job ficava em "Não Enviado" durante toda a aprovação em vez de "Pendente". `Status_Qualificacao` é o `FieldUpdate` que já existe no `Workflow` do objeto (grava `Status_da_Qualificaco__c = Pendente`) e que o outro processo ativo (`Aprova_o_JOB`) já usa do mesmo jeito — só estava faltando referenciá-lo aqui. Não foi criado nenhum componente novo.

---

## 2. Validação

### Comando

```
sf project deploy validate --target-org sbx-somos-agility-dev \
  --metadata "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento" \
  --test-level RunSpecifiedTests --tests ChangePasswordControllerTest
```

### Por que `--test-level RunSpecifiedTests --tests ChangePasswordControllerTest`

A primeira tentativa, sem `--test-level`, rodou a suíte Apex inteira da org (71 classes) por padrão e falhou — mas por motivos **pré-existentes e não relacionados a esta mudança**: cobertura de alguns triggers abaixo de 1%, cobertura média de 19% (abaixo dos 75% exigidos), e várias classes de teste quebradas por validações de campo obrigatório (telefone, DSA/CR/DEPV, `Conversao_de_Lead__c`) que não têm relação com `ApprovalProcess` nem com `Status_da_Qualificaco__c`. O componente alterado não é Apex, então não exige cobertura de teste — só é preciso rodar *algum* teste válido para satisfazer o parâmetro obrigatório do comando. `ChangePasswordControllerTest` foi escolhido por ser uma classe de teste padrão da plataforma (boilerplate de autenticação), sem relação com Job, aprovação ou financeiro, e que passa isoladamente.

### Resultado

```
Status: Succeeded
Deploy ID: 0AfHa00000Dzir3KAB
Changed  JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento  ApprovalProcess
Test Results Summary — Passing: 1, Failing: 0, Total: 1
```

Validação (check-only) **passou**. A plataforma aceitou a mudança num processo de aprovação ativo (risco R2 do design, mitigado — não foi preciso desativar/clonar o processo).

---

## 3. Deploy real em dev

**Decisão: sim, fiz o deploy real em `sbx-somos-agility-dev`** (além da validação), com o mesmo comando trocando `deploy validate` por `deploy start`:

```
sf project deploy start --target-org sbx-somos-agility-dev \
  --metadata "ApprovalProcess:JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento" \
  --test-level RunSpecifiedTests --tests ChangePasswordControllerTest
```

Resultado: `Status: Succeeded`, Deploy ID `0AfHa00000DzisfKAB`.

**Por quê:** dev é a sandbox onde os agentes constroem (`CLAUDE.md` do cliente); deixar o processo de aprovação de dev refletindo o que está no repositório evita que uma sessão futura (QA detalhando o roteiro, ou outro builder) encontre a org de dev divergente do que o git descreve. A mudança é de baixo risco (um `FieldUpdate` já existente, sem alteração de etapas/aprovadores) e já havia passado na validação check-only antes. Nenhum dado real foi tocado — a demanda não envolve DML em registros, só metadata.

Isso **não substitui** a etapa de QA: o roteiro de teste (seção 4 abaixo) continua previsto para `sbx-somos-agility-qa`, que é uma sandbox separada e não recebeu nenhum deploy desta sessão.

---

## 4. Roteiro de teste de alto nível (o `qa` detalha)

Já está descrito em `03-design.md`, seção 6. Resumo, a ser executado em `sbx-somos-agility-qa` com Job de teste, sem dado real (guardrail #2):
1. Criar Job com usuário que entra no processo de ordem 2 → status inicial "Não Enviado".
2. Enviar para aprovação → status deve virar "Pendente" (critério novo desta correção). Conferir que `Status_Previs_o_de_Gastos__c` não mudou (R4 do design).
3. Aprovar → "Aprovado"; rejeitar (em outro Job) → "Rejeitado"; reenviar o rejeitado → "Pendente" de novo.
4. Conferir o relatório `JOBs_de_Investimento_HsY` e o dashboard "Controle Financeiro": o Job de teste aparece no grupo do status atual, contagem do dashboard bate com a do relatório.
5. Regressão: o lookup `Relacionado_ao_Job__c` em lançamento de despesa continua só aceitando Job aprovado.
6. Prints só do registro de teste, nunca de dado real.

---

## 5. Fora de escopo deste build (explícito, para quem revisar o PR)

- **Mudança no Report `Financeiro/JOBs_de_Investimento_HsY`** (janela `timeFrameFilter`) — condicionada a **G2**, pergunta de negócio ao financeiro ainda **sem resposta** em `comentarios-do-card.md`. Nenhum arquivo de `reports/` foi tocado nesta sessão.
- **Correção de dados já em aprovação** (Jobs hoje em "Não Enviado"/"Rejeitado" que deveriam estar "Pendente") — **G3**, decisão do cliente, fora da esteira (é DML em dados de produção, proibido ao agente — guardrail #1). A mudança desta demanda só vale para envios feitos **depois** do deploy em cada ambiente.
- **G4, bloqueante no design e ainda sem registro de checagem: ninguém confirmou que produção está igual a dev.** O diagnóstico (falta de ação de envio inicial) foi feito e corrigido só em `sbx-somos-agility-dev`. Se produção já tiver essa ação de envio inicial configurada, a causa raiz seria outra e este build não resolveria a queixa do financeiro lá. **Quem revisar este PR: confirme com o cliente, antes de levar esta mudança para QA/produção, que alguém olhou em Setup > Processos de Aprovação > "JOB de solicitações de investimentos" em produção e viu a mesma ausência de "Ações de Envio Inicial".** Não há esse registro em nenhum artefato desta demanda até agora.
- Os 4 processos de aprovação inativos e a regra de workflow inativa do objeto — não tocados, de propósito.
- O processo ativo `Aprova_o_JOB` — não tocado; foi só recuperado temporariamente nesta sessão para confirmar a posição correta de `<initialSubmissionActions>` no XML, e removido do disco sem entrar no commit.
- Os outros ~244 processos de aprovação (de outros objetos) e os outros 44 relatórios de Job/Investimento mencionados no design — fora do escopo, não abertos nem revisados além do que já constava em `02-recon.md`/`03-design.md`.

---

## 6. Commit e push

- Arquivos adicionados ao commit: o novo `force-app/main/default/approvalProcesses/JOB_de_Solicita_o_de_Investimento__c.JOB_de_solicitacoes_de_investimento.approvalProcess-meta.xml` e este `04-plano-build.md`.
- Nenhum outro arquivo do índice (as mudanças já staged em `CLAUDE.md`, `src/salesforce_agents/ao_vivo.py`, `src/salesforce_agents/orchestrator.py`, `src/salesforce_agents/sessao.py` são de outra sessão/demanda e não foram tocadas nem incluídas aqui).
- Push para `origin feature/SOMOSAGILITY-22` — atualiza o PR já aberto pela esteira, sem abrir um novo.
