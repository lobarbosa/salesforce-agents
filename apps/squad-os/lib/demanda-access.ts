import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario, type CurrentUsuario } from "@/lib/current-user";
import { canAccessClient, canManageClientData } from "@/lib/auth";
import { bloqueioPorEncerramento, enxergaCliente, type AcaoBloqueada } from "@/lib/encerramento";

type Ok = { usuario: CurrentUsuario; demandaId: string; erro?: never };
type Erro = { erro: NextResponse; usuario?: never; demandaId?: never };

// Toda rota filha de /api/demandas/[id] repete a mesma pergunta: existe a
// demanda, e este usuário alcança o cliente dela? O papel `cliente` participa
// do próprio card (comenta, anexa, aprova a homologação), então o gate padrão
// é canAccessClient e não canManageClientData.
//
// `somenteDelivery` é para o que é instrumento interno do time: subtarefa,
// checklist e lançamento de tempo. Achado real (2026-09-18): isso estava só
// escondido pela UI em alguns lugares e nem isso em outros — um usuário
// `cliente` conseguia criar e remover subtarefa, item de checklist e
// lançamento de tempo de consultor no próprio card. A UI nunca foi o gate.
//
// Cliente encerrado (lib/encerramento.ts): só o admin ainda alcança as
// demandas dele (histórico); e `clienteAtivo` recusa com 409 o que criaria
// coisa nova — hoje, lançamento de horas.
export async function resolverDemanda(
  id: string,
  opcoes: { somenteDelivery?: boolean; clienteAtivo?: AcaoBloqueada } = {}
): Promise<Ok | Erro> {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    select: { id: true, clientId: true, client: { select: { nome: true, encerradoEm: true } } },
  });
  if (!demanda) {
    return { erro: NextResponse.json({ error: "demanda não encontrada" }, { status: 404 }) };
  }

  if (!canAccessClient(usuario.role, usuario.clientId, demanda.clientId)) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }

  if (opcoes.somenteDelivery && !canManageClientData(usuario.role)) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }

  if (!enxergaCliente(usuario.role, demanda.client)) {
    return {
      erro: NextResponse.json(
        { error: bloqueioPorEncerramento(demanda.client, "demanda"), clienteEncerrado: true },
        { status: 409 }
      ),
    };
  }
  if (opcoes.clienteAtivo) {
    const bloqueio = bloqueioPorEncerramento(demanda.client, opcoes.clienteAtivo);
    if (bloqueio) {
      return { erro: NextResponse.json({ error: bloqueio, clienteEncerrado: true }, { status: 409 }) };
    }
  }

  return { usuario, demandaId: demanda.id };
}
