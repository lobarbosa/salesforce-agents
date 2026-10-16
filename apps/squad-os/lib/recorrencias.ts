import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";
import { lerReais } from "@/lib/contas";

// Regras puras de despesas recorrentes — sem Prisma, sem request; testadas em
// scripts/testa-recorrencias.ts.
//
// Vocabulário:
// - competência: 'YYYY-MM', o mês a que a conta pertence. A conta gerada vence
//   no `diaVencimento` desse mês (ou no último dia, em mês mais curto).
// - modelo (DespesaRecorrente): fornecedor, valor previsto por ocorrência,
//   periodicidade e o intervalo [inicio, fim] de competências.
//
// Datas são sempre dias de São Paulo ("YYYY-MM-DD", ver chaveDia em lib/horas.ts).

export const MESES_POR_PERIODO: Record<Periodicidade, number> = {
  mensal: 1,
  trimestral: 3,
  semestral: 6,
  anual: 12,
};

export const ROTULO_PERIODICIDADE: Record<Periodicidade, string> = {
  mensal: "mensal",
  trimestral: "trimestral",
  semestral: "semestral",
  anual: "anual",
};

/** "Repetir todo mês", "todo trimestre"... — rótulo do checkbox no lançamento. */
export const ROTULO_REPETIR: Record<Periodicidade, string> = {
  mensal: "todo mês",
  trimestral: "todo trimestre",
  semestral: "todo semestre",
  anual: "todo ano",
};

export const ROTULO_NATUREZA: Record<NaturezaCusto, string> = {
  direto: "custo direto",
  fixo: "despesa fixa",
};

export const PERIODICIDADES = Object.keys(MESES_POR_PERIODO) as Periodicidade[];
export const NATUREZAS: NaturezaCusto[] = ["fixo", "direto"];

/** Quem "lança" as contas geradas. Não é pessoa: qualquer aprovador pode decidir sobre elas. */
export const EMAIL_RECORRENCIA = "recorrencia@squad-os";

/** Quantos dias antes do vencimento a conta recorrente aparece em contas a pagar. */
export const HORIZONTE_DIAS = 30;

export interface ModeloParaRegra {
  periodicidade: Periodicidade;
  diaVencimento: number;
  /** Primeira competência, "YYYY-MM-DD" (o dia é ignorado). */
  inicioEm: string;
  /** Última competência, "YYYY-MM-DD" ou null = sem fim. */
  fimEm: string | null;
  /** Dia (SP) em que o modelo foi criado. */
  criadoEm: string;
}

export function ehCompetencia(s: string): boolean {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(s);
}

export function somaMeses(competencia: string, n: number): string {
  const [a, m] = competencia.split("-").map(Number);
  const total = a * 12 + (m - 1) + n;
  return `${Math.floor(total / 12)}-${String((total % 12) + 1).padStart(2, "0")}`;
}

function mesesEntre(de: string, ate: string): number {
  const [a1, m1] = de.split("-").map(Number);
  const [a2, m2] = ate.split("-").map(Number);
  return (a2 - a1) * 12 + (m2 - m1);
}

function ultimoDia(competencia: string): number {
  const [a, m] = competencia.split("-").map(Number);
  return new Date(Date.UTC(a, m, 0)).getUTCDate();
}

/** Vencimento da competência: o dia pedido, ou o último dia do mês se ele for mais curto. */
export function vencimentoDa(competencia: string, diaVencimento: number): string {
  const dia = Math.min(diaVencimento, ultimoDia(competencia));
  return `${competencia}-${String(dia).padStart(2, "0")}`;
}

