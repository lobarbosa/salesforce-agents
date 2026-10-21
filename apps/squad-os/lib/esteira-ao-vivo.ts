import { prisma } from "@/lib/prisma";
import { runsAtivosDaEsteira } from "@/lib/github";

// Esteira ao vivo (2026-10-21): agrupa os eventos de /api/sync/evento por
// execução (runId) e responde "o que está rodando agora, em que agente, fazendo
// o quê". Só lê; quem decide estado continua sendo o git + /api/sync/demanda.

/** Sem evento há mais que isso e sem "fim": provável job morto (runner caiu, cancelado). */
export const SEM_SINAL_MS = 10 * 60 * 1000;
const JANELA_MS = 12 * 3600 * 1000;

// "sem_detalhe": o Actions diz que está rodando, mas a sessão não manda eventos
// (código anterior à esteira ao vivo, ou ainda instalando). "na_fila": aprovação
// esperando o cliente ficar livre (lib/fila-esteira.ts).
export type EstadoRun = "rodando" | "sem_detalhe" | "na_fila" | "sem_sinal" | "concluida" | "erro";

export interface EventoVisto {
  tipo: string;
  agente: string;
  ferramenta: string;
  detalhe: string;
  em: string;
}

export interface RunAoVivo {
  runId: string;
  runUrl: string;
  clientId: string;
  clientNome: string;
  clientSlug: string;
  demandaCode: string;
  /** Id interno, pra abrir o card direto (?demand=). */
  demandaId: string | null;
  etapa: string;
  estado: EstadoRun;
  inicioEm: string;
  ultimoEm: string;
  agenteAtual: string;
  agentes: string[];
  ferramentas: number;
  custoUsd: number | null;
  eventos: EventoVisto[];
}

