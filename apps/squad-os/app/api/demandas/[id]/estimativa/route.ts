import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";

// Estimativa oficial do consultor. Só delivery lança (o cliente vê o
// resultado, não edita). Fica gravado quem lançou e quando — é o número
// contra o qual o timesheet vai ser medido, então precisa ter dono.
const HORAS_MAX = 2000;

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const body = (await request.json().catch(() => null)) as { horas?: unknown } | null;
  const horas = Number(body?.horas);
  if (!Number.isFinite(horas) || horas <= 0 || horas > HORAS_MAX) {
    return NextResponse.json({ error: `informe as horas estimadas (entre 0 e ${HORAS_MAX})` }, { status: 400 });
  }

  const atualizada = await prisma.demanda.update({
    where: { id },
    data: {
      estimativaConsultorHoras: Math.round(horas * 4) / 4, // quarto de hora
      estimativaConsultorPor: usuario.nome.trim() || usuario.email,
      estimativaConsultorEm: new Date(),
    },
    select: { estimativaConsultorHoras: true, estimativaConsultorPor: true, estimativaConsultorEm: true },
  });
  return NextResponse.json(atualizada);
}
