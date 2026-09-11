import { prisma } from "@/lib/prisma";
import type { MesDeHoras } from "@/lib/contrato";

// `ambientes` vem junto em ambas: a Visão Geral precisa dele pra listar
// conexão pendente, e a aba Conexões renderiza um card por ambiente.
export function getClients() {
  return prisma.client.findMany({
    orderBy: { nome: "asc" },
    include: { ambientes: true },
  });
}

export function getClientById(id: string) {
  return prisma.client.findUnique({
    where: { id },
    include: { ambientes: true, contrato: { include: { entregaveis: { orderBy: { ordem: "asc" } } } } },
  });
}

// Quantas demandas nasceram de cada entregável e quantas já foram entregues.
// Agregado no banco em vez de carregar as demandas todas: a aba Contrato só
// precisa dos dois números por linha.
export async function demandasPorEntregavel(clientId: string) {
  const linhas = await prisma.demanda.groupBy({
    by: ["entregavelId", "status"],
    where: { clientId, entregavelId: { not: null } },
    _count: { _all: true },
  });
  const mapa: Record<string, { total: number; entregues: number }> = {};
  for (const l of linhas) {
    if (!l.entregavelId) continue;
    const atual = (mapa[l.entregavelId] ??= { total: 0, entregues: 0 });
    atual.total += l._count._all;
    if (l.status === "entregue") atual.entregues += l._count._all;
  }
  return mapa;
}

// Só aqui o conteúdo do card vem junto: é a tela que abre o modal da demanda.
// getAllDemandas() alimenta a Visão Geral, que mostra só o resumo — carregar
// conversa, subtarefas e anexos de todas as demandas lá seria puxar o card
// inteiro de cada uma sem ninguém abrir nenhum.
export function getDemandasByClient(clientId: string) {
  return prisma.demanda.findMany({
    where: { clientId },
    orderBy: { criadoEm: "desc" },
    include: {
      comentarios: { orderBy: { criadoEm: "asc" } },
      subtarefas: { orderBy: { ordem: "asc" } },
      checklist: { orderBy: { ordem: "asc" } },
      tempos: { orderBy: { inicioEm: "desc" } },
      anexos: { orderBy: { criadoEm: "desc" } },
    },
  });
}

export function getAllDemandas() {
  return prisma.demanda.findMany({ orderBy: { criadoEm: "desc" } });
}

// O tipo que o modal (e tudo que passa a demanda pra ele) espera — definido
// a partir da query, e não à mão, pra que mudar o `include` acima quebre a
// compilação em vez de silenciosamente deixar um campo faltando na UI.
export type DemandaCompleta = Awaited<ReturnType<typeof getDemandasByClient>>[number];

function chaveMes(d: Date): string {
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

function mesAnterior(chave: string, passos: number): string {
  const [ano, mes] = chave.split("-").map(Number);
  const d = new Date(Date.UTC(ano, mes - 1 - passos, 1));
  return chaveMes(d);
}

/**
 * Horas lançadas por mês nas demandas do cliente, contra as contratadas.
 *
 * Agrupa por `inicioEm` e não por `criadoEm`: o que interessa é o mês em que o
 * trabalho aconteceu, não o mês em que alguém lembrou de lançar. Cronômetro
 * ainda rodando (`minutos` nulo) não entra — hora que não fechou não é hora
 * gasta, e somá-la faria o gráfico oscilar sozinho.
 *
 * Devolve sempre os últimos `meses` meses, inclusive os vazios: um mês sem
 * lançamento é informação (ninguém trabalhou, ou ninguém apontou), e sumir
 * com ele esconderia o buraco.
 */
export async function horasPorMes(clientId: string, meses = 6): Promise<MesDeHoras[]> {
  const contrato = await prisma.contrato.findUnique({
    where: { clientId },
    select: { horasContratadas: true },
  });
  const contratadas = contrato?.horasContratadas ?? 0;

  const agora = new Date();
  const primeiroMes = mesAnterior(chaveMes(agora), meses - 1);
  const [ano, mes] = primeiroMes.split("-").map(Number);
  const desde = new Date(Date.UTC(ano, mes - 1, 1));

  const registros = await prisma.registroTempo.findMany({
    where: {
      demanda: { clientId },
      fimEm: { not: null },
      inicioEm: { gte: desde },
    },
    select: { inicioEm: true, minutos: true },
  });

  const porMes = new Map<string, number>();
  for (const r of registros) {
    const k = chaveMes(r.inicioEm);
    porMes.set(k, (porMes.get(k) ?? 0) + (r.minutos ?? 0));
  }

  const saida: MesDeHoras[] = [];
  for (let i = meses - 1; i >= 0; i--) {
    const k = mesAnterior(chaveMes(agora), i);
    saida.push({
      mes: k,
      // Uma casa decimal: o gráfico é de acompanhamento, não de faturamento.
      horasGastas: Math.round(((porMes.get(k) ?? 0) / 60) * 10) / 10,
      horasContratadas: contratadas,
    });
  }
  return saida;
}
