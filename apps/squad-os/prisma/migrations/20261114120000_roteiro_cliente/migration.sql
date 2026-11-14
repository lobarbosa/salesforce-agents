-- Roteiro de teste do cliente (2026-11-14): passo a passo de homologação que o
-- agente de QA escreve quando aprova. Espelhado pelo sync da demanda.
ALTER TABLE "demandas" ADD COLUMN "roteiro_cliente" TEXT NOT NULL DEFAULT '';
