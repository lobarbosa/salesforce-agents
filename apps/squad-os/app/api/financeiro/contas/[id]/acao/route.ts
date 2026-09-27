import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { agirNaConta } from "@/lib/contas-data";
import type { Acao } from "@/lib/contas";

const ACOES: Acao[] = ["aprovar", "recusar", "pagar", "cancelar"];

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const body = await request.json().catch(() => ({}));
  const acao = String(body.acao ?? "") as Acao;
  if (!ACOES.includes(acao)) return NextResponse.json({ error: "ação inválida" }, { status: 400 });
  const comentario = String(body.comentario ?? "").trim().slice(0, 500);

  const r = await agirNaConta(id, acao, { role: acesso.usuario.role, email: acesso.usuario.email }, comentario);
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json(r.conta);
}
