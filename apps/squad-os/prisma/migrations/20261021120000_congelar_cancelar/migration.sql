-- Congelar / cancelar demanda (2026-10-21).
ALTER TYPE "StatusDemanda" ADD VALUE 'cancelada';
ALTER TABLE "demandas" ADD COLUMN "congelada_de" "StatusDemanda";
ALTER TABLE "demandas" ADD COLUMN "motivo_parada" TEXT NOT NULL DEFAULT '';
