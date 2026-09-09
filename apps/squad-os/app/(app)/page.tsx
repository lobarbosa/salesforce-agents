import Link from "next/link";
import { getClients, getAllDemandas } from "@/lib/data";
import { perguntasPendentes, asAprovacao } from "@/lib/demandas";

const CONN_STATUS_LABEL: Record<string, string> = {
  nao_configurado: "Não configurado",
  aguardando_teste: "Teste de conexão solicitado",
  conectado: "Conectado",
  erro: "Erro na última tentativa",
};

export default async function OverviewPage() {
  const [clients, demandas] = await Promise.all([getClients(), getAllDemandas()]);
  const clientNome = (id: string) => clients.find((c) => c.id === id)?.nome ?? id;

  const pendentes = demandas
    .filter((d) => {
      const perguntas = Array.isArray(d.perguntas) ? d.perguntas : [];
      const aprov = asAprovacao(d.aprovacao);
      return perguntas.length > 0 && !aprov?.aprovado;
    })
    .sort((a, b) => b.criadoEm.getTime() - a.criadoEm.getTime());

  // Pendência agora é por ambiente, não por cliente: a esteira só roda ponta
  // a ponta se dev e qa estiverem conectados. Ambiente ainda não cadastrado
  // conta como pendente — a linha só existe depois do primeiro save.
  const conexoesPendentes = clients.flatMap((c) =>
    (["dev", "qa"] as const).flatMap((tipo) => {
      const status = c.ambientes.find((a) => a.tipo === tipo)?.statusConexao ?? "nao_configurado";
      return status === "conectado" ? [] : [{ client: c, tipo, status }];
    })
  );

  return (
    <>
      <div className="overview-header">
        <h1>Visão Geral</h1>
        <p>O que precisa da sua atenção entre os {clients.length} clientes ativos.</p>
      </div>

      <div className="overview-section">
        <h2>Demandas aguardando você</h2>
        {pendentes.length === 0 ? (
          <div className="overview-empty ok">Nenhuma demanda esperando você — tudo respondido e aprovado.</div>
        ) : (
          <div className="overview-list">
            {pendentes.map((d) => {
              const n = perguntasPendentes(d.perguntas);
              const tag = n > 0 ? `${n} pergunta${n > 1 ? "s" : ""} pendente${n > 1 ? "s" : ""}` : "aguardando aprovação";
              return (
                <Link
                  key={d.id}
                  className="overview-row"
                  href={`/clients/${d.clientId}?tab=demandas&demand=${d.id}`}
                >
                  <span className="oc-client">{clientNome(d.clientId)}</span>
                  <span className="oc-title">{d.titulo}</span>
                  <span className="badge pendente">{tag}</span>
                </Link>
              );
            })}
          </div>
        )}
      </div>

      <div className="overview-section">
        <h2>Conexões Salesforce pendentes</h2>
        {conexoesPendentes.length === 0 ? (
          <div className="overview-empty ok">Todos os ambientes com conexão configurada.</div>
        ) : (
          <div className="overview-list">
            {conexoesPendentes.map((p) => (
              <Link
                key={`${p.client.id}-${p.tipo}`}
                className="overview-row"
                href={`/clients/${p.client.id}?tab=conexao`}
              >
                <span className="oc-client">{p.client.nome}</span>
                <span className="badge stage mono">{p.tipo}</span>
                <span className="oc-title">{CONN_STATUS_LABEL[p.status] ?? p.status}</span>
              </Link>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
