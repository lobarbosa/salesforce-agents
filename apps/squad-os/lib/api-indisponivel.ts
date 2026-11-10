import { prisma } from "@/lib/prisma";

// "A esteira está sem crédito na API" (2026-11-10). Achado: o saldo da
// Anthropic acabou em 04/11 e toda execução falhou por 6 dias — a de uma
// demanda foi retentada 10 vezes — sem que o portal dissesse nada; só
// apareceu quando alguém perguntou por que a Eplast não andava.
//
// A execução registra `motivo: api_indisponivel` (cli.py → run-demand.yml →
// /api/sync/execucao). O aviso vale enquanto essa for a notícia mais recente:
// qualquer execução bem-sucedida depois dela o apaga sozinho.

const JANELA_MS = 7 * 24 * 60 * 60 * 1000;

export async function apiIndisponivelDesde(): Promise<Date | null> {
  const desde = new Date(Date.now() - JANELA_MS);
  const [falha, sucesso] = await Promise.all([
    prisma.execucaoAgente.findFirst({
      where: { motivo: "api_indisponivel", concluidoEm: { gte: desde } },
      orderBy: { concluidoEm: "desc" },
      select: { concluidoEm: true },
    }),
    prisma.execucaoAgente.findFirst({
      where: { resultado: "success", origem: { in: ["demanda", "assessment", "planejamento"] }, concluidoEm: { gte: desde } },
      orderBy: { concluidoEm: "desc" },
      select: { concluidoEm: true },
    }),
  ]);
  if (!falha) return null;
  if (sucesso && sucesso.concluidoEm >= falha.concluidoEm) return null;
  // A mais antiga da sequência atual de falhas: desde quando está parado.
  const primeira = await prisma.execucaoAgente.findFirst({
    where: { motivo: "api_indisponivel", concluidoEm: { gte: sucesso?.concluidoEm ?? desde } },
    orderBy: { concluidoEm: "asc" },
    select: { concluidoEm: true },
  });
  return primeira?.concluidoEm ?? falha.concluidoEm;
}
