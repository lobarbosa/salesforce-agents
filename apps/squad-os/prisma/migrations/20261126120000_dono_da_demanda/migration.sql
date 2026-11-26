-- Dono da demanda: a pessoa do time que responde por ela. Só acrescenta
-- colunas opcionais, então aplicar antes do código novo não quebra nada.
ALTER TABLE "demandas"
  ADD COLUMN "dono_id" TEXT,
  ADD COLUMN "dono_definido_em" TIMESTAMP(3),
  ADD COLUMN "dono_definido_por" TEXT NOT NULL DEFAULT '';

CREATE INDEX "demandas_dono_id_idx" ON "demandas"("dono_id");

ALTER TABLE "demandas"
  ADD CONSTRAINT "demandas_dono_id_fkey" FOREIGN KEY ("dono_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Demandas que já existem: o dono é quem criou, quando o autor é uma pessoa
-- do time, pelo nome (único no portal) ou pelo e-mail. "X (via Claude)" é
-- registro feito em nome de X. As outras ficam sem dono e o card mostra.
WITH autores AS (
  SELECT d."id", lower(trim(regexp_replace(d."autor", '\s*\(via Claude\)\s*$', ''))) AS quem
  FROM "demandas" d
  WHERE d."dono_id" IS NULL AND d."autor" <> ''
),
time AS (
  SELECT u."id", lower(trim(u."nome")) AS nome, lower(u."email") AS email
  FROM "usuarios" u
  WHERE u."role" IN ('admin', 'consultor')
),
nomes_unicos AS (
  SELECT nome FROM time WHERE nome <> '' GROUP BY nome HAVING count(*) = 1
),
par AS (
  SELECT a."id" AS demanda_id, t."id" AS usuario_id
  FROM autores a
  JOIN time t ON t.email = a.quem OR (t.nome = a.quem AND t.nome IN (SELECT nome FROM nomes_unicos))
)
UPDATE "demandas" d
SET "dono_id" = par.usuario_id, "dono_definido_em" = d."criado_em", "dono_definido_por" = 'migração (autor da demanda)'
FROM par
WHERE d."id" = par.demanda_id
  AND (SELECT count(DISTINCT p2.usuario_id) FROM par p2 WHERE p2.demanda_id = d."id") = 1;
