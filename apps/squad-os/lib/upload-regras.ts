// Regras de upload que valem dos dois lados (tela e rota) — puro, sem
// dependência de servidor, pra poder ser importado por Client Component.

// A Vercel recusa corpo de requisição acima de 4,5 MB antes de chegar na rota
// (413 FUNCTION_PAYLOAD_TOO_LARGE, sem JSON). Com o teto antigo de 10 MB, um
// arquivo de 6 MB passava na tela e morria no caminho com um erro genérico.
// 4 MB por arquivo deixa folga pro multipart e pros outros campos — e os
// envios em lote mandam um arquivo por requisição.
export const TAMANHO_MAX_ARQUIVO = 4 * 1024 * 1024;
export const TAMANHO_MAX_MB = 4;

export type PerfilUpload = "anexo" | "conta" | "contabilidade";

// extensão → tipos MIME aceitos (o primeiro é o canônico, gravado no Storage).
const TIPOS: Record<string, readonly string[]> = {
  pdf: ["application/pdf"],
  png: ["image/png"],
  jpg: ["image/jpeg", "image/pjpeg"],
  jpeg: ["image/jpeg", "image/pjpeg"],
  gif: ["image/gif"],
  webp: ["image/webp"],
  xlsx: ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
  xls: ["application/vnd.ms-excel"],
  csv: ["text/csv", "application/csv", "text/plain", "application/vnd.ms-excel"],
  docx: ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
  pptx: ["application/vnd.openxmlformats-officedocument.presentationml.presentation"],
  txt: ["text/plain"],
  md: ["text/markdown", "text/x-markdown", "text/plain"],
  xml: ["application/xml", "text/xml"],
};

// Sem SVG/HTML em nenhum perfil: são documentos ativos (script) e o download
// sai de um domínio do Supabase com o nosso link.
export const EXTENSOES: Record<PerfilUpload, readonly string[]> = {
  anexo: ["pdf", "png", "jpg", "jpeg", "gif", "webp", "xlsx", "csv", "docx", "pptx", "txt", "md"],
  // Documento fiscal: NF em PDF/XML, boleto em PDF, foto do comprovante.
  conta: ["pdf", "xml", "png", "jpg", "jpeg", "webp"],
  contabilidade: ["pdf", "xlsx", "xls", "csv", "png", "jpg", "jpeg", "webp"],
};

/** Valor pro atributo `accept` do <input type="file">. */
export function acceptDo(perfil: PerfilUpload): string {
  return EXTENSOES[perfil].map((e) => `.${e}`).join(",");
}

export function extensaoDe(nome: string): string {
  const m = /\.([a-z0-9]+)$/i.exec(nome.trim());
  return m ? m[1].toLowerCase() : "";
}

/**
 * Confere extensão + MIME declarado. Devolve o MIME canônico (o que vai pro
 * Storage — nunca o que o navegador afirmou) ou a mensagem de erro.
 * MIME vazio ou `application/octet-stream` é aceito quando a extensão bate:
 * navegador manda isso pra .md/.csv com frequência, e o conteúdo ainda passa
 * pela checagem de assinatura no servidor (lib/arquivo.ts).
 */
export function conferirTipo(
  perfil: PerfilUpload,
  nome: string,
  mime: string
): { ok: true; mime: string; extensao: string } | { ok: false; erro: string } {
  const extensao = extensaoDe(nome);
  if (!EXTENSOES[perfil].includes(extensao)) {
    return { ok: false, erro: `tipo de arquivo não aceito (.${extensao || "?"}) — use ${EXTENSOES[perfil].join(", ")}` };
  }
  const aceitos = TIPOS[extensao];
  const declarado = (mime || "").split(";")[0].trim().toLowerCase();
  if (declarado && declarado !== "application/octet-stream" && !aceitos.includes(declarado)) {
    return { ok: false, erro: `o conteúdo declarado (${declarado}) não bate com a extensão .${extensao}` };
  }
  return { ok: true, mime: aceitos[0], extensao };
}

/** Mensagem pra resposta de erro de upload — inclusive o 413 da Vercel, que não vem em JSON. */
export async function erroDeUpload(res: Response, padrao: string): Promise<string> {
  if (res.status === 413) {
    return `arquivo grande demais — o limite é ${TAMANHO_MAX_MB} MB por arquivo`;
  }
  const corpo = await res.json().catch(() => null);
  return (corpo && typeof corpo.error === "string" && corpo.error) || padrao;
}
