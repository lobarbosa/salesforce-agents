-- Estado de execução do assessment, separado do resultado dele.
--
-- Aditiva: enum novo e quatro colunas com default em `clients`. Código que
-- ainda não conhece nenhuma delas continua funcionando — e é por isso que a
-- migração pode subir antes do deploy que passa a lê-las.
--
-- Por que existe: até 2026-09-13 o app não registrava nada ao disparar o
-- assessment, e `run-assessment.yml` só reportava de volta em caso de sucesso.
-- O primeiro assessment de uma org real falhou e o perfil do cliente seguiu
-- mostrando "ainda não avaliada" — o mesmo estado de quem nunca tentou.

-- CreateEnum
CREATE TYPE "StatusAtividade" AS ENUM ('nunca', 'rodando', 'concluido', 'erro');

-- AlterTable
ALTER TABLE "clients"
  ADD COLUMN "assessment_status" "StatusAtividade" NOT NULL DEFAULT 'nunca',
  ADD COLUMN "assessment_iniciado_em" TIMESTAMP(3),
  ADD COLUMN "assessment_erro" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "assessment_run_url" TEXT NOT NULL DEFAULT '';

-- Quem já tem assessment no perfil não é "nunca avaliado": o backfill evita que
-- a primeira tela depois do deploy minta para os clientes que já rodaram.
UPDATE "clients" SET "assessment_status" = 'concluido' WHERE "assessment_em" IS NOT NULL;
