// Margem de contribuição por contrato e mês. O cálculo é da view
// `ops.margem_contratos` (konecta-agents, migration 20261020120000): aqui só
// se lê e agrupa. Margem nula = falta receita ou custo direto no mês, e a
// `situacao` diz qual — nunca vira 100% por falta de custo.

export interface MargemMes {
  clientId: string;
  cliente: string;
  mes: string; // YYYY-MM
  receita: number;
  custoDireto: number;
  margem: number | null;
  margemPct: number | null; // 0–1
  horas: number;
  horasContratadas: number | null;
  contrato: string | null;
  receitaHora: number | null;
  custoHora: number | null;
  notas: string;
  situacao: string;
}

export interface MargemContrato {
  clientId: string;
  cliente: string;
  linhas: MargemMes[];
  /** Último mês que tem margem (receita e custo); null se nenhum tem. */
  ultima: MargemMes | null;
}

const numero = (v: unknown) => (v === null || v === undefined ? null : Number(v));

export function normalizarMargem(r: Record<string, unknown>): MargemMes {
  return {
    clientId: String(r.client_id),
    cliente: String(r.cliente),
    mes: String(r.mes),
    receita: numero(r.receita) ?? 0,
    custoDireto: numero(r.custo_direto) ?? 0,
    margem: numero(r.margem),
    margemPct: numero(r.margem_pct),
    horas: numero(r.horas) ?? 0,
    horasContratadas: numero(r.horas_contratadas),
    contrato: r.contrato == null ? null : String(r.contrato),
    receitaHora: numero(r.receita_hora),
    custoHora: numero(r.custo_hora),
    notas: r.notas == null ? "" : String(r.notas),
    situacao: String(r.situacao ?? ""),
  };
}

/** Linhas da view agrupadas por contrato, meses em ordem, contratos por nome. */
export function porContrato(linhas: MargemMes[]): MargemContrato[] {
  const grupos = new Map<string, MargemMes[]>();
  for (const l of linhas) grupos.set(l.clientId, [...(grupos.get(l.clientId) ?? []), l]);
  return [...grupos.values()]
    .map((ls) => {
      const ordenadas = [...ls].sort((a, b) => a.mes.localeCompare(b.mes));
      const comMargem = ordenadas.filter((l) => l.margem !== null);
      return {
        clientId: ordenadas[0].clientId,
        cliente: ordenadas[0].cliente,
        linhas: ordenadas,
        ultima: comMargem.at(-1) ?? null,
      };
    })
    .sort((a, b) => a.cliente.localeCompare(b.cliente, "pt-BR"));
}

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

/** "2026-09" → "set/26". */
export function rotuloMesCurto(chave: string): string {
  const [ano, mes] = chave.split("-");
  return `${MESES[Number(mes) - 1] ?? mes}/${ano.slice(2)}`;
}

/** 0.0657 → "6,6%"; null → "—". */
export function formatarPct(v: number | null): string {
  if (v === null) return "—";
  return `${(v * 100).toLocaleString("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 1 })}%`;
}
