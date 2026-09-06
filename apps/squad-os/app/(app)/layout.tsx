import { getClients } from "@/lib/data";
import { createClient } from "@/lib/supabase/server";
import { Sidebar } from "@/components/Sidebar";

// Toda página aqui lê direto do Postgres (sem fetch(), então o Next não
// detecta dinamismo sozinho) e depende da sessão do usuário logado — nunca
// deve ser pré-renderada estaticamente no build.
export const dynamic = "force-dynamic";

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const [clients, supabase] = await Promise.all([getClients(), createClient()]);
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <div className="shell">
      <Sidebar clients={clients} userEmail={user?.email ?? null} />
      <main>{children}</main>
    </div>
  );
}
