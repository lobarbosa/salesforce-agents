// Estimativa de horas calibrada pelo timesheet (2026-10-17).
//
// O agente estima o esforço do consultor na análise (refinado no design) —
// mas estimativa crua de agente erra sempre para o mesmo lado até alguém
// medir. O timesheet (`RegistroTempo`) é a medida: em cada demanda entregue
// que tinha estimativa, a razão "horas lançadas ÷ ponto médio estimado" diz
// quanto a esteira subestima ou superestima. A mediana dessas razões é o
// fator que corrige a próxima estimativa.
//
// Fator do próprio cliente quando há amostra suficiente (cada org tem a sua
// dívida e o seu jeito); senão o de todos os clientes; senão 1 — e a tela diz
// qual foi usado. Preso entre 0,5 e 3: uma demanda com 0,1 h lançada (ninguém
// apontou) ou 50 h (escopo explodiu) não pode mover a régua sozinha.
//
// Puro aqui; quem busca no banco é `fatorDeCalibracao` em lib/data.ts.

export const MIN_AMOSTRAS_CALIBRACAO = 3;
const FATOR_MIN = 0.5;
const FATOR_MAX = 3;

export interface AmostraCalibracao {
  clientId: string;
  estimativaMin: number;
  estimativaMax: number;
  lancadoMin: number; // minutos fechados no timesheet
}

export interface Calibracao {
  fator: number;
  amostras: number;
  escopo: "cliente" | "geral" | "nenhum";
}

export interface EstimativaCalibrada {
  /** Faixa total (consultor calibrado + agente), em horas. */
  min: number;
  max: number;
  calibracao: Calibracao;
}

function mediana(xs: number[]): number {
  const s = [...xs].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}

function razoes(amostras: AmostraCalibracao[]): number[] {
  return amostras
    .filter((a) => a.lancadoMin > 0 && a.estimativaMax > 0)
    .map((a) => a.lancadoMin / 60 / ((a.estimativaMin + a.estimativaMax) / 2))
    .map((r) => Math.min(FATOR_MAX, Math.max(FATOR_MIN, r)));
}

export function calibracaoPara(clientId: string, amostras: AmostraCalibracao[]): Calibracao {
  const doCliente = razoes(amostras.filter((a) => a.clientId === clientId));
  if (doCliente.length >= MIN_AMOSTRAS_CALIBRACAO) {
    return { fator: mediana(doCliente), amostras: doCliente.length, escopo: "cliente" };
  }
  const todas = razoes(amostras);
  if (todas.length >= MIN_AMOSTRAS_CALIBRACAO) {
    return { fator: mediana(todas), amostras: todas.length, escopo: "geral" };
  }
  return { fator: 1, amostras: 0, escopo: "nenhum" };
}

export function estimativaCalibrada(
  d: {
    estimativaHorasMin: number | null;
    estimativaHorasMax: number | null;
    agenteHorasGasto: number | null;
    agenteHorasRestante: number | null;
  },
  calibracao: Calibracao
): EstimativaCalibrada | null {
  if (d.estimativaHorasMin === null || d.estimativaHorasMax === null) return null;
  const agente = (d.agenteHorasGasto ?? 0) + (d.agenteHorasRestante ?? 0);
  return {
    min: d.estimativaHorasMin * calibracao.fator + agente,
    max: d.estimativaHorasMax * calibracao.fator + agente,
    calibracao,
  };
}

// O cliente vê a estimativa a partir do momento em que a análise existe
// (gate da análise) — é quando ele precisa decidir se segue, antes de
// qualquer construção. Antes disso não há número que preste.
const SEM_ESTIMATIVA_PRO_CLIENTE = new Set(["backlog", "planejada", "recorrente", "standby", "analise"]);

export function clienteVeEstimativa(status: string): boolean {
  return !SEM_ESTIMATIVA_PRO_CLIENTE.has(status);
}
