# 05 — Testes: SOMOSAGILITY-15 — Layout de página inicial

**Resultado desta etapa: QA não executado. Não há build para testar.**

Esta sessão não produziu nenhum roteiro executado contra `sbx-somos-agility-dev` ou
`sbx-somos-agility-qa`, porque não existe, em nenhuma das duas sandboxes, metadata
alterado por esta demanda. Testar a tela hoje provaria exatamente nada: não há mudança
de `FlexiPage` para verificar, e "abrir a Início e ver se está igual a antes" não é um
critério de aceite — os critérios de `01-analise.md` são sobre um componente específico
deixar de aparecer, e esse componente nunca foi identificado em texto.

## O que foi conferido nesta sessão, antes de montar qualquer roteiro

1. **Cadeia de artefatos completa**, na ordem pedida: `demanda.md`,
   `comentarios-do-card.md`, `01-analise.md`, `02-recon.md`, `03-design.md` (incluindo o
   adendo de 2026-10-27), `04-plano-build.md`, `gates.md`.
2. **`gates.md`**: o gate `aguardando_gate_build` foi aprovado por Leonardo Barbosa em
   2026-10-28T01:44:55Z, tendo `04-plano-build.md` (sha256 `42c4f5a484af7cce`) como único
   artefato revisado. Conferido que o hash registrado bate com o arquivo em disco nesta
   sessão (mesmo conteúdo). Ou seja: o que foi aprovado é, literalmente, o documento que
   diz "nenhuma branch foi criada, nenhum metadata foi escrito e nenhum deploy foi feito" e
   termina com "Build não liberado. Próxima ação é humana, não de agente."
3. **`04-plano-build.md`**: registra que as três condições de liberação da seção 0 do
   design (P1 em texto/print mapeado, P2 respondida, matriz item×página preenchida pelo
   arquiteto) seguem **não satisfeitas**, com evidência linha a linha contra
   `comentarios-do-card.md` (4 entradas, nenhuma traz a lista nem responde ao escopo de
   perfis).
4. **`comentarios-do-card.md`**, lido diretamente nesta sessão: confirma as mesmas 4
   entradas que o build relatou — aviso do anexo (19/10), aprovação de estimativa (21/10),
   aprovação do gate de análise (21/10), aprovação do gate de design (27/10), e, no
   histórico de `status.yaml`, a aprovação do gate de build (28/10). Nenhuma delas contém a
   lista de componentes nem resposta a "todos os usuários = todos os perfis?".
