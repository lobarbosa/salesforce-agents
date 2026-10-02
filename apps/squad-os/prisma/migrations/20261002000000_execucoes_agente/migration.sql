-- Observabilidade de execução (council de 2026-10-01): admin pedia visão de
-- todas as execuções da plataforma; consultor, uma tela do que falhou, pra
-- não ficar no escuro. Uma linha por execução que já reporta de volta pro
-- Squad OS hoje (demanda, assessment, planejamento, conexão) — nunca fonte
-- de verdade (o git continua sendo, guardrail #5), é o espelho histórico.

CREATE TABLE "execucoes_agente" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "demanda_id" TEXT,
    "origem" TEXT NOT NULL,
    "etapa" TEXT NOT NULL,
    "motivo" TEXT NOT NULL DEFAULT '',
    "resultado" TEXT NOT NULL,
    "iniciado_em" TIMESTAMP(3),
    "concluido_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "run_url" TEXT NOT NULL DEFAULT '',
    CONSTRAINT "execucoes_agente_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "execucoes_agente_client_id_concluido_em_idx" ON "execucoes_agente"("client_id", "concluido_em");
CREATE INDEX "execucoes_agente_resultado_concluido_em_idx" ON "execucoes_agente"("resultado", "concluido_em");

ALTER TABLE "execucoes_agente" ADD CONSTRAINT "execucoes_agente_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "execucoes_agente" ADD CONSTRAINT "execucoes_agente_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Mesmo padrão de 20260910000000_rls_nas_tabelas_novas: RLS ligado e nenhuma
-- policy. O app acessa pelo Prisma (dono do schema); a anon key pública não
-- lê nada.
ALTER TABLE "execucoes_agente" ENABLE ROW LEVEL SECURITY;
