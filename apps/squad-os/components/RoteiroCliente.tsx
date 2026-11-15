"use client";

import { Artefato } from "@/components/Artefato";

// O passo a passo que o agente de QA escreve para quem homologa
// (05-roteiro-cliente.md, ver src/salesforce_agents/roteiro.py). Renderizado
// pelo mesmo componente do artefato de gate, que monta elemento React a
// partir de estrutura de dados: texto escrito por agente nunca vira HTML.
export function RoteiroCliente({
  texto,
  demandaId,
  visaoCliente,
  aberto,
}: {
  texto: string;
  demandaId: string;
  visaoCliente: boolean;
  aberto: boolean;
}) {
  return (
    <details className="artefato" open={aberto}>
      <summary>
        <span className="badge stage">Roteiro de teste</span>
        <span className="gate-texto">
          {visaoCliente
            ? "o passo a passo para você conferir esta entrega"
            : "o passo a passo para testar à mão — o cliente vê da homologação em diante"}
        </span>
      </summary>
      <div className="artefato-corpo">
        <Artefato texto={texto} />
      </div>
      <p className="gate-texto">
        <a className="btn-ghost" href={`/api/demandas/${demandaId}/roteiro/pdf`} target="_blank" rel="noopener">
          Baixar em PDF
        </a>
      </p>
    </details>
  );
}
