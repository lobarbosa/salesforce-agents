import { tool } from "ai";
import { z } from "zod";
import { consultarRag } from "@/lib/rag";

/**
 * Base de conhecimento interna (RAG) pelo copiloto — só para o time
 * (admin/consultor), decisão de 2026-11-01 que revisa a de 2026-09-29.
 *
 * O corpus é todo `.md` de clients/<cliente>/: análises, designs, gates.md,
 * briefing de conta, assessment. É material interno de delivery — útil para
 * quem trabalha no cliente ("já fizemos algo parecido?"), impróprio para o
 * próprio cliente. Por isso a rota nunca entrega esta ferramenta ao papel
 * `cliente`, e o `clientId` é o da página aberta, conferido no servidor
 * (canAccessClient) — nunca um argumento que o modelo escolhe (guardrail #7).
 */
export function criarFerramentasConhecimento({ clientId }: { clientId: string }) {
  return {
    consultar_base_conhecimento: tool({
      description:
        "Busca na base de conhecimento interna DESTE cliente (demandas anteriores, análises, designs, aprovações, briefing de conta e o relatório completo do assessment da org) os trechos mais parecidos com a pergunta. Use para 'já fizemos algo parecido?', 'o que foi decidido sobre X?', 'o que o assessment diz sobre Y?'. Cite o arquivo de origem na resposta.",
      inputSchema: z.object({ pergunta: z.string().min(3).max(500) }),
      execute: async ({ pergunta }) => {
        const resultados = await consultarRag(clientId, pergunta, 6);
        if (resultados.length === 0) return { encontrados: 0, trechos: [] };
        return {
          encontrados: resultados.length,
          trechos: resultados.map((r) => ({
            fonte: r.path,
            similaridade: Math.round(Number(r.similaridade) * 100) / 100,
            trecho: r.trecho.slice(0, 1500),
          })),
        };
      },
    }),
  };
}
