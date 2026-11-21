import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";
import { ehChaveMes } from "@/lib/horas";
import { relatorioPublicado } from "@/lib/relatorio-publicado";

// O PDF do relatório mensal publicado na página do cliente (ver lib/relatorio-publicado.ts).
export async function GET(_request: Request, { params }: { params: Promise<{ id: string; mes: string }> }) {
  const usuario = await getCurrentUsuario();
  const { id, mes } = await params;
  if (!usuario || !canAccessClient(usuario.role, usuario.clientId, id)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }
  if (!ehChaveMes(mes)) return NextResponse.json({ error: "mês inválido" }, { status: 400 });
  const client = await prisma.client.findUnique({ where: { id }, select: { nome: true, encerradoEm: true, criadoEm: true } });
  if (!client || !enxergaCliente(usuario.role, client)) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }
  const r = await relatorioPublicado(id, client.criadoEm, mes);
  if (!r) return NextResponse.json({ error: "não há relatório deste mês" }, { status: 404 });
  return new NextResponse(new Uint8Array(r.pdf), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${r.nome}"`,
      "Cache-Control": "private, no-store",
    },
  });
}
