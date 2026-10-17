import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";

// Comentários do card para a sessão do agente (2026-10-17). É ali que cliente
// e consultor respondem as dúvidas que a análise deixou — e até aqui isso
// nunca chegava à etapa seguinte (achado: SOMOSAGILITY-14).
//
// O que sai daqui é o mínimo: de que lado veio (cliente ou equipe), quando, e
// o texto. Nome e e-mail de quem escreveu ficam no banco — o agente não
// precisa saber quem é a pessoa para usar a resposta (guardrail #2). O job
// ainda passa o texto pelos padrões do scanner de PII antes de gravar
// (src/salesforce_agents/comentarios.py).
//
// Mesmo bearer por cliente das outras rotas de sync, e a demanda é procurada
// dentro do cliente do token (guardrail #7).
const MAX_COMENTARIOS = 50;
const MAX_CHARS = 4000;

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const registro = body as Record<string, unknown>;
  const clientSlug = String(registro.clientSlug ?? "").trim();
  const code = String(registro.demandaId ?? "").trim();

  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  if (!clientSlug || !code) {
    return NextResponse.json({ error: "clientSlug e demandaId são obrigatórios" }, { status: 400 });
  }

  const demanda = await prisma.demanda.findFirst({
    where: { code, client: { slug: clientSlug } },
    select: {
      comentarios: {
        orderBy: { criadoEm: "desc" },
        take: MAX_COMENTARIOS,
        select: { autorEmail: true, texto: true, criadoEm: true },
      },
    },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }

  const emails = [...new Set(demanda.comentarios.map((c) => c.autorEmail.toLowerCase()))];
  const usuarios = emails.length
    ? await prisma.usuario.findMany({ where: { email: { in: emails } }, select: { email: true, role: true } })
    : [];
  const papelPorEmail = new Map(usuarios.map((u) => [u.email.toLowerCase(), u.role]));

  const comentarios = demanda.comentarios
    .reverse() // cronológico, como uma conversa se lê
    .map((c) => ({
      papel: papelPorEmail.get(c.autorEmail.toLowerCase()) === "cliente" ? "cliente" : "equipe",
      em: c.criadoEm.toISOString(),
      texto: c.texto.slice(0, MAX_CHARS),
    }));

  return NextResponse.json({ comentarios }, { status: 200 });
}
