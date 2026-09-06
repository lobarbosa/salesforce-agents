import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { generateDemandCode } from "@/lib/slug";

export async function POST(request: NextRequest) {
  const body = await request.json();
  const clientId = String(body.clientId ?? "");
  const titulo = String(body.titulo ?? "").trim();
  if (!clientId || !titulo) {
    return NextResponse.json({ error: "clientId e titulo são obrigatórios" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({ where: { id: clientId } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const autor = String(body.autor ?? "").trim();
  const tipo = body.tipo === "projeto" ? "projeto" : "sustentacao";
  const code = await generateDemandCode(clientId, client.slug);

  const demanda = await prisma.demanda.create({
    data: {
      clientId,
      code,
      titulo,
      tipo,
      texto: String(body.texto ?? "").trim(),
      autor,
      status: "backlog",
      historico: [{ de: null, para: "backlog", autor: autor || "os", em: new Date().toISOString() }],
    },
  });

  return NextResponse.json(demanda, { status: 201 });
}
