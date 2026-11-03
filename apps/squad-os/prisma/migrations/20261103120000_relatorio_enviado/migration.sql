-- Fechamento mensal enviado ao cliente (2026-11-03).
CREATE TABLE "relatorios_enviados" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "mes" TEXT NOT NULL,
    "enviado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "enviado_por" TEXT NOT NULL,
    "destinatarios" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "relatorios_enviados_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "relatorios_enviados_client_id_mes_key" ON "relatorios_enviados"("client_id", "mes");
-- Mesmo padrão de toda tabela nova (20260910000000_rls_nas_tabelas_novas).
ALTER TABLE "relatorios_enviados" ENABLE ROW LEVEL SECURITY;
