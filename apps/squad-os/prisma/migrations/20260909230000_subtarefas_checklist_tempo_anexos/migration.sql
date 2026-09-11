-- Subtarefas, checklist, registro de tempo e anexos por demanda. Como a
-- migration dos comentários, esta é puramente aditiva: só cria tabela nova,
-- não toca em coluna existente. Código que ainda não conhece essas tabelas
-- continua funcionando, então não há janela em que produção quebre entre o
-- migrate e o deploy.

-- CreateTable
CREATE TABLE "subtarefas" (
    "id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "feita" BOOLEAN NOT NULL DEFAULT false,
    "responsavel" TEXT NOT NULL DEFAULT '',
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subtarefas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "checklist_itens" (
    "id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "texto" TEXT NOT NULL,
    "feito" BOOLEAN NOT NULL DEFAULT false,
    "ordem" INTEGER NOT NULL DEFAULT 0,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "checklist_itens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registros_tempo" (
    "id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "autor" TEXT NOT NULL,
    "autor_email" TEXT NOT NULL,
    "descricao" TEXT NOT NULL DEFAULT '',
    "inicio_em" TIMESTAMP(3) NOT NULL,
    "fim_em" TIMESTAMP(3),
    "minutos" INTEGER,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "registros_tempo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "anexos" (
    "id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "caminho" TEXT NOT NULL,
    "tamanho" INTEGER NOT NULL,
    "tipo" TEXT NOT NULL DEFAULT '',
    "autor" TEXT NOT NULL,
    "autor_email" TEXT NOT NULL,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "anexos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "subtarefas_demanda_id_idx" ON "subtarefas"("demanda_id");
CREATE INDEX "checklist_itens_demanda_id_idx" ON "checklist_itens"("demanda_id");
CREATE INDEX "registros_tempo_demanda_id_idx" ON "registros_tempo"("demanda_id");
CREATE INDEX "anexos_demanda_id_idx" ON "anexos"("demanda_id");
CREATE UNIQUE INDEX "anexos_caminho_key" ON "anexos"("caminho");

-- AddForeignKey
ALTER TABLE "subtarefas" ADD CONSTRAINT "subtarefas_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "checklist_itens" ADD CONSTRAINT "checklist_itens_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "registros_tempo" ADD CONSTRAINT "registros_tempo_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "anexos" ADD CONSTRAINT "anexos_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
