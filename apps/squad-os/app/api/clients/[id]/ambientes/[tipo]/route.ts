import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import type { TipoAmbiente } from "@/lib/generated/prisma/client";

const TIPOS: TipoAmbiente[] = ["dev", "qa"];

// Campos que identificam a conexão. Nunca a chave privada nem o Consumer
// Secret — esses ficam só no GitHub Environment `<slug>-<tipo>`.
const EDITABLE_FIELDS = ["orgAlias", "loginUrl", "username", "consumerKey"] as const;

function parseTipo(raw: string): TipoAmbiente | null {
  return (TIPOS as string[]).includes(raw) ? (raw as TipoAmbiente) : null;
}

// Upsert em vez de update: a migration só criou a linha `dev` dos clientes que
// já tinham conexão cadastrada. Os demais ambientes passam a existir no
// primeiro save, sem precisar de um passo de criação explícito na UI.
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; tipo: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id, tipo: tipoRaw } = await params;
  const tipo = parseTipo(tipoRaw);
  if (!tipo) {
    return NextResponse.json({ error: "ambiente inválido" }, { status: 400 });
  }

  const body = await request.json();
  const data: Record<string, string> = {};
  for (const key of EDITABLE_FIELDS) {
    if (key in body) data[key] = String(body[key] ?? "");
  }
  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nenhum campo editável enviado" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({ where: { id }, select: { id: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const ambiente = await prisma.ambienteOrg.upsert({
    where: { clientId_tipo: { clientId: id, tipo } },
    update: data,
    create: { clientId: id, tipo, ...data },
  });

  return NextResponse.json(ambiente);
}
