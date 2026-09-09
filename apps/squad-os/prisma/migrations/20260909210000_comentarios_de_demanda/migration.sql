-- Comentários por demanda. Diferente da migration anterior, esta é puramente
-- aditiva: cria tabela nova e não toca em nenhuma coluna existente. Código
-- que ainda não conhece `comentarios` continua funcionando normalmente, então
-- não há janela em que produção quebre entre o migrate e o deploy do código.

-- CreateTable
CREATE TABLE "comentarios" (
    "id" TEXT NOT NULL,
    "demanda_id" TEXT NOT NULL,
    "autor" TEXT NOT NULL,
    "autor_email" TEXT NOT NULL,
    "texto" TEXT NOT NULL,
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comentarios_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "comentarios_demanda_id_idx" ON "comentarios"("demanda_id");

-- AddForeignKey
ALTER TABLE "comentarios" ADD CONSTRAINT "comentarios_demanda_id_fkey"
    FOREIGN KEY ("demanda_id") REFERENCES "demandas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
