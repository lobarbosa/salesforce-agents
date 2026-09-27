import { usuarioDaArea } from "@/lib/area";
import { saudeDosAgentes, ultimosDeploys } from "@/lib/ops";

// Saúde dos agentes (runner da VM) a partir de ops.agent_runs e ops.deploys.
// Só leitura: rodar agente e reiniciar runner continuam na VM (acxya-ops).

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

function ha(iso: string, agora: number) {
  const min = Math.round((agora - Date.parse(iso)) / 60_000);
  if (min < 1) return "agora";
  if (min < 60) return `há ${min} min`;
  const h = Math.round(min / 60);
  if (h < 48) return `há ${h} h`;
  return `há ${Math.round(h / 24)} dias`;
}

const ROTULO = { ok: "ok", erro: "falhou", pulado: "pulado" } as const;
const ROTULO_DEPLOY = { ok: "publicado", rollback: "revertido", abortado: "abortado" } as const;

export default async function SaudeAgentesPage() {
  await usuarioDaArea("operacao");
  const [agentes, deploys] = await Promise.all([saudeDosAgentes(), ultimosDeploys(8)]);
  // eslint-disable-next-line react-hooks/purity -- Server Component: a hora do request é o "agora" da página
  const agora = Date.now();

  if (agentes === null) {
    return (
      <>
        <div className="overview-header">
          <h1>Saúde dos agentes</h1>
        </div>
        <div className="overview-empty">
          As execuções aparecem aqui quando o banco dos agentes estiver ligado a este Squad OS (SUPABASE_URL e
          SUPABASE_SERVICE_KEY no .env da VM).
        </div>
      </>
    );
  }

  const comErro = agentes.filter((a) => a.ultimoStatus === "erro");
  const ultima = agentes.reduce<string | null>((m, a) => (!m || a.ultimaEm > m ? a.ultimaEm : m), null);
  // O db_sync roda a cada 15 min: nada gravado há 1 h = runner parado ou banco inacessível pela VM.
  const runnerParado = !ultima || agora - Date.parse(ultima) > 60 * 60_000;
  const erros24 = agentes.reduce((s, a) => s + a.erros24h, 0);
  const exec24 = agentes.reduce((s, a) => s + a.execucoes24h, 0);

  return (
    <>
      <div className="overview-header">
        <h1>Saúde dos agentes</h1>
        <p>Última execução de cada agente do runner e os deploys recentes.</p>
      </div>

      <div className="kpis">
        <div className={`kpi${runnerParado ? " kpi-alerta" : ""}`}>
          <span className="kpi-rotulo">Runner</span>
          <span className="kpi-valor">{runnerParado ? "sem sinal" : "ativo"}</span>
          <span className="kpi-nota">{ultima ? `última execução ${ha(ultima, agora)}` : "nenhuma execução registrada"}</span>
        </div>
        <div className={`kpi${comErro.length ? " kpi-alerta" : ""}`}>
          <span className="kpi-rotulo">Agentes com a última execução em falha</span>
          <span className="kpi-valor num">{comErro.length}</span>
          <span className="kpi-nota">{comErro.length ? comErro.map((a) => a.agente).join(", ") : "nenhum"}</span>
        </div>
        <div className="kpi">
          <span className="kpi-rotulo">Execuções nas últimas 24 h</span>
          <span className="kpi-valor num">{exec24}</span>
          <span className="kpi-nota">
            {erros24} com falha · {agentes.length} agentes
          </span>
        </div>
      </div>

      <div className="tabela-wrap">
        <table className="tabela">
          <caption className="sr-only">Agentes e última execução</caption>
          <thead>
            <tr>
              <th scope="col">Agente</th>
              <th scope="col">Última execução</th>
              <th scope="col">Situação</th>
              <th scope="col" className="num">24 h</th>
              <th scope="col">Último sucesso</th>
            </tr>
          </thead>
          <tbody>
            {agentes.map((a) => (
              <tr key={a.agente}>
                <th scope="row" className="mono-cel">
                  {a.agente}
                  {a.ultimoErro && <span className="sub erro-agente">{a.ultimoErro.slice(0, 240)}</span>}
                </th>
                <td>
                  {ha(a.ultimaEm, agora)}
                  <span className="sub">{quando(a.ultimaEm)}</span>
                </td>
                <td>
                  <span className={`badge-status run-${a.ultimoStatus}`}>{ROTULO[a.ultimoStatus]}</span>
                </td>
                <td className="num">
                  {a.execucoes24h}
                  {a.erros24h > 0 && <span className="sub">{a.erros24h} com falha</span>}
                </td>
                <td>{a.ultimoOkEm ? ha(a.ultimoOkEm, agora) : "nunca"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2 className="secao-titulo">Deploys recentes</h2>
      {!deploys?.length ? (
        <div className="overview-empty">Nenhum deploy registrado ainda.</div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Deploys recentes</caption>
            <thead>
              <tr>
                <th scope="col">Quando</th>
                <th scope="col">Commit</th>
                <th scope="col">Resultado</th>
                <th scope="col">Detalhe</th>
              </tr>
            </thead>
            <tbody>
              {deploys.map((d) => (
                <tr key={d.commit + d.em}>
                  <td>{quando(d.em)}</td>
                  <td className="data">{d.commit}</td>
                  <td>
                    <span className={`badge-status dep-${d.resultado}`}>{ROTULO_DEPLOY[d.resultado]}</span>
                  </td>
                  <td>{d.detalhe}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
