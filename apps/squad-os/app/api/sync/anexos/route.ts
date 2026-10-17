import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { recusaSeEncerradoPorId } from "@/lib/encerramento-server";
import { BUCKET_ANEXOS, createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";
import { chaveSegura } from "@/lib/arquivo";

// Chamada pelo run-demand.yml antes da sessão do agente: devolve só os anexos
// que alguém de delivery liberou (`liberadoEm` preenchido) desta demanda, cada
// um com uma URL assinada curta pro job baixar. Anexo não liberado nem aparece
// na resposta — o job não tem como pedir o que ninguém liberou.
//
// Mesmo bearer por cliente das outras rotas de sync; `clientSlug` decide o
// cliente e a demanda é procurada **dentro** dele (guardrail #7): um code de
// outro cliente simplesmente não é encontrado.
const SEGUNDOS_VALIDADE = 300;

export async function POST(request: NextRequest) {
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }
  const registro = body as Record<string, unknown>;
  const clientSlug = String(registro.clientSlug ?? "").trim();
  const code = String(registro.demandaId ?? "").trim();

  const naoAutorizado = autorizarSync(request, clientSlug);
  if (naoAutorizado) return naoAutorizado;

  if (!clientSlug || !code) {
    return NextResponse.json({ error: "clientSlug e demandaId são obrigatórios" }, { status: 400 });
  }
  if (!serviceRoleConfigurado()) {
    return NextResponse.json({ error: "anexos ainda não configurados" }, { status: 503 });
  }

  const encerrado = await recusaSeEncerradoPorId({ slug: clientSlug }, "sync");
  if (encerrado) return encerrado;

  const demanda = await prisma.demanda.findFirst({
    where: { code, client: { slug: clientSlug } },
    select: {
      anexos: {
        where: { liberadoEm: { not: null } },
        select: { id: true, nome: true, caminho: true, tipo: true },
        orderBy: { criadoEm: "asc" },
      },
    },
  });
  if (!demanda) {
    return NextResponse.json({ error: "demanda não encontrada" }, { status: 404 });
  }

  const storage = createServiceClient();
  const anexos = [];
  for (const a of demanda.anexos) {
    const { data, error } = await storage.storage
      .from(BUCKET_ANEXOS)
      .createSignedUrl(a.caminho, SEGUNDOS_VALIDADE);
    if (error || !data) {
      return NextResponse.json({ error: `falha ao assinar o anexo ${a.id}` }, { status: 502 });
    }
    // Nome de arquivo seguro pro disco do runner, prefixado pelo id pra dois
    // anexos com o mesmo nome não se sobrescreverem.
    anexos.push({ arquivo: `${a.id.slice(-6)}-${chaveSegura(a.nome)}`, tipo: a.tipo, url: data.signedUrl });
  }

  return NextResponse.json({ anexos }, { status: 200 });
}
