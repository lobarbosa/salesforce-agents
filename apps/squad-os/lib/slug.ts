import { prisma } from "@/lib/prisma";
import { proximoSufixo } from "@/lib/codigo-demanda";

const COMBINING_MARKS = /[̀-ͯ]/g;

// Deriva o slug de clients/<slug>/ a partir do nome de exibição — mesma ideia
// de normalização que src/salesforce_agents/demands.py:_next_id() usa pro
// prefixo do código de demanda, só que aplicada ao nome inteiro.
function baseSlug(nome: string): string {
  const ascii = nome.normalize("NFD").replace(COMBINING_MARKS, "");
  const slug = ascii
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return slug || "cliente";
}

export async function generateUniqueSlug(nome: string): Promise<string> {
  const base = baseSlug(nome);
  let candidate = base;
  let n = 2;
  while (await prisma.client.findUnique({ where: { slug: candidate } })) {
    candidate = `${base}-${n}`;
    n += 1;
  }
  return candidate;
}

// <CODE>-<n>, mesmo formato que o CLI sfagents já usa pra nomear
// clients/<slug>/demandas/<code>/ — código = slug reduzido a A-Z0-9 maiúsculo.
export function codePrefixFor(slug: string): string {
  const code = slug.toUpperCase().replace(/[^A-Z0-9]/g, "");
  return code || "CLI";
}

/**
 * Próximo código livre do cliente: maior sufixo numérico já usado + 1.
 *
 * Antes era `count + 1`, que colide assim que um número fica de fora (demanda
 * apagada, ou criada pela CLI com outro número) e quando duas criações correm
 * juntas (as duas contam N). O maior sufixo resolve o primeiro; o segundo
 * resolve `criarComCodigoUnico`, que tenta de novo no P2002 do
 * @@unique([clientId, code]). Demanda que só existe no git (CLI) o banco não
 * vê — essa colisão é barrada na materialização (lib/github.ts).
 */
export async function generateDemandCode(clientId: string, slug: string): Promise<string> {
  const prefix = codePrefixFor(slug);
  const existentes = await prisma.demanda.findMany({
    where: { clientId, code: { startsWith: `${prefix}-` } },
    select: { code: true },
  });
  return `${prefix}-${proximoSufixo(prefix, existentes.map((d) => d.code))}`;
}

function ehColisaoDeCodigo(e: unknown): boolean {
  return !!e && typeof e === "object" && (e as { code?: unknown }).code === "P2002";
}

/** Gera o código e cria; se outra criação pegou o mesmo número no meio, tenta o próximo. */
export async function criarComCodigoUnico<T>(
  clientId: string,
  slug: string,
  criar: (code: string) => Promise<T>,
  tentativas = 5
): Promise<T> {
  for (let i = 1; ; i++) {
    const code = await generateDemandCode(clientId, slug);
    try {
      return await criar(code);
    } catch (e) {
      if (!ehColisaoDeCodigo(e) || i >= tentativas) throw e;
    }
  }
}
