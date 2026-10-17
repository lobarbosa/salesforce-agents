import { prisma } from "@/lib/prisma";
import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";
import { chaveDia } from "@/lib/horas";
import {
  aGerar,
  avulsaParaVincular,
  chaveOcorrencia,
  MAX_POR_PASSADA,
  somaMeses,
  type AvulsaCandidata,
  EMAIL_RECORRENCIA,
  encerrado,
  equivalenteMensal,
  proximaCompetencia,
  type DadosModelo,
  type ModeloParaRegra,
} from "@/lib/recorrencias";

// Acesso a banco das despesas recorrentes. Regras em lib/recorrencias.ts.

export interface ModeloVisto {
  id: string;
  fornecedor: string;
  descricao: string;
  categoria: string;
  valor: number;
  valorVariavel: boolean;
  periodicidade: Periodicidade;
  diaVencimento: number;
  inicio: string; // 'YYYY-MM'
  fim: string | null; // 'YYYY-MM'
  ativa: boolean;
  encerrada: boolean;
  natureza: NaturezaCusto;
  clientId: string | null;
  clientNome: string | null;
  equivalenteMensal: number;
  proxima: { competencia: string; vencimento: string } | null;
  contasGeradas: number;
  criadoPorEmail: string;
}

const dia = (d: Date) => d.toISOString().slice(0, 10);

type LinhaModelo = Awaited<ReturnType<typeof prisma.despesaRecorrente.findFirstOrThrow>>;

function paraRegra(m: LinhaModelo): ModeloParaRegra {
  return {
    periodicidade: m.periodicidade,
    diaVencimento: m.diaVencimento,
    inicioEm: dia(m.inicioEm),
    fimEm: m.fimEm ? dia(m.fimEm) : null,
  };
}

export async function listarModelos(hoje = chaveDia(new Date())): Promise<ModeloVisto[]> {
  const linhas = await prisma.despesaRecorrente.findMany({
    include: { client: { select: { nome: true } }, _count: { select: { contas: true } } },
    orderBy: [{ ativa: "desc" }, { fornecedor: "asc" }],
  });
  return linhas.map((m) => {
    const regra = paraRegra(m);
    const valor = Number(m.valor);
    const fim = regra.fimEm;
    return {
      id: m.id,
      fornecedor: m.fornecedor,
      descricao: m.descricao,
      categoria: m.categoria,
      valor,
      valorVariavel: m.valorVariavel,
      periodicidade: m.periodicidade,
      diaVencimento: m.diaVencimento,
      inicio: regra.inicioEm.slice(0, 7),
      fim: fim?.slice(0, 7) ?? null,
      ativa: m.ativa,
      encerrada: encerrado(fim, hoje),
      natureza: m.natureza,
      clientId: m.clientId,
      clientNome: m.client?.nome ?? null,
      equivalenteMensal: equivalenteMensal(valor, m.periodicidade),
      proxima: m.ativa ? proximaCompetencia(regra, hoje) : null,
      contasGeradas: m._count.contas,
      criadoPorEmail: m.criadoPorEmail,
    };
  });
}

function ehUnicaViolada(e: unknown): boolean {
  return !!e && typeof e === "object" && (e as { code?: unknown }).code === "P2002";
}

export interface ResultadoGeracao {
  /** Contas novas criadas (inclui as retroativas). */
  criadas: number;
  /** Das criadas, quantas com vencimento já passado. */
  retroativas: number;
  /** Contas avulsas já lançadas que viraram a ocorrência da competência. */
  vinculadas: number;
  falhas: number;
  /** Modelos que bateram no freio de MAX_POR_PASSADA (continuam na próxima passada). */
  limitadas: { modeloId: string; faltando: number }[];
}

/**
 * Garante uma conta por competência devida (lib/recorrencias.ts:
 * competenciasDevidas — retroativo desde o início do modelo) dos modelos
 * ativos. Para cada competência que falta: se existe conta AVULSA do mesmo
 * fornecedor com vencimento naquele mês (lançada antes do modelo existir),
 * ela é vinculada em vez de duplicada; senão a conta é criada, aguardando
 * aprovação. Idempotente: o unique (recorrencia_id, competencia) do banco é
 * quem garante — cron e carga de página podem rodar ao mesmo tempo, e o
 * perdedor recebe P2002, que aqui só quer dizer "já existe".
 */
