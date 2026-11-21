import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { mudarCiclo } from "@/lib/ciclo-demanda";
import { propostaPendente } from "@/lib/assessment-propostas";

// O cliente aprova ou recusa a melhoria que o time propôs a partir do
// assessment da org (2026-11-21).
//
// - aprovar: a demanda continua no backlog, agora liberada; o time decide
//   quando manda para a esteira (decisão do responsável: a fila por cliente e
//   o consumo de horas do AMS ficam com o time).
// - recusar: cancela a demanda (mesmo caminho de "Cancelar" do card), com o
//   motivo do cliente. A recomendação fica ligada a ela e não é oferecida de
//   novo pelo copiloto.
//
// Só o papel cliente decide, como na aprovação da estimativa: uma aprovação
// que a Acxya dá a si mesma não vale como aprovação do cliente.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { clienteAtivo: "demanda" });
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;
  if (usuario.role !== "cliente") {
    return NextResponse.json({ error: "quem aprova a melhoria proposta é o cliente" }, { status: 403 });
  }
  const autor = usuario.nome.trim() || usuario.email;

  const body = (await request.json().catch(() => null)) as { decisao?: unknown; motivo?: unknown } | null;
  const decisao = String(body?.decisao ?? "");
  const motivo = String(body?.motivo ?? "").trim().slice(0, 1000);
  if (decisao !== "aprovar" && decisao !== "recusar") {
    return NextResponse.json({ error: "decisão inválida" }, { status: 400 });
  }
  if (decisao === "recusar" && !motivo) {
    return NextResponse.json({ error: "diga por que vai recusar a melhoria" }, { status: 400 });
  }

  const d = await prisma.demanda.findUniqueOrThrow({
    where: { id },
    select: { status: true, propostaClienteEm: true, propostaDecisao: true },
  });
  if (!propostaPendente(d) || d.status !== "backlog") {
    return NextResponse.json({ error: "não há melhoria esperando a sua aprovação nesta demanda" }, { status: 409 });
  }

  // Só uma decisão vale: dois cliques (ou duas abas) não gravam duas.
  const { count } = await prisma.demanda.updateMany({
    where: { id, propostaDecisao: "", status: "backlog" },
    data: {
      propostaDecisao: decisao === "aprovar" ? "aprovada" : "recusada",
      propostaDecididaPor: autor,
      propostaDecididaEm: new Date(),
    },
  });
  if (count === 0) return NextResponse.json({ error: "a melhoria já foi decidida — recarregue" }, { status: 409 });

  if (decisao === "recusar") {
    const erro = await mudarCiclo(id, "cancelar", `Cliente recusou a melhoria proposta: ${motivo}`, autor);
    if (erro) {
      // Não cancelou: desfaz a decisão para o cliente poder tentar de novo.
      await prisma.demanda.update({
        where: { id },
        data: { propostaDecisao: "", propostaDecididaPor: "", propostaDecididaEm: null },
      });
      return erro;
    }
  }

  await prisma.comentario.create({
    data: {
      demandaId: id,
      autor,
      autorEmail: usuario.email,
      texto:
        decisao === "aprovar"
          ? "Aprovou a melhoria proposta. Ela segue no backlog para a equipe programar."
          : `Recusou a melhoria proposta. Motivo: ${motivo}`,
    },
  });
  return NextResponse.json({ ok: true });
}
