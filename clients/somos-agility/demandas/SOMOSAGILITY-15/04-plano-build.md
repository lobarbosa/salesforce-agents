**Resultado do build:** bloqueado

# 04 — Plano de build: SOMOSAGILITY-15 (Layout de página inicial)

**Org conferida:** `sbx-somos-agility-dev` (única conectada em `sf org list`). Nenhum metadata escrito, nenhum deploy, nenhuma branch nova (a `feature/SOMOSAGILITY-15` já existia). Nada construído.

## O que mudou desde a última tentativa

- **P2 resolvida.** Comentário do cliente em 2026-11-23: "Todos os perfis". Vale a remoção da página, sem filtro de visibilidade.
- **P1 continua sem resposta do cliente.** A equipe propôs em 2026-11-23 três itens lidos na imagem do PDF (feed com "Classificar por", "Principais negócios - Oportunidades recentes", "Desempenho trimestral") e pediu confirmação ou correção. Não há confirmação do cliente no card.
- **Matriz item × página (seção 4 do design) continua vazia.** O `03-design.md` está inalterado (sha256 `9f19edc49eb6caa0`, o mesmo de antes) e não tem adendo do arquiteto preenchendo a matriz. A condição 3 da seção 0 do design não foi cumprida.

## Pergunta sem resposta que impede construir

1. **Quem responde: cliente (confirma a lista) e arquiteto (matriz).** A lista dos itens a retirar da Home está confirmada em texto? Os três itens acima são exatamente os do pedido? O design exige que a lista chegue em texto no card e que cada item seja mapeado na matriz da seção 4 antes do build. Construir a partir de leitura de imagem por agente violaria o guardrail #3 e a regra do design de não improvisar.
2. **Quem responde: arquiteto.** Confirmar a interpretação A (componentes da Home) para os três itens. "Principais negócios" e "Desempenho trimestral" são componentes padrão da Home, mas o design pede essa correspondência na matriz, com a página default da org (R4) e a remoção página por página.
3. **Quem responde: equipe.** O comentário de 2026-11-24 22:09 diz "Realizado o ajuste nas paginas iniciais retirando o que esta no anexo. Card encerrado." Não sei onde o ajuste foi feito. Se foi feito em produção ou manualmente na dev, o repositório e a dev precisam refletir isso, e o build deixa de ser necessário. A esteira precisa decidir: fechar a demanda por correção manual, que exige `05-testes.md` aprovado e `06-entrega.md`, ou devolver ao design para completar a matriz.

## Próximo passo

Devolver ao gate de design. Com a matriz preenchida (itens, páginas, default da org, e as duas páginas fora do baseline: `Equipe_vendas_SP` e `P_gina_Inicial_Customizada`), o build é de 2 h conforme estimativa aprovada. Se a lista passar de três itens, a estimativa é revista antes.
