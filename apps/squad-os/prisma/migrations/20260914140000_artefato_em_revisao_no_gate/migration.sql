-- O artefato que o gate põe na mesa, espelhado do git junto com o status.
--
-- Aditiva: três colunas com default em `demandas`. Código que não as conhece
-- segue funcionando, então a migração pode subir antes do deploy que as lê.
--
-- Por que existe: no primeiro ciclo real de demanda (ACXYA-2, 2026-09-14) o
-- gate chegou oco ao app. O `ba-discovery` listou onze premissas pendentes no
-- 01-analise.md, o card mostrou "0 perguntas" e um botão de aprovar — o
-- artefato existia só no git, e a trava do modal (que recusa aprovar com
-- pergunta em aberto) estava inerte por falta de quem enchesse `perguntas`.

-- AlterTable
ALTER TABLE "demandas"
  ADD COLUMN "artefato_nome" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "artefato_conteudo" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "artefato_truncado" BOOLEAN NOT NULL DEFAULT false;
