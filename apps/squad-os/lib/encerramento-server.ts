import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import type { Prisma } from "@/lib/generated/prisma/client";
import { bloqueioPorEncerramento, type AcaoBloqueada, type HistoricoDoCliente } from "@/lib/encerramento";

// Parte com banco das regras de lib/encerramento.ts.

/** 409 se o cliente estiver encerrado; null se a ação pode seguir. */
export function recusaSeEncerrado(
  c: { nome: string; encerradoEm: Date | null } | null | undefined,
  acao: AcaoBloqueada
): NextResponse | null {
  const motivo = bloqueioPorEncerramento(c, acao);
  return motivo ? NextResponse.json({ error: motivo, clienteEncerrado: true }, { status: 409 }) : null;
}

/** Mesmo 409, para as rotas que só têm o id (ou o slug) do cliente. */
export async function recusaSeEncerradoPorId(
  where: { id: string } | { slug: string },
  acao: AcaoBloqueada
): Promise<NextResponse | null> {
  const c = await prisma.client.findUnique({ where, select: { nome: true, encerradoEm: true } });
  return recusaSeEncerrado(c, acao);
}

/** `db` = a transação do DELETE, para contar e apagar sob o mesmo lock. */
export async function historicoDoCliente(
  clientId: string,
  db: Prisma.TransactionClient = prisma
): Promise<HistoricoDoCliente> {
  // Sequencial e não Promise.all: dentro de uma transação interativa as
  // consultas vão pela mesma conexão de qualquer jeito.
  const demandas = await db.demanda.count({ where: { clientId } });
  const registrosTempo = await db.registroTempo.count({ where: { demanda: { clientId } } });
  const execucoes = await db.execucaoAgente.count({ where: { clientId } });
  // Custo alocado ao cliente: excluir faria o FK virar NULL e a margem por cliente perderia o histórico.
  const contasPagar = await db.contaPagar.count({ where: { clientId } });
  const despesasRecorrentes = await db.despesaRecorrente.count({ where: { clientId } });
  const contrato = await db.contrato.findUnique({
    where: { clientId },
    select: { horasContratadas: true, _count: { select: { entregaveis: true } } },
  });
  return {
    demandas,
    registrosTempo,
    execucoes,
    contasPagar,
    despesasRecorrentes,
    entregaveis: contrato?._count.entregaveis ?? 0,
    horasContratadas: contrato?.horasContratadas ?? 0,
  };
}
