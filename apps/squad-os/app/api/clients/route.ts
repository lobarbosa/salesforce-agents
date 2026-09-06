import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { generateUniqueSlug } from "@/lib/slug";

// Auth já é garantida pelo proxy.ts (sessão Supabase + allowlist) pra toda
// rota fora de /login e /auth/callback — inclusive /api/**.
export async function POST(request: NextRequest) {
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
