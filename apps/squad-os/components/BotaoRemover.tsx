"use client";

import { useState } from "react";

/**
 * "remover" em dois passos: o primeiro clique troca o botão por "Manter /
 * Remover" (mesmo padrão `.confirmar-inline` de Documentos da contabilidade).
 * Antes cada "remover" apagava na hora, a um toque do checkbox ao lado
 * (achado da revisão UI/UX). O foco vai para "Manter", a opção segura.
 */
export function BotaoRemover({
  nome,
  aviso,
  disabled,
  onRemover,
}: {
  /** O que será removido, para o rótulo acessível ("Remover subtarefa X"). */
  nome: string;
  /** Consequência curta, mostrada ao confirmar. */
  aviso?: string;
  disabled?: boolean;
  onRemover: () => void | Promise<unknown>;
}) {
  const [confirmando, setConfirmando] = useState(false);
  if (!confirmando) {
    return (
      <button type="button" className="btn-remover" disabled={disabled} aria-label={`Remover ${nome}`} onClick={() => setConfirmando(true)}>
        remover
      </button>
    );
  }
  return (
    <span className="confirmar-inline" role="group" aria-label={`Confirmar remoção de ${nome}`}>
      {aviso && <span className="sub">{aviso}</span>}
      <button type="button" className="btn-ghost" autoFocus onClick={() => setConfirmando(false)}>
        Manter
      </button>
      <button
        type="button"
        className="btn-perigo"
        disabled={disabled}
        onClick={async () => {
          await onRemover();
          setConfirmando(false);
        }}
      >
        Remover
      </button>
    </span>
  );
}
