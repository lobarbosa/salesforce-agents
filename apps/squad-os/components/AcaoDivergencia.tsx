"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { StatusDivergencia } from "@/lib/ops";

// Ação de uma linha de divergência: resolver (nota opcional), ignorar (nota
// obrigatória — ignorar sem motivo apaga o sinal) ou reabrir. Confirma antes.
export function AcaoDivergencia({ id, status, resumo }: { id: string; status: StatusDivergencia; resumo: string }) {
  const router = useRouter();
  const [escolha, setEscolha] = useState<StatusDivergencia | null>(null);
  const [nota, setNota] = useState("");
  const [erro, setErro] = useState("");
  const [enviando, setEnviando] = useState(false);

  async function confirmar() {
    if (!escolha) return;
    setEnviando(true);
    setErro("");
    const r = await fetch(`/api/financeiro/divergencias/${id}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: escolha, nota }),
    });
    setEnviando(false);
    if (!r.ok) {
      const j = await r.json().catch(() => ({}));
      setErro(j.error ?? "não foi possível registrar");
      return;
    }
    setEscolha(null);
    setNota("");
    router.refresh();
  }

  if (!escolha) {
    return status === "aberta" ? (
      <span className="acoes-div">
        <button type="button" className="btn-ghost" onClick={() => setEscolha("resolvida")} aria-label={`Resolver: ${resumo}`}>
          Resolver
        </button>
        <button type="button" className="btn-ghost" onClick={() => setEscolha("ignorada")} aria-label={`Ignorar: ${resumo}`}>
          Ignorar
        </button>
      </span>
    ) : (
      <button type="button" className="btn-ghost" onClick={() => setEscolha("aberta")} aria-label={`Reabrir: ${resumo}`}>
        Reabrir
      </button>
    );
  }

  const obrigatoria = escolha === "ignorada";
  const verbo = { resolvida: "Marcar como resolvida", ignorada: "Ignorar", aberta: "Reabrir" }[escolha];
  return (
    <div className="confirmar confirmar-div" role="group" aria-label={`${verbo}: ${resumo}`}>
      <label>
        {obrigatoria ? "Por que pode ser ignorada? *" : "Nota (opcional)"}
        <textarea rows={2} value={nota} onChange={(e) => setNota(e.target.value)} />
      </label>
      {erro && (
        <span className="campo-erro" role="alert">
          {erro}
        </span>
      )}
      <div className="form-acoes">
        <button type="button" className="btn-ghost" onClick={() => setEscolha(null)}>
          Voltar
        </button>
        <button type="button" className="btn-primary" disabled={enviando || (obrigatoria && !nota.trim())} onClick={confirmar}>
          {enviando ? "Registrando…" : verbo}
        </button>
      </div>
    </div>
  );
}
