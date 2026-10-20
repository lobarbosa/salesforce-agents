"use client";

import { useEffect, useId, useRef, type ReactNode } from "react";

// Porta o padrão de openModal() da versão Artifact: fecha com Escape, fecha
// ao clicar no backdrop, foca o diálogo ao abrir, e dá nome acessível ao
// dialog via aria-labelledby (achado da revisão UI/UX Pro Max — dialog sem
// aria-labelledby não tem nome anunciado por leitor de tela).
export function Modal({
  title,
  onClose,
  wide,
  children,
}: {
  title: string;
  onClose: () => void;
  wide?: boolean;
  children: ReactNode;
}) {
  const titleId = useId();
  const dialogRef = useRef<HTMLDivElement>(null);

  // `onClose` costuma ser uma função nova a cada render do pai; com ela na lista
  // de dependências o efeito rodava a cada tecla digitada num campo do modal e
  // devolvia o foco ao diálogo (achado da revisão UI/UX: no Encerrar cliente só
  // dava para digitar um caractere). A ref guarda a mais recente; o efeito roda
  // uma vez: foca ao abrir, prende o Tab dentro do diálogo e devolve o foco a
  // quem abriu ao fechar.
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  });

  useEffect(() => {
    const anterior = document.activeElement as HTMLElement | null;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onCloseRef.current();
      if (e.key !== "Tab" || !dialogRef.current) return;
      const focaveis = dialogRef.current.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
      );
      if (focaveis.length === 0) return;
      const primeiro = focaveis[0];
      const ultimo = focaveis[focaveis.length - 1];
      if (e.shiftKey && (document.activeElement === primeiro || document.activeElement === dialogRef.current)) {
        e.preventDefault();
        ultimo.focus();
      } else if (!e.shiftKey && document.activeElement === ultimo) {
        e.preventDefault();
        primeiro.focus();
      }
    }
    document.addEventListener("keydown", onKey);
    // Campo com autoFocus dentro do modal já recebeu o foco: não roubar.
    if (!dialogRef.current?.contains(document.activeElement)) dialogRef.current?.focus();
    return () => {
      document.removeEventListener("keydown", onKey);
      if (anterior?.isConnected) anterior.focus();
    };
  }, []);

  return (
    <div
      className="modal-backdrop"
      onClick={(e) => {
        if (e.target === e.currentTarget) onCloseRef.current();
      }}
    >
      <div
        className={`modal${wide ? " wide" : ""}`}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        ref={dialogRef}
      >
        <h3 id={titleId}>{title}</h3>
        {children}
      </div>
    </div>
  );
}
