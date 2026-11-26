-- Contas a receber: recebimento de NFS-e registrado no Squad OS. Tabela nova,
-- só acrescenta; os agentes (integrations/nfse.py) passam a ler daqui.
CREATE TABLE "nfse_recebimentos" (
    "id" TEXT NOT NULL,
    "numero" TEXT NOT NULL,
    "emissao" DATE NOT NULL,
    "cliente" TEXT NOT NULL DEFAULT '',
    "valor_nota" DECIMAL(14,2) NOT NULL,
    "recebido_em" DATE NOT NULL,
    "valor_recebido" DECIMAL(14,2) NOT NULL,
    "forma" TEXT NOT NULL DEFAULT '',
    "observacao" TEXT NOT NULL DEFAULT '',
    "registrado_por_email" TEXT NOT NULL,
    "registrado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estornado_em" TIMESTAMP(3),
    "estornado_por_email" TEXT,
    "estorno_motivo" TEXT NOT NULL DEFAULT '',

    CONSTRAINT "nfse_recebimentos_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "nfse_recebimentos_numero_emissao_idx" ON "nfse_recebimentos"("numero", "emissao");

-- Mesmo padrão das outras tabelas do financeiro: RLS ligado e nenhuma policy.
-- O app fala pelo Prisma (dono das tabelas, ignora RLS) e os agentes pela
-- service key; a anon key pública não lê nada.
ALTER TABLE "nfse_recebimentos" ENABLE ROW LEVEL SECURITY;
