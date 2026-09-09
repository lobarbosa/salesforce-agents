import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { generateDemandCode } from "@/lib/slug";
import { getCurrentUsuario } from "@/lib/current-user";
import { canAccessClient } from "@/lib/auth";

export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json();
  const clientId = String(body.clientId ?? "");
  const titulo = String(body.titulo ?? "").trim();
  if (!clientId || !titulo) {
    return NextResponse.json({ error: "clientId e titulo são obrigatórios" }, { status: 400 });
  }
  if (!canAccessClient(usuario.role, usuario.clientId, clientId)) {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const client = await prisma.client.findUnique({ where: { id: clientId } });
  if (!client) {
    return NextResponse.json({ error: "cliente não encontrado" }, { status: 404 });
  }

  // Autor sai da sessão, não do corpo: além de poupar o preenchimento manual,
  // impede que quem chama a API registre a demanda em nome de outra pessoa.
  // `nome` é opcional em `usuarios` (default ""), daí o fallback pro e-mail.
  const autor = usuario.nome.trim() || usuario.email;
  const tipo = body.tipo === "projeto" ? "projeto" : "sustentacao";
  const code = await generateDemandCode(clientId, client.slug);

  const demanda = await prisma.demanda.create({
    data: {
      clientId,
      code,
      titulo,
      tipo,
      texto: String(body.texto ?? "").trim(),
      autor,
      status: "backlog",
      historico: [{ de: null, para: "backlog", autor, em: new Date().toISOString() }],
    },
  });

  return NextResponse.json(demanda, { status: 201 });
}
