// Constantes e helpers de exibição pra demanda — sem Prisma, importável de
// Server e Client Components. Espelha STAGES_TRIAGEM/STAGES_EXECUCAO de
// src/salesforce_agents/demands.py.

export const TRIAGE = ["backlog", "planejada", "recorrente", "standby"] as const;
export const TRIAGE_LABEL: Record<string, string> = {
  backlog: "Backlog",
  planejada: "Planejada",
  recorrente: "Recorrente",
  standby: "Congelada",
};

// Encerrada sem entrega (src/salesforce_agents/demands.py STAGES_ENCERRADOS).
export const ENCERRADOS = ["cancelada"] as const;

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
  aguardando_gate_build: "revisão do PR",
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
  // Congelada não entra: ela sai do quadro para a faixa "Congeladas" (DemandasTab).
  // Misturada ao Backlog, uma demanda segurada pelo cliente parecia nova.
  { chave: "triagem", titulo: "Backlog", estagios: ["backlog", "planejada", "recorrente"] },
  { chave: "analise", titulo: "Análise", estagios: ["analise", "aguardando_gate_analise"] },
  { chave: "design", titulo: "Design", estagios: ["design", "aguardando_gate_design"] },
  // "Build" lia como "liberar para construir" — mas card parado aqui já foi
  // construído e espera a revisão do PR. Quem libera a construção é o design.
  { chave: "build", titulo: "Construção", estagios: ["build", "aguardando_gate_build"] },
  { chave: "qa", titulo: "QA", estagios: ["qa"] },
  // A homologação é o único gate do cliente; dividindo coluna com QA e release
  // (do agente) ela sumia. Release fica junto: é o que acontece logo depois.
  { chave: "homologacao", titulo: "Homologação", estagios: ["aguardando_homologacao", "release"] },
  // Cancelada fica junto da entregue: as duas saíram da esteira.
  { chave: "entregue", titulo: "Entregue / cancelada", estagios: ["entregue", ...ENCERRADOS] },
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

/** Há um agente trabalhando nesta demanda agora — ou seja, o estado vai mudar
 *  sozinho e a tela precisa ficar olhando.
 *
 *  É o complemento de `estaEmGate` dentro da execução: etapa de execução que
 *  não é gate é etapa rodando. Triagem e `entregue` ficam de fora porque ali
 *  nada acontece sem alguém clicar — e um quadro que fica recarregando à toa
 *  gasta conexão do pool sem trazer novidade nenhuma. */
