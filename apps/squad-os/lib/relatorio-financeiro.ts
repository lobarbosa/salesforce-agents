// Relatório diário de saúde financeira (ops.relatorios_financeiros), gravado
// pelo agente de relatório financeiro do konecta-agents. Este arquivo é puro
// (sem banco): normaliza o jsonb que vem do agente e formata para a tela —
// testado em scripts/testa-saude-financeira.ts.
//
// O agente grava cada seção de `indicadores` só quando a fonte dela respondeu
// (Asaas fora → sem `receitas`). Seção ausente vira `null` aqui e a tela diz
// "indisponível" — nunca zero, que leria como "não entrou dinheiro".

export const SAUDES_FINANCEIRAS = ["verde", "amarelo", "vermelho"] as const;
export type SaudeFinanceira = (typeof SAUDES_FINANCEIRAS)[number];

export const TIPOS_INSIGHT = ["insight", "risco", "recomendacao"] as const;
export type TipoInsight = (typeof TIPOS_INSIGHT)[number];

export const ROTULO_INSIGHT: Record<TipoInsight, { simbolo: string; rotulo: string }> = {
  insight: { simbolo: "💡", rotulo: "Insights" },
  risco: { simbolo: "⚠️", rotulo: "Riscos" },
  recomendacao: { simbolo: "✅", rotulo: "Recomendações" },
};

export interface Insight {
  tipo: TipoInsight;
  titulo: string;
  texto: string;
}

export interface Destaque {
  nome: string;
  valor: number | null;
  pct: number | null;
}

export interface Receitas {
  mrr: number | null;
  arr: number | null;
  assinaturasAtivas: number | null;
  recebidoMesAtual: number | null;
  recebidoMesAnterior: number | null;
  recebido90d: number | null;
  aReceber30d: number | null;
  inadimplenciaTotal: number | null;
  inadimplenciaQtd: number | null;
  inadimplenciaDiasMaisAntiga: number | null;
  inadimplenciaPctMrr: number | null;
  maiorCliente90d: Destaque | null;
}

export interface Despesas {
  pagasMesAtual: number | null;
  pagasMesAnterior: number | null;
  mediaMensalPagas3m: number | null;
  pagas90d: number | null;
  porCategoria90d: { categoria: string; valor: number }[];
  maiorFornecedor90d: Destaque | null;
  emAbertoTotal: number | null;
  emAbertoQtd: number | null;
  vencidasNaoPagasTotal: number | null;
  vencidasNaoPagasQtd: number | null;
  aVencer30dTotal: number | null;
  aguardandoAprovacaoQtd: number | null;
  aguardandoAprovacaoTotal: number | null;
}

export interface Caixa {
  caixa30d: number | null;
  caixa60d: number | null;
  caixa90d: number | null;
  aReceber30d: number | null;
  aPagar30d: number | null;
  pipelinePonderado90d: number | null;
  referencia: string | null;
}

export interface Comercial {
  bookingsMes: number | null;
  bookingsQtd: number | null;
  pipelineAberto: number | null;
  pipelineQtd: number | null;
  oppsAtrasadas: number | null;
}

export interface ContratoHoras {
  cliente: string;
  tipo: string;
  horasContratadas: number | null;
  ciclo: string;
  horasMes: number | null;
  usoPct: number | null;
}

export interface Operacao {
  contratos: ContratoHoras[];
  contratosSemHorasDefinidas: string[];
  horasLancadasMes: number | null;
}

export interface Contabil {
  competenciasComDocumentos: string[];
  competenciasConciliadas: string[];
  ultimaConciliacao: { competencia: string; diferencaPct: number | null } | null;
  divergenciasAbertas: number | null;
}

export interface Indicadores {
  receitas: Receitas | null;
  despesas: Despesas | null;
  caixa: Caixa | null;
  comercial: Comercial | null;
  operacao: Operacao | null;
  contabil: Contabil | null;
  coberturaMrrDespesa: number | null;
  resultadoCaixaMesAnterior: number | null;
}

export interface RelatorioFinanceiro {
  referencia: string; // YYYY-MM-DD
  saude: SaudeFinanceira | null; // null = valor fora do vocabulário (a tela mostra "desconhecida")
  motivos: string[];
  resumo: string | null;
  indicadores: Indicadores;
  insights: Insight[];
  alertas: string[];
  fontes: { fonte: string; status: string; ok: boolean }[];
  atualizadoEm: string;
}

