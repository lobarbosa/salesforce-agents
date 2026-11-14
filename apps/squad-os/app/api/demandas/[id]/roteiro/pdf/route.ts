import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { canManageClientData } from "@/lib/auth";
import { resolverDemanda } from "@/lib/demanda-access";
import { chaveDia } from "@/lib/horas";
import { clienteVeRoteiro } from "@/lib/visao-cliente";
import { gerarPdfRoteiro, nomeDoArquivoDoRoteiro } from "@/lib/roteiro-pdf";

// Roteiro de teste do cliente em PDF (2026-11-14): o passo a passo de
// homologação que o agente de QA escreve, no mesmo desenho do espelho de
// horas. Só leitura. Quem alcança a demanda baixa; o papel `cliente`, só da
// homologação em diante — a mesma regra do card (lib/visao-cliente.ts).
export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    select: { code: true, titulo: true, status: true, roteiroCliente: true, client: { select: { nome: true } } },
  });
  const liberado = demanda && (canManageClientData(acesso.usuario.role) || clienteVeRoteiro(demanda.status));
  if (!demanda || !liberado || !demanda.roteiroCliente.trim()) {
    return NextResponse.json({ error: "esta demanda ainda não tem roteiro de teste" }, { status: 404 });
  }

  const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
  const pdf = await gerarPdfRoteiro(
    demanda.roteiroCliente,
    { clienteNome: demanda.client.nome, codigo: demanda.code, titulo: demanda.titulo, emissor: "Acxya", geradoEm: chaveDia(new Date()) },
    logo
  );
  return new NextResponse(new Uint8Array(pdf), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${nomeDoArquivoDoRoteiro(demanda.code)}"`,
      "Cache-Control": "no-store",
    },
  });
}
