-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "StatusConexao" AS ENUM ('nao_configurado', 'aguardando_teste', 'conectado', 'erro');

-- CreateEnum
CREATE TYPE "TipoDemanda" AS ENUM ('projeto', 'sustentacao');

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('admin', 'consultor', 'cliente');

-- CreateEnum
CREATE TYPE "StatusDemanda" AS ENUM ('backlog', 'planejada', 'recorrente', 'standby', 'analise', 'aguardando_gate_analise', 'design', 'aguardando_gate_design', 'build', 'aguardando_gate_build', 'qa', 'aguardando_homologacao', 'release', 'entregue');

-- CreateTable
CREATE TABLE "clients" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "segmento" TEXT NOT NULL DEFAULT '',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "marcas" TEXT NOT NULL DEFAULT '',
    "contatos" TEXT NOT NULL DEFAULT '',
    "ambiente_salesforce" TEXT NOT NULL DEFAULT '',
    "concorrentes" TEXT NOT NULL DEFAULT '',
    "integracoes" TEXT NOT NULL DEFAULT '',
    "regras" TEXT NOT NULL DEFAULT '',
    "org_alias" TEXT,
    "login_url" TEXT,
    "username" TEXT,
    "consumer_key" TEXT,
    "status_conexao" "StatusConexao" NOT NULL DEFAULT 'nao_configurado',
    "teste_solicitado_por" TEXT,
    "teste_solicitado_em" TIMESTAMP(3),

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "nome" TEXT NOT NULL DEFAULT '',
    "role" "Role" NOT NULL,
    "client_id" TEXT,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "concedido_por" TEXT,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "demandas" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "tipo" "TipoDemanda" NOT NULL DEFAULT 'sustentacao',
    "texto" TEXT NOT NULL DEFAULT '',
    "autor" TEXT NOT NULL DEFAULT '',
    "status" "StatusDemanda" NOT NULL DEFAULT 'backlog',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "perguntas" JSONB NOT NULL DEFAULT '[]',
    "aprovacao" JSONB,
    "historico" JSONB NOT NULL DEFAULT '[]',
    "materializado_em" TIMESTAMP(3),

    CONSTRAINT "demandas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "clients_slug_key" ON "clients"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE INDEX "usuarios_client_id_idx" ON "usuarios"("client_id");

-- CreateIndex
CREATE INDEX "demandas_client_id_idx" ON "demandas"("client_id");

-- CreateIndex
CREATE INDEX "demandas_status_idx" ON "demandas"("status");

-- CreateIndex
CREATE UNIQUE INDEX "demandas_client_id_code_key" ON "demandas"("client_id", "code");

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "demandas" ADD CONSTRAINT "demandas_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

