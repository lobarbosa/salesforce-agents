import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import type { Prisma } from "@/lib/generated/prisma/client";
import { resolverDemanda } from "@/lib/demanda-access";
import { BUCKET_ANEXOS } from "@/lib/supabase/storage";
import { removerArquivo, subirArquivo } from "@/lib/arquivo";
import { gravarArquivoDaDemandaNoGit, registrarStatusNoGit } from "@/lib/github";
import { travar } from "@/lib/trava";
import {
  ARQUIVO_ENTREGA_MANUAL,
  conteudoDaEntregaManual,
  erroDoRegistro,
  motivoSemEntregaManual,
} from "@/lib/entrega-manual";

// Entrega manual pelo consultor (lib/entrega-manual.ts). Só delivery; o
// cliente homologa depois, pelo gate de sempre (/aprovar-gate).
//
// Ordem: valida, sobe a evidência, grava o registro e o status no repositório
// (fonte de verdade da demanda materializada) e só então o Postgres. Se o
// repositório falhar, a evidência é removida e nada muda.
export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acesso = await resolverDemanda(id, { somenteDelivery: true, clienteAtivo: "demanda" });
  if (acesso.erro) return acesso.erro;
  const { usuario } = acesso;

  const form = await request.formData().catch(() => null);
  const descricao = String(form?.get("descricao") ?? "").trim().slice(0, 4000);
  const arquivo = form?.get("arquivo");
  const temArquivo = arquivo instanceof File && arquivo.size > 0;
  const incompleto = erroDoRegistro(descricao, temArquivo);
  if (incompleto) return NextResponse.json({ error: incompleto }, { status: 400 });

  const demanda = await prisma.demanda.findUnique({
    where: { id },
    include: {
      client: { select: { slug: true } },
      disparos: { where: { concluidoEm: null }, select: { concluidoEm: true } },
    },
  });
  if (!demanda) return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  const recusa = motivoSemEntregaManual(demanda);
  if (recusa) return NextResponse.json({ error: recusa }, { status: 409 });

  const r = await subirArquivo(BUCKET_ANEXOS, id, arquivo as File, "anexo");
  if ("erro" in r) return r.erro;

  const autor = usuario.nome.trim() || usuario.email;
  const agora = new Date();
  const registro = conteudoDaEntregaManual({
    code: demanda.code,
    titulo: demanda.titulo,
    por: autor,
    em: agora,
    descricao,
    evidencia: r.nome,
  });

  if (demanda.materializadoEm) {
    try {
      await gravarArquivoDaDemandaNoGit(demanda.client.slug, demanda.code, ARQUIVO_ENTREGA_MANUAL, registro);
      await registrarStatusNoGit(demanda.client.slug, demanda.code, "aguardando_homologacao", autor, "entrega manual");
    } catch (err) {
      await removerArquivo(BUCKET_ANEXOS, r.caminho);
      return NextResponse.json(
        { error: `não consegui gravar a entrega no repositório: ${(err as Error).message}` },
        { status: 502 }
      );
    }
  }

  const mudou = await prisma.$transaction(async (tx) => {
    await travar(tx, `aprovar-gate:${demanda.id}`);
    // Compare-and-set: se a esteira moveu a demanda no meio, recusa.
    const { count } = await tx.demanda.updateMany({
      where: { id, status: demanda.status },
      data: {
        status: "aguardando_homologacao",
        historico: [
          ...(Array.isArray(demanda.historico) ? demanda.historico : []),
          { de: demanda.status, para: "aguardando_homologacao", autor, em: agora.toISOString(), motivo: "entrega manual" },
        ] as Prisma.InputJsonValue,
        entregaManualEm: agora,
        entregaManualPor: autor,
        entregaManualDescricao: descricao,
        // O card mostra o registro como o artefato da etapa: é o que o
        // cliente lê antes de homologar.
        artefatoNome: ARQUIVO_ENTREGA_MANUAL,
        artefatoConteudo: registro,
        artefatoTruncado: false,
        // Horas aprovadas pelo cliente e ainda não debitadas entram no
        // contrato agora, como entrariam no começo da construção.
        ...(demanda.estimativaAprovadaHoras != null && demanda.estimativaDebitadaEm == null
          ? { estimativaDebitadaHoras: demanda.estimativaAprovadaHoras, estimativaDebitadaEm: agora }
          : {}),
      },
    });
    if (count === 0) return false;
    await tx.anexo.create({
      data: {
        demandaId: id,
        nome: r.nome,
        caminho: r.caminho,
        tamanho: (arquivo as File).size,
        tipo: r.mime,
        autor,
        autorEmail: usuario.email,
      },
    });
    await tx.comentario.create({
      data: {
        demandaId: id,
        autor,
        autorEmail: usuario.email,
        texto: `Entrega manual registrada, com a evidência "${r.nome}" anexada. Aguardando a homologação do cliente.\n\n${descricao}`,
      },
    });
    return true;
  });
  if (!mudou) {
    await removerArquivo(BUCKET_ANEXOS, r.caminho);
    return NextResponse.json({ error: "a demanda mudou de etapa — recarregue a página" }, { status: 409 });
  }
  return NextResponse.json({ ok: true, status: "aguardando_homologacao", por: autor });
}
