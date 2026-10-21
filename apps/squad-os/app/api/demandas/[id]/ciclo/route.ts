import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import type { Prisma, StatusDemanda } from "@/lib/generated/prisma/client";
import { resolverDemanda } from "@/lib/demanda-access";
import { registrarStatusNoGit } from "@/lib/github";
import { ESTAGIOS_PARAVEIS, podeCancelar } from "@/lib/demandas";

// Congelar, descongelar e cancelar (2026-10-21). Só delivery.
//
// Só se para uma demanda que não está com agente rodando: na triagem ou
// esperando gate humano. Parar no meio de uma etapa deixaria a sessão do
// Actions terminando e o sync de volta desfazendo a parada — espere o gate.
//
// Demanda materializada muda o status.yaml no git primeiro (fonte de
// verdade; fluxo.py recusa rodar standby/cancelada) e só então o Postgres.
// Se o git falhar, nada muda aqui.

type Acao = "congelar" | "descongelar" | "cancelar";

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;
  const autor = acesso.usuario.nome.trim() || acesso.usuario.email;

  const body = (await request.json().catch(() => null)) as { acao?: unknown; motivo?: unknown } | null;
  const acao = String(body?.acao ?? "") as Acao;
  const motivo = String(body?.motivo ?? "").trim().slice(0, 1000);
  if (!["congelar", "descongelar", "cancelar"].includes(acao)) {
    return NextResponse.json({ error: "ação inválida" }, { status: 400 });
  }
  if (acao !== "descongelar" && !motivo) {
    return NextResponse.json({ error: "informe o motivo" }, { status: 400 });
  }

  const demanda = await prisma.demanda.findUniqueOrThrow({
    where: { id },
    include: { client: { select: { slug: true } } },
  });

  let para: StatusDemanda;
  if (acao === "descongelar") {
    if (demanda.status !== "standby") {
      return NextResponse.json({ error: "a demanda não está congelada" }, { status: 409 });
    }
    para = demanda.congeladaDe ?? "backlog";
  } else {
    const podeParar = acao === "cancelar" ? podeCancelar(demanda.status) : ESTAGIOS_PARAVEIS.includes(demanda.status);
    if (!podeParar) {
      return NextResponse.json(
        {
          error:
            demanda.status === "cancelada" || demanda.status === "entregue"
              ? "a demanda já está encerrada"
              : "há uma etapa de agente rodando — espere ela chegar ao gate para parar",
        },
        { status: 409 }
      );
    }
    para = acao === "congelar" ? "standby" : "cancelada";
  }

  if (demanda.materializadoEm) {
    try {
      await registrarStatusNoGit(demanda.client.slug, demanda.code, para, autor, motivo);
    } catch (err) {
      return NextResponse.json(
        { error: `não consegui gravar o status no repositório: ${(err as Error).message}` },
        { status: 502 }
      );
    }
  }

  const data: Prisma.DemandaUpdateManyMutationInput = {
    status: para,
    historico: [
      ...(Array.isArray(demanda.historico) ? demanda.historico : []),
      { de: demanda.status, para, autor, em: new Date().toISOString(), ...(motivo ? { motivo } : {}) },
    ] as Prisma.InputJsonValue,
    motivoParada: acao === "descongelar" ? "" : motivo,
    congeladaDe: acao === "congelar" ? demanda.status : acao === "descongelar" ? null : demanda.congeladaDe,
  };
  // Compare-and-set, igual ao PATCH do card: se o sync moveu a demanda no meio, recusa.
  const { count } = await prisma.demanda.updateMany({ where: { id, status: demanda.status }, data });
  if (count === 0) {
    return NextResponse.json({ error: "a demanda mudou de etapa — recarregue a página" }, { status: 409 });
  }
  return NextResponse.json(await prisma.demanda.findUnique({ where: { id } }));
}
