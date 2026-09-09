import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

const TITULO_MAX = 200;

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const body = await request.json();
  const titulo = String(body.titulo ?? "").trim();
  if (!titulo) {
    return NextResponse.json({ error: "título vazio" }, { status: 400 });
  }
  if (titulo.length > TITULO_MAX) {
    return NextResponse.json(
      { error: `título passa de ${TITULO_MAX} caracteres` },
      { status: 400 }
    );
  }

  // Entra sempre no fim da lista. `ordem` é derivada do maior valor atual e
  // não do total de linhas: apagar uma subtarefa do meio não pode fazer a
  // próxima nascer com a ordem de uma que já existe.
  const ultima = await prisma.subtarefa.findFirst({
    where: { demandaId: id },
    orderBy: { ordem: "desc" },
    select: { ordem: true },
  });

  const subtarefa = await prisma.subtarefa.create({
    data: {
      demandaId: id,
      titulo,
      responsavel: String(body.responsavel ?? "").trim(),
      ordem: (ultima?.ordem ?? -1) + 1,
    },
  });

  return NextResponse.json(subtarefa, { status: 201 });
}
