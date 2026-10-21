-- Fila de disparo por cliente (2026-10-21): o GitHub guarda um só disparo pendente por concurrency group.
CREATE TABLE "disparos_esteira" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "gate" TEXT NOT NULL DEFAULT '',
    "autor" TEXT NOT NULL DEFAULT '',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "disparado_em" TIMESTAMP(3),
    "concluido_em" TIMESTAMP(3),
    "nota" TEXT NOT NULL DEFAULT '',
    CONSTRAINT "disparos_esteira_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "disparos_esteira_client_id_concluido_em_idx" ON "disparos_esteira"("client_id", "concluido_em");
CREATE INDEX "disparos_esteira_demanda_id_concluido_em_idx" ON "disparos_esteira"("demanda_id", "concluido_em");
ALTER TABLE "disparos_esteira" ADD CONSTRAINT "disparos_esteira_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "disparos_esteira" ADD CONSTRAINT "disparos_esteira_demanda_id_fkey" FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
-- Mesmo padrão de toda tabela nova (20260910000000_rls_nas_tabelas_novas).
ALTER TABLE "disparos_esteira" ENABLE ROW LEVEL SECURITY;
