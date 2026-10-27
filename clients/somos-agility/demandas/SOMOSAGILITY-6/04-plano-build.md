# SOMOSAGILITY-6: Plano de build (builder-declarativo)

**Cliente:** Somos Agility. **Org alvo:** `sbx-somos-agility-dev` (sandbox, confirmada por
`sf org list` antes de qualquer alteração — `Status: Connected`).
**Branch:** `feature/SOMOSAGILITY-6` (reusada, sem sufixo de descrição — conforme
convenção real do repo).
**PR:** [#78 — "SOMOSAGILITY-6: acompanhamento da demanda"](https://github.com/lobarbosa/salesforce-agents/pull/78)
(já existia, aberto antes desta etapa; não foi aberto um PR novo). Estado: `OPEN`. Comentário
de build com o resumo e os riscos R-1/R-3 adicionado ao PR (sem username/e-mail).

Execução seguiu a seção 7 do `03-design.md`, aprovado no gate `aguardando_gate_design`
(Leonardo Barbosa, 2026-10-27T23:12:39Z, commit `7739bfc1`).

---

## O que foi criado/alterado

| Arquivo | Ação | Descrição |
|---|---|---|
| `clients/somos-agility/sfdx-project.json` | Criado | Estrutura SFDX mínima do cliente (ainda não existia). Mesmo formato de `clients/acxya/sfdx-project.json`, com `name: "somos-agility"` e `sourceApiVersion: "68.0"` (versão confirmada pela org via `sf org display`/recon). |
| `clients/somos-agility/force-app/main/default/approvalProcesses/FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1.approvalProcess-meta.xml` | Criado (retrieve) e depois alterado (1 linha) | Approval Process ativo do objeto `FluxoVendaProdutos__c`. Único nó alterado: `assignedApprover/approver/name` da etapa `Diretor_a_Comercial_Validacao_Fiscal`, trocando o username da Kelly pelo username do usuário "Sales Operation" (o mesmo já presente na etapa `GrupoOperacoesValidacaoFiscal` do mesmo arquivo — fonte confirmada pelo design, seção 1.1). `type` permanece `user`. Nada mais no arquivo foi tocado.

Nenhum outro componente (campo, objeto, Flow, classe, layout, e-mail template) foi criado
ou alterado — confere com a seção 2 do design ("Não há mudança de modelo de dados").
Os processos inativos `ValidacaoFiscal` e `ValidacaoCotacao_v_1_1` não foram tocados
(fora de escopo, seção 1.2/8 do design).

## Commits

1. **`1b48c6c6`** — `SOMOSAGILITY-6: trazer baseline do approval process ValidacaoFiscal_v_1_1`
   Retrieve puro da org (`sfdx-project.json` + XML do approval process tal como está hoje em
   produção/dev), sem nenhuma edição. Serve de baseline para o diff do commit seguinte.
2. **`11c8b979`** — `SOMOSAGILITY-6: trocar aprovador da etapa Diretor(a) Comercial de Kelly
   para Sales Operation`
   Diff de **uma linha** (confirmado visualmente com `git diff` antes do commit): só o
   `<name>` dentro de `assignedApprover/approver` da etapa
   `Diretor_a_Comercial_Validacao_Fiscal`.

Ambos commitados só com os arquivos desta demanda (`git commit -- <paths>`), sem tocar nas
mudanças de outros arquivos do repositório que já estavam staged na branch antes desta
sessão (não relacionadas a este build). Push feito com sucesso:
`7739bfc1..11c8b979  feature/SOMOSAGILITY-6 -> feature/SOMOSAGILITY-6`.

## Comandos `sf` rodados e resultados

| Comando | Resultado |
|---|---|
| `sf org list` | `sbx-somos-agility-dev` conectada (`Status: Connected`), confirmado como alvo antes de qualquer escrita. |
| `sf project retrieve start --metadata "ApprovalProcess:FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1" --target-org sbx-somos-agility-dev` | Sucesso (1x antes da edição, para baseline; 1x depois do deploy, para conferência). |
| `sf project deploy validate --target-org sbx-somos-agility-dev --source-dir force-app` (sem `--test-level`) | **Falhou**, mas não pelo motivo do risco R-2 do design. O CLI usa `RunLocalTests` por padrão quando nenhum nível de teste é informado, e essa org tem cobertura de teste Apex pré-existente de ~19% (vários testes legados já quebrados, nada relacionado a esta demanda) — abaixo dos 75% exigidos pela plataforma para esse nível. A etapa "Deploying Metadata" em si teve sucesso (1/1, 100%); quem bloqueou foi a etapa de testes. |
| `sf project deploy validate --target-org sbx-somos-agility-dev --source-dir force-app --test-level RunSpecifiedTests --tests fflib_AnswerTest` | **Sucesso.** Como o pacote implantado não contém nenhum Apex, a etapa de testes foi pulada (`Running Tests - Skipped`, `Passing: 0, Failing: 0, Total: 0`) e a validação (check-only) passou. Isso confirma que o **risco R-2 não se concretizou**: a Metadata API aceitou a alteração do aprovador numa etapa de processo ativo sem restrição. `fflib_AnswerTest` foi escolhido por ser um teste de framework sem DML em objetos de negócio, só para satisfazer a exigência de informar pelo menos uma classe em `RunSpecifiedTests` — não executou de fato. Deploy ID: `0AfHa00000E4vMDKAZ`. |
| `sf project deploy start --target-org sbx-somos-agility-dev --source-dir force-app --test-level RunSpecifiedTests --tests fflib_AnswerTest` | **Sucesso.** Deploy real na dev. Deploy ID: `0AfHa00000E4vNpKAJ`. `Status: Succeeded`, componente `Changed`. |
| `sf project retrieve start --metadata "ApprovalProcess:FluxoVendaProdutos__c.ValidacaoFiscal_v_1_1" --target-org sbx-somos-agility-dev` (conferência pós-deploy) | Sucesso. `git diff` contra o commit `1b48c6c6` (baseline) mostrou exatamente a mesma linha alterada e nenhuma diferença a mais — confirma que a etapa `Diretor_a_Comercial_Validacao_Fiscal` ficou com um único aprovador = usuário "Sales Operation" (`type = user`), igual ao que foi commitado. Não foi necessário um novo commit (sem diferença entre o retrieve e o que já estava no repo). |

## Ponto de atenção registrado, mas que **não bloqueou** o build

O primeiro `deploy validate` sem `--test-level` falhou por cobertura de teste Apex da org
(pré-existente, ~19% contra 75% exigido para `RunLocalTests`) — **não** é o risco R-2 do
design (restrição da Metadata API a mudanças em etapa/ação de processo ativo). Depois de
rodar com `--test-level RunSpecifiedTests` e uma classe de teste que não toca o pacote
implantado (sem Apex no pacote, então a checagem de cobertura nem se aplica), tanto o
`validate` quanto o `deploy` passaram sem nenhuma recusa ligada à alteração do approval
process em si. Não foi necessário parar e escalar ao arquiteto — a condição descrita na
seção 7.5 do design ("se der erro do tipo de R-2, parar e escalar") não ocorreu.

Fica registrado para quem fizer o deploy em QA/produção: a cobertura de teste legada da org
(~19%) é um achado à parte, fora do escopo desta demanda, que pode exigir `--test-level`
explícito em qualquer deploy futuro de metadata não-Apex nesta org.

## O que NÃO pôde ser confirmado / ressalvas

- **FLS do usuário de integração em `Status__c` (R-5)** — não foi testado nesta etapa
  (é escopo da etapa 5, QA). Confirmo apenas que não foi necessário para o deploy do
  Approval Process em si (metadata de `ApprovalProcess` não depende de FLS de campo).
- **R-3 (username por sandbox)** — os usernames usados (Kelly e Sales Operation) foram
  confirmados apenas na **dev**. Antes do deploy em QA, é preciso confirmar que ambos
  existem e estão ativos naquele ambiente, conforme o design pede — isso é responsabilidade
  da etapa de QA/release, não desta etapa de build.
- Nenhum username, e-mail ou outro dado de usuário foi escrito neste arquivo nem no
  comentário do PR — só nomes de exibição ("Kelly", "Sales Operation"). O username aparece
  apenas dentro do XML de metadata em `force-app/`, que é configuração técnica, conforme
  orientado.

## Confirmação final (lido do disco)

- `demandas/SOMOSAGILITY-6/04-plano-build.md` — este arquivo, presente em disco.
- `git log --oneline -5` confirma os dois commits desta etapa no topo da branch.
- `git push` concluído com sucesso (`7739bfc1..11c8b979`).
- PR #78 segue `OPEN`, sem merge (nenhum merge foi feito, conforme guardrail).

## Bloqueios pendentes

**Nenhum.** O build foi concluído de ponta a ponta conforme o design aprovado, sem
necessidade de escalar ao arquiteto. R-1 (segregação de funções) e P-5 (itens pendentes
em produção) seguem como decisões de negócio já registradas no design — não são bloqueio
técnico desta etapa, apenas pontos que QA/release precisam carregar adiante.
