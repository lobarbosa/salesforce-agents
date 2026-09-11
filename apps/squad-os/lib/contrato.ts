import type { Contrato, Entregavel } from "@/lib/generated/prisma/client";

// Puro de propósito: sem Prisma, importável de Server e Client Components —
// mesma convenção de lib/demandas.ts. `ContratoTab` é client component, e uma
// importação daqui que puxasse `lib/prisma` arrastaria o driver `pg` inteiro
// pro bundle do browser (o `next build` reprova; `tsc` e o eslint não pegam).
// A consulta de horas mora em lib/data.ts, com as outras queries por cliente.

// --- SLA -----------------------------------------------------------------

// A assinatura de índice satisfaz o tipo de entrada JSON do Prisma sem cast —
// e é honesta: todo campo aqui é string ou número.
export interface LinhaSla {
  severidade: string;
  primeiraRespostaHoras: number;
  resolucaoHoras: number;
  [campo: string]: string | number;
}

// Ponto de partida quando um contrato AMS é criado. Não é "o SLA da Acxya" —
// é um rascunho editável, pra a tabela não nascer vazia e alguém ter que
// inventar as quatro severidades do zero toda vez.
export const SLA_PADRAO: LinhaSla[] = [
  { severidade: "Crítica", primeiraRespostaHoras: 1, resolucaoHoras: 4 },
  { severidade: "Alta", primeiraRespostaHoras: 4, resolucaoHoras: 16 },
  { severidade: "Média", primeiraRespostaHoras: 8, resolucaoHoras: 40 },
  { severidade: "Baixa", primeiraRespostaHoras: 24, resolucaoHoras: 80 },
];

export function asSla(valor: unknown): LinhaSla[] {
  if (!Array.isArray(valor)) return [];
  return valor
    .filter((l): l is Record<string, unknown> => !!l && typeof l === "object")
    .map((l) => ({
      severidade: String(l.severidade ?? "").trim().slice(0, 40),
      primeiraRespostaHoras: Math.max(0, Math.round(Number(l.primeiraRespostaHoras) || 0)),
      resolucaoHoras: Math.max(0, Math.round(Number(l.resolucaoHoras) || 0)),
    }))
    .filter((l) => l.severidade);
}

export interface MesDeHoras {
  /** AAAA-MM — chave estável, ordenável como texto. */
  mes: string;
  horasGastas: number;
  horasContratadas: number;
}

// --- Progresso (Projeto) -------------------------------------------------

export interface Progresso {
  pct: number;
  pesoConcluido: number;
  pesoTotal: number;
  concluidos: number;
  total: number;
}

/**
 * Progresso ponderado pelo peso dos entregáveis.
 *
 * Ponderado e não contagem simples porque "migrar 12 Flows" e "ajustar um
 * layout" contariam igual numa média — e o número mentiria exatamente quando
 * mais importa, perto do fim.
 */
export function progressoDoProjeto(entregaveis: Pick<Entregavel, "peso" | "concluido">[]): Progresso {
  const pesoTotal = entregaveis.reduce((s, e) => s + Math.max(1, e.peso), 0);
  const pesoConcluido = entregaveis
    .filter((e) => e.concluido)
    .reduce((s, e) => s + Math.max(1, e.peso), 0);
  return {
    pct: pesoTotal === 0 ? 0 : Math.round((pesoConcluido / pesoTotal) * 100),
    pesoConcluido,
    pesoTotal,
    concluidos: entregaveis.filter((e) => e.concluido).length,
    total: entregaveis.length,
  };
}

export type ContratoCompleto = Contrato & { entregaveis: Entregavel[] };
