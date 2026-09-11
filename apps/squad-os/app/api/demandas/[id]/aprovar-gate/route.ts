import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { triggerRunDemand } from "@/lib/github";

// O gate humano deixa de ser "aprova aqui e alguém dispara o pipeline lá":
// aprovar no card move a demanda e acende a próxima sessão de agente.
//
// Quem pode aprovar o quê segue a doutrina, não o papel genérico:
// `aguardando_homologacao` é o cliente dizendo que aceita o que foi entregue —
// é dele esse gate. Os outros (análise, design, PR) são internos de delivery e
// não fazem sentido pra quem está do lado de fora.
const GATE_DO_CLIENTE = "aguardando_homologacao";

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
    include: { client: { select: { slug: true } } },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }

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

  // Dispara ANTES de mexer no Postgres. Se o dispatch falhar, o estado local
  // continua dizendo "esperando gate", que é a verdade — o inverso deixaria o
  // quadro dizendo que avançou sem nada ter rodado. Quem escreve o status real
  // é o workflow, em status.yaml, e ele volta pelo /api/sync/demanda.
  try {
    await triggerRunDemand(demanda.client.slug, demanda.code, { aprovarGate: autor });
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao disparar o pipeline" },
      { status: 502 }
    );
  }

  // Registro local de quem liberou, pra a conversa do card ter o rastro sem
  // depender de abrir o git. O `gates.md` da demanda continua sendo o log
  // oficial — o agente escreve lá na etapa seguinte.
  await prisma.comentario.create({
    data: {
      demandaId: demanda.id,
      autor,
      autorEmail: usuario.email,
      texto: `Aprovou o gate "${demanda.status}". A próxima etapa foi disparada.`,
    },
  });

  return NextResponse.json({ ok: true, gate: demanda.status, por: autor });
}
