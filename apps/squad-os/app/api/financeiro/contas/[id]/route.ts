import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { bloqueio, bloqueioValor, lerReais, type Acao } from "@/lib/contas";
import { alterarConta, eventosDa, INCLUDE_VISTA, paraVista } from "@/lib/contas-data";
import { NATUREZAS } from "@/lib/recorrencias";
import type { NaturezaCusto } from "@/lib/generated/prisma/client";

// Detalhe da conta: dados, trilha de eventos e, para cada ação, se a pessoa
// logada pode fazê-la (e por que não) — a tela mostra o motivo em vez de um
// botão que falha.
export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const c = await prisma.contaPagar.findUnique({ where: { id }, include: INCLUDE_VISTA });
  if (!c) return NextResponse.json({ error: "conta não encontrada" }, { status: 404 });

  const conta = paraVista(c);
  const acoes: Acao[] = ["aprovar", "recusar", "pagar", "cancelar"];
  const bloqueios = Object.fromEntries(
    acoes.map((a) => [a, bloqueio(a, conta, { role: acesso.usuario.role, email: acesso.usuario.email })])
  );
  return NextResponse.json({ conta, eventos: await eventosDa(id), bloqueios, bloqueioValor: bloqueioValor(conta.status) });
}

// Corrigir o valor (só aguardando aprovação — conta de consumo gerada pela
// recorrência chega com valor estimado) e classificar (natureza, cliente).
// Corpo JSON: { valor?: "1.234,56", natureza?: "direto"|"fixo"|"", clientId?: string|"" }.
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const body = await request.json().catch(() => ({}));

  const mudanca: { valor?: number; natureza?: NaturezaCusto | null; clientId?: string | null } = {};
  if (body.valor !== undefined) {
    const v = lerReais(String(body.valor).slice(0, 30));
    if (v === null) return NextResponse.json({ error: "valor inválido — use 1.234,56" }, { status: 400 });
    mudanca.valor = v;
  }
  if (body.natureza !== undefined) {
    const n = String(body.natureza);
    if (n && !NATUREZAS.includes(n as NaturezaCusto)) return NextResponse.json({ error: "natureza inválida" }, { status: 400 });
    mudanca.natureza = (n || null) as NaturezaCusto | null;
  }
  if (body.clientId !== undefined) mudanca.clientId = String(body.clientId).slice(0, 60) || null;

  const r = await alterarConta(id, mudanca, { role: acesso.usuario.role, email: acesso.usuario.email });
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json(r.conta);
}
