**Resultado do build:** bloqueado

# 04 — Plano de build: SOMOSAGILITY-15 — Layout de página inicial

**Org confirmada (`sf org list`):** `sbx-somos-agility-dev` (sandbox, conectada). Nada foi tocado nela.
**Branch:** `feature/SOMOSAGILITY-15` (já existente). Nenhum metadata escrito, nenhum deploy, nenhum commit de componente.

## Condições do design (seção 0 do `03-design.md`) conferidas nesta sessão

| # | Condição | Situação |
|---|----------|----------|
| 1 | P1: lista do que retirar, em texto no card (ou print liberado por delivery), cada item identificável na tabela de componentes do `02-recon.md` | **Não atendida.** O card (`comentarios-do-card.md`) não traz a lista. Comentário de 2026-11-12 da equipe a pediu de novo; a resposta do cliente de 2026-11-23 20:07 trata só do escopo de perfis. A lista continua só na imagem embutida do PDF. |
| 2 | P2: escopo de perfis | **Atendida.** Cliente, 2026-11-23 20:07: "Todos os perfis". |
| 3 | Matriz item × página (seção 4 do design) preenchida pelo arquiteto em adendo | **Não atendida.** A seção 4 segue com "*pendente P1*". O adendo existente no design (2026-10-27) só registra o bloqueio anterior. O aceite do gate de design de 2026-11-23 aprova o documento, mas não traz a matriz. |

## Por que não construo

O design diz que a remoção é por componente em cada FlexiPage Home que o contém, e que sem a matriz
o build corre o risco R1 (alta): retirar o que o cliente não pediu ou deixar de retirar algo. A única
pista sobre a lista é uma leitura visual de três trechos destacados no print (feed "Classificar por",
"Principais negócios - Oportunidades recentes", "Desempenho trimestral"), já registrada no adendo do
design como indício e não confirmação. Usá-la como critério seria inventar o escopo (guardrail #3), e
o QA ficaria sem critério verificável. Também ficam abertas as interpretações A/B/C da seção 2: só o
arquiteto, com a lista, diz se cai em A.

## O que falta e quem responde

1. **Lista do que sai da aba Início, em texto** (ou print sem dado pessoal liberado por delivery), com
   cada item mapeável à tabela de componentes do `02-recon.md`. Responde: cliente, via consultor/delivery
   no card.
2. **Adendo do arquiteto ao `03-design.md`** com a matriz item × página (seção 4): componente, páginas
   (Id), remoção ou filtro, confirmando a interpretação A. Escopo de perfis já é "todos"; portanto
   remoção direta em cada página, sem `visibilityRule`. Responde: arquiteto humano.
3. **Default de Home da org**, a confirmar no início do build (R4), e inclusão na matriz. Responde:
   builder, assim que a matriz existir.

## Pronto para executar quando a matriz chegar

- Recuperar `Equipe_vendas_SP` e `P_gina_Inicial_Customizada` da org para `force-app` e commitar o
  estado original separado da alteração (R5).
- Remover o `componentInstance` de cada item em cada FlexiPage listada na matriz; não tocar em
  `CustomApplication`, `Dashboard`, `Report`, perfis nem permission sets.
- Deploy só em `sbx-somos-agility-dev`; registrar cada componente alterado neste arquivo.

## Versões e ativação

Nenhuma. Nada foi criado ou ativado.
