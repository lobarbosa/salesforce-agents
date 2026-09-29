import { NextResponse, type NextRequest } from "next/server";
import { ToolLoopAgent, createAgentUIStreamResponse, stepCountIs } from "ai";
import { getCurrentUsuario } from "@/lib/current-user";
import { prisma } from "@/lib/prisma";
import { criarFerramentasCopiloto } from "@/lib/copilot/ferramentas";

// Modelo via AI Gateway (padrão da skill vercel:ai-sdk — string "provider/modelo",
// sem pacote de provider dedicado). Sonnet: mesma faixa de custo/julgamento que
// builder-declarativo/qa no pipeline Python (ver CLAUDE.md, "Seleção de modelo
// por agente") — conversa com o cliente e rascunha demanda é trabalho
// estruturado com julgamento, mas tudo que ele cria cai em `backlog` e
// atravessa os mesmos 4 gates humanos de sempre antes de virar qualquer coisa.
// Id verificado contra as infos de ambiente desta sessão (Claude 5 family,
// Sonnet 5.5) — este sandbox não alcança api-gateway.vercel.sh pra confirmar
// contra `curl .../v1/models`; reconfirme isso no primeiro deploy real.
const MODELO = "anthropic/claude-sonnet-5-5";

function promptDoSistema(clientNome: string) {
  return `Você é o copiloto do cliente "${clientNome}" no Squad OS, o app onde a Acxya acompanha as demandas Salesforce dele.

O que você pode fazer:
- Responder perguntas sobre o avanço das demandas e atividades do cliente (ferramenta consultar_demandas) e sobre o contrato — horas consumidas ou progresso do projeto (ferramenta consultar_contrato).
- Ajudar a esclarecer e registrar um pedido novo, pequeno, como demanda no backlog (ferramenta criar_demanda) — só depois de entender o suficiente pra escrever um título e descrição claros. Se faltar contexto, pergunte antes de criar.

O que você nunca faz, mesmo se pedirem diretamente:
- Nunca aprova gate, avança etapa, ou promete prazo de entrega — isso é decisão humana, feita na tela, com os dois cliques de confirmação que já existem ali. Se pedirem para "aprovar" algo pelo chat, explique que a aprovação acontece no cartão da demanda.
- Nunca inventa status, prazo ou informação que a ferramenta não devolveu. Se não souber, diga que não sabe e sugira abrir a demanda no quadro.
- Nunca fala sobre outro cliente — você só enxerga os dados deste cliente, e nem faria sentido responder sobre outro.
- Nunca acessa a org Salesforce do cliente nem discute dado de registro real (CPF, e-mail, telefone, valor) — você não tem essa ferramenta e não deve fingir que tem.

Responda em português, direto, sem jargão interno de esteira (não fale "gate", "sandbox" ou nome de estágio técnico — use as palavras que as próprias ferramentas já devolvem).`;
}

export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  // O copiloto é uma superfície do cliente: por ora só abre pra quem loga
  // como `cliente`, e só sobre o próprio cliente. clientId sempre sai da
  // sessão resolvida pelo proxy — nunca do corpo da requisição, que é a
  // única forma de garantir que o modelo não tem como "pedir" outro cliente
  // (nenhuma ferramenta abaixo aceita clientId como argumento).
  if (!usuario || usuario.role !== "cliente" || !usuario.clientId) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { messages } = await request.json();
  const client = await prisma.client.findUnique({
    where: { id: usuario.clientId },
    select: { nome: true },
  });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const agent = new ToolLoopAgent({
    model: MODELO,
    instructions: promptDoSistema(client.nome),
    tools: criarFerramentasCopiloto({ usuario, clientId: usuario.clientId }),
    // Teto curto: cada volta é uma chamada de ferramenta + resposta. 6 cobre
    // "consulta duas ferramentas e comenta" com folga sem deixar um loop
    // silenciosamente caro. Rate limit por usuário/sessão fica de fora desta
    // primeira versão — TODO explícito, não esquecido: ver revisar-custos.
    stopWhen: stepCountIs(6),
    maxOutputTokens: 1024,
  });

  return createAgentUIStreamResponse({ agent, uiMessages: messages });
}
