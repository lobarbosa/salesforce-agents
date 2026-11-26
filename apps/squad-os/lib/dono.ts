import type { Role } from "@/lib/generated/prisma/client";

// Dono da demanda (2026-11-26): a pessoa do time que responde por ela do
// começo ao fim. Não é quem criou (`autor`), que fica como registro, nem quem
// aprova gate, que continua sendo o papel certo de cada gate. Achado que
// motivou: sem dono, demanda parada era "do time" — ou seja, de ninguém.
//
// Módulo puro: quem lê e grava é app/api/demandas/[id]/dono/route.ts e
// lib/demandas-server.ts.

/** Só gente do time responde por uma demanda. Cliente e financeiro, não. */
export function podeSerDono(role: Role): boolean {
  return role === "admin" || role === "consultor";
}

/** Quem cria é o dono, se for do time; o cliente que abre demanda não é. */
export function donoInicial(usuario: { id: string; role: Role }): string | null {
  return podeSerDono(usuario.role) ? usuario.id : null;
}

export interface PessoaDoTime {
  id: string;
  nome: string;
  email: string;
}

/** Como o dono aparece na tela: o nome, ou o e-mail de quem não tem nome. */
export function nomeDoDono(dono: { nome: string; email?: string } | null | undefined): string {
  if (!dono) return "";
  return dono.nome.trim() || dono.email || "";
}

/** Primeiro nome, para o card do quadro, onde o espaço é curto. */
export function primeiroNome(dono: { nome: string; email?: string } | null | undefined): string {
  const nome = nomeDoDono(dono);
  return nome.includes("@") ? nome : nome.split(/\s+/)[0] ?? "";
}

/**
 * Valida o corpo do PUT. `null` tira o dono; string é o id de alguém da lista
 * do time. Qualquer outra coisa é recusada, não convertida.
 */
export function lerDonoDoCorpo(body: unknown): { ok: true; donoId: string | null } | { ok: false } {
  if (!body || typeof body !== "object" || Array.isArray(body)) return { ok: false };
  const chaves = Object.keys(body);
  if (chaves.length !== 1 || chaves[0] !== "donoId") return { ok: false };
  const v = (body as { donoId: unknown }).donoId;
  if (v === null) return { ok: true, donoId: null };
  if (typeof v === "string" && /^[A-Za-z0-9_-]{1,64}$/.test(v)) return { ok: true, donoId: v };
  return { ok: false };
}
