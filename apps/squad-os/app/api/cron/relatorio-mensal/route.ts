import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { prisma } from "@/lib/prisma";
import { horasPorMes } from "@/lib/data";

import { mesAnterior, progressoDoProjeto } from "@/lib/contrato";
import { chaveDia } from "@/lib/horas";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { entreguesNoMes, textoDoRelatorio, type DadosRelatorio } from "@/lib/relatorio-mensal";
import { gerarPdfRelatorio } from "@/lib/relatorio-pdf";
import { demandasPorEntregavel } from "@/lib/data";
import { APP_URL, emailConfigurado, enviarEmail, mascarar } from "@/lib/email";

// Vercel Cron no dia 1 (vercel.json): cada cliente recebe o resumo do mês que
// fechou — demandas concluídas e horas do contrato (lib/relatorio-mensal.ts).
// Vai para os usuários de papel `cliente`, com cópia oculta aos admins: o
// e-mail traz os tópicos principais e o PDF anexo traz o detalhe.
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
      demandas: {
        where: { status: "entregue" },
        select: {
          code: true,
          titulo: true,
          status: true,
          historico: true,
          estimativaDebitadaHoras: true,
          tempos: { where: { fimEm: { not: null } }, select: { minutos: true } },
        },
      },
    },
  });

  // Logo da marca no PDF (PNG/JPEG; o pdfkit não lê SVG/WebP).
  const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);

  const previa: { cliente: string; para: string[]; assunto: string }[] = [];
  let enviados = 0;
  for (const c of clientes) {
    const k = c.contrato;
    let contrato: DadosRelatorio["contrato"] = null;
    if (k?.tipo === "ams") {
      const meses = await horasPorMes(c.id, distancia + 6);
      const ate = meses.filter((m) => m.mes <= mes);
      contrato = { tipo: "ams", cicloHoras: k.cicloHoras, doMes: meses.find((m) => m.mes === mes) ?? null, historico: ate.slice(-6) };
    } else if (k?.tipo === "projeto") {
      const porEntregavel = await demandasPorEntregavel(c.id);
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
        entregaveis: k.entregaveis.map((e) => ({
          titulo: e.titulo,
          peso: e.peso,
          concluido: e.concluido,
          demandas: porEntregavel[e.id] ?? { total: 0, entregues: 0 },
        })),
        historico: ate,
        fimPrevisto: k.fimPrevistoEm ? chaveDia(k.fimPrevistoEm) : null,
      };
    }
    const dados: DadosRelatorio = {
      clienteNome: c.nome,
      mes,
      entregues: entreguesNoMes(c.demandas, mes).map((d) => {
        const hist = Array.isArray(d.historico) ? (d.historico as { para?: string; em?: string }[]) : [];
        const em = [...hist].reverse().find((x) => x?.para === "entregue" && x.em)?.em;
        return {
          code: d.code,
          titulo: d.titulo,
          entregueEm: em ? chaveDia(new Date(em)) : undefined,
          horasAprovadas: d.estimativaDebitadaHoras,
          horasLancadas: d.tempos.reduce((s, r) => s + (r.minutos ?? 0), 0) / 60,
        };
      }),
      contrato,
      url: `${APP_URL}/clients/${c.id}`,
    };
    const { assunto, texto } = textoDoRelatorio(dados);
    const pdf = await gerarPdfRelatorio(dados, logo);
    const anexos = [{ nome: `relatorio-${c.nome.toLowerCase().normalize("NFD").replace(/[^a-z0-9]+/g, "-")}-${mes}.pdf`, conteudo: pdf }];
    const para = c.usuarios.map((u) => u.email);
    previa.push({ cliente: c.nome, para: para.map(mascarar), assunto });
    if (!dry) {
      for (const [i, p] of para.entries()) {
        // Cópia oculta aos admins só uma vez por cliente.
        if (await enviarEmail({ para: p, assunto, texto, anexos, cco: i === 0 ? admins : undefined })) enviados++;
      }
    }
  }
  return NextResponse.json({ dry, mes, clientes: clientes.length, enviados, previa });
}
