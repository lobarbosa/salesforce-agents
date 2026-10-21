import { NextResponse } from "next/server";
import { acessoDaArea } from "@/lib/area";
import { listarEsteiraAoVivo } from "@/lib/esteira-ao-vivo";

// Polling da tela /esteira. Delivery vê; custo só admin (CLAUDE.md, "Custo de agente").
export async function GET() {
  const acesso = await acessoDaArea("delivery");
  if (acesso.erro) return acesso.erro;
  const runs = await listarEsteiraAoVivo({ comCusto: acesso.usuario.role === "admin" });
  return NextResponse.json({ runs, em: new Date().toISOString() }, { headers: { "Cache-Control": "no-store" } });
}
