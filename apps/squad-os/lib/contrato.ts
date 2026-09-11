import type { Contrato, Entregavel, TipoContrato } from "@/lib/generated/prisma/client";

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

// --- Montagem do contrato a partir de um PUT parcial ----------------------

export const HORAS_MAX = 10_000;

/** O que já está guardado, no formato que interessa à montagem. */
export interface ContratoGuardado {
  tipo: TipoContrato;
  horasContratadas: number;
  cicloHoras: string;
  sla: unknown;
  projetoNome: string;
  projetoEscopo: string;
  inicioEm: Date | null;
  fimPrevistoEm: Date | null;
}

export interface DadosDoContrato {
  tipo: TipoContrato;
  horasContratadas: number;
  cicloHoras: string;
  sla: LinhaSla[];
  projetoNome: string;
  projetoEscopo: string;
  inicioEm: Date | null;
  fimPrevistoEm: Date | null;
}

export class ContratoInvalidoError extends Error {}

function dataOuNull(valor: unknown): Date | null {
  if (!valor) return null;
  const d = valor instanceof Date ? valor : new Date(String(valor));
  return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * Monta o contrato a ser gravado a partir do corpo do PUT e do que já existe.
 *
 * Duas regras, e as duas existem por causa de perda de dado real (2026-09-11,
 * navegando em produção):
 *
 * 1. **Campo ausente no corpo mantém o valor guardado.** A rota era substituição
 *    total, e o botão "Mudar para AMS/projeto" manda só `{ tipo }` — trocar de
 *    tipo zerava as horas e reiniciava a tabela de SLA. `centric` nasceu com 0
 *    horas exatamente assim.
 *
 * 2. **Trocar de tipo não apaga o que é do outro tipo.** A tela promete, com
 *    estas palavras, que "o que já estiver preenchido do outro tipo fica
 *    guardado" — e a rota zerava. Guardar um número que não está em exibição
 *    não custa nada; refazer o cadastro custa. Quem decide o que aparece é a
 *    aba, pelo `tipo`, não o banco esquecendo.
 *
 * Pura de propósito: é a regra mais fácil de quebrar em silêncio deste app, e
 * aqui ela é testável sem Prisma e sem servidor.
 */
export function montarDadosDoContrato(
  body: Record<string, unknown>,
  atual: ContratoGuardado | null
): DadosDoContrato {
  const tipo = body.tipo as TipoContrato;
  if (tipo !== "ams" && tipo !== "projeto") {
    throw new ContratoInvalidoError("tipo precisa ser 'ams' ou 'projeto'");
  }

  const manter = <T>(recebido: unknown, guardado: T, converter: (v: unknown) => T): T =>
    recebido === undefined ? guardado : converter(recebido);

  const horasContratadas = manter(
    body.horasContratadas,
    atual?.horasContratadas ?? 0,
    (v) => Math.round(Number(v) || 0)
  );
  if (horasContratadas < 0 || horasContratadas > HORAS_MAX) {
    throw new ContratoInvalidoError(`horas contratadas fora da faixa (0 a ${HORAS_MAX})`);
  }

  // SLA nasce com o rascunho padrão só quando não existe nenhum — para a tabela
  // não abrir vazia. Depois disso, o que vale é o que está guardado.
  const slaGuardado = asSla(atual?.sla);
  const sla = manter(
    body.sla,
    slaGuardado.length > 0 ? slaGuardado : SLA_PADRAO,
    (v) => asSla(v)
  );

  return {
    tipo,
    horasContratadas,
    cicloHoras:
      manter(body.cicloHoras, atual?.cicloHoras ?? "mensal", (v) =>
        String(v ?? "").trim().slice(0, 30)
      ) || "mensal",
    sla,
    projetoNome: manter(body.projetoNome, atual?.projetoNome ?? "", (v) =>
      String(v ?? "").trim().slice(0, 200)
    ),
    projetoEscopo: manter(body.projetoEscopo, atual?.projetoEscopo ?? "", (v) =>
      String(v ?? "").trim().slice(0, 4000)
    ),
    inicioEm: manter(body.inicioEm, atual?.inicioEm ?? null, dataOuNull),
    fimPrevistoEm: manter(body.fimPrevistoEm, atual?.fimPrevistoEm ?? null, dataOuNull),
  };
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
