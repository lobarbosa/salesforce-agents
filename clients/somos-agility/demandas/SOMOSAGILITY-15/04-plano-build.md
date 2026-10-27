# 04 — Plano de build: SOMOSAGILITY-15 — Layout de página inicial

**Tipo:** sustentação (design enxuto)
**Base:** `03-design.md`, gate aprovado por Leonardo Barbosa em 2026-10-27T23:49:57Z (ver `gates.md`,
hashes de `02-recon.md` e `03-design.md` conferem com o disco nesta sessão).
**Branch:** `feature/SOMOSAGILITY-15` (já existente, reutilizada — nenhuma branch nova foi criada
nesta sessão).

## Resultado desta tentativa: build não executado

Esta sessão tentou iniciar a etapa de build e **não produziu metadata nenhum**. Nenhum componente foi
criado, alterado ou removido em `force-app/`, nenhum `sf project deploy start` foi executado contra
`sbx-somos-agility-dev` ou qualquer outra org, e nenhum commit de metadata foi feito. O que segue é o
registro do que foi conferido e por que o build não avançou — não um plano de passos a executar, porque
os dados de entrada que o plano precisaria referenciar ainda não existem.

## O que foi conferido antes de tentar construir

A seção 0 do `03-design.md` condiciona a liberação do build, além do aceite do gate, a três itens.
Conferi os três contra o disco nesta sessão, relendo toda a cadeia de artefatos (`demanda.md`,
`comentarios-do-card.md`, `01-analise.md`, `02-recon.md`, `03-design.md` completo) e o anexo PDF
liberado para esta sessão (`anexos/osj7bk-Layout-de-pagina-inicial-x-Paineis--.pdf`, lido com
`spec_read`, inclusive visualmente, não só por extração de texto):

| # | Condição | Status | Evidência |
|---|---|---|---|
| 1 | **P1** — lista do que retirar da aba Início, em texto no card ou print liberado mapeado à tabela de componentes da seção 3 do `02-recon.md` | **Não satisfeita** | `comentarios-do-card.md` tem 4 entradas (aviso do anexo em 19/10, aprovação da estimativa em 21/10, aprovação do gate de análise em 21/10, aprovação do gate de design em 27/10). Nenhuma traz a lista. O anexo PDF continua trazendo a lista apenas como imagem embutida — a extração de texto não alcança o conteúdo, igual ao registrado em `01-analise.md`. Ao abrir o PDF visualmente nesta sessão, dá para notar três trechos destacados em amarelo num print de Home padrão ("Classificar por", "Principais negócios - Oportunidades recentes", "Desempenho trimestral") — isso é um **indício lido por um agente**, não uma resposta formal do cliente, e não foi usado para decidir nada: o design exige a lista em texto no card (ou print liberado por delivery) mapeada à tabela de componentes, e isso ainda não existe. |
| 2 | **P2** — resposta explícita ao escopo de perfis ("todos os usuários" = todos os perfis, ou quais) | **Não satisfeita** | Mesma conferência de `comentarios-do-card.md` acima — nenhuma entrada responde a essa pergunta. |
| 3 | **Matriz item × página (seção 4 do `03-design.md`)**, adendo do arquiteto confirmando interpretação (A/B/C) e mecanismo (remoção vs. filtro de visibilidade) | **Não satisfeita** | A seção 4 do design segue com a linha `*pendente P1*` / `*pendente P2*`. Não há adendo do arquiteto no arquivo além do registro desta tentativa de build (ver `03-design.md`, seção "Adendo — tentativa de build em 2026-10-27"). |

Como nenhuma das três condições está satisfeita, não há como preencher a tabela de componentes a
criar/alterar (seção 3 do design) com itens concretos sem inventar — o que o guardrail #3 do `CLAUDE.md`
raiz proíbe explicitamente ("não invente metadata... se não confirmou, declare a incerteza"). Não escrevi
nenhuma linha de "componente a alterar" neste plano porque nenhuma foi confirmada.

## O que NÃO foi possível medir/confirmar nesta sessão, e por quê

- **Página default de Home da org** (risco R4 do design): não confirmado. O design já apontava isso como
  pendência do início do build, e sem a matriz da seção 4 fechada não há razão para gastar uma chamada
  `sf` nisso agora — ela precisaria ser refeita de qualquer forma quando o build de fato começar, pois a
  org pode mudar entre agora e então.
- **Recuperação das duas FlexiPages fora do baseline** (`Equipe_vendas_SP` e `P_gina_Inicial_Customizada`,
  risco R5): não executada. `sf project retrieve` nessas páginas antes de saber quais itens remover delas
  seria trabalho descartável — a ação fica para quando a matriz da seção 4 estiver fechada.
- Nenhum comando `sf` foi executado contra a sandbox nesta sessão: não havia o que fazer nela sem
  metadata confirmado para alterar.

Nenhum desses itens foi *inventado* para preencher a tabela acima — ficam registrados como não medidos,
não como valores supostos.

## O que falta para o build prosseguir (sem mudança desde o gate de design)

1. Delivery conseguir com a Governança/PMO do cliente a lista de componentes em **texto** no card (ou um
   print sem dado pessoal liberado por delivery), com cada item identificável na tabela de componentes do
   `02-recon.md` (P1).
2. Registrar no card a resposta sobre escopo de perfis (P2).
3. Acionar o arquiteto para preencher a matriz item × página × perfil da seção 4 do `03-design.md` em
   adendo, decidindo entre as interpretações A/B/C da seção 2 e, dentro de A, entre remoção e filtro de
   visibilidade por página.

Só depois disso o build tem dado real para trabalhar: confirmar o default de Home da org, recuperar as
duas páginas fora do baseline, remover os `componentInstance` indicados em cada FlexiPage Home afetada,
e registrar cada componente alterado nesta mesma seção deste arquivo (ou numa nova versão dele).

## Branch e estado do repositório

- Branch ativa: `feature/SOMOSAGILITY-15` (reutilizada, não criada nesta sessão).
- Nenhum arquivo em `force-app/` foi tocado.
- Nenhum `sf project deploy start` foi executado.
- Nenhum PR foi aberto — não há metadata para revisar.

---

Build não liberado. Próxima ação é humana (delivery/arquiteto), não de agente — ver seção acima.
