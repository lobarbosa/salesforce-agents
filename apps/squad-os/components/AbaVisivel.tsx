"use client";

import { useEffect } from "react";
import { usePathname, useSearchParams } from "next/navigation";

// No celular a faixa de abas rola de lado, e a aba ativa podia ficar fora da
// tela (Demandas é a quarta para o time). A cada navegação, traz a aba ativa
// de cada faixa para a área visível, sem mexer na rolagem vertical da página.
export function AbaVisivel() {
  const pathname = usePathname();
  const busca = useSearchParams().toString();
  useEffect(() => {
    for (const ativa of document.querySelectorAll<HTMLElement>(".tabs .tab-btn.active")) {
      const faixa = ativa.closest<HTMLElement>(".tabs");
      if (!faixa || faixa.scrollWidth <= faixa.clientWidth) continue;
      faixa.scrollLeft = Math.max(0, ativa.offsetLeft - (faixa.clientWidth - ativa.offsetWidth) / 2);
    }
  }, [pathname, busca]);
  return null;
}
