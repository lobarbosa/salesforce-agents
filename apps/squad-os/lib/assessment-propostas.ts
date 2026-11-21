// Melhorias do assessment propostas ao cliente (2026-11-21). Puro, sem banco:
// importável pela tela, pelo copiloto e pelos testes.
//
// O assessment guarda as recomendações como JSON no cliente (título,
// severidade, área), sem id. O id aqui é derivado do conteúdo (área + título,
// normalizados), então é o mesmo a cada leitura e não exige migrar o JSON. Se
// um assessment novo reescrever a recomendação com outro título, ela conta como
// outra, o que é o certo: é outro diagnóstico.

export interface Recomendacao {
  titulo: string;
  severidade: string;
  area: string;
}

export interface DemandaDaProposta {
  code: string;
  titulo: string;
  status: string;
  origemAssessmentId: string;
  propostaClienteEm: Date | string | null;
  propostaDecisao: string;
}

export const SEVERIDADE_ORDEM: Record<string, number> = { critica: 0, alta: 1, media: 2, baixa: 3 };

/** Teto de propostas abertas de uma vez pelo copiloto. */
export const MAX_PROPOSTAS_POR_VEZ = 10;

function normalizar(texto: string): string {
  return texto
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

/** FNV-1a de 32 bits em hexadecimal: curto, estável e sem dependência de crypto no browser. */
function fnv1a(texto: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < texto.length; i++) {
    h ^= texto.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(16).padStart(8, "0");
}

export function idDaRecomendacao(r: Pick<Recomendacao, "titulo" | "area">): string {
  return `rec-${fnv1a(`${normalizar(r.area)}|${normalizar(r.titulo)}`)}`;
}

export function lerRecomendacoes(valor: unknown): Recomendacao[] {
  if (!Array.isArray(valor)) return [];
  return valor
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object" && typeof (r as Record<string, unknown>).titulo === "string")
    .map((r) => ({
      titulo: String(r.titulo).trim(),
      severidade: String(r.severidade ?? "baixa"),
      area: String(r.area ?? ""),
    }))
    .filter((r) => r.titulo);
}

/** A proposta ainda espera o cliente decidir. */
export function propostaPendente(d: { propostaClienteEm?: Date | string | null; propostaDecisao?: string | null }): boolean {
  return !!d.propostaClienteEm && !d.propostaDecisao;
}

export type SituacaoMelhoria =
  | { tipo: "livre" }
  | { tipo: "proposta"; code: string; decisao: "pendente" | "aprovada" | "recusada" }
  | { tipo: "demanda"; code: string; status: string };

export interface MelhoriaDoAssessment extends Recomendacao {
  id: string;
  situacao: SituacaoMelhoria;
}

/**
 * Cada recomendação com o que já aconteceu com ela. Uma recomendação só fica
 * "livre" se nenhuma demanda nasceu dela; recusada pelo cliente continua
 * ligada à demanda cancelada e não volta a ser oferecida.
 */
export function melhoriasDoAssessment(recomendacoes: Recomendacao[], demandas: DemandaDaProposta[]): MelhoriaDoAssessment[] {
  const porOrigem = new Map<string, DemandaDaProposta>();
  for (const d of demandas) {
    if (!d.origemAssessmentId) continue;
    const atual = porOrigem.get(d.origemAssessmentId);
    // Se houver mais de uma (não deveria), a que não foi cancelada manda.
    if (!atual || (atual.status === "cancelada" && d.status !== "cancelada")) porOrigem.set(d.origemAssessmentId, d);
  }
  const vistos = new Set<string>();
  const saida: MelhoriaDoAssessment[] = [];
  for (const r of recomendacoes) {
    const id = idDaRecomendacao(r);
    if (vistos.has(id)) continue;
    vistos.add(id);
    const d = porOrigem.get(id);
    let situacao: SituacaoMelhoria = { tipo: "livre" };
    if (d && d.propostaClienteEm) {
      situacao = {
        tipo: "proposta",
        code: d.code,
        decisao: d.propostaDecisao === "aprovada" ? "aprovada" : d.propostaDecisao === "recusada" ? "recusada" : "pendente",
      };
    } else if (d) {
      situacao = { tipo: "demanda", code: d.code, status: d.status };
    }
    saida.push({ ...r, id, situacao });
  }
  return saida.sort((a, b) => (SEVERIDADE_ORDEM[a.severidade] ?? 9) - (SEVERIDADE_ORDEM[b.severidade] ?? 9));
}

/** O que a tela e o copiloto dizem da proposta, na linguagem do cliente. */
export const DECISAO_LABEL: Record<string, string> = {
  pendente: "esperando o cliente aprovar",
  aprovada: "aprovada pelo cliente",
  recusada: "recusada pelo cliente",
};
