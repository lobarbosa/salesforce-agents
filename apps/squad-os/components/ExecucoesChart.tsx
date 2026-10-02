"use client";

import { useId } from "react";
import type { DiaExecucoes } from "@/lib/execucoes-data";

function rotuloDia(iso: string): string {
  return `${iso.slice(8, 10)}/${iso.slice(5, 7)}`;
}

/**
 * Execuções por dia, empilhadas por resultado — a tendência que a tabela
 * de baixo não mostra sozinha (ela é a lista, isso é "está piorando?").
 * Três fatias de status, não três séries categóricas: por isso usa a
 * paleta de status e não hues de identidade, e por isso tem legenda mesmo
 * com poucas fatias — status nunca é só cor.
 */
export function ExecucoesChart({ dados }: { dados: DiaExecucoes[] }) {
  const uid = useId();
  if (dados.length === 0) return null;

  const totais = dados.map((d) => d.success + d.failure + d.cancelled);
  const max = Math.max(...totais, 1);
  const temDado = totais.some((t) => t > 0);
  if (!temDado) return null;

  const L = 28, R = 16, T = 16, B = 26;
  const larg = 420, alt = 170;
  const plotW = larg - L - R;
  const plotH = alt - T - B;
  const passo = plotW / dados.length;
  const barraW = Math.min(22, passo - 6);

  const alturaDe = (v: number) => (v / max) * plotH;

  // Rótulo de eixo x só em alguns pontos — um por dia em 14 dias vira ruído.
  const mostrarRotulo = (i: number) => i === 0 || i === dados.length - 1 || i % 3 === 0;

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
          Execuções por dia nos últimos {dados.length} dias, sucesso, falha e cancelada.
        </title>

        <line x1={L} y1={T + plotH} x2={L + plotW} y2={T + plotH} className="eixo" />

        {dados.map((d, i) => {
          const x = L + i * passo + (passo - barraW) / 2;
          const hSucesso = alturaDe(d.success);
          const hFalha = alturaDe(d.failure);
          const hCancelada = alturaDe(d.cancelled);
          const yBase = T + plotH;
          const ySucesso = yBase - hSucesso;
          const yFalha = ySucesso - hFalha;
          const yCancelada = yFalha - hCancelada;
          return (
            <g key={d.dia}>
              {d.success > 0 && (
                <rect x={x} y={ySucesso} width={barraW} height={hSucesso} className="seg-ok">
                  <title>{`${rotuloDia(d.dia)}: ${d.success} com sucesso`}</title>
                </rect>
              )}
              {d.failure > 0 && (
                <rect x={x} y={yFalha} width={barraW} height={hFalha} className="seg-erro">
                  <title>{`${rotuloDia(d.dia)}: ${d.failure} com falha`}</title>
                </rect>
              )}
              {d.cancelled > 0 && (
                <rect x={x} y={yCancelada} width={barraW} height={hCancelada} className="seg-pulado">
                  <title>{`${rotuloDia(d.dia)}: ${d.cancelled} cancelada`}</title>
                </rect>
              )}
              {mostrarRotulo(i) && (
                <text x={x + barraW / 2} y={alt - 8} textAnchor="middle" className="rot-x">
                  {rotuloDia(d.dia)}
                </text>
              )}
            </g>
          );
        })}
      </svg>

      <div className="chart-legenda" aria-hidden="true">
        <span><span className="ponto ok" /> sucesso</span>
        <span><span className="ponto erro" /> falha</span>
        <span><span className="ponto cancelada" /> cancelada</span>
      </div>

      <table className="sr-only">
        <caption>Execuções por dia</caption>
        <thead>
          <tr><th scope="col">Dia</th><th scope="col">Sucesso</th><th scope="col">Falha</th><th scope="col">Cancelada</th></tr>
        </thead>
        <tbody>
          {dados.map((d) => (
            <tr key={d.dia}>
              <th scope="row">{d.dia}</th>
              <td>{d.success}</td>
              <td>{d.failure}</td>
              <td>{d.cancelled}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
