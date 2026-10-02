"use client";

import { useId } from "react";
import { formatarReaisCompacto } from "@/lib/contas";

/**
 * Resultado contábil × gerencial, lado a lado — a pergunta da conciliação é
 * literalmente "essas duas batem?", e duas barras da mesma altura respondem
 * isso mais rápido que dois cartões de KPI em cantos diferentes da tela.
 *
 * Duas fontes nomeadas, não duas pontas de uma métrica só: por isso é hue
 * categórico fixo (contábil sempre --accent, gerencial sempre --accent2),
 * não divergente por sinal como o ResultadoChart — aqui "negativo" é só
 * "deu prejuízo", não um segundo eixo semântico.
 */
export function ConciliacaoChart({
  contabil,
  gerencial,
}: {
  contabil: number | null;
  gerencial: number | null;
}) {
  const uid = useId();
  if (contabil === null || gerencial === null) return null;

  const dados = [
    { rotulo: "contábil", valor: contabil, classe: "barra-contabil" },
    { rotulo: "gerencial", valor: gerencial, classe: "barra-gerencial" },
  ];
  const maxAbs = Math.max(...dados.map((d) => Math.abs(d.valor)), 1);
  const algumNegativo = dados.some((d) => d.valor < 0);
  const topo = maxAbs * 1.25;

  const larg = 420, alt = 160;
  const T = 16, B = 30;
  const plotH = alt - T - B;
  const passo = larg / dados.length;
  const barraW = Math.min(72, passo - 24);
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
          Resultado contábil {formatarReaisCompacto(contabil)} contra resultado gerencial {formatarReaisCompacto(gerencial)}.
        </title>

        <line x1="0" y1={base} x2={larg} y2={base} className="eixo" />

        {dados.map((d, i) => {
          const x = i * passo + (passo - barraW) / 2;
          const positivo = d.valor >= 0;
          const yBarra = positivo ? y(d.valor) : base;
          const h = Math.max(0, Math.abs(y(d.valor) - base));
          return (
            <g key={d.rotulo}>
              <rect x={x} y={yBarra} width={barraW} height={h} rx="4" className={d.classe}>
                <title>{`${d.rotulo}: ${formatarReaisCompacto(d.valor)}`}</title>
              </rect>
              {h > 0 && (
                <text
                  x={x + barraW / 2}
                  y={positivo ? yBarra - 6 : yBarra + h + 13}
                  textAnchor="middle"
                  className="valor"
                >
                  {formatarReaisCompacto(d.valor)}
                </text>
              )}
              <text x={x + barraW / 2} y={alt - 10} textAnchor="middle" className="rot-x">
                {d.rotulo}
              </text>
            </g>
          );
        })}
      </svg>

      <div className="chart-legenda" aria-hidden="true">
        <span><span className="ponto contabil" /> contábil</span>
        <span><span className="ponto gerencial" /> gerencial</span>
      </div>

      <table className="sr-only">
        <caption>Resultado contábil × gerencial</caption>
        <thead>
          <tr><th scope="col">Fonte</th><th scope="col">Resultado</th></tr>
        </thead>
        <tbody>
          {dados.map((d) => (
            <tr key={d.rotulo}>
              <th scope="row">{d.rotulo}</th>
              <td>{formatarReaisCompacto(d.valor)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
