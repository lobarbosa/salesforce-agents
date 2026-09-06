"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Demanda } from "@/lib/generated/prisma/client";
import { Modal } from "@/components/Modal";
import { asPerguntas, asAprovacao, timeAgo } from "@/lib/demandas";

export function DemandModal({ demanda, onClose }: { demanda: Demanda; onClose: () => void }) {
  const router = useRouter();
  const perguntasIniciais = asPerguntas(demanda.perguntas);
  const aprovacao = asAprovacao(demanda.aprovacao);

  const [respostas, setRespostas] = useState(
    perguntasIniciais.map((p) => ({ ...p, resposta: p.resposta ?? "" }))
  );
  const [notes, setNotes] = useState<Record<string, "" | "salvo">>({});
  const [aprovador, setAprovador] = useState("");
  const [observacao, setObservacao] = useState("");
  const [aprovando, setAprovando] = useState(false);
  const [aprovarMsg, setAprovarMsg] = useState("");
  const [materializando, setMaterializando] = useState(demanda.materializadoEm != null);
  const [materializeErro, setMaterializeErro] = useState("");

  const jaAprovada = !!aprovacao?.aprovado;
  const faltandoResposta = respostas.filter((p) => !p.resposta.trim()).length;

  async function salvarResposta(id: string, valor: string) {
    const atualizadas = respostas.map((p) => (p.id === id ? { ...p, resposta: valor } : p));
    setRespostas(atualizadas);
    const res = await fetch(`/api/demandas/${demanda.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ perguntas: atualizadas }),
    });
    setNotes((n) => ({ ...n, [id]: res.ok ? "salvo" : "" }));
    if (res.ok) setTimeout(() => setNotes((n) => ({ ...n, [id]: "" })), 1400);
    router.refresh();
  }

  async function aprovarEAvancar() {
    if (faltandoResposta > 0) {
      setAprovarMsg(`Responda tudo antes (${faltandoResposta} falta${faltandoResposta > 1 ? "m" : ""})`);
      setTimeout(() => setAprovarMsg(""), 2000);
      return;
    }
    if (!aprovador.trim()) return;
    setAprovando(true);
    const res = await fetch(`/api/demandas/${demanda.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        perguntas: respostas,
        aprovacao: {
          aprovado: true,
          por: aprovador.trim(),
          em: new Date().toISOString(),
          observacao: observacao.trim() || "",
        },
      }),
    });
    setAprovando(false);
    if (res.ok) {
      router.refresh();
      onClose();
    }
  }

  async function materializar() {
    setMaterializeErro("");
    setMaterializando(true);
    const res = await fetch(`/api/demandas/${demanda.id}/materialize`, { method: "POST" });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setMaterializeErro(body.error || "falha ao materializar");
      setMaterializando(false);
      return;
    }
    router.refresh();
  }

  return (
    <Modal title={demanda.titulo} onClose={onClose} wide>
      <div className="meta">
        <span className={`badge ${demanda.tipo === "projeto" ? "projeto" : "sustentacao"}`}>
          {demanda.tipo === "projeto" ? "projeto" : "sustentação"}
        </span>
        <span>{demanda.autor}</span>
        <span>{timeAgo(demanda.criadoEm)}</span>
      </div>

      <div className="demanda-texto">{demanda.texto || "(sem descrição)"}</div>

      {jaAprovada ? (
        <div className="approval-banner aprovado">
          ✓ Aprovado por {aprovacao!.por} em {(aprovacao!.em || "").slice(0, 10)}
          {aprovacao!.observacao ? ` — ${aprovacao!.observacao}` : ""}
        </div>
      ) : (
        respostas.length > 0 && (
          <div className="approval-banner pendente">
            Responda as perguntas abaixo — cada resposta salva sozinha. Depois aprove pra liberar a
            próxima etapa, sem precisar acionar ninguém.
          </div>
        )
      )}

      {respostas.length > 0 && (
        <div className="pergunta-list">
          {respostas.map((p, i) => (
            <div className="pergunta-item" key={p.id}>
              <div className="texto">
                {i + 1}. {p.texto}
              </div>
              <textarea
                defaultValue={p.resposta}
                placeholder="sua resposta... (salva sozinho ao sair do campo)"
                onBlur={(e) => salvarResposta(p.id, e.target.value)}
              />
              <span className="save-note" role="status">
                {notes[p.id] ?? ""}
              </span>
            </div>
          ))}
        </div>
      )}

      {respostas.length > 0 && !jaAprovada && (
        <>
          <div className="field">
            <label>Seu nome (para registrar a aprovação)</label>
            <input
              type="text"
              placeholder="quem está aprovando"
              value={aprovador}
              onChange={(e) => setAprovador(e.target.value)}
            />
          </div>
          <div className="field">
            <label>Observação (opcional)</label>
            <textarea
              placeholder="alguma ressalva ou contexto..."
              value={observacao}
              onChange={(e) => setObservacao(e.target.value)}
            />
          </div>
        </>
      )}

      {demanda.status === "backlog" && (
        <div className="approval-banner pendente">
          {materializeErro && <div style={{ marginBottom: "0.4rem" }}>{materializeErro}</div>}
          {demanda.materializadoEm
            ? "Já materializada — os agentes assumem a partir daqui (acompanhe via sfagents / GitHub Actions)."
            : "Pronta pra virar execução? Isso commita demanda.md + status.yaml em clients/<cliente>/demandas/ e dispara os agentes no CI."}
          {!demanda.materializadoEm && (
            <div style={{ marginTop: "0.5rem" }}>
              <button className="btn-secondary" type="button" onClick={materializar} disabled={materializando}>
                {materializando ? "Materializando..." : "Materializar e disparar agentes"}
              </button>
            </div>
          )}
        </div>
      )}

      <div className="modal-actions">
        <button className="btn-ghost" type="button" onClick={onClose}>
          Fechar
        </button>
        {respostas.length > 0 && !jaAprovada && (
          <button className="btn-primary" type="button" onClick={aprovarEAvancar} disabled={aprovando}>
            {aprovarMsg || (aprovando ? "Aprovando..." : "Aprovar e avançar")}
          </button>
        )}
      </div>
    </Modal>
  );
}
