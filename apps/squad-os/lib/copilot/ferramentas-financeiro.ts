import { tool } from "ai";
import { z } from "zod";
import { listarContas } from "@/lib/contas-data";
import { bloqueio, formatarReais, type QuemAge } from "@/lib/contas";
import { listarDivergencias, contarDivergenciasAbertas, kpisAtuais, STATUS_DIVERGENCIA } from "@/lib/ops";
import { horasPorCliente } from "@/lib/horas-data";
import { chaveDia } from "@/lib/horas";
import { rotuloOrigem } from "@/lib/divergencias";
import { defKpi, tendencia } from "@/lib/kpis";
import { checklist, competenciaPadrao, rotuloMes } from "@/lib/contabilidade";
import { prisma } from "@/lib/prisma";

/**
 * Ferramentas financeiras do copiloto — mesmos dados das telas de
 * /financeiro, nunca de outro lugar: cada ferramenta aqui chama a mesma
 * função que a página correspondente já usa (lib/contas-data.ts,
 * lib/ops.ts, lib/horas-data.ts), sem reimplementar nenhuma regra.
 *
 * Escopo deliberado (ver CLAUDE.md):
 * - Só consulta. Nenhuma ferramenta aqui paga conta, aprova ou decide
 *   divergência — essas são ações com peso financeiro real, e a regra que
 *   já vale pro gate e pro pagamento no chat da demanda ("ação irreversível
 *   não é coisa de 'sim' no chat") vale aqui do mesmo jeito.
 * - Nenhum dado de CPF/conta bancária/cartão passa por aqui — o que
 *   `lib/contas-data.ts` já expõe é fornecedor/categoria/valor/vencimento,
 *   o mesmo que a tela mostra.
 * - Quem chama estas ferramentas é sempre `admin` ou `financeiro` (ver
 *   app/api/copilot/chat/route.ts) — a mesma dupla que já vê `/financeiro`
 *   em lib/permissoes.ts.
 */
