import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import type { Role } from "@/lib/generated/prisma/client";
import { serviceRoleConfigurado } from "@/lib/supabase/storage";
import { definirSenha } from "@/lib/supabase/senha";

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

  // Nova senha pra quem já tem conta — mesma operação de "Conceder acesso",
  // só que endereçada por id em vez de digitar o e-mail de novo. Tratado à
  // parte de role/clientId/nome porque precisa do e-mail (não vem no body,
  // vem do registro) e fala com o Supabase Auth, não só com o Postgres.
  if (typeof body.senha === "string" && body.senha.trim()) {
    const senha = body.senha.trim();
    if (senha.length < 8) {
      return NextResponse.json({ error: "senha precisa ter pelo menos 8 caracteres" }, { status: 400 });
    }
    const alvo = await prisma.usuario.findUnique({ where: { id } });
    if (!alvo) return NextResponse.json({ error: "usuário não encontrado" }, { status: 404 });
    if (!serviceRoleConfigurado()) {
      return NextResponse.json(
        { error: "SUPABASE_SERVICE_ROLE_KEY não configurada — não dá pra definir senha" },
        { status: 500 }
      );
    }
    const problema = await definirSenha(alvo.email, senha);
    if (problema) return NextResponse.json({ error: problema }, { status: 500 });
    return NextResponse.json({ ok: true });
  }

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
