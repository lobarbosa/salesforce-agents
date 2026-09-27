// Rótulos e leitura dos KPIs que os agentes gravam em ops.kpi_snapshots
// (cashflow_monitor e finance_report_agent). Métrica desconhecida aparece com
// o nome cru — agente novo não some da tela por falta de rótulo aqui.

export interface DefKpi {
  rotulo: string;
  grupo: "caixa" | "resultado";
  /** true = subir é ruim (despesa, a pagar, taxa). Decide a palavra da tendência, não a cor. */
  subirEhRuim?: boolean;
  ordem: number;
}

export const KPIS: Record<string, DefKpi> = {
  caixa_30d: { rotulo: "Caixa projetado em 30 dias", grupo: "caixa", ordem: 1 },
  caixa_60d: { rotulo: "Caixa projetado em 60 dias", grupo: "caixa", ordem: 2 },
  caixa_90d: { rotulo: "Caixa projetado em 90 dias", grupo: "caixa", ordem: 3 },
  a_receber_30d: { rotulo: "A receber em 30 dias", grupo: "caixa", ordem: 4 },
  a_pagar_30d: { rotulo: "A pagar em 30 dias", grupo: "caixa", subirEhRuim: true, ordem: 5 },
  pipeline_ponderado_90d: { rotulo: "Pipeline ponderado (90 dias)", grupo: "caixa", ordem: 6 },
  a_receber_60d: { rotulo: "A receber em 60 dias", grupo: "caixa", ordem: 7 },
  a_pagar_60d: { rotulo: "A pagar em 60 dias", grupo: "caixa", subirEhRuim: true, ordem: 8 },
  a_receber_90d: { rotulo: "A receber em 90 dias", grupo: "caixa", ordem: 9 },
  a_pagar_90d: { rotulo: "A pagar em 90 dias", grupo: "caixa", subirEhRuim: true, ordem: 10 },
  receita_bruta: { rotulo: "Receita bruta", grupo: "resultado", ordem: 1 },
  receita_liquida: { rotulo: "Receita líquida", grupo: "resultado", ordem: 2 },
  taxas_asaas: { rotulo: "Taxas do Asaas", grupo: "resultado", subirEhRuim: true, ordem: 3 },
  despesas_pagas: { rotulo: "Despesas pagas", grupo: "resultado", subirEhRuim: true, ordem: 4 },
  resultado: { rotulo: "Resultado do mês", grupo: "resultado", ordem: 5 },
};

export function defKpi(metrica: string): DefKpi {
  return KPIS[metrica] ?? { rotulo: metrica.replace(/_/g, " "), grupo: "caixa", ordem: 99 };
}

/** "subiu 12% (piorou)" — tendência por texto, sem depender de cor. null sem base de comparação. */
export function tendencia(valor: number, anterior: number | null, subirEhRuim = false): string | null {
  if (anterior === null || anterior === 0) return null;
  const pct = ((valor - anterior) / Math.abs(anterior)) * 100;
  if (Math.abs(pct) < 0.5) return "estável";
  const sentido = pct > 0 ? "subiu" : "caiu";
  const bom = pct > 0 !== subirEhRuim;
  return `${sentido} ${Math.abs(pct).toLocaleString("pt-BR", { maximumFractionDigits: 0 })}% (${bom ? "melhorou" : "piorou"})`;
}
