import { prisma } from "@/lib/prisma";

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

export async function generateDemandCode(clientId: string, slug: string): Promise<string> {
  const prefix = codePrefixFor(slug);
  const count = await prisma.demanda.count({ where: { clientId } });
  return `${prefix}-${count + 1}`;
}
