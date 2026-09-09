import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario, type CurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";

type Ok = { usuario: CurrentUsuario; demandaId: string; erro?: never };
type Erro = { erro: NextResponse; usuario?: never; demandaId?: never };

// Toda rota filha de /api/demandas/[id] repete a mesma pergunta: existe a
// demanda, e este usuário alcança o cliente dela? O papel `cliente` participa
// do próprio card (comenta, marca checklist), então o gate aqui é
// canAccessClient e não canManageClientData — quem restringe por papel é cada
// rota, quando precisa.
export async function resolverDemanda(id: string): Promise<Ok | Erro> {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    select: { id: true, clientId: true },
  });
  if (!demanda) {
    return { erro: NextResponse.json({ error: "demanda não encontrada" }, { status: 404 }) };
  }

  if (!canAccessClient(usuario.role, usuario.clientId, demanda.clientId)) {
    return { erro: NextResponse.json({ error: "sem permissão" }, { status: 403 }) };
  }

  return { usuario, demandaId: demanda.id };
}