/** Linha resumida do histórico. */
export interface RelatorioResumo {
  referencia: string;
  saude: SaudeFinanceira | null;
  primeiroMotivo: string | null;
  mrr: number | null;
  inadimplenciaTotal: number | null;
}

// ── Normalização do jsonb ─────────────────────────────────────────────────

type Obj = Record<string, unknown>;

function obj(v: unknown): Obj | null {
  return v && typeof v === "object" && !Array.isArray(v) ? (v as Obj) : null;
}

/** Número finito ou null — jsonb pode trazer número como string (numeric serializado). */
export function numero(v: unknown): number | null {
  if (v === null || v === undefined || v === "" || typeof v === "boolean") return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

function texto(v: unknown): string | null {
  return typeof v === "string" && v.trim() ? v : null;
}

function textos(v: unknown): string[] {
  return Array.isArray(v) ? v.filter((x): x is string => typeof x === "string" && x.trim() !== "") : [];
}

export function saudeDe(v: unknown): SaudeFinanceira | null {
  return SAUDES_FINANCEIRAS.includes(v as SaudeFinanceira) ? (v as SaudeFinanceira) : null;
}

function destaque(v: unknown): Destaque | null {
  const o = obj(v);
  const nome = o && texto(o.nome);
  return o && nome ? { nome, valor: numero(o.valor), pct: numero(o.pct) } : null;
}

function receitas(v: unknown): Receitas | null {
  const o = obj(v);
  if (!o) return null;
  return {
    mrr: numero(o.mrr),
    arr: numero(o.arr),
    assinaturasAtivas: numero(o.assinaturas_ativas),
    recebidoMesAtual: numero(o.recebido_mes_atual),
    recebidoMesAnterior: numero(o.recebido_mes_anterior),
    recebido90d: numero(o.recebido_90d),
    aReceber30d: numero(o.a_receber_30d),
    inadimplenciaTotal: numero(o.inadimplencia_total),
    inadimplenciaQtd: numero(o.inadimplencia_qtd),
    inadimplenciaDiasMaisAntiga: numero(o.inadimplencia_dias_mais_antiga),
    inadimplenciaPctMrr: numero(o.inadimplencia_pct_mrr),
    maiorCliente90d: destaque(o.maior_cliente_90d),
  };
}

function despesas(v: unknown): Despesas | null {
  const o = obj(v);
  if (!o) return null;
  const cats = obj(o.por_categoria_90d) ?? {};
  return {
    pagasMesAtual: numero(o.pagas_mes_atual),
    pagasMesAnterior: numero(o.pagas_mes_anterior),
    mediaMensalPagas3m: numero(o.media_mensal_pagas_3m),
    pagas90d: numero(o.pagas_90d),
    porCategoria90d: Object.entries(cats)
      .map(([categoria, valor]) => ({ categoria, valor: numero(valor) }))
      .filter((c): c is { categoria: string; valor: number } => c.valor !== null)
      .sort((a, b) => b.valor - a.valor),
    maiorFornecedor90d: destaque(o.maior_fornecedor_90d),
    emAbertoTotal: numero(o.em_aberto_total),
    emAbertoQtd: numero(o.em_aberto_qtd),
    vencidasNaoPagasTotal: numero(o.vencidas_nao_pagas_total),
    vencidasNaoPagasQtd: numero(o.vencidas_nao_pagas_qtd),
    aVencer30dTotal: numero(o.a_vencer_30d_total),
    aguardandoAprovacaoQtd: numero(o.aguardando_aprovacao_qtd),
    aguardandoAprovacaoTotal: numero(o.aguardando_aprovacao_total),
  };
}

function caixa(v: unknown): Caixa | null {
  const o = obj(v);
  if (!o) return null;
  return {
    caixa30d: numero(o.caixa_30d),
    caixa60d: numero(o.caixa_60d),
    caixa90d: numero(o.caixa_90d),
    aReceber30d: numero(o.a_receber_30d),
    aPagar30d: numero(o.a_pagar_30d),
    pipelinePonderado90d: numero(o.pipeline_ponderado_90d),
    referencia: texto(o.referencia),
  };
}

function comercial(v: unknown): Comercial | null {
  const o = obj(v);
  if (!o) return null;
  return {
    bookingsMes: numero(o.bookings_mes),
    bookingsQtd: numero(o.bookings_qtd),
    pipelineAberto: numero(o.pipeline_aberto),
    pipelineQtd: numero(o.pipeline_qtd),
    oppsAtrasadas: numero(o.opps_atrasadas),
  };
}

function operacao(v: unknown): Operacao | null {
  const o = obj(v);
  if (!o) return null;
  const contratos = (Array.isArray(o.contratos) ? o.contratos : [])
    .map(obj)
    .filter((c): c is Obj => !!c && !!texto(c.cliente))
    .map((c) => ({
      cliente: String(c.cliente),
      tipo: texto(c.tipo) ?? "",
      horasContratadas: numero(c.horas_contratadas),
      ciclo: texto(c.ciclo) ?? "",
      horasMes: numero(c.horas_mes),
      usoPct: numero(c.uso_pct),
    }));
  return {
    contratos,
    contratosSemHorasDefinidas: textos(o.contratos_sem_horas_definidas),
    horasLancadasMes: numero(o.horas_lancadas_mes),
  };
}

function contabil(v: unknown): Contabil | null {
  const o = obj(v);
  if (!o) return null;
  const ult = obj(o.ultima_conciliacao);
  const comp = ult && texto(ult.competencia);
  return {
    competenciasComDocumentos: textos(o.competencias_com_documentos),
    competenciasConciliadas: textos(o.competencias_conciliadas),
    ultimaConciliacao: ult && comp ? { competencia: comp, diferencaPct: numero(ult.diferenca_pct) } : null,
    divergenciasAbertas: numero(o.divergencias_abertas),
  };
}

export function normalizarIndicadores(v: unknown): Indicadores {
  const o = obj(v) ?? {};
  return {
    receitas: receitas(o.receitas),
    despesas: despesas(o.despesas),
    caixa: caixa(o.caixa),
    comercial: comercial(o.comercial),
    operacao: operacao(o.operacao),
    contabil: contabil(o.contabil),
    coberturaMrrDespesa: numero(o.cobertura_mrr_despesa),
    resultadoCaixaMesAnterior: numero(o.resultado_caixa_mes_anterior),
  };
}

export function normalizarInsights(v: unknown): Insight[] {
  if (!Array.isArray(v)) return [];
  return v
    .map(obj)
    .filter((i): i is Obj => !!i && TIPOS_INSIGHT.includes(i.tipo as TipoInsight) && !!(texto(i.titulo) || texto(i.texto)))
    .map((i) => ({ tipo: i.tipo as TipoInsight, titulo: texto(i.titulo) ?? "", texto: texto(i.texto) ?? "" }));
}

/** Fontes na ordem fixa (Squad OS, Asaas, Salesforce) e depois qualquer outra que o agente passe a gravar. */
export function normalizarFontes(v: unknown): RelatorioFinanceiro["fontes"] {
  const o = obj(v) ?? {};
  const ordem = ["squad_os", "asaas", "salesforce"];
  const chaves = [...ordem.filter((k) => k in o), ...Object.keys(o).filter((k) => !ordem.includes(k)).sort()];
  return chaves.map((fonte) => {
    const status = typeof o[fonte] === "string" ? (o[fonte] as string) : "desconhecido";
    return { fonte, status, ok: status === "ok" };
  });
}

export const ROTULO_FONTE: Record<string, string> = {
  squad_os: "Squad OS",
  asaas: "Asaas",
  salesforce: "Salesforce",
};

export const rotuloFonte = (f: string) => ROTULO_FONTE[f] ?? f.replace(/_/g, " ");

export function agruparInsights(lista: Insight[]): { tipo: TipoInsight; itens: Insight[] }[] {
  return TIPOS_INSIGHT.map((tipo) => ({ tipo, itens: lista.filter((i) => i.tipo === tipo) })).filter((g) => g.itens.length);
}

// ── Formatação ────────────────────────────────────────────────────────────

/** 1.25 → "1,25x". */
export function formatarCobertura(v: number): string {
  return `${v.toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}x`;
}

/** 12.345 → "12,3%". O agente grava percentuais já em pontos (12.3 = 12,3%). */
export function formatarPct(v: number): string {
  return `${v.toLocaleString("pt-BR", { maximumFractionDigits: 1 })}%`;
}

/** "2026-10-16" → "16/10/2026". */
export function dataBr(dia: string): string {
  return /^\d{4}-\d{2}-\d{2}/.test(dia) ? `${dia.slice(8, 10)}/${dia.slice(5, 7)}/${dia.slice(0, 4)}` : dia;
}
