import type { Prisma } from "@/lib/generated/prisma/client";

/**
 * Lock de Postgres preso à transação (pg_advisory_xact_lock): duas
 * transações com a mesma `chave` rodam uma depois da outra, e o lock solta
 * sozinho no commit/rollback. É o "check-then-insert" atômico sem precisar de
 * índice único novo (que exigiria migration). Funciona no transaction pooler
 * porque vive dentro de uma transação só.
 *
 * `$executeRaw` e não `$queryRaw`: a função devolve `void`, que o Prisma não
 * sabe desserializar como linha.
 */
export async function travar(tx: Prisma.TransactionClient, chave: string): Promise<void> {
  await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${chave}))`;
}
