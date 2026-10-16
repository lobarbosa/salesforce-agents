import { prisma } from "@/lib/prisma";
import {
  normalizarFontes,
  normalizarIndicadores,
  normalizarInsights,
  numero,
  saudeDe,
  type RelatorioFinanceiro,
  type RelatorioResumo,
} from "@/lib/relatorio-financeiro";

// Leitura do schema `ops` (banco operacional dos agentes, konecta-agents
// supabase/migrations). O Squad OS só lê — exceto o status de divergência,
// que é decisão humana (resolvida/ignorada) e o agente nunca sobrescreve.
//
// O schema pode não existir ainda (banco dos agentes não ligado, ou Squad OS
// e agentes em projetos diferentes durante a migração): toda leitura devolve
// `null` nesse caso e a tela mostra o que falta ligar, em vez de quebrar.

async function temOps(): Promise<boolean> {
  try {
    const r = await prisma.$queryRaw<{ ok: boolean }[]>`select to_regclass('ops.agent_runs') is not null as ok`;
    return Boolean(r[0]?.ok);
  } catch {
    return false;
  }
}

async function ler<T>(fn: () => Promise<T>): Promise<T | null> {
  if (!(await temOps())) return null;
  try {
    return await fn();
  } catch (e) {
    console.error("leitura do schema ops falhou:", e);
    return null;
  }
}

const num = (v: unknown) => (v === null || v === undefined ? null : Number(v));
const iso = (v: unknown) => (v instanceof Date ? v.toISOString() : v ? String(v) : null);
const dia = (v: unknown) => (v instanceof Date ? v.toISOString().slice(0, 10) : v ? String(v).slice(0, 10) : null);

// ── Conciliação contábil ───────────────────────────────────────────────────

export interface Conciliacao {
  competencia: string; // YYYY-MM
  resultadoContabil: number | null;
  resultadoGerencial: number | null;
  diferencaPct: number | null;
  ok: string[];
  divergencias: string[];
  em: string;
}

export function conciliacaoDo(mes: string): Promise<Conciliacao | null | undefined> {
  return ler(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select competencia, resultado_contabil, resultado_gerencial, diferenca_pct, extraido, created_at,
             to_jsonb(c) ->> 'updated_at' as updated_at
      from ops.conciliacoes c where competencia = ${`${mes}-01`}::date`;
    if (!r[0]) return undefined; // ops existe, mas o mês ainda não foi conciliado
    const x = r[0];
    const extraido = (x.extraido ?? {}) as { ok?: string[]; divergencias?: string[] };
    return {
      competencia: mes,
      resultadoContabil: num(x.resultado_contabil),
      resultadoGerencial: num(x.resultado_gerencial),
      diferencaPct: num(x.diferenca_pct),
      ok: extraido.ok ?? [],
      divergencias: extraido.divergencias ?? [],
      // A conciliação é um upsert por competência e `created_at` fica com a
      // data da PRIMEIRA rodada — a tela dizia "conciliado em" uma data velha
      // depois de reprocessar. `updated_at` ainda não existe em
      // ops.conciliacoes (o schema é do konecta-agents); `to_jsonb(c)` lê a
      // coluna se ela existir e devolve null se não, sem quebrar a query.
      em: maisRecente(iso(x.created_at), iso(x.updated_at)) ?? "",
    };
  });
}

function maisRecente(...isos: (string | null | undefined)[]): string | null {
  const validos = isos.filter((v): v is string => !!v && !Number.isNaN(Date.parse(v)));
  if (!validos.length) return null;
  return validos.reduce((a, b) => (Date.parse(b) > Date.parse(a) ? b : a));
}

// ── Divergências ───────────────────────────────────────────────────────────

export const STATUS_DIVERGENCIA = ["aberta", "resolvida", "ignorada"] as const;
export type StatusDivergencia = (typeof STATUS_DIVERGENCIA)[number];

export interface Divergencia {
  id: string;
  origem: string;
  tipo: string;
  refExterna: string;
  competencia: string | null;
  esperado: number | null;
  encontrado: number | null;
  detalhe: Record<string, unknown>;
  status: StatusDivergencia;
  resolvidoPor: string | null;
  criadaEm: string;
  atualizadaEm: string;
}

export function listarDivergencias(filtro: { status?: StatusDivergencia; origem?: string }): Promise<Divergencia[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select id, origem, tipo, ref_externa, competencia, esperado, encontrado, detalhe, status,
             resolvido_por, created_at, updated_at
      from ops.divergencias
      where (${filtro.status ?? null}::text is null or status = ${filtro.status ?? null}::text)
        and (${filtro.origem ?? null}::text is null or origem = ${filtro.origem ?? null}::text)
      order by (status = 'aberta') desc, updated_at desc
      limit 500`;
    return r.map((x) => ({
      id: String(x.id),
      origem: String(x.origem),
      tipo: String(x.tipo),
      refExterna: String(x.ref_externa),
      competencia: dia(x.competencia),
      esperado: num(x.esperado),
      encontrado: num(x.encontrado),
      detalhe: (x.detalhe ?? {}) as Record<string, unknown>,
      status: x.status as StatusDivergencia,
      resolvidoPor: x.resolvido_por ? String(x.resolvido_por) : null,
      criadaEm: iso(x.created_at) ?? "",
      atualizadaEm: iso(x.updated_at) ?? "",
    }));
  });
}

