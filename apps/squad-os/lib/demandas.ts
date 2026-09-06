// Constantes e helpers de exibição pra demanda — sem Prisma, importável de
// Server e Client Components. Espelha STAGES_TRIAGEM/STAGES_EXECUCAO de
// src/salesforce_agents/demands.py.

export const TRIAGE = ["backlog", "planejada", "recorrente", "standby"] as const;
export const TRIAGE_LABEL: Record<string, string> = {
  backlog: "Backlog",
  planejada: "Planejada",
  recorrente: "Recorrente",
  standby: "Standby",
};

export const EXEC_STAGES = [
  "analise",
  "aguardando_gate_analise",
  "design",
  "aguardando_gate_design",
  "build",
  "aguardando_gate_build",
  "qa",
  "aguardando_homologacao",
  "release",
] as const;

export const STAGE_LABEL: Record<string, string> = {
  analise: "análise",
  aguardando_gate_analise: "gate: análise",
  design: "design",
  aguardando_gate_design: "gate: design (bloq.)",
  build: "build",
  aguardando_gate_build: "gate: PR",
  qa: "qa",
  aguardando_homologacao: "gate: homologação",
  release: "release",
};

export interface Pergunta {
  id: string;
  texto: string;
  resposta?: string;
}

export interface Aprovacao {
  aprovado: boolean;
  por: string;
  em: string;
  observacao?: string;
}

export function asPerguntas(value: unknown): Pergunta[] {
  return Array.isArray(value) ? (value as Pergunta[]) : [];
}

export function asAprovacao(value: unknown): Aprovacao | null {
  if (!value || typeof value !== "object") return null;
  return value as Aprovacao;
}

export function perguntasPendentes(perguntas: unknown): number {
  return asPerguntas(perguntas).filter((p) => !p.resposta?.trim()).length;
}

export function timeAgo(iso: string | Date | null | undefined): string {
  if (!iso) return "";
  const d = new Date(iso);
  const diff = (Date.now() - d.getTime()) / 1000;
  if (diff < 3600) return Math.max(1, Math.round(diff / 60)) + "min";
  if (diff < 86400) return Math.round(diff / 3600) + "h";
  return Math.round(diff / 86400) + "d";
}
