-- Tela "Minhas horas" (timesheet semanal): a grade precisa distinguir a própria
-- parcela dos lançamentos feitos por cronômetro ou manualmente no card.
ALTER TABLE "registros_tempo" ADD COLUMN "origem" TEXT NOT NULL DEFAULT 'manual';

-- A grade consulta "minhas horas da semana": por autor e período.
CREATE INDEX "registros_tempo_autor_email_inicio_em_idx" ON "registros_tempo"("autor_email", "inicio_em");
