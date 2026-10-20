"use client";

import { useId } from "react";
import type { SaudeAgente } from "@/lib/ops";

/**
 * Execuções das últimas 24h por agente, ok vs. erro — barra horizontal
 * empilhada. Horizontal porque a identidade (nome do agente) é o que se lê
 * primeiro, e a lista pode crescer além de poucos agentes; rótulo de
 * categoria em texto corrido não cabe embaixo de uma barra vertical.
 *
 * Cor é status real (ok/erro), não série arbitrária — por isso usa a
 * paleta de status (--success/--danger) em vez de hues categóricos, e por
 * isso tem legenda mesmo com só duas fatias: a pergunta "qual fatia é erro?"
 * não pode depender de adivinhar.
 */
export function AgentesChart({ agentes }: { agentes: SaudeAgente[] }) {
  const uid = useId();
  if (agentes.length === 0) return null;

  const ordenados = [...agentes].sort((a, b) => b.execucoes24h - a.execucoes24h);
  const max = Math.max(...ordenados.map((a) => a.execucoes24h), 1);

  // A coluna do nome cresce com o maior nome (mono 10px ≈ 6,2 unidades por
  // caractere): com L fixo em 110, "accounting_reconciliation_agent" saía do
  // gráfico pela esquerda. Até 32 caracteres; além disso corta com "…" e o
  // nome inteiro fica no <title>.
  const MAX_NOME = 32;
  const curto = (n: string) => (n.length > MAX_NOME ? `${n.slice(0, MAX_NOME - 1)}…` : n);
  const L = Math.max(110, 16 + 6.2 * Math.max(...ordenados.map((a) => curto(a.agente).length)));
  const R = 36, T = 8, B = 8;
  const linhaH = 26;
  const larg = L + 310;
  const alt = T + B + ordenados.length * linhaH;
  const plotW = larg - L - R;
  const x = (v: number) => (v / max) * plotW;

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
          {`Execuções nas últimas 24 horas por agente, ok contra erro, ${ordenados.length} agentes.`}
        </title>
        {ordenados.map((a, i) => {
          const y = T + i * linhaH;
          const ok = Math.max(0, a.execucoes24h - a.erros24h);
          const okW = x(ok);
          const erroW = x(a.erros24h);
          return (
            <g key={a.agente}>
              <text x={L - 8} y={y + linhaH / 2 + 4} className="rot-y">
                <title>{a.agente}</title>
                {curto(a.agente)}
              </text>
              {a.execucoes24h === 0 ? (
                <text x={L} y={y + linhaH / 2 + 4} className="rot-limite">
                  sem execução
                </text>
              ) : (
                <>
                  <rect x={L} y={y + 4} width={okW} height={linhaH - 12} rx="3" className="seg-ok">
                    <title>{`${a.agente}: ${ok} ok`}</title>
                  </rect>
                  {a.erros24h > 0 && (
                    <rect x={L + okW} y={y + 4} width={erroW} height={linhaH - 12} rx="3" className="seg-erro">
                      <title>{`${a.agente}: ${a.erros24h} com falha`}</title>
                    </rect>
                  )}
                  <text x={L + okW + erroW + 6} y={y + linhaH / 2 + 4} className="valor">
                    {a.execucoes24h}
                  </text>
                </>
              )}
            </g>
          );
        })}
      </svg>

      <div className="chart-legenda" aria-hidden="true">
        <span><span className="ponto ok" /> ok</span>
        <span><span className="ponto erro" /> com falha</span>
      </div>

      <table className="sr-only">
        <caption>Execuções nas últimas 24h por agente</caption>
        <thead>
          <tr><th scope="col">Agente</th><th scope="col">Ok</th><th scope="col">Com falha</th></tr>
        </thead>
        <tbody>
          {ordenados.map((a) => (
            <tr key={a.agente}>
              <th scope="row">{a.agente}</th>
              <td>{Math.max(0, a.execucoes24h - a.erros24h)}</td>
              <td>{a.erros24h}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
