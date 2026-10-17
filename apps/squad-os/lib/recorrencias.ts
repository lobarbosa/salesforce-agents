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
 * Competências cuja conta já deve existir em `hoje`: todas desde o início do
 * modelo (retroativo, decisão do CEO de 17/10/2026) até as que vencem em
 * hoje + HORIZONTE_DIAS, sem passar do fim. Cobre modelo criado com início no
 * passado, dia em que o cron não rodou e meses em que o modelo ficou pausado
 * (ao retomar, os meses pausados também saem). Modelo pausado não gera nada
 * enquanto estiver pausado — quem filtra é `aGerar`.
 */
export function competenciasDevidas(m: ModeloParaRegra, hoje: string): { competencia: string; vencimento: string }[] {
  const limite = somaDias(hoje, HORIZONTE_DIAS);
  const devidas: { competencia: string; vencimento: string }[] = [];
  for (const comp of competenciasDesde(m, m.inicioEm.slice(0, 7))) {
    const vencimento = vencimentoDa(comp, m.diaVencimento);
    if (vencimento > limite) break;
    devidas.push({ competencia: comp, vencimento });
  }
  return devidas;
}

/** Freio por modelo por passada: um início errado (ex.: 2016) não despeja 120 contas de uma vez. */
export const MAX_POR_PASSADA = 24;

/**
 * O que falta gerar: para cada modelo ativo, as competências devidas que ainda
 * não estão em `existentes` (chaves "modeloId|competencia"), da mais antiga
 * para a mais nova, no máximo MAX_POR_PASSADA por modelo — a passada seguinte
 * continua de onde esta parou (`limitados` diz quem ficou com o quê faltando).
 * Chamar de novo com o resultado somado a `existentes` não repete nada.
 */
export function aGerar<M extends ModeloParaRegra & { id: string; ativa: boolean }>(
  modelos: M[],
  existentes: Set<string>,
  hoje: string,
  maximo = MAX_POR_PASSADA
): {
  itens: { modelo: M; competencia: string; vencimento: string }[];
  limitados: { modeloId: string; faltando: number }[];
} {
  const itens: { modelo: M; competencia: string; vencimento: string }[] = [];
  const limitados: { modeloId: string; faltando: number }[] = [];
  for (const m of modelos) {
    if (!m.ativa) continue;
    const faltam = competenciasDevidas(m, hoje).filter((d) => !existentes.has(chaveOcorrencia(m.id, d.competencia)));
    for (const d of faltam.slice(0, maximo)) itens.push({ modelo: m, ...d });
    if (faltam.length > maximo) limitados.push({ modeloId: m.id, faltando: faltam.length - maximo });
  }
  return { itens, limitados };
}

export interface AvulsaCandidata {
  id: string;
  fornecedor: string;
  vencimento: string; // 'YYYY-MM-DD'
  valor: number;
  status: string;
}

/** Fornecedor comparável: sem diferença de caixa nem de espaços. */
export function normalizarFornecedor(s: string): string {
  return s.trim().replace(/\s+/g, " ").toLowerCase();
}

/**
 * Conta avulsa já lançada que É a ocorrência desta competência: mesmo
 * fornecedor (sem caixa/espaços), vencimento no mês da competência, não
 * cancelada nem recusada, ainda não usada nesta passada. Mais de uma: a de
 * valor mais próximo. Null = nenhuma; a ocorrência é criada.
 */
export function avulsaParaVincular(
  candidatas: AvulsaCandidata[],
  fornecedor: string,
  competencia: string,
  valor: number,
  usadas: Set<string> = new Set()
): string | null {
  const alvo = normalizarFornecedor(fornecedor);
  const ok = candidatas.filter(
    (c) =>
      !usadas.has(c.id) &&
      c.status !== "cancelada" &&
      c.status !== "recusada" &&
      c.vencimento.slice(0, 7) === competencia &&
      normalizarFornecedor(c.fornecedor) === alvo
  );
  if (!ok.length) return null;
  ok.sort((a, b) => Math.abs(a.valor - valor) - Math.abs(b.valor - valor));
  return ok[0].id;
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
