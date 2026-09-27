import Link from "next/link";
import { usuarioDaArea } from "@/lib/area";
import { horasPorCliente } from "@/lib/horas-data";
import { chaveDia, ehChaveMes, formatarDuracao, type SituacaoConsumo } from "@/lib/horas";

// Horas por cliente: consumido × contratado (padrão do relatório Summary do
// Clockify). Lê os mesmos lançamentos de "Minhas horas" e do card.
const ROTULO: Record<SituacaoConsumo, string> = {
  estourado: "estourado",
  atencao: "atenção (80%+)",
  dentro: "dentro do contratado",
  sem_teto: "sem teto de horas",
};

function mesVizinho(mes: string, delta: number) {
  const [a, m] = mes.split("-").map(Number);
  const d = new Date(Date.UTC(a, m - 1 + delta, 1));
  return d.toISOString().slice(0, 7);
}

const horas = (min: number) => formatarDuracao(min) || "0:00";

export default async function HorasPorClientePage({
  searchParams,
}: {
  searchParams: Promise<{ mes?: string }>;
}) {
  await usuarioDaArea("financeiro");
  const atual = chaveDia(new Date()).slice(0, 7);
  const pedido = (await searchParams).mes ?? "";
  const mes = ehChaveMes(pedido) && pedido <= atual ? pedido : atual;
  const linhas = await horasPorCliente(mes);

  const total = linhas.reduce((s, l) => s + l.minutos, 0);
  const atencao = linhas.filter((l) => l.situacao === "atencao" || l.situacao === "estourado");
  const rotuloMes = `${mes.slice(5)}/${mes.slice(0, 4)}`;

  return (
    <>
      <div className="overview-header">
        <h1>Horas por cliente</h1>
        <p>
          Consumido × contratado em {rotuloMes}. Contratos AMS contam o ciclo inteiro (mensal ou trimestral);
          projeto e cliente sem contrato mostram as horas do mês.
        </p>
      </div>

      <nav className="semana-nav" aria-label="Navegar entre meses">
        <Link className="btn-ghost" href={`/financeiro/horas?mes=${mesVizinho(mes, -1)}`}>
          ← Mês anterior
        </Link>
        {mes !== atual && (
          <Link className="btn-ghost" href="/financeiro/horas">
            Este mês
          </Link>
        )}
        {mes < atual ? (
          <Link className="btn-ghost" href={`/financeiro/horas?mes=${mesVizinho(mes, 1)}`}>
            Próximo mês →
          </Link>
        ) : (
          <span className="btn-ghost desabilitado" aria-disabled="true">
            Próximo mês →
          </span>
        )}
      </nav>

      <div className="kpis">
        <div className="kpi">
          <span className="kpi-rotulo">Horas lançadas em {rotuloMes}</span>
          <span className="kpi-valor num">{horas(total)}</span>
        </div>
        <div className={`kpi${atencao.length ? " kpi-alerta" : ""}`}>
          <span className="kpi-rotulo">Contratos AMS em atenção ou estourados</span>
          <span className="kpi-valor num">{atencao.length}</span>
          <span className="kpi-nota">{atencao.length ? atencao.map((l) => l.clientNome).join(", ") : "nenhum"}</span>
        </div>
      </div>

      {linhas.length === 0 ? (
        <div className="overview-empty ok">Nenhum cliente cadastrado ainda.</div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Consumo de horas por cliente em {rotuloMes}</caption>
            <thead>
              <tr>
                <th scope="col">Cliente</th>
                <th scope="col">Contrato</th>
                <th scope="col" className="num">Consumido</th>
                <th scope="col" className="num">Contratado</th>
                <th scope="col">Consumo</th>
              </tr>
            </thead>
            <tbody>
              {linhas.map((l) => {
                const pct = l.horasContratadas ? Math.round((l.minutos / 60 / l.horasContratadas) * 100) : null;
                return (
                  <tr key={l.clientId} className={`sit-${l.situacao}`}>
                    <th scope="row">
                      <details className="detalhe-linha">
                        <summary>{l.clientNome}</summary>
                        {l.minutos === 0 ? (
                          <p className="save-note">Sem horas neste período.</p>
                        ) : (
                          <div className="detalhe-grade">
                            <div>
                              <h3>Por pessoa</h3>
                              <ul>
                                {l.porPessoa.map((p) => (
                                  <li key={p.autor}>
                                    <span>{p.autor}</span> <span className="num">{horas(p.minutos)}</span>
                                  </li>
                                ))}
                              </ul>
                            </div>
                            <div>
                              <h3>Por demanda</h3>
                              <ul>
                                {l.porDemanda.map((d) => (
                                  <li key={d.code}>
                                    <span>
                                      <span className="mono">{d.code}</span> {d.titulo}
                                    </span>{" "}
                                    <span className="num">{horas(d.minutos)}</span>
                                  </li>
                                ))}
                              </ul>
                            </div>
                          </div>
                        )}
                      </details>
                    </th>
                    <td>
                      {l.tipo === "ams" ? `AMS · ${l.rotuloCiclo}` : l.tipo === "projeto" ? "Projeto" : "sem contrato"}
                    </td>
                    <td className="num">{horas(l.minutos)}</td>
                    <td className="num">{l.horasContratadas ? `${l.horasContratadas}:00` : "—"}</td>
                    <td>
                      {pct !== null && (
                        <span className="barra-consumo" aria-hidden="true">
                          <span style={{ width: `${Math.min(pct, 100)}%` }} />
                        </span>
                      )}
                      <span className={`sit-rotulo sit-${l.situacao}`}>
                        {pct !== null ? `${pct}% · ` : ""}
                        {ROTULO[l.situacao]}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
