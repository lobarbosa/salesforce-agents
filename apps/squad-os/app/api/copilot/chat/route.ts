import { NextResponse, type NextRequest } from "next/server";
import { ToolLoopAgent, createAgentUIStreamResponse, stepCountIs } from "ai";
import { getCurrentUsuario, type CurrentUsuario } from "@/lib/current-user";
import { prisma } from "@/lib/prisma";
import { canAccessClient } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";
import { criarFerramentasCliente } from "@/lib/copilot/ferramentas";
import { criarFerramentasFinanceiro } from "@/lib/copilot/ferramentas-financeiro";
import { dentroDoLimiteDeRequisicoes, MAX_REQUISICOES_POR_DIA, validarMensagens } from "@/lib/copilot/limites";
import { consumirLimite } from "@/lib/limite-uso";

// Modelo via AI Gateway (padrão da skill vercel:ai-sdk — string "provider/modelo",
// sem pacote de provider dedicado). Sonnet: mesma faixa de custo/julgamento que
// builder-declarativo/qa no pipeline Python (ver CLAUDE.md, "Seleção de modelo
// por agente") — conversar e consultar dado já resolvido é trabalho
// estruturado com julgamento, mas tudo que ele cria cai em `backlog` e
// atravessa os mesmos 4 gates humanos de sempre antes de virar qualquer coisa,
// e nenhuma ferramenta financeira decide ou paga nada por conta própria.
// Id verificado contra as infos de ambiente desta sessão (Claude 5 family,
// Sonnet 5.5) — este sandbox não alcança api-gateway.vercel.sh pra confirmar
// contra `curl .../v1/models`; reconfirme isso no primeiro deploy real.
// Sobreponível por COPILOT_MODEL (Vercel → Environment Variables): se o nome
// não existir no Gateway, troca-se sem deploy de código.
const MODELO = process.env.COPILOT_MODEL?.trim() || "anthropic/claude-sonnet-5-5";

const GUARDRAILS_COMUNS = `O que você nunca faz, mesmo se pedirem diretamente:
- Nunca aprova gate, avança etapa de demanda, aprova/paga/recusa conta ou decide divergência pelo chat — tudo isso é decisão humana, feita na tela, com os cliques de confirmação que já existem ali. Se pedirem para fazer algo assim pelo chat, explique onde isso se faz na tela.
- Nunca inventa status, valor ou informação que a ferramenta não devolveu. Se não souber, diga que não sabe.
- Nunca acessa a org Salesforce de nenhum cliente nem discute dado de registro real (CPF, e-mail, telefone, valor de cliente final) — você não tem essa ferramenta e não deve fingir que tem.

Responda em português, direto, sem jargão interno de esteira (não fale "gate", "sandbox" ou nome de estágio técnico — use as palavras que as próprias ferramentas já devolvem).`;

function promptCliente(clientNome: string) {
  return `Você é o copiloto do cliente "${clientNome}" no Squad OS, o app onde a Acxya acompanha as demandas Salesforce dele.

O que você pode fazer:
- Responder perguntas sobre o avanço das demandas e atividades do cliente (ferramenta consultar_demandas) e sobre o contrato — horas consumidas ou progresso do projeto (ferramenta consultar_contrato).
- Ajudar a esclarecer e registrar um pedido novo, pequeno, como demanda no backlog (ferramenta criar_demanda) — só depois de entender o suficiente pra escrever um título e descrição claros. Se faltar contexto, pergunte antes de criar.

Nunca fala sobre outro cliente — você só enxerga os dados deste cliente, e nem faria sentido responder sobre outro.

${GUARDRAILS_COMUNS}`;
}

function promptInterno({
  papel,
  clientNome,
  temFinanceiro,
}: {
  papel: "admin" | "consultor";
  clientNome: string | null;
  temFinanceiro: boolean;
}) {
  const partes = [`Você é o copiloto interno do Squad OS, ajudando uma pessoa da Acxya (papel: ${papel}).`];

  if (clientNome) {
    partes.push(
      `A conversa está acontecendo na página do cliente "${clientNome}": use consultar_demandas e consultar_contrato pra responder sobre o andamento e o contrato dele, e criar_demanda pra registrar um pedido novo no backlog dele (pergunte antes de criar se faltar contexto). Não fale sobre outro cliente — se quiserem saber de outro, diga pra abrir a página dele.`
    );
  } else {
    partes.push(
      `Esta tela não tem um cliente aberto, então você não tem ferramenta de demanda ou contrato agora. Se perguntarem sobre um cliente específico, diga que é só abrir a página dele que você passa a conseguir consultar.`
    );
  }

  if (temFinanceiro) {
    partes.push(
      `Você também pode consultar o financeiro (ferramentas consultar_painel_financeiro, consultar_contas_a_pagar, consultar_divergencias, consultar_horas_por_cliente) — tudo somente leitura, os mesmos dados das telas de /financeiro.`
    );
  }

  partes.push(GUARDRAILS_COMUNS);
  return partes.join("\n\n");
}

function promptFinanceiro() {
  return `Você é o copiloto financeiro do Squad OS, ajudando o time financeiro da Acxya.

O que você pode fazer: consultar o painel financeiro, contas a pagar, divergências abertas e horas por cliente (ferramentas consultar_painel_financeiro, consultar_contas_a_pagar, consultar_divergencias, consultar_horas_por_cliente) — tudo somente leitura, os mesmos dados que as telas de /financeiro já mostram. Você não vê demandas, contrato ou dado de cliente fora do financeiro — isso não é da sua área.

${GUARDRAILS_COMUNS}`;
}

