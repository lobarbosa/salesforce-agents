import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;

  // Mesmo padrão do POST /api/demandas: quem solicitou sai da sessão, não do
  // corpo — o registro de "quem pediu o teste" só vale se não puder ser
  // informado por quem chama.
  const client = await prisma.client.update({
    where: { id },
    data: {
      statusConexao: "aguardando_teste",
      testeSolicitadoPor: usuario.nome.trim() || usuario.email,
      testeSolicitadoEm: new Date(),
    },
  });

  return NextResponse.json(client);
}
