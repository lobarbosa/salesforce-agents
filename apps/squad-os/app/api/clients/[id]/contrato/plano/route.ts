import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { materializeContrato, triggerPlanejamento } from "@/lib/github";

// Materializa o contrato no repositório e dispara o planejador. Dois passos e
// não um: o agente roda no repo e não enxerga o Postgres, então o contrato
// precisa existir como arquivo antes de haver o que planejar.
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
    select: {
      slug: true,
      nome: true,
      contrato: { include: { entregaveis: { orderBy: { ordem: "asc" } } } },
    },
  });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const contrato = client.contrato;
  if (!contrato || contrato.tipo !== "projeto") {
    return NextResponse.json(
      { error: "o planejador só roda em contrato de projeto" },
      { status: 409 }
    );
  }
  if (contrato.entregaveis.length === 0) {
    return NextResponse.json(
      { error: "cadastre ao menos um entregável antes — é o que o planejador lê" },
      { status: 409 }
    );
  }

  try {
    await materializeContrato({
      clientSlug: client.slug,
      clientNome: client.nome,
      projetoNome: contrato.projetoNome,
      projetoEscopo: contrato.projetoEscopo,
      inicioEm: contrato.inicioEm,
      fimPrevistoEm: contrato.fimPrevistoEm,
      entregaveis: contrato.entregaveis,
    });
    await triggerPlanejamento(client.slug);
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "falha ao disparar o planejador" },
      { status: 502 }
    );
  }

  return NextResponse.json({ ok: true, entregaveis: contrato.entregaveis.length });
}