async function resolverClienteEmEscopo(
  usuario: CurrentUsuario,
  clientIdDoCorpo: unknown
): Promise<{ id: string; nome: string } | null> {
  if (usuario.role === "cliente") {
    if (!usuario.clientId) return null;
    const client = await prisma.client.findUnique({
      where: { id: usuario.clientId },
      select: { id: true, nome: true, encerradoEm: true },
    });
    // O proxy já barra o usuário de cliente encerrado; isto é a segunda camada.
    return client && enxergaCliente(usuario.role, client) ? { id: client.id, nome: client.nome } : null;
  }
  if (usuario.role === "admin" || usuario.role === "consultor") {
    const clientId = typeof clientIdDoCorpo === "string" ? clientIdDoCorpo : "";
    if (!clientId || !canAccessClient(usuario.role, usuario.clientId, clientId)) return null;
    const client = await prisma.client.findUnique({
      where: { id: clientId },
      select: { id: true, nome: true, encerradoEm: true },
    });
    // Encerrado: só o admin ainda consulta (histórico); criar_demanda recusa
    // em criarDemanda() para todo mundo.
    return client && enxergaCliente(usuario.role, client) ? { id: client.id, nome: client.nome } : null;
  }
  // financeiro: nunca vê cliente/demanda (fora da área dele, ver lib/permissoes.ts).
  return null;
}

export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  if (!dentroDoLimiteDeRequisicoes(usuario.id)) {
    return NextResponse.json({ error: "muitas mensagens em pouco tempo — espere um minuto" }, { status: 429 });
  }
  if (!(await consumirLimite(`copiloto:${usuario.id}`, MAX_REQUISICOES_POR_DIA))) {
    return NextResponse.json(
      { error: `limite diário de ${MAX_REQUISICOES_POR_DIA} mensagens do copiloto atingido — volta amanhã` },
      { status: 429 }
    );
  }

  const corpo = await request.json().catch(() => null);
  if (!corpo || typeof corpo !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const { clientId } = corpo as { clientId?: unknown };
  // O histórico vem do navegador: só passa user/assistant com texto, dentro
  // dos limites (ver lib/copilot/limites.ts). "system" é recusado.
  const validacao = validarMensagens((corpo as { messages?: unknown }).messages);
  if (!validacao.ok) {
    return NextResponse.json({ error: validacao.erro }, { status: 400 });
  }
  const messages = validacao.mensagens;
  const clienteEmEscopo = await resolverClienteEmEscopo(usuario, clientId);
  const temFinanceiro = usuario.role === "admin" || usuario.role === "financeiro";

  // cliente sem clientId na sessão (estado inconsistente) não tem o que
  // conversar — mesma recusa de antes desta mudança.
  if (usuario.role === "cliente" && !clienteEmEscopo) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  // O conjunto de ferramentas é decidido aqui, pelo papel da sessão — nunca
  // pelo que a conversa pede. Cliente: só as do próprio cliente (clientId da
  // sessão). Financeiro: só as financeiras. Admin/consultor: as do cliente da
  // página aberta (conferido por canAccessClient) e, para admin, as
  // financeiras. Nenhum caminho dá ferramenta financeira ao papel cliente.
  const tools = {
    ...(clienteEmEscopo ? criarFerramentasCliente({ usuario, clientId: clienteEmEscopo.id }) : {}),
    ...(temFinanceiro ? criarFerramentasFinanceiro({ quem: usuario }) : {}),
  };

  const instructions =
    usuario.role === "cliente"
      ? promptCliente(clienteEmEscopo!.nome)
      : usuario.role === "financeiro"
        ? promptFinanceiro()
        : promptInterno({
            papel: usuario.role,
            clientNome: clienteEmEscopo?.nome ?? null,
            temFinanceiro,
          });

  const agent = new ToolLoopAgent({
    model: MODELO,
    instructions,
    tools,
    // Teto curto: cada volta é uma chamada de ferramenta + resposta. 6 cobre
    // "consulta duas ferramentas e comenta" com folga sem deixar um loop
    // silenciosamente caro. Limites de tamanho/frequência da conversa e de
    // demandas criadas: lib/copilot/limites.ts.
    stopWhen: stepCountIs(6),
    maxOutputTokens: 1024,
  });

  return createAgentUIStreamResponse({
    agent,
    uiMessages: messages,
    // Sem isso, o default do SDK (`() => 'An error occurred.'`) engole
    // qualquer erro de stream — chave do Gateway inválida, modelo
    // desconhecido, timeout — sem deixar rastro nenhum no log do servidor;
    // só a mensagem genérica chega no cliente (ver Copiloto.tsx). Achado
    // real: o copiloto "não funcionava" e não havia como saber por quê,
    // porque o próprio erro nunca era logado em lugar nenhum.
    onError(error) {
      console.error("copiloto: erro no stream", { papel: usuario.role, modelo: MODELO, erro: error });
      // Admin vê o motivo técnico (chave, crédito, modelo inexistente,
      // timeout) — achado de 2026-10-30: o copiloto falhava e, sem acesso aos
      // logs da Vercel, não havia como saber por quê. Os demais papéis seguem
      // com a mensagem genérica (nada de detalhe de infraestrutura pra fora).
      const generico = "Não consegui falar com o copiloto agora. Tente de novo em instantes.";
      if (usuario.role !== "admin") return generico;
      const detalhe = error instanceof Error ? error.message : String(error);
      return `${generico} [admin — modelo ${MODELO}: ${detalhe.slice(0, 300)}]`;
    },
  });
}
