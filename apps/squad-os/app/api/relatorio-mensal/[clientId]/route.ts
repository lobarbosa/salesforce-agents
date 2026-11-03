import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { prisma } from "@/lib/prisma";
import { chaveDia, ehChaveMes } from "@/lib/horas";
import { montarRelatorioDoCliente } from "@/lib/relatorio-mensal-data";
import { emailConfigurado, enviarEmail } from "@/lib/email";

// Fechamento mensal (2026-11-03): o admin/financeiro revisa e envia ao
// cliente o relatório do mês que fechou, em /financeiro/horas.
// GET  → o PDF, para conferir antes (prévia, não envia nada).
// POST → envia ao(s) usuário(s) do cliente, com cópia oculta a quem enviou,
//        e registra o envio. Reenviar o mesmo mês exige `reenviar: true`.

function mesValido(mes: string | null): string | null {
  const atual = chaveDia(new Date()).slice(0, 7);
  return mes && ehChaveMes(mes) && mes < atual ? mes : null;
}

export async function GET(request: NextRequest, { params }: { params: Promise<{ clientId: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { clientId } = await params;
  const mes = mesValido(request.nextUrl.searchParams.get("mes"));
  if (!mes) return NextResponse.json({ error: "mês inválido — só meses já fechados" }, { status: 400 });
  const r = await montarRelatorioDoCliente(clientId, mes);
  if (!r) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  return new NextResponse(new Uint8Array(r.pdf), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${r.nomeArquivo}"`,
      "Cache-Control": "no-store",
    },
  });
}

export async function POST(request: NextRequest, { params }: { params: Promise<{ clientId: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;
  const { clientId } = await params;
  const corpo = (await request.json().catch(() => null)) as { mes?: string; reenviar?: boolean } | null;
  const mes = mesValido(corpo?.mes ?? null);
  if (!mes) return NextResponse.json({ error: "mês inválido — só meses já fechados" }, { status: 400 });
  if (!emailConfigurado()) {
    return NextResponse.json({ error: "envio de e-mail não configurado (Microsoft 365 ou Resend) — veja com o admin" }, { status: 503 });
  }

  const anterior = await prisma.relatorioEnviado.findUnique({ where: { clientId_mes: { clientId, mes } } });
  if (anterior && !corpo?.reenviar) {
    return NextResponse.json(
      { error: `já enviado por ${anterior.enviadoPor} — use "Reenviar" se for de propósito`, jaEnviado: true },
      { status: 409 }
    );
  }

  const r = await montarRelatorioDoCliente(clientId, mes);
  if (!r) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  if (r.para.length === 0) {
    return NextResponse.json({ error: "o cliente não tem nenhum usuário com e-mail no portal para receber" }, { status: 409 });
  }

  let enviados = 0;
  for (const [i, para] of r.para.entries()) {
    const ok = await enviarEmail({
      para,
      assunto: r.assunto,
      texto: r.texto,
      anexos: [{ nome: r.nomeArquivo, conteudo: r.pdf }],
      // Quem fechou o mês recebe a mesma coisa, uma vez por cliente.
      cco: i === 0 ? [usuario.email] : undefined,
    });
    if (ok) enviados++;
  }
  if (enviados === 0) return NextResponse.json({ error: "o provedor de e-mail recusou o envio — tente de novo" }, { status: 502 });

  const enviadoPor = usuario.nome.trim() || usuario.email;
  await prisma.relatorioEnviado.upsert({
    where: { clientId_mes: { clientId, mes } },
    create: { clientId, mes, enviadoPor, destinatarios: enviados },
    update: { enviadoPor, destinatarios: enviados, enviadoEm: new Date() },
  });
  return NextResponse.json({ ok: true, enviados, de: r.para.length });
}
