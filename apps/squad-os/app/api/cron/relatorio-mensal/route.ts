import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { prisma } from "@/lib/prisma";
import { horasPorMes } from "@/lib/data";
import { mesAnterior, progressoDoProjeto } from "@/lib/contrato";
import { chaveDia } from "@/lib/horas";
import { entreguesNoMes, textoDoRelatorio, type DadosRelatorio } from "@/lib/relatorio-mensal";
import { APP_URL, emailConfigurado, enviarEmail, mascarar } from "@/lib/email";

// Vercel Cron no dia 1 (vercel.json): cada cliente recebe o resumo do mês que
// fechou — demandas concluídas e horas do contrato (lib/relatorio-mensal.ts).
// Vai para os usuários de papel `cliente`, com cópia oculta aos admins.
// `?mes=AAAA-MM` refaz um mês específico; `?dry=1` (ou sem e-mail configurado)
// só devolve a prévia.

export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const q = request.nextUrl.searchParams;
  const dry = q.get("dry") === "1" || !emailConfigurado();
  const mes = /^\d{4}-\d{2}$/.test(q.get("mes") ?? "") ? q.get("mes")! : mesAnterior(chaveDia(new Date()).slice(0, 7), 1);
  // Meses entre `mes` e hoje, para achar `mes` no histórico de horasPorMes.
  const atual = chaveDia(new Date()).slice(0, 7);
  let distancia = 0;
  while (mesAnterior(atual, distancia) !== mes && distancia < 36) distancia++;

  const admins = (await prisma.usuario.findMany({ where: { role: "admin" }, select: { email: true } })).map((u) => u.email);
  const clientes = await prisma.client.findMany({
    where: { encerradoEm: null, usuarios: { some: { role: "cliente" } } },
    select: {
      id: true,
      nome: true,
      usuarios: { where: { role: "cliente" }, select: { email: true } },
      contrato: { include: { entregaveis: { orderBy: { ordem: "asc" } } } },
      demandas: { where: { status: "entregue" }, select: { code: true, titulo: true, status: true, historico: true } },
    },
  });

  const previa: { cliente: string; para: string[]; assunto: string }[] = [];
  let enviados = 0;
  for (const c of clientes) {
    const k = c.contrato;
    let contrato: DadosRelatorio["contrato"] = null;
    if (k?.tipo === "ams") {
      const meses = await horasPorMes(c.id, distancia + 1);
      contrato = { tipo: "ams", cicloHoras: k.cicloHoras, doMes: meses.find((m) => m.mes === mes) ?? null };
    } else if (k?.tipo === "projeto") {
      const desde = k.inicioEm ? chaveDia(k.inicioEm).slice(0, 7) : mes;
      let n = 0;
      while (mesAnterior(atual, n) !== desde && n < 36) n++;
      const meses = await horasPorMes(c.id, Math.max(n, distancia) + 1);
      const ate = meses.filter((m) => m.mes >= desde && m.mes <= mes);
      contrato = {
        tipo: "projeto",
        nome: k.projetoNome,
        progresso: progressoDoProjeto(k.entregaveis),
        horasDoMes: meses.find((m) => m.mes === mes)?.horasGastas ?? 0,
        horasAcumuladas: ate.reduce((s, m) => s + m.horasGastas, 0),
        horasContratadas: k.horasContratadas,
        entregaveisConcluidos: k.entregaveis.filter((e) => e.concluido).map((e) => e.titulo),
      };
    }
    const { assunto, texto } = textoDoRelatorio({
      clienteNome: c.nome,
      mes,
      entregues: entreguesNoMes(c.demandas, mes).map((d) => ({ code: d.code, titulo: d.titulo })),
      contrato,
      url: `${APP_URL}/clients/${c.id}`,
    });
    const para = c.usuarios.map((u) => u.email);
    previa.push({ cliente: c.nome, para: para.map(mascarar), assunto });
    if (!dry) {
      for (const [i, p] of para.entries()) {
        // Cópia oculta aos admins só uma vez por cliente.
        if (await enviarEmail({ para: p, assunto, texto, cco: i === 0 ? admins : undefined })) enviados++;
      }
    }
  }
  return NextResponse.json({ dry, mes, clientes: clientes.length, enviados, previa });
}
