import { EMISSOR_DOCUMENTOS } from "@/lib/marca";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { prisma } from "@/lib/prisma";
import { removerArquivo } from "@/lib/arquivo";
import { chaveDia } from "@/lib/horas";
import { gerarPdfRoteiro, type ImagemDoDocumento } from "@/lib/roteiro-pdf";
import { BUCKET_ANEXOS, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { caminhoDasEvidencias } from "@/lib/visao-cliente";

// Evidências de teste no card (decisão de 2026-11-16): um PDF com o roteiro que
// o agente de QA executou (`05-testes.md`) e as capturas de tela da rodada, no
// mesmo desenho do roteiro do cliente (lib/roteiro-anexo.ts). Até aqui a
// evidência ficava só no git e a captura de tela não era guardada.
//
// Um anexo por demanda, sempre no mesmo caminho: cada rodada de QA substitui o
// arquivo. Quem o enxerga é decidido em lib/visao-cliente.ts (o time sempre; o
// cliente, da homologação em diante).

export const AUTOR_DAS_EVIDENCIAS = "Esteira (QA)";

export const nomeDoAnexoDasEvidencias = (codigo: string) => `Evidências de teste - ${codigo}.pdf`;

// Tetos do que o sync aceita (o CLI já corta antes, em evidencias.py).
const MAX_IMAGENS = 12;
const MAX_BYTES_POR_IMAGEM = 1_500_000;

export interface ImagemRecebida {
  legenda?: unknown;
  jpeg_base64?: unknown;
}

/** Converte as capturas do payload; descarta o que não for JPEG ou PNG de tamanho razoável. */
export function imagensDoPayload(bruto: unknown): ImagemDoDocumento[] {
  if (!Array.isArray(bruto)) return [];
  const saida: ImagemDoDocumento[] = [];
  for (const item of bruto.slice(0, MAX_IMAGENS) as ImagemRecebida[]) {
    if (!item || typeof item.jpeg_base64 !== "string") continue;
    const dados = Buffer.from(item.jpeg_base64, "base64");
    const jpeg = dados[0] === 0xff && dados[1] === 0xd8;
    const png = dados[0] === 0x89 && dados[1] === 0x50;
    if ((!jpeg && !png) || dados.length > MAX_BYTES_POR_IMAGEM) continue;
    saida.push({ legenda: typeof item.legenda === "string" ? item.legenda.slice(0, 200) : "", dados });
  }
  return saida;
}

interface DemandaDasEvidencias {
  id: string;
  code: string;
  titulo: string;
  clienteNome: string;
}

/**
 * Publica (ou substitui) o PDF das evidências como anexo da demanda; sem
 * texto, remove o anexo. Nunca lança: é efeito colateral do sync.
 */
export async function publicarEvidenciasComoAnexo(
  d: DemandaDasEvidencias,
  markdown: string,
  imagens: ImagemDoDocumento[]
): Promise<"publicado" | "removido" | "ignorado"> {
  const caminho = caminhoDasEvidencias(d.id);
  try {
    if (!markdown.trim()) {
      const existente = await prisma.anexo.findUnique({ where: { caminho }, select: { id: true } });
      if (!existente) return "ignorado";
      await prisma.anexo.delete({ where: { caminho } });
      await removerArquivo(BUCKET_ANEXOS, caminho);
      return "removido";
    }
    if (!serviceRoleConfigurado()) {
      console.error("evidencias-anexo: armazenamento não configurado — as evidências não viraram anexo", { demanda: d.code });
      return "ignorado";
    }

    const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
    const pdf = await gerarPdfRoteiro(
      markdown,
      { clienteNome: d.clienteNome, codigo: d.code, titulo: d.titulo, emissor: EMISSOR_DOCUMENTOS, geradoEm: chaveDia(new Date()) },
      logo,
      {
        rotulo: "Evidências de teste",
        contexto: "testes executados na sandbox de QA",
        rodape: "evidências de teste",
        vazio: "Não há evidência registrada.",
        imagens,
      }
    );
    const { error } = await createServiceClient()
      .storage.from(BUCKET_ANEXOS)
      .upload(caminho, pdf, { contentType: "application/pdf", upsert: true });
    if (error) throw error;

    const dados = { nome: nomeDoAnexoDasEvidencias(d.code), tamanho: pdf.length, tipo: "application/pdf" };
    await prisma.anexo.upsert({
      where: { caminho },
      create: { demandaId: d.id, caminho, autor: AUTOR_DAS_EVIDENCIAS, autorEmail: "", ...dados },
      // A data acompanha a rodada: diz ao leitor de qual QA é o arquivo.
      update: { ...dados, criadoEm: new Date() },
    });
    return "publicado";
  } catch (err) {
    console.error("evidencias-anexo: falha ao publicar as evidências como anexo", { demanda: d.code, err });
    return "ignorado";
  }
}
