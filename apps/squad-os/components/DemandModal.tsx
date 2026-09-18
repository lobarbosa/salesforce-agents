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
  podeAprovarGate,
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
  // Mesma função que a API chama — ver podeAprovarGate em lib/demandas.ts.
  // Decide o botão de aprovar, o artefato que aparece e as perguntas que
  // podem ser respondidas: as três coisas são o mesmo gate.
  const podeAprovarEsteGate = podeAprovarGate(canManage, demanda.status);

  const jaAprovada = !!aprovacao?.aprovado;
  const faltandoResposta = respostas.filter((p) => !p.resposta.trim()).length;
  // As perguntas saem do mesmo artefato do gate, então seguem a mesma regra:
  // pro cliente elas aparecem só no gate que é dele, junto do documento de
  // onde vieram. Antes ele via pergunta de gate interno sem o documento — e a
  // API deixava responder. Pra quem é do time, nada muda: continua podendo
  // responder mesmo fora de gate (adiantar resposta enquanto o agente roda).
  const mostrarPerguntas = respostas.length > 0 && (!visaoCliente || podeAprovarEsteGate);

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

      {/* O que está sendo julgado. Antes disto o gate chegava como um botão sem
          contexto: o artefato existia só no git, e aprovar sem ler era o
          caminho mais curto da tela.

          A condição é `podeAprovarEsteGate`, a mesma do botão, e não o papel:
          quem aprova vê o que aprova. Na prática isso dá ao cliente o
          `05-testes.md` no gate de homologação — que é a evidência da
          pergunta que ele responde ali ("aceito esta entrega?") — e mantém
          fechados os gates de análise, design e build, que são decisão
          interna de método e que ele não aprova de qualquer forma (a API
          restringe o papel `cliente` a `aguardando_homologacao`). O
          invariante que fica: não existe botão de aprovar sem a coisa
          aprovada do lado. */}
      {podeAprovarEsteGate && demanda.artefatoConteudo && (
        <details className="artefato" open>
          <summary>
            <span className="badge stage">{demanda.artefatoNome}</span>
            <span className="gate-texto">
              {visaoCliente ? "o que foi testado nesta entrega" : "o que este gate põe na mesa"}
            </span>
          </summary>
          {/* Texto puro, não markdown renderizado: este conteúdo é escrito por
              um agente, e passá-lo por um renderizador de HTML abriria injeção
              na tela de quem decide. Legibilidade não vale esse preço. */}
          <pre className="artefato-corpo">{demanda.artefatoConteudo}</pre>
          {demanda.artefatoTruncado && (
            <p className="gate-texto">
              {visaoCliente ? (
                <>
                  Cortado por tamanho — peça o{" "}
                  <code className="mono">{demanda.artefatoNome}</code> completo ao time da Acxya.
                </>
              ) : (
                <>
                  Cortado por tamanho — o <code className="mono">{demanda.artefatoNome}</code>{" "}
                  completo está no PR desta demanda.
                </>
              )}
            </p>
          )}
        </details>
      )}

      {jaAprovada ? (
        <div className="approval-banner aprovado">
          ✓ Aprovado por {aprovacao!.por} em {(aprovacao!.em || "").slice(0, 10)}
          {aprovacao!.observacao ? ` — ${aprovacao!.observacao}` : ""}
        </div>
      ) : (
        mostrarPerguntas && (
          <div className="approval-banner pendente">
            Responda as perguntas abaixo — cada resposta salva sozinha. Depois aprove pra liberar a
            próxima etapa, sem precisar acionar ninguém.
          </div>
        )
      )}

      {mostrarPerguntas && (
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

      {mostrarPerguntas && !jaAprovada && (
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
        visaoCliente={visaoCliente}
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
        {mostrarPerguntas && !jaAprovada && (
          <button className="btn-primary" type="button" onClick={aprovarEAvancar} disabled={aprovando}>
            {aprovarMsg || (aprovando ? "Aprovando..." : "Aprovar e avançar")}
          </button>
        )}
      </div>
    </Modal>
  );
}
