import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { triggerAssessment } from "@/lib/github";

// Refazer o assessment sob demanda. O primeiro roda sozinho quando a org de dev
// conecta (ver /api/sync/conexao); este é pro caso de a org ter mudado muito
// desde então. Só admin/consultor: é uma sessão de agente contra a org do
// cliente, não um botão de atualizar tela.
export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const client = await prisma.client.findUnique({
    where: { id },
    select: { slug: true, ambientes: { where: { tipo: "dev" }, select: { statusConexao: true } } },
  });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  // Sem org de dev conectada o agente não tem o que auditar — falharia lá na
  // frente, no runner, com uma mensagem bem menos clara que esta.
  const dev = client.ambientes[0];
  if (!dev || dev.statusConexao !== "conectado") {
    return NextResponse.json(
      { error: "a org de dev precisa estar conectada antes — teste a conexão na aba Conexão" },
      { status: 409 }
    );
  }

  try {
    await triggerAssessment(client.slug);
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao disparar o assessment" },
      { status: 502 }
    );
  }

  return NextResponse.json({ ok: true });
}
