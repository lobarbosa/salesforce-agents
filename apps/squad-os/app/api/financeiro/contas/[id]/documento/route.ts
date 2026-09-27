import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { paraVista } from "@/lib/contas-data";
import { redirecionarDownload, removerArquivo, subirArquivo } from "@/lib/arquivo";
import { BUCKET_FINANCEIRO } from "@/lib/supabase/storage";

export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const c = await prisma.contaPagar.findUnique({ where: { id }, select: { documentoCaminho: true, documentoNome: true } });
  if (!c?.documentoCaminho) return NextResponse.json({ error: "esta conta não tem documento" }, { status: 404 });
  return redirecionarDownload(BUCKET_FINANCEIRO, c.documentoCaminho, c.documentoNome);
}

// Anexa (ou troca) o documento fiscal. Conta paga ou cancelada não muda mais.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const c = await prisma.contaPagar.findUnique({ where: { id } });
  if (!c) return NextResponse.json({ error: "conta não encontrada" }, { status: 404 });
  if (c.status === "paga" || c.status === "cancelada") {
    return NextResponse.json({ error: "conta paga ou cancelada não recebe documento novo" }, { status: 409 });
  }
  const arquivo = (await request.formData()).get("documento");
  if (!(arquivo instanceof File)) return NextResponse.json({ error: "nenhum arquivo enviado" }, { status: 400 });
  const r = await subirArquivo(BUCKET_FINANCEIRO, "contas", arquivo);
  if ("erro" in r) return r.erro;

  const atualizada = await prisma.$transaction(async (tx) => {
    const u = await tx.contaPagar.update({ where: { id }, data: { documentoCaminho: r.caminho, documentoNome: r.nome } });
    await tx.eventoConta.create({
      data: { contaId: id, acao: "documento", porEmail: acesso.usuario.email, comentario: r.nome },
    });
    return u;
  });
  // O documento anterior sai do bucket; a trilha guarda que houve troca.
  if (c.documentoCaminho) await removerArquivo(BUCKET_FINANCEIRO, c.documentoCaminho);
  return NextResponse.json(paraVista(atualizada));
}