export function criarFerramentasFinanceiro({ quem }: { quem: QuemAge }) {
  return {
    consultar_painel_financeiro: tool({
      description:
        "Visão geral do financeiro: o que precisa de atenção agora (contas a aprovar, vencidas, a pagar em breve, divergências abertas, documentos de contabilidade faltando, contratos de horas em atenção) e os KPIs de caixa e resultado mais recentes. Use para perguntas gerais como \"como está o financeiro\" ou \"o que está pendente\".",
      inputSchema: z.object({}),
      execute: async () => {
        const hoje = chaveDia(new Date());
        const mesAtual = hoje.slice(0, 7);
        const compContabil = competenciaPadrao(mesAtual);
        const somaDias = (dia: string, n: number) => {
          const d = new Date(`${dia}T00:00:00Z`);
          d.setUTCDate(d.getUTCDate() + n);
          return d.toISOString().slice(0, 10);
        };

        const [contas, divergencias, kpis, docsContabeis, horas] = await Promise.all([
          listarContas(),
          contarDivergenciasAbertas(),
          kpisAtuais(),
          prisma.documentoContabil.findMany({ where: { competencia: compContabil, removidoEm: null }, select: { tipo: true } }),
          horasPorCliente(mesAtual),
        ]);

        const decidir = contas.filter((c) => c.status === "aguardando_aprovacao" && bloqueio("aprovar", c, quem) === null);
        const abertas = contas.filter((c) => c.status === "aguardando_aprovacao" || c.status === "aprovada");
        const vencidas = abertas.filter((c) => c.vencimento < hoje);
        const pagarLogo = contas.filter((c) => c.status === "aprovada" && c.vencimento >= hoje && c.vencimento <= somaDias(hoje, 3));
        const faltamDocs = checklist(docsContabeis.map((d) => d.tipo)).filter((i) => !i.recebidos);
        const estourados = horas.filter((h) => h.situacao === "estourado" || h.situacao === "atencao");
        const soma = (l: { valor: number }[]) => l.reduce((s, c) => s + c.valor, 0);

        return {
          contasParaAprovar: { quantidade: decidir.length, total: formatarReais(soma(decidir)) },
          contasVencidas: { quantidade: vencidas.length, total: formatarReais(soma(vencidas)) },
          contasAPagarEm3Dias: { quantidade: pagarLogo.length, total: formatarReais(soma(pagarLogo)) },
          divergenciasAbertasPorOrigem: (divergencias ?? []).map((d) => ({ origem: rotuloOrigem(d.origem), total: d.total })),
          contabilidadeDoMes: { mes: rotuloMes(compContabil), documentosFaltando: faltamDocs.map((i) => i.item) },
          contratosDeHorasEmAtencao: estourados.map((h) => h.clientNome),
          kpis:
            kpis === null
              ? null
              : kpis.map((k) => {
                  const def = defKpi(k.metrica);
                  return {
                    metrica: def.rotulo,
                    valor: formatarReais(k.valor),
                    tendencia: tendencia(k.valor, k.anterior, def.subirEhRuim),
                  };
                }),
        };
      },
    }),

    consultar_contas_a_pagar: tool({
      description:
        "Lista contas a pagar com fornecedor, categoria, valor, vencimento e situação. Filtre por status se o pedido for específico (ex.: só vencidas, só aguardando aprovação). Use para perguntas sobre contas, fornecedores ou pagamentos.",
      inputSchema: z.object({
        status: z
          .enum(["lancada", "aguardando_aprovacao", "aprovada", "paga", "recusada", "cancelada"])
          .optional()
          .describe("Filtra por situação da conta. Omita para listar todas."),
      }),
      execute: async ({ status }) => {
        const contas = await listarContas();
        const filtradas = status ? contas.filter((c) => c.status === status) : contas;
        return filtradas.slice(0, 50).map((c) => ({
          fornecedor: c.fornecedor,
          descricao: c.descricao,
          categoria: c.categoria,
          valor: formatarReais(c.valor),
          vencimento: c.vencimento,
          status: c.status,
        }));
      },
    }),

    consultar_divergencias: tool({
      description:
        "Lista divergências que os agentes encontraram ao cruzar dados (ex.: assinatura sem cobrança, cobrança sem nota fiscal). Por padrão só as abertas. Use para perguntas sobre o que não bateu ou precisa de revisão.",
      inputSchema: z.object({
        status: z.enum(STATUS_DIVERGENCIA).optional().describe("Padrão: aberta. Use 'resolvida' ou 'ignorada' se pedirem histórico."),
        origem: z.string().optional().describe("Filtra por origem (ex.: accounting_reconciliation_agent), se souber qual."),
      }),
      execute: async ({ status, origem }) => {
        const lista = await listarDivergencias({ status: status ?? "aberta", origem });
        if (lista === null) return { disponivel: false as const };
        return {
          disponivel: true as const,
          divergencias: lista.slice(0, 30).map((d) => ({
            origem: rotuloOrigem(d.origem),
            tipo: d.tipo,
            competencia: d.competencia,
            esperado: d.esperado === null ? null : formatarReais(d.esperado),
            encontrado: d.encontrado === null ? null : formatarReais(d.encontrado),
            status: d.status,
          })),
        };
      },
    }),

    consultar_horas_por_cliente: tool({
      description:
        "Horas consumidas por cliente no mês (contra o contratado, em contratos AMS) — quem lançou mais, quais demandas consumiram mais e quais contratos estão em atenção ou estourados. Use para perguntas sobre consumo de horas por cliente.",
      inputSchema: z.object({
        mes: z.string().regex(/^\d{4}-\d{2}$/).optional().describe("Mês no formato AAAA-MM. Padrão: mês atual."),
      }),
      execute: async ({ mes }) => {
        const mesFinal = mes ?? chaveDia(new Date()).slice(0, 7);
        const linhas = await horasPorCliente(mesFinal);
        return linhas.map((l) => ({
          cliente: l.clientNome,
          situacao: l.situacao,
          horasContratadas: l.tipo === "ams" ? l.horasContratadas : null,
          minutosConsumidos: l.minutos,
        }));
      },
    }),
  };
}
