-- Melhorias do assessment propostas ao cliente (2026-11-21): a demanda guarda de
-- qual recomendação nasceu e a decisão do cliente sobre a proposta.
ALTER TABLE "demandas" ADD COLUMN "origem_assessment_id" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "proposta_cliente_em" TIMESTAMP(3);
ALTER TABLE "demandas" ADD COLUMN "proposta_decisao" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "proposta_decidida_por" TEXT NOT NULL DEFAULT '';
ALTER TABLE "demandas" ADD COLUMN "proposta_decidida_em" TIMESTAMP(3);
CREATE INDEX "demandas_client_id_origem_assessment_id_idx" ON "demandas"("client_id", "origem_assessment_id");