5. **Anexo PDF liberado** (`anexos/osj7bk-Layout-de-pagina-inicial-x-Paineis--.pdf`):
   tentei abrir para ter contexto completo. Nesta sessão o renderizador de PDF por página
   não está disponível no ambiente (dependência de sistema ausente), então não consegui
   nem a visualização que a sessão de build relatou ter conseguido. Isso não muda nada: o
   próprio `03-design.md` e `04-plano-build.md` já registram, de forma consistente, que a
   lista real é uma imagem embutida sem texto extraível, que o indício visual que o build
   viu ("Classificar por", "Principais negócios - Oportunidades recentes", "Desempenho
   trimestral") é explicitamente **não uma resposta formal do cliente** e **não foi usada
   para decidir nada**, e que isso não é fonte válida para critério verificável de teste
   (guardrail #2/#3 — não transcrevo esse conteúdo aqui nem o uso para montar casos).
6. **Git**, na raiz do repositório, para confirmar com os próprios olhos (não só
   confiando no relato do build):
   - `git log --oneline -5`: o commit mais recente é `8d2d6b69 SOMOSAGILITY-15: build via
     CI (dev)`.
   - `git show --stat 8d2d6b69`: toca só artefatos da demanda (`03-design.md`,
     `04-plano-build.md`, `gates.md`, `status.yaml`), um CSV de telemetria de custo, e
     arquivos de infraestrutura do orquestrador (`assessment.py`, `orchestrator.py`,
     `planejamento.py`, `sessao.py`). **Nenhum arquivo sob `force-app/` aparece nesse
     commit.**
   - `git diff origin/main...HEAD --stat -- force-app`: **saída vazia**. A branch
     `feature/SOMOSAGILITY-15` não tem nenhuma diferença de metadata (`force-app/`) em
     relação a `main`.
   - Conclusão própria, não copiada: não há nenhum commit, em nenhum ponto desta branch,
     que tenha alterado qualquer `FlexiPage` ou outro metadata. Não há nada deployado em
     `sbx-somos-agility-dev` por esta demanda, e portanto nada a promover ou testar em
     `sbx-somos-agility-qa`.

## Por que não executo um roteiro mesmo assim

- Os critérios de aceite de `01-analise.md` são condicionados a um componente concreto
  ("Dado um componente X listado... Então o componente X não é exibido") e a um perfil
  concreto no escopo. Sem P1 e P2 resolvidas e sem a matriz item×página do design (seção
  4, ainda com `*pendente P1*`/`*pendente P2*`), não existe "componente X" nem "perfil Y"
  para testar — eu estaria inventando o próprio caso de teste, o que viola o mesmo
  guardrail #3 que travou a análise, o design e o build.
- Abrir a Início em `sbx-somos-agility-dev` ou `sbx-somos-agility-qa` e registrar "está
  igual a antes" não verifica nenhum critério de aceite — verifica só que nada foi
  construído, o que já está provado pelo `git diff` acima sem precisar abrir navegador.
  Rodar `qa_browser_*` aqui produziria uma evidência que parece teste mas não testa nada,
  o oposto do que o método deste papel pede ("testar o código contra ele mesmo não prova
  nada" — aqui nem há código/config a testar).
- Não há diferença entre dev e qa para este caso: nenhuma das duas sandboxes recebeu
  deploy desta demanda.

## O que falta, e de quem é a próxima ação

Idêntico ao que `04-plano-build.md` já registrou, porque nada mudou desde então:

1. Delivery conseguir da Governança/PMO do cliente a lista de componentes **em texto** no
   card (ou um print sem dado pessoal, liberado por delivery), mapeável item a item à
   tabela de componentes da seção 3 de `02-recon.md`.
2. Resposta registrada no card sobre o escopo de perfis (P2): "todos os usuários" = todos
   os perfis, ou uma lista específica.
3. O arquiteto preencher a matriz item × página × perfil da seção 4 de `03-design.md`,
   decidindo entre as interpretações A/B/C da seção 2 do design.

Só depois disso o build tem o que construir, e só depois de haver build o QA tem o que
testar.

## Tabela de casos (nenhum executado)

| Caso | Passos | Esperado | Obtido | Status |
|---|---|---|---|---|
| Qualquer cenário de `01-analise.md` seção 4 | Requer componente X e perfil Y concretos | Requer componente X e perfil Y concretos | Não aplicável — P1/P2 não resolvidas, nenhum metadata alterado | **Não executável** |

Falha é falha e teria sido reportada primeiro se existisse — mas não há falha de produto
aqui, porque não há produto construído. Classificar isto como "passou" seria inventar
resultado; classificar como "falhou" atestaria um defeito que não existe no que foi
(não-)construído. O estado correto é **não testável nesta sandbox hoje**, pelas razões
acima.

## Ação recomendada

A demanda está em `status: qa` com um artefato de build (`04-plano-build.md`) que diz,
na própria primeira linha, que nada foi construído, e um gate de build aprovado sobre
esse mesmo artefato. QA não pode homologar o que não existe. Recomendo que delivery
corrija o estágio da demanda de volta (`sfagents demanda avancar` permite correção manual
para trás sem exigir o artefato do estágio abandonado, conforme guardrail #5 do CLAUDE.md
raiz) até, no mínimo, `aguardando_gate_design` ou `design`, resolva P1/P2 no card, acione
o arquiteto para o adendo da matriz, e só então libere um novo ciclo de build.

---

QA não pôde ser executado — não há build para testar. Pendências P1/P2 continuam abertas
e a matriz item×página do design nunca foi preenchida. Preciso que delivery decida se
corrige o estágio da demanda de volta para resolver isso antes de prosseguir; não há
release a liberar a partir do que existe hoje em disco ou em sandbox.
