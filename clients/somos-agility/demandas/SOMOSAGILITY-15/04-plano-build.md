**Resultado do build:** bloqueado

# 04 — Plano de build: SOMOSAGILITY-15

Org conferida: `sbx-somos-agility-dev` (única conectada em `sf org list`). Nenhuma branch nova, nenhum metadata escrito, nenhum deploy.

## O que já está resolvido
- **P2 (escopo de perfis):** respondida pelo cliente em 2026-11-23 20:07: "Todos os perfis".
- Estimativa de 2 h aprovada pelo cliente (2026-11-23 20:07), válida para o cenário de 3 itens.

## O que falta (impede construir)
**P1: lista do que sai da aba Início, em texto.** Não há resposta no card. A última mensagem da equipe (2026-11-23 23:59) propõe três itens lidos da imagem do PDF e pede confirmação. Não há comentário do cliente depois dela. O gate de design foi aprovado de novo em 2026-11-24 12:03, mas sem a lista confirmada. A seção 4 do `03-design.md` (matriz item × página) continua "pendente P1", sem adendo do arquiteto. A seção 0 do design condiciona o build à lista em texto, e eu não vou tratar a leitura visual do print como confirmação.

Itens hipotéticos, a confirmar (não construídos):
1. Feed com "Classificar por"
2. "Principais negócios - Oportunidades recentes"
3. "Desempenho trimestral"

## Perguntas e quem responde
1. **Cliente (via card):** confirmar ou corrigir os três itens acima, em texto. Se a lista for maior, a estimativa de 2 h é revista.
2. **Arquiteto humano:** preencher a matriz da seção 4 do design, com componente, Id das FlexiPages Home atribuídas e remoção ou filtro. Decidir a interpretação A/B/C da seção 2.
3. **Arquiteto humano:** definir se `Equipe_vendas_SP` (`0M00z000000GoLuCAK`) e `P_gina_Inicial_Customizada` (`0M038000000GmdwCAC`) entram. Ambas estão marcadas "Recuperar antes" (R5) e não estão no baseline do repositório.

## Próximo passo quando desbloquear
Criar `feature/SOMOSAGILITY-15` (a branch local já existe), recuperar as duas páginas fora do baseline e commitá-las separadas, aplicar a alteração em versão nova da FlexiPage conforme a matriz e implantar só em `sbx-somos-agility-dev`.
