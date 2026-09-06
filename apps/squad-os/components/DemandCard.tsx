"use client";

import { useRef, type DragEvent } from "react";
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
  canMove,
  isDragging,
  onOpen,
  onMove,
  onDragStart,
  onDragEnd,
}: {
  demanda: Demanda;
  triageColumn: boolean;
  canMove?: boolean;
  isDragging?: boolean;
  onOpen: () => void;
  onMove?: (status: string) => void;
  onDragStart?: (id: string) => void;
  onDragEnd?: () => void;
}) {
  const podeArrastar = triageColumn && canMove;
  // Depois de um drop, alguns navegadores ainda despacham um click no card de
  // origem (mouseup da mesma interação) — sem essa guarda, soltar o card
  // reabre o modal de detalhe por cima. dragend limpa a guarda logo em
  // seguida (setTimeout 0), só depois de qualquer click da mesma interação já
  // ter sido processado.
  const acabouDeArrastar = useRef(false);

  function handleDragStart(e: DragEvent<HTMLDivElement>) {
    e.dataTransfer.setData("text/plain", demanda.id);
    e.dataTransfer.effectAllowed = "move";
    acabouDeArrastar.current = true;
    onDragStart?.(demanda.id);
  }

  function handleDragEnd() {
    onDragEnd?.();
    setTimeout(() => {
      acabouDeArrastar.current = false;
    }, 0);
  }

  function handleClick() {
    if (acabouDeArrastar.current) {
      acabouDeArrastar.current = false;
      return;
    }
    onOpen();
  }

  return (
    <div
      className={`card${isDragging ? " dragging" : ""}`}
      tabIndex={0}
      role="button"
      aria-label={`Abrir demanda ${demanda.titulo}`}
      draggable={podeArrastar}
      onDragStart={podeArrastar ? handleDragStart : undefined}
      onDragEnd={podeArrastar ? handleDragEnd : undefined}
      onClick={handleClick}
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
      {triageColumn && canMove ? (
        <>
          {podeArrastar && <span className="drag-handle" aria-hidden="true">⠿ arraste ou use a lista</span>}
          <select
            className="move"
            value={demanda.status}
            onClick={(e) => e.stopPropagation()}
            onPointerDown={(e) => e.stopPropagation()}
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
        </>
      ) : triageColumn ? (
        <span className="readonly-note">{TRIAGE_LABEL[demanda.status] ?? demanda.status}</span>
      ) : (
        <span className="readonly-note">avança via sfagents</span>
      )}
    </div>
  );
}
