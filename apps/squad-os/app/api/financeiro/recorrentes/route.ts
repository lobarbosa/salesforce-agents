import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { prisma } from "@/lib/prisma";
import { validarModelo, type DadosModelo } from "@/lib/recorrencias";
import { criarModelo } from "@/lib/recorrencias-data";

// Cria um modelo de despesa recorrente. Com `contaId` no corpo, é o "Tornar
// recorrente" de uma conta avulsa: o modelo começa no mês dela e a conta passa
// a ser a primeira ocorrência (não é gerada de novo).
export async function POST(request: NextRequest) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object") return NextResponse.json({ error: "corpo inválido" }, { status: 400 });

  const v = validarModelo(body);
  if (v.erro !== undefined) return NextResponse.json({ error: v.erro }, { status: 400 });
  const dados: DadosModelo = {
    descricao: "",
    categoria: "",
    valorVariavel: false,
    fim: null,
    clientId: null,
    ...(v.dados as Omit<DadosModelo, "descricao" | "categoria" | "valorVariavel" | "fim" | "clientId">),
  };
  if (dados.clientId && !(await prisma.client.findUnique({ where: { id: dados.clientId }, select: { id: true } }))) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 400 });
  }
  const contaId = typeof body.contaId === "string" && body.contaId ? body.contaId.slice(0, 60) : undefined;

  const r = await criarModelo(dados, acesso.usuario.email, contaId);
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json(r, { status: 201 });
}
