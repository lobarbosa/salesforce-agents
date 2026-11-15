import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { prisma } from "@/lib/prisma";
import { removerArquivo } from "@/lib/arquivo";
import { chaveDia } from "@/lib/horas";
import { gerarPdfRoteiro } from "@/lib/roteiro-pdf";
import { BUCKET_ANEXOS, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { caminhoDoRoteiro } from "@/lib/visao-cliente";

// O roteiro de teste do cliente chega ao card como um arquivo só, na seção de
// anexos (decisão de 2026-11-15): o PDF gerado do `05-roteiro-cliente.md` que
// o agente de QA escreveu, no desenho do espelho de horas. Não há mais seção
// própria no card nem rota de PDF — quem quer o roteiro baixa o anexo.
//
// Um anexo por demanda, sempre no mesmo caminho: cada rodada de QA substitui o
// arquivo em vez de empilhar versões. Quem o enxerga é decidido em
// lib/visao-cliente.ts (o cliente, só da homologação em diante).

export const AUTOR_DO_ROTEIRO = "Esteira (QA)";

export const nomeDoAnexoDoRoteiro = (codigo: string) => `Roteiro de teste - ${codigo}.pdf`;

interface DemandaDoRoteiro {
  id: string;
  code: string;
  titulo: string;
  clienteNome: string;
}

/**
 * Publica (ou substitui) o PDF do roteiro como anexo da demanda; com roteiro
 * vazio, remove o anexo. Nunca lança: é efeito colateral do sync, e uma falha
 * de armazenamento não pode fazer o espelho da demanda falhar junto.
 */
export async function publicarRoteiroComoAnexo(d: DemandaDoRoteiro, markdown: string): Promise<"publicado" | "removido" | "ignorado"> {
  const caminho = caminhoDoRoteiro(d.id);
  try {
    if (!markdown.trim()) {
      const existente = await prisma.anexo.findUnique({ where: { caminho }, select: { id: true } });
      if (!existente) return "ignorado";
      await prisma.anexo.delete({ where: { caminho } });
      await removerArquivo(BUCKET_ANEXOS, caminho);
      return "removido";
    }
    if (!serviceRoleConfigurado()) {
      console.error("roteiro-anexo: armazenamento não configurado — o roteiro não virou anexo", { demanda: d.code });
      return "ignorado";
    }

    const logo = await readFile(join(process.cwd(), "public", "marca.png")).catch(() => null);
    const pdf = await gerarPdfRoteiro(
      markdown,
      { clienteNome: d.clienteNome, codigo: d.code, titulo: d.titulo, emissor: "Acxya", geradoEm: chaveDia(new Date()) },
      logo
    );
    const { error } = await createServiceClient()
      .storage.from(BUCKET_ANEXOS)
      .upload(caminho, pdf, { contentType: "application/pdf", upsert: true });
    if (error) throw error;

    const dados = { nome: nomeDoAnexoDoRoteiro(d.code), tamanho: pdf.length, tipo: "application/pdf" };
    await prisma.anexo.upsert({
      where: { caminho },
      create: { demandaId: d.id, caminho, autor: AUTOR_DO_ROTEIRO, autorEmail: "", ...dados },
      // A data acompanha a rodada: é o que diz ao leitor de qual QA é o arquivo.
      update: { ...dados, criadoEm: new Date() },
    });
    return "publicado";
  } catch (err) {
    console.error("roteiro-anexo: falha ao publicar o roteiro como anexo", { demanda: d.code, err });
    return "ignorado";
  }
}
