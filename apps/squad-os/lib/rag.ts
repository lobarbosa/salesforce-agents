import { randomUUID } from "node:crypto";
import { embed, embedMany } from "ai";
import { prisma } from "@/lib/prisma";

// Base de conhecimento por cliente pro pipeline de agentes Python — nunca o
// copiloto do cliente em Squad OS (ver CLAUDE.md guardrail #2). Toda função
// aqui exige clientId resolvido (nunca um slug/string livre não verificado
// contra a tabela Client) e todo SELECT filtra por ele — é o que impede a
// demanda de um cliente aparecer na busca de outro (guardrail #7).
//
// Embeddings via AI Gateway (mesma infra do copiloto, ver
// app/api/copilot/chat/route.ts — sem provider novo, sem secret novo).
// Dimensão 1536 é a do text-embedding-3-small da OpenAI; confirme o id do
// modelo contra `curl https://ai-gateway.vercel.sh/v1/models` no primeiro
// deploy — este sandbox não alcança o Gateway pra verificar ao vivo (mesma
// ressalva já feita pro modelo de chat do copiloto).
const MODELO_EMBEDDING = "openai/text-embedding-3-small";
const DIMENSAO = 1536;

const TAMANHO_CHUNK = 1200;
const SOBREPOSICAO = 150;

/** Quebra em parágrafos primeiro, depois empacota em blocos de ~TAMANHO_CHUNK
 *  com sobreposição — nunca corta uma frase no meio se der pra evitar. */
export function chunkTexto(texto: string): string[] {
  const paragrafos = texto.split(/\n{2,}/).map((p) => p.trim()).filter(Boolean);
  const chunks: string[] = [];
  let atual = "";

  for (const p of paragrafos) {
    const candidato = atual ? `${atual}\n\n${p}` : p;
    if (candidato.length <= TAMANHO_CHUNK) {
      atual = candidato;
      continue;
    }
    if (atual) chunks.push(atual);
    // Parágrafo sozinho maior que o chunk: corta na força, sem tentar achar
    // fronteira de frase — é o caso raro (bloco de código, tabela grande).
    if (p.length > TAMANHO_CHUNK) {
      for (let i = 0; i < p.length; i += TAMANHO_CHUNK - SOBREPOSICAO) {
        chunks.push(p.slice(i, i + TAMANHO_CHUNK));
      }
      atual = "";
    } else {
      atual = p;
    }
  }
  if (atual) chunks.push(atual);
  return chunks;
}

function paraLiteralVetor(embedding: number[]): string {
  return `[${embedding.join(",")}]`;
}

/**
 * Reingestão de um cliente: cada documento substitui inteiramente os chunks
 * que já existiam sob o mesmo `path` (nunca upsert por chunk — o texto pode
 * ter sido re-chunkado desde a última vez, e um upsert por índice deixaria
 * chunk velho sobrando se o novo texto tiver menos pedaços).
 */
export async function ingerirDocumentos(
  clientId: string,
  documentos: { path: string; conteudo: string }[]
) {
  let totalChunks = 0;
  for (const doc of documentos) {
    const partes = chunkTexto(doc.conteudo);
    await prisma.ragChunk.deleteMany({ where: { clientId, path: doc.path } });
    if (partes.length === 0) continue;

    const { embeddings } = await embedMany({ model: MODELO_EMBEDDING, values: partes });
    for (let i = 0; i < partes.length; i++) {
      const id = randomUUID();
      const vetor = paraLiteralVetor(embeddings[i]);
      await prisma.$executeRaw`
        INSERT INTO "rag_chunks" ("id", "client_id", "path", "chunk_index", "conteudo", "embedding")
        VALUES (${id}, ${clientId}, ${doc.path}, ${i}, ${partes[i]}, ${vetor}::vector)
      `;
    }
    totalChunks += partes.length;
  }
  return { documentos: documentos.length, chunks: totalChunks };
}

export interface ResultadoRag {
  path: string;
  trecho: string;
  similaridade: number;
}

/** Top-k trechos mais próximos da pergunta, só dentro do cliente informado. */
export async function consultarRag(
  clientId: string,
  pergunta: string,
  k = 6
): Promise<ResultadoRag[]> {
  const { embedding } = await embed({ model: MODELO_EMBEDDING, value: pergunta });
  const vetor = paraLiteralVetor(embedding);
  return prisma.$queryRaw<ResultadoRag[]>`
    SELECT "path", "conteudo" AS "trecho", 1 - ("embedding" <=> ${vetor}::vector) AS "similaridade"
    FROM "rag_chunks"
    WHERE "client_id" = ${clientId}
    ORDER BY "embedding" <=> ${vetor}::vector
    LIMIT ${k}
  `;
}

// Dimensão exportada só pra quem quiser validar embeddings.length antes de
// gravar — hoje ninguém chama isso fora deste módulo, mas é mais barato
// exportar a constante do que redeclarar "1536" em outro arquivo depois.
export const DIMENSAO_EMBEDDING = DIMENSAO;
