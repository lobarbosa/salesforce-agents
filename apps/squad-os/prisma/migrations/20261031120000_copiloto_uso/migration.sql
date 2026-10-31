-- Telemetria do copiloto (2026-10-31): só metadata, nunca o texto da conversa.
CREATE TABLE "copiloto_uso" (
    "id" TEXT NOT NULL,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usuario_id" TEXT NOT NULL,
    "papel" TEXT NOT NULL,
    "client_id" TEXT,
    "modelo" TEXT NOT NULL,
    "ferramentas" TEXT[],
    "erros_ferramenta" INTEGER NOT NULL DEFAULT 0,
    "passos" INTEGER NOT NULL DEFAULT 0,
    "finish_reason" TEXT NOT NULL DEFAULT '',
    "input_tokens" INTEGER NOT NULL DEFAULT 0,
    "output_tokens" INTEGER NOT NULL DEFAULT 0,
    "duracao_ms" INTEGER NOT NULL DEFAULT 0,
    "erro" TEXT NOT NULL DEFAULT '',
    CONSTRAINT "copiloto_uso_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "copiloto_uso_criado_em_idx" ON "copiloto_uso"("criado_em");
-- Mesmo padrão de toda tabela nova (20260910000000_rls_nas_tabelas_novas).
ALTER TABLE "copiloto_uso" ENABLE ROW LEVEL SECURITY;
