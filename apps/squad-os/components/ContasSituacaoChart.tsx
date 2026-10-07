"use client";

import { useId } from "react";
import { formatarReaisCompacto } from "@/lib/contas";

/**
 * Valor em R$ por situação da conta — as 4 fatias que os KPIs de cima já
 * contam em texto, lado a lado em magnitude. Hue único (é a mesma métrica,
 * "quanto", em recortes diferentes, não identidades diferentes); "vencidas"
 * sai do hue de magnitude pra cor de status porque ali a pergunta deixa de
 * ser "quanto" e passa a ser "atrasou".
 *
 * Só 4 categorias: rótulo direto em toda barra é a leitura certa aqui, não
 * ruído — a lista "um por mês" que o skill avisa não se aplica a uma
 * comparação categórica deste tamanho.
 */
export function ContasSituacaoChart({
  dados,
}: {
  dados: { rotulo: string; valor: number; alerta?: boolean }[];
}) {
  const uid = useId();
  if (dados.length === 0) return null;

  const max = Math.max(...dados.map((d) => d.valor), 1);
  const topo = max * 1.25;

  const T = 20, B = 34;
  const larg = 420, alt = 170;
  const plotH = alt - T - B;
  const passo = larg / dados.length;
  const barraW = Math.min(64, passo - 20);

  const h = (v: number) => (v / topo) * plotH;

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
          {`Valor em reais por situação: ${dados.map((d) => `${d.rotulo} ${formatarReaisCompacto(d.valor)}`).join(", ")}.`}
        </title>

        <line x1="0" y1={T + plotH} x2={larg} y2={T + plotH} className="eixo" />

        {dados.map((d, i) => {
          const x = i * passo + (passo - barraW) / 2;
          const altura = h(d.valor);
          const y = T + plotH - altura;
          return (
            <g key={d.rotulo}>
              <rect x={x} y={y} width={barraW} height={altura} rx="4" className={d.alerta ? "barra-resultado negativo" : "barra"}>
                <title>{`${d.rotulo}: ${formatarReaisCompacto(d.valor)}`}</title>
              </rect>
              {altura > 0 && (
                <text x={x + barraW / 2} y={y - 6} textAnchor="middle" className="valor">
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

      <table className="sr-only">
        <caption>Valor por situação</caption>
        <thead>
          <tr><th scope="col">Situação</th><th scope="col">Valor</th></tr>
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
