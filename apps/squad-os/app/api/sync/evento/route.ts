import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";

// Esteira ao vivo (2026-10-21): recebe, em lote, os eventos que a sessão de
// agente manda enquanto roda (src/salesforce_agents/ao_vivo.py). Mesmo bearer
// por cliente das outras rotas de sync. Só metadata — e por isso cada campo é
// cortado curto aqui também: se um dia o lado Python mandar mais do que
// deveria, o banco não guarda.
const TIPOS = new Set(["inicio", "agente", "ferramenta", "turno", "fim"]);
const MAX_EVENTOS = 200;
const RETENCAO_MS = 7 * 24 * 3600 * 1000;

const curto = (v: unknown, n: number) => String(v ?? "").trim().slice(0, n);

export async function POST(request: NextRequest) {
  const body = (await request.json().catch(() => null)) as Record<string, unknown> | null;
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const clientSlug = curto(body.client, 80);
  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  const runId = curto(body.runId, 40);
  const eventos = Array.isArray(body.eventos) ? body.eventos.slice(0, MAX_EVENTOS) : [];
  if (!clientSlug || !runId || eventos.length === 0) {
    return NextResponse.json({ error: "client, runId e eventos são obrigatórios" }, { status: 400 });
  }
  const client = await prisma.client.findUnique({ where: { slug: clientSlug }, select: { id: true } });
  if (!client) return NextResponse.json({ aviso: `cliente '${clientSlug}' não encontrado` }, { status: 202 });

  const runUrlBruta = curto(body.runUrl, 300);
  const base = {
    clientId: client.id,
    runId,
    runUrl: runUrlBruta.startsWith("https://github.com/") ? runUrlBruta : "",
    demandaCode: curto(body.demandaId, 40),
    etapa: curto(body.etapa, 40),
  };
  const agora = Date.now();
  const data = eventos
    .filter((e): e is Record<string, unknown> => !!e && typeof e === "object" && TIPOS.has(String((e as Record<string, unknown>).tipo)))
    .map((e) => {
      const em = Date.parse(String(e.em ?? ""));
      const custo = Number(e.custoUsd);
      return {
        ...base,
        tipo: String(e.tipo),
        agente: curto(e.agente, 60),
        ferramenta: curto(e.ferramenta, 60),
        detalhe: curto(e.detalhe, 120),
        custoUsd: Number.isFinite(custo) && custo >= 0 ? custo : null,
        // Relógio do runner, mas nunca no futuro nem antigo demais.
        em: new Date(Number.isFinite(em) && em <= agora && em > agora - RETENCAO_MS ? em : agora),
      };
    });
  if (data.length) await prisma.eventoEsteira.createMany({ data });

  // Faxina barata: o histórico durável é ExecucaoAgente; isto aqui é o "agora".
  await prisma.eventoEsteira.deleteMany({ where: { em: { lt: new Date(agora - RETENCAO_MS) } } });
  return NextResponse.json({ ok: true, gravados: data.length });
}
