import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { consultarRag } from "@/lib/rag";

// Consulta do RAG interno — chamada pela ferramenta rag_consultar do
// pipeline Python (src/salesforce_agents/rag.py) DURANTE a sessão do agente,
// diferente dos outros /api/sync/* (que só recebem resultado depois que o
// job terminou). Mesmo bearer token, mesmo guardrail: clientSlug decide
// tudo, resolvido pra clientId aqui — nunca aceitar clientId direto do
// corpo, e a busca em lib/rag.ts sempre filtra por ele (guardrail #7).
const K_PADRAO = 6;
const K_MAXIMO = 20;
const PERGUNTA_MAX = 2000;

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const registro = body as Record<string, unknown>;

  const clientSlug = String(registro.clientSlug ?? "").trim();

  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  const pergunta = String(registro.pergunta ?? "").trim().slice(0, PERGUNTA_MAX);
  const kPedido = Number(registro.k);
  const k = Math.min(Math.max(Number.isFinite(kPedido) && kPedido > 0 ? kPedido : K_PADRAO, 1), K_MAXIMO);

  if (!clientSlug || !pergunta) {
    return NextResponse.json({ error: "clientSlug e pergunta são obrigatórios" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({ where: { slug: clientSlug }, select: { id: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const resultados = await consultarRag(client.id, pergunta, k);
  return NextResponse.json({ resultados }, { status: 200 });
}
