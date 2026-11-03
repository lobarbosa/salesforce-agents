import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { prisma } from "@/lib/prisma";
import { mesAnterior } from "@/lib/contrato";
import { chaveDia } from "@/lib/horas";
import { ehPrimeiroDiaUtil, nomeDoMes } from "@/lib/relatorio-mensal";
import { APP_URL, emailConfigurado, enviarEmail, mascarar } from "@/lib/email";

// Lembrete de fechamento (2026-11-03). Roda nos dias 1 a 3 (vercel.json) e
// só age no primeiro dia útil do mês: avisa admin e financeiro que o
// relatório do mês que fechou está pronto para revisar e enviar em
// /financeiro/horas. Não envia nada ao cliente — até 2026-11-03 enviava
// sozinho; agora quem fecha o mês confere as horas da equipe e envia.
// `?forcar=1` ignora a checagem do dia útil; `?dry=1` só devolve a prévia.

export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const q = request.nextUrl.searchParams;
  const hoje = chaveDia(new Date());
  if (q.get("forcar") !== "1" && !ehPrimeiroDiaUtil(hoje)) {
    return NextResponse.json({ ok: true, pulado: "hoje não é o primeiro dia útil do mês" });
  }
  const mes = mesAnterior(hoje.slice(0, 7), 1);
  const dry = q.get("dry") === "1" || !emailConfigurado();

  const [equipe, clientes, enviados] = await Promise.all([
    prisma.usuario.findMany({ where: { role: { in: ["admin", "financeiro"] } }, select: { email: true } }),
    prisma.client.findMany({
      where: { encerradoEm: null, usuarios: { some: { role: "cliente" } } },
      select: { id: true, nome: true },
      orderBy: { nome: "asc" },
    }),
    prisma.relatorioEnviado.findMany({ where: { mes }, select: { clientId: true } }),
  ]);
  const jaEnviados = new Set(enviados.map((e) => e.clientId));
  const pendentes = clientes.filter((c) => !jaEnviados.has(c.id));
  if (pendentes.length === 0) return NextResponse.json({ ok: true, mes, pendentes: 0 });

  const link = `${APP_URL}/financeiro/horas?mes=${mes}`;
  const assunto = `Fechamento de ${nomeDoMes(mes)}: ${pendentes.length} ${pendentes.length === 1 ? "relatório" : "relatórios"} para enviar`;
  const texto = [
    `Hoje é o primeiro dia útil do mês. As horas de ${nomeDoMes(mes)} estão prontas para fechar.`,
    "",
    "Clientes aguardando o relatório:",
    ...pendentes.map((c) => `• ${c.nome}`),
    "",
    `Revise as horas da equipe, confira o PDF de cada cliente e envie em: ${link}`,
    "",
    "— Squad OS",
  ].join("\n");

  let avisados = 0;
  if (!dry) for (const u of equipe) if (await enviarEmail({ para: u.email, assunto, texto })) avisados++;
  return NextResponse.json({ ok: true, dry, mes, pendentes: pendentes.length, avisados, para: equipe.map((u) => mascarar(u.email)) });
}
