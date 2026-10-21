-- Esteira ao vivo (2026-10-21): eventos de metadata enviados durante a sessão de agente.
CREATE TABLE "eventos_esteira" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "run_id" TEXT NOT NULL,
    "run_url" TEXT NOT NULL DEFAULT '',
    "demanda_code" TEXT NOT NULL DEFAULT '',
    "etapa" TEXT NOT NULL DEFAULT '',
    "tipo" TEXT NOT NULL,
    "agente" TEXT NOT NULL DEFAULT '',
    "ferramenta" TEXT NOT NULL DEFAULT '',
    "detalhe" TEXT NOT NULL DEFAULT '',
    "custo_usd" DOUBLE PRECISION,
    "em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "eventos_esteira_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "eventos_esteira_em_idx" ON "eventos_esteira"("em");
CREATE INDEX "eventos_esteira_run_id_em_idx" ON "eventos_esteira"("run_id", "em");
CREATE INDEX "eventos_esteira_client_id_idx" ON "eventos_esteira"("client_id");
ALTER TABLE "eventos_esteira" ADD CONSTRAINT "eventos_esteira_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
-- Mesmo padrão de toda tabela nova (20260910000000_rls_nas_tabelas_novas).
ALTER TABLE "eventos_esteira" ENABLE ROW LEVEL SECURITY;
