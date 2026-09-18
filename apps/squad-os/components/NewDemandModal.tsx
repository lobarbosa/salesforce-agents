"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Modal } from "@/components/Modal";

export function NewDemandModal({
  clientId,
  clientNome,
  onClose,
}: {
  clientId: string;
  clientNome: string;
  onClose: () => void;
}) {
  const router = useRouter();
  const [titulo, setTitulo] = useState("");
  const [tipo, setTipo] = useState<"sustentacao" | "projeto">("sustentacao");
  const [texto, setTexto] = useState("");
  const [saving, setSaving] = useState(false);
  const [erro, setErro] = useState("");

  async function handleSave() {
    if (!titulo.trim()) return;
    setSaving(true);
    setErro("");
    const res = await fetch("/api/demandas", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ clientId, titulo: titulo.trim(), tipo, texto }),
    });
    setSaving(false);
    if (res.ok) {
      router.refresh();
      onClose();
      return;
    }
    // Sem isto o modal só não fechava, e quem clicou não tinha como saber se
    // foi sessão expirada, permissão ou defeito nosso. Passou a importar mais
    // agora que o próprio cliente registra demanda por aqui.
    const corpo = await res.json().catch(() => ({}));
    setErro((corpo as { error?: string }).error ?? `não consegui criar (HTTP ${res.status})`);
  }

  return (
    <Modal title={`Nova demanda — ${clientNome}`} onClose={onClose}>
      <div className="field">
        <label>Título</label>
        <input type="text" required value={titulo} onChange={(e) => setTitulo(e.target.value)} autoFocus />
      </div>
      <div className="field">
        <label>Tipo</label>
        <select value={tipo} onChange={(e) => setTipo(e.target.value as "sustentacao" | "projeto")}>
          <option value="sustentacao">Sustentação</option>
          <option value="projeto">Projeto</option>
        </select>
      </div>
      <div className="field">
        <label>Descrição (a história)</label>
        <textarea
          placeholder="Contexto, objetivo, o que precisa acontecer..."
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
        />
      </div>
      {erro && (
        <div className="auth-note error" role="alert">
          {erro}
        </div>
      )}
      <div className="modal-actions">
        <button className="btn-ghost" type="button" onClick={onClose}>
          Cancelar
        </button>
        <button className="btn-primary" type="button" onClick={handleSave} disabled={saving}>
          {saving ? "Criando..." : "Criar demanda"}
        </button>
      </div>
    </Modal>
  );
}
