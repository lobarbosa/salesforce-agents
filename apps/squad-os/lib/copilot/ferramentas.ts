import { tool } from "ai";
import { z } from "zod";
import { getDemandasByClient, demandasPorEntregavel, horasPorMes, getClientById } from "@/lib/data";
import { estadoDoCliente, ESTADO_CLIENTE_LABEL, progressoDaDemanda, timeAgo } from "@/lib/demandas";
import { progressoDoProjeto } from "@/lib/contrato";
import { criarDemanda } from "@/lib/demandas-server";
import type { CurrentUsuario } from "@/lib/current-user";

/**
 * Ferramentas do copiloto sobre um cliente — sempre fechadas sobre um
 * `clientId` e um `usuario` já resolvidos no servidor (ver
 * app/api/copilot/chat/route.ts). Nenhum schema de entrada aqui aceita
 * `clientId`: o modelo não tem como pedir dado de outro cliente porque a
 * pergunta nunca chega a existir pra ele. Usadas para o papel `cliente`
 * (sempre o próprio) e para `admin`/`consultor` quando a conversa está
 * acontecendo dentro da página de um cliente (o `clientId` vem da página
 * aberta, nunca escolhido pelo modelo — ver a rota).
 *
 * Escopo deliberado (guardrails da construção, ver CLAUDE.md):
 * - Zero acesso a Salesforce/org do cliente. O copiloto só fala com o mesmo
 *   Postgres que a UI já usa — nada de SOQL, nada de `sf`, nada de PII de org
 *   (guardrail #2, LGPD já é moot aqui: nunca chega perto).
 * - Vocabulário sempre `ESTADOS_CLIENTE` (recebida/andamento/você/entregue) —
 *   nunca o jargão interno de estágio/gate que `STAGE_LABEL` usa pro time.
 *   Para admin/consultor isso também vale: o copiloto não é a ferramenta de
 *   trabalho interno, é a mesma conversa que o cliente teria.
 * - `criar_demanda` só cria em `backlog`, chamando a mesma `criarDemanda()`
 *   que a API usa — nunca aprova gate, nunca materializa, nunca muda status
 *   de demanda existente. Aprovar gate continua exigindo o fluxo de dois
 *   passos na tela (DemandModal) — ação irreversível não é coisa de "sim" no
 *   chat, nem pro cliente nem pro time.
 * - Não expõe Conhecimento/Conexão nem conteúdo de artefato de gate — a
 *   mesma restrição de aba que `ClientDetail.tsx` já aplica ao papel cliente.
 */
export function criarFerramentasCliente({
  usuario,
  clientId,
}: {
  usuario: CurrentUsuario;
  clientId: string;
}) {
  return {
    consultar_demandas: tool({
      description:
        "Lista as demandas do cliente autenticado, com o estado de cada uma na linguagem do cliente (recebida, em andamento, esperando você, entregue). Use para responder perguntas sobre avanço, status ou atividades em curso.",
      inputSchema: z.object({}),
      execute: async () => {
        const demandas = await getDemandasByClient(clientId);
        return demandas.map((d) => {
          const progresso = progressoDaDemanda(d.status);
          return {
            code: d.code,
            titulo: d.titulo,
            estado: ESTADO_CLIENTE_LABEL[estadoDoCliente(d.status)],
            fase: estadoDoCliente(d.status) === "andamento" ? progresso?.rotulo ?? null : null,
            criadaEm: timeAgo(d.criadoEm),
          };
        });
      },
    }),

    consultar_contrato: tool({
      description:
        "Traz o contrato do cliente: em AMS, horas consumidas por mês contra as contratadas; em projeto, o progresso ponderado dos entregáveis (quanto do escopo já saiu). Use para perguntas sobre consumo de horas, prazo ou quanto falta do projeto.",
      inputSchema: z.object({}),
      execute: async () => {
        const client = await getClientById(clientId);
        const contrato = client?.contrato;
        if (!contrato) return { existe: false as const };

        if (contrato.tipo === "ams") {
          const meses = await horasPorMes(clientId, 3);
          return {
            existe: true as const,
            tipo: "ams" as const,
            cicloHoras: contrato.cicloHoras,
            horasContratadas: contrato.horasContratadas,
            ultimosMeses: meses,
          };
        }

        const progresso = progressoDoProjeto(contrato.entregaveis);
        const porEntregavel = await demandasPorEntregavel(clientId);
        return {
          existe: true as const,
          tipo: "projeto" as const,
          nome: contrato.projetoNome,
          progresso,
          entregaveis: contrato.entregaveis.map((e) => ({
            titulo: e.titulo,
            concluido: e.concluido,
            demandas: porEntregavel[e.id] ?? { total: 0, entregues: 0 },
          })),
        };
      },
    }),

    criar_demanda: tool({
      description:
        "Registra uma demanda nova (pedido pequeno, dúvida, ajuste) no backlog do cliente — exatamente como o botão \"+ nova demanda\" da tela. Não aprova nem avança nada sozinho: a demanda entra em backlog e segue o fluxo normal, com os mesmos gates humanos de sempre. Use só depois de entender o pedido o suficiente para escrever um título claro; se faltar contexto, pergunte antes de criar.",
      inputSchema: z.object({
        titulo: z.string().min(3).max(200).describe("Título curto e claro do pedido"),
        texto: z.string().max(4000).optional().describe("Descrição do pedido, com o contexto que o cliente deu na conversa"),
      }),
      execute: async ({ titulo, texto }) => {
        const resultado = await criarDemanda({ usuario, clientId, titulo, texto });
        if (!resultado.ok) return { criada: false as const, erro: resultado.error };
        return { criada: true as const, code: resultado.demanda.code, titulo: resultado.demanda.titulo };
      },
    }),
  };
}
