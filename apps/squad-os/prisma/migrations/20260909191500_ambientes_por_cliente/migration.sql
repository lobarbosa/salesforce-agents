-- Conexão Salesforce deixa de ser um conjunto achatado em `clients` e vira uma
-- linha por ambiente. A esteira vai de dev até o deploy na sandbox de QA, e o
-- agente para ali — por isso o enum tem só esses dois valores. Produção não é
-- modelada aqui (guardrail #1: o agente não toca prod).
--
-- A ORDEM IMPORTA: o backfill roda ANTES do DROP COLUMN. Invertido, a conexão
-- já cadastrada (acxya/Konecta: sbx-acxya) seria perdida sem recuperação.

-- CreateEnum
CREATE TYPE "TipoAmbiente" AS ENUM ('dev', 'qa');

-- CreateTable
CREATE TABLE "ambientes_org" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "tipo" "TipoAmbiente" NOT NULL,
    "org_alias" TEXT,
    "login_url" TEXT,
    "username" TEXT,
    "consumer_key" TEXT,
    "status_conexao" "StatusConexao" NOT NULL DEFAULT 'nao_configurado',
    "teste_solicitado_por" TEXT,
    "teste_solicitado_em" TIMESTAMP(3),

    CONSTRAINT "ambientes_org_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ambientes_org_client_id_idx" ON "ambientes_org"("client_id");

-- CreateIndex
CREATE UNIQUE INDEX "ambientes_org_client_id_tipo_key" ON "ambientes_org"("client_id", "tipo");

-- AddForeignKey
ALTER TABLE "ambientes_org" ADD CONSTRAINT "ambientes_org_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill: a org que já estava cadastrada em `clients` era a sandbox onde se
-- construía e se testava, então ela vira o ambiente `dev`. Só clientes que
-- têm de fato algum dado de conexão geram linha; os demais começam sem
-- ambiente e a aba Conexões cria sob demanda ao salvar.
INSERT INTO "ambientes_org" (
    "id", "client_id", "tipo", "org_alias", "login_url", "username",
    "consumer_key", "status_conexao", "teste_solicitado_por", "teste_solicitado_em"
)
SELECT
    gen_random_uuid()::text,
    "id",
    'dev'::"TipoAmbiente",
    "org_alias",
    "login_url",
    "username",
    "consumer_key",
    "status_conexao",
    "teste_solicitado_por",
    "teste_solicitado_em"
FROM "clients"
WHERE "org_alias" IS NOT NULL
   OR "login_url" IS NOT NULL
   OR "username" IS NOT NULL
   OR "consumer_key" IS NOT NULL;

-- DropColumn — só depois do backfill acima.
ALTER TABLE "clients" DROP COLUMN "org_alias";
ALTER TABLE "clients" DROP COLUMN "login_url";
ALTER TABLE "clients" DROP COLUMN "username";
ALTER TABLE "clients" DROP COLUMN "consumer_key";
ALTER TABLE "clients" DROP COLUMN "status_conexao";
ALTER TABLE "clients" DROP COLUMN "teste_solicitado_por";
ALTER TABLE "clients" DROP COLUMN "teste_solicitado_em";
