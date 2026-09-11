import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

const DESCRICAO_MAX = 200;

// Tempo é lançamento de quem trabalhou, não dado compartilhado do card: só o
// próprio autor (ou um admin, pra corrigir lançamento de alguém que saiu)
// para o cronômetro ou apaga o registro. Consultor não mexe no tempo de
// consultor.
function podeMexer(
  role: string,
  email: string,
  registro: { autorEmail: string }
): boolean {
  return role === "admin" || registro.autorEmail === email;
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; registroId: string }> }
) {
  const { id, registroId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const registro = await prisma.registroTempo.findFirst({
    where: { id: registroId, demandaId: id },
  });
  if (!registro) {
    return NextResponse.json({ error: "registro não encontrado" }, { status: 404 });
  }
  if (!podeMexer(usuario.role, usuario.email, registro)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json().catch(() => ({}));
  const data: { descricao?: string; fimEm?: Date; minutos?: number } = {};

  if (body.descricao !== undefined) {
    data.descricao = String(body.descricao).trim().slice(0, DESCRICAO_MAX);
  }

  if (body.parar) {
    if (registro.fimEm) {
      return NextResponse.json({ error: "esse registro já está parado" }, { status: 409 });
    }
    const fim = new Date();
    data.fimEm = fim;
    // Arredonda pra cima: um registro de 20 segundos é 1 minuto de trabalho,
    // não zero. Zero apareceria na lista como se nada tivesse acontecido.
    data.minutos = Math.max(1, Math.round((fim.getTime() - registro.inicioEm.getTime()) / 60_000));
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nada pra atualizar" }, { status: 400 });
  }

  const atualizado = await prisma.registroTempo.update({ where: { id: registroId }, data });
  return NextResponse.json(atualizado);
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; registroId: string }> }
) {
  const { id, registroId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const registro = await prisma.registroTempo.findFirst({
    where: { id: registroId, demandaId: id },
  });
  if (!registro) {
    return NextResponse.json({ error: "registro não encontrado" }, { status: 404 });
  }
  if (!podeMexer(usuario.role, usuario.email, registro)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  await prisma.registroTempo.delete({ where: { id: registroId } });
  return new NextResponse(null, { status: 204 });
}
