-- Encerrar cliente (2026-10-17): cliente que saiu é encerrado (soft), não
-- apagado — o DELETE em cascata levaria junto demandas, horas e contrato,
-- que são histórico de trabalho e de faturamento. Só colunas novas, todas
-- opcionais ou com default: nenhuma linha existente muda de significado
-- (encerrado_em nulo = cliente ativo). IF NOT EXISTS para reaplicar sem erro.
-- A tabela já tem RLS ligado — nada a mudar ali.
ALTER TABLE "clients" ADD COLUMN IF NOT EXISTS "encerrado_em" TIMESTAMP(3);
ALTER TABLE "clients" ADD COLUMN IF NOT EXISTS "encerrado_por_email" TEXT;
ALTER TABLE "clients" ADD COLUMN IF NOT EXISTS "motivo_encerramento" TEXT NOT NULL DEFAULT '';
