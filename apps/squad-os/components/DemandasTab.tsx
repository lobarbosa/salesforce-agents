"use client";

import { useState, type DragEvent } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  TRIAGE,
  TRIAGE_LABEL,
  EXEC_STAGES,
  ESTADOS_CLIENTE,
  ESTADO_CLIENTE_LABEL,
  estadoDoCliente,
} from "@/lib/demandas";
import { DemandCard } from "@/components/DemandCard";
import { DemandModal } from "@/components/DemandModal";
import { NewDemandModal } from "@/components/NewDemandModal";

export function DemandasTab({
  client,
  demandas,
  openDemandId,
  canManage,
  usuarioEmail,
  isAdmin,
  visaoCliente = false,
}: {
  client: Client;
  demandas: DemandaCompleta[];
  openDemandId?: string;
  canManage: boolean;
  usuarioEmail: string;
  isAdmin: boolean;
  /** Quadro na lingua de quem esta do lado de fora — ver lib/demandas.ts. */
  visaoCliente?: boolean;
}) {
  const router = useRouter();
  const [newOpen, setNewOpen] = useState(false);
  const [openId, setOpenId] = useState<string | null>(openDemandId ?? null);
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [dragOverStatus, setDragOverStatus] = useState<string | null>(null);

  const byId = new Map(demandas.map((d) => [d.id, d]));
  const open = openId ? byId.get(openId) : null;

  async function handleMove(id: string, status: string) {
    const res = await fetch(`/api/demandas/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    });
    if (res.ok) router.refresh();
  }

  function clearDrag() {
    setDraggingId(null);
    setDragOverStatus(null);
  }

  // Drag-and-drop é um atalho pra quem prefere arrastar — a lista <select> em
  // cada card continua sendo o jeito sem arrastar de mudar a triagem (WCAG
  // 2.2 "Dragging Movements": nunca deixar arrastar como única forma).
  function dropHandlers(status: string) {
    return {
      onDragOver(e: DragEvent<HTMLDivElement>) {
        if (!draggingId) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = "move";
        if (dragOverStatus !== status) setDragOverStatus(status);
      },
      onDragLeave(e: DragEvent<HTMLDivElement>) {
        if (e.currentTarget.contains(e.relatedTarget as Node)) return;
        setDragOverStatus((cur) => (cur === status ? null : cur));
      },
      onDrop(e: DragEvent<HTMLDivElement>) {
        e.preventDefault();
        const id = e.dataTransfer.getData("text/plain") || draggingId;
        clearDrag();
        if (!id) return;
        const atual = byId.get(id);
        if (!atual || atual.status === status) return;
        handleMove(id, status);
      },
    };
  }

  const execItems = demandas.filter((d) => (EXEC_STAGES as readonly string[]).includes(d.status));
  const doneItems = demandas.filter((d) => d.status === "entregue");

  // Quadro do cliente: as mesmas demandas, nas quatro palavras que ele
  // reconhece. Ver ESTADOS_CLIENTE em lib/demandas.ts para o porquê de cada
  // uma. Sem triagem e sem arrastar — mover a esteira não é dele, e as colunas
  // de triagem só exporiam decisão interna de priorização.
  if (visaoCliente) {
    const porEstado = ESTADOS_CLIENTE.map((estado) => ({
      estado,
      items: demandas.filter((d) => estadoDoCliente(d.status) === estado),
    }));
    const suas = porEstado.find((c) => c.estado === "voce")!.items;

    return (
      <>
        {/* As colunas ficam na ordem cronológica, que é o que um quadro
            promete. Quem chama atenção para o que pede ação é este aviso —
            enterrar "precisa de você" na terceira coluna é o mesmo que não
            mostrar. */}
        {suas.length > 0 && (
          <div className="aviso-sua-vez" role="status">
            <strong>
              {suas.length === 1
                ? "1 demanda esperando a sua aprovação"
                : `${suas.length} demandas esperando a sua aprovação`}
            </strong>
            <span>Abra o cartão para ver o que foi entregue e aprovar.</span>
          </div>
        )}

        <div className="board">
          {porEstado.map(({ estado, items }) => (
            <div className={`column estado-${estado}`} key={estado}>
              <h3>
                {ESTADO_CLIENTE_LABEL[estado]}
                <span className="count">{items.length}</span>
              </h3>
              {items.length === 0 ? (
                <div className="empty-col">nenhuma</div>
              ) : (
                items.map((d) => (
                  <DemandCard
                    key={d.id}
                    demanda={d}
                    triageColumn={false}
                    visaoCliente
                    onOpen={() => setOpenId(d.id)}
                  />
                ))
              )}
            </div>
          ))}
        </div>

        {open && (
          <DemandModal
            demanda={open}
            canManage={canManage}
            usuarioEmail={usuarioEmail}
            isAdmin={isAdmin}
            visaoCliente
            onClose={() => setOpenId(null)}
          />
        )}
      </>
    );
  }

  return (
    <>
      <div className="board-toolbar">
        <span className="save-note">demandas de {client.nome}</span>
        <button className="btn-primary" type="button" onClick={() => setNewOpen(true)}>
          + nova demanda
        </button>
      </div>

      <div className="board">
        {TRIAGE.map((s) => {
          const items = demandas.filter((d) => d.status === s);
          return (
            <div
              className={`column${canManage && dragOverStatus === s ? " drag-over" : ""}`}
              key={s}
              {...(canManage ? dropHandlers(s) : {})}
            >
              <h3>
                {TRIAGE_LABEL[s]}
                <span className="count">{items.length}</span>
              </h3>
              {items.length === 0 ? (
                <div className="empty-col">sem demandas</div>
              ) : (
                items.map((d) => (
                  <DemandCard
                    key={d.id}
                    demanda={d}
                    triageColumn
                    canMove={canManage}
                    isDragging={d.id === draggingId}
                    onOpen={() => setOpenId(d.id)}
                    onMove={(status) => handleMove(d.id, status)}
                    onDragStart={setDraggingId}
                    onDragEnd={clearDrag}
                  />
                ))
              )}
            </div>
          );
        })}

        <div className="column exec">
          <h3>
            Em execução<span className="count">{execItems.length}</span>
          </h3>
          {execItems.length === 0 ? (
            <div className="empty-col">nenhuma em andamento</div>
          ) : (
            execItems.map((d) => <DemandCard key={d.id} demanda={d} triageColumn={false} onOpen={() => setOpenId(d.id)} />)
          )}
        </div>

        <div className="column done">
          <h3>
            Entregue<span className="count">{doneItems.length}</span>
          </h3>
          {doneItems.length === 0 ? (
            <div className="empty-col">nenhuma ainda</div>
          ) : (
            doneItems.map((d) => <DemandCard key={d.id} demanda={d} triageColumn={false} onOpen={() => setOpenId(d.id)} />)
          )}
        </div>
      </div>

      {open && (
        <DemandModal
          demanda={open}
          canManage={canManage}
          usuarioEmail={usuarioEmail}
          isAdmin={isAdmin}
          onClose={() => setOpenId(null)}
        />
      )}
      {newOpen && <NewDemandModal clientId={client.id} clientNome={client.nome} onClose={() => setNewOpen(false)} />}
    </>
  );
}
