-- Entrega manual pelo consultor (lib/entrega-manual.ts): quem registrou,
-- quando e o que foi feito. A evidência é um anexo do card.
ALTER TABLE "demandas"
  ADD COLUMN "entrega_manual_em" TIMESTAMP(3),
  ADD COLUMN "entrega_manual_por" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "entrega_manual_descricao" TEXT NOT NULL DEFAULT '';
