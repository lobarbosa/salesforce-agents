import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";

// Campos editáveis por PATCH — um por vez, no mesmo padrão de autosave-on-blur
// da versão anterior. Os campos de conexão saíram daqui: agora são por
// ambiente, em /api/clients/[id]/ambientes/[tipo]. Chave privada e Consumer
// Secret nunca entram em nenhuma das duas (ver docs/conexoes-e-setup.md).
const EDITABLE_FIELDS = [
  "nome",
  "segmento",
  "contatos",
  "ambienteSalesforce",
  "integracoes",
  "regras",
] as const;
// `marcas` e `concorrentes` saíram do briefing a pedido. As colunas seguem no
// banco (vazias nos 5 clientes na remoção) — dropar exige migration, e depois
// do incidente de 2026-09-09 migration destrutiva não entra de carona em
// mudança de UI.

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();

  const data: Record<string, string> = {};
  for (const key of EDITABLE_FIELDS) {
    if (key in body) data[key] = String(body[key] ?? "");
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nenhum campo editável enviado" }, { status: 400 });
  }

  try {
    const client = await prisma.client.update({ where: { id }, data });
    return NextResponse.json(client);
  } catch {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }
}
