"use client";

import { useId } from "react";
import type { MesDeHoras } from "@/lib/contrato";

const MESES = ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"];

function rotuloMes(chave: string): string {
  const [, mes] = chave.split("-").map(Number);
  return MESES[mes - 1] ?? chave;
}

/**
 * Horas gastas por mês contra as contratadas.
 *
 * **Uma série, não duas.** "Contratadas" é um limite constante, não uma
 * medida que varia — desenhá-la como segunda barra faria o leitor comparar
 * duas coisas de naturezas diferentes e encheria o gráfico de barras que
 * dizem sempre o mesmo número. Como linha de referência, a pergunta que
 * importa ("estourou?") se responde de relance.
 *
 * Mês que passa do limite muda de cor **e** ganha a palavra "excedeu": cor de
 * status nunca carrega o significado sozinha.
 */
export function HorasChart({ dados }: { dados: MesDeHoras[] }) {
  const uid = useId();
  const contratadas = dados[0]?.horasContratadas ?? 0;
  const maxGasto = Math.max(...dados.map((d) => d.horasGastas), 0);
  // O topo acomoda o maior valor E a linha de limite, senão a linha sai do
  // desenho justamente quando o mês estoura — que é quando ela importa.
  const topo = Math.max(maxGasto, contratadas) * 1.15 || 1;

  const L = 44, R = 16, T = 16, B = 30;
  const larg = 420, alt = 190;
  const plotW = larg - L - R;
  const plotH = alt - T - B;
  const passo = plotW / Math.max(1, dados.length);
  const barraW = Math.min(38, passo - 10);

  const y = (v: number) => T + plotH - (v / topo) * plotH;
  const yLimite = y(contratadas);

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
          Horas gastas por mês nos últimos {dados.length} meses, contra {contratadas} horas
          contratadas por ciclo.
        </title>

        {/* Grade recessiva: só o zero e o limite. Mais linhas competiriam com as barras. */}
        <line x1={L} y1={T + plotH} x2={L + plotW} y2={T + plotH} className="eixo" />

        {contratadas > 0 && (
          <>
            <line x1={L} y1={yLimite} x2={L + plotW} y2={yLimite} className="limite" />
            <text x={L + plotW} y={yLimite - 5} textAnchor="end" className="rot-limite">
              contratado · {contratadas}h
            </text>
          </>
        )}

        {dados.map((d, i) => {
          const x = L + i * passo + (passo - barraW) / 2;
          const topoBarra = y(d.horasGastas);
          const h = Math.max(0, T + plotH - topoBarra);
          const excedeu = contratadas > 0 && d.horasGastas > contratadas;
          const ultimo = i === dados.length - 1;
          return (
            <g key={d.mes}>
              <rect
                x={x}
                y={topoBarra}
                width={barraW}
                height={h}
                rx="4"
                className={excedeu ? "barra excedeu" : "barra"}
              >
                <title>{`${rotuloMes(d.mes)}: ${d.horasGastas}h de ${contratadas}h`}</title>
              </rect>
              {/* Rótulo só onde diz algo: no mês corrente e nos que estouraram.
                  Número em toda barra vira ruído e deixa de ser lido. */}
              {(excedeu || ultimo) && h > 0 && (
                <text x={x + barraW / 2} y={topoBarra - 5} textAnchor="middle" className="valor">
                  {d.horasGastas}h
                </text>
              )}
              <text x={x + barraW / 2} y={alt - 10} textAnchor="middle" className="rot-x">
                {rotuloMes(d.mes)}
              </text>
            </g>
          );
        })}
      </svg>

      {/* A mesma informação em texto, pra leitor de tela e pra quem precisa do
          número exato — o gráfico responde "estourou?", a tabela responde
          "quanto?". */}
      <table className="sr-only">
        <caption>Horas por mês</caption>
        <thead>
          <tr><th scope="col">Mês</th><th scope="col">Gastas</th><th scope="col">Contratadas</th></tr>
        </thead>
        <tbody>
          {dados.map((d) => (
            <tr key={d.mes}>
              <th scope="row">{d.mes}</th>
              <td>{d.horasGastas}h</td>
              <td>{d.horasContratadas}h</td>
            </tr>
          ))}
        </tbody>
      </table>

      {dados.some((d) => contratadas > 0 && d.horasGastas > contratadas) && (
        <figcaption className="chart-nota">
          <span className="pill-excedeu">excedeu</span> mês acima das horas contratadas.
        </figcaption>
      )}
    </figure>
  );
}
