import { tool } from "ai";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import type { CurrentUsuario } from "@/lib/current-user";
import { enxergaCliente } from "@/lib/encerramento";
import { paradas } from "@/lib/esteira-parada";
import { QUEM_AGE_LABEL } from "@/lib/demandas";
import { nomeDoDono } from "@/lib/dono";

/**
 * "Tem algo parado?" pelo copiloto — só para o time (admin/consultor), em
 * qualquer tela, cruzando os clientes que a pessoa enxerga. Somente leitura,
 * os mesmos campos que o quadro já mostra; nunca chega ao papel cliente (a
 * rota decide, ver app/api/copilot/chat/route.ts).
 */
export function criarFerramentasEsteira({ usuario }: { usuario: CurrentUsuario }) {
  return {
    consultar_parados: tool({
      description:
        "Lista as demandas abertas de todos os clientes que esperam alguém agir (time, cliente, fila ou congeladas), ordenadas pelos dias parados na etapa atual, com o que falta, o dono da demanda e se o QA reprovou. Use para 'tem algo parado?', 'o que está esperando a gente?', 'o que o cliente precisa aprovar?'. Com dono='minhas' traz só as de quem pergunta ('o que é meu?'); com dono='sem_dono', as que ninguém assumiu.",
      inputSchema: z.object({
        dono: z.enum(["todas", "minhas", "sem_dono"]).optional().describe("Filtrar pelo dono da demanda. Padrão: todas."),
      }),
      execute: async ({ dono: filtro = "todas" }) => {
        const demandas = await prisma.demanda.findMany({
          where: { status: { notIn: ["entregue", "cancelada", "recorrente"] } },
          select: {
            code: true,
            titulo: true,
            status: true,
            congeladaDe: true,
            criadoEm: true,
            historico: true,
            estimativaConsultorHoras: true,
            estimativaAprovadaHoras: true,
            estimativaDebitadaEm: true,
            artefatoNome: true,
            propostaClienteEm: true,
            propostaDecisao: true,
            disparos: { select: { tipo: true, gate: true, disparadoEm: true, concluidoEm: true } },
            client: { select: { nome: true, encerradoEm: true, contrato: { select: { tipo: true } } } },
            dono: { select: { nome: true, email: true } },
          },
        });
        // O texto do artefato pode ter dezenas de KB por demanda; só o
        // 05-testes de quem está em homologação interessa (veredito do QA).
        const testes = await prisma.demanda.findMany({
          where: { status: "aguardando_homologacao", artefatoNome: "05-testes.md" },
          select: { code: true, artefatoConteudo: true },
        });
        const conteudo = new Map(testes.map((t) => [t.code, t.artefatoConteudo]));
        const visiveis = demandas
          .filter((d) => enxergaCliente(usuario.role, d.client))
          .filter((d) =>
            filtro === "minhas"
              ? d.dono?.email.toLowerCase() === usuario.email.toLowerCase()
              : filtro === "sem_dono"
                ? !d.dono
                : true
          )
          .map((d) => ({ ...d, artefatoConteudo: conteudo.get(d.code) ?? "" }));
        const donoPorCode = new Map(visiveis.map((d) => [d.code, nomeDoDono(d.dono)]));
        return paradas(visiveis).map((p) => ({
          cliente: p.cliente,
          code: p.code,
          titulo: p.titulo,
          dono: donoPorCode.get(p.code) || "sem dono",
          esperando: p.acoes.map((a) => `${QUEM_AGE_LABEL[a.quem]}: ${a.oque}`).join("; "),
          diasNaEtapa: p.diasNaEtapa,
          ...(p.qaReprovado ? { alerta: "QA reprovou — ler os testes antes de homologar" } : {}),
        }));
      },
    }),
  };
}
