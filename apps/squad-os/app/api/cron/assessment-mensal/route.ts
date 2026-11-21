import { NextResponse, type NextRequest } from "next/server";
import { autorizarCron } from "@/lib/cron-auth";
import { prisma } from "@/lib/prisma";
import { dispararAssessment } from "@/lib/assessment";
import { execucaoTravada } from "@/lib/execucao";

// Assessment mensal (2026-11-21, decisão do responsável): o diagnóstico da org
// de cada cliente é refeito uma vez por mês, para o copiloto ter recomendações
// atuais ao propor melhorias (lib/copilot/ferramentas-assessment.ts). Roda no
// dia 5 (vercel.json), fora do fechamento do mês.
//
// Dispara para cada cliente ativo com a org de dev conectada, sem assessment
// rodando e cujo último assessment tem mais de 25 dias (um disparo manual
// recente conta). O agente `org-assessment` é só leitura na org de dev; o
// resultado volta por /api/sync/assessment como no disparo manual.
// `?dry=1` só devolve quem seria disparado.

const DIAS_MINIMOS = 25;

export async function GET(request: NextRequest) {
  const negado = autorizarCron(request);
  if (negado) return negado;
  const dry = request.nextUrl.searchParams.get("dry") === "1";
  const limite = new Date(Date.now() - DIAS_MINIMOS * 86_400_000);

  const clientes = await prisma.client.findMany({
    where: { encerradoEm: null, ambientes: { some: { tipo: "dev", statusConexao: "conectado" } } },
    select: { id: true, slug: true, nome: true, assessmentEm: true, assessmentStatus: true, assessmentIniciadoEm: true },
    orderBy: { nome: "asc" },
  });

  const disparados: string[] = [];
  const pulados: { cliente: string; motivo: string }[] = [];
  const falhas: { cliente: string; erro: string }[] = [];
  for (const c of clientes) {
    if (c.assessmentStatus === "rodando" && !execucaoTravada(c.assessmentIniciadoEm)) {
      pulados.push({ cliente: c.nome, motivo: "assessment já rodando" });
      continue;
    }
    if (c.assessmentEm && c.assessmentEm > limite) {
      pulados.push({ cliente: c.nome, motivo: `último assessment há menos de ${DIAS_MINIMOS} dias` });
      continue;
    }
    if (dry) {
      disparados.push(c.nome);
      continue;
    }
    try {
      await dispararAssessment(c.id, c.slug);
      disparados.push(c.nome);
    } catch (e) {
      falhas.push({ cliente: c.nome, erro: e instanceof Error ? e.message : String(e) });
    }
  }
  return NextResponse.json({ ok: falhas.length === 0, dry, disparados, pulados, falhas }, { status: falhas.length ? 500 : 200 });
}
