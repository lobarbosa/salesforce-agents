import { prisma } from "@/lib/prisma";
import {
  ancoraDoDia,
  chaveDia,
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
