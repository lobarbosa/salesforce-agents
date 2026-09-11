import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { StatusDemanda } from "@/lib/generated/prisma/client";

// Fecha o laço na direção git → app. `status.yaml` no repositório é a fonte de
// verdade do estágio (guardrail #5 do CLAUDE.md raiz); o Postgres é espelho, e
// até agora esse espelho congelava no momento da materialização — o gate que
// estava esperando alguém ficava invisível justamente pra quem precisava vê-lo.
//
// Chamado por run-demand.yml no fim de cada execução, com `if: always()`:
// saber que a etapa falhou importa tanto quanto saber que passou.

const STATUS_VALIDOS = new Set<string>(Object.values(StatusDemanda));

export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  // O payload é o próprio status.yaml em JSON (`sfagents demanda status-json`)
  // mais dois campos que só o Actions sabe.
  const clientSlug = String(body.client ?? "");
  const code = String(body.id ?? "");
  const status = String(body.status ?? "");

  if (!clientSlug || !code) {
    return NextResponse.json({ error: "client e id são obrigatórios" }, { status: 400 });
  }
  if (!STATUS_VALIDOS.has(status)) {
    // Um status que o app não conhece significa que demands.py e o enum do
    // Prisma saíram de sincronia. Recusar é melhor que gravar lixo: o git
    // continua correto e o erro aparece no log do workflow.
    return NextResponse.json(
      { error: `status desconhecido: ${status}` },
      { status: 400 }
    );
  }

  const client = await prisma.client.findUnique({
    where: { slug: clientSlug },
    select: { id: true },
  });
  if (!client) {
    return NextResponse.json({ error: `cliente '${clientSlug}' não encontrado` }, { status: 404 });
  }

  const demanda = await prisma.demanda.findUnique({
    where: { clientId_code: { clientId: client.id, code } },
    select: { id: true },
  });
  if (!demanda) {
    // Acontece quando a demanda nasceu pela CLI (`sfagents demanda nova`) e
    // não pelo Squad OS. Não é erro do chamador — só não há espelho a
    // atualizar. 202 pra o workflow não ficar amarelo por isso.
    return NextResponse.json(
      { aviso: `demanda '${code}' não existe no Squad OS — nada a espelhar` },
      { status: 202 }
    );
  }

  const atualizada = await prisma.demanda.update({
    where: { id: demanda.id },
    data: {
      status: status as StatusDemanda,
      // O histórico vem do status.yaml inteiro, não incrementado aqui: o git é
      // a fonte, e reconstruir a lista do zero evita divergência silenciosa.
      historico: Array.isArray(body.historico) ? body.historico : [],
      ultimaExecucaoEm: new Date(),
      ultimoResultado: String(body.resultado ?? "").slice(0, 40),
      ultimoRunUrl: String(body.run_url ?? "").slice(0, 500),
    },
  });

  return NextResponse.json({ id: atualizada.id, status: atualizada.status });
}
