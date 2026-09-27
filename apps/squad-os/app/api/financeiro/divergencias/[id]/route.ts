import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { decidirDivergencia, STATUS_DIVERGENCIA, type StatusDivergencia } from "@/lib/ops";

// Resolver, ignorar ou reabrir uma divergência. É a única escrita do Squad OS
// no schema ops: o agente cria e atualiza os números, mas nunca o status.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  if (!/^\d+$/.test(id)) return NextResponse.json({ error: "divergência inválida" }, { status: 400 });

  const body = (await request.json().catch(() => ({}))) as { status?: string; nota?: string };
  const status = body.status as StatusDivergencia;
  const nota = String(body.nota ?? "").trim().slice(0, 1000);
  if (!STATUS_DIVERGENCIA.includes(status)) return NextResponse.json({ error: "situação inválida" }, { status: 400 });
  if (status === "ignorada" && !nota) {
    return NextResponse.json({ error: "diga por que esta divergência pode ser ignorada" }, { status: 400 });
  }
  const r = await decidirDivergencia(id, status, acesso.usuario.email, nota);
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json({ ok: true });
}
