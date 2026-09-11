import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import { canManageClientData } from "@/lib/auth";
import { asSla, SLA_PADRAO } from "@/lib/contrato";
import type { TipoContrato } from "@/lib/generated/prisma/client";

const TIPOS: TipoContrato[] = ["ams", "projeto"];
const HORAS_MAX = 10_000;

// Um contrato por cliente, criado ou atualizado pelo mesmo PUT — não existe
// "criar contrato" como ato separado: o cliente ou tem um, ou passa a ter.
// Só admin/consultor: é dado comercial, não algo que o cliente final edita.
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const usuario = await getCurrentUsuario();
  if (!usuario || !canManageClientData(usuario.role)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const { id } = await params;
  const client = await prisma.client.findUnique({ where: { id }, select: { id: true } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "corpo inválido" }, { status: 400 });
  }

  const tipo = body.tipo as TipoContrato;
  if (!TIPOS.includes(tipo)) {
    return NextResponse.json({ error: "tipo precisa ser 'ams' ou 'projeto'" }, { status: 400 });
  }

  const horas = Math.round(Number(body.horasContratadas) || 0);
  if (horas < 0 || horas > HORAS_MAX) {
    return NextResponse.json(
      { error: `horas contratadas fora da faixa (0 a ${HORAS_MAX})` },
      { status: 400 }
    );
  }

  // SLA só faz sentido em AMS; num contrato de projeto ele fica vazio em vez
  // de guardar a tabela de um tipo que não se aplica.
  const sla = tipo === "ams" ? (body.sla === undefined ? SLA_PADRAO : asSla(body.sla)) : [];

  const dados = {
    tipo,
    horasContratadas: tipo === "ams" ? horas : 0,
    cicloHoras: String(body.cicloHoras ?? "mensal").trim().slice(0, 30) || "mensal",
    sla,
    projetoNome: tipo === "projeto" ? String(body.projetoNome ?? "").trim().slice(0, 200) : "",
    projetoEscopo: tipo === "projeto" ? String(body.projetoEscopo ?? "").trim().slice(0, 4000) : "",
    inicioEm: tipo === "projeto" ? dataOuNull(body.inicioEm) : null,
    fimPrevistoEm: tipo === "projeto" ? dataOuNull(body.fimPrevistoEm) : null,
  };

  const contrato = await prisma.contrato.upsert({
    where: { clientId: id },
    update: dados,
    create: { clientId: id, ...dados },
    include: { entregaveis: { orderBy: { ordem: "asc" } } },
  });

  return NextResponse.json(contrato);
}

function dataOuNull(valor: unknown): Date | null {
  if (!valor) return null;
  const d = new Date(String(valor));
  return Number.isNaN(d.getTime()) ? null : d;
}
