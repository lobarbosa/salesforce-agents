import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { BUCKET_ANEXOS, createStorageClient, storageConfigurado } from "@/lib/supabase/storage";

const TAMANHO_MAX = 10 * 1024 * 1024;
const NOME_MAX = 200;

// O nome original vai pro banco como está (é o que a pessoa reconhece na
// lista); só a chave no Storage é normalizada, porque acento e espaço em
// chave de objeto viram fonte de erro difícil de ver.
function chaveSegura(nome: string): string {
  return (
    nome
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-zA-Z0-9._-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 80) || "arquivo"
  );
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  if (!storageConfigurado()) {
    return NextResponse.json(
      { error: "anexos ainda não configurados (falta SUPABASE_SERVICE_ROLE_KEY)" },
      { status: 503 }
    );
  }

  const form = await request.formData();
  const arquivo = form.get("arquivo");
  if (!(arquivo instanceof File) || arquivo.size === 0) {
    return NextResponse.json({ error: "nenhum arquivo enviado" }, { status: 400 });
  }
  if (arquivo.size > TAMANHO_MAX) {
    return NextResponse.json(
      { error: `arquivo passa de ${TAMANHO_MAX / 1024 / 1024} MB` },
      { status: 400 }
    );
  }

  const nome = (arquivo.name || "arquivo").slice(0, NOME_MAX);
  const caminho = `${id}/${crypto.randomUUID()}-${chaveSegura(nome)}`;

  const storage = createStorageClient();
  const { error: uploadErro } = await storage.storage
    .from(BUCKET_ANEXOS)
    .upload(caminho, arquivo, { contentType: arquivo.type || undefined, upsert: false });
  if (uploadErro) {
    return NextResponse.json({ error: `falha ao subir o arquivo: ${uploadErro.message}` }, { status: 502 });
  }

  try {
    const anexo = await prisma.anexo.create({
      data: {
        demandaId: id,
        nome,
        caminho,
        tamanho: arquivo.size,
        tipo: arquivo.type || "",
        autor: usuario.nome.trim() || usuario.email,
        autorEmail: usuario.email,
      },
    });
    return NextResponse.json(anexo, { status: 201 });
  } catch (e) {
    // O objeto já subiu; sem a linha no banco ele fica órfão e invisível,
    // ocupando espaço pra sempre. Desfaz antes de devolver o erro.
    await storage.storage.from(BUCKET_ANEXOS).remove([caminho]);
    throw e;
  }
}
