// Contas a receber (26/11/2026): regras puras das NFS-e emitidas e dos
// recebimentos. Sem banco aqui — lib/receber-data.ts lê e grava; os testes
// (scripts/testa-receber.ts) exercitam estas funções.
//
// Nota = número + data de emissão: a numeração recomeçou em nov/2026, então
// "nota 10" sozinho é ambíguo. O registro antigo (ops.agent_state
// financeiro/nfse_recebimentos, feito à mão antes desta tela) usa a chave
// "<nº>" — vale para a nota MAIS ANTIGA com aquele número — ou "<nº>@AAAA-MM"
// (mês da emissão). As mesmas regras de konecta-agents/integrations/nfse.py.

export const FORMAS = ["pix", "boleto", "ted", "cartao", "outro"] as const;
export type Forma = (typeof FORMAS)[number];
export const ROTULO_FORMA: Record<Forma, string> = {
  pix: "PIX",
  boleto: "Boleto",
  ted: "TED/transferência",
  cartao: "Cartão",
  outro: "Outro",
};

/** Nota como a conciliação contábil publica (ops.agent_state accounting_reconciliation_agent/nfse). */
export interface NotaPublicada {
  numero: string | null;
  data_emissao: string | null; // YYYY-MM-DD
  cliente: string | null;
  valor: number;
  valor_liquido: number | null;
  vencimento: string | null; // YYYY-MM-DD
  documento?: string | null; // id do documento contábil de onde a nota foi lida
  arquivo?: string | null;
}

export interface RegistroRecebimento {
  id: string;
  numero: string;
  emissao: string; // YYYY-MM-DD
  recebidoEm: string; // YYYY-MM-DD
  valorRecebido: number;
  forma: string;
  observacao: string;
  registradoPorEmail: string;
  registradoEm: string; // ISO
  estornadoEm: string | null;
  estornadoPorEmail: string | null;
  estornoMotivo: string;
}

export type Situacao = "recebida" | "vencida" | "a_vencer" | "sem_vencimento";
export const ROTULO_SITUACAO: Record<Situacao, string> = {
  recebida: "recebida",
  vencida: "vencida",
  a_vencer: "a vencer",
  sem_vencimento: "sem vencimento",
};

export interface NotaVista {
  chave: string; // "<nº>@<emissão>"
  numero: string;
  emissao: string;
  cliente: string;
  valor: number;
  valorLiquido: number | null;
  /** O que se espera receber: o líquido da nota (após retenções) ou, sem ele, o valor. */
  esperado: number;
  vencimento: string | null;
  documento: string | null;
  arquivo: string | null;
  situacao: Situacao;
  /** Recebimento que vale (registro ativo no Squad OS ou o registro antigo). */
  recebimento: {
    em: string;
    valor: number | null;
    forma: string;
    observacao: string;
    por: string;
    origem: "squad_os" | "registro_antigo";
    id: string | null;
  } | null;
  /** Todos os registros feitos nesta tela, inclusive os desfeitos (histórico). */
  historico: RegistroRecebimento[];
}

export function numeroSemZeros(n: string | number | null | undefined): string {
  return String(n ?? "").trim().replace(/^0+(?=\d)/, "") || "0";
}

export function chaveNota(numero: string, emissao: string): string {
  return `${numeroSemZeros(numero)}@${emissao}`;
}

export function lerChave(chave: string): { numero: string; emissao: string } | null {
  const m = /^(\d+)@(\d{4}-\d{2}-\d{2})$/.exec(chave.trim());
  return m ? { numero: m[1], emissao: m[2] } : null;
}

const dia = (v: string | null | undefined) => (v && /^\d{4}-\d{2}-\d{2}/.test(v) ? v.slice(0, 10) : null);
const arred = (v: number) => Math.round(v * 100) / 100;

/** Data do registro antigo que vale para a nota, ou null. */
function legadoDa(
  numero: string,
  emissao: string,
  maisAntiga: Map<string, string>,
  legado: Record<string, string>
): string | null {
  const porMes = legado[`${numero}@${emissao.slice(0, 7)}`];
  if (porMes) return dia(porMes);
  if (maisAntiga.get(numero) === emissao && legado[numero]) return dia(legado[numero]);
  return null;
}

/**
 * Junta as notas publicadas, os registros desta tela e o registro antigo.
 * Nota sem número ou sem emissão fica de fora (não dá para registrar o
 * recebimento dela com segurança); a mesma nota publicada duas vezes conta uma.
 */
