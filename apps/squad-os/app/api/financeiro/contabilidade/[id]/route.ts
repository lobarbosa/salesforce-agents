import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { redirecionarDownload } from "@/lib/arquivo";
import { BUCKET_FINANCEIRO } from "@/lib/supabase/storage";

export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const d = await prisma.documentoContabil.findUnique({ where: { id } });
  if (!d) return NextResponse.json({ error: "documento não encontrado" }, { status: 404 });
  return redirecionarDownload(BUCKET_FINANCEIRO, d.caminho, d.nome);
}

// Remoção lógica: o agente para de considerar o arquivo na próxima
// conciliação; o arquivo e quem removeu ficam registrados.
export async function DELETE(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const r = await prisma.documentoContabil.updateMany({
    where: { id, removidoEm: null },
    data: { removidoEm: new Date(), removidoPorEmail: acesso.usuario.email },
  });
  if (!r.count) return NextResponse.json({ error: "documento não encontrado ou já removido" }, { status: 404 });
  return NextResponse.json({ ok: true });
}
