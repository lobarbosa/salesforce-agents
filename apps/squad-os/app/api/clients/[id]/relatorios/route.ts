import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";

// Relatórios mensais publicados na página do cliente (2026-11-21): os meses já
// enviados a ele. Quem enxerga o cliente vê, o próprio cliente incluído.
export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const usuario = await getCurrentUsuario();
  const { id } = await params;
  if (!usuario || !canAccessClient(usuario.role, usuario.clientId, id)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }
  const client = await prisma.client.findUnique({ where: { id }, select: { nome: true, encerradoEm: true } });
  if (!client || !enxergaCliente(usuario.role, client)) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }
  const envios = await prisma.relatorioEnviado.findMany({
    where: { clientId: id },
    orderBy: { mes: "desc" },
    select: { mes: true, enviadoEm: true },
  });
  return NextResponse.json({ relatorios: envios });
}
