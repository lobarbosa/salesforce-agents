import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import type { Role } from "@/lib/generated/prisma/client";

const ROLES: Role[] = ["admin", "consultor", "cliente"];

// proxy.ts já bloqueia /api/admin/** pra quem não é admin — a checagem
// abaixo é defesa em profundidade, não o gate principal.
export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario || usuario.role !== "admin") {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json();
  const email = String(body.email ?? "").toLowerCase().trim();
  const role = body.role as Role;
  const clientId = body.clientId ? String(body.clientId) : null;

  if (!email || !ROLES.includes(role)) {
    return NextResponse.json({ error: "email e role válidos são obrigatórios" }, { status: 400 });
  }
  if (role === "cliente" && !clientId) {
    return NextResponse.json({ error: "role=cliente precisa de um cliente atribuído" }, { status: 400 });
  }

  const novo = await prisma.usuario.upsert({
    where: { email },
    update: { role, clientId: role === "cliente" ? clientId : null, nome: String(body.nome ?? "").trim() },
    create: {
      email,
      nome: String(body.nome ?? "").trim(),
      role,
      clientId: role === "cliente" ? clientId : null,
      concedidoPor: usuario.email,
    },
  });

  return NextResponse.json(novo, { status: 201 });
}
