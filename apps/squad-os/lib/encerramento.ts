import type { Role } from "@/lib/generated/prisma/client";

// Encerrar × excluir cliente, as regras puras (sem Prisma, sem Next) — as
// rotas e as telas perguntam aqui, e scripts/testa-encerramento.ts testa aqui.
//
// O pedido real (CEO, 2026-10-17): "se eu precisar deletar um cliente que saiu
// eu não consigo". Só que toda relação do Client é onDelete: Cascade — um
// DELETE levaria junto demandas, registros de horas, comentários, anexos,
// execuções e contrato: histórico de trabalho e de faturamento que o
// financeiro ainda soma. Por isso o caminho padrão é **encerrar** (some das
// listas, perde acesso, nada novo nasce, histórico fica) e **excluir** só
// existe para cliente já encerrado e sem histórico nenhum — tipicamente um
// cadastro feito por engano.

/** Encerrar, reativar e excluir são decisões do admin — nenhum outro papel. */
export function podeEncerrarCliente(role: Role): boolean {
  return role === "admin";
}

export interface EstadoDoCliente {
  nome: string;
  encerradoEm: Date | null;
}

export function estaEncerrado(c: { encerradoEm: Date | null } | null | undefined): boolean {
  return !!c?.encerradoEm;
}

/** O que fica bloqueado num cliente encerrado — cada um com a sua mensagem. */
export type AcaoBloqueada = "demanda" | "tempo" | "agente" | "sync" | "acesso";

const O_QUE: Record<AcaoBloqueada, string> = {
  demanda: "não recebe demanda nova",
  tempo: "não recebe lançamento de horas novo",
  agente: "não dispara agente (materializar, aprovar gate, assessment, planejamento, teste de conexão)",
  sync: "não aceita sync de execução de agente",
  acesso: "não pode receber usuário novo",
};

export function dataBR(d: Date): string {
  return d.toLocaleDateString("pt-BR", { timeZone: "America/Sao_Paulo" });
}

/**
 * null quando a ação pode seguir; senão, a mensagem do 409. Cliente ativo
 * (encerradoEm nulo) nunca bloqueia nada aqui.
 */
export function bloqueioPorEncerramento(c: EstadoDoCliente | null | undefined, acao: AcaoBloqueada): string | null {
  if (!c?.encerradoEm) return null;
  return `o cliente ${c.nome} foi encerrado em ${dataBR(c.encerradoEm)} e ${O_QUE[acao]} — um admin pode reativá-lo na página do cliente`;
}

/**
 * Quem ainda enxerga um cliente encerrado: só o admin (histórico, reativar,
 * excluir). O consultor deixa de vê-lo junto com as listas; o usuário
 * `cliente` dele perde o login (ver `usuarioPerdeAcesso`). As telas de
 * /financeiro não passam por aqui — horas e relatórios continuam somando o
 * passado.
 */
export function enxergaCliente(role: Role, c: { encerradoEm: Date | null }): boolean {
  if (!c.encerradoEm) return true;
  return role === "admin";
}

/** O usuário de papel `cliente` de um cliente encerrado não entra mais. */
export function usuarioPerdeAcesso(role: Role, clienteDoUsuario: { encerradoEm: Date | null } | null): boolean {
  return role === "cliente" && estaEncerrado(clienteDoUsuario);
}

// ── Encerrar ────────────────────────────────────────────────────────────────

export const MOTIVO_MAX = 500;

export type Resultado = { ok: true } | { ok: false; status: number; error: string };

export function validarEncerramento(c: EstadoDoCliente, motivo: string): Resultado {
  if (c.encerradoEm) {
    return { ok: false, status: 409, error: `o cliente já está encerrado desde ${dataBR(c.encerradoEm)}` };
  }
  const m = motivo.trim();
  if (!m) return { ok: false, status: 400, error: "informe o motivo do encerramento" };
  if (m.length > MOTIVO_MAX) return { ok: false, status: 400, error: `o motivo vai até ${MOTIVO_MAX} caracteres` };
  return { ok: true };
}

