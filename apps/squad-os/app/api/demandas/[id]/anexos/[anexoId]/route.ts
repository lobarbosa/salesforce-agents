import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { BUCKET_ANEXOS, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";

// URL assinada curta em vez de link público: o link expira antes de virar
// algo que se encaminha por aí, e cada download passa de novo pelo gate de
// acesso da demanda.
const SEGUNDOS_VALIDADE = 60;

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; anexoId: string }> }
) {
  const { id, anexoId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  if (!serviceRoleConfigurado()) {
    return NextResponse.json({ error: "anexos ainda não configurados" }, { status: 503 });
  }

  const anexo = await prisma.anexo.findFirst({ where: { id: anexoId, demandaId: id } });
  if (!anexo) {
    return NextResponse.json({ error: "anexo não encontrado" }, { status: 404 });
  }

  const storage = createServiceClient();
  const { data, error } = await storage.storage
    .from(BUCKET_ANEXOS)
    .createSignedUrl(anexo.caminho, SEGUNDOS_VALIDADE, { download: anexo.nome });
  if (error || !data) {
    return NextResponse.json({ error: "falha ao gerar o link de download" }, { status: 502 });
  }

  return NextResponse.redirect(data.signedUrl);
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string; anexoId: string }> }
) {
  const { id, anexoId } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const anexo = await prisma.anexo.findFirst({ where: { id: anexoId, demandaId: id } });
  if (!anexo) {
    return NextResponse.json({ error: "anexo não encontrado" }, { status: 404 });
  }
  if (usuario.role !== "admin" && anexo.autorEmail !== usuario.email) {
    return NextResponse.json({ error: "só quem anexou (ou um admin) pode remover" }, { status: 403 });
  }

  if (serviceRoleConfigurado()) {
    // Apaga o objeto primeiro: se falhar, a linha continua e o anexo segue
    // baixável — o inverso deixaria arquivo órfão sem ninguém pra encontrar.
    const storage = createServiceClient();
    const { error } = await storage.storage.from(BUCKET_ANEXOS).remove([anexo.caminho]);
    if (error) {
      return NextResponse.json({ error: "falha ao remover o arquivo" }, { status: 502 });
    }
  }

  await prisma.anexo.delete({ where: { id: anexoId } });
  return new NextResponse(null, { status: 204 });
}
