import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { BUCKET_ANEXOS } from "@/lib/supabase/storage";
import { removerArquivo, subirArquivo } from "@/lib/arquivo";

// O nome original vai pro banco como está (é o que a pessoa reconhece na
// lista); só a chave no Storage é normalizada (lib/arquivo.ts). Tamanho,
// extensão, MIME e assinatura do conteúdo são conferidos lá também — o
// `accept` do input na tela é conveniência, não gate.
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const form = await request.formData();
  const arquivo = form.get("arquivo");
  if (!(arquivo instanceof File) || arquivo.size === 0) {
    return NextResponse.json({ error: "nenhum arquivo enviado" }, { status: 400 });
  }

  const r = await subirArquivo(BUCKET_ANEXOS, id, arquivo, "anexo");
  if ("erro" in r) return r.erro;

  try {
    const anexo = await prisma.anexo.create({
      data: {
        demandaId: id,
        nome: r.nome,
        caminho: r.caminho,
        tamanho: arquivo.size,
        tipo: r.mime,
        autor: usuario.nome.trim() || usuario.email,
        autorEmail: usuario.email,
      },
    });
    return NextResponse.json(anexo, { status: 201 });
  } catch (e) {
    // O objeto já subiu; sem a linha no banco ele fica órfão e invisível,
    // ocupando espaço pra sempre. Desfaz antes de devolver o erro.
    await removerArquivo(BUCKET_ANEXOS, r.caminho);
    throw e;
  }
}
