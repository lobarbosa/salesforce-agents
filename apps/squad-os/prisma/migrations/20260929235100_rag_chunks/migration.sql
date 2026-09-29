-- RAG interno por cliente (pipeline de agentes Python — nunca o copiloto do
-- cliente em Squad OS, ver CLAUDE.md guardrail #2). Schema.prisma modela a
-- coluna de embedding como Unsupported("vector(1536)") porque o tipo pgvector
-- não tem scalar nativo no Prisma sem preview feature; a extensão e a coluna
-- em si só existem via SQL cru, aqui.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE "rag_chunks" (
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "path" TEXT NOT NULL,
    "chunk_index" INTEGER NOT NULL,
    "conteudo" TEXT NOT NULL,
    "embedding" vector(1536),
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rag_chunks_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "rag_chunks_client_id_fkey" FOREIGN KEY ("client_id")
        REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "rag_chunks_client_id_path_idx" ON "rag_chunks"("client_id", "path");

-- ivfflat exige `lists` e funciona melhor com estatística de tabela — num
-- projeto novo (poucos clientes, corpus pequeno) 100 listas é excesso de
-- zelo, mas é barato e evita ter que lembrar de tunar isso depois. A busca
-- de verdade (lib/rag.ts) sempre filtra por client_id antes do `<=>`, então
-- o índice só precisa ser bom o bastante — o filtro por cliente já corta o
-- grosso do trabalho.
CREATE INDEX "rag_chunks_embedding_idx" ON "rag_chunks"
    USING ivfflat ("embedding" vector_cosine_ops) WITH (lists = 100);

-- Mesmo padrão das demais tabelas: RLS ligado, nenhuma policy. Sem isso o
-- Supabase publicaria clients_id + conteúdo (texto interno de demanda) via
-- PostgREST pra qualquer um com a anon key — achado real de 2026-09-09,
-- ver 20260910000000_rls_nas_tabelas_novas/migration.sql.
ALTER TABLE "rag_chunks" ENABLE ROW LEVEL SECURITY;
