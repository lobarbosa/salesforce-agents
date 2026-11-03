import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { prisma } from "@/lib/prisma";
import { demandasPorEntregavel, horasPorMes } from "@/lib/data";
import { mesAnterior, progressoDoProjeto } from "@/lib/contrato";
import { chaveDia } from "@/lib/horas";
import { entreguesNoMes, textoDoRelatorio, type DadosRelatorio } from "@/lib/relatorio-mensal";
import { gerarPdfRelatorio } from "@/lib/relatorio-pdf";
import { APP_URL } from "@/lib/email";

// Fechamento mensal de um cliente (2026-11-03): monta o relatório — demandas
// concluídas, contrato e as horas que cada consultor lançou no mês — para o
// admin revisar e enviar ao cliente em /financeiro/horas. Antes o cron do
// dia 1 enviava sozinho; o envio passou a ser decisão de quem fecha o mês.

export interface RelatorioDoCliente {
  clienteNome: string;
  para: string[];
  assunto: string;
  texto: string;
  pdf: Buffer;
  nomeArquivo: string;
}

/** Meses entre `mes` e o mês atual (0 = este mês). */
function distanciaAte(mes: string): number {
  const atual = chaveDia(new Date()).slice(0, 7);
  let n = 0;
  while (mesAnterior(atual, n) !== mes && n < 36) n++;
  return n;
}

export async function montarRelatorioDoCliente(clientId: string, mes: string): Promise<RelatorioDoCliente | null> {
  const c = await prisma.client.findUnique({
    where: { id: clientId },
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
  if (!c) return null;

  const distancia = distanciaAte(mes);
  const k = c.contrato;
  let contrato: DadosRelatorio["contrato"] = null;
  if (k?.tipo === "ams") {
    const meses = await horasPorMes(c.id, distancia + 6);
    const ate = meses.filter((m) => m.mes <= mes);
    contrato = { tipo: "ams", cicloHoras: k.cicloHoras, doMes: meses.find((m) => m.mes === mes) ?? null, historico: ate.slice(-6) };
  } else if (k?.tipo === "projeto") {
    const porEntregavel = await demandasPorEntregavel(c.id);
    const desde = k.inicioEm ? chaveDia(k.inicioEm).slice(0, 7) : mes;
    const meses = await horasPorMes(c.id, Math.max(distanciaAte(desde), distancia) + 1);
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

  // Horas que cada consultor lançou no mês, por demanda (timesheet, cronômetro
  // e card). Janela larga no banco e corte exato pelo dia de São Paulo.
  const [a, m] = mes.split("-").map(Number);
  const registros = await prisma.registroTempo.findMany({
    where: {
      demanda: { clientId: c.id },
      fimEm: { not: null },
      inicioEm: { gte: new Date(Date.UTC(a, m - 1, 1) - 86_400_000), lt: new Date(Date.UTC(a, m, 1) + 86_400_000) },
    },
    select: { autor: true, inicioEm: true, minutos: true, demanda: { select: { code: true, titulo: true } } },
  });
  const porChave = new Map<string, { consultor: string; code: string; titulo: string; minutos: number }>();
  for (const r of registros) {
    if (chaveDia(r.inicioEm).slice(0, 7) !== mes) continue;
    const chave = `${r.autor}|${r.demanda.code}`;
    const atual = porChave.get(chave) ?? { consultor: r.autor, code: r.demanda.code, titulo: r.demanda.titulo, minutos: 0 };
    atual.minutos += r.minutos ?? 0;
    porChave.set(chave, atual);
  }
  const horasPorConsultor = [...porChave.values()]
    .filter((x) => x.minutos > 0)
    .sort((x, y) => x.consultor.localeCompare(y.consultor, "pt-BR") || x.code.localeCompare(y.code, "pt-BR", { numeric: true }))
    .map((x) => ({ consultor: x.consultor, code: x.code, titulo: x.titulo, horas: x.minutos / 60 }));

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
    horasPorConsultor,
    url: `${APP_URL}/clients/${c.id}`,
  };

  // Logo da marca no PDF (PNG/JPEG; o pdfkit não lê SVG/WebP).
  const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
  const { assunto, texto } = textoDoRelatorio(dados);
  return {
    clienteNome: c.nome,
    para: c.usuarios.map((u) => u.email),
    assunto,
    texto,
    pdf: await gerarPdfRelatorio(dados, logo),
    nomeArquivo: `relatorio-${c.nome.toLowerCase().normalize("NFD").replace(/[^a-z0-9]+/g, "-")}-${mes}.pdf`,
  };
}
