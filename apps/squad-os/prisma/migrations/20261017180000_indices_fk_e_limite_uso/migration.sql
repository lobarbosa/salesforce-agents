-- 1) Índices das FKs que o advisor do Supabase apontou sem cobertura
--    (2026-10-17). Sem eles, filtrar/apagar por cliente varre a tabela.
CREATE INDEX IF NOT EXISTS "contas_pagar_client_id_idx" ON "contas_pagar"("client_id");
CREATE INDEX IF NOT EXISTS "despesas_recorrentes_client_id_idx" ON "despesas_recorrentes"("client_id");
CREATE INDEX IF NOT EXISTS "execucoes_agente_demanda_id_idx" ON "execucoes_agente"("demanda_id");

-- 2) Contador durável de uso (teto diário do copiloto por usuário).
CREATE TABLE "limites_uso" (
    "chave" TEXT NOT NULL,
    "janela" TEXT NOT NULL,
    "contagem" INTEGER NOT NULL DEFAULT 0,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "limites_uso_pkey" PRIMARY KEY ("chave", "janela")
);
CREATE INDEX "limites_uso_criado_em_idx" ON "limites_uso"("criado_em");

-- Mesmo padrão de toda tabela nova (20260910000000_rls_nas_tabelas_novas):
-- RLS ligado e nenhuma policy — o app acessa pelo Prisma; a anon key não lê.
ALTER TABLE "limites_uso" ENABLE ROW LEVEL SECURITY;
