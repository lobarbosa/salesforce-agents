"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

// Nada nesta tela se atualiza sozinho por padrão: o estado real chega ao banco
// por uma rota de sync que o GitHub Actions chama, e a aba aberta de quem está
// esperando não fica sabendo. Foi o que aconteceu em 2026-09-13 — a conexão da
// Konecta virou "conectado" no banco e a tela seguiu dizendo "aguardando" até
// alguém apertar F5, o que ninguém faz enquanto acha que ainda está rodando.
//
// `router.refresh()` re-executa o Server Component e traz o estado novo sem
// perder o que o usuário digitou nos campos — é a forma barata de "tempo real"
// aqui: não há socket, e não precisa haver para um job de minutos.

const INTERVALO_MS = 8000;

/** Re-busca o estado do servidor enquanto `ativo` for verdadeiro.
 *
 * Só roda com a aba visível. Uma aba esquecida em segundo plano não tem quem
 * leia o resultado, e o pool do Postgres é pequeno demais (lição de
 * 2026-09-13) pra gastar conexão com tela que ninguém está olhando.
 */
export function useAutoRefresh(ativo: boolean, intervaloMs: number = INTERVALO_MS): void {
  const router = useRouter();

  useEffect(() => {
    if (!ativo) return;

    const id = setInterval(() => {
      if (document.visibilityState === "visible") router.refresh();
    }, intervaloMs);

    // Voltar pra aba é o momento em que a pessoa mais quer o estado atual —
    // esperar o próximo tick faria a tela abrir mostrando o passado.
    const aoVoltar = () => {
      if (document.visibilityState === "visible") router.refresh();
    };
    document.addEventListener("visibilitychange", aoVoltar);

    return () => {
      clearInterval(id);
      document.removeEventListener("visibilitychange", aoVoltar);
    };
  }, [ativo, intervaloMs, router]);
}
