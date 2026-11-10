import { getClients, getClientById, getClientesEncerrados } from "@/lib/data";
import { getCurrentUsuario } from "@/lib/current-user";
import { Sidebar } from "@/components/Sidebar";
import { Copiloto } from "@/components/Copiloto";
import { marcaUrl, marcaDarkUrl } from "@/lib/marca";
import { clienteDaSidebar } from "@/lib/visao-cliente";
import { esteiraPorCliente } from "@/lib/esteira-sidebar";
import { apiIndisponivelDesde } from "@/lib/api-indisponivel";
import { chaveDia, rotuloDia } from "@/lib/horas";

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
  // Só o time vê: é assunto de conta/cobrança, não do cliente.
  const semApiDesde =
    usuario.role === "admin" || usuario.role === "consultor" ? await apiIndisponivelDesde().catch(() => null) : null;

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
        marcaDarkSrc={marcaDarkUrl()}
        clients={clients.map((c) => clienteDaSidebar(c, esteira[c.id]))}
        encerrados={encerrados.map((c) => ({ id: c.id, nome: c.nome }))}
        usuario={usuario}
      />
      <main id="conteudo" tabIndex={-1}>
        {semApiDesde && (
          <div className="conn-warning" role="alert">
            <strong>A esteira está parada: a API do modelo recusou as execuções</strong> desde{" "}
            {rotuloDia(chaveDia(semApiDesde))} (saldo de crédito ou chave da Anthropic). Nenhum agente roda até isso ser
            resolvido em console.anthropic.com → Billing. Depois, reenvie as demandas que falharam; este aviso some na
            primeira execução que der certo.
          </div>
        )}
        {children}
      </main>
      {/* Uma conversa só, que atravessa a navegação; o contexto (cliente da
          página aberta) sai do caminho — ver Copiloto.tsx. */}
      <Copiloto papel={usuario.role} clientes={clients.map((c) => ({ id: c.id, nome: c.nome }))} />
    </div>
  );
}
