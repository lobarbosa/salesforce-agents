// Espelho de horas para o cliente (2026-11-11): regras puras — sem Prisma, sem
// request, testadas em scripts/testa-espelho-horas.ts.
//
// É o "Weekly report" do Clockify que o financeiro mandava aos clientes de
// alocação: uma tabela por semana (segunda a domingo), uma linha por demanda
// com os consultores embaixo e o total de cada dia. O PDF sai de
// lib/espelho-horas-pdf.ts; aqui só se monta o que ele desenha.

import { chaveDia, diasDaSemana, ehChaveDia, inicioDaSemana, proximaSemana } from "@/lib/horas";

/** Um período maior que isso vira dezenas de páginas e não é um espelho: use o relatório mensal. */
export const DIAS_MAX_ESPELHO = 93;

export interface RegistroDoEspelho {
  autor: string;
  inicioEm: Date;
  minutos: number | null;
  demanda: { code: string; titulo: string };
}

export interface LinhaConsultor {
  consultor: string;
  /** "YYYY-MM-DD" → minutos. Só dias com lançamento. */
  porDia: Record<string, number>;
  total: number;
}

export interface LinhaDemanda {
  code: string;
  titulo: string;
  porDia: Record<string, number>;
  total: number;
  consultores: LinhaConsultor[];
}

export interface SemanaDoEspelho {
  /** Os 7 dias, de segunda a domingo. */
  dias: string[];
  /** Dias da semana que caem fora do período pedido (pontas da primeira e da última semana). */
  fora: string[];
  demandas: LinhaDemanda[];
  porDia: Record<string, number>;
  total: number;
}

export interface Espelho {
  desde: string;
  ate: string;
  semanas: SemanaDoEspelho[];
  /** Período inteiro, por demanda e consultor — a última tabela do PDF. */
  resumo: { code: string; titulo: string; consultor: string; minutos: number }[];
  porConsultor: { consultor: string; minutos: number }[];
  total: number;
}

function diasEntre(desde: string, ate: string): number {
  return Math.round((Date.parse(`${ate}T00:00:00Z`) - Date.parse(`${desde}T00:00:00Z`)) / 86_400_000);
}

/** Devolve o motivo da recusa, ou null se o período serve. `hoje` = dia de São Paulo. */
export function erroDoPeriodo(desde: string | null, ate: string | null, hoje: string): string | null {
  if (!desde || !ate || !ehChaveDia(desde) || !ehChaveDia(ate)) return "informe as duas datas do período";
  if (desde > ate) return "a data inicial é depois da final";
  if (desde > hoje) return "o período ainda não começou";
  if (diasEntre(desde, ate) + 1 > DIAS_MAX_ESPELHO) {
    return `período maior que ${DIAS_MAX_ESPELHO} dias — gere um espelho por mês ou por trimestre`;
  }
  return null;
}

const porNome = (a: string, b: string) => a.localeCompare(b, "pt-BR", { numeric: true });

/**
 * Monta o espelho do período [desde, ate] (inclusivo, dias de São Paulo).
 * Registro fora do período ou sem duração é ignorado; semana sem lançamento
 * não aparece.
 */
