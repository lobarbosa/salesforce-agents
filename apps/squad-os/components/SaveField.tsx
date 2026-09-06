"use client";

import { useRef, useState } from "react";

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
}: {
  label: string;
  value: string;
  multiline?: boolean;
  placeholder?: string;
  full?: boolean;
  onSave: (value: string) => Promise<boolean>;
}) {
  const [value, setValue] = useState(initialValue);
  const [note, setNote] = useState<"" | "salvo" | "erro ao salvar">("");
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  async function handleBlur() {
    if (value === initialValue) return;
    const ok = await onSave(value);
    setNote(ok ? "salvo" : "erro ao salvar");
    if (timer.current) clearTimeout(timer.current);
    if (ok) timer.current = setTimeout(() => setNote(""), 1600);
  }

  return (
    <div className={`brief-field${full ? " full" : ""}`}>
      <label>
        {label}
        <span className={`save-note${note === "salvo" ? " saved" : note === "erro ao salvar" ? " error" : ""}`} role="status">
          {note}
        </span>
      </label>
      {multiline ? (
        <textarea value={value} placeholder={placeholder} onChange={(e) => setValue(e.target.value)} onBlur={handleBlur} />
      ) : (
        <input value={value} placeholder={placeholder} onChange={(e) => setValue(e.target.value)} onBlur={handleBlur} />
      )}
    </div>
  );
}
