import { NextResponse } from "next/server";
import { createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";

export const TAMANHO_MAX_ARQUIVO = 10 * 1024 * 1024;

// Mesmo critério dos anexos de demanda: o nome original fica no banco; só a
// chave do objeto no Storage é normalizada (acento e espaço em chave dão erro).
export function chaveSegura(nome: string): string {
  return (
    nome
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-zA-Z0-9._-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80) || "arquivo"
  );
}

/** Sobe um arquivo de formulário para um bucket privado. Devolve o caminho ou uma resposta de erro pronta. */
export async function subirArquivo(
  bucket: string,
  prefixo: string,
  arquivo: File
): Promise<{ caminho: string; nome: string } | { erro: NextResponse }> {
  if (!serviceRoleConfigurado()) {
    return { erro: NextResponse.json({ error: "armazenamento não configurado (falta SUPABASE_SERVICE_ROLE_KEY)" }, { status: 503 }) };
  }
  if (arquivo.size === 0) return { erro: NextResponse.json({ error: "arquivo vazio" }, { status: 400 }) };
  if (arquivo.size > TAMANHO_MAX_ARQUIVO) {
    return { erro: NextResponse.json({ error: "arquivo passa de 10 MB" }, { status: 400 }) };
  }
  const nome = (arquivo.name || "arquivo").slice(0, 200);
  const caminho = `${prefixo}/${crypto.randomUUID()}-${chaveSegura(nome)}`;
  const { error } = await createServiceClient()
    .storage.from(bucket)
    .upload(caminho, arquivo, { contentType: arquivo.type || undefined, upsert: false });
  if (error) return { erro: NextResponse.json({ error: `falha ao subir o arquivo: ${error.message}` }, { status: 502 }) };
  return { caminho, nome };
}

export async function removerArquivo(bucket: string, caminho: string) {
  if (caminho && serviceRoleConfigurado()) await createServiceClient().storage.from(bucket).remove([caminho]);
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
