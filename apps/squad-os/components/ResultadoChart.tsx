"use client";

import { useId } from "react";
import type { ResultadoMes } from "@/lib/ops";

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

function rotuloMes(chave: string): string {
  const [, mes] = chave.split("-").map(Number);
  return MESES[mes - 1] ?? chave;
}

function formatarReaisCompacto(v: number): string {
  const sinal = v < 0 ? "-" : "";
  const abs = Math.abs(v);
  if (abs >= 1000) return `${sinal}R$ ${(abs / 1000).toLocaleString("pt-BR", { maximumFractionDigits: 1 })} mil`;
  return `${sinal}R$ ${abs.toLocaleString("pt-BR", { maximumFractionDigits: 0 })}`;
}

/**
 * Resultado (receita - despesas) por mês fechado, divergente em torno de
 * zero: uma hue pra lucro, outra pra prejuízo, sem meio-termo de cor no
 * próprio zero. Mês positivo e negativo competem pela mesma pergunta
 * ("deu lucro?"), por isso é uma barra só por mês, nunca duas.
 *
 * Rótulo direto só no mês corrente e nos que deram prejuízo — igual ao
 * HorasChart, repetir o valor em toda barra vira ruído.
 */
export function ResultadoChart({ dados }: { dados: ResultadoMes[] }) {
  const uid = useId();
  if (dados.length === 0) return null;

  const maxAbs = Math.max(...dados.map((d) => Math.abs(d.valor)), 1);
  const topo = maxAbs * 1.25;

  const L = 16, R = 16, T = 16, B = 30;
  const larg = 420, alt = 190;
  const plotW = larg - L - R;
  const plotH = alt - T - B;
  const passo = plotW / Math.max(1, dados.length);
  const barraW = Math.min(38, passo - 10);
  const meio = T + plotH / 2;

  const y = (v: number) => meio - (v / topo) * (plotH / 2);

  const algumNegativo = dados.some((d) => d.valor < 0);

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
          Resultado (receita menos despesas) por mês, nos últimos {dados.length} meses fechados.
        </title>

        {/* Zero é o eixo que importa aqui — não "o menor valor" como no HorasChart. */}
        <line x1={L} y1={meio} x2={L + plotW} y2={meio} className="eixo" />

        {dados.map((d, i) => {
          const x = L + i * passo + (passo - barraW) / 2;
          const positivo = d.valor >= 0;
          const yBarra = positivo ? y(d.valor) : meio;
          const h = Math.max(0, Math.abs(y(d.valor) - meio));
          const ultimo = i === dados.length - 1;
          return (
            <g key={d.mes}>
              <rect
                x={x}
                y={yBarra}
                width={barraW}
                height={h}
                rx="4"
                className={positivo ? "barra-resultado positivo" : "barra-resultado negativo"}
              >
                <title>{`${rotuloMes(d.mes)}: ${formatarReaisCompacto(d.valor)}`}</title>
              </rect>
              {(!positivo || ultimo) && h > 0 && (
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
                {rotuloMes(d.mes)}
              </text>
            </g>
          );
        })}
      </svg>

      <table className="sr-only">
        <caption>Resultado por mês</caption>
        <thead>
          <tr><th scope="col">Mês</th><th scope="col">Resultado</th></tr>
        </thead>
        <tbody>
          {dados.map((d) => (
            <tr key={d.mes}>
              <th scope="row">{d.mes}</th>
              <td>{formatarReaisCompacto(d.valor)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {algumNegativo && (
        <figcaption className="chart-nota">
          <span className="pill-prejuizo">prejuízo</span> mês com despesas acima da receita.
        </figcaption>
      )}
    </figure>
  );
}
