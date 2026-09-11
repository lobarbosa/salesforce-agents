-- Aditiva: só ADD COLUMN, todas com default ou nulas. Código que ainda não
-- conhece essas colunas continua funcionando, então não há janela em que
-- produção quebre entre o migrate e o deploy (ver README, "Preview e
-- Production compartilham o mesmo banco").

-- `clients`: resultado do assessment de org do onboarding.
ALTER TABLE "clients" ADD COLUMN "assessment_em" TIMESTAMP(3);
ALTER TABLE "clients" ADD COLUMN "assessment_saude" TEXT NOT NULL DEFAULT '';
ALTER TABLE "clients" ADD COLUMN "assessment_resumo" TEXT NOT NULL DEFAULT '';
ALTER TABLE "clients" ADD COLUMN "assessment_recomendacoes" JSONB NOT NULL DEFAULT '[]';

-- `demandas`: rastro da última execução do pipeline, preenchido pelo sync de
-- volta. Sem isso uma etapa que falhou fica indistinguível de uma que nunca
-- rodou.
ALTER TABLE "demandas" ADD COLUMN "ultima_execucao_em" TIMESTAMP(3);
ALTER TABLE "demandas" ADD COLUMN "ultimo_resultado" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "ultimo_run_url" TEXT NOT NULL DEFAULT '';
