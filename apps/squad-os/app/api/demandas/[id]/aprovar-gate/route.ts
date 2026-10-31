import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { resolverDemanda } from "@/lib/demanda-access";
import { processarFila } from "@/lib/fila-esteira";
import { GATE_DO_CLIENTE, estimativaAprovada, marcadorDeGate } from "@/lib/demandas";
import { travar } from "@/lib/trava";
import { recusaSeEncerrado } from "@/lib/encerramento-server";
import { exigeRiscoAceito } from "@/lib/qa-veredito";

// O gate humano deixa de ser "aprova aqui e alguém dispara o pipeline lá":
// aprovar no card move a demanda e acende a próxima sessão de agente.
//
// Quem pode aprovar o quê segue a doutrina, não o papel genérico:
// `aguardando_homologacao` é o cliente dizendo que aceita o que foi entregue —
// é dele esse gate. Os outros (análise, design, PR) são internos de delivery e
// não fazem sentido pra quem está do lado de fora. A constante mora em
// lib/demandas.ts: a tela, esta rota e o PATCH de perguntas/aprovação
// precisam responder isto pelo mesmo lugar.

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const acesso = await resolverDemanda(id);
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    include: { client: { select: { slug: true, nome: true, encerradoEm: true } } },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }
  // Aprovar gate dispara a próxima sessão de agente.
  const encerrado = recusaSeEncerrado(demanda.client, "agente");
  if (encerrado) return encerrado;

  if (!demanda.status.startsWith("aguardando_")) {
    return NextResponse.json(
      { error: `a demanda está em '${demanda.status}', que não é um gate humano` },
      { status: 409 }
    );
  }

  if (usuario.role === "cliente" && demanda.status !== GATE_DO_CLIENTE) {
    return NextResponse.json(
      { error: "este gate é interno de delivery — quem aprova é o time da Acxya" },
      { status: 403 }
    );
  }

  if (!demanda.materializadoEm) {
    return NextResponse.json(
      { error: "a demanda ainda não foi materializada — não existe no repositório pra avançar" },
      { status: 409 }
    );
  }

  // Build só com a estimativa aprovada pelo cliente (2026-10-21): é o número
  // que vai debitar do contrato quando a construção começar.
  if (demanda.status === "aguardando_gate_design" && !estimativaAprovada(demanda)) {
    return NextResponse.json(
      {
        error:
          demanda.estimativaConsultorHoras == null
            ? "lance a estimativa oficial no card — o cliente precisa aprová-la antes do build"
            : "o cliente ainda não aprovou a estimativa de horas — o build só sai depois disso",
      },
      { status: 409 }
    );
  }
  // QA com falha crítica: homologar é aceitar o risco, e isso fica escrito.
  const corpo = (await request.json().catch(() => null)) as { riscoAceito?: unknown } | null;
  const riscoAceito = String(corpo?.riscoAceito ?? "").trim().slice(0, 1000);
  if (exigeRiscoAceito(demanda) && riscoAceito.length < 10) {
    return NextResponse.json(
      { error: "os testes encontraram falha crítica — para homologar mesmo assim, escreva o risco que está aceitando" },
      { status: 400 }
    );
  }
  const autor = usuario.nome.trim() || usuario.email;
  const gate = demanda.status;
  const marcador = marcadorDeGate(gate);

  // Reivindica e enfileira na mesma transação (lock por demanda): dois
  // cliques ou duas pessoas não geram duas aprovações. Até 2026-10-21 a
  // reivindicação era o comentário de rastro e o disparo ia direto pro
  // Actions — que guarda um só pendente por cliente: aprovar vários cards em
  // sequência cancelava os anteriores em silêncio (5 gates da Somos). Agora
  // a aprovação entra na fila do cliente (lib/fila-esteira.ts) e sai de lá
  // um disparo por vez. O workflow ainda confere `gate_esperado`.
  const claim = await prisma.$transaction(async (tx) => {
    await travar(tx, `aprovar-gate:${demanda.id}`);
    const atual = await tx.demanda.findUnique({ where: { id: demanda.id }, select: { status: true } });
    if (!atual || atual.status !== gate) return { conflito: "a demanda saiu deste gate enquanto você decidia — recarregue" };
    const aberto = await tx.disparoEsteira.findFirst({
      where: { demandaId: demanda.id, tipo: "aprovar", gate, concluidoEm: null },
      select: { autor: true },
    });
    if (aberto) {
      return { conflito: `este gate já foi liberado por ${aberto.autor} — está na fila da esteira` };
    }
    await tx.disparoEsteira.create({
      data: { clientId: demanda.clientId, demandaId: demanda.id, tipo: "aprovar", gate, autor },
    });
    // Rastro na conversa do card. O `gates.md` da demanda continua sendo o
    // log oficial — escrito por gates.py quando a execução roda.
    await tx.comentario.create({
      data: {
        demandaId: demanda.id,
        autor,
        autorEmail: usuario.email,
        texto: riscoAceito
          ? `${marcador} Entrou na fila da esteira. Aprovado com falha crítica no QA — risco aceito: ${riscoAceito}`
          : `${marcador} Entrou na fila da esteira.`,
      },
    });
    return { ok: true as const };
  });
  if ("conflito" in claim) {
    return NextResponse.json({ error: claim.conflito }, { status: 409 });
  }
  // Se o cliente está livre, sai agora; senão, quando a execução atual
  // sincronizar (ou na varredura). Falha aqui não perde nada: está na fila.
  await processarFila(demanda.clientId).catch((e) => console.error("aprovar-gate: processarFila", e));
  return NextResponse.json({ ok: true, gate, por: autor });
}
