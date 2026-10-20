"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Modal } from "@/components/Modal";
import { dataBR, MOTIVO_MAX, nomeConfere } from "@/lib/encerramento";

// Encerrar / reativar / excluir cliente — só renderizado para admin (a API
// confere de novo). Encerrar é o caminho normal para "cliente que saiu";
// excluir só aparece habilitado para encerrado sem histórico. Regras em
// lib/encerramento.ts.

async function erroDe(res: Response): Promise<string> {
  const corpo = await res.json().catch(() => ({}));
  return (corpo as { error?: string }).error ?? `falhou (HTTP ${res.status})`;
}

export function EncerradoBadge({ encerradoEm }: { encerradoEm: Date | string }) {
  return <span className="badge encerrado">Encerrado em {dataBR(new Date(encerradoEm))}</span>;
}

export function EncerramentoCliente({
  clientId,
  nome,
  slug,
  encerradoEm,
  encerradoPorEmail,
  motivoEncerramento,
  bloqueiosExclusao,
}: {
  clientId: string;
  nome: string;
  slug: string;
  encerradoEm: Date | string | null;
  encerradoPorEmail: string | null;
  motivoEncerramento: string;
  /** Só faz sentido para encerrado: o que impede excluir (vazio = pode). */
  bloqueiosExclusao: string[];
}) {
  const router = useRouter();
  const [aberto, setAberto] = useState<null | "encerrar" | "excluir">(null);
  const [motivo, setMotivo] = useState("");
  const [confirmacao, setConfirmacao] = useState("");
  const [erro, setErro] = useState("");
  const [enviando, setEnviando] = useState(false);

  // Erro de rede não pode deixar o modal travado em "enviando" (Cancelar fica desabilitado).
  async function enviar(req: () => Promise<Response>): Promise<Response | null> {
    setEnviando(true);
    setErro("");
    try {
      const res = await req();
      if (!res.ok) setErro(await erroDe(res));
      return res.ok ? res : null;
    } catch {
      setErro("sem conexão com o servidor — tente de novo");
      return null;
    } finally {
      setEnviando(false);
    }
  }

  function fechar() {
    if (enviando) return;
    setAberto(null);
    setErro("");
    setMotivo("");
    setConfirmacao("");
  }

  async function encerrar(e: FormEvent) {
    e.preventDefault();
    const res = await enviar(() =>
      fetch(`/api/clients/${clientId}/encerramento`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ motivo }),
      })
    );
    if (!res) return;
    setAberto(null);
    setMotivo("");
    router.refresh();
  }

  async function reativar() {
    const res = await enviar(() => fetch(`/api/clients/${clientId}/encerramento`, { method: "DELETE" }));
    if (!res) return;
    router.refresh();
  }

  async function excluir(e: FormEvent) {
    e.preventDefault();
    const res = await enviar(() =>
      fetch(`/api/clients/${clientId}`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ confirmacaoNome: confirmacao }),
      })
    );
    if (!res) return;
    router.push("/");
    router.refresh();
  }

  if (!encerradoEm) {
    return (
      <>
        <button className="btn-ghost" type="button" onClick={() => setAberto("encerrar")}>
          Encerrar cliente
        </button>
        {aberto === "encerrar" && (
          <Modal title={`Encerrar ${nome}?`} onClose={fechar}>
            <form className="encerramento-form" onSubmit={encerrar}>
              <p className="save-note">Para cliente que saiu. Nada é apagado, e dá para reativar depois.</p>
              <ul className="encerramento-lista">
                <li>Os usuários de papel cliente de {nome} perdem o acesso ao Squad OS.</li>
                <li>Novas demandas, lançamentos de horas e execuções de agente ficam bloqueados.</li>
                <li>O cliente some da lista, da Visão Geral e dos seletores (fica em &ldquo;Encerrados&rdquo;, só para admin).</li>
                <li>O histórico fica: demandas, horas, contrato e relatórios financeiros continuam como estão.</li>
              </ul>
              <div className="field">
                <label htmlFor="motivo-encerramento">Motivo *</label>
                <textarea
                  id="motivo-encerramento"
                  required
                  maxLength={MOTIVO_MAX}
                  value={motivo}
                  onChange={(e) => setMotivo(e.target.value)}
                  placeholder="Ex.: contrato encerrado em setembro, sem renovação"
                />
              </div>
              {erro && (
                <p className="form-erro" role="alert">
                  {erro}
                </p>
              )}
              <div className="modal-actions">
                <button type="button" className="btn-ghost" onClick={fechar} disabled={enviando}>
                  Cancelar
                </button>
                <button type="submit" className="btn-perigo" disabled={enviando || !motivo.trim()}>
                  {enviando ? "Encerrando…" : "Encerrar cliente"}
                </button>
              </div>
            </form>
          </Modal>
        )}
      </>
    );
  }

  const podeExcluir = bloqueiosExclusao.length === 0;
  return (
    <div className="encerrado-banner" role="status">
      <div>
        <strong>Cliente encerrado em {dataBR(new Date(encerradoEm))}</strong>
        {encerradoPorEmail ? <> por {encerradoPorEmail}</> : null}.
        {motivoEncerramento ? <> Motivo: {motivoEncerramento}</> : null}
        <div className="save-note">
          Sem acesso para o cliente, sem demandas, horas ou agentes novos. O histórico abaixo é somente consulta.
        </div>
      </div>
      <div className="encerrado-acoes">
        <button className="btn-secondary" type="button" onClick={reativar} disabled={enviando}>
          Reativar
        </button>
        <button
          className="btn-ghost"
          type="button"
          onClick={() => setAberto("excluir")}
          disabled={!podeExcluir}
          title={podeExcluir ? undefined : `Não dá para excluir: ${bloqueiosExclusao.join(", ")}`}
        >
          Excluir definitivamente
        </button>
      </div>
      {!podeExcluir && (
        <div className="save-note">
          Exclusão bloqueada — tem histórico ({bloqueiosExclusao.join(", ")}). Mantenha encerrado.
        </div>
      )}
      {erro && !aberto && (
        <p className="form-erro" role="alert">
          {erro}
        </p>
      )}
      {aberto === "excluir" && (
        <Modal title={`Excluir ${nome} definitivamente?`} onClose={fechar}>
          <form className="encerramento-form" onSubmit={excluir}>
            <p className="save-note">
              Não dá para desfazer. Saem do banco o cliente, os ambientes, o contrato vazio e os usuários de papel
              cliente dele. O diretório <code className="mono">clients/{slug}/</code> no repositório{" "}
              <strong>não</strong> é apagado — é histórico do git.
            </p>
            <div className="field">
              <label htmlFor="confirmacao-exclusao">Digite o nome do cliente ({nome}) para confirmar</label>
              <input
                id="confirmacao-exclusao"
                autoComplete="off"
                value={confirmacao}
                onChange={(e) => setConfirmacao(e.target.value)}
              />
            </div>
            {erro && (
              <p className="form-erro" role="alert">
                {erro}
              </p>
            )}
            <div className="modal-actions">
              <button type="button" className="btn-ghost" onClick={fechar} disabled={enviando}>
                Cancelar
              </button>
              <button type="submit" className="btn-perigo" disabled={enviando || !nomeConfere(confirmacao, nome)}>
                {enviando ? "Excluindo…" : "Excluir definitivamente"}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
