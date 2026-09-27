import Link from "next/link";
import { getClients, getAllDemandas } from "@/lib/data";
import { perguntasPendentes, asAprovacao } from "@/lib/demandas";
import { getCurrentUsuario } from "@/lib/current-user";
import { podeVer } from "@/lib/permissoes";
import { minutosDaSemana } from "@/lib/horas-data";
import { chaveDia, duracaoPorExtenso, formatarDuracao, inicioDaSemana } from "@/lib/horas";
import { listarContas } from "@/lib/contas-data";
import { bloqueio } from "@/lib/contas";
import { contarDivergenciasAbertas, saudeDosAgentes } from "@/lib/ops";

const CONN_STATUS_LABEL: Record<string, string> = {
  nao_configurado: "Não configurado",
  aguardando_teste: "Teste de conexão solicitado",
  conectado: "Conectado",
  erro: "Erro na última tentativa",
};

export default async function OverviewPage() {
  const usuario = await getCurrentUsuario();
  const hoje = chaveDia(new Date());
  const admin = usuario ? podeVer(usuario.role, "financeiro") && podeVer(usuario.role, "operacao") : false;
  const [clients, demandas, minutos, contas, divergencias, agentes] = await Promise.all([
    getClients(),
    getAllDemandas(),
    usuario ? minutosDaSemana(usuario.email, inicioDaSemana(hoje)) : Promise.resolve(0),
    admin ? listarContas() : Promise.resolve([]),
    admin ? contarDivergenciasAbertas() : Promise.resolve(null),
    admin ? saudeDosAgentes() : Promise.resolve(null),
  ]);
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

  // Admin: o que dos módulos novos precisa dele, no mesmo formato das demandas.
  const operacionais: { href: string; titulo: string; tag: string }[] = [];
  if (usuario && admin) {
    const quem = { role: usuario.role, email: usuario.email };
    const decidir = contas.filter((c) => c.status === "aguardando_aprovacao" && bloqueio("aprovar", c, quem) === null);
    if (decidir.length)
      operacionais.push({ href: "/financeiro/aprovacoes", tag: "financeiro", titulo: `${decidir.length} conta${decidir.length > 1 ? "s" : ""} a pagar esperando sua aprovação` });
    const abertas = (divergencias ?? []).reduce((n, d) => n + d.total, 0);
    if (abertas)
      operacionais.push({ href: "/financeiro/divergencias", tag: "financeiro", titulo: `${abertas} divergência${abertas > 1 ? "s" : ""} aberta${abertas > 1 ? "s" : ""}` });
    const falhas = (agentes ?? []).filter((a) => a.ultimoStatus === "erro");
    if (falhas.length)
      operacionais.push({ href: "/operacao/agentes", tag: "operação", titulo: `${falhas.length} agente${falhas.length > 1 ? "s" : ""} com a última execução em falha` });
  }

  return (
    <>
      <div className="overview-header">
        <h1>Visão Geral</h1>
        <p>O que precisa da sua atenção entre os {clients.length} clientes ativos.</p>
      </div>

      {usuario && (
        <div className="overview-section">
          <h2>Suas horas nesta semana</h2>
          <Link className="overview-row" href="/horas">
            <span className="oc-client num">{formatarDuracao(minutos) || "0:00"}</span>
            <span className="oc-title">
              {minutos ? `${duracaoPorExtenso(minutos)} lançadas desde segunda` : "Nenhuma hora lançada desde segunda"}
            </span>
            <span className="badge stage">{minutos ? "abrir timesheet" : "lançar horas"}</span>
          </Link>
        </div>
      )}

      {admin && (
        <div className="overview-section">
          <h2>Financeiro e operação</h2>
          {operacionais.length === 0 ? (
            <div className="overview-empty ok">Nenhuma aprovação, divergência ou falha de agente esperando você.</div>
          ) : (
            <div className="overview-list">
              {operacionais.map((o) => (
                <Link key={o.href} className="overview-row" href={o.href}>
                  <span className="oc-client">{o.tag}</span>
                  <span className="oc-title">{o.titulo}</span>
                  <span aria-hidden="true">→</span>
                </Link>
              ))}
            </div>
          )}
        </div>
      )}

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
