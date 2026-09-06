import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import type { Role } from "@/lib/generated/prisma/client";

const ROLES: Role[] = ["admin", "consultor", "cliente"];

async function wouldRemoveLastAdmin(targetId: string, novoRole: Role | null): Promise<boolean> {
  const target = await prisma.usuario.findUnique({ where: { id: targetId } });
  if (!target || target.role !== "admin") return false;
  if (novoRole === "admin") return false; // continua admin, não é remoção
  const totalAdmins = await prisma.usuario.count({ where: { role: "admin" } });
  return totalAdmins <= 1;
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || usuario.role !== "admin") {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();
  const data: { role?: Role; clientId?: string | null; nome?: string } = {};

  if ("role" in body) {
    const role = body.role as Role;
    if (!ROLES.includes(role)) {
      return NextResponse.json({ error: "role inválida" }, { status: 400 });
    }
    if (await wouldRemoveLastAdmin(id, role)) {
      return NextResponse.json(
        { error: "esse é o último admin — promova outra pessoa antes de rebaixar" },
        { status: 400 }
      );
    }
    data.role = role;
    if (role !== "cliente") data.clientId = null;
  }

  if ("clientId" in body) {
    data.clientId = body.clientId ? String(body.clientId) : null;
  }

  if ("nome" in body) {
    data.nome = String(body.nome ?? "").trim();
  }

  try {
    const atualizado = await prisma.usuario.update({ where: { id }, data });
    return NextResponse.json(atualizado);
  } catch {
    return NextResponse.json({ error: "usuário não encontrado" }, { status: 404 });
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || usuario.role !== "admin") {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  if (await wouldRemoveLastAdmin(id, null)) {
    return NextResponse.json(
      { error: "esse é o último admin — promova outra pessoa antes de remover" },
      { status: 400 }
    );
  }

  try {
    await prisma.usuario.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "usuário não encontrado" }, { status: 404 });
  }
}
