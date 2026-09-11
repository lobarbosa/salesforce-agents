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

// --- As fases da esteira, que são as colunas do quadro interno -------------
//
// O quadro dava **quatro colunas para a triagem** (backlog/planejada/
// recorrente/standby) e **uma só para as nove etapas de execução**, chamada
// "Em execução". Ou seja: quatro colunas para decidir se algo vira trabalho, e
// uma para o trabalho inteiro acontecer. A doutrina — 7 etapas, 4 gates
// bloqueantes, quem espera quem — ficava invisível justamente na tela que
// existe para mostrá-la.
//
// A correção não é acrescentar colunas: o quadro já rola na horizontal com
// 240px por coluna, e "evitar rolagem horizontal" é regra de severidade alta.
// É **redistribuir** — a triagem inteira colapsa em uma, e as cinco que sobram
// vão para onde o trabalho acontece. Mesmo número de colunas, outra informação.
//
// Gate não vira coluna. Gate é uma *parada dentro* da fase: a demanda continua
// em Design, só que travada esperando gente. Coluna própria para gate sugeriria
// que a demanda saiu da fase, e dobraria a largura do quadro.

export interface FaseDoQuadro {
  chave: string;
  titulo: string;
  /** Estágios de `demands.py` que caem nesta coluna. */
  estagios: readonly string[];
}

export const FASES: readonly FaseDoQuadro[] = [
  { chave: "triagem", titulo: "Backlog", estagios: TRIAGE },
  { chave: "analise", titulo: "Análise", estagios: ["analise", "aguardando_gate_analise"] },
  { chave: "design", titulo: "Design", estagios: ["design", "aguardando_gate_design"] },
  { chave: "build", titulo: "Build", estagios: ["build", "aguardando_gate_build"] },
  { chave: "qa", titulo: "QA e entrega", estagios: ["qa", "aguardando_homologacao", "release"] },
  { chave: "entregue", titulo: "Entregue", estagios: ["entregue"] },
];

export function faseDoEstagio(status: string): FaseDoQuadro | null {
  return FASES.find((f) => f.estagios.includes(status)) ?? null;
}

/** Quem precisa agir para a demanda sair da parada — vazio quando ela está andando. */
export function quemDestrava(status: string): string {
  switch (status) {
    case "aguardando_gate_analise":
      return "consultor";
    case "aguardando_gate_design":
      return "arquiteto";
    case "aguardando_gate_build":
      return "revisor do PR";
    case "aguardando_homologacao":
      return "cliente";
    default:
      return "";
  }
}

export function estaEmGate(status: string): boolean {
  return status.startsWith("aguardando_");
}

// --- A mesma esteira, dita para quem está do lado de fora ------------------
//
// `aguardando_gate_design` é vocabulário de quem opera a esteira. Para o
// cliente, é ruído: ele não sabe o que é um gate, e a palavra "design" o faz
// pensar em tela. Pior, os três gates internos parecem pedir uma ação dele —
// e só um dos quatro é dele de verdade.
//
// Quatro estados, e a pergunta que cada um responde:
//   recebida  — "chegou?"
//   andamento — "estão trabalhando?"
//   voce      — "preciso fazer alguma coisa?"   ← o único que pede ação dele
//   entregue  — "acabou?"
//
// Não é simplificação por estética: um cliente que não distingue "esperando a
// Acxya" de "esperando você" ou não age quando devia, ou cobra o que não é seu.

export type EstadoCliente = "recebida" | "andamento" | "voce" | "entregue";

export const ESTADOS_CLIENTE = ["recebida", "andamento", "voce", "entregue"] as const;

export const ESTADO_CLIENTE_LABEL: Record<EstadoCliente, string> = {
  recebida: "Recebida",
  andamento: "Em andamento",
  voce: "Precisa da sua aprovação",
  entregue: "Entregue",
};

// O único gate da esteira que o papel `cliente` aprova — a mesma constante que
// a rota /api/demandas/[id]/aprovar-gate usa pra decidir quem pode aprovar.
const GATE_DO_CLIENTE = "aguardando_homologacao";

export function estadoDoCliente(status: string): EstadoCliente {
  if (status === GATE_DO_CLIENTE) return "voce";
  if (status === "entregue") return "entregue";
  if ((TRIAGE as readonly string[]).includes(status)) return "recebida";
  return "andamento";
}

// As quatro fases que o cliente reconhece como progresso. Os gates internos
// somem porque não são fases do trabalho dele: são pontos de controle nossos.
const FASES_CLIENTE = [
  ["analise", "aguardando_gate_analise"],
  ["design", "aguardando_gate_design"],
  ["build", "aguardando_gate_build"],
  ["qa", "aguardando_homologacao", "release"],
];

export interface ProgressoDemanda {
  fase: number;
  total: number;
  rotulo: string;
}

/**
 * "Etapa 3 de 4" para uma demanda em execução, ou null fora dela.
 *
 * Estado sem progresso deixa o cliente sem saber se "em andamento" é o
 * primeiro dia ou o último — que é justamente a informação que ele quer.
 */
export function progressoDaDemanda(status: string): ProgressoDemanda | null {
  const i = FASES_CLIENTE.findIndex((fase) => fase.includes(status));
  if (i < 0) return null;
  return { fase: i + 1, total: FASES_CLIENTE.length, rotulo: `etapa ${i + 1} de ${FASES_CLIENTE.length}` };
}

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

// Minutos viram "1h20" em vez de "80min" a partir de uma hora: é como a
// pessoa fala do próprio tempo, e a lista de lançamentos fica comparável de
// relance.
export function formatarMinutos(total: number): string {
  const m = Math.max(0, Math.round(total));
  if (m < 60) return `${m}min`;
  const horas = Math.floor(m / 60);
  const resto = m % 60;
  return resto === 0 ? `${horas}h` : `${horas}h${String(resto).padStart(2, "0")}`;
}

// Tamanho de anexo em unidade legível — o número cru em bytes não ajuda
// ninguém a decidir se vale baixar.
export function formatarTamanho(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}
