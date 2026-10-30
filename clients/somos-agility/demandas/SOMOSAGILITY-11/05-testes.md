# SOMOSAGILITY-11 — Testes (QA)

**Etapa:** 5 (testes) · **Autor:** agente `qa` · **Data:** 2026-10-30
**Resultado desta etapa: TESTES CONTINUAM BLOQUEADOS. Nenhum roteiro foi executado contra
nenhuma org, porque não existe nenhum componente construído para testar — mesmo com a org
de QA correta agora conectada.**

---

## 0. Por que esta sessão existe e o que mudou desde 2026-10-25

Entre a sessão de QA de 2026-10-25 e esta, foi corrigido um defeito do `run-demand.yml`
(PR #121) que fazia a etapa `qa` rodar contra a sandbox de **dev** em vez da de **qa**. A
sessão anterior já havia registrado que `sbx-somos-agility-qa` não aparecia conectada e,
por isso, não testou nada — nem contra dev, por recusa deliberada de substituir o ambiente
errado. Esta sessão foi disparada especificamente para refazer a confirmação na sandbox
correta (`gates.md`: gate `aguardando_gate_build` aprovado de novo por Leonardo Barbosa em
2026-10-30T04:12:32, revisando o mesmo `04-plano-build.md` que registra o build bloqueado).

**Confirmado nesta sessão:** `sf org list` retorna desta vez a org esperada:

```
Type     Alias                 Status
Sandbox  sbx-somos-agility-qa  Connected
```

Só `sbx-somos-agility-qa` aparece — é exatamente o alias esperado para a etapa `qa`
(guardrail #1). Diferente da sessão de 2026-10-25, a org correta está acessível agora. Isso
resolve o problema de ambiente da sessão anterior, mas **não** resolve o motivo real do
bloqueio, que nunca foi o ambiente — foi a ausência de build.

## 1. Confirmação, nesta sessão, de que não há build para testar

1. **Nenhum `force-app` para somos-agility no repositório.**
   `find . -iname "force-app"` (raiz do repo) retorna só `./clients/acxya/force-app`.
   Não existe pasta de metadata para somos-agility em lugar nenhum da árvore.

2. **Nenhum commit de metadata na branch.**
   `git log --oneline feature/SOMOSAGILITY-11 -- clients/somos-agility` mostra só commits
   de artefatos de demanda e de materialização de status (análise, design, plano de build,
   estimativa, "via CI", "qa via CI (dev)", "voltar para a revisão do PR") — nenhum commit
   altera metadata do cliente.

3. **`git show --stat` do commit de build (`1ebd823d`, "SOMOSAGILITY-11: build via CI
   (dev)")** confirma que os arquivos alterados são: `04-plano-build.md`, o anexo `.xlsx`,
   `comentarios-do-card.md`, `gates.md`, `status.yaml`, um CSV de telemetria de custo, e
   infraestrutura do próprio pipeline (`src/salesforce_agents/*.py`, `.claude/agents/*.md`,
   `.claude/skills/*`, `CLAUDE.md`) — nada em `force-app` de nenhum cliente.

4. **`git status` nesta sessão** mostra apenas alterações em `gates.md` e `status.yaml`
   (histórico de gate/transição, escrito pelo mecanismo da esteira) e num arquivo de skill
   fora do escopo desta demanda — nenhuma mudança de metadata pendente.

5. **`gh pr list --head feature/SOMOSAGILITY-11`** não pôde ser confirmado via `gh` neste
   runner (`GH_TOKEN` ausente, mesma limitação já registrada na sessão de 2026-10-25). Não
   muda a conclusão: o histórico de commits já é evidência suficiente de que não há
   mudança de metadata para revisar em PR nenhum.

**Conclusão: o relato de `04-plano-build.md` ("BUILD BLOQUEADO. Nenhum componente foi
criado...") continua verdadeiro hoje.** Não foi assumido o relato do agente anterior — foi
reconfirmado de ponta a ponta nesta sessão.

## 2. `comentarios-do-card.md` — perguntas de negócio ainda sem resposta

Reli `comentarios-do-card.md` procurando resposta às perguntas B-1 a B-5 de `03-design.md`
§7.1 e decisão sobre os riscos R1/R2. O arquivo tem 6 entradas, todas registros mecânicos
de aprovação de gate/estimativa/fila da esteira:

| Data | Conteúdo |
|---|---|
| 2026-10-16 16:20 | Aprovou gate `aguardando_gate_analise` |
| 2026-10-21 01:19 | Aprovou gate `aguardando_gate_design` |
| 2026-10-21 01:47 | Aprovou gate `aguardando_gate_design` (fila) |
| 2026-10-21 17:13 | Aprovou estimativa de 3 h |
| 2026-10-25 01:05 | Aprovou gate `aguardando_gate_build` (fila) |
| 2026-10-30 02:34 | Aprovou gate `aguardando_gate_build` (fila) |

**Nenhuma resposta textual de negócio** a B-1 (objeto alvo), B-2 (entrega/chave/volume da
planilha), B-3 (valores novos de picklist), B-4 (decisão sobre R1 — e-mails em massa) ou
B-5 (decisão sobre R2 — recálculo de CIF/FOB). A aprovação repetida do gate de build em
2026-10-30 é aprovação do **processo** (reabrir a revisão do PR para refazer o QA na
sandbox certa — motivo registrado em `status.yaml`), não uma resposta às cinco perguntas.
Isso é coerente com o que `status.yaml` documenta: a transição de 2026-10-30 teve como
motivo explícito corrigir o ambiente de QA, não destravar o build.

O anexo `demandas/SOMOSAGILITY-11/anexos/x39f1n-CONTROLE-LOGISITCA---DSA.xlsx` segue
presente na pasta. Tentei `Read` novamente nesta sessão e recebi o mesmo erro das sessões
anteriores: "This tool cannot read binary files. The file appears to be a binary .xlsx
file." Não há, nesta sessão, ferramenta de documento (`spec_read`) disponível, e mesmo que
houvesse, ela é documentada como sem suporte a `.xlsx` (só `.md`/`.pdf`/`.docx`). Não
tentei contornar com script/unzip/parser manual, por instrução explícita. O anexo continua
**não lido**, e B-1/B-2/B-3 continuam sem resposta por essa via também.

**Nenhum fato novo.** Nada mudou desde `04-plano-build.md`: as cinco perguntas de negócio
seguem abertas, os dois riscos Alta seguem sem decisão, e o anexo segue ilegível pelas
ferramentas disponíveis.

## 3. Critérios de aceite de `01-analise.md` — por que não são testáveis agora

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Campo de status de logística existe no objeto alvo | N/A — exigiria abrir um registro do objeto alvo confirmado em `sbx-somos-agility-qa` e checar visibilidade do campo no layout | Campo "Status de Logística" visível no layout apropriado | **Não executável**: o objeto alvo (`DSA__c` vs. `Novo_DSA__c`, pergunta B-1) não foi confirmado por negócio, e nenhum componente foi criado ou alterado por este build | **BLOQUEADO** |
| Carga em massa aplica o status corretamente | N/A — exigiria CSV de origem com chave de cruzamento confirmada e uma carga real em sandbox | Cada registro da planilha reflete o status correspondente; nenhum registro fora da lista é alterado | **Não executável**: não há carga nenhuma, planilha segue ilegível (B-2), nenhum ambiente recebeu a mudança | **BLOQUEADO** |
| Carga em massa não quebra registros existentes | N/A — exigiria massa fictícia cobrindo R1 (notificação)/R2 (recálculo CIF-FOB) e comparação campo a campo antes/depois | Nenhum outro campo além do status é alterado | **Não executável**: além de não haver carga, os riscos R1 e R2 de `03-design.md` seguem sem decisão de negócio (B-4, B-5) — são justamente o tipo de "quebra" que este critério pretende cobrir | **BLOQUEADO** |

Não escrevi passo a passo de UI nem usei `qa_browser_*` para nenhum destes três cenários:
abrir a sessão de navegador contra um objeto/campo que não existe (ou que não foi
confirmado como alvo) produziria, na melhor hipótese, evidência de um estado atual da org
que nada tem a ver com esta demanda, e na pior, ficção de teste — o que a instrução desta
etapa proíbe explicitamente.

## 4. O que esta etapa fez e não fez

- **Fez:** confirmou via `sf org list` que `sbx-somos-agility-qa` está conectada (a org
  correta desta vez); confirmou via `find`/`git log`/`git show`/`git status` que continua
  não existindo `force-app` nem diff de metadata para somos-agility nesta branch; releu
  `01-analise.md`, `03-design.md`, `04-plano-build.md`, `comentarios-do-card.md`,
  `gates.md` e `status.yaml`; tentou novamente ler o anexo `.xlsx` e confirmou a mesma
  limitação das sessões anteriores.
- **Não fez (deliberadamente):** não rodou nenhum deploy, DML, Apex anônimo ou SOQL contra
  nenhuma org; não abriu sessão de navegador contra nenhuma org (nada foi construído para
  testar na UI); não escreveu roteiro de teste para funcionalidade inexistente; não
  inventou "testei e passou" para nenhum dos três critérios de aceite.

## 5. O que precisa acontecer para destravar

Igual ao que `04-plano-build.md` já registra, sem mudança:

1. Alguém de delivery/consultor (Juliana Mendes) responder B-1 a B-5 de `03-design.md`
   §7.1 — em especial confirmar o objeto alvo e entregar o conteúdo da planilha em formato
   legível (CSV/texto) ou resumido em comentário do card, sem colunas de dado pessoal.
2. O arquiteto humano (e negócio) decidir R1 (e-mails em massa) e R2 (recálculo CIF/FOB).
3. Uma sessão de build real criar o(s) componente(s)/rodar a carga em
   `sbx-somos-agility-dev` com massa fictícia cobrindo os cenários descritos em
   `03-design.md` §8.
4. O release levar essa mudança até `sbx-somos-agility-qa`.
5. Só então uma sessão de `qa` monta e executa o roteiro real (e, quando aplicável, usa
   `qa_browser_*`) contra os três critérios de aceite de `01-analise.md`.

Sem esses passos, qualquer "teste" registrado aqui seria inventado.

---

Testes não executados — etapa segue bloqueada antes de qualquer teste, pela mesma causa
raiz da sessão de 2026-10-25 (ausência de build), agora reconfirmada com a org de QA
correta conectada. O defeito de ambiente do `run-demand.yml` (PR #121) está corrigido, mas
não é ele que impede o teste — é a falta de resposta às perguntas de negócio B-1 a B-5 e de
decisão sobre os riscos R1/R2 em `03-design.md`. Preciso da sua decisão para destravar
(seção 5) antes de qualquer homologação ou release.
