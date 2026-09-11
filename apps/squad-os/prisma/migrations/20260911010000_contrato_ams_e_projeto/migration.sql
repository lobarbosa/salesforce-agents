-- Contrato por cliente (AMS ou projeto) e os entregáveis contratados.
-- Aditiva: cria tipo, duas tabelas e uma coluna nula em `demandas`. Código
-- que ainda não conhece nada disso continua funcionando.

-- CreateEnum
CREATE TYPE "TipoContrato" AS ENUM ('ams', 'projeto');

-- CreateTable
CREATE TABLE "contratos" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "tipo" "TipoContrato" NOT NULL,
    "horas_contratadas" INTEGER NOT NULL DEFAULT 0,
    "ciclo_horas" TEXT NOT NULL DEFAULT 'mensal',
    "sla" JSONB NOT NULL DEFAULT '[]',
    "projeto_nome" TEXT NOT NULL DEFAULT '',
    "projeto_escopo" TEXT NOT NULL DEFAULT '',
    "inicio_em" TIMESTAMP(3),
    "fim_previsto_em" TIMESTAMP(3),
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "atualizado_em" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "contratos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "entregaveis" (
    "id" TEXT NOT NULL,
    "contrato_id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "descricao" TEXT NOT NULL DEFAULT '',
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "peso" INTEGER NOT NULL DEFAULT 1,
    "concluido" BOOLEAN NOT NULL DEFAULT false,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "entregaveis_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "demandas" ADD COLUMN "entregavel_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "contratos_client_id_key" ON "contratos"("client_id");
CREATE INDEX "entregaveis_contrato_id_idx" ON "entregaveis"("contrato_id");
CREATE INDEX "demandas_entregavel_id_idx" ON "demandas"("entregavel_id");

-- AddForeignKey
ALTER TABLE "contratos" ADD CONSTRAINT "contratos_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "entregaveis" ADD CONSTRAINT "entregaveis_contrato_id_fkey"
    FOREIGN KEY ("contrato_id") REFERENCES "contratos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
-- SetNull e não Cascade: apagar um entregável não pode levar junto a demanda
-- que já virou trabalho real no quadro — ela só perde o vínculo com o escopo.
ALTER TABLE "demandas" ADD CONSTRAINT "demandas_entregavel_id_fkey"
    FOREIGN KEY ("entregavel_id") REFERENCES "entregaveis"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- RLS ligado, sem policy: o app fala Postgres direto e ignora RLS (é dono das
-- tabelas); o PostgREST, que a anon key alcança, passa a negar tudo. Mesma
-- correção da migration 20260910000000 — tabela nova nasce trancada.
ALTER TABLE "contratos"   ENABLE ROW LEVEL SECURITY;
ALTER TABLE "entregaveis" ENABLE ROW LEVEL SECURITY;
