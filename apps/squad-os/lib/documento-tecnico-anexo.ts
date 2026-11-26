import { EMISSOR_DOCUMENTOS } from "@/lib/marca";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { prisma } from "@/lib/prisma";
import { removerArquivo } from "@/lib/arquivo";
import { chaveDia } from "@/lib/horas";
import { gerarPdfRoteiro, type TipoDeDocumento } from "@/lib/roteiro-pdf";
import { BUCKET_ANEXOS, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { caminhoDoDocumentoTecnico } from "@/lib/visao-cliente";

// Documento técnico de construção no card (decisão de 2026-11-26): o PDF do
// `03-documento-tecnico.md` que o arquiteto escreve em todo design (skill
// `documento-tecnico`), na seção de anexos, no mesmo desenho do roteiro do
// cliente (lib/roteiro-anexo.ts). Sem isso ele ficava só no git, longe de quem
// constrói e do time do outro sistema.
//
// Um anexo por demanda, sempre no mesmo caminho: um design refeito substitui o
// arquivo. Só o time o enxerga (lib/visao-cliente.ts).

export const AUTOR_DO_DOCUMENTO_TECNICO = "Esteira (design)";

export const nomeDoAnexoDoDocumentoTecnico = (codigo: string) => `Documento técnico - ${codigo}.pdf`;

const DOCUMENTO_TECNICO: TipoDeDocumento = {
  rotulo: "Documento técnico",
  contexto: "construção",
  rodape: "documento técnico de construção",
  vazio: "Este documento técnico está vazio.",
};

/** Hash do texto, para o sync só refazer o PDF quando ele mudou. Vazio sem texto. */
export function hashDoDocumentoTecnico(markdown: string): string {
  return markdown.trim() ? createHash("sha256").update(markdown, "utf8").digest("hex") : "";
}

interface DemandaDoDocumento {
  id: string;
  code: string;
  titulo: string;
  clienteNome: string;
}

/**
 * Publica (ou substitui) o PDF do documento técnico como anexo da demanda; com
 * texto vazio, remove o anexo. Nunca lança: é efeito colateral do sync, e uma
 * falha de armazenamento não pode fazer o espelho da demanda falhar junto.
 */
export async function publicarDocumentoTecnicoComoAnexo(
  d: DemandaDoDocumento,
  markdown: string
): Promise<"publicado" | "removido" | "ignorado"> {
  const caminho = caminhoDoDocumentoTecnico(d.id);
  try {
    if (!markdown.trim()) {
      const existente = await prisma.anexo.findUnique({ where: { caminho }, select: { id: true } });
      if (!existente) return "removido";
      await prisma.anexo.delete({ where: { caminho } });
      await removerArquivo(BUCKET_ANEXOS, caminho);
      return "removido";
    }
    if (!serviceRoleConfigurado()) {
      console.error("documento-tecnico-anexo: armazenamento não configurado — o documento não virou anexo", { demanda: d.code });
      return "ignorado";
    }

    const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
    const pdf = await gerarPdfRoteiro(
      markdown,
      { clienteNome: d.clienteNome, codigo: d.code, titulo: d.titulo, emissor: EMISSOR_DOCUMENTOS, geradoEm: chaveDia(new Date()) },
      logo,
      DOCUMENTO_TECNICO
    );
    const { error } = await createServiceClient()
      .storage.from(BUCKET_ANEXOS)
      .upload(caminho, pdf, { contentType: "application/pdf", upsert: true });
    if (error) throw error;

    const dados = { nome: nomeDoAnexoDoDocumentoTecnico(d.code), tamanho: pdf.length, tipo: "application/pdf" };
    await prisma.anexo.upsert({
      where: { caminho },
      create: { demandaId: d.id, caminho, autor: AUTOR_DO_DOCUMENTO_TECNICO, autorEmail: "", ...dados },
      // A data acompanha a versão do design: é o que diz ao leitor de quando é o arquivo.
      update: { ...dados, criadoEm: new Date() },
    });
    return "publicado";
  } catch (err) {
    console.error("documento-tecnico-anexo: falha ao publicar o documento técnico como anexo", { demanda: d.code, err });
    return "ignorado";
  }
}
