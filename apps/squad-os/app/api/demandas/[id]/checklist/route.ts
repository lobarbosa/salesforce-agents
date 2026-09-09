import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

const TEXTO_MAX = 200;

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const body = await request.json();
  const texto = String(body.texto ?? "").trim();
  if (!texto) {
    return NextResponse.json({ error: "item vazio" }, { status: 400 });
  }
  if (texto.length > TEXTO_MAX) {
    return NextResponse.json(
      { error: `item passa de ${TEXTO_MAX} caracteres` },
      { status: 400 }
    );
  }

  const ultimo = await prisma.checklistItem.findFirst({
    where: { demandaId: id },
    orderBy: { ordem: "desc" },
    select: { ordem: true },
  });

  const item = await prisma.checklistItem.create({
    data: { demandaId: id, texto, ordem: (ultimo?.ordem ?? -1) + 1 },
  });

  return NextResponse.json(item, { status: 201 });
}
