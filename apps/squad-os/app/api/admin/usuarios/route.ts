import { NextResponse, type NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCurrentUsuario } from "@/lib/current-user";
import type { Role } from "@/lib/generated/prisma/client";
import { createServiceClient, serviceRoleConfigurado } from "@/lib/supabase/storage";

const ROLES: Role[] = ["admin", "consultor", "cliente"];

// proxy.ts já bloqueia /api/admin/** pra quem não é admin — a checagem
// abaixo é defesa em profundidade, não o gate principal.
export async function POST(request: NextRequest) {
  const usuario = await getCurrentUsuario();
  if (!usuario || usuario.role !== "admin") {
    return NextResponse.json({ error: "sem permissão" }, { status: 403 });
  }

  const body = await request.json();
  const email = String(body.email ?? "").toLowerCase().trim();
  const role = body.role as Role;
  const clientId = body.clientId ? String(body.clientId) : null;

  if (!email || !ROLES.includes(role)) {
    return NextResponse.json({ error: "email e role válidos são obrigatórios" }, { status: 400 });
  }
  if (role === "cliente" && !clientId) {
    return NextResponse.json({ error: "role=cliente precisa de um cliente atribuído" }, { status: 400 });
  }

  const novo = await prisma.usuario.upsert({
    where: { email },
    update: { role, clientId: role === "cliente" ? clientId : null, nome: String(body.nome ?? "").trim() },
    create: {
      email,
      nome: String(body.nome ?? "").trim(),
      role,
      clientId: role === "cliente" ? clientId : null,
      concedidoPor: usuario.email,
    },
  });

  // Conceder acesso passa a criar o usuário no Supabase Auth e mandar o
  // convite. Antes isso não existia e o auto-cadastro tapava o buraco: a pessoa
  // criava a própria conta e o admin liberava depois. Com o cadastro fechado,
  // sem convite ninguém novo entraria — "esqueci minha senha" só funciona pra
  // quem já tem linha em auth.users, e quem acabou de ser concedido não tem.
  //
  // Falha no convite não desfaz a concessão: o acesso está dado e é verdade. O
  // que volta é um aviso, pro admin saber que precisa reenviar.
  let convite: string | null = null;
  if (!serviceRoleConfigurado()) {
    convite = "SUPABASE_SERVICE_ROLE_KEY não configurada — acesso concedido, mas o convite não foi enviado.";
  } else {
    const origin = new URL(request.url).origin;
    const { error } = await createServiceClient().auth.admin.inviteUserByEmail(email, {
      redirectTo: `${origin}/auth/callback?next=${encodeURIComponent("/auth/nova-senha")}`,
    });
    // "already been registered" é o caso normal de mudar o papel de alguém que
    // já entra no sistema — não é erro, e avisar seria ruído.
    if (error && !/already/i.test(error.message)) {
      convite = `Acesso concedido, mas o convite não saiu: ${error.message}`;
    }
  }

  return NextResponse.json({ ...novo, avisoConvite: convite }, { status: 201 });
}
