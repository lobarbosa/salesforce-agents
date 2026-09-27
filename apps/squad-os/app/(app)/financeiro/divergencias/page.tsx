import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { listarDivergencias, STATUS_DIVERGENCIA, type Divergencia, type StatusDivergencia } from "@/lib/ops";
import { ROTULO_ORIGEM, rotuloOrigem, rotuloTipoDivergencia } from "@/lib/divergencias";
import { formatarReais } from "@/lib/contas";
import { AcaoDivergencia } from "@/components/AcaoDivergencia";

// Divergências que os agentes encontraram (Asaas × NFS-e, assinaturas ×
// cobranças, contabilidade × gerencial). Filtros no link, para o alerta do
// Slack e o painel abrirem direto no recorte certo.

function dataBr(iso: string) {
  return `${iso.slice(8, 10)}/${iso.slice(5, 7)}/${iso.slice(0, 4)}`;
}

function texto(d: Divergencia): string {
  const t = d.detalhe.texto;
  return typeof t === "string" && t ? t : `${rotuloTipoDivergencia(d.tipo)} (${d.refExterna})`;
}

function nota(d: Divergencia): string | null {
  const n = d.detalhe.nota_humana;
  return typeof n === "string" && n ? n : null;
}

export default async function DivergenciasPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; origem?: string }>;
}) {
  await usuarioDaArea("financeiro");
  const sp = await searchParams;
  const todas = sp.status === "todas";
  const status: StatusDivergencia | undefined = todas
    ? undefined
    : STATUS_DIVERGENCIA.includes(sp.status as StatusDivergencia)
      ? (sp.status as StatusDivergencia)
      : "aberta";
  const origem = sp.origem && /^[a-z_]+$/.test(sp.origem) ? sp.origem : undefined;
  const lista = await listarDivergencias({ status, origem });

  const link = (p: { status?: string; origem?: string | null }) => {
    const q = new URLSearchParams();
    const s = p.status ?? (todas ? "todas" : status);
    if (s && s !== "aberta") q.set("status", s);
    const o = p.origem === undefined ? origem : p.origem;
    if (o) q.set("origem", o);
    const qs = q.toString();
    return `/financeiro/divergencias${qs ? `?${qs}` : ""}`;
  };
  const statusAtual = todas ? "todas" : status;

  return (
    <>
      <div className="overview-header">
        <h1>Divergências</h1>
        <p>O que os agentes cruzaram e não bateu. Resolva na origem (Asaas, contabilidade) e marque aqui; ignorar pede o motivo.</p>
      </div>

      <nav className="tabs" aria-label="Situação">
        {[...STATUS_DIVERGENCIA, "todas" as const].map((s) => (
          <Link key={s} href={link({ status: s })} className={`tab-btn${s === statusAtual ? " active" : ""}`} aria-current={s === statusAtual ? "page" : undefined}>
            {s === "todas" ? "Todas" : s === "aberta" ? "Abertas" : s === "resolvida" ? "Resolvidas" : "Ignoradas"}
          </Link>
        ))}
      </nav>

      <div className="chips" role="group" aria-label="Filtrar por origem">
        <Link href={link({ origem: null })} className={`chip${!origem ? " ativo" : ""}`} aria-current={!origem ? "true" : undefined}>
          Todas as origens
        </Link>
        {Object.keys(ROTULO_ORIGEM).map((o) => (
          <Link key={o} href={link({ origem: o })} className={`chip${origem === o ? " ativo" : ""}`} aria-current={origem === o ? "true" : undefined}>
            {rotuloOrigem(o)}
          </Link>
        ))}
      </div>

      {lista === null ? (
        <div className="overview-empty">As divergências aparecem aqui quando o banco dos agentes estiver ligado a este Squad OS.</div>
      ) : lista.length === 0 ? (
        <div className={`overview-empty${statusAtual === "aberta" ? " ok" : ""}`}>
          {statusAtual === "aberta" ? "Nenhuma divergência aberta neste recorte." : "Nada neste recorte."}
        </div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Divergências</caption>
            <thead>
              <tr>
                <th scope="col">O que não bateu</th>
                <th scope="col">Origem</th>
                <th scope="col">Competência</th>
                <th scope="col" className="num">Esperado</th>
                <th scope="col" className="num">Encontrado</th>
                <th scope="col">Situação</th>
                <th scope="col">
                  <span className="sr-only">Ação</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {lista.map((d) => (
                <tr key={d.id}>
                  <th scope="row" className="texto-div">
                    {texto(d)}
                    <span className="sub">
                      desde {dataBr(d.criadaEm)}
                      {typeof d.detalhe.task_url === "string" && /^https?:\/\//.test(d.detalhe.task_url) ? (
                        <>
                          {" · "}
                          <a href={String(d.detalhe.task_url)}>ver origem</a>
                        </>
                      ) : null}
                    </span>
                  </th>
                  <td>{rotuloOrigem(d.origem)}</td>
                  <td className="data">{d.competencia ? `${d.competencia.slice(5, 7)}/${d.competencia.slice(0, 4)}` : "—"}</td>
                  <td className="num">{d.esperado === null ? "—" : formatarReais(d.esperado)}</td>
                  <td className="num">{d.encontrado === null ? "—" : formatarReais(d.encontrado)}</td>
                  <td>
                    <span className={`badge-status div-${d.status}`}>{d.status}</span>
                    {d.resolvidoPor && <span className="sub">por {d.resolvidoPor}</span>}
                    {d.status !== "aberta" && nota(d) && <span className="sub">“{nota(d)}”</span>}
                  </td>
                  <td className="acoes-linha">
                    <AcaoDivergencia id={d.id} status={d.status} resumo={texto(d)} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
