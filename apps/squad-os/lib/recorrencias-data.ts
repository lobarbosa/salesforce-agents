import { prisma } from "@/lib/prisma";
import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";
import { chaveDia } from "@/lib/horas";
import {
  aGerar,
  chaveOcorrencia,
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
    criadoEm: chaveDia(m.criadoEm),
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

/**
 * Cria a ContaPagar de cada competência devida (lib/recorrencias.ts:
 * competenciasDevidas) dos modelos ativos que ainda não a têm. Idempotente:
 * o unique (recorrencia_id, competencia) do banco é quem garante — cron e
 * carga de página podem rodar ao mesmo tempo, e o perdedor recebe P2002, que
 * aqui só quer dizer "já existe".
 */
export async function gerarContasRecorrentes(
  hoje = chaveDia(new Date()),
  filtro: { modeloId?: string } = {}
): Promise<{ criadas: number; falhas: number }> {
  const linhas = await prisma.despesaRecorrente.findMany({
    where: { ativa: true, ...(filtro.modeloId ? { id: filtro.modeloId } : {}) },
  });
  const modelos = linhas.map((linha) => ({ ...paraRegra(linha), id: linha.id, ativa: linha.ativa, linha }));
  const devidas = aGerar(modelos, new Set(), hoje);
  if (!devidas.length) return { criadas: 0, falhas: 0 };

  // Uma consulta para saber o que já existe; o unique segura a corrida.
  const existentes = await prisma.contaPagar.findMany({
    where: {
      recorrenciaId: { in: [...new Set(devidas.map((p) => p.modelo.id))] },
      competencia: { in: [...new Set(devidas.map((p) => p.competencia))] },
    },
    select: { recorrenciaId: true, competencia: true },
  });
  const pendentes = aGerar(
    modelos,
    new Set(existentes.map((e) => chaveOcorrencia(e.recorrenciaId!, e.competencia!))),
    hoje
  );

  let criadas = 0;
  let falhas = 0;
  for (const { modelo, competencia, vencimento } of pendentes) {
    const m = modelo.linha;
    try {
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
            comentario: `gerada pela recorrência ${m.id}${m.valorVariavel ? " — valor estimado, confirmar" : ""}`,
          },
        });
      });
      criadas++;
    } catch (e) {
      if (ehUnicaViolada(e)) continue;
      falhas++;
      console.error(`recorrências: falha ao gerar ${m.id} ${competencia}`, e);
    }
  }
  return { criadas, falhas };
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
): Promise<{ id: string } | { erro: string; status: number }> {
  const r = await prisma.$transaction(async (tx) => {
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
  if ("id" in r) await gerarContasRecorrentes(undefined, { modeloId: r.id });
  return r;
}

/** Edita o modelo. Vale para as próximas contas; as já geradas não mudam. */
export async function atualizarModelo(
  id: string,
  dados: Partial<DadosModelo> & { ativa?: boolean }
): Promise<{ ok: true } | { erro: string; status: number }> {
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
  await gerarContasRecorrentes(undefined, { modeloId: id });
  return { ok: true };
}

export async function clientesParaSelecao(): Promise<{ id: string; nome: string }[]> {
  return prisma.client.findMany({ select: { id: true, nome: true }, orderBy: { nome: "asc" } });
}
