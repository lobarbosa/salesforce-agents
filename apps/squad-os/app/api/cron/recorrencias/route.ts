import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { gerarContasRecorrentes } from "@/lib/recorrencias-data";

// Vercel Cron diário (vercel.json → "crons"): gera as contas a pagar das
// despesas recorrentes que vencem nos próximos 30 dias. Idempotente — pode
// rodar quantas vezes for, e as telas do financeiro também chamam a geração.

export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const r = await gerarContasRecorrentes();
  return NextResponse.json(r, { status: r.falhas ? 500 : 200 });
}
