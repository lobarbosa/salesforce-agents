"use client";

import { useState } from "react";
import type { AmbienteOrg, Client, Comentario, Demanda } from "@/lib/generated/prisma/client";
import type { CurrentUsuario } from "@/lib/current-user";
import { ConhecimentoTab } from "@/components/ConhecimentoTab";
import { ConexaoTab } from "@/components/ConexaoTab";
import { DemandasTab } from "@/components/DemandasTab";

type Tab = "conhecimento" | "conexao" | "demandas";

export function ClientDetail({
  client,
  demandas,
  usuario,
  initialTab,
  openDemandId,
}: {
  client: Client & { ambientes: AmbienteOrg[] };
  demandas: (Demanda & { comentarios: Comentario[] })[];
  usuario: CurrentUsuario;
  initialTab?: Tab;
  openDemandId?: string;
}) {
  const podeGerenciarClientes = usuario.role !== "cliente";
  const [tab, setTab] = useState<Tab>(podeGerenciarClientes ? initialTab ?? (openDemandId ? "demandas" : "conhecimento") : "demandas");

  // role=cliente só vê Demandas — Conhecimento/Conexão são dados internos de
  // delivery (avaliação da conta, credenciais de org), não algo que o
  // cliente final edita ou precisa ver.
  if (!podeGerenciarClientes) {
    return (
      <>
        <div className="client-header">
          <h1>{client.nome}</h1>
        </div>
        <DemandasTab client={client} demandas={demandas} openDemandId={openDemandId} canManage={false} />
      </>
    );
  }

  return (
    <>
      <div className="scope-note">
        <strong>Escopo deste OS:</strong> aqui nasce a demanda e vive o briefing do cliente. A
        execução (agentes, gates, deploy) roda no pipeline <code className="mono">sfagents</code>,
        materializado a partir daqui — estágios de execução aparecem como leitura, não são
        movidos por aqui.
      </div>

      <div className="client-header">
        <h1>
          {client.nome}
          <span className="seg">{client.segmento || "sem segmento definido"}</span>
        </h1>
      </div>

      <div className="tabs">
        <button className={`tab-btn${tab === "conhecimento" ? " active" : ""}`} onClick={() => setTab("conhecimento")} type="button">
          Conhecimento do Cliente
        </button>
        <button className={`tab-btn${tab === "conexao" ? " active" : ""}`} onClick={() => setTab("conexao")} type="button">
          Conexão Salesforce
        </button>
        <button className={`tab-btn${tab === "demandas" ? " active" : ""}`} onClick={() => setTab("demandas")} type="button">
          Demandas
        </button>
      </div>

      {tab === "conhecimento" && <ConhecimentoTab client={client} />}
      {tab === "conexao" && (
        <ConexaoTab clientId={client.id} clientSlug={client.slug} ambientes={client.ambientes} />
      )}
      {tab === "demandas" && (
        <DemandasTab client={client} demandas={demandas} openDemandId={openDemandId} canManage />
      )}
    </>
  );
}
