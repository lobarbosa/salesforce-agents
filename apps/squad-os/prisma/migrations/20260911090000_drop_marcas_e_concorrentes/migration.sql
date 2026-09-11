-- Passo 2 de 2: as colunas saem do banco.
--
-- `marcas` e `concorrentes` saíram do schema Prisma em 2026-09-09, mas ficaram
-- no banco de propósito. Preview e Production compartilham o mesmo
-- DATABASE_URL, então o build de preview de um PR migra a produção **antes** do
-- merge: remover uma coluna que a `main` ainda lê derrubaria a produção no
-- instante em que o PR abrisse. Com o PR #12 mergeado, nenhum código em `main`
-- conhece essas colunas, e o DROP deixou de ser destrutivo na prática.
--
-- Conferido antes de escrever: as duas são `text`, e os 5 clientes têm string
-- vazia (0 bytes) nas duas. Não há dado a perder.
--
-- `IF EXISTS` porque este banco já pode ter sido migrado à mão; a migration
-- precisa ser idempotente para não travar um deploy por já estar feita.

ALTER TABLE "clients" DROP COLUMN IF EXISTS "marcas";
ALTER TABLE "clients" DROP COLUMN IF EXISTS "concorrentes";
