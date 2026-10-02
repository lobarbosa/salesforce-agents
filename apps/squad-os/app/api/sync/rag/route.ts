import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { ingerirDocumentos } from "@/lib/rag";

// Reingestão do RAG interno de um cliente — chamada por run-demand.yml depois
// de commitar os artefatos da etapa (nunca pelo próprio agente: o token fica
// só no ambiente do workflow, igual aos outros /api/sync/*). Sempre
// "apaga path, insere de novo" (ver lib/rag.ts) — o body manda o conteúdo
// atual de cada documento, não um diff.
const MAX_DOCUMENTOS = 200;
const MAX_CONTEUDO = 50_000;

interface DocumentoBruto {
  path: string;
  content: string;
}

function normalizarDocumentos(bruto: unknown): DocumentoBruto[] {
  if (!Array.isArray(bruto)) return [];
  return bruto
    .filter((d): d is Record<string, unknown> => !!d && typeof d === "object")
    .map((d) => ({
      path: String(d.path ?? "").trim().slice(0, 500),
      content: String(d.content ?? "").slice(0, MAX_CONTEUDO),
    }))
    .filter((d) => d.path && d.content)
    .slice(0, MAX_DOCUMENTOS);
}

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const registro = body as Record<string, unknown>;

  const clientSlug = String(registro.clientSlug ?? "").trim();

  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  const documentos = normalizarDocumentos(registro.documents);
  if (!clientSlug || documentos.length === 0) {
    return NextResponse.json({ error: "clientSlug e documents são obrigatórios" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({ where: { slug: clientSlug }, select: { id: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const resultado = await ingerirDocumentos(
    client.id,
    documentos.map((d) => ({ path: d.path, conteudo: d.content }))
  );
  return NextResponse.json(resultado, { status: 200 });
}