export function consolidar(
  notas: NotaPublicada[],
  registros: RegistroRecebimento[],
  legadoBruto: Record<string, string>,
  hoje: string
): NotaVista[] {
  const legado: Record<string, string> = {};
  for (const [k, v] of Object.entries(legadoBruto ?? {})) {
    const [n, mes] = k.split("@");
    legado[numeroSemZeros(n) + (mes ? `@${mes.trim()}` : "")] = String(v);
  }
  const validas = new Map<string, NotaPublicada & { numero: string; data_emissao: string }>();
  for (const n of notas) {
    const emissao = dia(n.data_emissao);
    if (!n.numero || !emissao || !(Number(n.valor) > 0)) continue;
    const chave = chaveNota(n.numero, emissao);
    if (!validas.has(chave)) validas.set(chave, { ...n, numero: numeroSemZeros(n.numero), data_emissao: emissao });
  }
  const maisAntiga = new Map<string, string>();
  for (const n of validas.values()) {
    const atual = maisAntiga.get(n.numero);
    if (!atual || n.data_emissao < atual) maisAntiga.set(n.numero, n.data_emissao);
  }
  const porChave = new Map<string, RegistroRecebimento[]>();
  for (const r of registros) {
    const k = chaveNota(r.numero, r.emissao);
    porChave.set(k, [...(porChave.get(k) ?? []), r]);
  }

  const out: NotaVista[] = [];
  for (const [chave, n] of validas) {
    const historico = (porChave.get(chave) ?? []).sort((a, b) => b.registradoEm.localeCompare(a.registradoEm));
    const ativo = historico.find((r) => !r.estornadoEm) ?? null;
    const antigo = ativo ? null : legadoDa(n.numero, n.data_emissao, maisAntiga, legado);
    const valorLiquido = n.valor_liquido === null || n.valor_liquido === undefined ? null : arred(Number(n.valor_liquido));
    const valor = arred(Number(n.valor));
    const vencimento = dia(n.vencimento);
    const recebimento = ativo
      ? {
          em: ativo.recebidoEm,
          valor: ativo.valorRecebido,
          forma: ativo.forma,
          observacao: ativo.observacao,
          por: ativo.registradoPorEmail,
          origem: "squad_os" as const,
          id: ativo.id,
        }
      : antigo
        ? { em: antigo, valor: null, forma: "", observacao: "", por: "", origem: "registro_antigo" as const, id: null }
        : null;
    out.push({
      chave,
      numero: n.numero,
      emissao: n.data_emissao,
      cliente: (n.cliente ?? "").trim(),
      valor,
      valorLiquido,
      esperado: valorLiquido ?? valor,
      vencimento,
      documento: n.documento ?? null,
      arquivo: n.arquivo ?? null,
      situacao: recebimento ? "recebida" : !vencimento ? "sem_vencimento" : vencimento < hoje ? "vencida" : "a_vencer",
      recebimento,
      historico,
    });
  }
  return out.sort(
    (a, b) => (a.vencimento ?? a.emissao).localeCompare(b.vencimento ?? b.emissao) || a.cliente.localeCompare(b.cliente)
  );
}

export interface DadosRecebimento {
  recebidoEm: string;
  valorRecebido: number;
  forma: Forma;
  observacao: string;
}

/** Valida o que a pessoa digitou. Devolve o erro em texto (para a tela) ou os dados limpos. */
export function validarRecebimento(
  nota: Pick<NotaVista, "emissao" | "esperado" | "valor">,
  entrada: { recebidoEm?: unknown; valorRecebido?: unknown; forma?: unknown; observacao?: unknown },
  hoje: string,
  lerValor: (s: string) => number | null
): { dados: DadosRecebimento } | { erro: string } {
  const recebidoEm = dia(String(entrada.recebidoEm ?? ""));
  if (!recebidoEm) return { erro: "informe a data do recebimento" };
  if (recebidoEm > hoje) return { erro: "a data do recebimento não pode ser no futuro" };
  if (recebidoEm < nota.emissao) return { erro: "a data do recebimento é anterior à emissão da nota" };
  const valorRecebido = lerValor(String(entrada.valorRecebido ?? "").slice(0, 30));
  if (valorRecebido === null) return { erro: "valor recebido inválido — use 1.234,56" };
  if (valorRecebido > nota.valor * 1.5) return { erro: "valor recebido muito acima do valor da nota — confira" };
  const forma = String(entrada.forma ?? "") as Forma;
  if (!FORMAS.includes(forma)) return { erro: "escolha a forma de recebimento" };
  return { dados: { recebidoEm, valorRecebido, forma, observacao: String(entrada.observacao ?? "").trim().slice(0, 500) } };
}

/** Diferença entre o recebido e o esperado (negativa = recebeu menos). null sem valor recebido. */
export function diferenca(n: Pick<NotaVista, "esperado" | "recebimento">): number | null {
  if (!n.recebimento || n.recebimento.valor === null) return null;
  return arred(n.recebimento.valor - n.esperado);
}

/** Totais dos cartões do topo. Recebido no mês: o registrado ou, no registro antigo, o esperado da nota. */
export function totais(notas: NotaVista[], hoje: string) {
  const mes = hoje.slice(0, 7);
  const ate30 = new Date(`${hoje}T00:00:00Z`);
  ate30.setUTCDate(ate30.getUTCDate() + 30);
  const lim = ate30.toISOString().slice(0, 10);
  const soma = (l: NotaVista[], f: (n: NotaVista) => number) => arred(l.reduce((s, n) => s + f(n), 0));
  const abertas = notas.filter((n) => n.situacao !== "recebida");
  const vencidas = notas.filter((n) => n.situacao === "vencida");
  const proximas = notas.filter((n) => n.situacao === "a_vencer" && n.vencimento! <= lim);
  const recebidasMes = notas.filter((n) => n.recebimento?.em.startsWith(mes));
  return {
    abertas: { qtd: abertas.length, valor: soma(abertas, (n) => n.esperado) },
    vencidas: { qtd: vencidas.length, valor: soma(vencidas, (n) => n.esperado) },
    proximas30: { qtd: proximas.length, valor: soma(proximas, (n) => n.esperado) },
    recebidasMes: { qtd: recebidasMes.length, valor: soma(recebidasMes, (n) => n.recebimento!.valor ?? n.esperado) },
  };
}
