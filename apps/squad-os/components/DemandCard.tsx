"use client";

import type { Demanda } from "@/lib/generated/prisma/client";
import { TRIAGE, TRIAGE_LABEL, STAGE_LABEL, perguntasPendentes, timeAgo } from "@/lib/demandas";

function StageChip({ status }: { status: string }) {
  if (status === "aguardando_gate_design") return <span className="badge gate">gate bloqueante</span>;
  if (status.startsWith("aguardando")) return <span className="badge gate">{STAGE_LABEL[status] ?? status}</span>;
  return <span className="badge stage">{STAGE_LABEL[status] ?? status}</span>;
}

function ApprovalBadge({ demanda }: { demanda: Demanda }) {
  const pendentes = perguntasPendentes(demanda.perguntas);
  if (pendentes > 0) {
    return <span className="badge pendente">❓ {pendentes} pendente{pendentes > 1 ? "s" : ""}</span>;
  }
  const aprovacao = demanda.aprovacao as { aprovado?: boolean } | null;
  if (aprovacao?.aprovado) return <span className="badge aprovado">✓ aprovado</span>;
  if (Array.isArray(demanda.perguntas) && demanda.perguntas.length > 0) {
    return <span className="badge pendente">aguardando aprovação</span>;
  }
  return null;
}

export function DemandCard({
  demanda,
  triageColumn,
  onOpen,
  onMove,
}: {
  demanda: Demanda;
  triageColumn: boolean;
  onOpen: () => void;
  onMove?: (status: string) => void;
}) {
  return (
    <div
      className="card"
      tabIndex={0}
      role="button"
      aria-label={`Abrir demanda ${demanda.titulo}`}
      onClick={onOpen}
      onKeyDown={(e) => {
        if (e.target !== e.currentTarget) return;
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onOpen();
        }
      }}
    >
      <div className="titulo">{demanda.titulo}</div>
      <div className="meta">
        <span className={`badge ${demanda.tipo === "projeto" ? "projeto" : "sustentacao"}`}>
          {demanda.tipo === "projeto" ? "projeto" : "sustentação"}
        </span>
        {!triageColumn && <StageChip status={demanda.status} />}
        <ApprovalBadge demanda={demanda} />
        <span>{demanda.autor}</span>
        <span>{timeAgo(demanda.criadoEm)}</span>
      </div>
      {triageColumn ? (
        <select
          className="move"
          value={demanda.status}
          onClick={(e) => e.stopPropagation()}
          onChange={(e) => {
            e.stopPropagation();
            onMove?.(e.target.value);
          }}
        >
          {TRIAGE.map((s) => (
            <option key={s} value={s}>
              {TRIAGE_LABEL[s]}
            </option>
          ))}
        </select>
      ) : (
        <span className="readonly-note">avança via sfagents</span>
      )}
    </div>
  );
}
