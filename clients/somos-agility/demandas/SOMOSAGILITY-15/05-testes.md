# 05 — Testes: SOMOSAGILITY-15 — Layout de página inicial

**Resultado desta etapa (refeita contra a sandbox correta): QA não executado. Não há build para testar.**

Esta sessão refaz do zero a checagem de QA, depois de Leonardo Barbosa apontar que a sessão
de QA anterior (28/10) tinha rodado contra `sbx-somos-agility-dev` em vez de
`sbx-somos-agility-qa`, por um defeito do `run-demand.yml` já corrigido no PR #121. Conferi
com os próprios olhos, nesta sessão, qual org está conectada e refiz as verificações — não
copiei a conclusão do artefato anterior sem checar.

## 0. Confirmação do ambiente desta sessão

- `sf org list` nesta sessão mostra **uma única org conectada: `sbx-somos-agility-qa`**
  (Org Id `00DHa000006WcTcMAK`, status `Connected`). Não há `sbx-somos-agility-dev`
  disponível nesta sessão — a checagem abaixo é, portanto, necessariamente contra a
  sandbox de QA, o que resolve o defeito que motivou o reteste.

## 1. O que foi conferido nesta sessão, antes de montar qualquer roteiro

1. **Cadeia de artefatos completa**, na ordem pedida: `demanda.md`,
   `comentarios-do-card.md`, `01-analise.md`, `02-recon.md`, `03-design.md` (incluindo o
   adendo de 2026-10-27), `04-plano-build.md`, `gates.md`, e o `05-testes.md` anterior (lido
   com espírito crítico, não copiado).

