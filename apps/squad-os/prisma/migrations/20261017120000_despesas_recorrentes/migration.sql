-- Despesas recorrentes x avulsas (16/10/2026, pedido do CEO).
--
-- Só aditiva: dois enums, uma tabela nova e quatro colunas NULLABLE em
-- contas_pagar. Linha existente fica com tudo nulo = conta avulsa sem
-- classificação; nada é renomeado nem apagado. Escrita para poder rodar de
-- novo sem erro (IF NOT EXISTS / blocos DO), caso alguém aplique à mão antes
-- do `prisma migrate deploy`.
--
-- Contrato com o cfo_agent (konecta-agents, PostgREST + service key):
--   contas_pagar.recorrencia_id, .competencia ('YYYY-MM'), .natureza
--   ('direto'|'fixo'), .client_id; tabela despesas_recorrentes.

DO $$ BEGIN
  CREATE TYPE "NaturezaCusto" AS ENUM ('direto', 'fixo');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "Periodicidade" AS ENUM ('mensal', 'trimestral', 'semestral', 'anual');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "despesas_recorrentes" (
    "id" TEXT NOT NULL,
    "fornecedor" TEXT NOT NULL,
    "descricao" TEXT NOT NULL DEFAULT '',
    "categoria" TEXT NOT NULL DEFAULT '',
    "valor" DECIMAL(14,2) NOT NULL,
    "valor_variavel" BOOLEAN NOT NULL DEFAULT false,
    "periodicidade" "Periodicidade" NOT NULL DEFAULT 'mensal',
    "dia_vencimento" INTEGER NOT NULL,
    "inicio_em" DATE NOT NULL,
    "fim_em" DATE,
    "ativa" BOOLEAN NOT NULL DEFAULT true,
    "natureza" "NaturezaCusto" NOT NULL,
    "client_id" TEXT,
    "criado_por_email" TEXT NOT NULL,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "despesas_recorrentes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "despesas_recorrentes_valor_positivo" CHECK ("valor" > 0),
    CONSTRAINT "despesas_recorrentes_dia_valido" CHECK ("dia_vencimento" BETWEEN 1 AND 31),
    CONSTRAINT "despesas_recorrentes_fim_depois_do_inicio" CHECK ("fim_em" IS NULL OR "fim_em" >= "inicio_em")
);

CREATE INDEX IF NOT EXISTS "despesas_recorrentes_ativa_idx" ON "despesas_recorrentes"("ativa");

ALTER TABLE "contas_pagar" ADD COLUMN IF NOT EXISTS "recorrencia_id" TEXT;
ALTER TABLE "contas_pagar" ADD COLUMN IF NOT EXISTS "competencia" TEXT;
ALTER TABLE "contas_pagar" ADD COLUMN IF NOT EXISTS "natureza" "NaturezaCusto";
ALTER TABLE "contas_pagar" ADD COLUMN IF NOT EXISTS "client_id" TEXT;

-- Uma conta por recorrência por competência: é o que torna a geração
-- idempotente (cron + carga de página podem rodar juntos). NULLs não colidem,
-- então as avulsas não são afetadas.
CREATE UNIQUE INDEX IF NOT EXISTS "contas_pagar_recorrencia_id_competencia_key"
    ON "contas_pagar"("recorrencia_id", "competencia");

DO $$ BEGIN
  ALTER TABLE "contas_pagar" ADD CONSTRAINT "contas_pagar_competencia_formato"
      CHECK ("competencia" IS NULL OR "competencia" ~ '^[0-9]{4}-(0[1-9]|1[0-2])$');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "contas_pagar" ADD CONSTRAINT "contas_pagar_recorrencia_id_fkey"
      FOREIGN KEY ("recorrencia_id") REFERENCES "despesas_recorrentes"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "contas_pagar" ADD CONSTRAINT "contas_pagar_client_id_fkey"
      FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "despesas_recorrentes" ADD CONSTRAINT "despesas_recorrentes_client_id_fkey"
      FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Mesmo padrão das outras tabelas do financeiro: RLS ligado e nenhuma policy.
-- O app fala pelo Prisma (dono das tabelas, ignora RLS) e os agentes pela
-- service key; a anon key pública não lê nada.
ALTER TABLE "despesas_recorrentes" ENABLE ROW LEVEL SECURITY;