export function contarDivergenciasAbertas(): Promise<{ origem: string; total: number }[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<{ origem: string; total: bigint }[]>`
      select origem, count(*) as total from ops.divergencias where status = 'aberta' group by origem order by origem`;
    return r.map((x) => ({ origem: x.origem, total: Number(x.total) }));
  });
}

/** Decisão humana. Só sai de "aberta"; reabrir também é permitido (erro de quem marcou). */
export async function decidirDivergencia(id: string, status: StatusDivergencia, porEmail: string, nota: string) {
  if (!(await temOps())) return { erro: "banco operacional não ligado", status: 503 } as const;
  const detalheNota = JSON.stringify({ nota_humana: nota, decidido_por: porEmail, decidido_em: new Date().toISOString() });
  const n = await prisma.$executeRaw`
    update ops.divergencias
       set status = ${status}, resolvido_por = ${status === "aberta" ? null : porEmail},
           detalhe = detalhe || ${detalheNota}::jsonb, updated_at = now()
     where id = ${BigInt(id)} and status <> ${status}`;
  return n ? ({ ok: true } as const) : ({ erro: "divergência não encontrada ou já nesta situação", status: 409 } as const);
}

// ── KPIs ───────────────────────────────────────────────────────────────────

export interface Kpi {
  metrica: string;
  referencia: string;
  valor: number;
  fonte: string;
  anterior: number | null;
  em: string;
}

/** Último valor de cada métrica e o anterior dela, para mostrar a tendência. */
export function kpisAtuais(): Promise<Kpi[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select metrica, referencia, valor, fonte, created_at, anterior from (
        select metrica, referencia, valor, fonte, created_at,
               lead(valor) over (partition by metrica order by referencia desc) as anterior,
               row_number() over (partition by metrica order by referencia desc) as n
        from ops.kpi_snapshots) k
      where n = 1`;
    return r.map((x) => ({
      metrica: String(x.metrica),
      referencia: dia(x.referencia) ?? "",
      valor: Number(x.valor),
      fonte: String(x.fonte),
      anterior: num(x.anterior),
      em: iso(x.created_at) ?? "",
    }));
  });
}

export interface ResultadoMes {
  mes: string; // YYYY-MM
  valor: number;
}

/**
 * "Resultado do mês" (receita - despesas) dos últimos `meses` meses fechados,
 * para o gráfico de tendência — kpisAtuais só traz o atual e o anterior, essa
 * é a série completa. finance_report_agent grava uma linha por mês fechado;
 * quando grava mais de uma no mesmo mês (reprocessamento), fica a mais
 * recente por `created_at`.
 */
export function resultadoPorMes(meses = 6): Promise<ResultadoMes[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<{ mes: string; valor: unknown }[]>`
      select mes, valor from (
        select to_char(referencia, 'YYYY-MM') as mes, valor, created_at,
               row_number() over (
                 partition by to_char(referencia, 'YYYY-MM')
                 order by referencia desc, created_at desc
               ) as rn
        from ops.kpi_snapshots
        where metrica = 'resultado') k
      where rn = 1
      order by mes desc
      limit ${meses}`;
    return r.map((x) => ({ mes: x.mes, valor: Number(x.valor) })).reverse();
  });
}

// ── Saúde dos agentes ──────────────────────────────────────────────────────

export interface SaudeAgente {
  agente: string;
  ultimaEm: string;
  ultimoStatus: "ok" | "erro" | "pulado";
  ultimoErro: string | null;
  execucoes24h: number;
  erros24h: number;
  ultimoOkEm: string | null;
}

export function saudeDosAgentes(): Promise<SaudeAgente[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      with ult as (
        select distinct on (agent) agent, started_at, status, error
        from ops.agent_runs order by agent, started_at desc
      )
      select u.agent, u.started_at, u.status, u.error,
             (select count(*) from ops.agent_runs a where a.agent = u.agent and a.started_at > now() - interval '24 hours') as exec24,
             (select count(*) from ops.agent_runs a where a.agent = u.agent and a.status = 'erro'
                and a.started_at > now() - interval '24 hours') as erros24,
             (select max(started_at) from ops.agent_runs a where a.agent = u.agent and a.status = 'ok') as ultimo_ok
      from ult u
      order by (u.status = 'erro') desc, u.agent`;
    return r.map((x) => ({
      agente: String(x.agent),
      ultimaEm: iso(x.started_at) ?? "",
      ultimoStatus: x.status as SaudeAgente["ultimoStatus"],
      ultimoErro: x.error ? String(x.error) : null,
      execucoes24h: Number(x.exec24),
      erros24h: Number(x.erros24),
      ultimoOkEm: iso(x.ultimo_ok),
    }));
  });
}

