import { NextResponse, type NextRequest } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { lerReais } from "@/lib/contas";
import { chaveDia } from "@/lib/horas";
import { lerChave, validarRecebimento } from "@/lib/receber";
import { listarNotas, registrarRecebimento } from "@/lib/receber-data";

// Registrar o recebimento de uma NFS-e. Corpo JSON:
// { chave: "<nº>@<AAAA-MM-DD emissão>", recebidoEm: "AAAA-MM-DD", valorRecebido: "1.234,56",
//   forma: "pix"|"boleto"|"ted"|"cartao"|"outro", observacao?: string }
export async function POST(request: NextRequest) {
  const acesso = await acessoDaArea("financeiro");
  if (acesso.erro) return acesso.erro;
  const body = await request.json().catch(() => ({}));
  const chave = lerChave(String(body.chave ?? ""));
  if (!chave) return NextResponse.json({ error: "nota inválida" }, { status: 400 });

  const hoje = chaveDia(new Date());
  const lista = await listarNotas(hoje);
  if (!lista) return NextResponse.json({ error: "as notas fiscais não estão disponíveis agora — tente mais tarde" }, { status: 503 });
  const nota = lista.notas.find((n) => n.numero === chave.numero && n.emissao === chave.emissao);
  if (!nota) return NextResponse.json({ error: "nota não encontrada" }, { status: 404 });

  const v = validarRecebimento(nota, body, hoje, lerReais);
  if ("erro" in v) return NextResponse.json({ error: v.erro }, { status: 400 });
  const r = await registrarRecebimento(nota, v.dados, acesso.usuario.email);
  if ("erro" in r) return NextResponse.json({ error: r.erro }, { status: r.status });
  return NextResponse.json({ ok: true });
}
