import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { gerarContasRecorrentes } from "@/lib/recorrencias-data";

// Vercel Cron diário (vercel.json → "crons"): gera as contas a pagar das
// despesas recorrentes: toda competência desde o início do modelo que ainda
// não tem conta, até as que vencem nos próximos 30 dias (no máximo 24 por
// modelo por passada; avulsa já lançada do mesmo fornecedor/mês é vinculada
// em vez de duplicada). Idempotente — pode
// rodar quantas vezes for, e as telas do financeiro também chamam a geração.

export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const r = await gerarContasRecorrentes();
  return NextResponse.json(r, { status: r.falhas ? 500 : 200 });
}
