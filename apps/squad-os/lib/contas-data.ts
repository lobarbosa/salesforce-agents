import { prisma } from "@/lib/prisma";
import type { NaturezaCusto, Periodicidade, StatusConta } from "@/lib/generated/prisma/client";
import { bloqueio, bloqueioValor, formatarReais, PROXIMO_STATUS, type Acao, type QuemAge } from "@/lib/contas";
import { criarModelo } from "@/lib/recorrencias-data";

// Formato que vai para a tela (serializável: Decimal e Date viram number e string).
export interface ContaVista {
  id: string;
  fornecedor: string;
  descricao: string;
  categoria: string;
  valor: number;
  vencimento: string; // YYYY-MM-DD
  status: StatusConta;
  temDocumento: boolean;
  documentoNome: string;
  lancadoPorEmail: string;
  lancadoEm: string;
  decididoPorEmail: string | null;
  pagoEm: string | null;
  // Recorrência e classificação (null = conta avulsa / ainda não classificada).
  recorrenciaId: string | null;
  competencia: string | null;
  natureza: NaturezaCusto | null;
  clientId: string | null;
  clientNome: string | null;
  /** Quem corrigiu o valor antes da aprovação (também não aprova — lib/contas.ts). */
  valorAlteradoPor: string[];
}

export interface EventoVisto {
  acao: string;
  porEmail: string;
  comentario: string;
  em: string;
}

type Linha = Awaited<ReturnType<typeof prisma.contaPagar.findFirstOrThrow>> & {
  client?: { nome: string } | null;
  eventos?: { porEmail: string }[];
};

// O que paraVista precisa além das colunas: nome do cliente e quem corrigiu o valor.
export const INCLUDE_VISTA = {
  client: { select: { nome: true } },
  eventos: { where: { acao: "valor_alterado" }, select: { porEmail: true } },
} as const;

export function paraVista(c: Linha): ContaVista {
  return {
    id: c.id,
    fornecedor: c.fornecedor,
    descricao: c.descricao,
    categoria: c.categoria,
    valor: Number(c.valor),
    vencimento: c.vencimento.toISOString().slice(0, 10),
    status: c.status,
    temDocumento: Boolean(c.documentoCaminho),
    documentoNome: c.documentoNome,
    lancadoPorEmail: c.lancadoPorEmail,
    lancadoEm: c.lancadoEm.toISOString(),
    decididoPorEmail: c.decididoPorEmail,
    pagoEm: c.pagoEm?.toISOString() ?? null,
    recorrenciaId: c.recorrenciaId,
    competencia: c.competencia,
    natureza: c.natureza,
    clientId: c.clientId,
    clientNome: c.client?.nome ?? null,
    valorAlteradoPor: [...new Set((c.eventos ?? []).map((e) => e.porEmail))],
  };
}

export async function listarContas(): Promise<ContaVista[]> {
  const contas = await prisma.contaPagar.findMany({
    include: INCLUDE_VISTA,
    orderBy: [{ vencimento: "asc" }, { lancadoEm: "asc" }],
  });
  return contas.map(paraVista);
}

export async function eventosDa(contaId: string): Promise<EventoVisto[]> {
  const ev = await prisma.eventoConta.findMany({ where: { contaId }, orderBy: { em: "asc" } });
  return ev.map((e) => ({ acao: e.acao, porEmail: e.porEmail, comentario: e.comentario, em: e.em.toISOString() }));
}

export interface DadosLancamento {
  fornecedor: string;
  descricao: string;
  categoria: string;
  valor: number;
  vencimento: string;
  natureza: NaturezaCusto | null;
  clientId: string | null;
}

/**
 * Lança a conta. Com `repetir`, cria também o modelo recorrente a partir dela
 * (início = mês do vencimento, dia = dia do vencimento) e liga os dois.
 */
export async function lancarConta(
  dados: DadosLancamento,
  documento: { caminho: string; nome: string } | null,
  porEmail: string,
  repetir: { periodicidade: Periodicidade; valorVariavel: boolean } | null = null
): Promise<ContaVista> {
  const conta = await prisma.$transaction(async (tx) => {
    const c = await tx.contaPagar.create({
      data: {
        fornecedor: dados.fornecedor,
        descricao: dados.descricao,
        categoria: dados.categoria,
        valor: dados.valor,
        vencimento: new Date(`${dados.vencimento}T00:00:00Z`),
        documentoCaminho: documento?.caminho ?? "",
        documentoNome: documento?.nome ?? "",
        lancadoPorEmail: porEmail,
        natureza: dados.natureza,
        clientId: dados.clientId,
      },
    });
    await tx.eventoConta.create({ data: { contaId: c.id, acao: "lancada", porEmail } });
    return c;
  });
  if (repetir && dados.natureza) {
    // Fora da transação do lançamento: se a recorrência falhar, a conta (e o
    // documento já no bucket) continua valendo; dá para "tornar recorrente" depois.
    await criarModelo(
      {
        fornecedor: dados.fornecedor,
        descricao: dados.descricao,
        categoria: dados.categoria,
        valor: dados.valor,
        valorVariavel: repetir.valorVariavel,
        periodicidade: repetir.periodicidade,
        diaVencimento: Number(dados.vencimento.slice(8, 10)),
        inicio: dados.vencimento.slice(0, 7),
        fim: null,
        natureza: dados.natureza,
        clientId: dados.clientId,
      },
      porEmail,
      conta.id
    ).catch((e) => console.error("contas: conta lançada, mas a recorrência não foi criada", e));
  }
  return paraVista(await prisma.contaPagar.findUniqueOrThrow({ where: { id: conta.id }, include: INCLUDE_VISTA }));
}

