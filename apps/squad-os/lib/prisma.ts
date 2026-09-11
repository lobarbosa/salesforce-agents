import { PrismaClient } from "@/lib/generated/prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

// Prisma 7 usa driver adapters em vez de conexão implícita por url no schema —
// singleton de dev evita esgotar conexões com o hot-reload do Next.js.
//
// `DATABASE_URL` aqui é o **transaction pooler** (6543): Vercel Functions são
// clientes efêmeros e a conexão precisa voltar pro pool a cada statement. A
// migração usa outra variável, `DIRECT_URL` (session pooler, 5432), lida por
// prisma7.config.ts — DDL numa sessão longa é o que transaction mode não
// sustenta. Ver README, "Setup".
//
// Transaction mode não suporta prepared statement, e isso aqui é um não-problema
// verificável: @prisma/adapter-pg só nomeia a query quando recebe
// `statementNameGenerator` nas opções (ver `performIO` em
// node_modules/@prisma/adapter-pg/dist/index.js), e não passamos. Query sem nome
// = statement não preparado. Por isso também não existe `?pgbouncer=true` na
// URL: é parâmetro do Prisma clássico, sem efeito com driver adapter.
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

function createClient() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL não configurada — ver apps/squad-os/README.md");
  }
  const adapter = new PrismaPg({ connectionString });
  return new PrismaClient({ adapter });
}

export const prisma = globalForPrisma.prisma ?? createClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