export interface Deploy {
  commit: string;
  em: string;
  resultado: "ok" | "rollback" | "abortado";
  detalhe: string;
}

export function ultimosDeploys(n = 10): Promise<Deploy[] | null> {
  return ler(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select commit_sha, started_at, resultado, detalhe from ops.deploys order by started_at desc limit ${n}`;
    return r.map((x) => ({
      commit: String(x.commit_sha).slice(0, 8),
      em: iso(x.started_at) ?? "",
      resultado: x.resultado as Deploy["resultado"],
      detalhe: x.detalhe ? String(x.detalhe) : "",
    }));
  });
}

// ── Saúde financeira (relatório diário do cfo_agent) ───────────────────────

// Tabela mais nova que o resto do `ops`: o schema pode existir sem ela (banco
// dos agentes ligado, migration de relatorios_financeiros ainda não aplicada).
// `temOps()` olha só agent_runs, então aqui a checagem é da própria tabela —
// sem ela a leitura devolve null e a tela mostra o estado vazio, sem logar erro.
async function temRelatorios(): Promise<boolean> {
  try {
    const r = await prisma.$queryRaw<{ ok: boolean }[]>`select to_regclass('ops.relatorios_financeiros') is not null as ok`;
    return Boolean(r[0]?.ok);
  } catch {
    return false;
  }
}

async function lerRelatorios<T>(fn: () => Promise<T>): Promise<T | null> {
  if (!(await temRelatorios())) return null;
  try {
    return await fn();
  } catch (e) {
    console.error("leitura de ops.relatorios_financeiros falhou:", e);
    return null;
  }
}

/** null = tabela ausente; undefined = tabela existe, mas o agente ainda não gravou nenhum relatório. */
export function ultimoRelatorioFinanceiro(): Promise<RelatorioFinanceiro | null | undefined> {
  return lerRelatorios(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select referencia, saude, motivos, resumo, indicadores, insights, alertas, fontes, created_at, updated_at
      from ops.relatorios_financeiros order by referencia desc limit 1`;
    const x = r[0];
    if (!x) return undefined;
    return {
      referencia: dia(x.referencia) ?? "",
      saude: saudeDe(x.saude),
      motivos: textosJson(x.motivos),
      resumo: typeof x.resumo === "string" && x.resumo.trim() ? x.resumo : null,
      indicadores: normalizarIndicadores(x.indicadores),
      insights: normalizarInsights(x.insights),
      alertas: textosJson(x.alertas),
      fontes: normalizarFontes(x.fontes),
      atualizadoEm: maisRecente(iso(x.created_at), iso(x.updated_at)) ?? "",
    };
  });
}

/** Últimos `n` relatórios, do mais recente ao mais antigo, só com o que o histórico mostra. */
export function historicoRelatoriosFinanceiros(n = 30): Promise<RelatorioResumo[] | null> {
  return lerRelatorios(async () => {
    const r = await prisma.$queryRaw<Record<string, unknown>[]>`
      select referencia, saude, motivos ->> 0 as primeiro_motivo,
             indicadores #>> '{receitas,mrr}' as mrr,
             indicadores #>> '{receitas,inadimplencia_total}' as inadimplencia_total
      from ops.relatorios_financeiros order by referencia desc limit ${n}`;
    return r.map((x) => ({
      referencia: dia(x.referencia) ?? "",
      saude: saudeDe(x.saude),
      primeiroMotivo: typeof x.primeiro_motivo === "string" && x.primeiro_motivo ? x.primeiro_motivo : null,
      mrr: numero(x.mrr),
      inadimplenciaTotal: numero(x.inadimplencia_total),
    }));
  });
}

function textosJson(v: unknown): string[] {
  return Array.isArray(v) ? v.filter((s): s is string => typeof s === "string" && s.trim() !== "") : [];
}
