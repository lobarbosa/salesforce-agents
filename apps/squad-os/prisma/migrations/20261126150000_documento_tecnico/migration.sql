-- Documento técnico de construção (lib/documento-tecnico-anexo.ts): hash do
-- 03-documento-tecnico.md publicado como anexo, para o sync não regerar o PDF.
ALTER TABLE "demandas" ADD COLUMN "documento_tecnico_hash" TEXT NOT NULL DEFAULT '';
