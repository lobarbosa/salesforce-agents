"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import type { EstadoRun, RunAoVivo } from "@/lib/esteira-ao-vivo";

const INTERVALO_MS = 4000;

const ROTULO: Record<EstadoRun, string> = {
  rodando: "Rodando",
  sem_detalhe: "Rodando",
  na_fila: "Na fila",
  sem_sinal: "Sem sinal",
  concluida: "Concluída",
  erro: "Falhou",
};

function duracao(deIso: string, ateMs: number) {
  const s = Math.max(0, Math.round((ateMs - new Date(deIso).getTime()) / 1000));
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  return m < 60 ? `${m}min ${s % 60}s` : `${Math.floor(m / 60)}h ${m % 60}min`;
}

function hora(iso: string) {
  return new Date(iso).toLocaleTimeString("pt-BR", { timeZone: "America/Sao_Paulo" });
}

function descreve(e: RunAoVivo["eventos"][number]) {
  switch (e.tipo) {
    case "inicio":
      return "sessão começou";
    case "agente":
      return `chamou o subagente ${e.agente}`;
    case "fila":
      return e.detalhe;
    case "turno":
      return "turno concluído";
    case "fim":
      return e.detalhe === "erro" ? "sessão terminou com erro" : "sessão terminou";
    default:
      return [e.ferramenta, e.detalhe].filter(Boolean).join(" · ");
  }
}

export function EsteiraAoVivo({ inicial }: { inicial: RunAoVivo[] }) {
  const [runs, setRuns] = useState(inicial);
  const [agora, setAgora] = useState(() => Date.now());
  const [offline, setOffline] = useState(false);
  const [aberto, setAberto] = useState<string | null>(inicial.find((r) => r.estado === "rodando")?.runId ?? null);

  useEffect(() => {
    let vivo = true;
    async function buscar() {
      if (document.visibilityState !== "visible") return;
      const res = await fetch("/api/esteira/ao-vivo", { cache: "no-store" }).catch(() => null);
      if (!vivo) return;
      if (!res?.ok) {
        setOffline(true);
        return;
      }
      const body = (await res.json()) as { runs: RunAoVivo[] };
      setRuns(body.runs);
      setOffline(false);
    }
    const id = setInterval(buscar, INTERVALO_MS);
    const relogio = setInterval(() => setAgora(Date.now()), 1000);
    document.addEventListener("visibilitychange", buscar);
    return () => {
      vivo = false;
      clearInterval(id);
      clearInterval(relogio);
      document.removeEventListener("visibilitychange", buscar);
    };
  }, []);

  const rodando = runs.filter((r) => r.estado === "rodando" || r.estado === "sem_detalhe").length;
  const naFila = runs.filter((r) => r.estado === "na_fila").length;

  return (
    <>
      <p className="esteira-resumo" aria-live="polite">
        <span className={`esteira-pulso${rodando ? " ativo" : ""}`} aria-hidden="true" />
        {rodando === 0 ? "Nenhum agente rodando agora." : rodando === 1 ? "1 execução rodando agora." : `${rodando} execuções rodando agora.`}
        {naFila > 0 && <span className="esteira-fila"> {naFila} na fila.</span>}
        {offline && <span className="esteira-offline"> Sem conexão com o servidor — tentando de novo.</span>}
      </p>

      {runs.length === 0 ? (
        <div className="overview-empty">
          Nenhuma execução nas últimas 12 horas. Quando um gate for liberado ou uma demanda for enviada para a esteira, ela aparece aqui.
        </div>
      ) : (
        <ul className="esteira-lista">
          {runs.map((r) => {
            const aberta = aberto === r.runId;
            return (
              <li key={r.runId} className={`esteira-run estado-${r.estado}`}>
                <button
                  type="button"
                  className="esteira-cabeca"
                  aria-expanded={aberta}
                  onClick={() => setAberto(aberta ? null : r.runId)}
                >
                  <span className={`esteira-estado estado-${r.estado}`}>{ROTULO[r.estado]}</span>
                  <span className="esteira-quem">
                    <strong>{r.demandaCode || "—"}</strong> <span className="sub">{r.clientNome}</span>
                  </span>
                  <span className="esteira-onde">
                    etapa <span className="mono">{r.etapa || "?"}</span>
                    {r.estado === "sem_detalhe" && " · sem detalhe dos agentes"}
                    {r.estado === "rodando" && (
                      <>
                        {" "}· agora em <strong>{r.agenteAtual}</strong>
                      </>
                    )}
                  </span>
                  <span className="esteira-tempo">
                    {r.estado === "na_fila"
                      ? `esperando ${duracao(r.inicioEm, agora)}`
                      : r.estado === "rodando" || r.estado === "sem_detalhe" || r.estado === "sem_sinal"
                      ? duracao(r.inicioEm, agora)
                      : duracao(r.inicioEm, new Date(r.ultimoEm).getTime())}
                    <span className="sub">
                      {r.ferramentas} ações{r.custoUsd != null && ` · US$ ${r.custoUsd.toFixed(2)}`}
                    </span>
                  </span>
                </button>
                {aberta && (
                  <div className="esteira-detalhe">
                    {r.estado === "sem_sinal" && (
                      <p className="auth-note error">
                        Nenhum evento há {duracao(r.ultimoEm, agora)} e a sessão não avisou que terminou — o job pode ter caído ou sido cancelado. Confira o log.
                      </p>
                    )}
                    {r.estado === "sem_detalhe" && (
                      <p className="sub">
                        O GitHub diz que esta execução está rodando, mas ela não está mandando eventos — começou antes da esteira ao vivo existir ou ainda está instalando. O detalhe completo está no log.
                      </p>
                    )}
                    {r.estado === "na_fila" && (
                      <p className="sub">Este cliente já tem uma execução rodando; esta sai sozinha quando ela terminar (uma por vez por cliente).</p>
                    )}
                    {r.agentes.length > 0 && <p className="sub">Subagentes: {r.agentes.join(" → ")}</p>}
                    <ol className="esteira-eventos">
                      {r.eventos.map((e, i) => (
                        <li key={i}>
                          <span className="mono">{hora(e.em)}</span>
                          {e.agente && e.tipo === "ferramenta" && <span className="esteira-agente">{e.agente}</span>}
                          <span>{descreve(e)}</span>
                        </li>
                      ))}
                    </ol>
                    <p className="esteira-links">
                      {r.demandaId && (
                        <Link href={`/clients/${r.clientId}?demand=${r.demandaId}`}>Abrir o card</Link>
                      )}
                      {r.runUrl && (
                        <a href={r.runUrl} target="_blank" rel="noreferrer">
                          Log completo no GitHub
                        </a>
                      )}
                    </p>
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}
