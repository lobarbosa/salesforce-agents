import { prisma } from "@/lib/prisma";

// Teto durável de uso, contado no Postgres (tabela limites_uso).
//
// Complementa, não substitui, o limite por minuto em memória do copiloto:
// aquele segura rajada barato dentro de uma instância; este segura o total,
// mesmo com N instâncias serverless e cold starts. Um único INSERT ... ON
// CONFLICT DO UPDATE ... RETURNING é atômico — duas requisições simultâneas
// não leem o mesmo valor.

/** Janela diária em UTC, ex.: "2026-10-17". */
export function janelaDoDia(agora = new Date()): string {
  return agora.toISOString().slice(0, 10);
}

/** Incrementa e devolve se ainda está dentro do limite (contando esta). */
export async function consumirLimite(chave: string, maximo: number, janela = janelaDoDia()): Promise<boolean> {
  const linhas = await prisma.$queryRaw<{ contagem: number }[]>`
    INSERT INTO "limites_uso" ("chave", "janela", "contagem")
    VALUES (${chave}, ${janela}, 1)
    ON CONFLICT ("chave", "janela") DO UPDATE SET "contagem" = "limites_uso"."contagem" + 1
    RETURNING "contagem"`;
  return (linhas[0]?.contagem ?? 0) <= maximo;
}
