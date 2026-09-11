import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { ContratoInvalidoError, montarDadosDoContrato } from "@/lib/contrato";

// Um contrato por cliente, criado ou atualizado pelo mesmo PUT — não existe
// "criar contrato" como ato separado: o cliente ou tem um, ou passa a ter.
// Só admin/consultor: é dado comercial, não algo que o cliente final edita.
//
// **O PUT é parcial, não substituição.** Campo ausente no corpo mantém o que
// está guardado; quem decide isso é `montarDadosDoContrato`, em lib/contrato.ts,
// onde a regra é testável sem servidor. Era substituição total até 2026-09-11,
// e o botão de trocar de tipo — que manda só `{ tipo }` — zerava as horas e
// reiniciava o SLA de quem já tinha preenchido.
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const client = await prisma.client.findUnique({ where: { id }, select: { id: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const atual = await prisma.contrato.findUnique({ where: { clientId: id } });

  let dados;
  try {
    dados = montarDadosDoContrato(body as Record<string, unknown>, atual);
  } catch (err) {
    if (err instanceof ContratoInvalidoError) {
      return NextResponse.json({ error: err.message }, { status: 400 });
    }
    throw err;
  }

  const contrato = await prisma.contrato.upsert({
    where: { clientId: id },
    update: dados,
    create: { clientId: id, ...dados },
    include: { entregaveis: { orderBy: { ordem: "asc" } } },
  });

  return NextResponse.json(contrato);
}