export async function listarEsteiraAoVivo(opcoes: { comCusto: boolean }): Promise<RunAoVivo[]> {
  const desde = new Date(Date.now() - JANELA_MS);
  const linhas = await prisma.eventoEsteira.findMany({
    where: { em: { gte: desde } },
    orderBy: { em: "asc" },
    take: 5000,
    include: { client: { select: { nome: true, slug: true } } },
  });

  const porRun = new Map<string, typeof linhas>();
  for (const l of linhas) {
    const lista = porRun.get(l.runId) ?? [];
    lista.push(l);
    porRun.set(l.runId, lista);
  }

  const pares = [...new Set(linhas.filter((l) => l.demandaCode).map((l) => `${l.clientId}|${l.demandaCode}`))];
  const demandas = pares.length
    ? await prisma.demanda.findMany({
        where: { OR: pares.map((p) => ({ clientId: p.split("|")[0], code: p.split("|")[1] })) },
        select: { id: true, clientId: true, code: true },
      })
    : [];
  const idDaDemanda = new Map(demandas.map((d) => [`${d.clientId}|${d.code}`, d.id]));

  const agora = Date.now();
  const runs: RunAoVivo[] = [];
  for (const [runId, evs] of porRun) {
    const primeiro = evs[0];
    const ultimo = evs[evs.length - 1];
    const fim = evs.find((e) => e.tipo === "fim");
    const estado: EstadoRun = fim
      ? fim.detalhe === "erro" ? "erro" : "concluida"
      : agora - ultimo.em.getTime() > SEM_SINAL_MS ? "sem_sinal" : "rodando";
    const comAgente = evs.filter((e) => e.agente);
    const agentes = [...new Set(evs.filter((e) => e.tipo === "agente").map((e) => e.agente))];
    const custos = evs.map((e) => e.custoUsd).filter((c): c is number => c != null);
    runs.push({
      runId,
      runUrl: evs.find((e) => e.runUrl)?.runUrl ?? "",
      clientId: primeiro.clientId,
      clientNome: primeiro.client.nome,
      clientSlug: primeiro.client.slug,
      demandaCode: primeiro.demandaCode,
      demandaId: idDaDemanda.get(`${primeiro.clientId}|${primeiro.demandaCode}`) ?? null,
      etapa: primeiro.etapa,
      estado,
      inicioEm: primeiro.em.toISOString(),
      ultimoEm: ultimo.em.toISOString(),
      agenteAtual: comAgente.length ? comAgente[comAgente.length - 1].agente : "orquestrador",
      agentes,
      ferramentas: evs.filter((e) => e.tipo === "ferramenta").length,
      custoUsd: opcoes.comCusto && custos.length ? custos.reduce((a, b) => a + b, 0) : null,
      eventos: evs.slice(-25).reverse().map((e) => ({
        tipo: e.tipo,
        agente: e.agente,
        ferramenta: e.ferramenta,
        detalhe: e.detalhe,
        em: e.em.toISOString(),
      })),
    });
  }
  // O que o Actions diz que está ativo e não mandou nenhum evento ainda.
  const ativos = await runsAtivosDaEsteira().catch(() => []);
  const comEvento = new Set(runs.map((r) => r.runUrl).filter(Boolean));
  const clientes = await prisma.client.findMany({ select: { id: true, nome: true, slug: true } });
  const porSlug = new Map(clientes.map((c) => [c.slug, c]));
  const semEvento = ativos.filter((a) => !comEvento.has(a.url) && porSlug.has(a.clientSlug));
  const idsSemEvento = semEvento.length
    ? await prisma.demanda.findMany({
        where: { OR: semEvento.map((a) => ({ clientId: porSlug.get(a.clientSlug)!.id, code: a.demandaCode })) },
        select: { id: true, clientId: true, code: true, status: true },
      })
    : [];
  for (const a of semEvento) {
    const c = porSlug.get(a.clientSlug)!;
    const d = idsSemEvento.find((x) => x.clientId === c.id && x.code === a.demandaCode);
    const executando = a.status === "in_progress";
    runs.push({
      runId: a.url,
      runUrl: a.url,
      clientId: c.id,
      clientNome: c.nome,
      clientSlug: c.slug,
      demandaCode: a.demandaCode,
      demandaId: d?.id ?? null,
      etapa: d?.status ?? "",
      estado: executando ? "sem_detalhe" : "na_fila",
      inicioEm: a.criadoEm,
      ultimoEm: a.criadoEm,
      agenteAtual: "",
      agentes: [],
      ferramentas: 0,
      custoUsd: null,
      eventos: [],
    });
  }

  // Fila do Squad OS: aprovado, esperando o cliente ficar livre.
  const fila = await prisma.disparoEsteira.findMany({
    where: { disparadoEm: null, concluidoEm: null },
    orderBy: { criadoEm: "asc" },
    include: { client: { select: { nome: true, slug: true } }, demanda: { select: { code: true } } },
  });
  for (const f of fila) {
    runs.push({
      runId: `fila-${f.id}`,
      runUrl: "",
      clientId: f.clientId,
      clientNome: f.client.nome,
      clientSlug: f.client.slug,
      demandaCode: f.demanda.code,
      demandaId: f.demandaId,
      etapa: f.tipo === "aprovar" ? f.gate : "envio para a esteira",
      estado: "na_fila",
      inicioEm: f.criadoEm.toISOString(),
      ultimoEm: f.criadoEm.toISOString(),
      agenteAtual: "",
      agentes: [],
      ferramentas: 0,
      custoUsd: null,
      eventos: f.autor ? [{ tipo: "fila", agente: "", ferramenta: "", detalhe: `aprovado por ${f.autor}${f.nota ? ` — ${f.nota}` : ""}`, em: f.criadoEm.toISOString() }] : [],
    });
  }

  // Rodando primeiro; depois fila; depois o mais recente.
  const ordem: Record<EstadoRun, number> = { rodando: 0, sem_detalhe: 1, na_fila: 2, sem_sinal: 3, erro: 4, concluida: 5 };
  return runs.sort(
    (a, b) =>
      ordem[a.estado] - ordem[b.estado] ||
      (a.estado === "na_fila" ? a.inicioEm.localeCompare(b.inicioEm) : b.ultimoEm.localeCompare(a.ultimoEm))
  );
}
