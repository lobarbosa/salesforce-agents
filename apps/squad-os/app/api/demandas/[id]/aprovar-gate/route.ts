import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { triggerRunDemand } from "@/lib/github";
import { GATE_DO_CLIENTE } from "@/lib/demandas";
import { travar } from "@/lib/trava";
import { recusaSeEncerrado } from "@/lib/encerramento-server";

// O gate humano deixa de ser "aprova aqui e alguém dispara o pipeline lá":
// aprovar no card move a demanda e acende a próxima sessão de agente.
//
// Quem pode aprovar o quê segue a doutrina, não o papel genérico:
// `aguardando_homologacao` é o cliente dizendo que aceita o que foi entregue —
// é dele esse gate. Os outros (análise, design, PR) são internos de delivery e
// não fazem sentido pra quem está do lado de fora. A constante mora em
// lib/demandas.ts: a tela, esta rota e o PATCH de perguntas/aprovação
// precisam responder isto pelo mesmo lugar.

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    include: { client: { select: { slug: true, nome: true, encerradoEm: true } } },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  // Aprovar gate dispara a próxima sessão de agente.
  const encerrado = recusaSeEncerrado(demanda.client, "agente");
  if (encerrado) return encerrado;

  if (!demanda.status.startsWith("aguardando_")) {
    return NextResponse.json(
      { error: `a demanda está em '${demanda.status}', que não é um gate humano` },
      { status: 409 }
    );
  }

  if (usuario.role === "cliente" && demanda.status !== GATE_DO_CLIENTE) {
    return NextResponse.json(
      { error: "este gate é interno de delivery — quem aprova é o time da Acxya" },
      { status: 403 }
    );
  }

  if (!demanda.materializadoEm) {
    return NextResponse.json(
      { error: "a demanda ainda não foi materializada — não existe no repositório pra avançar" },
      { status: 409 }
    );
  }

  const autor = usuario.nome.trim() || usuario.email;
  const gate = demanda.status;
  const marcador = `Aprovou o gate "${gate}".`;

  // Reivindica a aprovação ANTES de disparar (compare-and-set). Achado da
  // revisão de 2026-10-12: dois cliques (ou duas pessoas) disparavam o
  // workflow duas vezes; a segunda execução esperava na fila do concurrency
  // group e, quando rodava, a demanda já estava no gate SEGUINTE — e aprovava
  // esse também, sem ninguém ter olhado. O schema não tem um campo "gate
  // liberado em", então a reivindicação é o próprio comentário de rastro,
  // criado sob um lock transacional por demanda: só passa quem não encontra
  // um "Aprovou o gate X" posterior à última execução sincronizada (uma
  // execução nova — inclusive uma que falhou — reabre o gate pra nova
  // tentativa). O workflow ainda confere `gate_esperado` do lado dele.
  const claim = await prisma.$transaction(async (tx) => {
    await travar(tx, `aprovar-gate:${demanda.id}`);
    const atual = await tx.demanda.findUnique({
      where: { id: demanda.id },
      select: { status: true, ultimaExecucaoEm: true, materializadoEm: true },
    });
    if (!atual || atual.status !== gate) return { conflito: "a demanda saiu deste gate enquanto você decidia — recarregue" };
    const desde = atual.ultimaExecucaoEm ?? atual.materializadoEm ?? new Date(0);
    const jaAprovado = await tx.comentario.findFirst({
      where: { demandaId: demanda.id, texto: { startsWith: marcador }, criadoEm: { gt: desde } },
      select: { autor: true },
    });
    if (jaAprovado) {
      return { conflito: `este gate já foi liberado por ${jaAprovado.autor} — a próxima etapa está rodando` };
    }
    // Registro local de quem liberou, pra a conversa do card ter o rastro sem
    // depender de abrir o git. O `gates.md` da demanda continua sendo o log
    // oficial — o agente escreve lá na etapa seguinte.
    const comentario = await tx.comentario.create({
      data: {
        demandaId: demanda.id,
        autor,
        autorEmail: usuario.email,
        texto: `${marcador} A próxima etapa foi disparada.`,
      },
      select: { id: true },
    });
    return { comentarioId: comentario.id };
  });
  if ("conflito" in claim) {
    return NextResponse.json({ error: claim.conflito }, { status: 409 });
  }

  // Quem escreve o status real é o workflow, em status.yaml, e ele volta pelo
  // /api/sync/demanda — o Postgres não avança a etapa aqui. Se o dispatch
  // falhar, a reivindicação é desfeita e o gate continua esperando, que é a
  // verdade.
  try {
    await triggerRunDemand(demanda.client.slug, demanda.code, { aprovarGate: autor, gateEsperado: gate });
  } catch (err) {
    await prisma.comentario.delete({ where: { id: claim.comentarioId } }).catch((e) => {
      console.error("aprovar-gate: falha ao desfazer a reivindicação", e);
    });
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao disparar o pipeline" },
      { status: 502 }
    );
  }

  return NextResponse.json({ ok: true, gate, por: autor });
}
