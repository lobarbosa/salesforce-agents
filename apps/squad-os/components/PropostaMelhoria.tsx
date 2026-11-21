"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { DemandaCompleta } from "@/lib/data";
import { propostaPendente } from "@/lib/assessment-propostas";

// Melhoria proposta pela equipe a partir do diagnóstico da org (2026-11-21).
// O cliente aprova (segue no backlog para a equipe programar) ou recusa (a
// demanda é cancelada com o motivo dele). Dois passos, como os gates.

export function DecisaoProposta({ demanda, podeDecidir }: { demanda: DemandaCompleta; podeDecidir: boolean }) {
  const router = useRouter();
  const [modo, setModo] = useState<"" | "aprovar" | "recusar">("");
  const [motivo, setMotivo] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");

  if (!demanda.propostaClienteEm) return null;
  const pendente = propostaPendente(demanda) && demanda.status === "backlog";

  async function decidir(decisao: "aprovar" | "recusar") {
    setEnviando(true);
    setErro("");
    const res = await fetch(`/api/demandas/${demanda.id}/proposta`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ decisao, motivo }),
    }).catch(() => null);
    setEnviando(false);
    if (!res?.ok) {
      const body = res ? await res.json().catch(() => ({})) : {};
      setErro(body.error || "não deu certo — tente de novo");
      return;
    }
    setModo("");
    router.refresh();
  }

  if (!pendente) {
    const aprovada = demanda.propostaDecisao === "aprovada";
    return (
      <div className={`aprovacao-estimativa ${aprovada ? "aprovada" : "segurada"}`} role="status">
        <strong>{aprovada ? "Melhoria aprovada pelo cliente" : "Melhoria recusada pelo cliente"}</strong>
        <span>
          {demanda.propostaDecididaPor ? `Por ${demanda.propostaDecididaPor}. ` : ""}
          {aprovada
            ? "Proposta a partir do diagnóstico da org. Segue no backlog para a equipe programar."
            : `Motivo: ${demanda.motivoParada.replace(/^Cliente recusou a melhoria proposta: /, "") || "—"}`}
        </span>
      </div>
    );
  }

  return (
    <div className="aprovacao-estimativa pendente">
      <strong>Melhoria proposta pela equipe, esperando aprovação do cliente</strong>
      <span>
        Nasceu do diagnóstico da org. Aprovar não começa o trabalho nem consome horas: a demanda fica no backlog e a
        equipe combina com você quando ela entra, com a estimativa de horas depois da análise.
      </span>
      {podeDecidir && !modo && (
        <span className="aprovacao-botoes">
          <button type="button" className="btn-primary" onClick={() => setModo("aprovar")}>
            Aprovar melhoria
          </button>
          <button type="button" className="btn-ghost" onClick={() => setModo("recusar")}>
            Recusar
          </button>
        </span>
      )}
      {modo === "aprovar" && (
        <span className="aprovacao-botoes" role="group" aria-label="Confirmar aprovação">
          <span>Confirma a aprovação desta melhoria?</span>
          <button type="button" className="btn-primary" onClick={() => decidir("aprovar")} disabled={enviando} autoFocus>
            {enviando ? "Aprovando..." : "Sim, aprovar"}
          </button>
          <button type="button" className="btn-ghost" onClick={() => setModo("")} disabled={enviando}>
            Voltar
          </button>
        </span>
      )}
      {modo === "recusar" && (
        <div className="aprovacao-segurar">
          <label className="field">
            Por que recusar? (a equipe vê no card)
            <textarea value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={2} autoFocus />
          </label>
          <span className="aprovacao-botoes">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => decidir("recusar")}
              disabled={enviando || !motivo.trim()}
            >
              {enviando ? "Enviando..." : "Recusar melhoria"}
            </button>
            <button type="button" className="btn-ghost" onClick={() => setModo("")} disabled={enviando}>
              Voltar
            </button>
          </span>
        </div>
      )}
      {erro && (
        <p className="auth-note error" role="alert">
          {erro}
        </p>
      )}
    </div>
  );
}
