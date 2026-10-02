import { prisma } from "@/lib/prisma";

// Observabilidade de execução (council de 2026-10-01) — leitura do espelho
// histórico que /api/sync/execucao grava. Nunca decide nada sobre estado de
// demanda (isso é git + /api/sync/demanda); isto só responde "o que rodou,
// com que resultado, quando" pra quem não quer abrir o GitHub Actions.

export interface ExecucaoVista {
  id: string;
  clientNome: string;
  demandaCode: string | null;
  origem: string;
  etapa: string;
  motivo: string;
  resultado: string;
  iniciadoEm: string | null;
  concluidoEm: string;
  runUrl: string;
}

type Linha = Awaited<ReturnType<typeof prisma.execucaoAgente.findFirstOrThrow>> & {
  client: { nome: string };
  demanda: { code: string } | null;
};

function paraVista(e: Linha): ExecucaoVista {
  return {
    id: e.id,
    clientNome: e.client.nome,
    demandaCode: e.demanda?.code ?? null,
    origem: e.origem,
    etapa: e.etapa,
    motivo: e.motivo,
    resultado: e.resultado,
    iniciadoEm: e.iniciadoEm?.toISOString() ?? null,
    concluidoEm: e.concluidoEm.toISOString(),
    runUrl: e.runUrl,
  };
}

const LIMITE_PADRAO = 200;

/** Todas as execuções, mais recente primeiro — filtros opcionais por cliente/origem/resultado. */
export async function listarExecucoes(
  filtro: { clientId?: string; origem?: string; resultado?: string } = {},
  limite = LIMITE_PADRAO
): Promise<ExecucaoVista[]> {
  const execucoes = await prisma.execucaoAgente.findMany({
    where: {
      clientId: filtro.clientId,
      origem: filtro.origem,
      resultado: filtro.resultado,
    },
    orderBy: { concluidoEm: "desc" },
    take: limite,
    include: {
      client: { select: { nome: true } },
      demanda: { select: { code: true } },
    },
  });
  return execucoes.map(paraVista);
}

/** Só as que falharam — a tela do consultor ("o que pode ter falhado"). */
export function listarFalhasRecentes(limite = LIMITE_PADRAO): Promise<ExecucaoVista[]> {
  return listarExecucoes({ resultado: "failure" }, limite);
}