export function validarReativacao(c: EstadoDoCliente): Resultado {
  if (!c.encerradoEm) return { ok: false, status: 409, error: "o cliente não está encerrado" };
  return { ok: true };
}

// ── Excluir definitivamente ─────────────────────────────────────────────────

/**
 * O que existe do cliente que é histórico. Qualquer número > 0 bloqueia a
 * exclusão: demandas (e com elas comentários, anexos, subtarefas), horas
 * (faturamento e /financeiro/horas), execuções de agente (rastro do que rodou
 * contra a org) e contrato com conteúdo (entregáveis ou horas contratadas).
 * Ambientes, chunks de RAG e usuários não bloqueiam: são configuração ou
 * índice derivado, e vão junto na cascata.
 */
export interface HistoricoDoCliente {
  demandas: number;
  registrosTempo: number;
  execucoes: number;
  /** Contas a pagar e despesas recorrentes alocadas ao cliente (opcionais nos testes antigos). */
  contasPagar?: number;
  despesasRecorrentes?: number;
  entregaveis: number;
  horasContratadas: number;
}

function plural(n: number, um: string, varios: string) {
  return `${n} ${n === 1 ? um : varios}`;
}

export function bloqueiosDeExclusao(h: HistoricoDoCliente): string[] {
  const b: string[] = [];
  if (h.demandas > 0) b.push(plural(h.demandas, "demanda", "demandas"));
  if (h.registrosTempo > 0) b.push(plural(h.registrosTempo, "registro de horas", "registros de horas"));
  if (h.execucoes > 0) b.push(plural(h.execucoes, "execução de agente", "execuções de agente"));
  if ((h.contasPagar ?? 0) > 0) b.push(plural(h.contasPagar!, "conta a pagar alocada", "contas a pagar alocadas"));
  if ((h.despesasRecorrentes ?? 0) > 0)
    b.push(plural(h.despesasRecorrentes!, "despesa recorrente alocada", "despesas recorrentes alocadas"));
  if (h.entregaveis > 0) b.push(plural(h.entregaveis, "entregável no contrato", "entregáveis no contrato"));
  if (h.horasContratadas > 0) b.push(`contrato com ${h.horasContratadas}h contratadas`);
  return b;
}

/** Compara o nome digitado na confirmação, sem caixa nem espaço nas pontas. */
export function nomeConfere(digitado: string, nome: string): boolean {
  const n = (s: string) => s.trim().replace(/\s+/g, " ").toLocaleLowerCase("pt-BR");
  return n(digitado) !== "" && n(digitado) === n(nome);
}

export const AVISO_WORKSPACE =
  "o diretório clients/<slug> no repositório não é apagado — é histórico do git; remova por PR se for o caso";

export function validarExclusao(
  c: EstadoDoCliente & { slug: string },
  historico: HistoricoDoCliente,
  nomeDigitado: string
): Resultado & { bloqueios?: string[] } {
  if (!c.encerradoEm) {
    return { ok: false, status: 409, error: "encerre o cliente antes de excluir — excluir só existe para cliente encerrado" };
  }
  const bloqueios = bloqueiosDeExclusao(historico);
  if (bloqueios.length > 0) {
    return {
      ok: false,
      status: 409,
      error: `o cliente tem histórico (${bloqueios.join(", ")}) — mantenha encerrado em vez de excluir`,
      bloqueios,
    };
  }
  if (!nomeConfere(nomeDigitado, c.nome)) {
    return { ok: false, status: 400, error: `digite o nome do cliente (${c.nome}) para confirmar` };
  }
  return { ok: true };
}

/** Linha de auditoria (log estruturado) — o banco guarda só o último encerramento. */
export function linhaDeAuditoria(
  acao: "encerrou" | "reativou" | "excluiu",
  c: { id: string; slug: string; nome: string },
  porEmail: string,
  extra: Record<string, unknown> = {}
): string {
  return JSON.stringify({
    auditoria: "cliente",
    acao,
    clientId: c.id,
    slug: c.slug,
    nome: c.nome,
    por: porEmail,
    em: new Date().toISOString(),
    ...extra,
  });
}
