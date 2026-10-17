import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { AVISO_WORKSPACE, enxergaCliente, linhaDeAuditoria, podeEncerrarCliente, validarExclusao } from "@/lib/encerramento";
import { historicoDoCliente } from "@/lib/encerramento-server";
import { travar } from "@/lib/trava";

// Campos editáveis por PATCH — um por vez, no mesmo padrão de autosave-on-blur
// da versão anterior. Os campos de conexão saíram daqui: agora são por
// ambiente, em /api/clients/[id]/ambientes/[tipo]. Chave privada e Consumer
// Secret nunca entram em nenhuma das duas (ver docs/conexoes-e-setup.md).
const EDITABLE_FIELDS = [
  "nome",
  "segmento",
  "contatos",
  "ambienteSalesforce",
  "integracoes",
  "regras",
] as const;
// `marcas` e `concorrentes` saíram do briefing a pedido, e já saíram do schema
// e do banco — ver README, "Por que o DROP não vem junto", que explica por que
// as duas coisas não podiam ir no mesmo merge.

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json();

  const data: Record<string, string> = {};
  for (const key of EDITABLE_FIELDS) {
    if (key in body) data[key] = String(body[key] ?? "");
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "nenhum campo editável enviado" }, { status: 400 });
  }

  // Cliente encerrado só o admin enxerga (lib/encerramento.ts): o consultor
  // não edita o briefing de quem já saiu.
  const atual = await prisma.client.findUnique({ where: { id }, select: { encerradoEm: true } });
  if (!atual) return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  if (!enxergaCliente(usuario.role, atual)) {
    return NextResponse.json({ error: "cliente encerrado — só admin edita" }, { status: 409 });
  }

  try {
    const client = await prisma.client.update({ where: { id }, data });
    return NextResponse.json(client);
  } catch {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }
}

// Excluir definitivamente — só admin, só cliente já encerrado e sem histórico
// nenhum (demandas, horas, execuções de agente, contrato com conteúdo), e só
// com o nome do cliente digitado na confirmação. O resto vai na cascata de
// sempre (ambientes, contrato vazio, usuários, chunks de RAG). O caminho
// normal para "cliente que saiu" é encerrar (./encerramento), não isto.
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !podeEncerrarCliente(usuario.role)) {
    return NextResponse.json({ error: "sem permissão — só admin exclui cliente" }, { status: 403 });
  }

  const { id } = await params;
  const body = await request.json().catch(() => ({}));
  const nomeDigitado = String(body?.confirmacaoNome ?? "");

  // Conferir e apagar na mesma transação, sob lock por cliente: um registro
  // de tempo ou execução que chegasse entre a contagem e o DELETE iria junto
  // na cascata sem ninguém ter visto.
  const resultado = await prisma.$transaction(async (tx) => {
    await travar(tx, `cliente:${id}`);
    const client = await tx.client.findUnique({
      where: { id },
      select: { id: true, slug: true, nome: true, encerradoEm: true },
    });
    if (!client) return { status: 404, corpo: { error: "cliente não encontrado" } };
    const historico = await historicoDoCliente(id, tx);
    const v = validarExclusao(client, historico, nomeDigitado);
    if (!v.ok) return { status: v.status, corpo: { error: v.error, bloqueios: v.bloqueios ?? [] } };
    await tx.client.delete({ where: { id } });
    return { status: 200, corpo: { ok: true, slug: client.slug, aviso: AVISO_WORKSPACE.replace("<slug>", client.slug) }, client };
  });

  if (resultado.client) {
    console.info(linhaDeAuditoria("excluiu", resultado.client, usuario.email));
  }
  return NextResponse.json(resultado.corpo, { status: resultado.status });
}
