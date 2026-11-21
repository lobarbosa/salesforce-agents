import { tool } from "ai";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { criarDemanda } from "@/lib/demandas-server";
import type { CurrentUsuario } from "@/lib/current-user";
import { DECISAO_LABEL, MAX_PROPOSTAS_POR_VEZ, lerRecomendacoes, melhoriasDoAssessment } from "@/lib/assessment-propostas";
import { STAGE_LABEL, TRIAGE_LABEL } from "@/lib/demandas";

/** Propostas que o copiloto abre por cliente na última hora, somando todas as conversas. */
export const MAX_PROPOSTAS_POR_HORA = 20;

/**
 * Melhorias do assessment viram demandas propostas ao cliente (2026-11-21).
 * Só para o time (admin/consultor), só na página do cliente aberto: o
 * `clientId` vem da rota, nunca do modelo (guardrail #7).
 *
 * - `listar_melhorias_do_assessment` só lê: cada recomendação com o que já
 *   aconteceu com ela (livre, proposta e a decisão do cliente, ou demanda).
 * - `propor_melhorias_ao_cliente` abre as demandas no backlog marcadas como
 *   proposta, esperando o cliente. Não manda nada para a esteira e não aprova
 *   nada: quem aprova é o cliente, no card (/api/demandas/[id]/proposta), e
 *   quem manda para a esteira depois é o time.
 */
export function criarFerramentasAssessment({ usuario, clientId }: { usuario: CurrentUsuario; clientId: string }) {
  let usadaNestaRequisicao = false;

  async function melhorias() {
    const [c, demandas] = await Promise.all([
      prisma.client.findUnique({ where: { id: clientId }, select: { assessmentEm: true, assessmentRecomendacoes: true } }),
      prisma.demanda.findMany({
        where: { clientId, origemAssessmentId: { not: "" } },
        select: { code: true, titulo: true, status: true, origemAssessmentId: true, propostaClienteEm: true, propostaDecisao: true },
      }),
    ]);
    return { feitoEm: c?.assessmentEm ?? null, lista: melhoriasDoAssessment(lerRecomendacoes(c?.assessmentRecomendacoes), demandas) };
  }

  return {
    listar_melhorias_do_assessment: tool({
      description:
        "Lista as recomendações do assessment da org deste cliente, por severidade, com o id de cada uma e o que já aconteceu com ela: 'livre' (nenhuma demanda nasceu dela), 'proposta' (já proposta ao cliente, com a decisão dele) ou 'demanda' (já virou demanda de outro jeito). Use antes de propor melhorias ao cliente, e para responder 'o que do assessment ainda não virou demanda?'. Para o detalhe de uma recomendação (evidência, impacto), use consultar_base_conhecimento.",
      inputSchema: z.object({}),
      execute: async () => {
        const { feitoEm, lista } = await melhorias();
        if (!feitoEm) return { existe: false as const };
        return {
          existe: true as const,
          melhorias: lista.map((m) => ({
            id: m.id,
            titulo: m.titulo,
            severidade: m.severidade,
            area: m.area,
            situacao:
              m.situacao.tipo === "livre"
                ? "livre"
                : m.situacao.tipo === "proposta"
                  ? `proposta em ${m.situacao.code}: ${DECISAO_LABEL[m.situacao.decisao]}`
                  : `demanda ${m.situacao.code} (${TRIAGE_LABEL[m.situacao.status] ?? STAGE_LABEL[m.situacao.status] ?? m.situacao.status})`,
          })),
        };
      },
    }),

    propor_melhorias_ao_cliente: tool({
      description:
        `Abre, no backlog deste cliente, uma demanda por melhoria do assessment, marcada como proposta: o cliente vê no card e aprova ou recusa. Não manda nada para a esteira. Use SÓ depois de: (1) listar_melhorias_do_assessment; (2) mostrar à pessoa a lista exata que vai abrir, com título e texto de cada card; e (3) ela confirmar explicitamente nesta conversa. Só recomendações com situação 'livre'. No máximo ${MAX_PROPOSTAS_POR_VEZ} por vez. Título e texto em linguagem de cliente (o que muda para ele e por quê), sem jargão técnico, sem dado pessoal nem número de registro da org.`,
      inputSchema: z.object({
        confirmadoPelaPessoa: z.literal(true).describe("true só se a pessoa confirmou esta lista exata na conversa"),
        itens: z
          .array(
            z.object({
              recomendacaoId: z.string().min(5).max(40).describe("id devolvido por listar_melhorias_do_assessment"),
              titulo: z.string().min(3).max(200),
              texto: z.string().min(10).max(4000).describe("O que muda para o cliente, por que o diagnóstico recomendou e o que acontece se ele aprovar"),
            })
          )
          .min(1)
          .max(MAX_PROPOSTAS_POR_VEZ),
      }),
      execute: async ({ itens }) => {
        if (usadaNestaRequisicao) {
          return { abertas: [], recusadas: [{ recomendacaoId: "", motivo: "uma leva de propostas por mensagem" }] };
        }
        usadaNestaRequisicao = true;

        const naUltimaHora = await prisma.demanda.count({
          where: { clientId, propostaClienteEm: { gte: new Date(Date.now() - 60 * 60_000) } },
        });
        const cabem = Math.max(0, MAX_PROPOSTAS_POR_HORA - naUltimaHora);

        const { lista } = await melhorias();
        const livres = new Map(lista.filter((m) => m.situacao.tipo === "livre").map((m) => [m.id, m]));
        const abertas: { code: string; titulo: string; recomendacao: string }[] = [];
        const recusadas: { recomendacaoId: string; motivo: string }[] = [];
        const nestaLeva = new Set<string>();

        for (const item of itens) {
          const rec = livres.get(item.recomendacaoId);
          if (!rec) {
            recusadas.push({ recomendacaoId: item.recomendacaoId, motivo: "não é uma recomendação livre deste assessment" });
            continue;
          }
          if (nestaLeva.has(item.recomendacaoId)) {
            recusadas.push({ recomendacaoId: item.recomendacaoId, motivo: "repetida nesta lista" });
            continue;
          }
          if (abertas.length >= cabem) {
            recusadas.push({ recomendacaoId: item.recomendacaoId, motivo: `limite de ${MAX_PROPOSTAS_POR_HORA} propostas por hora neste cliente` });
            continue;
          }
          nestaLeva.add(item.recomendacaoId);
          const resultado = await criarDemanda({ usuario, clientId, titulo: item.titulo, texto: item.texto });
          if (!resultado.ok) {
            recusadas.push({ recomendacaoId: item.recomendacaoId, motivo: resultado.error });
            continue;
          }
          await prisma.demanda.update({
            where: { id: resultado.demanda.id },
            data: { origemAssessmentId: rec.id, propostaClienteEm: new Date() },
          });
          abertas.push({ code: resultado.demanda.code, titulo: resultado.demanda.titulo, recomendacao: rec.titulo });
        }
        return { abertas, recusadas };
      },
    }),
  };
}
