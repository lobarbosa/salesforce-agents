import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { generateUniqueSlug } from "@/lib/slug";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

// Auth (sessão Supabase + Usuario autorizado) já é garantida pelo proxy.ts
// pra toda rota fora de /login e /auth/callback — inclusive /api/**. O que
// falta checar aqui é autorização por papel: só admin/consultor criam
// cliente (tenant) novo, nunca role=cliente.
export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json();
  const nome = String(body.nome ?? "").trim();
  if (!nome) {
    return NextResponse.json({ error: "nome é obrigatório" }, { status: 400 });
  }

  const slug = await generateUniqueSlug(nome);
  const client = await prisma.client.create({
    data: {
      nome,
      slug,
      segmento: String(body.segmento ?? "").trim(),
    },
  });

  return NextResponse.json(client, { status: 201 });
}
