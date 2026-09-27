import { prisma } from "@/lib/prisma";
import type { StatusConta } from "@/lib/generated/prisma/client";
import { bloqueio, PROXIMO_STATUS, type Acao, type QuemAge } from "@/lib/contas";

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
}

export interface EventoVisto {
  acao: string;
  porEmail: string;
  comentario: string;
  em: string;
}

type Linha = Awaited<ReturnType<typeof prisma.contaPagar.findFirstOrThrow>>;

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
  };
}

export async function listarContas(): Promise<ContaVista[]> {
  const contas = await prisma.contaPagar.findMany({ orderBy: [{ vencimento: "asc" }, { lancadoEm: "asc" }] });
  return contas.map(paraVista);
}

export async function eventosDa(contaId: string): Promise<EventoVisto[]> {
  const ev = await prisma.eventoConta.findMany({ where: { contaId }, orderBy: { em: "asc" } });
  return ev.map((e) => ({ acao: e.acao, porEmail: e.porEmail, comentario: e.comentario, em: e.em.toISOString() }));
}

export async function lancarConta(
  dados: { fornecedor: string; descricao: string; categoria: string; valor: number; vencimento: string },
  documento: { caminho: string; nome: string } | null,
  porEmail: string
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
      },
    });
    await tx.eventoConta.create({ data: { contaId: c.id, acao: "lancada", porEmail } });
    return c;
  });
  return paraVista(conta);
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
    const c = await tx.contaPagar.findUnique({ where: { id } });
    if (!c) return { erro: "conta não encontrada", status: 404 };
    const motivo = bloqueio(acao, { status: c.status, valor: Number(c.valor), lancadoPorEmail: c.lancadoPorEmail }, quem);
    if (motivo) return { erro: motivo, status: 409 };
    if (acao === "recusar" && !comentario) return { erro: "diga o motivo da recusa", status: 400 };

    const agora = new Date();
    const dados =
      acao === "pagar"
        ? { status: PROXIMO_STATUS[acao], pagoPorEmail: quem.email, pagoEm: agora }
        : acao === "cancelar"
          ? { status: PROXIMO_STATUS[acao] }
          : { status: PROXIMO_STATUS[acao], decididoPorEmail: quem.email, decididoEm: agora };
    const r = await tx.contaPagar.updateMany({ where: { id, status: c.status }, data: dados });
    if (r.count === 0) return { erro: "outra pessoa mudou esta conta agora — recarregue", status: 409 };

    await tx.eventoConta.create({
      data: { contaId: id, acao: PROXIMO_STATUS[acao], porEmail: quem.email, comentario },
    });
    return { conta: paraVista(await tx.contaPagar.findUniqueOrThrow({ where: { id } })) };
  });
}
