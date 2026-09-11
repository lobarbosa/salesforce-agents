import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

const TITULO_MAX = 200;

// O filtro sempre carrega `demandaId` junto do id do item: sem isso, quem
// alcança uma demanda conseguiria editar a subtarefa de outra só trocando o
// id na URL, porque o gate de acesso olha a demanda do path, não o dono real
// da linha.
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; subtarefaId: string }> }
) {
  const { id, subtarefaId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const body = await request.json();
  const data: { titulo?: string; feita?: boolean; responsavel?: string } = {};

  if (body.titulo !== undefined) {
    const titulo = String(body.titulo).trim();
    if (!titulo) return NextResponse.json({ error: "título vazio" }, { status: 400 });
    if (titulo.length > TITULO_MAX) {
      return NextResponse.json(
        { error: `título passa de ${TITULO_MAX} caracteres` },
        { status: 400 }
      );
    }
    data.titulo = titulo;
  }
  if (body.feita !== undefined) data.feita = Boolean(body.feita);
  if (body.responsavel !== undefined) data.responsavel = String(body.responsavel).trim();

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nada pra atualizar" }, { status: 400 });
  }

  const { count } = await prisma.subtarefa.updateMany({
    where: { id: subtarefaId, demandaId: id },
    data,
  });
  if (count === 0) {
    return NextResponse.json({ error: "subtarefa não encontrada" }, { status: 404 });
  }

  const subtarefa = await prisma.subtarefa.findUnique({ where: { id: subtarefaId } });
  return NextResponse.json(subtarefa);
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; subtarefaId: string }> }
) {
  const { id, subtarefaId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const { count } = await prisma.subtarefa.deleteMany({
    where: { id: subtarefaId, demandaId: id },
  });
  if (count === 0) {
    return NextResponse.json({ error: "subtarefa não encontrada" }, { status: 404 });
  }

  return new NextResponse(null, { status: 204 });
}
