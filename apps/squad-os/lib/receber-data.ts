import { prisma } from "@/lib/prisma";
import { notasEmitidas } from "@/lib/ops";
import { chaveNota, consolidar, type DadosRecebimento, type NotaPublicada, type NotaVista, type RegistroRecebimento } from "@/lib/receber";

// Leitura e escrita de contas a receber. As notas vêm do schema ops (a
// conciliação contábil publica); os recebimentos ficam em public.nfse_recebimentos.

const dia = (d: Date) => d.toISOString().slice(0, 10);
const numero = (v: unknown) => (v === null || v === undefined || v === "" ? null : Number(v));

function paraRegistro(r: Awaited<ReturnType<typeof prisma.recebimentoNota.findFirstOrThrow>>): RegistroRecebimento {
  return {
    id: r.id,
    numero: r.numero,
    emissao: dia(r.emissao),
    recebidoEm: dia(r.recebidoEm),
    valorRecebido: Number(r.valorRecebido),
    forma: r.forma,
    observacao: r.observacao,
    registradoPorEmail: r.registradoPorEmail,
    registradoEm: r.registradoEm.toISOString(),
    estornadoEm: r.estornadoEm?.toISOString() ?? null,
    estornadoPorEmail: r.estornadoPorEmail,
    estornoMotivo: r.estornoMotivo,
  };
}

function paraNota(n: Record<string, unknown>): NotaPublicada {
  const txt = (v: unknown) => (v === null || v === undefined ? null : String(v));
  return {
    numero: txt(n.numero),
    data_emissao: txt(n.data_emissao),
    cliente: txt(n.cliente),
    valor: Number(n.valor ?? 0),
    valor_liquido: numero(n.valor_liquido),
    vencimento: txt(n.vencimento),
    documento: txt(n.documento),
    arquivo: txt(n.arquivo),
  };
}

/** null = as notas ainda não chegam (banco dos agentes não ligado ou conciliação sem publicar). */
export async function listarNotas(hoje: string): Promise<{ notas: NotaVista[]; atualizadoEm: string | null } | null> {
  const [publicadas, registros] = await Promise.all([
    notasEmitidas(),
    prisma.recebimentoNota.findMany({ orderBy: { registradoEm: "desc" } }),
  ]);
  if (!publicadas) return null;
  return {
    notas: consolidar(publicadas.notas.map(paraNota), registros.map(paraRegistro), publicadas.legado, hoje),
    atualizadoEm: publicadas.atualizadoEm,
  };
}

/**
 * Registra o recebimento. Um registro ativo por nota: com outro ativo (alguém
 * registrou agora), recusa com 409 — a tela recarrega e mostra o que está lá.
 */
export async function registrarRecebimento(
  nota: NotaVista,
  dados: DadosRecebimento,
  porEmail: string
): Promise<{ ok: true } | { erro: string; status: number }> {
  if (nota.recebimento) return { erro: "esta nota já está como recebida — desfaça antes de registrar de novo", status: 409 };
  const emissao = new Date(`${nota.emissao}T00:00:00Z`);
  return prisma.$transaction(async (tx) => {
    const ativo = await tx.recebimentoNota.findFirst({ where: { numero: nota.numero, emissao, estornadoEm: null } });
    if (ativo) return { erro: "outra pessoa registrou o recebimento desta nota agora — recarregue", status: 409 };
    await tx.recebimentoNota.create({
      data: {
        numero: nota.numero,
        emissao,
        cliente: nota.cliente,
        valorNota: nota.valor,
        recebidoEm: new Date(`${dados.recebidoEm}T00:00:00Z`),
        valorRecebido: dados.valorRecebido,
        forma: dados.forma,
        observacao: dados.observacao,
        registradoPorEmail: porEmail,
      },
    });
    return { ok: true as const };
  }, { isolationLevel: "Serializable" });
}

/** Desfaz o recebimento (lançado na nota errada, devolvido...). O registro fica no histórico. */
export async function estornarRecebimento(
  id: string,
  motivo: string,
  porEmail: string
): Promise<{ ok: true; chave: string } | { erro: string; status: number }> {
  const r = await prisma.recebimentoNota.findUnique({ where: { id } });
  if (!r) return { erro: "recebimento não encontrado", status: 404 };
  const feito = await prisma.recebimentoNota.updateMany({
    where: { id, estornadoEm: null },
    data: { estornadoEm: new Date(), estornadoPorEmail: porEmail, estornoMotivo: motivo },
  });
  if (!feito.count) return { erro: "este recebimento já foi desfeito", status: 409 };
  return { ok: true, chave: chaveNota(r.numero, dia(r.emissao)) };
}
