import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

const TEXTO_MAX = 200;

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; itemId: string }> }
) {
  const { id, itemId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const body = await request.json();
  const data: { texto?: string; feito?: boolean } = {};

  if (body.texto !== undefined) {
    const texto = String(body.texto).trim();
    if (!texto) return NextResponse.json({ error: "item vazio" }, { status: 400 });
    if (texto.length > TEXTO_MAX) {
      return NextResponse.json(
        { error: `item passa de ${TEXTO_MAX} caracteres` },
        { status: 400 }
      );
    }
    data.texto = texto;
  }
  if (body.feito !== undefined) data.feito = Boolean(body.feito);

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nada pra atualizar" }, { status: 400 });
  }

  const { count } = await prisma.checklistItem.updateMany({
    where: { id: itemId, demandaId: id },
    data,
  });
  if (count === 0) {
    return NextResponse.json({ error: "item não encontrado" }, { status: 404 });
  }

  const item = await prisma.checklistItem.findUnique({ where: { id: itemId } });
  return NextResponse.json(item);
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; itemId: string }> }
) {
  const { id, itemId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const { count } = await prisma.checklistItem.deleteMany({
    where: { id: itemId, demandaId: id },
  });
  if (count === 0) {
    return NextResponse.json({ error: "item não encontrado" }, { status: 404 });
  }

  return new NextResponse(null, { status: 204 });
}
