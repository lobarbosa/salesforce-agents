import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import type { TipoAmbiente } from "@/lib/generated/prisma/client";

const TIPOS: TipoAmbiente[] = ["dev", "qa"];

// Substitui /api/clients/[id]/test-connection, que só sabia de uma org por
// cliente. Quem solicitou sai da sessão, não do corpo — o registro de "quem
// pediu o teste" só vale se não puder ser informado por quem chama.
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; tipo: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id, tipo: tipoRaw } = await params;
  if (!(TIPOS as string[]).includes(tipoRaw)) {
    return NextResponse.json({ error: "ambiente inválido" }, { status: 400 });
  }
  const tipo = tipoRaw as TipoAmbiente;

  const existente = await prisma.ambienteOrg.findUnique({
    where: { clientId_tipo: { clientId: id, tipo } },
    select: { orgAlias: true },
  });
  if (!existente?.orgAlias) {
    return NextResponse.json(
      { error: "configure ao menos o alias do org antes de solicitar o teste" },
      { status: 400 }
    );
  }

  const ambiente = await prisma.ambienteOrg.update({
    where: { clientId_tipo: { clientId: id, tipo } },
    data: {
      statusConexao: "aguardando_teste",
      testeSolicitadoPor: usuario.nome.trim() || usuario.email,
      testeSolicitadoEm: new Date(),
    },
  });

  return NextResponse.json(ambiente);
}
