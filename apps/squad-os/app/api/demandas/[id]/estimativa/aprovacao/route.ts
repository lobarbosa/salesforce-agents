import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { mudarCiclo } from "@/lib/ciclo-demanda";
import { aguardaAprovacaoEstimativa } from "@/lib/demandas";
import { processarFila } from "@/lib/fila-esteira";

// O cliente aprova ou segura a estimativa de horas da demanda (2026-10-21).
//
// - aprovar: grava o número aprovado (snapshot da estimativa oficial do
//   consultor). É ele que o gate de design exige para liberar o build e que
//   vira o débito no contrato quando a demanda entra em build. Se a demanda
//   estava segurada pelo cliente, aprovar também a descongela.
// - segurar: congela a demanda (mesmo caminho de "Congelar" do card), com o
//   motivo do cliente. Delivery vê o motivo e decide: revisar a estimativa
//   (o cliente aprova de novo) ou cancelar.
//
// Quem decide é o cliente; admin pode registrar em nome dele (fica no nome).
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { clienteAtivo: "agente" });
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;
  if (usuario.role !== "cliente" && usuario.role !== "admin") {
    return NextResponse.json({ error: "quem aprova a estimativa é o cliente" }, { status: 403 });
  }
  const autor = usuario.nome.trim() || usuario.email;

  const body = (await request.json().catch(() => null)) as { decisao?: unknown; motivo?: unknown; horas?: unknown } | null;
  const decisao = String(body?.decisao ?? "");
  const motivo = String(body?.motivo ?? "").trim().slice(0, 1000);
  if (decisao !== "aprovar" && decisao !== "segurar") {
    return NextResponse.json({ error: "decisão inválida" }, { status: 400 });
  }

  const d = await prisma.demanda.findUniqueOrThrow({ where: { id } });
  if (!aguardaAprovacaoEstimativa(d)) {
    return NextResponse.json({ error: "não há estimativa esperando aprovação nesta demanda" }, { status: 409 });
  }

  if (decisao === "segurar") {
    if (!motivo) return NextResponse.json({ error: "diga por que vai segurar a demanda" }, { status: 400 });
    if (d.status === "standby") return NextResponse.json({ error: "a demanda já está segurada" }, { status: 409 });
    const erro = await mudarCiclo(id, "congelar", `Cliente segurou a estimativa: ${motivo}`, autor);
    if (erro) return erro;
    await prisma.comentario.create({
      data: { demandaId: id, autor, autorEmail: usuario.email, texto: `Segurou a demanda na estimativa de ${d.estimativaConsultorHoras} h. Motivo: ${motivo}` },
    });
    return NextResponse.json({ ok: true });
  }

  // Aprova exatamente o número que a pessoa viu: se o consultor mudou no meio, recusa.
  if (Number(body?.horas) !== d.estimativaConsultorHoras) {
    return NextResponse.json({ error: "a estimativa mudou enquanto você decidia — recarregue" }, { status: 409 });
  }
  const { count } = await prisma.demanda.updateMany({
    where: { id, estimativaConsultorHoras: d.estimativaConsultorHoras },
    data: { estimativaAprovadaHoras: d.estimativaConsultorHoras, estimativaAprovadaPor: autor, estimativaAprovadaEm: new Date() },
  });
  if (count === 0) return NextResponse.json({ error: "a estimativa mudou — recarregue" }, { status: 409 });
  await prisma.comentario.create({
    data: { demandaId: id, autor, autorEmail: usuario.email, texto: `Aprovou a estimativa de ${d.estimativaConsultorHoras} h.` },
  });

  if (d.status === "standby") {
    const erro = await mudarCiclo(id, "descongelar", "", autor);
    if (erro) return erro;
  }
  // Uma aprovação de gate de design pode estar na fila esperando por isto.
  await processarFila(d.clientId).catch((e) => console.error("aprovacao-estimativa: processarFila", e));
  return NextResponse.json({ ok: true });
}
