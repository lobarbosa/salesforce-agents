"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { DemandaCompleta } from "@/lib/data";
import { DESCRICAO_MINIMA, erroDoRegistro, motivoSemEntregaManual } from "@/lib/entrega-manual";
import { acceptDo } from "@/lib/upload-regras";

// Entrega manual (lib/entrega-manual.ts): o consultor concluiu o trabalho
// fora da esteira. Registra o que fez e anexa a evidência; o card vai para a
// homologação do cliente. Só aparece para delivery, e só quando a API aceita
// (sem execução da esteira em andamento, card não encerrado nem congelado).
export function EntregaManual({ demanda, onClose }: { demanda: DemandaCompleta; onClose: () => void }) {
  const router = useRouter();
  const [aberto, setAberto] = useState(false);
  const [descricao, setDescricao] = useState("");
  const [arquivo, setArquivo] = useState<File | null>(null);
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");

  if (motivoSemEntregaManual(demanda)) return null;

  async function enviar() {
    const incompleto = erroDoRegistro(descricao, !!arquivo);
    if (incompleto) {
      setErro(incompleto);
      return;
    }
    setEnviando(true);
    setErro("");
    const corpo = new FormData();
    corpo.set("descricao", descricao);
    corpo.set("arquivo", arquivo as File);
    const res = await fetch(`/api/demandas/${demanda.id}/entrega-manual`, { method: "POST", body: corpo }).catch(() => null);
    setEnviando(false);
    if (!res?.ok) {
      const body = await res?.json().catch(() => ({}));
      setErro(body?.error || "não deu certo — tente de novo");
      return;
    }
    router.refresh();
    onClose();
  }

  if (!aberto) {
    return (
      <div className="ciclo-demanda">
        <button type="button" className="btn-secondary" onClick={() => setAberto(true)}>
          Entregar manualmente
        </button>
      </div>
    );
  }

  return (
    <div className="ciclo-demanda approval-banner pendente entrega-manual" role="group" aria-label="Registrar entrega manual">
      <div>
        Use quando o trabalho foi concluído por você, fora da esteira de agentes. O card vai para a homologação do
        cliente, que vê esta descrição e a evidência; só vira entregue quando ele aprovar.
      </div>
      <label className="field">
        O que foi feito e onde
        <textarea
          value={descricao}
          onChange={(e) => setDescricao(e.target.value)}
          rows={4}
          maxLength={4000}
          autoFocus
          aria-describedby={`entrega-ajuda-${demanda.id}`}
        />
      </label>
      <p id={`entrega-ajuda-${demanda.id}`} className="estimativa-nota">
        Pelo menos {DESCRICAO_MINIMA} caracteres. Não cole dado pessoal de cliente (CPF, e-mail, telefone).
      </p>
      <label className="field">
        Evidência (print ou documento)
        <input type="file" accept={acceptDo("anexo")} onChange={(e) => setArquivo(e.target.files?.[0] ?? null)} />
      </label>
      <p className="estimativa-nota">Obrigatória. Não anexe tela com registro real de cliente.</p>
      {erro && (
        <p className="auth-note error" role="alert">
          {erro}
        </p>
      )}
      <span className="confirmar-inline">
        <button
          type="button"
          className="btn-ghost"
          onClick={() => {
            setAberto(false);
            setErro("");
          }}
          disabled={enviando}
        >
          Voltar
        </button>
        <button type="button" className="btn-primary" onClick={enviar} disabled={enviando}>
          {enviando ? "Registrando..." : "Registrar entrega e enviar ao cliente"}
        </button>
      </span>
    </div>
  );
}
