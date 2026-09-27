import { prisma } from "@/lib/prisma";
import {
  ancoraDoDia,
  chaveDia,
  cicloDoMes,
  situacaoConsumo,
  type SituacaoConsumo,
  diasDaSemana,
  FUSO,
  intervaloDaSemana,
  parcelaDaGrade,
  semanaAnterior,
} from "@/lib/horas";

export interface DemandaDaGrade {
  id: string;
  clientId: string;
  code: string;
  titulo: string;
  clientNome: string;
}

export interface LinhaDaGrade {
  demanda: DemandaDaGrade;
  /** Total fechado por dia ("YYYY-MM-DD" → minutos), somando todas as origens. */
  minutos: Record<string, number>;
  /** Parte que NÃO veio da grade (cronômetro/manual) — a grade não pode ficar abaixo disso. */
  foraDaGrade: Record<string, number>;
}

export interface SemanaDeHoras {
  segunda: string;
  dias: string[];
  linhas: LinhaDaGrade[];
  /** Demandas que dá para adicionar como linha (não entregues), para o seletor. */
  opcoes: DemandaDaGrade[];
  rodando: { demanda: DemandaDaGrade; desde: string } | null;
}

function paraGrade(d: {
  id: string;
  clientId: string;
  code: string;
  titulo: string;
  client: { nome: string };
}): DemandaDaGrade {
  return { id: d.id, clientId: d.clientId, code: d.code, titulo: d.titulo, clientNome: d.client.nome };
}

const SELECAO_DEMANDA = {
  id: true,
  clientId: true,
  code: true,
  titulo: true,
  client: { select: { nome: true } },
} as const;

/**
 * A semana de uma pessoa na grade. Linhas = demandas com hora nesta semana
 * + demandas em que ela lançou nas duas semanas anteriores (com zero), para
 * que a semana nova já comece com as linhas de sempre — o padrão do Clockify
 * e do Tempo, e a regra "não fazer redigitar" da skill de UX.
 */
export async function minhaSemana(email: string, segunda: string): Promise<SemanaDeHoras> {
  const dias = diasDaSemana(segunda);
  const { desde, ate } = intervaloDaSemana(segunda);
  const desdeRecentes = intervaloDaSemana(semanaAnterior(semanaAnterior(segunda))).desde;

  const [daSemana, recentes, abertas, rodando] = await Promise.all([
    prisma.registroTempo.findMany({
      where: { autorEmail: email, fimEm: { not: null }, inicioEm: { gte: desde, lt: ate } },
      select: { inicioEm: true, minutos: true, origem: true, demanda: { select: SELECAO_DEMANDA } },
    }),
    prisma.registroTempo.findMany({
      where: { autorEmail: email, fimEm: { not: null }, inicioEm: { gte: desdeRecentes, lt: desde } },
      distinct: ["demandaId"],
      select: { demanda: { select: SELECAO_DEMANDA } },
    }),
    prisma.demanda.findMany({
      where: { status: { not: "entregue" } },
      select: SELECAO_DEMANDA,
      orderBy: [{ client: { nome: "asc" } }, { criadoEm: "desc" }],
    }),
    prisma.registroTempo.findFirst({
      where: { autorEmail: email, fimEm: null },
      select: { inicioEm: true, demanda: { select: SELECAO_DEMANDA } },
    }),
  ]);

  const linhas = new Map<string, LinhaDaGrade>();
  const linha = (d: DemandaDaGrade) => {
    let l = linhas.get(d.id);
    if (!l) {
      l = { demanda: d, minutos: {}, foraDaGrade: {} };
      linhas.set(d.id, l);
    }
    return l;
  };

  for (const r of daSemana) {
    const l = linha(paraGrade(r.demanda));
    const dia = chaveDia(r.inicioEm);
    l.minutos[dia] = (l.minutos[dia] ?? 0) + (r.minutos ?? 0);
    if (r.origem !== "grade") l.foraDaGrade[dia] = (l.foraDaGrade[dia] ?? 0) + (r.minutos ?? 0);
  }
  for (const r of recentes) linha(paraGrade(r.demanda));

  const ordenadas = [...linhas.values()].sort(
    (a, b) =>
      a.demanda.clientNome.localeCompare(b.demanda.clientNome, "pt-BR") ||
      a.demanda.code.localeCompare(b.demanda.code, "pt-BR", { numeric: true })
  );

  return {
    segunda,
    dias,
    linhas: ordenadas,
    opcoes: abertas.map(paraGrade),
    rodando: rodando ? { demanda: paraGrade(rodando.demanda), desde: rodando.inicioEm.toISOString() } : null,
  };
}

/**
 * Grava uma célula da grade: o total do dia passa a ser `minutos`. Só mexe na
 * linha `origem = "grade"` daquela pessoa+demanda+dia; cronômetro e lançamento
 * manual ficam intactos. Se o alvo for menor do que já existe fora da grade,
 * não grava e devolve o mínimo (a correção é no card da demanda).
 */
