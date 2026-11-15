import { estimativaLiberaBuild } from "@/lib/demandas";

// O que a fila faz com cada pedido pendente. Função pura, separada de
// fila-esteira.ts para ter teste (scripts/testa-fila.ts) sem banco nem GitHub.

export const NOTA_ESPERA_ESTIMATIVA = "esperando o cliente aprovar a estimativa de horas";
export const notaEsperaQa = (codigo: string) => `esperando a sandbox de QA: ${codigo} está em teste lá`;

export type TipoDisparo = "rodar" | "aprovar" | "reverificar";
export type Ambiente = "dev" | "qa";

// Espelho de ambientes.py: estágios que rodam na sandbox de QA. Mudou lá,
// muda aqui (scripts/testa-fila.ts confere os casos da fronteira).
const ESTAGIOS_QA = new Set(["qa", "aguardando_homologacao", "release", "entregue"]);
const DEPOIS_DO_GATE: Record<string, string> = {
  aguardando_gate_analise: "design",
  aguardando_gate_design: "build",
  aguardando_gate_build: "qa",
  aguardando_homologacao: "release",
};

/** Em qual sandbox o disparo vai rodar: a do estágio que a sessão executa. */
export function ambienteDoDisparo(tipo: string, gate: string, status: string): Ambiente {
  if (tipo === "reverificar") return "dev";
  const etapa = tipo === "aprovar" ? (DEPOIS_DO_GATE[gate] ?? status) : status;
  return ESTAGIOS_QA.has(etapa) ? "qa" : "dev";
}

export interface PedidoNaFila {
  tipo: string;
  gate: string;
  autor: string;
  nota: string;
  demanda: Parameters<typeof estimativaLiberaBuild>[0] & { status: string };
}

export type Decisao =
  | { acao: "descartar"; nota: string }
  | { acao: "esperar"; nota: string }
  | { acao: "disparar"; opcoes: { aprovarGate?: string; gateEsperado?: string; reverificar?: string } };

/**
 * `outraEmQa`: código de outra demanda do mesmo cliente que está em `qa`, se
 * houver. Guardrail #6 (uma demanda por vez, por cliente, na mesma sandbox):
 * o teste de uma não pode criar registros no meio do teste armado da outra
 * (achado 2026-11-15: a EPLAST-47 contava contas na QA entre duas sessões).
 */
export function decidirDisparo(p: PedidoNaFila, outraEmQa: string | null): Decisao {
  const status = p.demanda.status;
  if (status === "standby" || status === "cancelada") {
    return { acao: "descartar", nota: `sem efeito: demanda ${status}` };
  }
  if (p.tipo === "aprovar" && status !== p.gate) {
    return { acao: "descartar", nota: `sem efeito: a demanda saiu de ${p.gate} antes de rodar` };
  }
  if (p.tipo === "reverificar" && status !== "aguardando_gate_build") {
    return { acao: "descartar", nota: `sem efeito: reverificação só no gate de build (demanda em ${status})` };
  }
  // Build só com a estimativa aprovada pelo cliente (AMS): a aprovação do
  // gate fica guardada na fila e sai quando ele aprovar.
  if (p.tipo === "aprovar" && p.gate === "aguardando_gate_design" && !estimativaLiberaBuild(p.demanda)) {
    return { acao: "esperar", nota: NOTA_ESPERA_ESTIMATIVA };
  }
  if (p.tipo === "aprovar" && p.gate === "aguardando_gate_build" && outraEmQa) {
    return { acao: "esperar", nota: notaEsperaQa(outraEmQa) };
  }
  if (p.tipo === "aprovar") return { acao: "disparar", opcoes: { aprovarGate: p.autor, gateEsperado: p.gate } };
  if (p.tipo === "reverificar") return { acao: "disparar", opcoes: { reverificar: p.autor || "Squad OS" } };
  return { acao: "disparar", opcoes: {} };
}

/**
 * Ordem da fila (decisão de 2026-11-15): projeto antes de sustentação, e
 * dentro de cada grupo por ordem de chegada. Exceção: a segunda sessão de um
 * QA em duas fases (`liberarEm` vencido) sai primeiro, porque é ela que
 * devolve a sandbox de QA para as outras.
 */
export function ordemDaFila(
  a: { criadoEm: Date; liberarEm: Date | null; demanda: { tipo: string } },
  b: { criadoEm: Date; liberarEm: Date | null; demanda: { tipo: string } }
): number {
  const peso = (x: typeof a) => (x.liberarEm ? 0 : x.demanda.tipo === "projeto" ? 1 : 2);
  return peso(a) - peso(b) || a.criadoEm.getTime() - b.criadoEm.getTime();
}
