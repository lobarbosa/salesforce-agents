import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { INCLUDE_VISTA, paraVista } from "@/lib/contas-data";
import { bloqueioDocumento } from "@/lib/contas";
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

// Anexa (ou troca) o documento fiscal — regra em bloqueioDocumento
// (lib/contas.ts): depois de aprovada, o documento aprovado não muda mais.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const c = await prisma.contaPagar.findUnique({ where: { id } });
  if (!c) return NextResponse.json({ error: "conta não encontrada" }, { status: 404 });
  const bloqueado = bloqueioDocumento(c.status, Boolean(c.documentoCaminho));
  if (bloqueado) return NextResponse.json({ error: bloqueado }, { status: 409 });

  const arquivo = (await request.formData()).get("documento");
  if (!(arquivo instanceof File)) return NextResponse.json({ error: "nenhum arquivo enviado" }, { status: 400 });
  const r = await subirArquivo(BUCKET_FINANCEIRO, "contas", arquivo, "conta");
  if ("erro" in r) return r.erro;

  // O arquivo anterior fica no bucket: a trilha (imutável) registra a troca
  // e o caminho do que foi substituído, pra auditoria conseguir abrir os dois.
  const comentario = c.documentoCaminho
    ? `${r.nome} (substitui ${c.documentoNome || "documento anterior"}; anterior mantido em ${c.documentoCaminho})`
    : r.nome;

  let atualizada;
  try {
    atualizada = await prisma.$transaction(async (tx) => {
      // Compare-and-set: só grava se a conta ainda está no estado lido acima
      // (ninguém aprovou, pagou ou trocou o documento no meio do upload).
      const { count } = await tx.contaPagar.updateMany({
        where: { id, status: c.status, documentoCaminho: c.documentoCaminho },
        data: { documentoCaminho: r.caminho, documentoNome: r.nome },
      });
      if (count === 0) return null;
      await tx.eventoConta.create({
        data: { contaId: id, acao: "documento", porEmail: acesso.usuario.email, comentario },
      });
      return tx.contaPagar.findUniqueOrThrow({ where: { id }, include: INCLUDE_VISTA });
    });
  } catch (e) {
    await removerArquivo(BUCKET_FINANCEIRO, r.caminho);
    throw e;
  }
  if (!atualizada) {
    await removerArquivo(BUCKET_FINANCEIRO, r.caminho);
    return NextResponse.json(
      { error: "a conta mudou enquanto o arquivo subia (aprovada, paga ou documento trocado) — recarregue" },
      { status: 409 }
    );
  }
  return NextResponse.json(paraVista(atualizada));
}
