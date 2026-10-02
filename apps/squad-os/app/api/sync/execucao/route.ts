import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";

// O rastro de observabilidade (council de 2026-10-01): admin pedia visão de
// todas as execuções da plataforma; consultor, uma tela do que falhou, pra
// não ficar no escuro. Cada um dos 4 workflows que já reporta resultado pra
// algum lugar (run-demand.yml, run-assessment.yml, run-planejamento.yml,
// test-connection.yml) manda também uma linha aqui, `if: always()` — uma
// execução que falhou é tão observável quanto uma que passou.
//
// Nunca é fonte de verdade: o git continua sendo (guardrail #5). Isto é só
// o espelho histórico — ExecucaoAgente nunca é lido por nada que decida
// estado da demanda, só pelas telas de observabilidade.

const ORIGENS = new Set(["demanda", "assessment", "planejamento", "conexao"]);
const RESULTADOS = new Set(["success", "failure", "cancelled"]);

function urlDeRunValida(bruto: unknown): string {
  const url = String(bruto ?? "").trim().slice(0, 500);
  return url.startsWith("https://github.com/") ? url : "";
}

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const clientSlug = String(body.client ?? "");

  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  const origem = String(body.origem ?? "");
  const etapa = String(body.etapa ?? "").trim().slice(0, 120);
  const resultado = String(body.resultado ?? "");

  if (!clientSlug || !ORIGENS.has(origem) || !etapa || !RESULTADOS.has(resultado)) {
    return NextResponse.json(
      { error: "client, origem (demanda|assessment|planejamento|conexao), etapa e resultado (success|failure|cancelled) são obrigatórios" },
      { status: 400 }
    );
  }

  const client = await prisma.client.findUnique({ where: { slug: clientSlug }, select: { id: true } });
  if (!client) {
    // Mesmo tratamento de /api/sync/demanda: não é erro de quem chamou, só
    // não há cliente a quem associar — 202 pra não deixar o workflow amarelo.
    return NextResponse.json({ aviso: `cliente '${clientSlug}' não encontrado` }, { status: 202 });
  }

  // demandaId no corpo é o code (ex.: ACXYA-1), igual a /api/sync/demanda —
  // nunca o id interno do Prisma, que quem chama não tem como conhecer.
  const demandaCode = String(body.demandaId ?? "").trim();
  let demandaIdInterno: string | null = null;
  if (demandaCode) {
    const demanda = await prisma.demanda.findUnique({
      where: { clientId_code: { clientId: client.id, code: demandaCode } },
      select: { id: true },
    });
    demandaIdInterno = demanda?.id ?? null;
  }

  const iniciadoBruto = String(body.iniciadoEm ?? "");
  const iniciadoEm = iniciadoBruto && !Number.isNaN(Date.parse(iniciadoBruto)) ? new Date(iniciadoBruto) : null;

  await prisma.execucaoAgente.create({
    data: {
      clientId: client.id,
      demandaId: demandaIdInterno,
      origem,
      etapa,
      motivo: String(body.motivo ?? "").trim().slice(0, 60),
      resultado,
      iniciadoEm,
      runUrl: urlDeRunValida(body.runUrl),
    },
  });

  return NextResponse.json({ ok: true });
}
