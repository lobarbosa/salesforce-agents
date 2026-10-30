import { getClients, getClientById, getClientesEncerrados } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { Sidebar } from "@/components/Sidebar";
import { Copiloto } from "@/components/Copiloto";
import { marcaUrl } from "@/lib/marca";
import { clienteDaSidebar } from "@/lib/visao-cliente";
import { esteiraPorCliente } from "@/lib/esteira-sidebar";

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
  // O financeiro não navega por clientes (ver lib/permissoes.ts).
  const clients =
    usuario.role === "cliente"
      ? await getClientById(usuario.clientId ?? "").then((c) => (c ? [c] : []))
      : usuario.role === "financeiro"
        ? []
        : await getClients();
  // Encerrados: fora da lista principal, numa seção à parte só para o admin.
  const encerrados = usuario.role === "admin" ? await getClientesEncerrados() : [];
  const esteira = await esteiraPorCliente(clients.map((c) => c.id));

  return (
    <div className="shell">
      {/* Primeiro item focável: pula a sidebar (itens + todos os clientes) a cada página. */}
      <a href="#conteudo" className="skip-link">
        Pular para o conteúdo
      </a>
      {/* Só id/nome/saúde de cada cliente: o objeto inteiro (ambientes,
          briefing, assessment) ia no payload RSC pra qualquer papel. */}
      <Sidebar
        marcaSrc={marcaUrl()}
        clients={clients.map((c) => clienteDaSidebar(c, esteira[c.id]))}
        encerrados={encerrados.map((c) => ({ id: c.id, nome: c.nome }))}
        usuario={usuario}
      />
      <main id="conteudo" tabIndex={-1}>
        {children}
      </main>
      {/* Montada uma vez pra todo papel; em páginas de cliente ela se anula
          sozinha (ver Copiloto.tsx) porque ClientDetail.tsx já monta a
          própria instância, com o clientId e o nome do cliente à mão. */}
      <Copiloto papel={usuario.role} />
    </div>
  );
}