export function agenteRodando(status: string): boolean {
  return (EXEC_STAGES as readonly string[]).includes(status) && !estaEmGate(status);
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

export type EstadoCliente = "recebida" | "andamento" | "voce" | "entregue" | "pausada" | "cancelada";

export const ESTADOS_CLIENTE = ["recebida", "andamento", "voce", "entregue", "pausada", "cancelada"] as const;

export const ESTADO_CLIENTE_LABEL: Record<EstadoCliente, string> = {
  recebida: "Recebida",
  andamento: "Em andamento",
  voce: "Precisa da sua aprovação",
  entregue: "Entregue",
  pausada: "Pausada",
  cancelada: "Cancelada",
};

// O único gate da esteira que o papel `cliente` aprova.
export const GATE_DO_CLIENTE = "aguardando_homologacao";

/** Quem aprova este gate — e, por consequência, o que ele enxerga dele.
 *
 * `aguardando_homologacao` é o cliente aceitando o que foi entregue: é dele
 * esse gate. Os outros (análise, design, PR) são internos de delivery.
 *
 * Mora aqui, e não em lib/auth.ts, porque este módulo não importa Prisma e
 * por isso atravessa Server e Client Component — a tela e a API precisam
 * responder isto pelo mesmo lugar. Quando a resposta vivia solta em cada
 * ponta, a tela escondia o artefato do gate de quem podia aprová-lo e a API
 * deixava o cliente responder pergunta de gate que não é dele.
 *
 * Recebe o booleano de "pode gerenciar" em vez do papel para não arrastar
 * lib/auth.ts (e o Prisma junto) para dentro do bundle do browser.
 */
export function podeAprovarGate(podeGerenciar: boolean, status: string): boolean {
  if (!status.startsWith("aguardando_")) return false;
  return podeGerenciar || status === GATE_DO_CLIENTE;
}

export function estadoDoCliente(status: string): EstadoCliente {
  if (status === GATE_DO_CLIENTE) return "voce";
  if (status === "entregue") return "entregue";
  if (status === "cancelada") return "cancelada";
  if (status === "standby") return "pausada";
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

// Os nomes que o cliente reconhece para cada fase — sem "design" (que soa
// como tela) e sem "gate".
const NOMES_FASES_CLIENTE = ["Entendimento", "Solução", "Construção", "Testes e entrega"];

export interface ProgressoDemanda {
  fase: number;
  total: number;
  rotulo: string;
  nome: string;
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
  return {
    fase: i + 1,
    total: FASES_CLIENTE.length,
    rotulo: `etapa ${i + 1} de ${FASES_CLIENTE.length}`,
    nome: NOMES_FASES_CLIENTE[i],
  };
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

/**
 * As perguntas do gate vêm do agente (sync de volta, `/api/sync/demanda`); o
 * card só responde. Por isso o PATCH nunca aceita a lista do navegador como
 * está: parte das perguntas atuais e copia só a `resposta` de cada id que já
 * existe. Pergunta nova, texto trocado ou id inventado são ignorados.
 */
export const RESPOSTA_MAX = 4000;
export function mesclarRespostas(atuais: unknown, enviadas: unknown): Pergunta[] | null {
  if (!Array.isArray(enviadas)) return null;
  const respostas = new Map<string, string>();
  for (const p of enviadas) {
    if (!p || typeof p !== "object") continue;
    const { id, resposta } = p as Record<string, unknown>;
    if (typeof id === "string" && typeof resposta === "string") respostas.set(id, resposta.slice(0, RESPOSTA_MAX));
  }
  return asPerguntas(atuais)
    .filter((p) => p && typeof p.id === "string")
    .map((p) => (respostas.has(p.id) ? { ...p, resposta: respostas.get(p.id)! } : p));
}

/**
 * A aprovação registrada no card é montada no servidor: `aprovado` é sempre
 * true (não existe "desaprovar" por aqui), a data é a do servidor e o e-mail
 * de quem aprovou vem da sessão. Do navegador só entram o nome digitado e a
 * observação, com tamanho limitado.
 */
export function montarAprovacao(
  enviada: unknown,
  quem: { nome: string; email: string },
  agora = new Date()
): (Aprovacao & { porEmail: string }) | null {
  if (!enviada || typeof enviada !== "object") return null;
  const a = enviada as Record<string, unknown>;
  if (a.aprovado !== true) return null;
  const digitado = typeof a.por === "string" ? a.por.trim().slice(0, 120) : "";
  return {
    aprovado: true,
    por: digitado || quem.nome.trim() || quem.email,
    porEmail: quem.email,
    em: agora.toISOString(),
    observacao: typeof a.observacao === "string" ? a.observacao.trim().slice(0, 1000) : "",
  };
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

// Onde dá pra parar (congelar/cancelar) uma demanda: triagem ou gate humano —
// nunca com etapa de agente rodando. Mesma lista na API (/ciclo), no card e
// no arrastar do quadro.
export const ESTAGIOS_PARAVEIS: readonly string[] = [
  "backlog",
  "planejada",
  "recorrente",
  "aguardando_gate_analise",
  "aguardando_gate_design",
  "aguardando_gate_build",
  "aguardando_homologacao",
];

export function podeCancelar(status: string): boolean {
  return ESTAGIOS_PARAVEIS.includes(status) || status === "standby";
}

/** Por que soltar o card nesta fase não faz nada — ou null se faz. */
export function motivoSemDrop(
  d: { status: string; materializadoEm: Date | string | null },
  faseDestino: string
): string | null {
  if (faseDestino === "analise") {
    if (d.status !== "backlog") return "só demanda no backlog vai para a esteira";
    if (d.materializadoEm) return "esta demanda já foi enviada para a esteira";
    return null;
  }
  if (faseDestino === "entregue") {
    return podeCancelar(d.status) ? null : "há uma etapa de agente rodando — espere o gate para cancelar";
  }
  return "as etapas da esteira só avançam pela aprovação do gate";
}

// Rastro que /api/demandas/[id]/aprovar-gate deixa ao liberar um gate — é ele
// a reivindicação contra o segundo clique. O status só muda quando a execução
// sincroniza de volta (minutos), então até lá a tela pergunta por aqui.
export function marcadorDeGate(gate: string): string {
  return `Aprovou o gate "${gate}".`;
}

/**
 * Quem já liberou o gate atual e se ainda está na fila — lido da fila de
 * disparo (DisparoEsteira, lib/fila-esteira.ts), a mesma que a API usa como
 * reivindicação. `naFila`: esperando o cliente ficar livre; senão, rodando.
 */
export function gateLiberadoPor(d: {
  status: string;
  disparos?: { tipo: string; gate: string; autor: string; disparadoEm: Date | string | null; concluidoEm: Date | string | null }[];
}): { autor: string; naFila: boolean } | null {
  if (!d.status.startsWith("aguardando_")) return null;
  const aberto = (d.disparos ?? []).find((x) => x.tipo === "aprovar" && x.gate === d.status && !x.concluidoEm);
  return aberto ? { autor: aberto.autor, naFila: !aberto.disparadoEm } : null;
}

// Aprovação da estimativa pelo cliente (2026-10-21). O cliente aprova (ou
// segura) a estimativa oficial do consultor depois da análise e antes do
// build; sem aprovação válida o gate de design não libera o build.
export const ESTAGIOS_APROVACAO_ESTIMATIVA: readonly string[] = [
  "aguardando_gate_analise",
  "design",
  "aguardando_gate_design",
];

/** A aprovação existe e é do número que está no card agora. */
export function estimativaAprovada(d: {
  estimativaConsultorHoras: number | null;
  estimativaAprovadaHoras: number | null;
}): boolean {
  return d.estimativaConsultorHoras != null && d.estimativaAprovadaHoras === d.estimativaConsultorHoras;
}

/** O cliente pode decidir sobre a estimativa agora? (inclui a segurada por ele) */
export function aguardaAprovacaoEstimativa(d: {
  status: string;
  congeladaDe?: string | null;
  estimativaConsultorHoras: number | null;
  estimativaAprovadaHoras: number | null;
}): boolean {
  if (d.estimativaConsultorHoras == null || estimativaAprovada(d)) return false;
  const etapa = d.status === "standby" ? d.congeladaDe ?? "" : d.status;
  return ESTAGIOS_APROVACAO_ESTIMATIVA.includes(etapa);
}

// --- Quem age agora (2026-10-29) --------------------------------------------
//
// A coluna diz a fase; não diz se o card está andando ou parado, nem quem
// destrava. Achado real: "gate de build" lido como "liberar a construção",
// cliente sem saber que era a vez dele, design esperando o arquiteto parecendo
// igual a design esperando o cliente aprovar as horas. Esta é a resposta
// única, usada pelo card, pelos filtros e pela visão do cliente.

export type QuemAge = "agente" | "time" | "cliente" | "fila" | "congelada";

export interface AcaoPendente {
  quem: QuemAge;
  /** O que falta, em poucas palavras ("aprovar design", "homologar"). */
  oque: string;
}

interface DemandaParaQuemAge {
  status: string;
  congeladaDe?: string | null;
  estimativaConsultorHoras: number | null;
  estimativaAprovadaHoras: number | null;
  disparos?: { tipo: string; gate: string; disparadoEm: Date | string | null; concluidoEm: Date | string | null; nota?: string }[];
}

const OQUE_DO_GATE: Record<string, string> = {
  aguardando_gate_analise: "aprovar análise",
  aguardando_gate_design: "aprovar design",
  aguardando_gate_build: "revisar PR",
  aguardando_homologacao: "homologar",
};

/** Quem precisa agir agora — pode ser mais de um (design: arquiteto E cliente nas horas). */
export function acoesPendentes(d: DemandaParaQuemAge): AcaoPendente[] {
  if (d.status === "standby") return [{ quem: "congelada", oque: "congelada" }];
  if (d.status === "entregue" || d.status === "cancelada") return [];

  const aberto = (d.disparos ?? []).find((x) => !x.concluidoEm);
  if (aberto && aberto.disparadoEm) return [{ quem: "agente", oque: "rodando" }];
  if (agenteRodando(d.status)) return [{ quem: "agente", oque: "rodando" }];

  const acoes: AcaoPendente[] = [];
  if (aberto) {
    acoes.push({ quem: "fila", oque: "na fila" });
  } else if (estaEmGate(d.status)) {
    acoes.push({
      quem: d.status === GATE_DO_CLIENTE ? "cliente" : "time",
      oque: OQUE_DO_GATE[d.status] ?? "aprovar",
    });
  }
  if (aguardaAprovacaoEstimativa(d)) acoes.push({ quem: "cliente", oque: "aprovar horas" });
  return acoes;
}

export const QUEM_AGE_LABEL: Record<QuemAge, string> = {
  agente: "Agente",
  time: "Time",
  cliente: "Cliente",
  fila: "Na fila",
  congelada: "Congelada",
};

// --- O mesmo, dito para o cliente ------------------------------------------

/** Estado do cliente considerando a estimativa: aprovar horas também é a vez dele. */
export function estadoDoClienteDemanda(d: DemandaParaQuemAge): EstadoCliente {
  const porStatus = estadoDoCliente(d.status);
  if (porStatus === "andamento" && aguardaAprovacaoEstimativa(d)) return "voce";
  return porStatus;
}

/** Uma frase do que está acontecendo, sem jargão de esteira. */
export function situacaoParaCliente(d: DemandaParaQuemAge): string {
  const acoes = acoesPendentes(d);
  if (d.status === GATE_DO_CLIENTE) return "Sua vez: conferir a entrega e homologar";
  if (acoes.some((a) => a.quem === "cliente" && a.oque === "aprovar horas")) return "Sua vez: aprovar a estimativa de horas";
  if (d.status === "release") return "Liberando a entrega";
  if (acoes.some((a) => a.quem === "agente")) return "Equipe trabalhando agora";
  if (acoes.some((a) => a.quem === "fila")) return "Na fila para começar";
  if (estaEmGate(d.status)) return "Em revisão pela equipe";
  if ((TRIAGE as readonly string[]).includes(d.status) && d.status !== "standby") return "Recebida, aguardando a equipe";
  return "";
}
