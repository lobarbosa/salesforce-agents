import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";
import { relatoriosDoCliente } from "@/lib/relatorio-publicado";

// Relatórios mensais publicados na página do cliente (2026-11-21): todo mês
// fechado desde outubro de 2026 (lib/relatorio-publicado.ts). Quem enxerga o
// cliente vê, o próprio cliente incluído.
export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const usuario = await getCurrentUsuario();
  const { id } = await params;
  if (!usuario || !canAccessClient(usuario.role, usuario.clientId, id)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }
  const client = await prisma.client.findUnique({ where: { id }, select: { nome: true, encerradoEm: true, criadoEm: true } });
  if (!client || !enxergaCliente(usuario.role, client)) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }
  const relatorios = await relatoriosDoCliente(id, client.criadoEm);
  return NextResponse.json({ relatorios });
}
