import type { KeyboardEvent } from "react";

/**
 * Teclado do padrão ARIA de abas: setas esquerda/direita, Home e End movem o
 * foco entre as abas do `role="tablist"` e ativam a aba (clicando nela). Junto
 * com `tabIndex={selecionada ? 0 : -1}` em cada aba, o Tab entra só na aba ativa
 * e sai direto para o painel — antes cada aba era uma parada de Tab e as setas
 * não faziam nada (achado da revisão UI/UX).
 */
export function navegarAbas(e: KeyboardEvent<HTMLElement>) {
  const abas = Array.from(e.currentTarget.querySelectorAll<HTMLElement>('[role="tab"]'));
  const atual = abas.indexOf(document.activeElement as HTMLElement);
  if (atual < 0 || abas.length === 0) return;
  const destino =
    e.key === "ArrowRight" ? (atual + 1) % abas.length
    : e.key === "ArrowLeft" ? (atual - 1 + abas.length) % abas.length
    : e.key === "Home" ? 0
    : e.key === "End" ? abas.length - 1
    : null;
  if (destino === null) return;
  e.preventDefault();
  abas[destino].focus();
  abas[destino].click();
}
