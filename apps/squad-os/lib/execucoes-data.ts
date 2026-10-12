import { prisma } from "@/lib/prisma";
import { chaveDia, FUSO } from "@/lib/horas";

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

export interface DiaExecucoes {
  dia: string; // YYYY-MM-DD
  success: number;
  failure: number;
  cancelled: number;
}

function chaveResultado(r: string): "success" | "failure" | "cancelled" | null {
  return r === "success" || r === "failure" || r === "cancelled" ? r : null;
}

/**
 * Contagem diária por resultado, para a tendência acima da tabela. Não
 * recebe filtro de resultado (diferente de listarExecucoes) — a pergunta do
 * gráfico é "como anda a proporção sucesso/falha", que só faz sentido com os
 * três juntos; cliente e origem continuam filtrando porque não mudam essa
 * pergunta, só o recorte.
 */
export async function execucoesPorDia(
  filtro: { clientId?: string; origem?: string } = {},
  dias = 14
): Promise<DiaExecucoes[]> {
  // Dia de São Paulo, como no resto do app (lib/horas.ts): no dia UTC, o que
  // falhou às 22h aparecia no dia seguinte do gráfico.
  const hoje = chaveDia(new Date());
  const chaves: string[] = [];
  for (let i = dias - 1; i >= 0; i--) {
    const d = new Date(`${hoje}T12:00:00Z`);
    d.setUTCDate(d.getUTCDate() - i);
    chaves.push(d.toISOString().slice(0, 10));
  }
  const desde = new Date(`${chaves[0]}T00:00:00${FUSO}`);

  const execucoes = await prisma.execucaoAgente.findMany({
    where: { clientId: filtro.clientId, origem: filtro.origem, concluidoEm: { gte: desde } },
    select: { concluidoEm: true, resultado: true },
  });

  const porDia = new Map<string, DiaExecucoes>(
    chaves.map((chave) => [chave, { dia: chave, success: 0, failure: 0, cancelled: 0 }])
  );
  for (const e of execucoes) {
    const bucket = porDia.get(chaveDia(e.concluidoEm));
    const r = chaveResultado(e.resultado);
    if (bucket && r) bucket[r]++;
  }
  return [...porDia.values()];
}
