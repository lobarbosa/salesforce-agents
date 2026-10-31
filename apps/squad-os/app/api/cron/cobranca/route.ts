import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { prisma } from "@/lib/prisma";
import { paradas } from "@/lib/esteira-parada";
import { emailDoCliente, emailDoTime, type Email, type ParadaComCliente } from "@/lib/cobranca";
import { APP_URL, emailConfigurado, enviarEmail, mascarar } from "@/lib/email";

// Vercel Cron diário (vercel.json): manda a cada pessoa o que espera por ela
// (lib/cobranca.ts). Envio pelo Microsoft 365 ou pelo Resend (lib/email.ts) —
// sem nenhum dos dois configurado, a rota só calcula e devolve o que mandaria
// (dry run), não falha. `?dry=1` força o dry run para conferir antes.


export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const dry = request.nextUrl.searchParams.get("dry") === "1" || !emailConfigurado();

  const demandas = await prisma.demanda.findMany({
    where: { status: { notIn: ["entregue", "cancelada", "recorrente"] }, client: { encerradoEm: null } },
    select: {
      clientId: true,
      code: true,
      titulo: true,
      status: true,
      congeladaDe: true,
      criadoEm: true,
      historico: true,
      estimativaConsultorHoras: true,
      estimativaAprovadaHoras: true,
      estimativaDebitadaEm: true,
      artefatoNome: true,
      disparos: { select: { tipo: true, gate: true, disparadoEm: true, concluidoEm: true } },
      client: { select: { nome: true } },
    },
  });
  const porCode = new Map(demandas.map((d) => [d.code, d.clientId]));
  // Veredito do QA não entra no e-mail do cliente; o texto do artefato fica de fora.
  const todas: ParadaComCliente[] = paradas(demandas.map((d) => ({ ...d, artefatoConteudo: "" }))).map((p) => ({
    ...p,
    clientId: porCode.get(p.code) ?? "",
  }));

  const usuarios = await prisma.usuario.findMany({
    where: { role: { in: ["cliente", "admin", "consultor"] } },
    select: { email: true, nome: true, role: true, clientId: true, client: { select: { nome: true, encerradoEm: true } } },
  });

  const emails: Email[] = [];
  for (const u of usuarios) {
    if (u.role === "cliente") {
      if (!u.clientId || !u.client || u.client.encerradoEm) continue;
      const e = emailDoCliente(u, u.client.nome, todas.filter((p) => p.clientId === u.clientId), `${APP_URL}/clients/${u.clientId}`);
      if (e) emails.push(e);
    } else {
      const e = emailDoTime(u, todas, `${APP_URL}/`);
      if (e) emails.push(e);
    }
  }

  let enviados = 0;
  if (!dry) for (const e of emails) if (await enviarEmail(e)) enviados++;
  return NextResponse.json({
    dry,
    emails: emails.length,
    enviados,
    ...(dry ? { previa: emails.map((e) => ({ para: mascarar(e.para), assunto: e.assunto })) } : {}),
  });
}
