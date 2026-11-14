"use client";

import { Artefato } from "@/components/Artefato";

// O passo a passo que o agente de QA escreve para quem homologa
// (05-roteiro-cliente.md, ver src/salesforce_agents/roteiro.py). Renderizado
// pelo mesmo componente do artefato de gate, que monta elemento React a
// partir de estrutura de dados: texto escrito por agente nunca vira HTML.
export function RoteiroCliente({
  texto,
  codigo,
  visaoCliente,
  aberto,
}: {
  texto: string;
  codigo: string;
  visaoCliente: boolean;
  aberto: boolean;
}) {
  function baixar() {
    const url = URL.createObjectURL(new Blob([texto], { type: "text/markdown;charset=utf-8" }));
    const link = document.createElement("a");
    link.href = url;
    link.download = `roteiro-de-teste-${codigo}.md`;
    link.click();
    URL.revokeObjectURL(url);
  }

  return (
    <details className="artefato" open={aberto}>
      <summary>
        <span className="badge stage">Roteiro de teste</span>
        <span className="gate-texto">
          {visaoCliente
            ? "o passo a passo para você conferir esta entrega"
            : "o passo a passo que o cliente segue na homologação"}
        </span>
      </summary>
      <div className="artefato-corpo">
        <Artefato texto={texto} />
      </div>
      <p className="gate-texto">
        <button type="button" className="btn-ghost" onClick={baixar}>
          Baixar o roteiro
        </button>
      </p>
    </details>
  );
}
