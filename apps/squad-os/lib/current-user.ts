import { headers } from "next/headers";
import type { Role } from "@/lib/generated/prisma/client";

// proxy.ts já resolveu o Usuario (Prisma) e injetou esses headers no request
// — Server Components e Route Handlers leem daqui em vez de bater no banco
// de novo a cada chamada. Não existe pra Client Components (a sessão do
// browser não vê headers de request); o que a UI precisa disso desce como
// prop a partir de um Server Component.
export interface CurrentUsuario {
  id: string;
  email: string;
  nome: string;
  role: Role;
  clientId: string | null;
}

export async function getCurrentUsuario(): Promise<CurrentUsuario | null> {
  const h = await headers();
  const id = h.get("x-squad-os-usuario-id");
  const email = h.get("x-squad-os-usuario-email");
  const role = h.get("x-squad-os-usuario-role") as Role | null;
  if (!id || !email || !role) return null;
  return {
    id,
    email,
    nome: h.get("x-squad-os-usuario-nome") ?? "",
    role,
    clientId: h.get("x-squad-os-usuario-client-id") || null,
  };
}
