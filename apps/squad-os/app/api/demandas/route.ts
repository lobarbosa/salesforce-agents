import { NextResponse, type NextRequest } from "next/server";
import { getCurrentUsuario } from "@/lib/current-user";
import { criarDemanda } from "@/lib/demandas-server";

export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json();
  const resultado = await criarDemanda({
    usuario,
    clientId: String(body.clientId ?? ""),
    titulo: String(body.titulo ?? ""),
    texto: String(body.texto ?? ""),
    tipo: body.tipo,
  });
  if (!resultado.ok) {
    return NextResponse.json({ error: resultado.error }, { status: resultado.status });
  }

  return NextResponse.json(resultado.demanda, { status: 201 });
}
