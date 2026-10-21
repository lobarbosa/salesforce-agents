import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import type { Prisma, StatusDemanda } from "@/lib/generated/prisma/client";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient, canManageClientData } from "@/lib/auth";
import { enxergaCliente } from "@/lib/encerramento";
import { recusaSeEncerrado } from "@/lib/encerramento-server";
import { resolverDemanda } from "@/lib/demanda-access";
import { GATE_DO_CLIENTE, mesclarRespostas, montarAprovacao } from "@/lib/demandas";

// Status de triagem que o próprio card pode mover (dropdown no board) —
// os estágios de execução só avançam via `sfagents demanda avancar`, o card
// aqui é só leitura pra esses (mesma regra da versão Artifact). Mover
// triagem é coisa de admin/consultor; role=cliente só mexe nas perguntas e na
// aprovação do gate que é dele (ver GATE_DO_CLIENTE abaixo).
const TRIAGE_STATUSES: StatusDemanda[] = ["backlog", "planejada", "recorrente", "standby"];

// Campos que cada papel pode mandar neste PATCH. Qualquer outro é recusado —
// o corpo é do navegador, e campo desconhecido "ignorado em silêncio" é como
// uma porta acaba aberta depois, quando alguém acrescenta um `if`.
const CAMPOS_DELIVERY = new Set(["status", "perguntas", "aprovacao"]);
const CAMPOS_CLIENTE = new Set(["perguntas", "aprovacao"]);

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    include: { client: { select: { nome: true, encerradoEm: true } } },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  if (!canAccessClient(usuario.role, usuario.clientId, demanda.clientId)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }
  // Cliente encerrado: só o admin ainda mexe no histórico (lib/encerramento.ts).
  if (!enxergaCliente(usuario.role, demanda.client)) {
    const encerrado = recusaSeEncerrado(demanda.client, "demanda");
    if (encerrado) return encerrado;
  }

  const permitidos = canManageClientData(usuario.role) ? CAMPOS_DELIVERY : CAMPOS_CLIENTE;
  const proibidos = Object.keys(body).filter((k) => !permitidos.has(k));
  if (proibidos.length > 0) {
    return NextResponse.json({ error: `campo não editável: ${proibidos.join(", ")}` }, { status: 403 });
  }

  const data: Prisma.DemandaUpdateInput = {};
  const autor = usuario.nome.trim() || usuario.email;

  if ("status" in body) {
    const status = String(body.status) as StatusDemanda;
    // Congelar exige motivo e guarda a etapa de origem — é /ciclo, não o dropdown.
    if (status === "standby") {
      return NextResponse.json({ error: "para congelar use a ação Congelar do card" }, { status: 400 });
    }
    if (demanda.status === "standby" && (demanda.congeladaDe || demanda.materializadoEm)) {
      return NextResponse.json({ error: "para tirar do congelamento use Descongelar no card" }, { status: 400 });
    }
    if (!TRIAGE_STATUSES.includes(status)) {
      return NextResponse.json(
        { error: "esse status só avança via sfagents (fora da triagem)" },
        { status: 400 }
      );
    }
    data.status = status;
    data.historico = [
      ...(Array.isArray(demanda.historico) ? demanda.historico : []),
      // Autor sempre da sessão — nunca um nome que o corpo afirma.
      { de: demanda.status, para: status, autor, em: new Date().toISOString() },
    ];
  }

  // Responder as perguntas do gate e registrar a aprovação são a mesma coisa
  // que aprovar: quem faz isso é quem aprova aquele gate. Pro papel `cliente`
  // isso é só `aguardando_homologacao` — a mesma regra de
  // /api/demandas/[id]/aprovar-gate, e por isso a mesma constante. Sem isto a
  // tela escondia as perguntas do gate interno mas a API aceitava a resposta,
  // que é o tipo de porta que ninguém encontra até alguém encontrar.
  if ("perguntas" in body || "aprovacao" in body) {
    if (!canManageClientData(usuario.role) && demanda.status !== GATE_DO_CLIENTE) {
      return NextResponse.json(
        { error: "este gate é interno de delivery — quem responde é o time da Acxya" },
        { status: 403 }
      );
    }
  }

  if ("perguntas" in body) {
    // Só respostas às perguntas que já existem — ver mesclarRespostas.
    const perguntas = mesclarRespostas(demanda.perguntas, body.perguntas);
    if (!perguntas) return NextResponse.json({ error: "perguntas em formato inválido" }, { status: 400 });
    data.perguntas = perguntas as unknown as Prisma.InputJsonValue;
  }

  if ("aprovacao" in body) {
    const aprovacao = montarAprovacao(body.aprovacao, usuario);
    if (!aprovacao) return NextResponse.json({ error: "aprovação em formato inválido" }, { status: 400 });
    data.aprovacao = aprovacao as unknown as Prisma.InputJsonValue;
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nenhum campo editável enviado" }, { status: 400 });
  }

  // Compare-and-set: a leitura acima e esta escrita não são atômicas, e o
  // sync do pipeline pode ter movido a demanda pra execução no meio. Mover
  // triagem só vale se ela AINDA está em triagem; responder/aprovar só vale
  // se ela ainda está no mesmo status lido (o gate não mudou por baixo).
  const where: Prisma.DemandaWhereInput =
    "status" in body
      ? { id, status: { in: TRIAGE_STATUSES } }
      : { id, status: demanda.status };
  const { count } = await prisma.demanda.updateMany({ where, data: data as Prisma.DemandaUpdateManyMutationInput });
  if (count === 0) {
    return NextResponse.json(
      { error: "a demanda mudou de etapa enquanto você editava — recarregue a página" },
      { status: 409 }
    );
  }
  const updated = await prisma.demanda.findUnique({ where: { id } });
  return NextResponse.json(updated);
}

// Excluir de verdade só o que nunca foi materializado: depois disso existe
// pasta no git, branch, PR e telemetria apontando pro código — apagar a linha
// deixaria tudo isso órfão e o número livre pra ser reusado. Para essas, o
// caminho é cancelar (/api/demandas/[id]/ciclo).
export async function DELETE(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true });
  if (acesso.erro) return acesso.erro;

  const { count } = await prisma.demanda.deleteMany({ where: { id, materializadoEm: null } });
  if (count === 0) {
    return NextResponse.json(
      { error: "demanda já foi para a esteira — cancele em vez de excluir" },
      { status: 409 }
    );
  }
  return NextResponse.json({ ok: true });
}
