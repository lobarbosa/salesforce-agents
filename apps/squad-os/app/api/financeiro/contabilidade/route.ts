import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { subirArquivo, removerArquivo } from "@/lib/arquivo";
import { BUCKET_FINANCEIRO } from "@/lib/supabase/storage";
import { ehTipoDoc } from "@/lib/contabilidade";
import { chaveDia, ehChaveMes } from "@/lib/horas";

// Envio de documentos do mês: vários arquivos de uma vez, cada um com o seu
// tipo (form: competencia, arquivo[], tipo[] na mesma ordem). Ou sobe tudo ou
// nada: se um arquivo falha, os que já subiram saem do bucket.
export async function POST(request: NextRequest) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;

  const form = await request.formData();
  const competencia = String(form.get("competencia") ?? "");
  if (!ehChaveMes(competencia) || competencia > chaveDia(new Date()).slice(0, 7)) {
    return NextResponse.json({ error: "competência inválida" }, { status: 400 });
  }
  const arquivos = form.getAll("arquivo").filter((a): a is File => a instanceof File);
  const tipos = form.getAll("tipo").map(String);
  if (!arquivos.length) return NextResponse.json({ error: "nenhum arquivo enviado" }, { status: 400 });
  if (tipos.length !== arquivos.length || !tipos.every(ehTipoDoc)) {
    return NextResponse.json({ error: "informe o tipo de cada arquivo" }, { status: 400 });
  }

  const subidos: { caminho: string; nome: string; tipo: string; mime: string; tamanho: number }[] = [];
  for (const [i, arquivo] of arquivos.entries()) {
    const r = await subirArquivo(BUCKET_FINANCEIRO, `contabilidade/${competencia}`, arquivo);
    if ("erro" in r) {
      await Promise.all(subidos.map((s) => removerArquivo(BUCKET_FINANCEIRO, s.caminho)));
      return r.erro;
    }
    subidos.push({ ...r, tipo: tipos[i], mime: arquivo.type, tamanho: arquivo.size });
  }

  await prisma.documentoContabil.createMany({
    data: subidos.map((s) => ({
      competencia,
      tipo: s.tipo,
      nome: s.nome,
      caminho: s.caminho,
      mime: s.mime,
      tamanho: s.tamanho,
      enviadoPorEmail: acesso.usuario.email,
    })),
  });
  return NextResponse.json({ enviados: subidos.length }, { status: 201 });
}
