import type { Role } from "@/lib/generated/prisma/client";

// Quem vê o quê no Squad OS, num lugar só. Proxy (navegação), páginas e APIs
// (o gate de verdade) e sidebar (o que aparece) leem daqui — um papel novo
// não pode depender de alguém lembrar de mais um `if` espalhado.
//
// - delivery:   clientes, demandas, Visão Geral e "Minhas horas" (o time que entrega)
// - financeiro: contas a pagar, aprovações, documentos da contabilidade,
//               painel financeiro, divergências e horas por cliente
// - operacao:   saúde dos agentes (quem responde pela plataforma)
// - admin:      gestão de usuários
export type Area = "delivery" | "financeiro" | "operacao" | "admin";

const AREAS: Record<Area, readonly Role[]> = {
  delivery: ["admin", "consultor"],
  financeiro: ["admin", "financeiro"],
  operacao: ["admin"],
  admin: ["admin"],
};

export function podeVer(role: Role, area: Area): boolean {
  return AREAS[area].includes(role);
}

/** A área de uma rota interna (página ou API). null = rota que não é de área (ex.: cliente, auth). */
export function areaDaRota(pathname: string): Area | null {
  const comeca = (p: string) => pathname === p || pathname.startsWith(p + "/");
  if (comeca("/financeiro") || comeca("/api/financeiro")) return "financeiro";
  if (comeca("/operacao") || comeca("/api/operacao")) return "operacao";
  if (comeca("/admin") || comeca("/api/admin")) return "admin";
  if (comeca("/horas") || comeca("/api/horas")) return "delivery";
  return null;
}

/** Para onde cada papel vai ao entrar (ou quando cai numa rota que não pode ver). */
export function inicioDo(role: Role, clientId: string | null): string {
  if (role === "cliente") return `/clients/${clientId}`;
  if (role === "financeiro") return "/financeiro";
  return "/";
}

export const ROTULO_PAPEL: Record<Role, string> = {
  admin: "admin",
  consultor: "consultor",
  financeiro: "financeiro",
  cliente: "cliente",
};
