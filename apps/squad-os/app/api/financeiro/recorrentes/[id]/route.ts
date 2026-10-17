import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { prisma } from "@/lib/prisma";
import { validarModelo } from "@/lib/recorrencias";
import { atualizarModelo } from "@/lib/recorrencias-data";

// Edita o modelo (campos parciais), pausa/retoma (`ativa`) e encerra (`fim`,
// a última competência; "" = sem fim). Vale para as próximas contas: as já
// geradas seguem o próprio fluxo de aprovação. Não existe DELETE — a
// recorrência é referenciada pelas contas e pela trilha; pausar ou encerrar.
export async function PATCH(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") return NextResponse.json({ error: "corpo inválido" }, { status: 400 });

  const v = validarModelo(body, true);
  if (v.erro !== undefined) return NextResponse.json({ error: v.erro }, { status: 400 });
  if (v.dados.clientId && !(await prisma.client.findUnique({ where: { id: v.dados.clientId }, select: { id: true } }))) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 400 });
  }
  const ativa = typeof body.ativa === "boolean" ? body.ativa : undefined;

  const r = await atualizarModelo(id, { ...v.dados, ativa });
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json(r);
}