export async function gravarCelula(p: {
  demandaId: string;
  dia: string;
  minutos: number;
  autor: string;
  autorEmail: string;
}): Promise<{ total: number } | { conflito: number }> {
  const inicio = new Date(`${p.dia}T00:00:00${FUSO}`);
  const fim = new Date(inicio.getTime() + 24 * 60 * 60_000);

  return prisma.$transaction(async (tx) => {
    const doDia = await tx.registroTempo.findMany({
      where: {
        demandaId: p.demandaId,
        autorEmail: p.autorEmail,
        fimEm: { not: null },
        inicioEm: { gte: inicio, lt: fim },
      },
      select: { id: true, minutos: true, origem: true },
    });
    const daGrade = doDia.filter((r) => r.origem === "grade");
    const fora = doDia.filter((r) => r.origem !== "grade").reduce((s, r) => s + (r.minutos ?? 0), 0);
    const parcela = parcelaDaGrade(p.minutos, fora);
    if (parcela < 0) return { conflito: fora };

    // Mais de uma linha de grade no mesmo dia só acontece por corrida entre
    // duas abas; consolida numa só.
    if (daGrade.length > 0) {
      await tx.registroTempo.deleteMany({ where: { id: { in: daGrade.map((r) => r.id) } } });
    }
    if (parcela > 0) {
      const ancora = ancoraDoDia(p.dia);
      await tx.registroTempo.create({
        data: {
          demandaId: p.demandaId,
          autor: p.autor,
          autorEmail: p.autorEmail,
          descricao: "",
          inicioEm: ancora,
          fimEm: new Date(ancora.getTime() + parcela * 60_000),
          minutos: parcela,
          origem: "grade",
        },
      });
    }
    return { total: p.minutos };
  });
}

// ── Horas por cliente ───────────────────────────────────────────────────────


export interface HorasDoCliente {
  clientId: string;
  clientNome: string;
  tipo: "ams" | "projeto" | null;
  horasContratadas: number;
  ciclo: string;
  rotuloCiclo: string;
  /** Minutos no ciclo do contrato (AMS) ou no mês (projeto / sem contrato). */
  minutos: number;
  situacao: SituacaoConsumo;
  porPessoa: { autor: string; minutos: number }[];
  porDemanda: { code: string; titulo: string; minutos: number }[];
}

/**
 * Consumido × contratado por cliente, no mês escolhido — o relatório "Summary"
 * do Clockify, agrupado por cliente e aberto por pessoa e por demanda.
 * AMS usa o ciclo do contrato (mensal ou trimestral que contém o mês); projeto
 * e cliente sem contrato mostram as horas do mês, sem teto (projeto se mede
 * por entregável, na aba Contrato).
 */
export async function horasPorCliente(mes: string): Promise<HorasDoCliente[]> {
  const clientes = await prisma.client.findMany({
    select: {
      id: true,
      nome: true,
      contrato: { select: { tipo: true, horasContratadas: true, cicloHoras: true } },
    },
    orderBy: { nome: "asc" },
  });

  const resultado: HorasDoCliente[] = [];
  for (const c of clientes) {
    const ams = c.contrato?.tipo === "ams";
    const ciclo = ams ? c.contrato!.cicloHoras : "mensal";
    const janela = cicloDoMes(mes, ciclo);
    const registros = await prisma.registroTempo.findMany({
      where: {
        demanda: { clientId: c.id },
        fimEm: { not: null },
        inicioEm: { gte: janela.desde, lt: janela.ate },
      },
      select: { autor: true, minutos: true, demanda: { select: { code: true, titulo: true } } },
    });

    const pessoas = new Map<string, number>();
    const demandas = new Map<string, { code: string; titulo: string; minutos: number }>();
    let total = 0;
    for (const r of registros) {
      const m = r.minutos ?? 0;
      total += m;
      pessoas.set(r.autor, (pessoas.get(r.autor) ?? 0) + m);
      const d = demandas.get(r.demanda.code) ?? { ...r.demanda, minutos: 0 };
      d.minutos += m;
      demandas.set(r.demanda.code, d);
    }
    const contratadas = ams ? c.contrato!.horasContratadas : 0;
    resultado.push({
      clientId: c.id,
      clientNome: c.nome,
      tipo: c.contrato?.tipo ?? null,
      horasContratadas: contratadas,
      ciclo,
      rotuloCiclo: janela.rotulo,
      minutos: total,
      situacao: situacaoConsumo(total, contratadas),
      porPessoa: [...pessoas.entries()].map(([autor, minutos]) => ({ autor, minutos })).sort((a, b) => b.minutos - a.minutos),
      porDemanda: [...demandas.values()].sort((a, b) => b.minutos - a.minutos),
    });
  }
  // Quem pede atenção primeiro: estourado, atenção, dentro, sem teto; depois por horas.
  const ordem: Record<SituacaoConsumo, number> = { estourado: 0, atencao: 1, dentro: 2, sem_teto: 3 };
  return resultado.sort((a, b) => ordem[a.situacao] - ordem[b.situacao] || b.minutos - a.minutos);
}

/** Minutos lançados pela pessoa na semana corrente (para o Início). */
export async function minutosDaSemana(email: string, segunda: string): Promise<number> {
  const { desde, ate } = intervaloDaSemana(segunda);
  const r = await prisma.registroTempo.aggregate({
    where: { autorEmail: email, fimEm: { not: null }, inicioEm: { gte: desde, lt: ate } },
    _sum: { minutos: true },
  });
  return r._sum.minutos ?? 0;
}