function somaDias(dia: string, n: number): string {
  const d = new Date(`${dia}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

const maior = (a: string, b: string) => (a > b ? a : b);

/** Competências do modelo (alinhadas ao início, no passo da periodicidade) a partir de `desde`. */
function* competenciasDesde(m: ModeloParaRegra, desde: string): Generator<string> {
  const inicio = m.inicioEm.slice(0, 7);
  const fim = m.fimEm?.slice(0, 7) ?? null;
  const passo = MESES_POR_PERIODO[m.periodicidade];
  const primeiro = maior(inicio, desde);
  // Primeiro múltiplo do passo, contado do início, que não fica antes de `primeiro`.
  let k = Math.ceil(mesesEntre(inicio, primeiro) / passo);
  for (;;) {
    const comp = somaMeses(inicio, k * passo);
    if (fim && comp > fim) return;
    yield comp;
    k++;
  }
}

/**
 * Competências cuja conta já deve existir em `hoje`: vencimento até
 * hoje + HORIZONTE_DIAS, dentro de [inicio, fim].
 *
 * Nunca volta para trás do mês corrente (nem do mês de criação do modelo):
 * um modelo criado ou reativado hoje com início em janeiro não despeja dez
 * contas atrasadas de uma vez. O mês corrente entra mesmo que o vencimento já
 * tenha passado — a conta deste mês existe e precisa ser paga.
 */
export function competenciasDevidas(m: ModeloParaRegra, hoje: string): { competencia: string; vencimento: string }[] {
  const piso = maior(m.criadoEm.slice(0, 7), hoje.slice(0, 7));
  const limite = somaDias(hoje, HORIZONTE_DIAS);
  const devidas: { competencia: string; vencimento: string }[] = [];
  for (const comp of competenciasDesde(m, piso)) {
    const vencimento = vencimentoDa(comp, m.diaVencimento);
    if (vencimento > limite) break;
    devidas.push({ competencia: comp, vencimento });
  }
  return devidas;
}

/**
 * O que falta gerar: para cada modelo ativo, as competências devidas que ainda
 * não estão em `existentes` (chaves "modeloId|competencia"). Chamar de novo com
 * o resultado somado a `existentes` devolve vazio — a geração é idempotente.
 */
export function aGerar<M extends ModeloParaRegra & { id: string; ativa: boolean }>(
  modelos: M[],
  existentes: Set<string>,
  hoje: string
): { modelo: M; competencia: string; vencimento: string }[] {
  const r: { modelo: M; competencia: string; vencimento: string }[] = [];
  for (const m of modelos) {
    if (!m.ativa) continue;
    for (const d of competenciasDevidas(m, hoje)) {
      if (!existentes.has(chaveOcorrencia(m.id, d.competencia))) r.push({ modelo: m, ...d });
    }
  }
  return r;
}

export function chaveOcorrencia(modeloId: string, competencia: string): string {
  return `${modeloId}|${competencia}`;
}

/** A próxima competência com vencimento a partir de hoje, ou null se o modelo já terminou. */
export function proximaCompetencia(m: ModeloParaRegra, hoje: string): { competencia: string; vencimento: string } | null {
  for (const comp of competenciasDesde(m, hoje.slice(0, 7))) {
    const vencimento = vencimentoDa(comp, m.diaVencimento);
    if (vencimento >= hoje) return { competencia: comp, vencimento };
  }
  return null;
}

/** Valor por ocorrência levado a mês (trimestral/3, semestral/6, anual/12), em centavos inteiros. */
export function equivalenteMensal(valor: number, periodicidade: Periodicidade): number {
  return Math.round((valor / MESES_POR_PERIODO[periodicidade]) * 100) / 100;
}

/** Encerrado = a última competência já passou. */
export function encerrado(fimEm: string | null, hoje: string): boolean {
  return fimEm !== null && fimEm.slice(0, 7) < hoje.slice(0, 7);
}

export interface ModeloParaCompromisso {
  valor: number;
  periodicidade: Periodicidade;
  natureza: NaturezaCusto;
  ativa: boolean;
  /** Última competência ('YYYY-MM' ou data) ou null = sem fim. */
  fim: string | null;
}

/** Compromisso mensal recorrente: soma dos modelos ativos e não encerrados, normalizada para mês. */
export function compromissoMensal(
  modelos: ModeloParaCompromisso[],
  hoje: string
): { total: number; fixo: number; direto: number; quantidade: number } {
  let fixo = 0;
  let direto = 0;
  let quantidade = 0;
  for (const m of modelos) {
    if (!m.ativa || encerrado(m.fim, hoje)) continue;
    const mensal = equivalenteMensal(m.valor, m.periodicidade);
    if (m.natureza === "direto") direto += mensal;
    else fixo += mensal;
    quantidade++;
  }
  const r = (v: number) => Math.round(v * 100) / 100;
  return { total: r(fixo + direto), fixo: r(fixo), direto: r(direto), quantidade };
}

export interface DadosModelo {
  fornecedor: string;
  descricao: string;
  categoria: string;
  valor: number;
  valorVariavel: boolean;
  periodicidade: Periodicidade;
  diaVencimento: number;
  inicio: string; // 'YYYY-MM'
  fim: string | null; // 'YYYY-MM'
  natureza: NaturezaCusto;
  clientId: string | null;
}

/**
 * Valida o corpo de criação/edição de um modelo. `parcial` = edição (só valida
 * o que veio). Devolve os campos normalizados ou o erro pronto para a tela.
 */
export function validarModelo(
  corpo: Record<string, unknown>,
  parcial = false
): { dados: Partial<DadosModelo>; erro?: never } | { erro: string; dados?: never } {
  const tem = (k: string) => corpo[k] !== undefined;
  const texto = (k: string, max: number) => String(corpo[k] ?? "").trim().slice(0, max);
  const dados: Partial<DadosModelo> = {};

  if (!parcial || tem("fornecedor")) {
    dados.fornecedor = texto("fornecedor", 200);
    if (!dados.fornecedor) return { erro: "informe o fornecedor" };
  }
  if (tem("descricao")) dados.descricao = texto("descricao", 500);
  if (tem("categoria")) dados.categoria = texto("categoria", 80);
  if (!parcial || tem("valor")) {
    const v = typeof corpo.valor === "number" ? corpo.valor : lerReais(String(corpo.valor ?? ""));
    if (v === null || !Number.isFinite(v) || v <= 0) return { erro: "valor inválido — use 1.234,56" };
    dados.valor = Math.round(v * 100) / 100;
  }
  if (tem("valorVariavel")) dados.valorVariavel = corpo.valorVariavel === true || corpo.valorVariavel === "on";
  if (!parcial || tem("periodicidade")) {
    const p = String(corpo.periodicidade ?? "mensal") as Periodicidade;
    if (!PERIODICIDADES.includes(p)) return { erro: "periodicidade inválida" };
    dados.periodicidade = p;
  }
  if (!parcial || tem("diaVencimento")) {
    const d = Number(corpo.diaVencimento);
    if (!Number.isInteger(d) || d < 1 || d > 31) return { erro: "dia de vencimento deve ser de 1 a 31" };
    dados.diaVencimento = d;
  }
  if (!parcial || tem("inicio")) {
    const i = texto("inicio", 7);
    if (!ehCompetencia(i)) return { erro: "informe a primeira competência (mês/ano)" };
    dados.inicio = i;
  }
  if (tem("fim")) {
    const f = texto("fim", 7);
    if (f && !ehCompetencia(f)) return { erro: "última competência inválida" };
    dados.fim = f || null;
  }
  if (dados.inicio && dados.fim && dados.fim < dados.inicio) {
    return { erro: "a última competência não pode ser antes da primeira" };
  }
  if (!parcial || tem("natureza")) {
    const n = String(corpo.natureza ?? "") as NaturezaCusto;
    if (!NATUREZAS.includes(n)) return { erro: "escolha a natureza: custo direto ou despesa fixa" };
    dados.natureza = n;
  }
  if (tem("clientId")) dados.clientId = texto("clientId", 60) || null;
  return { dados };
}

/** "2026-10" → "out/2026". */
export function rotuloCompetencia(competencia: string): string {
  const meses = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];
  return `${meses[Number(competencia.slice(5, 7)) - 1]}/${competencia.slice(0, 4)}`;
}
