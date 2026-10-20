"use client";

import { useId, useRef, useState } from "react";

// Campo com autosave ao perder foco — mesmo padrão usado em Conhecimento do
// Cliente, Conexão Salesforce e nas perguntas do gate. `role="status"` no
// aviso é o achado da revisão UI/UX Pro Max: sem isso "salvo"/"erro ao
// salvar" não era anunciado a leitor de tela.
export function SaveField({
  label,
  value: initialValue,
  multiline,
  placeholder,
  full,
  onSave,
  readOnly,
}: {
  label: string;
  value: string;
  multiline?: boolean;
  placeholder?: string;
  full?: boolean;
  onSave: (value: string) => Promise<boolean>;
  /** Visão do cliente: mostra o valor como texto, sem campo editável. */
  readOnly?: boolean;
}) {
  const [value, setValue] = useState(initialValue);
  const [note, setNote] = useState<"" | "salvo" | "erro ao salvar">("");
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const fieldId = useId();

  // Compara com o último valor SALVO, não com o da primeira renderização: sem
  // isso, editar A→B (salvo) e voltar B→A não salvava nada e o servidor ficava com B.
  const salvo = useRef(initialValue);

  async function handleBlur() {
    if (value === salvo.current) return;
    let ok = false;
    try {
      ok = await onSave(value);
    } catch {
      ok = false; // erro de rede também aparece como "erro ao salvar"
    }
    if (ok) salvo.current = value;
    setNote(ok ? "salvo" : "erro ao salvar");
    if (timer.current) clearTimeout(timer.current);
    if (ok) timer.current = setTimeout(() => setNote(""), 1600);
  }

  if (readOnly) {
    return (
      <div className={`brief-field somente-leitura${full ? " full" : ""}`}>
        <span className="brief-rotulo">{label}</span>
        <p className="brief-valor">{initialValue || <span className="sub">não informado</span>}</p>
      </div>
    );
  }

  return (
    <div className={`brief-field${full ? " full" : ""}`}>
      <label htmlFor={fieldId}>
        {label}
        <span className={`save-note${note === "salvo" ? " saved" : note === "erro ao salvar" ? " error" : ""}`} role="status">
          {note}
        </span>
      </label>
      {multiline ? (
        <textarea id={fieldId} value={value} placeholder={placeholder} onChange={(e) => setValue(e.target.value)} onBlur={handleBlur} />
      ) : (
        <input id={fieldId} value={value} placeholder={placeholder} onChange={(e) => setValue(e.target.value)} onBlur={handleBlur} />
      )}
    </div>
  );
}
