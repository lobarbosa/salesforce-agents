import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { triggerTestConnection } from "@/lib/github";
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

  const client = await prisma.client.findUnique({ where: { id }, select: { slug: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

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

  // Antes isto só marcava "aguardando_teste" e alguém ia rodar o workflow na
  // mão. Agora dispara de verdade; o resultado volta por /api/sync/conexao, e
  // é esse retorno que marca a org como conectada — e, na org de dev, acende o
  // assessment de onboarding.
  try {
    await triggerTestConnection(client.slug, tipo);
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao disparar o teste" },
      { status: 502 }
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
