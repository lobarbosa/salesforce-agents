-- Estimativa oficial do consultor por demanda (2026-10-17): lançada no card,
-- pré-preenchida com a sugestão do agente. Apontamento de horas exige ela.
ALTER TABLE "demandas" ADD COLUMN "estimativa_consultor_horas" DOUBLE PRECISION;
ALTER TABLE "demandas" ADD COLUMN "estimativa_consultor_por" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "estimativa_consultor_em" TIMESTAMP(3);
