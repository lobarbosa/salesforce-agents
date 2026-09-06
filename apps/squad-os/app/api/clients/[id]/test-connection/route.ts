import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();
  const nome = String(body.nome ?? "").trim();
  if (!nome) {
    return NextResponse.json({ error: "nome de quem solicita é obrigatório" }, { status: 400 });
  }

  const client = await prisma.client.update({
    where: { id },
    data: {
      statusConexao: "aguardando_teste",
      testeSolicitadoPor: nome,
      testeSolicitadoEm: new Date(),
    },
  });

  return NextResponse.json(client);
}
