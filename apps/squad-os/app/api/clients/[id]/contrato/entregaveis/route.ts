import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

const TITULO_MAX = 200;

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const contrato = await prisma.contrato.findUnique({
    where: { clientId: id },
    select: { id: true, tipo: true },
  });
  if (!contrato) {
    return NextResponse.json({ error: "o cliente ainda não tem contrato" }, { status: 409 });
  }
  if (contrato.tipo !== "projeto") {
    return NextResponse.json(
      { error: "entregáveis só existem em contrato de projeto" },
      { status: 409 }
    );
  }

  const body = await request.json();
  const titulo = String(body.titulo ?? "").trim();
  if (!titulo) return NextResponse.json({ error: "título vazio" }, { status: 400 });
  if (titulo.length > TITULO_MAX) {
    return NextResponse.json({ error: `título passa de ${TITULO_MAX} caracteres` }, { status: 400 });
  }

  const ultimo = await prisma.entregavel.findFirst({
    where: { contratoId: contrato.id },
    orderBy: { ordem: "desc" },
    select: { ordem: true },
  });

  const entregavel = await prisma.entregavel.create({
    data: {
      contratoId: contrato.id,
      titulo,
      descricao: String(body.descricao ?? "").trim().slice(0, 2000),
      peso: Math.min(100, Math.max(1, Math.round(Number(body.peso) || 1))),
      ordem: (ultimo?.ordem ?? -1) + 1,
    },
  });

  return NextResponse.json(entregavel, { status: 201 });
}
