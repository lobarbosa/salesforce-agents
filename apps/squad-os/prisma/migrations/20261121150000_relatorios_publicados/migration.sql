-- Relatórios mensais publicados na página do cliente (2026-11-21): a
-- publicação deixa de depender do envio por e-mail e ganha tabela própria. A
-- coluna relatorios_enviados.arquivo, da migração anterior, nunca chegou a ter
-- valor (nenhum envio registrado) e sai.
ALTER TABLE "relatorios_enviados" DROP COLUMN "arquivo";

CREATE TABLE "relatorios_publicados" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "mes" TEXT NOT NULL,
    "arquivo" TEXT NOT NULL,
    "publicado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "relatorios_publicados_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "relatorios_publicados_client_id_mes_key" ON "relatorios_publicados"("client_id", "mes");

-- Como toda tabela nova deste banco: RLS ligado sem policy (o app lê pelo
-- Prisma com o papel do servidor; PostgREST não publica a linha).
ALTER TABLE "relatorios_publicados" ENABLE ROW LEVEL SECURITY;
