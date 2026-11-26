"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { nomeDoDono, type PessoaDoTime } from "@/lib/dono";

/**
 * Dono da demanda no modal (lib/dono.ts). O time troca pelo seletor; o
 * cliente só lê o nome. A troca vale em qualquer etapa: não mexe na esteira.
 */
export function DonoDaDemanda({
  demandaId,
  dono,
  equipe,
  canManage,
}: {
  demandaId: string;
  dono: { id: string; nome: string; email: string } | null;
  equipe: PessoaDoTime[];
  canManage: boolean;
}) {
  const router = useRouter();
  const [valor, setValor] = useState(dono?.id ?? "");
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState("");

  if (!canManage) {
    return dono ? (
      <span className="dono-leitura">
        Responsável: <strong>{nomeDoDono(dono)}</strong>
      </span>
    ) : null;
  }

  // O dono atual pode ter saído do time (papel trocado): continua na lista
  // para a tela não mostrar outra pessoa no lugar dele.
  const opcoes = dono && !equipe.some((p) => p.id === dono.id) ? [...equipe, dono] : equipe;

  async function trocar(novo: string) {
    const anterior = valor;
    setValor(novo);
    setSalvando(true);
    setErro("");
    const res = await fetch(`/api/demandas/${demandaId}/dono`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ donoId: novo || null }),
    }).catch(() => null);
    setSalvando(false);
    if (!res || !res.ok) {
      const body = res ? await res.json().catch(() => ({})) : {};
      setValor(anterior);
      setErro(body.error || "não deu para trocar o dono");
      return;
    }
    router.refresh();
  }

  return (
    <span className="dono-campo">
      <label htmlFor={`dono-${demandaId}`}>Dono</label>
      <select
        id={`dono-${demandaId}`}
        className={valor ? "" : "sem-dono"}
        value={valor}
        disabled={salvando}
        onChange={(e) => trocar(e.target.value)}
      >
        <option value="">sem dono</option>
        {opcoes.map((p) => (
          <option key={p.id} value={p.id}>
            {nomeDoDono(p)}
          </option>
        ))}
      </select>
      {erro && (
        <span className="auth-note error" role="alert">
          {erro}
        </span>
      )}
    </span>
  );
}
