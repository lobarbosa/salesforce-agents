// Regras puras do timesheet (tela "Minhas horas") — sem Prisma, sem request,
// testadas em scripts/testa-horas.ts.
//
// Dia e semana são sempre os de São Paulo. O Brasil não tem horário de verão
// desde 2019, então o fuso é um deslocamento fixo de -03:00; usar o fuso do
// servidor (UTC na Vercel) jogaria o trabalho das 21h de segunda para terça.

export const FUSO = "-03:00";
const OFFSET_MS = 3 * 60 * 60_000;

/** Um lançamento na grade cobre no máximo um dia — o mesmo teto do lançamento manual. */
export const MINUTOS_MAX_DIA = 24 * 60;

export const DIAS_SEMANA = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"] as const;

/** "YYYY-MM-DD" do dia em São Paulo em que o instante cai. */
export function chaveDia(instante: Date): string {
  return new Date(instante.getTime() - OFFSET_MS).toISOString().slice(0, 10);
}

export function ehChaveDia(s: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}

function somaDias(dia: string, n: number): string {
  const d = new Date(`${dia}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/** Segunda-feira da semana do dia (semana de segunda a domingo, como no Clockify). */
export function inicioDaSemana(dia: string): string {
  const d = new Date(`${dia}T00:00:00Z`);
  const desdeSegunda = (d.getUTCDay() + 6) % 7;
  return somaDias(dia, -desdeSegunda);
}

export function diasDaSemana(segunda: string): string[] {
  return Array.from({ length: 7 }, (_, i) => somaDias(segunda, i));
}

export function semanaAnterior(segunda: string): string {
  return somaDias(segunda, -7);
}

export function proximaSemana(segunda: string): string {
  return somaDias(segunda, 7);
}

/** Início (inclusivo) e fim (exclusivo) da semana, em instantes absolutos. */
export function intervaloDaSemana(segunda: string): { desde: Date; ate: Date } {
  return {
    desde: new Date(`${segunda}T00:00:00${FUSO}`),
    ate: new Date(`${proximaSemana(segunda)}T00:00:00${FUSO}`),
  };
}

/** Meio-dia do dia em São Paulo: âncora do lançamento feito pela grade, longe da virada do dia. */
export function ancoraDoDia(dia: string): Date {
  return new Date(`${dia}T12:00:00${FUSO}`);
}

/**
 * Lê o que a pessoa digita numa célula. Aceita os formatos que timesheets
 * consagrados aceitam: "1:30", "1,5", "1.5", "1h30", "2h", "90m", "45min".
 * Número puro é hora ("2" = 2h), como no Clockify e no Tempo.
 * Vazio é zero (apagar a célula). Qualquer outra coisa devolve null.
 */
export function lerDuracao(entrada: string): number | null {
  const s = entrada.trim().toLowerCase().replace(/\s+/g, "");
  if (s === "") return 0;

  let m = s.match(/^(\d{1,2}):([0-5]\d)$/);
  if (m) return Number(m[1]) * 60 + Number(m[2]);

  m = s.match(/^(\d{1,2})h(?:([0-5]?\d)(?:m|min)?)?$/);
  if (m) return Number(m[1]) * 60 + Number(m[2] ?? 0);

  m = s.match(/^(\d{1,4})(?:m|min)$/);
  if (m) return Number(m[1]);

  m = s.match(/^(\d{1,2})(?:[.,](\d{1,2}))?$/);
  if (m) {
    const horas = Number(`${m[1]}.${m[2] ?? "0"}`);
    return Math.round(horas * 60);
  }
  return null;
}

/** 90 → "1:30"; 0 → "". A grade mostra h:mm porque é como a pessoa confere o dia. */
export function formatarDuracao(minutos: number): string {
  if (!minutos) return "";
  const h = Math.floor(minutos / 60);
  const m = minutos % 60;
  return `${h}:${String(m).padStart(2, "0")}`;
}

/** Total por extenso para leitores de tela e resumos: 90 → "1 hora e 30 minutos". */
export function duracaoPorExtenso(minutos: number): string {
  const h = Math.floor(minutos / 60);
  const m = minutos % 60;
  const partes = [];
  if (h) partes.push(`${h} hora${h > 1 ? "s" : ""}`);
  if (m) partes.push(`${m} minuto${m > 1 ? "s" : ""}`);
  return partes.length ? partes.join(" e ") : "nenhuma hora";
}

/**
 * Quanto o lançamento da grade precisa valer para a célula mostrar `alvo`,
 * dado o que já existe no dia por cronômetro ou lançamento manual (que a grade
 * não apaga — só a própria parcela dela). Negativo = impossível pela grade.
 */
export function parcelaDaGrade(alvo: number, outrosLancamentos: number): number {
  return alvo - outrosLancamentos;
}

/** Rótulo curto de dia: "2026-09-28" → "28/09". */
export function rotuloDia(dia: string): string {
  return `${dia.slice(8, 10)}/${dia.slice(5, 7)}`;
}

// ── Horas por cliente (relatório do financeiro) ─────────────────────────────

/** "YYYY-MM" válido. */
export function ehChaveMes(s: string): boolean {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(s);
}

/** Início e fim (exclusivo) do ciclo do contrato que contém o mês, em instantes de SP. */
export function cicloDoMes(mes: string, ciclo: string): { desde: Date; ate: Date; rotulo: string } {
  const [ano, m] = mes.split("-").map(Number);
  const trimestral = ciclo.trim().toLowerCase() === "trimestral";
  const mesInicio = trimestral ? Math.floor((m - 1) / 3) * 3 + 1 : m;
  const meses = trimestral ? 3 : 1;
  const fimAno = mesInicio + meses > 12 ? ano + 1 : ano;
  const fimMes = ((mesInicio + meses - 1) % 12) + 1;
  const p = (n: number) => String(n).padStart(2, "0");
  return {
    desde: new Date(`${ano}-${p(mesInicio)}-01T00:00:00${FUSO}`),
    ate: new Date(`${fimAno}-${p(fimMes)}-01T00:00:00${FUSO}`),
    rotulo: trimestral ? `${Math.floor((m - 1) / 3) + 1}º tri/${ano}` : `${p(m)}/${ano}`,
  };
}

export type SituacaoConsumo = "sem_teto" | "dentro" | "atencao" | "estourado";

/** Mesma régua do alerta de orçamento dos agentes: 80% acende atenção. */
export function situacaoConsumo(minutosConsumidos: number, horasContratadas: number): SituacaoConsumo {
  if (!horasContratadas) return "sem_teto";
  const pct = minutosConsumidos / 60 / horasContratadas;
  if (pct > 1) return "estourado";
  if (pct >= 0.8) return "atencao";
  return "dentro";
}