export function montarEspelho(registros: RegistroDoEspelho[], desde: string, ate: string): Espelho {
  // semana → demanda → consultor → dia → minutos
  type Celulas = Map<string, Map<string, Map<string, number>>>;
  const semanas = new Map<string, Celulas>();
  const titulos = new Map<string, string>();
  const resumo = new Map<string, { code: string; titulo: string; consultor: string; minutos: number }>();
  const porConsultor = new Map<string, number>();
  let total = 0;

  for (const r of registros) {
    const min = r.minutos ?? 0;
    if (min <= 0) continue;
    const dia = chaveDia(r.inicioEm);
    if (dia < desde || dia > ate) continue;
    const consultor = r.autor.trim() || "(sem nome)";
    const code = r.demanda.code;
    titulos.set(code, r.demanda.titulo);

    const segunda = inicioDaSemana(dia);
    const demandas: Celulas = semanas.get(segunda) ?? new Map();
    semanas.set(segunda, demandas);
    const consultores = demandas.get(code) ?? new Map<string, Map<string, number>>();
    demandas.set(code, consultores);
    const dias = consultores.get(consultor) ?? new Map<string, number>();
    consultores.set(consultor, dias);
    dias.set(dia, (dias.get(dia) ?? 0) + min);

    const chave = `${code}|${consultor}`;
    const linha = resumo.get(chave) ?? { code, titulo: r.demanda.titulo, consultor, minutos: 0 };
    linha.minutos += min;
    resumo.set(chave, linha);
    porConsultor.set(consultor, (porConsultor.get(consultor) ?? 0) + min);
    total += min;
  }

  const soma = (alvo: Record<string, number>, dia: string, min: number) => {
    alvo[dia] = (alvo[dia] ?? 0) + min;
  };

  const lista: SemanaDoEspelho[] = [...semanas.keys()].sort().map((segunda) => {
    const dias = diasDaSemana(segunda);
    const porDia: Record<string, number> = {};
    let totalSemana = 0;
    const demandas: LinhaDemanda[] = [...semanas.get(segunda)!.entries()]
      .sort(([a], [b]) => porNome(a, b))
      .map(([code, consultores]) => {
        const demanda: LinhaDemanda = { code, titulo: titulos.get(code) ?? "", porDia: {}, total: 0, consultores: [] };
        for (const [consultor, celulas] of [...consultores.entries()].sort(([a], [b]) => porNome(a, b))) {
          const linha: LinhaConsultor = { consultor, porDia: {}, total: 0 };
          for (const [dia, min] of celulas) {
            linha.porDia[dia] = min;
            linha.total += min;
            soma(demanda.porDia, dia, min);
            soma(porDia, dia, min);
          }
          demanda.total += linha.total;
          demanda.consultores.push(linha);
        }
        totalSemana += demanda.total;
        return demanda;
      });
    return { dias, fora: dias.filter((d) => d < desde || d > ate), demandas, porDia, total: totalSemana };
  });

  return {
    desde,
    ate,
    semanas: lista,
    resumo: [...resumo.values()].sort((a, b) => porNome(a.code, b.code) || porNome(a.consultor, b.consultor)),
    porConsultor: [...porConsultor.entries()]
      .map(([consultor, minutos]) => ({ consultor, minutos }))
      .sort((a, b) => b.minutos - a.minutos || porNome(a.consultor, b.consultor)),
    total,
  };
}

/** 480 → "8:00"; 0 → "0:00". No espelho o zero aparece (no total), diferente da grade. */
export function horasDoEspelho(minutos: number): string {
  const h = Math.floor(minutos / 60);
  return `${h}:${String(minutos % 60).padStart(2, "0")}`;
}

/** "2026-09-28" → "28/09/2026". */
export function dataBr(dia: string): string {
  return dia.split("-").reverse().join("/");
}

/** Janela larga para a consulta ao banco (um dia de folga de cada lado); o corte exato é pelo dia de São Paulo. */
export function janelaDaConsulta(desde: string, ate: string): { gte: Date; lt: Date } {
  return {
    gte: new Date(Date.parse(`${desde}T00:00:00Z`) - 86_400_000),
    lt: new Date(Date.parse(`${ate}T00:00:00Z`) + 2 * 86_400_000),
  };
}

/** Nome de arquivo sem acento nem espaço: "espelho-horas-gauge-2026-09-28-a-2026-10-04.pdf". */
export function nomeDoArquivo(cliente: string, desde: string, ate: string, consultor?: string): string {
  const limpo = (s: string) =>
    s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const partes = ["espelho-horas", limpo(cliente), consultor ? limpo(consultor) : "", desde, "a", ate].filter(Boolean);
  return `${partes.join("-")}.pdf`;
}

/** Semana passada inteira (segunda a domingo) em relação a `hoje` — o padrão do formulário. */
export function semanaPassada(hoje: string): { desde: string; ate: string } {
  const estaSegunda = inicioDaSemana(hoje);
  const desde = diasDaSemana(estaSegunda).at(0)!;
  const anterior = new Date(Date.parse(`${desde}T00:00:00Z`) - 7 * 86_400_000).toISOString().slice(0, 10);
  const fim = new Date(Date.parse(`${proximaSemana(anterior)}T00:00:00Z`) - 86_400_000).toISOString().slice(0, 10);
  return { desde: anterior, ate: fim };
}