export async function gerarContasRecorrentes(
  hoje = chaveDia(new Date()),
  filtro: { modeloId?: string } = {}
): Promise<ResultadoGeracao> {
  const r: ResultadoGeracao = { criadas: 0, retroativas: 0, vinculadas: 0, falhas: 0, limitadas: [] };
  const linhas = await prisma.despesaRecorrente.findMany({
    where: { ativa: true, ...(filtro.modeloId ? { id: filtro.modeloId } : {}) },
  });
  const modelos = linhas.map((linha) => ({ ...paraRegra(linha), id: linha.id, ativa: linha.ativa, linha }));
  if (!aGerar(modelos, new Set(), hoje, Infinity).itens.length) return r;

  // O que já existe destes modelos (uma consulta); o unique segura a corrida.
  const existentes = await prisma.contaPagar.findMany({
    where: { recorrenciaId: { in: modelos.map((m) => m.id) } },
    select: { recorrenciaId: true, competencia: true },
  });
  const { itens, limitados } = aGerar(
    modelos,
    new Set(existentes.map((e) => chaveOcorrencia(e.recorrenciaId!, e.competencia!))),
    hoje
  );
  r.limitadas = limitados;
  for (const l of limitados) {
    console.warn(`recorrências: ${l.modeloId} bateu no freio de ${MAX_POR_PASSADA}; faltam ${l.faltando} para a próxima passada`);
  }
  if (!itens.length) return r;

  // Avulsas que podem ser a ocorrência de alguma competência pendente.
  const comps = itens.map((i) => i.competencia).sort();
  const candidatas: AvulsaCandidata[] = (
    await prisma.contaPagar.findMany({
      where: {
        recorrenciaId: null,
        status: { notIn: ["cancelada", "recusada"] },
        vencimento: {
          gte: new Date(`${comps[0]}-01T00:00:00Z`),
          lt: new Date(`${somaMeses(comps[comps.length - 1], 1)}-01T00:00:00Z`),
        },
      },
      select: { id: true, fornecedor: true, vencimento: true, valor: true, status: true, natureza: true, clientId: true },
    })
  ).map((c) => ({ ...c, vencimento: dia(c.vencimento), valor: Number(c.valor) }));
  const porId = new Map(candidatas.map((c) => [c.id, c]));
  const usadas = new Set<string>();

  for (const { modelo, competencia, vencimento } of itens) {
    const m = modelo.linha;
    const avulsaId = avulsaParaVincular(candidatas, m.fornecedor, competencia, Number(m.valor), usadas);
    try {
      if (avulsaId) {
        usadas.add(avulsaId);
        const a = porId.get(avulsaId) as (typeof candidatas)[number] & { natureza: NaturezaCusto | null; clientId: string | null };
        const ligou = await prisma.$transaction(async (tx) => {
          const { count } = await tx.contaPagar.updateMany({
            where: { id: avulsaId, recorrenciaId: null },
            data: {
              recorrenciaId: m.id,
              competencia,
              // Classificação do modelo só onde a conta não tem a própria.
              ...(a.natureza ? {} : { natureza: m.natureza }),
              ...(a.clientId ? {} : { clientId: m.clientId }),
            },
          });
          if (count === 0) return false;
          await tx.eventoConta.create({
            data: {
              contaId: avulsaId,
              acao: "recorrente",
              porEmail: EMAIL_RECORRENCIA,
              comentario: `vinculada à recorrência ${m.id} (competência ${competencia})`,
            },
          });
          return true;
        });
        if (ligou) {
          r.vinculadas++;
          continue;
        }
        // Outra passada vinculou essa conta no meio do caminho: segue e cria.
      }
      const retroativa = vencimento < hoje;
      await prisma.$transaction(async (tx) => {
        const c = await tx.contaPagar.create({
          data: {
            fornecedor: m.fornecedor,
            descricao: m.descricao,
            categoria: m.categoria,
            valor: m.valor,
            vencimento: new Date(`${vencimento}T00:00:00Z`),
            lancadoPorEmail: EMAIL_RECORRENCIA,
            recorrenciaId: m.id,
            competencia,
            natureza: m.natureza,
            clientId: m.clientId,
          },
        });
        await tx.eventoConta.create({
          data: {
            contaId: c.id,
            acao: "lancada",
            porEmail: EMAIL_RECORRENCIA,
            comentario:
              `gerada pela recorrência ${m.id}` +
              (retroativa ? ` (retroativa, competência ${competencia})` : "") +
              (m.valorVariavel ? " — valor estimado, confirmar" : ""),
          },
        });
      });
      r.criadas++;
      if (retroativa) r.retroativas++;
    } catch (e) {
      if (ehUnicaViolada(e)) continue;
      r.falhas++;
      console.error(`recorrências: falha ao gerar ${m.id} ${competencia}`, e);
    }
  }
  return r;
}

// Na carga de /financeiro/contas e /financeiro/recorrentes: garante as contas
// mesmo sem o cron configurado. Barato (uma consulta quando nada é devido) e
// com freio por instância, para não refazer a cada navegação.
let ultimaGeracao = 0;
const INTERVALO_MS = 5 * 60_000;

export async function gerarSeNecessario(): Promise<void> {
  if (Date.now() - ultimaGeracao < INTERVALO_MS) return;
  ultimaGeracao = Date.now();
  try {
    await gerarContasRecorrentes();
  } catch (e) {
    // Gerar é conveniência na tela; falha aqui não pode derrubar a lista de contas.
    ultimaGeracao = 0;
    console.error("recorrências: geração na carga da página falhou", e);
  }
}

