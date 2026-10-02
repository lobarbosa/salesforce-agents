import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { getClients } from "@/lib/data";
import { execucoesPorDia, listarExecucoes } from "@/lib/execucoes-data";
import { ExecucoesChart } from "@/components/ExecucoesChart";

// Observabilidade de todas as execuções da plataforma (council de
// 2026-10-01): admin via GitHub Actions é "ninguém deveria precisar abrir
// isso" — esta tela é o porquê de existir /api/sync/execucao. Read-only,
// espelho histórico; não decide nada sobre demanda ou cliente.

const RESULTADOS = ["success", "failure", "cancelled"] as const;
const ROTULO_RESULTADO: Record<string, string> = { success: "sucesso", failure: "falhou", cancelled: "cancelada" };
const ORIGENS = ["demanda", "assessment", "planejamento", "conexao"] as const;
const ROTULO_ORIGEM: Record<string, string> = {
  demanda: "demanda",
  assessment: "assessment",
  planejamento: "planejamento",
  conexao: "conexão",
};

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

export default async function ExecucoesPage({
  searchParams,
}: {
  searchParams: Promise<{ cliente?: string; resultado?: string; origem?: string }>;
}) {
  await usuarioDaArea("operacao");
  const sp = await searchParams;

  const clientes = await getClients();
  const clienteFiltro = clientes.find((c) => c.slug === sp.cliente);
  const resultadoFiltro = RESULTADOS.includes(sp.resultado as (typeof RESULTADOS)[number]) ? sp.resultado : undefined;
  const origemFiltro = ORIGENS.includes(sp.origem as (typeof ORIGENS)[number]) ? sp.origem : undefined;

  const [execucoes, porDia] = await Promise.all([
    listarExecucoes({
      clientId: clienteFiltro?.id,
      resultado: resultadoFiltro,
      origem: origemFiltro,
    }),
    execucoesPorDia({ clientId: clienteFiltro?.id, origem: origemFiltro }),
  ]);

  const link = (p: { cliente?: string | null; resultado?: string | null; origem?: string | null }) => {
    const q = new URLSearchParams();
    const cliente = p.cliente === undefined ? sp.cliente : p.cliente;
    const resultado = p.resultado === undefined ? sp.resultado : p.resultado;
    const origem = p.origem === undefined ? sp.origem : p.origem;
    if (cliente) q.set("cliente", cliente);
    if (resultado) q.set("resultado", resultado);
    if (origem) q.set("origem", origem);
    const qs = q.toString();
    return `/operacao/execucoes${qs ? `?${qs}` : ""}`;
  };

  return (
    <>
      <div className="overview-header">
        <h1>Execuções da plataforma</h1>
        <p>Toda execução que reportou resultado — demanda, assessment, planejamento, teste de conexão. Mais recente primeiro.</p>
      </div>

      <nav className="tabs" aria-label="Resultado">
        <Link href={link({ resultado: null })} className={`tab-btn${!resultadoFiltro ? " active" : ""}`} aria-current={!resultadoFiltro ? "page" : undefined}>
          Todas
        </Link>
        {RESULTADOS.map((r) => (
          <Link key={r} href={link({ resultado: r })} className={`tab-btn${resultadoFiltro === r ? " active" : ""}`} aria-current={resultadoFiltro === r ? "page" : undefined}>
            {ROTULO_RESULTADO[r]}
          </Link>
        ))}
      </nav>

      <div className="chips" role="group" aria-label="Filtrar por origem">
        <Link href={link({ origem: null })} className={`chip${!origemFiltro ? " ativo" : ""}`} aria-current={!origemFiltro ? "true" : undefined}>
          Toda origem
        </Link>
        {ORIGENS.map((o) => (
          <Link key={o} href={link({ origem: o })} className={`chip${origemFiltro === o ? " ativo" : ""}`} aria-current={origemFiltro === o ? "true" : undefined}>
            {ROTULO_ORIGEM[o]}
          </Link>
        ))}
      </div>

      <div className="chips" role="group" aria-label="Filtrar por cliente">
        <Link href={link({ cliente: null })} className={`chip${!clienteFiltro ? " ativo" : ""}`} aria-current={!clienteFiltro ? "true" : undefined}>
          Todo cliente
        </Link>
        {clientes.map((c) => (
          <Link key={c.id} href={link({ cliente: c.slug })} className={`chip${clienteFiltro?.id === c.id ? " ativo" : ""}`} aria-current={clienteFiltro?.id === c.id ? "true" : undefined}>
            {c.nome}
          </Link>
        ))}
      </div>

      <ExecucoesChart dados={porDia} />

      {execucoes.length === 0 ? (
        <div className="overview-empty">Nenhuma execução neste recorte ainda.</div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Execuções da plataforma</caption>
            <thead>
              <tr>
                <th scope="col">Quando</th>
                <th scope="col">Cliente</th>
                <th scope="col">Origem</th>
                <th scope="col">Etapa</th>
                <th scope="col">Resultado</th>
                <th scope="col">
                  <span className="sr-only">Log do run</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {execucoes.map((e) => (
                <tr key={e.id}>
                  <td className="data">{quando(e.concluidoEm)}</td>
                  <td>
                    {e.clientNome}
                    {e.demandaCode && <span className="sub mono">{e.demandaCode}</span>}
                  </td>
                  <td>{ROTULO_ORIGEM[e.origem] ?? e.origem}</td>
                  <td className="mono-cel">
                    {e.etapa}
                    {e.motivo && <span className="sub">{e.motivo}</span>}
                  </td>
                  <td>
                    <span className={`badge-status run-${e.resultado === "success" ? "ok" : e.resultado === "cancelled" ? "pulado" : "erro"}`}>
                      {ROTULO_RESULTADO[e.resultado] ?? e.resultado}
                    </span>
                  </td>
                  <td>{e.runUrl && <a href={e.runUrl} target="_blank" rel="noopener noreferrer">ver o run</a>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
