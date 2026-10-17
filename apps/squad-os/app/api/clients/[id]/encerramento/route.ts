import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import {
  linhaDeAuditoria,
  podeEncerrarCliente,
  validarEncerramento,
  validarReativacao,
} from "@/lib/encerramento";

// Encerrar (POST) e reativar (DELETE) um cliente — só admin. Encerrar é o
// caminho para "cliente que saiu": some das listas, o usuário `cliente` dele
// perde o acesso, nada novo nasce (demanda, hora, run de agente), e o
// histórico fica. Regras em lib/encerramento.ts.
//
// Auditoria: `encerrado_por_email`/`encerrado_em` no próprio cliente (o
// último encerramento) + uma linha JSON no log do servidor para cada ação —
// não existe tabela de eventos de cliente, e uma só para isto seria mais um
// lugar para manter.

async function carregar(id: string) {
  return prisma.client.findUnique({
    where: { id },
    select: { id: true, slug: true, nome: true, encerradoEm: true },
  });
}

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !podeEncerrarCliente(usuario.role)) {
    return NextResponse.json({ error: "sem permissão — só admin encerra cliente" }, { status: 403 });
  }
  const { id } = await params;
  const client = await carregar(id);
  if (!client) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });

  const body = await request.json().catch(() => ({}));
  const motivo = String(body?.motivo ?? "");
  const v = validarEncerramento(client, motivo);
  if (!v.ok) return NextResponse.json({ error: v.error }, { status: v.status });

  // Compare-and-set: dois cliques (ou dois admins) não encerram duas vezes
  // sobrescrevendo quem/quando do primeiro.
  const agora = new Date();
  const { count } = await prisma.client.updateMany({
    where: { id, encerradoEm: null },
    data: { encerradoEm: agora, encerradoPorEmail: usuario.email, motivoEncerramento: motivo.trim() },
  });
  if (count === 0) {
    return NextResponse.json({ error: "o cliente acabou de ser encerrado por outra pessoa — recarregue" }, { status: 409 });
  }
  console.info(linhaDeAuditoria("encerrou", client, usuario.email, { motivo: motivo.trim() }));

  return NextResponse.json({ ok: true, encerradoEm: agora, encerradoPorEmail: usuario.email });
}

export async function DELETE(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !podeEncerrarCliente(usuario.role)) {
    return NextResponse.json({ error: "sem permissão — só admin reativa cliente" }, { status: 403 });
  }
  const { id } = await params;
  const client = await carregar(id);
  if (!client) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });

  const v = validarReativacao(client);
  if (!v.ok) return NextResponse.json({ error: v.error }, { status: v.status });

  // O motivo e quem encerrou ficam no log de auditoria; no cliente, zera
  // tudo — reativado é ativo, sem resto de estado.
  await prisma.client.update({
    where: { id },
    data: { encerradoEm: null, encerradoPorEmail: null, motivoEncerramento: "" },
  });
  console.info(linhaDeAuditoria("reativou", client, usuario.email, { encerradoEm: client.encerradoEm }));

  return NextResponse.json({ ok: true });
}
