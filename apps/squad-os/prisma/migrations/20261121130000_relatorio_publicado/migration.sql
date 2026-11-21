-- Relatório mensal publicado na página do cliente (2026-11-21): caminho do PDF
-- enviado, no bucket privado `financeiro`.
ALTER TABLE "relatorios_enviados" ADD COLUMN "arquivo" TEXT NOT NULL DEFAULT '';