2. **`status.yaml`**: histórico mostra que, depois do QA anterior ter rodado na sandbox
   errada, Leonardo Barbosa devolveu a demanda de `aguardando_homologacao` para
   `aguardando_gate_build` em 2026-10-30T01:23:37Z com o motivo registrado ("QA rodou na
   sandbox de dev... Volta para a revisão do PR para refazer o QA na sandbox de QA"),
   reaprovou o gate de build em 2026-10-30T03:56:02Z, e a demanda voltou a `qa` — estágio
   atual confirmado em disco (`status: qa`).

3. **`gates.md`**: o gate `aguardando_gate_build` tem **dois** registros de aprovação —
   2026-10-28T01:44:55Z e 2026-10-30T03:56:02Z — ambos sobre o **mesmo artefato e mesmo
   hash** (`04-plano-build.md`, sha256 `42c4f5a484af7cce`, 5956 bytes). Ou seja: o conteúdo
   do plano de build não mudou entre as duas aprovações. Conferido que o hash registrado
   bate com o arquivo em disco nesta sessão.

4. **`04-plano-build.md`**: continua registrando, sem alteração, que nenhuma branch foi
   criada, nenhum metadata foi escrito e nenhum deploy foi feito, porque as três condições
   da seção 0 do `03-design.md` (P1 em texto/print mapeado à tabela de componentes, P2
   respondida, matriz item×página preenchida pelo arquiteto) **não foram satisfeitas**.

5. **`comentarios-do-card.md`**, lido diretamente nesta sessão: agora tem **6** entradas
   (duas a mais que a checagem anterior, ambas "Equipe — aprovou o gate
   'aguardando_gate_build'", em 2026-10-28 e 2026-10-30 — refletindo a correção de estágio
   e a reaprovação acima). **Nenhuma das 6 entradas contém a lista de componentes (P1) nem
   responde ao escopo de perfis (P2).** Confirmado por leitura própria, não por confiança
   no relato anterior.

6. **Anexo PDF liberado** (`anexos/osj7bk-Layout-de-pagina-inicial-x-Paineis--.pdf`): abri o
   arquivo diretamente nesta sessão (o renderizador funcionou aqui, diferente da sessão de
   QA anterior que relatou falha de dependência). Confirmo com os próprios olhos: é um
   e-mail da Governança/PMO do cliente para a Agility Sistemas, pedindo a remoção de
   componentes da Home, com um print de tela anexado destacando em amarelo três elementos
   de uma página Home (um filtro de ordenação de lista/feed, um painel de negócios/
   oportunidades recentes, e um painel de desempenho trimestral) sobre uma org que parece
   vazia/demo (sem dado de cliente real visível nos elementos destacados). **Isso é
   consistente** com o que `03-design.md` (adendo) e `04-plano-build.md` já haviam
   registrado. Confirmo também, por leitura própria: **isso não é uma resposta formal e
   textual do cliente no card às pendências P1/P2** — é um e-mail anexado, não um comentário
   registrado respondendo à pergunta objetiva que o design faz ("qual item da tabela de
   componentes do recon cada elemento destacado corresponde, e qual o escopo de perfis").
   Conforme guardrail #2 (LGPD), **não transcrevo aqui** nome, e-mail, telefone ou endereço
   das pessoas citadas no e-mail — o parágrafo acima descreve sem reproduzir esses dados.

7. **Git, a partir da raiz do repositório**, para confirmar com os próprios olhos se existe
   metadata alterado nesta branch:
   - `git log --oneline -15`: commits mais recentes são os da própria esteira desta demanda
     (análise, design, build, qa, correção de estágio) — nenhum deles sugere, pelo nome, uma
     mudança de metadata de verdade.
   - `git show --stat 8d2d6b69` (o commit "build via CI (dev)"): toca só artefatos da
     demanda (`03-design.md`, `04-plano-build.md`, `gates.md`, `status.yaml`), telemetria de
     custo (CSV) e arquivos do orquestrador Python. **Nenhum arquivo sob `force-app/`.**
   - `git diff main..HEAD --stat -- force-app`: **saída vazia**. Repeti com `main` local
     (após `git fetch origin main`) e não apenas `origin/main`, já que o `...` three-dot
     falhou por falta de merge-base comum (`fatal: no merge base`) — provável efeito de
     clone raso (`git rev-parse --is-shallow-repository` confirma `true`). Com `git diff
     main..HEAD` (two-dot, que não depende de merge-base) a saída para `force-app` é
     igualmente vazia.
   - **Verificação mais forte que a da sessão anterior**: `git log --name-only main..HEAD --
     force-app` — lista todos os arquivos tocados sob `force-app/` em **todos** os commits
     que existem em `HEAD` e não em `main` (toda a história desta branch, não só o commit de
     build). **Saída vazia.** Nenhum commit desta branch, em nenhuma etapa da esteira (análise,
     design, build, qa), tocou `force-app/`.
   - Conclusão própria, não copiada: **não existe, em nenhum ponto da branch
     `feature/SOMOSAGILITY-15`, nenhuma alteração de `FlexiPage` ou qualquer outro
     metadata.** Não há nada deployado em `sbx-somos-agility-dev` nem em
     `sbx-somos-agility-qa` por esta demanda, e portanto nada a promover ou testar.

## 2. Por que não executo um roteiro mesmo assim

- Os critérios de aceite de `01-analise.md` (seção 4, Gherkin) são condicionados a um
  componente concreto ("Dado um componente X listado... Então o componente X não é
  exibido") e a um perfil concreto no escopo. P1 e P2 continuam sem resposta formal em
  texto no card, e a matriz item×página da seção 4 de `03-design.md` continua com
  `*pendente P1*` / `*pendente P2*`. Não existe "componente X" nem "perfil Y" verificável
  para montar um caso de teste sem inventar — o que o guardrail #3 proíbe.
- Abrir a aba Início em `sbx-somos-agility-qa` e registrar "está igual a antes" não
  verificaria nenhum critério de aceite — verificaria só que nada foi construído, o que já
  está provado pelo `git log --name-only` acima sem precisar abrir navegador. Rodar
  `qa_browser_*` aqui produziria uma evidência que parece teste mas não testa nada.
- A correção do defeito de sandbox (PR #121) resolve **onde** o QA roda, não **o que** há
  para rodar. Testar contra a sandbox certa não cria um build que não existe.

## 3. O que falta, e de quem é a próxima ação

Idêntico ao que `04-plano-build.md` e a sessão de QA anterior já registraram, porque nada
mudou na substância desde então — só o estágio da demanda foi corrigido (dev → qa) e o gate
de build foi reaprovado sobre o mesmo artefato:

1. Delivery conseguir da Governança/PMO do cliente a lista de componentes **em texto** no
   card (ou um print sem dado pessoal, liberado por delivery), mapeável item a item à tabela
   de componentes da seção 3 de `02-recon.md`. O e-mail anexo ao card **não cumpre** essa
   condição — é contexto, não resposta formal registrada.
2. Resposta registrada no card sobre o escopo de perfis (P2): "todos os usuários" = todos os
   perfis, ou uma lista específica.
3. O arquiteto preencher a matriz item × página × perfil da seção 4 de `03-design.md`,
   decidindo entre as interpretações A/B/C da seção 2 do design.

Só depois disso o build tem o que construir, e só depois de haver build o QA tem o que
testar — na sandbox de QA, que agora está confirmada como o ambiente correto para a etapa.

## 4. Tabela de casos (nenhum executado)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Qualquer cenário de `01-analise.md` seção 4 (componente X some da Início para perfil Y) | Requer componente X e perfil Y concretos, vindos da matriz item×página do design | Requer componente X e perfil Y concretos | Não aplicável — P1/P2 seguem sem resposta formal no card, matriz do design segue `*pendente*`, nenhum metadata alterado em nenhum commit da branch | **Não executável** |
| Componente removido continua acessível fora da Início | Mesma dependência acima | Mesma dependência acima | Não aplicável, mesma causa | **Não executável** |
| Perfil fora do escopo mantém a página como estava | Mesma dependência acima | Mesma dependência acima | Não aplicável, mesma causa | **Não executável** |
| Componentes não listados continuam visíveis | Mesma dependência acima | Mesma dependência acima | Não aplicável, mesma causa | **Não executável** |

Falha é falha e teria sido reportada primeiro se existisse — mas não há falha de produto
aqui, porque não há produto construído. Classificar isto como "passou" seria inventar
resultado; classificar como "falhou" atestaria um defeito que não existe no que foi
(não-)construído. O estado correto é **não testável na sandbox de QA hoje**, pelas razões
acima — e essa conclusão foi verificada de novo, nesta sessão, contra a sandbox certa, não
apenas herdada da sessão anterior.

## 5. Ação recomendada

A demanda está em `status: qa`, com a sandbox correta confirmada (`sbx-somos-agility-qa`) e
um artefato de build que continua dizendo, desde a primeira linha, que nada foi construído.
O problema que motivou o reteste (sandbox errada) está resolvido; o problema de fundo
(pendências P1/P2 do design) continua aberto e é anterior e independente dele. Recomendo que
delivery corrija o estágio da demanda de volta (`sfagents demanda avancar` permite correção
manual para trás sem exigir o artefato do estágio abandonado, guardrail #5) até, no mínimo,
`aguardando_gate_design` ou `design`, resolva P1/P2 no card com uma resposta formal em texto
(o e-mail anexo não conta como isso), acione o arquiteto para o adendo da matriz da seção 4,
e só então libere um novo ciclo de build — desta vez com algo real para o QA verificar.

---

QA refeito contra a sandbox correta (`sbx-somos-agility-qa`) nesta sessão — não há build
para testar, e essa conclusão foi verificada de novo, com os próprios olhos, e não apenas
herdada da sessão anterior. Pendências P1/P2 continuam abertas e a matriz item×página do
design nunca foi preenchida. Esta execução está encerrada; a próxima ação esperada é de
delivery/arquiteto: corrigir o estágio da demanda de volta para resolver P1/P2 e a matriz
antes de um novo ciclo de build. Não há release a liberar a partir do que existe hoje em
disco ou em sandbox.
