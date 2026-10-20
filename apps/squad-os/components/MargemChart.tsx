"use client";

import { useId, useState } from "react";
import { formatarReaisCompacto } from "@/lib/contas";
import { formatarPct, rotuloMesCurto, type MargemContrato } from "@/lib/margem";

/**
 * Receita × custo direto × margem por mês, um contrato por vez (seletor).
 * Receita no acento e custo em neutro (fontes nomeadas, cor fixa); a margem é
 * divergente por sinal, como o ResultadoChart — o vermelho fica só para ela.
 * Mês sem receita ou sem custo não desenha a barra que falta nem a margem:
 * a tabela abaixo diz o motivo.
 */
export function MargemChart({ contratos }: { contratos: MargemContrato[] }) {
  const uid = useId();
  const inicial = contratos.find((c) => c.ultima)?.clientId ?? contratos[0]?.clientId ?? "";
  const [clientId, setClientId] = useState(inicial);
  const contrato = contratos.find((c) => c.clientId === clientId) ?? contratos[0];
  if (!contrato) return null;

  const meses = contrato.linhas;
  const temReceita = (s: string) => !/nota/.test(s);
  const temCusto = (s: string) => s !== "sem custo direto lançado";
  const valores = meses.flatMap((m) => [
    temReceita(m.situacao) ? m.receita : 0,
    temCusto(m.situacao) ? m.custoDireto : 0,
    m.margem ?? 0,
  ]);
  const max = Math.max(...valores, 1);
  const min = Math.min(...valores, 0);
  const topo = max * 1.2;
  const fundo = min < 0 ? min * 1.4 : 0;

  const L = 8, R = 8, T = 18, B = 30;
  const larg = 520, alt = 220;
  const plotW = larg - L - R;
  const plotH = alt - T - B;
  const passo = plotW / Math.max(1, meses.length);
  const barraW = Math.min(26, (passo - 14) / 3);
  const y = (v: number) => T + ((topo - v) / (topo - fundo)) * plotH;
  const zero = y(0);

  return (
    <figure className="chart">
      <label className="chart-seletor">
        <span>Contrato</span>
        <select value={contrato.clientId} onChange={(e) => setClientId(e.target.value)}>
          {contratos.map((c) => (
            <option key={c.clientId} value={c.clientId}>
              {c.cliente}
            </option>
          ))}
        </select>
      </label>
      <svg
        viewBox={`0 0 ${larg} ${alt}`}
        width="100%"
        role="img"
        aria-labelledby={`${uid}-t`}
        preserveAspectRatio="xMidYMid meet"
      >
        <title id={`${uid}-t`}>{`Receita, custo direto e margem por mês de ${contrato.cliente}.`}</title>
        <line x1={L} y1={zero} x2={L + plotW} y2={zero} className="eixo" />
        {meses.map((m, i) => {
          const x0 = L + i * passo + (passo - barraW * 3 - 4) / 2;
          const barras = [
            { v: temReceita(m.situacao) ? m.receita : null, classe: "barra-receita", nome: "receita" },
            { v: temCusto(m.situacao) ? m.custoDireto : null, classe: "barra-custo", nome: "custo direto" },
            {
              v: m.margem,
              classe: `barra-resultado ${m.margem !== null && m.margem < 0 ? "negativo" : "positivo"}`,
              nome: "margem",
            },
          ];
          return (
            <g key={m.mes}>
              {barras.map((b, j) => {
                if (b.v === null) return null;
                const yb = b.v >= 0 ? y(b.v) : zero;
                const h = Math.max(0, Math.abs(y(b.v) - zero));
                const x = x0 + j * (barraW + 2);
                return (
                  <rect key={b.nome} x={x} y={yb} width={barraW} height={h} rx="3" className={b.classe}>
                    <title>{`${rotuloMesCurto(m.mes)} · ${b.nome}: ${formatarReaisCompacto(b.v)}`}</title>
                  </rect>
                );
              })}
              {m.margem !== null && (
                <text
                  x={x0 + 2 * (barraW + 2) + barraW / 2}
                  y={m.margem >= 0 ? y(m.margem) - 5 : zero + Math.abs(y(m.margem) - zero) + 12}
                  textAnchor="middle"
                  className="valor"
                >
                  {formatarPct(m.margemPct)}
                </text>
              )}
              <text x={L + i * passo + passo / 2} y={alt - 10} textAnchor="middle" className="rot-x">
                {rotuloMesCurto(m.mes)}
              </text>
            </g>
          );
        })}
      </svg>

      <div className="chart-legenda" aria-hidden="true">
        <span><span className="ponto receita" /> receita</span>
        <span><span className="ponto custo" /> custo direto</span>
        <span><span className="ponto margem" /> margem</span>
      </div>

      <table className="sr-only">
        <caption>{`Margem por mês de ${contrato.cliente}`}</caption>
        <thead>
          <tr>
            <th scope="col">Mês</th>
            <th scope="col">Receita</th>
            <th scope="col">Custo direto</th>
            <th scope="col">Margem</th>
          </tr>
        </thead>
        <tbody>
          {meses.map((m) => (
            <tr key={m.mes}>
              <th scope="row">{m.mes}</th>
              <td>{temReceita(m.situacao) ? formatarReaisCompacto(m.receita) : m.situacao}</td>
              <td>{temCusto(m.situacao) ? formatarReaisCompacto(m.custoDireto) : m.situacao}</td>
              <td>{m.margem === null ? "—" : `${formatarReaisCompacto(m.margem)} (${formatarPct(m.margemPct)})`}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
