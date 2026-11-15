-- Fila de disparo por ambiente (2026-11-15): a regra é uma demanda por vez,
-- por cliente, NA MESMA SANDBOX. A fila segurava o cliente inteiro, e a dev
-- ficava parada enquanto a QA testava. `ambiente` diz em qual sandbox o
-- disparo roda (dev | qa); `liberar_em` segura o disparo até a hora (segunda
-- sessão do QA em duas fases, depois da execução agendada).
ALTER TABLE "disparos_esteira" ADD COLUMN "ambiente" TEXT NOT NULL DEFAULT '';
ALTER TABLE "disparos_esteira" ADD COLUMN "liberar_em" TIMESTAMP(3);
