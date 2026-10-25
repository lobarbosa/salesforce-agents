# SOMOSAGILITY-11 — Testes (QA)

**Etapa:** 5 (testes) · **Autor:** agente `qa` · **Data:** 2026-10-25
**Resultado desta etapa: TESTES BLOQUEADOS. Nenhum roteiro foi executado contra nenhuma
org, porque não existe nenhum componente construído para testar e a org de QA não está
acessível nesta sessão.**

---

## 0. Por que este artefato não é um relatório de testes

Chegar à etapa `qa` pressupõe que algo foi construído e implantado em sandbox. Verifiquei
as duas pontas antes de montar qualquer roteiro — nenhuma se confirma:

1. **Não há build.** `04-plano-build.md` já registra, de forma explícita, que o agente
   `builder-declarativo` não criou nenhum componente, não abriu PR com mudança nenhuma e
   não tocou em nenhuma org, porque faltavam respostas de negócio (B-1 a B-5) e decisão
   sobre dois riscos (R1, R2) marcados como bloqueantes em `03-design.md`. Confirmei isso
   eu mesmo nesta sessão (não assumi o relato do agente anterior):
   - `find . -iname "force-app"` no repositório inteiro só retorna
     `clients/acxya/force-app` — **não existe `force-app` para `somos-agility`**, ou
     seja, não há nenhuma metadata versionada deste cliente para começar.
   - `git log --oneline feature/SOMOSAGILITY-11 -- clients/somos-agility` mostra só
     commits de artefatos de demanda (análise, design, plano de build, estimativa,
     "sessão via CI") — nenhum commit de metadata.
   - `git show --stat` dos dois commits mais recentes da branch (`1ebd823d`,
     `d3d7fe4d`) confirma que os arquivos alterados são `04-plano-build.md`,
     `comentarios-do-card.md`, `gates.md`, `status.yaml`, o anexo `.xlsx` e arquivos de
     infraestrutura do próprio pipeline (`src/salesforce_agents/*.py`,
     `.claude/agents/*.md`, `CLAUDE.md`) — nada em `force-app` de nenhum cliente.
   - `gh pr list --head feature/SOMOSAGILITY-11` não pôde ser confirmado via `gh` (o
     ambiente de CI não tem `GH_TOKEN` configurado para o `gh` CLI: "To use GitHub CLI
     in a GitHub Actions workflow, set the GH_TOKEN environment variable"). Isso não
     muda a conclusão acima — o histórico de commits da própria branch já é evidência
     suficiente de que nenhuma metadata foi adicionada ou alterada.

2. **A org de QA não está acessível nesta sessão.** `sf org list` retorna apenas:

   ```
   Type     Alias                  Status
   Sandbox  sbx-somos-agility-dev  Connected
   ```

   `sbx-somos-agility-qa` não aparece conectada. A etapa `qa` da esteira deveria rodar
   contra QA (`ambientes.ambiente_do_estagio("qa") == "qa"`, alias esperado
   `sbx-somos-agility-qa`, guardrail #1). Sem essa org conectada, não há onde executar
   nenhum teste de UI nem nenhuma query de verificação — e, mesmo que houvesse, não
   haveria o que verificar, porque nada foi construído (item 1).

   Por instrução explícita e por doutrina (guardrail #1 e "falhar alto em vez de
   contornar"), **não testei contra `sbx-somos-agility-dev` fingindo que é QA**. Isso
   violaria a separação de ambiente da esteira mesmo que, neste caso, não houvesse nada
   para testar nela de qualquer forma.

3. **O gate anterior foi aprovado sabendo do bloqueio.** `gates.md` registra que o gate
   `aguardando_gate_build` foi aprovado por Leonardo Barbosa em 2026-10-25T01:22:59,
   revisando exatamente `04-plano-build.md` — o artefato cujo conteúdo é "build
   bloqueado". `status.yaml` confirma a mesma transição (`aguardando_gate_build` →
   `qa`, autor Leonardo Barbosa, mesmo timestamp). Isto não é um erro desta sessão nem
   do agente anterior: é um fato do histórico, registrado aqui para que a homologação
   humana decida com essa informação em mãos, não às cegas.

## 1. O que foi conferido nesta sessão (evidência, não opinião)

| Verificação | Comando | Resultado |
|---|---|---|
| Orgs conectadas | `sf org list` | Só `sbx-somos-agility-dev` (Connected). `sbx-somos-agility-qa` ausente. |
| Metadata do cliente no repo | `find . -iname "force-app"` | Só `clients/acxya/force-app` existe; nenhum `force-app` para somos-agility. |
| Diff de metadata na branch | `git log --oneline feature/SOMOSAGILITY-11 -- clients/somos-agility` | Só commits de artefatos de demanda/pipeline, nenhum de metadata. |
| Conteúdo dos 2 últimos commits | `git show --stat 1ebd823d` / `d3d7fe4d` | Arquivos alterados: artefatos da demanda, anexo `.xlsx`, infraestrutura `src/salesforce_agents/*` e `.claude/*` — nada em `force-app`. |
| PR aberto para a branch | `gh pr list --head feature/SOMOSAGILITY-11` | `gh` não autentica neste runner (`GH_TOKEN` ausente) — não confirmável por essa via; o histórico de commits já é evidência suficiente de que não há mudança de metadata para revisar em PR nenhum. |
| Status da demanda | `status.yaml` | `status: qa`, histórico mostra `aguardando_gate_build → qa` aprovado por Leonardo Barbosa em 2026-10-25. |
| Gate revisado | `gates.md` | Gate de build aprovou apenas `04-plano-build.md` (hash bate), artefato que diz "build bloqueado". |

Nenhuma destas verificações envolveu DML, deploy, Apex anônimo ou SOQL com dado de
cliente — todas foram leitura de git/arquivo local e `sf org list` (metadata de conexão,
não dado de negócio).

## 2. Critérios de aceite de `01-analise.md` — por que não são testáveis agora

Os três cenários Gherkin de `01-analise.md` exigem, nesta ordem, coisas que ainda não
existem:

1. "Campo de status de logística existe no objeto alvo" — **não testável**: o objeto
   alvo (`DSA__c` vs. `Novo_DSA__c`, pergunta B-1) não foi confirmado, e nenhum campo foi
   criado.
2. "Carga em massa aplica o status corretamente" — **não testável**: não há carga, não
   há CSV de origem confirmado (pergunta B-2, planilha ainda ilegível nesta sessão — ver
   `04-plano-build.md` §2), e não há ambiente de dev com o campo criado para aplicar
   nada.
3. "Carga em massa não quebra registros existentes" — **não testável** pelo mesmo
   motivo do item 2, mais os riscos R1/R2 ainda não decididos (notificação em massa e
   recálculo de CIF/FOB), que são exatamente o tipo de "quebra" que este critério
   pretende cobrir.

Não escrevi passo a passo de UI para nenhum destes três porque um roteiro contra um
campo/objeto/automação inexistente seria ficção, não teste — e a instrução desta etapa é
explícita em proibir isso ("sem roteiro de teste fictício, sem 'testei e passou'
inventado").

## 3. O que precisa acontecer para destravar a etapa de testes

Depende, nesta ordem, do que já está documentado em `04-plano-build.md` §3:

1. Responder B-1 a B-5 e decidir R1/R2 (pendências de negócio e de risco — ver
   `04-plano-build.md` para o detalhe de cada uma).
2. Uma sessão de build real criar o(s) componente(s) e rodar a carga em
   `sbx-somos-agility-dev` com massa fictícia.
3. O release levar essa mudança até `sbx-somos-agility-qa`.
4. A próxima sessão de `qa` rodar com `sbx-somos-agility-qa` conectada (hoje só `dev`
   aparece em `sf org list` nesta sessão) e, só então, montar e executar o roteiro real
   contra os três critérios de aceite de `01-analise.md`.

Sem os quatro passos acima, qualquer "teste" registrado aqui seria inventado.

## 4. O que esta etapa fez e não fez

- **Fez:** confirmou via `sf org list` que só `sbx-somos-agility-dev` está conectada;
  confirmou via `find`/`git log`/`git show` que não existe nenhum `force-app` nem diff
  de metadata para somos-agility nesta branch; tentou (sem sucesso, por limitação do
  ambiente) confirmar PR aberto via `gh`; releu `01-analise.md`, `03-design.md`,
  `04-plano-build.md`, `gates.md`, `status.yaml` e `comentarios-do-card.md`.
- **Não fez (deliberadamente):** não rodou nenhum deploy, DML, Apex anônimo ou SOQL
  contra nenhuma org; não abriu sessão de navegador contra nenhuma org (não há
  Lightning para testar — nada foi construído, e a org de QA não está acessível); não
  escreveu roteiro de teste para funcionalidade inexistente; não testou contra
  `sbx-somos-agility-dev` como substituto da org de QA.

**Testes bloqueados. Esta demanda precisa, primeiro, que o build de fato aconteça (o que
por sua vez depende de B-1 a B-5 e R1/R2 — ver `04-plano-build.md`) e, segundo, que uma
sessão de QA rode com `sbx-somos-agility-qa` conectada, antes que qualquer teste real
possa ser executado ou homologado.**

---

Testes não executados — etapa bloqueada antes de qualquer teste. Preciso da sua decisão
para destravar (ver seção 3) antes de qualquer homologação ou release.
