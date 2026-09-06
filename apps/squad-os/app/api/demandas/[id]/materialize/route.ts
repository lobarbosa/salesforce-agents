import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { materializeDemanda, triggerRunDemand } from "@/lib/github";

// Materializa a demanda em clients/<slug>/demandas/<code>/ neste repo e
// dispara run-demand.yml. Chamado a partir do card (ver componentes/DemandModal)
// quando a demanda sai da triagem — não roda sozinho na criação, porque nem
// toda demanda criada vai virar execução imediatamente.
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const demanda = await prisma.demanda.findUnique({ where: { id }, include: { client: true } });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }

  try {
    await materializeDemanda({
      code: demanda.code,
      clientSlug: demanda.client.slug,
      titulo: demanda.titulo,
      texto: demanda.texto,
      tipo: demanda.tipo,
      status: demanda.status,
      criadoEm: demanda.criadoEm,
      historico: demanda.historico,
    });
    await triggerRunDemand(demanda.client.slug, demanda.code);
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao materializar" },
      { status: 502 }
    );
  }

  const updated = await prisma.demanda.update({
    where: { id },
    data: { materializadoEm: new Date() },
  });
  return NextResponse.json(updated);
}
