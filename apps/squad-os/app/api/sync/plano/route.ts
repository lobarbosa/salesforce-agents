import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { generateDemandCode } from "@/lib/slug";

// As demandas propostas pelo planejador entrando no quadro, em `backlog`.
//
// Nada é materializado nem executado aqui: o cartão aparece pra alguém ler,
// e quem decide o que vira esteira continua sendo o humano. É a mesma
// fronteira do botão "Materializar" — só que agora a lista chega pronta.

const MAX_DEMANDAS = 60;
const AUTOR = "planejador";

interface DemandaProposta {
  entregavelId: string;
  titulo: string;
  texto?: string;
  criteriosAceite?: unknown;
  perguntas?: unknown;
}

// As perguntas do agente viram as `perguntas` da demanda, no formato que o
// card já sabe exibir — é o insumo do gate de análise. Critérios de aceite
// entram no texto: quem refina de verdade é o `ba-discovery`, na etapa 1.
function comoPerguntas(valor: unknown): { id: string; texto: string }[] {
  if (!Array.isArray(valor)) return [];
  return valor
    .map((p) => String(p ?? "").trim())
    .filter(Boolean)
    .slice(0, 10)
    .map((texto, i) => ({ id: `p${i + 1}`, texto: texto.slice(0, 500) }));
}

function comoTexto(d: DemandaProposta): string {
  const partes = [String(d.texto ?? "").trim()];
  const criterios = Array.isArray(d.criteriosAceite)
    ? d.criteriosAceite.map((c) => String(c ?? "").trim()).filter(Boolean)
    : [];
  if (criterios.length > 0) {
    partes.push("", "**Critérios de aceite propostos**", ...criterios.map((c) => `- ${c}`));
  }
  return partes.join("\n").trim().slice(0, 8000);
}

export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const clientSlug = String(body.cliente ?? "");
  const propostas: DemandaProposta[] = Array.isArray(body.demandas) ? body.demandas : [];

  if (!clientSlug) {
    return NextResponse.json({ error: "cliente é obrigatório" }, { status: 400 });
  }
  if (propostas.length === 0) {
    return NextResponse.json({ error: "nenhuma demanda no plano" }, { status: 400 });
  }
  if (propostas.length > MAX_DEMANDAS) {
    return NextResponse.json(
      { error: `plano com ${propostas.length} demandas passa do teto de ${MAX_DEMANDAS}` },
      { status: 400 }
    );
  }

  const client = await prisma.client.findUnique({
    where: { slug: clientSlug },
    select: { id: true, slug: true, contrato: { select: { entregaveis: { select: { id: true } } } } },
  });
  if (!client) {
    return NextResponse.json({ error: `cliente '${clientSlug}' não encontrado` }, { status: 404 });
  }

  const validos = new Set(client.contrato?.entregaveis.map((e) => e.id) ?? []);
  const invalidas = propostas.filter((d) => !validos.has(String(d.entregavelId)));
  if (invalidas.length > 0) {
    // Recusa o lote inteiro, não só as ruins: um plano com id inventado
    // provavelmente tem mais coisa errada, e meia importação deixa o quadro
    // num estado que ninguém consegue auditar depois.
    return NextResponse.json(
      { error: `${invalidas.length} demanda(s) apontam pra entregável que não existe no contrato` },
      { status: 409 }
    );
  }

  // Os códigos são sequenciais por cliente e precisam ser gerados em série —
  // em paralelo, duas demandas pegariam o mesmo número.
  const criadas: { code: string; titulo: string }[] = [];
  for (const d of propostas) {
    const titulo = String(d.titulo ?? "").trim().slice(0, 300);
    if (!titulo) continue;
    const code = await generateDemandCode(client.id, client.slug);
    const demanda = await prisma.demanda.create({
      data: {
        clientId: client.id,
        code,
        titulo,
        tipo: "projeto",
        texto: comoTexto(d),
        autor: AUTOR,
        status: "backlog",
        entregavelId: String(d.entregavelId),
        perguntas: comoPerguntas(d.perguntas),
        historico: [
          { de: null, para: "backlog", autor: AUTOR, em: new Date().toISOString() },
        ],
      },
      select: { code: true, titulo: true },
    });
    criadas.push(demanda);
  }

  return NextResponse.json({ ok: true, criadas: criadas.length, demandas: criadas });
}
