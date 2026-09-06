"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client, Demanda } from "@/lib/generated/prisma/client";
import { TRIAGE, TRIAGE_LABEL, EXEC_STAGES } from "@/lib/demandas";
import { DemandCard } from "@/components/DemandCard";
import { DemandModal } from "@/components/DemandModal";
import { NewDemandModal } from "@/components/NewDemandModal";

export function DemandasTab({
  client,
  demandas,
  openDemandId,
}: {
  client: Client;
  demandas: Demanda[];
  openDemandId?: string;
}) {
  const router = useRouter();
  const [newOpen, setNewOpen] = useState(false);
  const [openId, setOpenId] = useState<string | null>(openDemandId ?? null);

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

  const execItems = demandas.filter((d) => (EXEC_STAGES as readonly string[]).includes(d.status));
  const doneItems = demandas.filter((d) => d.status === "entregue");

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
            <div className="column" key={s}>
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
                    onOpen={() => setOpenId(d.id)}
                    onMove={(status) => handleMove(d.id, status)}
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

      {open && <DemandModal demanda={open} onClose={() => setOpenId(null)} />}
      {newOpen && <NewDemandModal clientId={client.id} clientNome={client.nome} onClose={() => setNewOpen(false)} />}
    </>
  );
}
