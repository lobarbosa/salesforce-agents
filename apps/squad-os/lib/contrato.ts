import type { Contrato, Demanda, Entregavel, StatusDemanda, TipoContrato } from "@/lib/generated/prisma/client";
import { chaveDia, cicloDoMes } from "@/lib/horas";

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
  /** AAAA-MM (mês de São Paulo) — chave estável, ordenável como texto. */
  mes: string;
  /** Horas fechadas lançadas neste mês. */
  horasGastas: number;
  /** Horas acumuladas no ciclo do contrato até o fim deste mês (= horasGastas no ciclo mensal). */
  horasNoCiclo: number;
  /** Teto do ciclo (o contrato fala em horas por ciclo, não por mês). */
  horasContratadas: number;
}

/** "AAAA-MM" de `chave` deslocado `passos` meses para trás. */
export function mesAnterior(chave: string, passos: number): string {
  const [ano, mes] = chave.split("-").map(Number);
  const d = new Date(Date.UTC(ano, mes - 1 - passos, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/**
 * Monta a série mês a mês a partir dos registros fechados. Puro (testado em
 * scripts/testa-contrato.ts).
 *
 * - Mês é o de São Paulo (`chaveDia`), como em toda a parte de horas — antes
 *   era o mês UTC, e o trabalho das 21h do último dia caía no mês seguinte.
 * - Contrato trimestral: o teto é do ciclo, então cada mês carrega também o
 *   acumulado do ciclo até ele. Comparar o mês isolado com o teto do
 *   trimestre escondia o estouro (cada mês podia gastar o trimestre inteiro).
 *   `registros` precisa cobrir desde o início do ciclo do primeiro mês.
 */
export function montarHorasPorMes(
  registros: { inicioEm: Date; minutos: number | null }[],
  contratadas: number,
  ciclo: string,
  agora: Date,
  meses: number
): MesDeHoras[] {
  const porMes = new Map<string, number>();
  for (const r of registros) {
    const k = chaveDia(r.inicioEm).slice(0, 7);
    porMes.set(k, (porMes.get(k) ?? 0) + (r.minutos ?? 0));
  }
  const mesAtual = chaveDia(agora).slice(0, 7);
  const umaCasa = (min: number) => Math.round((min / 60) * 10) / 10;

  const saida: MesDeHoras[] = [];
  for (let i = meses - 1; i >= 0; i--) {
    const k = mesAnterior(mesAtual, i);
    const inicioCiclo = chaveDia(cicloDoMes(k, ciclo).desde).slice(0, 7);
    let noCiclo = 0;
    for (let m = inicioCiclo; m <= k; m = mesAnterior(m, -1)) noCiclo += porMes.get(m) ?? 0;
    saida.push({
      mes: k,
      // Uma casa decimal: o gráfico é de acompanhamento, não de faturamento.
      horasGastas: umaCasa(porMes.get(k) ?? 0),
      horasNoCiclo: umaCasa(noCiclo),
      horasContratadas: contratadas,
    });
  }
  return saida;
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
  /** Entregáveis concluídos (todas as demandas entregues, ou marcado à mão se não tem demanda). */
  concluidos: number;
  total: number;
  /** Demandas de projeto que entram na conta (sem as canceladas) e quantas já foram entregues. */
  demandas: number;
  demandasEntregues: number;
  /** Avanço de cada entregável (0 a 1) e se ele vem das demandas ou da marcação manual. */
  porEntregavel: Record<string, { fracao: number; automatico: boolean }>;
}

/**
 * Quanto do caminho cada etapa da esteira representa. Só `entregue` vale 1:
 * homologação pendente ainda não é entrega. Os valores acompanham o esforço
 * típico até ali (o build é a maior fatia), não o número de etapas.
 */
export const AVANCO_POR_STATUS: Record<StatusDemanda, number> = {
  backlog: 0,
  planejada: 0,
  recorrente: 0,
  standby: 0,
  cancelada: 0,
  analise: 0.1,
  aguardando_gate_analise: 0.15,
  design: 0.25,
  aguardando_gate_design: 0.3,
  build: 0.5,
  aguardando_gate_build: 0.6,
  qa: 0.7,
  aguardando_homologacao: 0.85,
  release: 0.95,
  entregue: 1,
};

export type DemandaDoProgresso = Pick<Demanda, "status" | "tipo" | "entregavelId">;

/**
 * Progresso do projeto, calculado das demandas (decisão de 2026-11-16: o número
 * não depende de alguém lembrar de marcar entregável).
 *
 * - Entram as demandas de projeto não canceladas; sustentação não é escopo.
 * - Entregável com demanda avança pela média do avanço delas e conclui sozinho
 *   quando todas estão entregues.
 * - Entregável sem demanda (feito fora da esteira) segue a marcação manual.
 * - Demanda de projeto sem entregável conta como uma unidade de peso 1, para o
 *   escopo que entrou depois do contrato não ficar fora da conta.
 *
 * Ponderado pelo peso e não contagem simples porque "migrar 12 Flows" e
 * "ajustar um layout" contariam igual numa média — e o número mentiria
 * exatamente quando mais importa, perto do fim.
 */
export function progressoDoProjeto(
  entregaveis: Pick<Entregavel, "id" | "peso" | "concluido">[],
  demandas: DemandaDoProgresso[] = []
): Progresso {
  const validas = demandas.filter((d) => d.tipo === "projeto" && d.status !== "cancelada");
  const ids = new Set(entregaveis.map((e) => e.id));
  const fracoes = new Map<string, number[]>();
  const soltas: number[] = [];
  for (const d of validas) {
    const f = AVANCO_POR_STATUS[d.status] ?? 0;
    if (d.entregavelId && ids.has(d.entregavelId)) {
      fracoes.set(d.entregavelId, [...(fracoes.get(d.entregavelId) ?? []), f]);
    } else {
      soltas.push(f);
    }
  }

  const porEntregavel: Progresso["porEntregavel"] = {};
  let pesoTotal = 0;
  let pesoConcluido = 0;
  let concluidos = 0;
  for (const e of entregaveis) {
    const peso = Math.max(1, e.peso);
    const fs = fracoes.get(e.id);
    const fracao = fs ? fs.reduce((s, f) => s + f, 0) / fs.length : e.concluido ? 1 : 0;
    porEntregavel[e.id] = { fracao, automatico: !!fs };
    pesoTotal += peso;
    pesoConcluido += peso * fracao;
    if (fracao >= 1) concluidos += 1;
  }
  pesoTotal += soltas.length;
  pesoConcluido += soltas.reduce((s, f) => s + f, 0);

  return {
    pct: pesoTotal === 0 ? 0 : Math.round((pesoConcluido / pesoTotal) * 100),
    pesoConcluido: Math.round(pesoConcluido * 100) / 100,
    pesoTotal,
    concluidos,
    total: entregaveis.length,
    demandas: validas.length,
    demandasEntregues: validas.filter((d) => d.status === "entregue").length,
    porEntregavel,
  };
}

/** "8 de 12 entregáveis · 0 de 20 demandas entregues" — a legenda do percentual. */
export function legendaDoProgresso(p: Progresso): string {
  const partes = [`${p.concluidos} de ${p.total} entregáveis`];
  if (p.demandas > 0) partes.push(`${p.demandasEntregues} de ${p.demandas} demandas entregues`);
  return partes.join(" · ");
}

export type ContratoCompleto = Contrato & { entregaveis: Entregavel[] };
