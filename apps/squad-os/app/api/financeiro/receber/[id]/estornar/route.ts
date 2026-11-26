import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { estornarRecebimento } from "@/lib/receber-data";

// Desfazer um recebimento registrado. Corpo JSON: { motivo: string } (obrigatório).
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const body = await request.json().catch(() => ({}));
  const motivo = String(body.motivo ?? "").trim().slice(0, 500);
  if (!motivo) return NextResponse.json({ error: "diga por que o recebimento está sendo desfeito" }, { status: 400 });
  const r = await estornarRecebimento(id, motivo, acesso.usuario.email);
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json(r);
}
