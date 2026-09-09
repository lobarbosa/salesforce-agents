import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";

// Recebe o resultado do assessment de org (run-assessment.yml) e o grava no
// perfil do cliente. O relatório longo continua em clients/<slug>/assessment.md
// no git — aqui fica só o que cabe num card: veredito, resumo e as
// recomendações que importam.

const SAUDES = new Set(["verde", "amarelo", "vermelho"]);
const SEVERIDADES = new Set(["alta", "media", "média", "baixa"]);
const MAX_RECOMENDACOES = 10;
const RESUMO_MAX = 4000;

// A assinatura de índice existe pra satisfazer o tipo de entrada JSON do
// Prisma sem cast — e é honesta: todo campo aqui é string.
interface Recomendacao {
  titulo: string;
  severidade: string;
  area: string;
  [campo: string]: string;
}

// Normaliza em vez de confiar: o payload vem de um modelo, e um campo a mais
// ou uma severidade escrita de outro jeito não pode virar lixo no banco nem
// derrubar a tela do cliente.
function normalizarRecomendacoes(bruto: unknown): Recomendacao[] {
  if (!Array.isArray(bruto)) return [];
  return bruto
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
    .map((r) => {
      const severidade = String(r.severidade ?? "").toLowerCase().trim();
      return {
        titulo: String(r.titulo ?? "").trim().slice(0, 300),
        severidade: SEVERIDADES.has(severidade) ? severidade.replace("média", "media") : "baixa",
        area: String(r.area ?? "").trim().slice(0, 60),
      };
    })
    .filter((r) => r.titulo)
    .slice(0, MAX_RECOMENDACOES);
}

export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const clientSlug = String(body.client ?? "");
  const saude = String(body.saude ?? "");
  const resumo = String(body.resumo ?? "").trim();

  if (!clientSlug) {
    return NextResponse.json({ error: "client é obrigatório" }, { status: 400 });
  }
  if (!SAUDES.has(saude)) {
    return NextResponse.json({ error: `saude desconhecida: ${saude}` }, { status: 400 });
  }
  if (!resumo) {
    return NextResponse.json({ error: "resumo vazio" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({
    where: { slug: clientSlug },
    select: { id: true },
  });
  if (!client) {
    return NextResponse.json({ error: `cliente '${clientSlug}' não encontrado` }, { status: 404 });
  }

  await prisma.client.update({
    where: { id: client.id },
    data: {
      assessmentEm: new Date(),
      assessmentSaude: saude,
      assessmentResumo: resumo.slice(0, RESUMO_MAX),
      assessmentRecomendacoes: normalizarRecomendacoes(body.recomendacoes),
    },
  });

  return NextResponse.json({ ok: true, slug: clientSlug, saude });
}
