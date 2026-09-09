import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { autorizarSync } from "@/lib/sync-auth";
import { triggerAssessment } from "@/lib/github";
import type { StatusConexao, TipoAmbiente } from "@/lib/generated/prisma/client";

// Resultado do smoke test de JWT (test-connection.yml) voltando pro app.
//
// É aqui que o onboarding vira automático: quando a org de **dev** de um
// cliente autentica pela primeira vez, este handler dispara o assessment. A
// primeira atividade de um cliente novo é diagnosticar a org dele — ninguém
// desenha solução numa org que não conhece, e esperar alguém lembrar de rodar
// o assessment é o mesmo que não ter assessment.

const STATUS: StatusConexao[] = ["nao_configurado", "aguardando_teste", "conectado", "erro"];
const TIPOS: TipoAmbiente[] = ["dev", "qa"];

export async function POST(request: NextRequest) {
  const naoAutorizado = autorizarSync(request);
  if (naoAutorizado) return naoAutorizado;

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const clientSlug = String(body.client ?? "");
  const tipo = String(body.ambiente ?? "") as TipoAmbiente;
  const status = String(body.status ?? "") as StatusConexao;

  if (!clientSlug || !TIPOS.includes(tipo) || !STATUS.includes(status)) {
    return NextResponse.json({ error: "client, ambiente e status são obrigatórios" }, { status: 400 });
  }

  const client = await prisma.client.findUnique({
    where: { slug: clientSlug },
    select: { id: true, assessmentEm: true },
  });
  if (!client) {
    return NextResponse.json({ error: `cliente '${clientSlug}' não encontrado` }, { status: 404 });
  }

  const ambiente = await prisma.ambienteOrg.findUnique({
    where: { clientId_tipo: { clientId: client.id, tipo } },
    select: { id: true, statusConexao: true },
  });
  if (!ambiente) {
    return NextResponse.json(
      { aviso: `cliente '${clientSlug}' não tem ambiente '${tipo}' cadastrado` },
      { status: 202 }
    );
  }

  await prisma.ambienteOrg.update({
    where: { id: ambiente.id },
    data: { statusConexao: status },
  });

  // Só na org de dev, só quando conecta, e só se ainda não houve assessment.
  // A terceira condição é a que impede um re-teste de conexão de queimar uma
  // sessão de agente à toa — refazer o assessment é uma decisão, e tem botão
  // próprio no perfil do cliente.
  let assessmentDisparado = false;
  if (tipo === "dev" && status === "conectado" && !client.assessmentEm) {
    try {
      await triggerAssessment(clientSlug);
      assessmentDisparado = true;
    } catch (err) {
      // Não derruba o sync: a conexão foi confirmada de verdade, e essa é a
      // informação que não pode se perder. O assessment tem botão manual.
      console.error("falha ao disparar o assessment de onboarding", err);
    }
  }

  return NextResponse.json({ ok: true, status, assessmentDisparado });
}
