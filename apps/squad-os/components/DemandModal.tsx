"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { DemandaCompleta } from "@/lib/data";
import { Modal } from "@/components/Modal";
import { DemandaPainel } from "@/components/DemandaPainel";
import {
  asPerguntas,
  asAprovacao,
  STAGE_LABEL,
  ESTADO_CLIENTE_LABEL,
  estadoDoCliente,
  progressoDaDemanda,
  timeAgo,
} from "@/lib/demandas";

export function DemandModal({
  demanda,
  canManage,
  usuarioEmail,
  isAdmin,
  visaoCliente = false,
  onClose,
}: {
  demanda: DemandaCompleta;
  canManage: boolean;
  usuarioEmail: string;
  isAdmin: boolean;
  /** Sem jargão de esteira — ver ESTADOS_CLIENTE em lib/demandas.ts. */
  visaoCliente?: boolean;
  onClose: () => void;
}) {
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
  const [confirmandoGate, setConfirmandoGate] = useState(false);
  const [aprovandoGate, setAprovandoGate] = useState(false);
  const [gateErro, setGateErro] = useState("");

  const emGate = demanda.status.startsWith("aguardando_");
  // `aguardando_homologacao` é o cliente aceitando a entrega — é dele esse
  // gate. Os outros são internos de delivery. A API repete essa checagem; aqui
  // é só pra não mostrar um botão que vai devolver 403.
  const podeAprovarEsteGate =
    emGate && (canManage || demanda.status === "aguardando_homologacao");

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

  async function aprovarGate() {
    setGateErro("");
    setAprovandoGate(true);
    const res = await fetch(`/api/demandas/${demanda.id}/aprovar-gate`, { method: "POST" });
    setAprovandoGate(false);
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setGateErro(body.error || "não consegui liberar o gate");
      return;
    }
    setConfirmandoGate(false);
    router.refresh();
    onClose();
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

      {visaoCliente && !emGate && (
        <div className="estado-cliente">
          <span className={`badge ${estadoDoCliente(demanda.status) === "entregue" ? "aprovado" : "stage"}`}>
            {ESTADO_CLIENTE_LABEL[estadoDoCliente(demanda.status)]}
          </span>
          {progressoDaDemanda(demanda.status) && (
            <span className="gate-texto">{progressoDaDemanda(demanda.status)!.rotulo}</span>
          )}
        </div>
      )}

      {emGate && (
        <div className="gate-box">
          <div className="gate-titulo">
            {visaoCliente ? (
              <span className="badge gate">
                {ESTADO_CLIENTE_LABEL[estadoDoCliente(demanda.status)]}
              </span>
            ) : (
              <>
                <span className="badge gate">gate humano</span>
                {STAGE_LABEL[demanda.status] ?? demanda.status}
              </>
            )}
          </div>
          {podeAprovarEsteGate ? (
            <>
              <p className="gate-texto">
                {visaoCliente
                  ? "Revise o que foi entregue e aprove quando estiver de acordo. Seu nome e a data ficam registrados, junto com a versão exata do que você aprovou."
                  : "A esteira parou aqui esperando aprovação. Ao liberar, a próxima etapa dispara sozinha na sandbox correspondente — e o seu nome fica registrado como quem aprovou."}
              </p>
              {!confirmandoGate ? (
                <button
                  className="btn-primary"
                  type="button"
                  onClick={() => setConfirmandoGate(true)}
                  disabled={!demanda.materializadoEm}
                >
                  {visaoCliente ? "Aprovar a entrega" : "Aprovar e liberar a próxima etapa"}
                </button>
              ) : (
                // Dois passos de propósito: isto aciona agente contra a org do
                // cliente e não tem desfazer. Um clique só num botão que fica
                // ao lado de "Fechar" é acidente esperando acontecer.
                <div className="gate-confirma" role="group" aria-label="Confirmar aprovação do gate">
                  <span>
                    {visaoCliente
                      ? "Confirma a aprovação? Não dá pra desfazer."
                      : "Confirma? Isso aciona os agentes agora."}
                  </span>
                  <button
                    className="btn-primary"
                    type="button"
                    onClick={aprovarGate}
                    disabled={aprovandoGate}
                  >
                    {aprovandoGate ? "Liberando..." : "Sim, liberar"}
                  </button>
                  <button
                    className="btn-ghost"
                    type="button"
                    onClick={() => setConfirmandoGate(false)}
                    disabled={aprovandoGate}
                  >
                    Cancelar
                  </button>
                </div>
              )}
              {!demanda.materializadoEm && (
                <p className="gate-texto">
                  Materialize a demanda primeiro — sem isso ela não existe no repositório pra
                  avançar.
                </p>
              )}
            </>
          ) : (
            <p className="gate-texto">
              Aguardando o time da Acxya liberar esta etapa.
            </p>
          )}
          {gateErro && (
            <div className="auth-note error" role="alert" style={{ marginTop: "0.5rem" }}>
              {gateErro}
            </div>
          )}
        </div>
      )}

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

      {canManage && demanda.status === "backlog" && (
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

      <DemandaPainel
        demandaId={demanda.id}
        usuarioEmail={usuarioEmail}
        isAdmin={isAdmin}
        dados={{
          comentarios: demanda.comentarios,
          subtarefas: demanda.subtarefas,
          checklist: demanda.checklist,
          tempos: demanda.tempos,
          anexos: demanda.anexos,
        }}
      />

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