/**
 * Corrige o valor (só aguardando aprovação) e/ou classifica a conta (natureza,
 * cliente — em qualquer situação: é rótulo de análise, não muda o que foi
 * aprovado). Compare-and-set no status e no valor lidos; cada mudança vira
 * evento na trilha.
 */
export async function alterarConta(
  id: string,
  mudanca: { valor?: number; natureza?: NaturezaCusto | null; clientId?: string | null },
  quem: QuemAge
): Promise<{ conta: ContaVista } | { erro: string; status: number }> {
  return prisma.$transaction(async (tx) => {
    const c = await tx.contaPagar.findUnique({ where: { id }, include: { client: { select: { nome: true } } } });
    if (!c) return { erro: "conta não encontrada", status: 404 };
    if (quem.role !== "admin" && quem.role !== "financeiro") return { erro: "só o time financeiro altera contas", status: 403 };

    const eventos: { acao: string; comentario: string }[] = [];
    const dados: { valor?: number; natureza?: NaturezaCusto | null; clientId?: string | null } = {};
    const valorAtual = Number(c.valor);
    if (mudanca.valor !== undefined && mudanca.valor !== valorAtual) {
      const motivo = bloqueioValor(c.status);
      if (motivo) return { erro: motivo, status: 409 };
      dados.valor = mudanca.valor;
      eventos.push({ acao: "valor_alterado", comentario: `${formatarReais(valorAtual)} → ${formatarReais(mudanca.valor)}` });
    }
    if (mudanca.natureza !== undefined && mudanca.natureza !== c.natureza) dados.natureza = mudanca.natureza;
    let novoCliente: string | null = null;
    if (mudanca.clientId !== undefined && mudanca.clientId !== c.clientId) {
      if (mudanca.clientId) {
        const cli = await tx.client.findUnique({ where: { id: mudanca.clientId }, select: { nome: true } });
        if (!cli) return { erro: "cliente não encontrado", status: 400 };
        novoCliente = cli.nome;
      }
      dados.clientId = mudanca.clientId;
    }
    if (dados.natureza !== undefined || dados.clientId !== undefined) {
      const partes = [];
      if (dados.natureza !== undefined) partes.push(`natureza: ${c.natureza ?? "—"} → ${dados.natureza ?? "—"}`);
      if (dados.clientId !== undefined) partes.push(`cliente: ${c.client?.nome ?? "—"} → ${novoCliente ?? "—"}`);
      eventos.push({ acao: "classificada", comentario: partes.join("; ") });
    }
    if (!eventos.length) return { conta: paraVista(await tx.contaPagar.findUniqueOrThrow({ where: { id }, include: INCLUDE_VISTA })) };

    const r = await tx.contaPagar.updateMany({ where: { id, status: c.status, valor: c.valor }, data: dados });
    if (r.count === 0) return { erro: "outra pessoa mudou esta conta agora — recarregue", status: 409 };
    for (const e of eventos) await tx.eventoConta.create({ data: { contaId: id, porEmail: quem.email, ...e } });
    return { conta: paraVista(await tx.contaPagar.findUniqueOrThrow({ where: { id }, include: INCLUDE_VISTA })) };
  });
}

/**
 * Aplica uma ação com as regras de lib/contas.ts. A troca de status é
 * condicional ao status lido (updateMany com `status` no where): se outra
 * pessoa agiu no meio do caminho, nada muda e a tela recebe o conflito.
 */
export async function agirNaConta(
  id: string,
  acao: Acao,
  quem: QuemAge,
  comentario: string
): Promise<{ conta: ContaVista } | { erro: string; status: number }> {
  return prisma.$transaction(async (tx) => {
    const c = await tx.contaPagar.findUnique({ where: { id }, include: INCLUDE_VISTA });
    if (!c) return { erro: "conta não encontrada", status: 404 };
    const motivo = bloqueio(acao, paraVista(c), quem);
    if (motivo) return { erro: motivo, status: 409 };
    if (acao === "recusar" && !comentario) return { erro: "diga o motivo da recusa", status: 400 };

    const agora = new Date();
    const dados =
      acao === "pagar"
        ? { status: PROXIMO_STATUS[acao], pagoPorEmail: quem.email, pagoEm: agora }
        : acao === "cancelar"
          ? { status: PROXIMO_STATUS[acao] }
          : { status: PROXIMO_STATUS[acao], decididoPorEmail: quem.email, decididoEm: agora };
    // Valor também no where: aprovar exatamente o valor que estava na tela.
    const r = await tx.contaPagar.updateMany({ where: { id, status: c.status, valor: c.valor }, data: dados });
    if (r.count === 0) return { erro: "outra pessoa mudou esta conta agora — recarregue", status: 409 };

    await tx.eventoConta.create({
      data: { contaId: id, acao: PROXIMO_STATUS[acao], porEmail: quem.email, comentario },
    });
    return { conta: paraVista(await tx.contaPagar.findUniqueOrThrow({ where: { id }, include: INCLUDE_VISTA })) };
  });
}
