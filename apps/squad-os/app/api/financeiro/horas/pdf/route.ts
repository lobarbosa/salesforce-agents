import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { prisma } from "@/lib/prisma";
import { chaveDia } from "@/lib/horas";
import { erroDoPeriodo, janelaDaConsulta, montarEspelho, nomeDoArquivo } from "@/lib/espelho-horas";
import { gerarPdfEspelho } from "@/lib/espelho-horas-pdf";

// Espelho de horas em PDF (2026-11-11): o financeiro escolhe cliente e período
// em /financeiro/horas e baixa o PDF para mandar ao cliente. Só leitura: não
// envia nada nem registra envio (isso é o fechamento mensal).
// GET ?clientId=…&desde=YYYY-MM-DD&ate=YYYY-MM-DD[&consultor=<e-mail>]

export async function GET(request: NextRequest) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const q = request.nextUrl.searchParams;
  const clientId = q.get("clientId") ?? "";
  const desde = q.get("desde");
  const ate = q.get("ate");
  const consultor = (q.get("consultor") ?? "").trim().toLowerCase();

  const hoje = chaveDia(new Date());
  const erro = erroDoPeriodo(desde, ate, hoje);
  if (erro || !desde || !ate) return NextResponse.json({ error: erro ?? "período inválido" }, { status: 400 });
  if (!clientId) return NextResponse.json({ error: "escolha o cliente" }, { status: 400 });

  const cliente = await prisma.client.findUnique({ where: { id: clientId }, select: { nome: true } });
  if (!cliente) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });

  const registros = await prisma.registroTempo.findMany({
    where: {
      demanda: { clientId },
      fimEm: { not: null },
      inicioEm: janelaDaConsulta(desde, ate),
      ...(consultor ? { autorEmail: { equals: consultor, mode: "insensitive" as const } } : {}),
    },
    select: { autor: true, inicioEm: true, minutos: true, demanda: { select: { code: true, titulo: true } } },
  });

  const espelho = montarEspelho(registros, desde, ate);
  const nomeConsultor = consultor ? espelho.porConsultor[0]?.consultor ?? consultor : undefined;
  const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
  const pdf = await gerarPdfEspelho(
    espelho,
    { clienteNome: cliente.nome, consultor: nomeConsultor, emissor: "Acxya", geradoEm: hoje },
    logo
  );
  return new NextResponse(new Uint8Array(pdf), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${nomeDoArquivo(cliente.nome, desde, ate, nomeConsultor)}"`,
      "Cache-Control": "no-store",
    },
  });
}
