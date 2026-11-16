-- Evidências de teste (2026-11-16): o card recebe um anexo em PDF com o roteiro
-- que o QA executou e as capturas de tela. O hash diz ao sync se o conteúdo
-- mudou desde o último PDF gerado.
ALTER TABLE "demandas" ADD COLUMN "evidencias_hash" TEXT NOT NULL DEFAULT '';
