import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

// O filtro carrega sempre o contrato do cliente do path junto do id do item:
// sem isso, quem gerencia um cliente editaria o entregável de outro trocando o
// id na URL.
async function contratoDo(clientId: string): Promise<string | null> {
  const c = await prisma.contrato.findUnique({ where: { clientId }, select: { id: true } });
  return c?.id ?? null;
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; entregavelId: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id, entregavelId } = await params;
  const contratoId = await contratoDo(id);
  if (!contratoId) return NextResponse.json({ error: "contrato não encontrado" }, { status: 404 });

  const body = await request.json();
  const data: { titulo?: string; descricao?: string; peso?: number; concluido?: boolean } = {};
  if (body.titulo !== undefined) {
    const t = String(body.titulo).trim();
    if (!t) return NextResponse.json({ error: "título vazio" }, { status: 400 });
    data.titulo = t.slice(0, 200);
  }
  if (body.descricao !== undefined) data.descricao = String(body.descricao).trim().slice(0, 2000);
  if (body.peso !== undefined) data.peso = Math.min(100, Math.max(1, Math.round(Number(body.peso) || 1)));
  if (body.concluido !== undefined) data.concluido = Boolean(body.concluido);

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nada pra atualizar" }, { status: 400 });
  }

  const { count } = await prisma.entregavel.updateMany({
    where: { id: entregavelId, contratoId },
    data,
  });
  if (count === 0) {
    return NextResponse.json({ error: "entregável não encontrado" }, { status: 404 });
  }

  const entregavel = await prisma.entregavel.findUnique({ where: { id: entregavelId } });
  return NextResponse.json(entregavel);
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; entregavelId: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id, entregavelId } = await params;
  const contratoId = await contratoDo(id);
  if (!contratoId) return NextResponse.json({ error: "contrato não encontrado" }, { status: 404 });

  // As demandas já geradas ficam — `onDelete: SetNull` no schema. Apagar um
  // item de escopo não pode levar junto trabalho que já está no quadro.
  const { count } = await prisma.entregavel.deleteMany({ where: { id: entregavelId, contratoId } });
  if (count === 0) {
    return NextResponse.json({ error: "entregável não encontrado" }, { status: 404 });
  }
  return new NextResponse(null, { status: 204 });
}
