import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";
import { recusaSeEncerrado } from "@/lib/encerramento-server";

const TEXTO_MAX = 4000;

// Comentar não exige canManageClientData: o papel `cliente` participa da
// conversa da própria demanda — é justamente o ponto de ter a conversa dentro
// do sistema. O escopo por cliente continua valendo via canAccessClient.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const demanda = await prisma.demanda.findUnique({
    where: { id },
    select: { id: true, clientId: true, client: { select: { nome: true, encerradoEm: true } } },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  if (!canAccessClient(usuario.role, usuario.clientId, demanda.clientId)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }
  if (!enxergaCliente(usuario.role, demanda.client)) {
    const encerrado = recusaSeEncerrado(demanda.client, "demanda");
    if (encerrado) return encerrado;
  }

  const body = await request.json();
  const texto = String(body.texto ?? "").trim();
  if (!texto) {
    return NextResponse.json({ error: "comentário vazio" }, { status: 400 });
  }
  if (texto.length > TEXTO_MAX) {
    return NextResponse.json(
      { error: `comentário passa de ${TEXTO_MAX} caracteres` },
      { status: 400 }
    );
  }

  // "Aprovou o gate ..." é o rastro (e a trava contra aprovação dupla) que a
  // rota aprovar-gate escreve — um comentário digitado com esse começo
  // fingiria uma aprovação e travaria o gate de verdade.
  if (texto.startsWith("Aprovou o gate")) {
    return NextResponse.json({ error: "esse texto é reservado ao registro de aprovação de gate" }, { status: 400 });
  }

  // Autor da sessão, mesmo padrão do POST /api/demandas — o rastro só serve
  // se não puder ser informado por quem chama.
  const comentario = await prisma.comentario.create({
    data: {
      demandaId: id,
      autor: usuario.nome.trim() || usuario.email,
      autorEmail: usuario.email,
      texto,
    },
  });

  return NextResponse.json(comentario, { status: 201 });
}
