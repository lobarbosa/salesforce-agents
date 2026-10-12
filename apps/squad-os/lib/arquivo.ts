import { NextResponse } from "next/server";
import { createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { conferirTipo, TAMANHO_MAX_ARQUIVO, TAMANHO_MAX_MB, type PerfilUpload } from "@/lib/upload-regras";

export { TAMANHO_MAX_ARQUIVO } from "@/lib/upload-regras";

// Mesmo critério dos anexos de demanda: o nome original fica no banco; só a
// chave do objeto no Storage é normalizada (acento e espaço em chave dão erro).
export function chaveSegura(nome: string): string {
  return (
    nome
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-zA-Z0-9._-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80) || "arquivo"
  );
}

const ZIP = [0x50, 0x4b, 0x03, 0x04];
const OLE = [0xd0, 0xcf, 0x11, 0xe0];
// Assinatura dos primeiros bytes por extensão. Formato de texto (csv, txt,
// md, xml) não tem assinatura: confere só que não é binário (sem byte nulo).
const ASSINATURA: Record<string, number[][]> = {
  pdf: [[0x25, 0x50, 0x44, 0x46]],
  png: [[0x89, 0x50, 0x4e, 0x47]],
  jpg: [[0xff, 0xd8, 0xff]],
  jpeg: [[0xff, 0xd8, 0xff]],
  gif: [[0x47, 0x49, 0x46, 0x38]],
  webp: [[0x52, 0x49, 0x46, 0x46]],
  xlsx: [ZIP],
  docx: [ZIP],
  pptx: [ZIP],
  xls: [OLE],
};
const TEXTO = new Set(["csv", "txt", "md", "xml"]);

/** O conteúdo bate com a extensão? Barato: lê só os primeiros 4 KB. */
export function conteudoBate(extensao: string, inicio: Uint8Array): boolean {
  if (TEXTO.has(extensao)) return !inicio.includes(0);
  const opcoes = ASSINATURA[extensao];
  if (!opcoes) return false;
  return opcoes.some((sig) => sig.every((b, i) => inicio[i] === b));
}

/**
 * Valida um arquivo de formulário contra o perfil (tamanho, extensão, MIME
 * declarado e assinatura do conteúdo). Devolve o MIME canônico ou o erro.
 */
export async function validarArquivo(
  arquivo: File,
  perfil: PerfilUpload
): Promise<{ ok: true; mime: string } | { ok: false; erro: string; status: number }> {
  if (arquivo.size === 0) return { ok: false, erro: "arquivo vazio", status: 400 };
  if (arquivo.size > TAMANHO_MAX_ARQUIVO) {
    return { ok: false, erro: `arquivo passa de ${TAMANHO_MAX_MB} MB`, status: 413 };
  }
  const tipo = conferirTipo(perfil, arquivo.name || "", arquivo.type);
  if (!tipo.ok) return { ok: false, erro: tipo.erro, status: 415 };
  const inicio = new Uint8Array(await arquivo.slice(0, 4096).arrayBuffer());
  if (!conteudoBate(tipo.extensao, inicio)) {
    return { ok: false, erro: `o conteúdo do arquivo não é um .${tipo.extensao} válido`, status: 415 };
  }
  return { ok: true, mime: tipo.mime };
}

/** Sobe um arquivo de formulário para um bucket privado. Devolve o caminho ou uma resposta de erro pronta. */
export async function subirArquivo(
  bucket: string,
  prefixo: string,
  arquivo: File,
  perfil: PerfilUpload
): Promise<{ caminho: string; nome: string; mime: string } | { erro: NextResponse }> {
  if (!serviceRoleConfigurado()) {
    return { erro: NextResponse.json({ error: "armazenamento não configurado (falta SUPABASE_SERVICE_ROLE_KEY)" }, { status: 503 }) };
  }
  const valido = await validarArquivo(arquivo, perfil);
  if (!valido.ok) return { erro: NextResponse.json({ error: valido.erro }, { status: valido.status }) };
  const nome = (arquivo.name || "arquivo").slice(0, 200);
  const caminho = `${prefixo}/${crypto.randomUUID()}-${chaveSegura(nome)}`;
  const { error } = await createServiceClient()
    .storage.from(bucket)
    // contentType canônico da extensão, nunca o que o navegador declarou.
    .upload(caminho, arquivo, { contentType: valido.mime, upsert: false });
  if (error) return { erro: NextResponse.json({ error: `falha ao subir o arquivo: ${error.message}` }, { status: 502 }) };
  return { caminho, nome, mime: valido.mime };
}

/**
 * Remove um objeto do bucket sem nunca lançar: é sempre limpeza (rollback de
 * upload ou arquivo substituído), e uma falha aqui não pode transformar uma
 * operação que deu certo em 500 — nem impedir as outras limpezas de rodarem.
 * Devolve se conseguiu, e loga quando não, pra o órfão ser achável.
 */
export async function removerArquivo(bucket: string, caminho: string): Promise<boolean> {
  if (!caminho || !serviceRoleConfigurado()) return false;
  try {
    const { error } = await createServiceClient().storage.from(bucket).remove([caminho]);
    if (error) throw error;
    return true;
  } catch (err) {
    console.error("arquivo: falha ao remover do bucket (ficou órfão)", { bucket, caminho, err });
    return false;
  }
}

/** Download por URL assinada de 60 s: cada clique passa de novo pelo gate de acesso. */
export async function redirecionarDownload(bucket: string, caminho: string, nome: string) {
  if (!serviceRoleConfigurado()) return NextResponse.json({ error: "armazenamento não configurado" }, { status: 503 });
  const { data, error } = await createServiceClient()
    .storage.from(bucket)
    .createSignedUrl(caminho, 60, { download: nome });
  if (error || !data) return NextResponse.json({ error: "falha ao gerar o link de download" }, { status: 502 });
  return NextResponse.redirect(data.signedUrl);
}
