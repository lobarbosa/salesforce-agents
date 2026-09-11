import { getClients, getClientById } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { Sidebar } from "@/components/Sidebar";
import { marcaUrl } from "@/lib/marca";

// Toda página aqui lê direto do Postgres (sem fetch(), então o Next não
// detecta dinamismo sozinho) e depende da sessão do usuário logado — nunca
// deve ser pré-renderada estaticamente no build.
export const dynamic = "force-dynamic";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const usuario = await getCurrentUsuario();
  // proxy.ts já garante um Usuario válido pra chegar aqui — null só numa
  // execução fora do proxy (ex.: teste isolado); trata como deslogado.
  if (!usuario) {
    return (
      <div className="shell">
        <main>{children}</main>
      </div>
    );
  }

  // role=cliente não precisa (e não deve) ver a lista dos outros clientes —
  // só o próprio, pra exibir o nome na sidebar.
  const clients =
    usuario.role === "cliente"
      ? await getClientById(usuario.clientId ?? "").then((c) => (c ? [c] : []))
      : await getClients();

  return (
    <div className="shell">
      <Sidebar marcaSrc={marcaUrl()} clients={clients} usuario={usuario} />
      <main>{children}</main>
    </div>
  );
}
