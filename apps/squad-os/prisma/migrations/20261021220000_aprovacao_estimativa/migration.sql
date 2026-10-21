-- Aprovação da estimativa pelo cliente e débito no contrato ao entrar em build (2026-10-21).
ALTER TABLE "demandas" ADD COLUMN "estimativa_aprovada_horas" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "estimativa_aprovada_por" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "estimativa_aprovada_em" TIMESTAMP(3);
ALTER TABLE "demandas" ADD COLUMN "estimativa_debitada_horas" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "estimativa_debitada_em" TIMESTAMP(3);
