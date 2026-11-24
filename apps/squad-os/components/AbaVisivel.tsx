"use client";

import { useEffect } from "react";
import { usePathname, useSearchParams } from "next/navigation";

// Ajustes de tela que dependem do que já foi desenhado (2026-11-24).
//
// 1. Abas: no celular a faixa rola de lado e a aba ativa podia ficar fora da
//    tela (Demandas é a quarta para o time). A cada navegação, a aba ativa de
//    cada faixa vem para a área visível, sem mexer na rolagem da página.
// 2. Tabelas: no celular toda `.tabela` vira lista de cartões (globals.css,
//    `.tabela-cartoes`). O rótulo de cada célula sai do cabeçalho da coluna e
//    é escrito em `data-rotulo` aqui, uma vez para todas as tabelas, em vez de
//    repetir o texto do cabeçalho célula por célula em cada página. Tabela de
//    markdown (artefato de agente) fica de fora: ali as colunas são livres.
function rotularTabelas() {
  for (const tabela of document.querySelectorAll<HTMLTableElement>("table.tabela")) {
    tabela.classList.add("tabela-cartoes");
    const rotulos = [...tabela.querySelectorAll("thead th")].map((th) => th.textContent?.trim() ?? "");
    if (rotulos.length === 0) continue;
    for (const linha of tabela.querySelectorAll("tbody tr, tfoot tr")) {
      [...linha.children].forEach((celula, i) => {
        if (celula.tagName !== "TD" || celula.hasAttribute("data-rotulo")) return;
        if ((celula as HTMLTableCellElement).colSpan > 1 || !rotulos[i]) return;
        celula.setAttribute("data-rotulo", rotulos[i]);
      });
    }
  }
}

export function AbaVisivel() {
  const pathname = usePathname();
  const busca = useSearchParams().toString();

  useEffect(() => {
    const faixas = [...document.querySelectorAll<HTMLElement>(".tabs")];
    // Esmaece a borda direita só enquanto há aba escondida daquele lado.
    const marcar = (faixa: HTMLElement) =>
      faixa.classList.toggle("tem-mais", faixa.scrollLeft + faixa.clientWidth < faixa.scrollWidth - 4);
    const aoRolar = (e: Event) => marcar(e.currentTarget as HTMLElement);
    for (const faixa of faixas) {
      const ativa = faixa.querySelector<HTMLElement>(".tab-btn.active");
      if (ativa && faixa.scrollWidth > faixa.clientWidth) {
        faixa.scrollLeft = Math.max(0, ativa.offsetLeft - (faixa.clientWidth - ativa.offsetWidth) / 2);
      }
      marcar(faixa);
      faixa.addEventListener("scroll", aoRolar, { passive: true });
    }
    return () => faixas.forEach((f) => f.removeEventListener("scroll", aoRolar));
  }, [pathname, busca]);

  // As linhas mudam sem navegação (filtro, recarga automática, lançamento):
  // o observador rotula o que entrar depois.
  useEffect(() => {
    rotularTabelas();
    const alvo = document.querySelector("main") ?? document.body;
    let agendado = 0;
    const obs = new MutationObserver(() => {
      if (agendado) return;
      agendado = requestAnimationFrame(() => {
        agendado = 0;
        rotularTabelas();
      });
    });
    obs.observe(alvo, { childList: true, subtree: true });
    return () => {
      obs.disconnect();
      if (agendado) cancelAnimationFrame(agendado);
    };
  }, []);

  return null;
}
