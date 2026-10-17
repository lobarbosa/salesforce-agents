// Limites do copiloto, num lugar só (rota + teste). O histórico da conversa
// vem inteiro do navegador a cada requisição — ou seja, é texto controlado por
// quem está do outro lado, não por nós. Sem teto, uma pessoa podia mandar uma
// conversa gigante (custo), inventar mensagens "system" com instruções novas
// (prompt injection com cara de instrução nossa) ou falsificar turnos antigos.

/** Mensagens por conversa — passou disto, é recomeçar o chat. */
export const MAX_MENSAGENS = 40;
/** Caracteres de texto por mensagem (o textarea do Copiloto usa o mesmo número). */
export const MAX_CHARS_MENSAGEM = 4000;
/** Caracteres de texto somados na conversa inteira. */
export const MAX_CHARS_CONVERSA = 60_000;
/** Demandas que o copiloto cria numa mesma requisição (uma volta da conversa). */
export const MAX_DEMANDAS_POR_REQUISICAO = 1;
/** Demandas que o copiloto cria por pessoa, por cliente, na última hora. */
export const MAX_DEMANDAS_POR_HORA = 5;
/** Requisições por pessoa por minuto (melhor esforço: memória do processo). */
export const MAX_REQUISICOES_POR_MINUTO = 20;
// Teto diário durável por usuário (Postgres, lib/limite-uso.ts). O por-minuto
// acima é em memória e só segura rajada numa instância.
export const MAX_REQUISICOES_POR_DIA = 300;

const PAPEIS_ACEITOS = new Set(["user", "assistant"]);

export type MensagemLimpa = { id: string; role: "user" | "assistant"; parts: { type: "text"; text: string }[] };
type Resultado = { ok: true; mensagens: MensagemLimpa[] } | { ok: false; erro: string };

function textoDaParte(parte: unknown): string {
  if (!parte || typeof parte !== "object") return "";
  const p = parte as Record<string, unknown>;
  return typeof p.text === "string" ? p.text : "";
}

/**
 * Confere o formato e o tamanho do histórico que o navegador mandou e devolve
 * só o que o servidor aceita como contexto: mensagens `user`/`assistant` com
 * as partes de texto. Partes de ferramenta do histórico ficam de fora de
 * propósito — um "resultado de ferramenta" forjado no navegador teria cara de
 * dado nosso; o que o modelo precisar de novo ele consulta de novo, pela
 * ferramenta, no servidor. O que não cabe nos limites é recusado com uma
 * mensagem que o Copiloto consegue mostrar.
 */
export function validarMensagens(mensagens: unknown): Resultado {
  if (!Array.isArray(mensagens) || mensagens.length === 0) {
    return { ok: false, erro: "conversa vazia ou em formato inválido" };
  }
  if (mensagens.length > MAX_MENSAGENS) {
    return { ok: false, erro: `conversa longa demais (máximo ${MAX_MENSAGENS} mensagens) — comece uma nova` };
  }
  let total = 0;
  const limpas: MensagemLimpa[] = [];
  for (const [i, m] of mensagens.entries()) {
    if (!m || typeof m !== "object") return { ok: false, erro: "mensagem em formato inválido" };
    const msg = m as Record<string, unknown>;
    if (typeof msg.role !== "string" || !PAPEIS_ACEITOS.has(msg.role)) {
      // "system" vindo do navegador é exatamente a injeção que queremos
      // impedir: as instruções do copiloto são montadas só no servidor.
      return { ok: false, erro: "papel de mensagem não permitido" };
    }
    if (!Array.isArray(msg.parts)) return { ok: false, erro: "mensagem em formato inválido" };
    const textos = msg.parts
      .filter((p): p is Record<string, unknown> => !!p && typeof p === "object" && (p as Record<string, unknown>).type === "text")
      .map(textoDaParte);
    const daMensagem = textos.reduce((n, t) => n + t.length, 0);
    if (daMensagem > MAX_CHARS_MENSAGEM) {
      return { ok: false, erro: `mensagem longa demais (máximo ${MAX_CHARS_MENSAGEM} caracteres)` };
    }
    total += daMensagem;
    if (textos.length === 0 || daMensagem === 0) continue;
    limpas.push({
      id: typeof msg.id === "string" ? msg.id.slice(0, 100) : `m${i}`,
      role: msg.role as "user" | "assistant",
      parts: textos.map((text) => ({ type: "text" as const, text })),
    });
  }
  if (total > MAX_CHARS_CONVERSA) {
    return { ok: false, erro: "conversa longa demais — comece uma nova" };
  }
  if (limpas.length === 0 || limpas[limpas.length - 1].role !== "user") {
    return { ok: false, erro: "a última mensagem precisa ser sua" };
  }
  return { ok: true, mensagens: limpas };
}

// Janela deslizante em memória. Em serverless cada instância tem a sua, então
// isto é freio de mão contra loop/abuso de uma aba, não cota contábil — a cota
// que importa (demandas criadas) é contada no banco, ver ferramentas.ts.
const janelas = new Map<string, number[]>();

export function dentroDoLimiteDeRequisicoes(chave: string, agora = Date.now()): boolean {
  const desde = agora - 60_000;
  const recentes = (janelas.get(chave) ?? []).filter((t) => t > desde);
  if (recentes.length >= MAX_REQUISICOES_POR_MINUTO) {
    janelas.set(chave, recentes);
    return false;
  }
  recentes.push(agora);
  janelas.set(chave, recentes);
  if (janelas.size > 5000) {
    for (const [k, v] of janelas) if (v.every((t) => t <= desde)) janelas.delete(k);
  }
  return true;
}
