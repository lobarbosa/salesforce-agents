// Regras puras dos documentos da contabilidade — testadas em scripts/testa-contabilidade.ts.

export const TIPOS_DOC = ["balancete", "dre", "guia_imposto", "relacao_notas", "outro"] as const;
export type TipoDoc = (typeof TIPOS_DOC)[number];

export const ROTULO_TIPO: Record<TipoDoc, string> = {
  balancete: "Balancete",
  dre: "DRE contábil",
  guia_imposto: "Guia de imposto",
  relacao_notas: "Relação de notas",
  outro: "Outro",
};

export function ehTipoDoc(s: string): s is TipoDoc {
  return (TIPOS_DOC as readonly string[]).includes(s);
}

// O que a conciliação precisa todo mês. Balancete OU DRE basta para o
// resultado contábil; guias e relação de notas têm conferência própria.
const ESPERADOS: { item: string; tipos: TipoDoc[] }[] = [
  { item: "Balancete ou DRE contábil", tipos: ["balancete", "dre"] },
  { item: "Guias de impostos", tipos: ["guia_imposto"] },
  { item: "Relação de notas emitidas", tipos: ["relacao_notas"] },
];

export interface ItemChecklist {
  item: string;
  recebidos: number;
}

/** O que já chegou e o que falta, a partir dos tipos dos documentos ativos do mês. */
export function checklist(tipos: string[]): ItemChecklist[] {
  return ESPERADOS.map(({ item, tipos: aceitos }) => ({
    item,
    recebidos: tipos.filter((t) => (aceitos as string[]).includes(t)).length,
  }));
}

/** Palpite do tipo pelo nome do arquivo, para a pessoa só confirmar (sem redigitar). */
export function tipoPeloNome(nome: string): TipoDoc {
  const n = nome
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase();
  // Sigla só conta como palavra inteira ("DRE_09" sim, "padre" não): "_" e dígito separam.
  const sigla = (...s: string[]) => new RegExp(`(^|[^a-z])(${s.join("|")})([^a-z]|$)`).test(n);
  if (n.includes("balancete")) return "balancete";
  if (sigla("dre") || n.includes("demonstracao")) return "dre";
  if (n.includes("guia") || sigla("darf", "das", "gps", "iss", "irrf", "pis", "cofins", "csll", "inss", "fgts")) return "guia_imposto";
  if (n.includes("nota") || n.includes("relacao") || n.includes("faturamento") || sigla("nfs", "nfse", "nfe")) return "relacao_notas";
  return "outro";
}

export function rotuloMes(mes: string): string {
  return `${mes.slice(5, 7)}/${mes.slice(0, 4)}`;
}

/** A contabilidade fecha o mês anterior: é a competência padrão da tela. */
export function competenciaPadrao(hojeMes: string): string {
  const [a, m] = hojeMes.split("-").map(Number);
  const d = new Date(Date.UTC(a, m - 2, 1));
  return d.toISOString().slice(0, 7);
}
