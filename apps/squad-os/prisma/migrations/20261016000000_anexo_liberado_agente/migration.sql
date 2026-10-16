-- Liberação de anexo para o agente (2026-10-16). Só anexo liberado por
-- alguém de delivery é baixado pelo run-demand.yml para a sessão do agente;
-- liberar é declarar que o arquivo não tem dado pessoal (guardrail #2).
-- Colunas novas numa tabela que já tem RLS ligado — nada a mudar ali.
ALTER TABLE "anexos" ADD COLUMN "liberado_por_email" TEXT;
ALTER TABLE "anexos" ADD COLUMN "liberado_em" TIMESTAMP(3);
