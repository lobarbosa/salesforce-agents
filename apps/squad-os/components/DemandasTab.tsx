"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  FASES,
  ESTADOS_CLIENTE,
  ESTADO_CLIENTE_LABEL,
  estaEmGate,
  estadoDoCliente,
  quemDestrava,
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

  // O que a esteira está esperando de gente, agora. É a única pergunta que o
  // quadro precisa responder de relance — o resto ele responde com as colunas.
  const paradas = demandas.filter((d) => estaEmGate(d.status));
  const resumoDasParadas = [
    ...new Map(
      paradas.map((d) => [quemDestrava(d.status), quemDestrava(d.status)])
    ).keys(),
  ]
    .filter(Boolean)
    .join(", ");

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

      {paradas.length > 0 && (
        <div className="aviso-parado" role="status">
          <strong>
            {paradas.length === 1
              ? "1 demanda parada esperando gente"
              : `${paradas.length} demandas paradas esperando gente`}
          </strong>
          <span>{resumoDasParadas}</span>
        </div>
      )}

      <div className="board board-fases">
        {FASES.map((fase) => {
          const items = demandas.filter((d) => fase.estagios.includes(d.status));
          const parados = items.filter((d) => estaEmGate(d.status)).length;
          const ehTriagem = fase.chave === "triagem";
          return (
            <div
              className={`column fase-${fase.chave}${parados > 0 ? " tem-parada" : ""}`}
              key={fase.chave}
            >
              <h3>
                {fase.titulo}
                <span className="count">{items.length}</span>
              </h3>
              {/* Quantos estão travados nesta fase. Só aparece quando há —
                  um "0 parada" em toda coluna seria ruído constante. */}
              {parados > 0 && (
                <span className="fase-parados">
                  {parados === 1 ? "1 esperando gente" : `${parados} esperando gente`}
                </span>
              )}
              {items.length === 0 ? (
                <div className="empty-col">{ehTriagem ? "sem demandas" : "nenhuma aqui"}</div>
              ) : (
                items.map((d) => (
                  <DemandCard
                    key={d.id}
                    demanda={d}
                    triageColumn={ehTriagem}
                    faseVisivel
                    canMove={canManage && ehTriagem}
                    onOpen={() => setOpenId(d.id)}
                    onMove={(status) => handleMove(d.id, status)}
                  />
                ))
              )}
            </div>
          );
        })}
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
