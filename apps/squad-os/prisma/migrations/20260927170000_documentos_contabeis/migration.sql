-- Documentos da contabilidade (sai a lista CLICKUP_LIST_CONTABILIDADE).
CREATE TABLE "documentos_contabeis" (
    "id" TEXT NOT NULL,
    "competencia" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "caminho" TEXT NOT NULL,
    "mime" TEXT NOT NULL DEFAULT '',
    "tamanho" INTEGER NOT NULL DEFAULT 0,
    "enviado_por_email" TEXT NOT NULL,
    "enviado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "removido_em" TIMESTAMP(3),
    "removido_por_email" TEXT,
    CONSTRAINT "documentos_contabeis_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "documentos_contabeis_competencia_formato" CHECK ("competencia" ~ '^\d{4}-(0[1-9]|1[0-2])$'),
    CONSTRAINT "documentos_contabeis_tipo_valido"
        CHECK ("tipo" IN ('balancete', 'dre', 'guia_imposto', 'relacao_notas', 'outro'))
);

CREATE INDEX "documentos_contabeis_competencia_idx" ON "documentos_contabeis"("competencia");

-- Mesmo padrão das demais tabelas: RLS ligado, nenhuma policy.
ALTER TABLE "documentos_contabeis" ENABLE ROW LEVEL SECURITY;
