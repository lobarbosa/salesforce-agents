import { prisma } from "@/lib/prisma";
import { acoesPendentes } from "@/lib/demandas";
import type { EstadoEsteira, ResumoEsteira } from "@/lib/esteira-resumo";

export type { EstadoEsteira, ResumoEsteira } from "@/lib/esteira-resumo";

// Estado da esteira de cada cliente para o ponto da sidebar (2026-10-30). O
// ponto era a saúde da org (assessment) — fixa por semanas, e quase sempre
// vermelha, então não dizia nada no dia a dia. Agora responde "onde a esteira
// deste cliente está esperando alguém?", com a mesma regra dos cards
// (acoesPendentes). A saúde da org continua no perfil do cliente.

// Prioridade do ponto: o que muda sozinho primeiro (agente), depois quem
// precisa agir — cliente antes do time, porque é o que o time precisa cobrar.
const PRIORIDADE = ["agente", "cliente", "time", "fila"] as const satisfies readonly EstadoEsteira[];

export async function esteiraPorCliente(clientIds: string[]): Promise<Record<string, ResumoEsteira>> {
  if (clientIds.length === 0) return {};
  const demandas = await prisma.demanda.findMany({
    where: { clientId: { in: clientIds }, status: { notIn: ["entregue", "cancelada"] } },
    select: {
      clientId: true,
      status: true,
      congeladaDe: true,
      estimativaConsultorHoras: true,
      estimativaAprovadaHoras: true,
      disparos: {
        where: { concluidoEm: null },
        select: { tipo: true, gate: true, disparadoEm: true, concluidoEm: true },
      },
    },
  });
  const saida: Record<string, ResumoEsteira> = {};
  for (const id of clientIds) saida[id] = { estado: "parado", contagem: {} };
  for (const d of demandas) {
    const r = saida[d.clientId];
    for (const a of acoesPendentes(d)) r.contagem[a.quem] = (r.contagem[a.quem] ?? 0) + 1;
  }
  for (const r of Object.values(saida)) {
    r.estado = PRIORIDADE.find((p) => (r.contagem[p] ?? 0) > 0) ?? "parado";
  }
  return saida;
}

