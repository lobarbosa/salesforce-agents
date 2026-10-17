-- Estimativa por demanda (2026-10-17): horas de esforço humano (lidas do
-- artefato da análise/design) e custo de agente gasto + projetado (da
-- telemetria). Espelho do sync; o git continua sendo a fonte. Tabela já tem
-- RLS ligado — nada a mudar ali.
ALTER TABLE "demandas" ADD COLUMN "estimativa_horas_min" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "estimativa_horas_max" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "estimativa_horas_fonte" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "custo_agente_gasto_usd" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "custo_agente_restante_usd" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "custo_agente_amostras" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "demandas" ADD COLUMN "agente_horas_gasto" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "agente_horas_restante" DOUBLE PRECISION;
