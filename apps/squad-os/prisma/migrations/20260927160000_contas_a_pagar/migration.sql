-- Contas a pagar dentro do Squad OS (saída do ClickUp, 27/09/2026).

CREATE TYPE "StatusConta" AS ENUM ('aguardando_aprovacao', 'aprovada', 'recusada', 'paga', 'cancelada');

CREATE TABLE "contas_pagar" (
    "id" TEXT NOT NULL,
    "fornecedor" TEXT NOT NULL,
    "descricao" TEXT NOT NULL DEFAULT '',
    "categoria" TEXT NOT NULL DEFAULT '',
    "valor" DECIMAL(14,2) NOT NULL,
    "vencimento" DATE NOT NULL,
    "status" "StatusConta" NOT NULL DEFAULT 'aguardando_aprovacao',
    "documento_caminho" TEXT NOT NULL DEFAULT '',
    "documento_nome" TEXT NOT NULL DEFAULT '',
    "lancado_por_email" TEXT NOT NULL,
    "lancado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decidido_por_email" TEXT,
    "decidido_em" TIMESTAMP(3),
    "pago_por_email" TEXT,
    "pago_em" TIMESTAMP(3),
    "atualizado_em" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "contas_pagar_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "contas_pagar_valor_positivo" CHECK ("valor" > 0)
);

CREATE TABLE "contas_pagar_eventos" (
    "id" TEXT NOT NULL,
    "conta_id" TEXT NOT NULL,
    "acao" TEXT NOT NULL,
    "por_email" TEXT NOT NULL,
    "comentario" TEXT NOT NULL DEFAULT '',
    "em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "contas_pagar_eventos_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "contas_pagar_status_vencimento_idx" ON "contas_pagar"("status", "vencimento");
CREATE INDEX "contas_pagar_eventos_conta_id_em_idx" ON "contas_pagar_eventos"("conta_id", "em");

ALTER TABLE "contas_pagar_eventos" ADD CONSTRAINT "contas_pagar_eventos_conta_id_fkey"
    FOREIGN KEY ("conta_id") REFERENCES "contas_pagar"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Mesmo padrão de 20260910000000_rls_nas_tabelas_novas: RLS ligado e nenhuma
-- policy. O app acessa pelo Prisma (dono do schema) e os agentes pela service
-- key; a anon key pública não lê nada.
ALTER TABLE "contas_pagar" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "contas_pagar_eventos" ENABLE ROW LEVEL SECURITY;

-- Trilha de auditoria só aceita inserção.
CREATE OR REPLACE FUNCTION contas_pagar_eventos_imutavel() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'contas_pagar_eventos é só inserção (trilha de auditoria)';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contas_pagar_eventos_sem_alteracao
    BEFORE UPDATE OR DELETE ON "contas_pagar_eventos"
    FOR EACH ROW EXECUTE FUNCTION contas_pagar_eventos_imutavel();
