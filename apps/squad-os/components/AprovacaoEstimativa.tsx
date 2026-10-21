"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { DemandaCompleta } from "@/lib/data";
import { aguardaAprovacaoEstimativa, estimativaAprovada } from "@/lib/demandas";

// Aprovação da estimativa de horas pelo cliente (2026-10-21). O número
// aprovado é o que debita do contrato quando a demanda entra em build, e sem
// ele o build não sai. "Segurar" congela a demanda com o motivo do cliente.

function h(n: number) {
  return n.toLocaleString("pt-BR", { maximumFractionDigits: 2 });
}

export function DecisaoEstimativa({ demanda, podeDecidir }: { demanda: DemandaCompleta; podeDecidir: boolean }) {
  const router = useRouter();
  const [modo, setModo] = useState<"" | "aprovar" | "segurar">("");
  const [motivo, setMotivo] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");

  const horas = demanda.estimativaConsultorHoras;
  const aprovada = estimativaAprovada(demanda);
  const pendente = aguardaAprovacaoEstimativa(demanda);
  const segurada = pendente && demanda.status === "standby";

  if (horas == null) return null;
  if (!pendente && !aprovada && !demanda.estimativaDebitadaEm) return null;

  async function decidir(decisao: "aprovar" | "segurar") {
    setEnviando(true);
    setErro("");
    const res = await fetch(`/api/demandas/${demanda.id}/estimativa/aprovacao`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ decisao, motivo, horas }),
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

  if (demanda.estimativaDebitadaEm && demanda.estimativaDebitadaHoras != null) {
    const lancado = demanda.tempos.reduce((s, t) => s + (t.fimEm ? (t.minutos ?? 0) : 0), 0) / 60;
    const excedente = lancado - demanda.estimativaDebitadaHoras;
    return (
      <div className="aprovacao-estimativa aprovada" role="status">
        <strong>{h(demanda.estimativaDebitadaHoras)} h debitadas do contrato</strong>
        <span>
          Estimativa aprovada por {demanda.estimativaAprovadaPor || "cliente"}, debitada quando a construção começou.
          {lancado > 0 && ` Lançado até agora: ${h(Math.round(lancado * 10) / 10)} h`}
          {excedente > 0.05 && ` — ${h(Math.round(excedente * 10) / 10)} h acima da estimativa (não debitadas).`}
        </span>
      </div>
    );
  }

  if (aprovada) {
    return (
      <div className="aprovacao-estimativa aprovada" role="status">
        <strong>Estimativa aprovada: {h(horas)} h</strong>
        <span>
          Por {demanda.estimativaAprovadaPor}. Essas horas são debitadas do contrato quando a construção começar.
        </span>
      </div>
    );
  }

  return (
    <div className={`aprovacao-estimativa ${segurada ? "segurada" : "pendente"}`}>
      <strong>
        {segurada ? "Demanda segurada na estimativa" : "Estimativa esperando aprovação do cliente"}: {h(horas)} h
      </strong>
      <span>
        {segurada
          ? `Motivo: ${demanda.motivoParada.replace(/^Cliente segurou a estimativa: /, "") || "—"}. Aprovar libera a demanda de novo.`
          : "Ao aprovar, essas horas são debitadas do contrato quando a construção começar. A construção só começa depois da aprovação."}
      </span>
      {podeDecidir && !modo && (
        <span className="aprovacao-botoes">
          <button type="button" className="btn-primary" onClick={() => setModo("aprovar")}>
            Aprovar {h(horas)} h
          </button>
          {!segurada && (
            <button type="button" className="btn-ghost" onClick={() => setModo("segurar")}>
              Segurar demanda
            </button>
          )}
        </span>
      )}
      {modo === "aprovar" && (
        <span className="aprovacao-botoes" role="group" aria-label="Confirmar aprovação">
          <span>Confirma {h(horas)} h para esta demanda?</span>
          <button type="button" className="btn-primary" onClick={() => decidir("aprovar")} disabled={enviando} autoFocus>
            {enviando ? "Aprovando..." : "Sim, aprovar"}
          </button>
          <button type="button" className="btn-ghost" onClick={() => setModo("")} disabled={enviando}>
            Voltar
          </button>
        </span>
      )}
      {modo === "segurar" && (
        <div className="aprovacao-segurar">
          <label className="field">
            Por que segurar? (o time vê e responde no card)
            <textarea value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={2} autoFocus />
          </label>
          <span className="aprovacao-botoes">
            <button
              type="button"
              className="btn-secondary"
              onClick={() => decidir("segurar")}
              disabled={enviando || !motivo.trim()}
            >
              {enviando ? "Enviando..." : "Segurar demanda"}
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

/** A tela do cliente: tudo que espera a decisão dele, de uma vez. */
export function AprovacoesTab({ demandas, onAbrir }: { demandas: DemandaCompleta[]; onAbrir?: (id: string) => void }) {
  const pendentes = demandas.filter(aguardaAprovacaoEstimativa);
  const aprovadas = demandas.filter((d) => estimativaAprovada(d) && !d.estimativaDebitadaEm);
  return (
    <div className="aprovacoes">
      <p className="aprovacoes-intro">
        Cada demanda tem uma estimativa de horas feita depois da análise. Aprove para a construção começar — as horas
        aprovadas são debitadas do contrato quando ela começa. Se não concordar, segure a demanda e diga por quê.
      </p>
      {pendentes.length === 0 ? (
        <div className="overview-empty ok">Nenhuma estimativa esperando sua aprovação.</div>
      ) : (
        <ul className="aprovacoes-lista">
          {pendentes.map((d) => (
            <li key={d.id} className="aprovacoes-item">
              <div className="aprovacoes-titulo">
                <span className="mono">{d.code}</span>
                {onAbrir ? (
                  <button type="button" className="link-btn" onClick={() => onAbrir(d.id)}>
                    {d.titulo}
                  </button>
                ) : (
                  <span>{d.titulo}</span>
                )}
              </div>
              <DecisaoEstimativa demanda={d} podeDecidir />
            </li>
          ))}
        </ul>
      )}
      {aprovadas.length > 0 && (
        <>
          <h3 className="aprovacoes-sub">Aprovadas, esperando a construção</h3>
          <ul className="aprovacoes-lista">
            {aprovadas.map((d) => (
              <li key={d.id} className="aprovacoes-item">
                <div className="aprovacoes-titulo">
                  <span className="mono">{d.code}</span> <span>{d.titulo}</span>
                </div>
                <DecisaoEstimativa demanda={d} podeDecidir={false} />
              </li>
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
