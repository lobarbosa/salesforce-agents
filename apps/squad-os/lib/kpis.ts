// Rótulos e leitura dos KPIs que os agentes gravam em ops.kpi_snapshots
// (cashflow_monitor e finance_report_agent). Métrica desconhecida aparece com
// o nome cru — agente novo não some da tela por falta de rótulo aqui.

export interface DefKpi {
  rotulo: string;
  /** "oculto": vai para o copiloto com rótulo, mas não vira cartão no painel (número parcial ou de apoio). */
  grupo: "caixa" | "resultado" | "oculto";
  /** Métrica mensal (referência = dia 1 do mês): o cartão mostra "set/2026", não "01/09/2026". */
  mensal?: boolean;
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
  // Resultado do último mês fechado. Com o Asaas parcial, a receita vem das NFS-e (finance_report_agent) e
  // "resultado" é o da contabilidade (inclui pró-labore e impostos fora de contas a pagar); o gerencial
  // (receita − despesas pagas) fica ao lado, rotulado, para os cartões fecharem a conta entre si.
  receita_bruta: { rotulo: "Receita bruta (NFS-e)", grupo: "resultado", mensal: true, ordem: 1 },
  deducoes_receita: { rotulo: "(−) Simples Nacional", grupo: "resultado", mensal: true, subirEhRuim: true, ordem: 2 },
  receita_liquida: { rotulo: "Receita líquida", grupo: "resultado", mensal: true, ordem: 3 },
  despesas_pagas: { rotulo: "Despesas pagas no mês", grupo: "resultado", mensal: true, subirEhRuim: true, ordem: 4 },
  resultado_gerencial: { rotulo: "Resultado gerencial (faturado − pago)", grupo: "resultado", mensal: true, ordem: 5 },
  resultado: { rotulo: "Resultado do mês (contábil)", grupo: "resultado", mensal: true, ordem: 6 },
  // Apoio e números do Asaas, que hoje cobre só parte do faturamento: o copiloto vê, o painel não mostra
  // (um "Taxas do Asaas R$ 0,00" ao lado da receita das NFS-e só confunde).
  receita_nfse: { rotulo: "Receita faturada (NFS-e)", grupo: "oculto", mensal: true, ordem: 90 },
  faturamento_nfse_mes: { rotulo: "Faturado no mês corrente (NFS-e)", grupo: "oculto", mensal: true, ordem: 91 },
  receita_contabil: { rotulo: "Receita contábil", grupo: "oculto", mensal: true, ordem: 92 },
  despesas_contabeis: { rotulo: "Despesas contábeis", grupo: "oculto", mensal: true, subirEhRuim: true, ordem: 93 },
  resultado_contabil: { rotulo: "Resultado contábil", grupo: "oculto", mensal: true, ordem: 94 },
  taxas_asaas: { rotulo: "Taxas do Asaas (parcial)", grupo: "oculto", mensal: true, subirEhRuim: true, ordem: 95 },
  recebido_asaas: { rotulo: "Recebido no Asaas (parcial)", grupo: "oculto", mensal: true, ordem: 96 },
  mrr: { rotulo: "MRR no Asaas (parcial)", grupo: "oculto", ordem: 97 },
  inadimplencia: { rotulo: "Inadimplência no Asaas (parcial)", grupo: "oculto", subirEhRuim: true, ordem: 98 },
};

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

/** Referência do cartão: "set/2026" para métrica mensal, "18/10/2026" para as diárias. */
export function rotuloReferencia(metrica: string, referencia: string): string {
  if (defKpi(metrica).mensal) return `${MESES[Number(referencia.slice(5, 7)) - 1]}/${referencia.slice(0, 4)}`;
  return `${referencia.slice(8, 10)}/${referencia.slice(5, 7)}/${referencia.slice(0, 4)}`;
}

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
