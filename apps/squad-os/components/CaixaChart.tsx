"use client";

import { useId } from "react";
import { formatarReaisCompacto } from "@/lib/contas";

/**
 * Caixa projetado por horizonte (30/60/90 dias) — magnitude, não tempo: o
 * eixo x é "daqui a quantos dias", não um calendário. Hue único (a projeção
 * é só "quanto", não uma série temporal) — vira cor de status só se algum
 * horizonte projeta caixa negativo, porque aí deixa de ser magnitude e passa
 * a ser alerta.
 */
export function CaixaChart({ dados }: { dados: { dias: number; valor: number }[] }) {
  const uid = useId();
  if (dados.length === 0) return null;

  const maxAbs = Math.max(...dados.map((d) => Math.abs(d.valor)), 1);
  const algumNegativo = dados.some((d) => d.valor < 0);
  const topo = algumNegativo ? maxAbs * 1.25 : maxAbs * 1.15;

  const L = 16, R = 16, T = 16, B = 30;
  const larg = 420, alt = 160;
  const plotW = larg - L - R;
  const plotH = alt - T - B;
  const passo = plotW / Math.max(1, dados.length);
  const barraW = Math.min(54, passo - 16);
  const base = algumNegativo ? T + plotH / 2 : T + plotH;

  const y = (v: number) => (algumNegativo ? base - (v / topo) * (plotH / 2) : T + plotH - (v / topo) * plotH);

  return (
    <figure className="chart">
      <svg
        viewBox={`0 0 ${larg} ${alt}`}
        width="100%"
        role="img"
        aria-labelledby={`${uid}-t`}
        preserveAspectRatio="xMidYMid meet"
      >
        <title id={`${uid}-t`}>
          Caixa projetado em {dados.map((d) => `${d.dias} dias`).join(", ")}.
        </title>

        <line x1={L} y1={base} x2={L + plotW} y2={base} className="eixo" />

        {dados.map((d, i) => {
          const x = L + i * passo + (passo - barraW) / 2;
          const positivo = d.valor >= 0;
          const yBarra = positivo ? y(d.valor) : base;
          const h = Math.max(0, Math.abs(y(d.valor) - base));
          return (
            <g key={d.dias}>
              <rect
                x={x}
                y={yBarra}
                width={barraW}
                height={h}
                rx="4"
                className={positivo ? "barra" : "barra-resultado negativo"}
              >
                <title>{`${d.dias} dias: ${formatarReaisCompacto(d.valor)}`}</title>
              </rect>
              {h > 0 && (
                <text
                  x={x + barraW / 2}
                  y={positivo ? yBarra - 5 : yBarra + h + 12}
                  textAnchor="middle"
                  className="valor"
                >
                  {formatarReaisCompacto(d.valor)}
                </text>
              )}
              <text x={x + barraW / 2} y={alt - 10} textAnchor="middle" className="rot-x">
                {d.dias} dias
              </text>
            </g>
          );
        })}
      </svg>

      <table className="sr-only">
        <caption>Caixa projetado por horizonte</caption>
        <thead>
          <tr><th scope="col">Horizonte</th><th scope="col">Caixa projetado</th></tr>
        </thead>
        <tbody>
          {dados.map((d) => (
            <tr key={d.dias}>
              <th scope="row">{d.dias} dias</th>
              <td>{formatarReaisCompacto(d.valor)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {algumNegativo && (
        <figcaption className="chart-nota">
          <span className="pill-prejuizo">negativo</span> horizonte com caixa projetado abaixo de zero.
        </figcaption>
      )}
    </figure>
  );
}
