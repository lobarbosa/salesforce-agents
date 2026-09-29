"use client";

import { useState } from "react";
import type { AmbienteOrg, Client, Contrato, Entregavel } from "@/lib/generated/prisma/client";
import type { MesDeHoras } from "@/lib/contrato";
import type { DemandaCompleta } from "@/lib/data";
import type { CurrentUsuario } from "@/lib/current-user";
import { ConhecimentoTab } from "@/components/ConhecimentoTab";
import { ConexaoTab } from "@/components/ConexaoTab";
import { ContratoTab } from "@/components/ContratoTab";
import { DemandasTab } from "@/components/DemandasTab";

type Tab = "conhecimento" | "contrato" | "conexao" | "demandas";

export function ClientDetail({
  client,
  demandas,
  usuario,
  horas,
  demandasPorEntregavel,
  initialTab,
  openDemandId,
}: {
  client: Client & {
    ambientes: AmbienteOrg[];
    contrato: (Contrato & { entregaveis: Entregavel[] }) | null;
  };
  horas: MesDeHoras[];
  demandasPorEntregavel: Record<string, { total: number; entregues: number }>;
  demandas: DemandaCompleta[];
  usuario: CurrentUsuario;
  initialTab?: Tab;
  openDemandId?: string;
}) {
  const podeGerenciarClientes = usuario.role !== "cliente";
  const [tab, setTab] = useState<Tab>(initialTab ?? (openDemandId || !podeGerenciarClientes ? "demandas" : "conhecimento"));

  // role=cliente vê tudo o que é do cliente dele, somente leitura: demandas,
  // contrato (quanto do balde de horas já foi, SLA, escopo entregue),
  // conhecimento com o assessment da org e a situação das conexões. As APIs
  // de escrita recusam o papel cliente (canManageClientData); aqui só não
  // mostramos controle que ele não pode usar.
  if (!podeGerenciarClientes) {
    return (
      <>
        <div className="client-header">
          <h1>{client.nome}</h1>
        </div>

        <div className="tabs">
          <button className={`tab-btn${tab === "demandas" ? " active" : ""}`} onClick={() => setTab("demandas")} type="button">
            Demandas
          </button>
          <button className={`tab-btn${tab === "contrato" ? " active" : ""}`} onClick={() => setTab("contrato")} type="button">
            Contrato
          </button>
          <button className={`tab-btn${tab === "conhecimento" ? " active" : ""}`} onClick={() => setTab("conhecimento")} type="button">
            Assessment e conhecimento
          </button>
          <button className={`tab-btn${tab === "conexao" ? " active" : ""}`} onClick={() => setTab("conexao")} type="button">
            Conexão Salesforce
          </button>
        </div>

        {tab === "demandas" && (
          <DemandasTab
            client={client}
            demandas={demandas}
            openDemandId={openDemandId}
            canManage={false}
            usuarioEmail={usuario.email}
            isAdmin={false}
            visaoCliente
          />
        )}
        {tab === "contrato" && (
          <ContratoTab
            clientId={client.id}
            clientNome={client.nome}
            contrato={client.contrato}
            horas={horas}
            demandasPorEntregavel={demandasPorEntregavel}
            canManage={false}
          />
        )}
        {tab === "conhecimento" && <ConhecimentoTab client={client} canManage={false} />}
        {tab === "conexao" && (
          <ConexaoTab clientId={client.id} clientSlug={client.slug} ambientes={client.ambientes} canManage={false} />
        )}
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
        <button className={`tab-btn${tab === "contrato" ? " active" : ""}`} onClick={() => setTab("contrato")} type="button">
          Contrato
        </button>
        <button className={`tab-btn${tab === "conexao" ? " active" : ""}`} onClick={() => setTab("conexao")} type="button">
          Conexão Salesforce
        </button>
        <button className={`tab-btn${tab === "demandas" ? " active" : ""}`} onClick={() => setTab("demandas")} type="button">
          Demandas
        </button>
      </div>

      {tab === "conhecimento" && <ConhecimentoTab client={client} canManage={podeGerenciarClientes} />}
      {tab === "contrato" && (
        <ContratoTab
          clientId={client.id}
          clientNome={client.nome}
          contrato={client.contrato}
          horas={horas}
          demandasPorEntregavel={demandasPorEntregavel}
          canManage={podeGerenciarClientes}
        />
      )}
      {tab === "conexao" && (
        <ConexaoTab clientId={client.id} clientSlug={client.slug} ambientes={client.ambientes} />
      )}
      {tab === "demandas" && (
        <DemandasTab
          client={client}
          demandas={demandas}
          openDemandId={openDemandId}
          canManage
          usuarioEmail={usuario.email}
          isAdmin={usuario.role === "admin"}
        />
      )}
    </>
  );
}
