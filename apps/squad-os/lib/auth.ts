import { prisma } from "@/lib/prisma";
import type { Role, Usuario } from "@/lib/generated/prisma/client";
import { usuarioPerdeAcesso } from "@/lib/encerramento";

// Quem pode logar no Squad OS é decidido pela tabela `usuarios` (papel +
// cliente), não mais por domínio/lista de e-mail — ver Usuario em
// prisma/schema.prisma. ADMIN_BOOTSTRAP_EMAILS só existe pra destravar o
// primeiro admin (senão ninguém consegue logar pra criar o primeiro
// registro): qualquer e-mail dessa lista vira admin automaticamente no
// primeiro login, e passa a existir como linha normal em `usuarios` dali
// em diante — dá pra revogar depois pela própria tela de administração.
function bootstrapAdminEmails(): string[] {
  return (process.env.ADMIN_BOOTSTRAP_EMAILS ?? "")
    .split(",")
    .map((e) => e.toLowerCase().trim())
    .filter(Boolean);
}

export async function resolveUsuario(email: string): Promise<Usuario | null> {
  const normalized = email.toLowerCase().trim();
  const existing = await prisma.usuario.findUnique({
    where: { email: normalized },
    include: { client: { select: { encerradoEm: true } } },
  });
  if (existing) {
    // Cliente encerrado: o usuário `cliente` dele deixa de ter acesso — o
    // proxy chama isto a cada requisição, então a sessão aberta cai junto.
    // A linha em `usuarios` fica (reativar o cliente devolve o acesso).
    if (usuarioPerdeAcesso(existing.role, existing.client)) return null;
    const { client: _client, ...usuario } = existing;
    void _client;
    return usuario;
  }

  if (bootstrapAdminEmails().includes(normalized)) {
    return prisma.usuario.create({
      data: { email: normalized, role: "admin", concedidoPor: "bootstrap" },
    });
  }

  return null;
}

export function canManageClientData(role: Role): boolean {
  return role === "admin" || role === "consultor";
}

export function canAccessClient(role: Role, usuarioClientId: string | null, clientId: string): boolean {
  if (role === "cliente") return usuarioClientId === clientId;
  // O financeiro trabalha nas telas de /financeiro; briefing, conexão e
  // demandas de cliente não são dele (ver lib/permissoes.ts).
  if (role === "financeiro") return false;
  return true;
}
