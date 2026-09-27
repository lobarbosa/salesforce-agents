import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { acessoDaArea } from "@/lib/area";
import { bloqueio, type Acao } from "@/lib/contas";
import { eventosDa, paraVista } from "@/lib/contas-data";

// Detalhe da conta: dados, trilha de eventos e, para cada ação, se a pessoa
// logada pode fazê-la (e por que não) — a tela mostra o motivo em vez de um
// botão que falha.
export async function GET(_request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const { id } = await params;
  const c = await prisma.contaPagar.findUnique({ where: { id } });
  if (!c) return NextResponse.json({ error: "conta não encontrada" }, { status: 404 });

  const conta = paraVista(c);
  const acoes: Acao[] = ["aprovar", "recusar", "pagar", "cancelar"];
  const bloqueios = Object.fromEntries(
    acoes.map((a) => [a, bloqueio(a, conta, { role: acesso.usuario.role, email: acesso.usuario.email })])
  );
  return NextResponse.json({ conta, eventos: await eventosDa(id), bloqueios });
}
