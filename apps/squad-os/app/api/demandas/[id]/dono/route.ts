import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { lerDonoDoCorpo, podeSerDono } from "@/lib/dono";

// Troca (ou tira) o dono da demanda — ver lib/dono.ts. Só o time: o dono é
// instrumento de delivery, e o cliente vê o nome mas não escolhe. Vale em
// qualquer etapa, inclusive com execução em voo: não mexe na esteira.
export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;

  const corpo = lerDonoDoCorpo(await request.json().catch(() => null));
  if (!corpo.ok) {
    return NextResponse.json({ error: "envie { donoId: <id de alguém do time> | null }" }, { status: 400 });
  }

  if (corpo.donoId) {
    const pessoa = await prisma.usuario.findUnique({ where: { id: corpo.donoId }, select: { role: true } });
    if (!pessoa || !podeSerDono(pessoa.role)) {
      return NextResponse.json({ error: "o dono precisa ser alguém do time (admin ou consultor)" }, { status: 400 });
    }
  }

  const { usuario } = acesso;
  const atualizada = await prisma.demanda.update({
    where: { id },
    data: {
      donoId: corpo.donoId,
      donoDefinidoEm: new Date(),
      // Quem trocou sai da sessão, nunca do corpo.
      donoDefinidoPor: usuario.nome.trim() || usuario.email,
    },
    select: { id: true, donoId: true, donoDefinidoEm: true, donoDefinidoPor: true, dono: { select: { id: true, nome: true, email: true } } },
  });
  return NextResponse.json(atualizada);
}
