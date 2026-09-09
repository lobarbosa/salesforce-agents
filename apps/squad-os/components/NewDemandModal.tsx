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

  async function handleSave() {
    if (!titulo.trim()) return;
    setSaving(true);
    const res = await fetch("/api/demandas", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ clientId, titulo: titulo.trim(), tipo, texto }),
    });
    setSaving(false);
    if (res.ok) {
      router.refresh();
      onClose();
    }
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
