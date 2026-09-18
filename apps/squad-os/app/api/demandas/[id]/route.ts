import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import type { Prisma, StatusDemanda } from "@/lib/generated/prisma/client";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient, canManageClientData } from "@/lib/auth";
import { GATE_DO_CLIENTE } from "@/lib/demandas";

// Status de triagem que o próprio card pode mover (dropdown no board) —
// os estágios de execução só avançam via `sfagents demanda avancar`, o card
// aqui é só leitura pra esses (mesma regra da versão Artifact). Mover
// triagem é coisa de admin/consultor; role=cliente só mexe nas perguntas e na
// aprovação do gate que é dele (ver GATE_DO_CLIENTE abaixo).
const TRIAGE_STATUSES: StatusDemanda[] = ["backlog", "planejada", "recorrente", "standby"];

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();

  const demanda = await prisma.demanda.findUnique({ where: { id } });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  if (!canAccessClient(usuario.role, usuario.clientId, demanda.clientId)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const data: Prisma.DemandaUpdateInput = {};

  if ("status" in body) {
    if (!canManageClientData(usuario.role)) {
      return NextResponse.json({ error: "sem permissão pra mover triagem" }, { status: 403 });
    }
    const status = String(body.status) as StatusDemanda;
    if (!TRIAGE_STATUSES.includes(status)) {
      return NextResponse.json(
        { error: "esse status só avança via sfagents (fora da triagem)" },
        { status: 400 }
      );
    }
    data.status = status;
    data.historico = [
      ...(Array.isArray(demanda.historico) ? demanda.historico : []),
      { de: demanda.status, para: status, autor: String(body.autor ?? usuario.nome ?? "os"), em: new Date().toISOString() },
    ];
  }

  // Responder as perguntas do gate e registrar a aprovação são a mesma coisa
  // que aprovar: quem faz isso é quem aprova aquele gate. Pro papel `cliente`
  // isso é só `aguardando_homologacao` — a mesma regra de
  // /api/demandas/[id]/aprovar-gate, e por isso a mesma constante. Sem isto a
  // tela escondia as perguntas do gate interno mas a API aceitava a resposta,
  // que é o tipo de porta que ninguém encontra até alguém encontrar.
  if ("perguntas" in body || "aprovacao" in body) {
    if (!canManageClientData(usuario.role) && demanda.status !== GATE_DO_CLIENTE) {
      return NextResponse.json(
        { error: "este gate é interno de delivery — quem responde é o time da Acxya" },
        { status: 403 }
      );
    }
  }

  if ("perguntas" in body) {
    data.perguntas = body.perguntas;
  }

  if ("aprovacao" in body) {
    data.aprovacao = body.aprovacao;
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nenhum campo editável enviado" }, { status: 400 });
  }

  const updated = await prisma.demanda.update({ where: { id }, data });
  return NextResponse.json(updated);
}
