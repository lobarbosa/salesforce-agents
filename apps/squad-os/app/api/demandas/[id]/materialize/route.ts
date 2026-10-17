import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { CodigoOcupadoNoGitError, materializeDemanda, triggerRunDemand } from "@/lib/github";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { recusaSeEncerrado } from "@/lib/encerramento-server";

// Materializa a demanda em clients/<slug>/demandas/<code>/ neste repo e
// dispara run-demand.yml. Chamado a partir do card (ver componentes/DemandModal)
// quando a demanda sai da triagem — não roda sozinho na criação, porque nem
// toda demanda criada vai virar execução imediatamente. Só admin/consultor:
// disparar o pipeline de agentes contra a sandbox é decisão operacional, não
// algo que o cliente final aciona sozinho.
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const demanda = await prisma.demanda.findUnique({ where: { id }, include: { client: true } });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  const encerrado = recusaSeEncerrado(demanda.client, "agente");
  if (encerrado) return encerrado;

  if (demanda.materializadoEm) {
    return NextResponse.json({ error: "esta demanda já foi materializada" }, { status: 409 });
  }

  // Reivindica antes de escrever no git: dois cliques (ou duas abas)
  // commitavam e disparavam o pipeline duas vezes. Só um updateMany acha
  // `materializadoEm` nulo; o outro recebe 409.
  const reivindicadaEm = new Date();
  const { count } = await prisma.demanda.updateMany({
    where: { id, materializadoEm: null },
    data: { materializadoEm: reivindicadaEm },
  });
  if (count === 0) {
    return NextResponse.json({ error: "esta demanda já está sendo materializada" }, { status: 409 });
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
    // Desfaz a reivindicação (só a nossa) pra poder tentar de novo. Reexecutar
    // é seguro: materializeDemanda aceita reescrever o próprio demanda.md.
    await prisma.demanda
      .updateMany({ where: { id, materializadoEm: reivindicadaEm }, data: { materializadoEm: null } })
      .catch((e) => console.error("materialize: falha ao desfazer a reivindicação", e));
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao materializar" },
      { status: err instanceof CodigoOcupadoNoGitError ? 409 : 502 }
    );
  }

  const updated = await prisma.demanda.findUnique({ where: { id } });
  return NextResponse.json(updated);
}
