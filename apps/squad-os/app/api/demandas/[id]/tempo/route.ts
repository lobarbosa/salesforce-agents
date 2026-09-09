import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

// Um lançamento manual cobre no máximo um dia. Não é limite técnico: é o
// ponto em que um número digitado errado (2400 em vez de 240) deixa de ser
// plausível e vira erro de digitação que ninguém revisa depois.
const MINUTOS_MAX = 24 * 60;
const DESCRICAO_MAX = 200;

// Dois modos no mesmo POST porque é a mesma linha em estados diferentes:
// sem `minutos`, começa um cronômetro (fimEm nulo); com `minutos`, grava um
// lançamento já fechado. Separar em duas rotas duplicaria a validação sem
// mudar o que vai pro banco.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const body = await request.json();
  const descricao = String(body.descricao ?? "").trim().slice(0, DESCRICAO_MAX);
  const autor = usuario.nome.trim() || usuario.email;
  const agora = new Date();

  if (body.minutos !== undefined && body.minutos !== null && body.minutos !== "") {
    const minutos = Math.round(Number(body.minutos));
    if (!Number.isFinite(minutos) || minutos <= 0) {
      return NextResponse.json({ error: "minutos precisa ser um número positivo" }, { status: 400 });
    }
    if (minutos > MINUTOS_MAX) {
      return NextResponse.json(
        { error: `lançamento manual vai até ${MINUTOS_MAX} minutos` },
        { status: 400 }
      );
    }

    const registro = await prisma.registroTempo.create({
      data: {
        demandaId: id,
        autor,
        autorEmail: usuario.email,
        descricao,
        inicioEm: new Date(agora.getTime() - minutos * 60_000),
        fimEm: agora,
        minutos,
      },
    });
    return NextResponse.json(registro, { status: 201 });
  }

  // Um cronômetro por pessoa por demanda. Sem essa checagem, um segundo
  // clique no botão abre um registro paralelo e o total passa a contar o
  // mesmo intervalo duas vezes.
  const rodando = await prisma.registroTempo.findFirst({
    where: { demandaId: id, autorEmail: usuario.email, fimEm: null },
  });
  if (rodando) {
    return NextResponse.json(
      { error: "você já tem um cronômetro rodando nesta demanda" },
      { status: 409 }
    );
  }

  const registro = await prisma.registroTempo.create({
    data: {
      demandaId: id,
      autor,
      autorEmail: usuario.email,
      descricao,
      inicioEm: agora,
    },
  });
  return NextResponse.json(registro, { status: 201 });
}