class ConflitoConta extends Error {}

const primeiroDia = (competencia: string) => new Date(`${competencia}-01T00:00:00Z`);

/**
 * Cria um modelo. Com `contaId` (tornar recorrente / repetir no lançamento),
 * liga a conta ao modelo novo na mesma transação, com a competência do mês de
 * vencimento dela — a geração nunca duplica o mês dessa conta. Natureza e
 * cliente do modelo passam para a conta.
 */
export async function criarModelo(
  dados: DadosModelo,
  porEmail: string,
  contaId?: string
): Promise<{ id: string; geracao?: ResultadoGeracao } | { erro: string; status: number }> {
  const r: { id: string } | { erro: string; status: number } = await prisma.$transaction(async (tx) => {
    let competenciaConta: string | null = null;
    if (contaId) {
      const c = await tx.contaPagar.findUnique({ where: { id: contaId } });
      if (!c) return { erro: "conta não encontrada", status: 404 };
      if (c.recorrenciaId) return { erro: "esta conta já é recorrente", status: 409 };
      competenciaConta = dia(c.vencimento).slice(0, 7);
      // O modelo começa no mês da conta que o originou, sempre.
      dados = { ...dados, inicio: competenciaConta };
      if (dados.fim && dados.fim < dados.inicio) {
        return { erro: "a última competência não pode ser antes do mês desta conta", status: 400 };
      }
    }
    const m = await tx.despesaRecorrente.create({
      data: {
        fornecedor: dados.fornecedor,
        descricao: dados.descricao,
        categoria: dados.categoria,
        valor: dados.valor,
        valorVariavel: dados.valorVariavel,
        periodicidade: dados.periodicidade,
        diaVencimento: dados.diaVencimento,
        inicioEm: primeiroDia(dados.inicio),
        fimEm: dados.fim ? primeiroDia(dados.fim) : null,
        natureza: dados.natureza,
        clientId: dados.clientId,
        criadoPorEmail: porEmail,
      },
    });
    if (contaId && competenciaConta) {
      const { count } = await tx.contaPagar.updateMany({
        where: { id: contaId, recorrenciaId: null },
        data: { recorrenciaId: m.id, competencia: competenciaConta, natureza: dados.natureza, clientId: dados.clientId },
      });
      if (count === 0) throw new ConflitoConta();
      await tx.eventoConta.create({
        data: { contaId, acao: "recorrente", porEmail, comentario: `ligada à recorrência ${m.id}` },
      });
    }
    return { id: m.id };
  }).catch((e) => {
    if (e instanceof ConflitoConta) return { erro: "outra pessoa mudou esta conta agora — recarregue", status: 409 };
    throw e;
  });
  // Mesma passada do cron: competências passadas saem agora (ou viram as
  // avulsas já lançadas do mesmo fornecedor, inclusive de meses seguintes à conta).
  if ("id" in r) return { id: r.id, geracao: await gerarContasRecorrentes(undefined, { modeloId: r.id }) };
  return r;
}

/** Edita o modelo. Vale para as próximas contas; as já geradas não mudam. */
export async function atualizarModelo(
  id: string,
  dados: Partial<DadosModelo> & { ativa?: boolean }
): Promise<{ ok: true; geracao: ResultadoGeracao } | { erro: string; status: number }> {
  const atual = await prisma.despesaRecorrente.findUnique({ where: { id } });
  if (!atual) return { erro: "recorrência não encontrada", status: 404 };
  const inicio = dados.inicio ?? dia(atual.inicioEm).slice(0, 7);
  const fim = dados.fim !== undefined ? dados.fim : atual.fimEm ? dia(atual.fimEm).slice(0, 7) : null;
  if (fim && fim < inicio) return { erro: "a última competência não pode ser antes da primeira", status: 400 };

  await prisma.despesaRecorrente.update({
    where: { id },
    data: {
      fornecedor: dados.fornecedor,
      descricao: dados.descricao,
      categoria: dados.categoria,
      valor: dados.valor,
      valorVariavel: dados.valorVariavel,
      periodicidade: dados.periodicidade,
      diaVencimento: dados.diaVencimento,
      inicioEm: dados.inicio ? primeiroDia(dados.inicio) : undefined,
      fimEm: dados.fim !== undefined ? (dados.fim ? primeiroDia(dados.fim) : null) : undefined,
      natureza: dados.natureza,
      clientId: dados.clientId,
      ativa: dados.ativa,
    },
  });
  return { ok: true, geracao: await gerarContasRecorrentes(undefined, { modeloId: id }) };
}

export async function clientesParaSelecao(): Promise<{ id: string; nome: string }[]> {
  return prisma.client.findMany({ select: { id: true, nome: true }, orderBy: { nome: "asc" } });
}
