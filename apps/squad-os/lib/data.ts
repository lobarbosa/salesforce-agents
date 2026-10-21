import { prisma } from "@/lib/prisma";
import { mesAnterior, montarHorasPorMes, type MesDeHoras } from "@/lib/contrato";
import { chaveDia, cicloDoMes } from "@/lib/horas";
import { calibracaoPara, type Calibracao, type EstimativaCalibrada } from "@/lib/estimativa";

// `ambientes` vem junto em ambas: a Visão Geral precisa dele pra listar
// conexão pendente, e a aba Conexões renderiza um card por ambiente.
//
// Só clientes ativos: encerrado sai da sidebar, da Visão Geral e de todo
// seletor (lib/encerramento.ts). Quem precisa dele é o admin, pela lista de
// encerrados abaixo — e as telas de /financeiro, que leem o histórico direto.
export function getClients() {
  return prisma.client.findMany({
    where: { encerradoEm: null },
    orderBy: { nome: "asc" },
    include: { ambientes: true },
  });
}

/** Encerrados, mais recente primeiro — só para o admin (seção "Encerrados"). */
export function getClientesEncerrados() {
  return prisma.client.findMany({
    where: { encerradoEm: { not: null } },
    orderBy: { encerradoEm: "desc" },
    select: { id: true, nome: true, encerradoEm: true, encerradoPorEmail: true, motivoEncerramento: true },
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
      // Fila de disparo (lib/fila-esteira.ts): só o que está aberto importa pro card.
      disparos: {
        where: { concluidoEm: null },
        select: { tipo: true, gate: true, autor: true, disparadoEm: true, concluidoEm: true },
      },
    },
  });
}

export function getAllDemandas() {
  return prisma.demanda.findMany({ orderBy: { criadoEm: "desc" } });
}

// O tipo que o modal (e tudo que passa a demanda pra ele) espera — definido
// a partir da query, e não à mão, pra que mudar o `include` acima quebre a
// compilação em vez de silenciosamente deixar um campo faltando na UI.
export type DemandaCompleta = Awaited<ReturnType<typeof getDemandasByClient>>[number] & {
  /** Calculada na página (consultor calibrado pelo timesheet + agente). */
  estimativaCalibrada?: EstimativaCalibrada | null;
  /** Pré-preenchimento do campo do consultor (sugestão do agente calibrada). */
  sugestaoConsultorHoras?: number | null;
};

/**
 * Fator de calibração das estimativas de horas, pelo timesheet das demandas
 * já entregues que tinham estimativa (lib/estimativa.ts explica a regra).
 * Lê todos os clientes de propósito — o fator geral é o fallback de quem
 * ainda não tem histórico — mas devolve só um número, nada de outro cliente
 * chega à tela (guardrail #7).
 */
export async function fatorDeCalibracao(clientId: string): Promise<Calibracao> {
  // Mede o que o agente SUGERIU contra o que se lançou: é a sugestão que a
  // calibração corrige. A estimativa do consultor fica fora da régua — ela já
  // é a correção humana, e calibrar com ela o fator se anularia.
  const entregues = await prisma.demanda.findMany({
    where: { status: "entregue", estimativaHorasMin: { not: null }, estimativaHorasMax: { not: null } },
    select: {
      clientId: true,
      estimativaHorasMin: true,
      estimativaHorasMax: true,
      tempos: { where: { fimEm: { not: null } }, select: { minutos: true } },
    },
  });
  return calibracaoPara(
    clientId,
    entregues.map((d) => ({
      clientId: d.clientId,
      estimativaMin: d.estimativaHorasMin!,
      estimativaMax: d.estimativaHorasMax!,
      lancadoMin: d.tempos.reduce((s, t) => s + (t.minutos ?? 0), 0),
    }))
  );
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
    select: { horasContratadas: true, cicloHoras: true },
  });
  const ciclo = contrato?.cicloHoras ?? "mensal";
  const agora = new Date();
  // Desde o início do CICLO do primeiro mês mostrado (no trimestral, até dois
  // meses antes): o acumulado do ciclo precisa dos meses anteriores dele.
  const primeiroMes = mesAnterior(chaveDia(agora).slice(0, 7), meses - 1);
  const desde = cicloDoMes(primeiroMes, ciclo).desde;

  // Demanda que entrou em build com estimativa aprovada debita a ESTIMATIVA,
  // no mês em que entrou (2026-10-21) — o timesheet dela mede desvio, não
  // debita de novo. As demais (sem aprovação, anteriores à regra) seguem pelo
  // timesheet, como sempre.
  const registros = await prisma.registroTempo.findMany({
    where: {
      demanda: { clientId, estimativaDebitadaEm: null },
      fimEm: { not: null },
      inicioEm: { gte: desde },
    },
    select: { inicioEm: true, minutos: true },
  });
  const debitos = await prisma.demanda.findMany({
    where: { clientId, estimativaDebitadaEm: { gte: desde }, estimativaDebitadaHoras: { not: null } },
    select: { estimativaDebitadaEm: true, estimativaDebitadaHoras: true },
  });
  for (const d of debitos) {
    registros.push({ inicioEm: d.estimativaDebitadaEm!, minutos: Math.round(d.estimativaDebitadaHoras! * 60) });
  }

  return montarHorasPorMes(registros, contrato?.horasContratadas ?? 0, ciclo, agora, meses);
}
