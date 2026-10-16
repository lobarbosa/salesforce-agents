import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";

// Rotas /api/cron/* são chamadas pelo Vercel Cron, sem sessão de usuário. A
// Vercel manda `Authorization: Bearer ${CRON_SECRET}` quando a variável existe
// no projeto (padrão documentado da plataforma). proxy.ts deixa /api/cron
// passar sem sessão; quem tranca é esta função — mesmo desenho de
// lib/sync-auth.ts.
//
// Sem CRON_SECRET configurado a rota fica FECHADA (503), não aberta. A geração
// das recorrências continua acontecendo na carga das telas do financeiro.

function iguais(esperado: string, recebido: string): boolean {
  const a = Buffer.from(recebido);
  const b = Buffer.from(esperado);
  return a.length === b.length && timingSafeEqual(a, b);
}

export function autorizarCron(request: NextRequest): NextResponse | null {
  const esperado = process.env.CRON_SECRET?.trim();
  if (!esperado) {
    return NextResponse.json({ error: "cron não configurado (falta CRON_SECRET)" }, { status: 503 });
  }
  const header = request.headers.get("authorization") ?? "";
  const recebido = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!iguais(esperado, recebido)) return NextResponse.json({ error: "não autorizado" }, { status: 401 });
  return null;
}
