import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { mudarCiclo, type AcaoCiclo } from "@/lib/ciclo-demanda";

// Congelar, descongelar e cancelar (2026-10-21). Só delivery. A regra mora em
// lib/ciclo-demanda.ts.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;
  const autor = acesso.usuario.nome.trim() || acesso.usuario.email;

  const body = (await request.json().catch(() => null)) as { acao?: unknown; motivo?: unknown } | null;
  const acao = String(body?.acao ?? "") as AcaoCiclo;
  const motivo = String(body?.motivo ?? "").trim().slice(0, 1000);
  if (!["congelar", "descongelar", "cancelar"].includes(acao)) {
    return NextResponse.json({ error: "ação inválida" }, { status: 400 });
  }
  if (acao !== "descongelar" && !motivo) {
    return NextResponse.json({ error: "informe o motivo" }, { status: 400 });
  }

  const erro = await mudarCiclo(id, acao, motivo, autor);
  if (erro) return erro;
  return NextResponse.json(await prisma.demanda.findUnique({ where: { id } }));
}
