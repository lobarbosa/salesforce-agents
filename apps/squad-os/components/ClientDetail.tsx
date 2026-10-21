"use client";

import { navegarAbas } from "@/lib/abas";
import { useState } from "react";
import type { AmbienteOrg, Client, Contrato, Entregavel } from "@/lib/generated/prisma/client";
import type { MesDeHoras } from "@/lib/contrato";
import type { DemandaCompleta } from "@/lib/data";
import type { CurrentUsuario } from "@/lib/current-user";
import { ConhecimentoTab } from "@/components/ConhecimentoTab";
import { ConexaoTab } from "@/components/ConexaoTab";
import { ContratoTab } from "@/components/ContratoTab";
import { DemandasTab } from "@/components/DemandasTab";
import { AprovacoesTab } from "@/components/AprovacaoEstimativa";
import { aguardaAprovacaoEstimativa } from "@/lib/demandas";
import { Copiloto } from "@/components/Copiloto";
import { EncerradoBadge, EncerramentoCliente } from "@/components/EncerramentoCliente";

type Tab = "conhecimento" | "contrato" | "conexao" | "demandas" | "aprovacoes";

export function ClientDetail({
  client,
  demandas,
  usuario,
  horas,
  demandasPorEntregavel,
  initialTab,
  openDemandId,
  bloqueiosExclusao = [],
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
  /** Só para admin com cliente encerrado: o que impede a exclusão definitiva. */
  bloqueiosExclusao?: string[];
}) {
  const podeGerenciarClientes = usuario.role !== "cliente";
  const [tab, setTab] = useState<Tab>(initialTab ?? (openDemandId || !podeGerenciarClientes ? "demandas" : "conhecimento"));

  // role=cliente vê tudo o que é do cliente dele, somente leitura: demandas,
  // contrato (quanto do balde de horas já foi, SLA, escopo entregue),
  // conhecimento com o assessment da org e a situação das conexões. As APIs
  // de escrita recusam o papel cliente (canManageClientData); aqui só não
  // mostramos controle que ele não pode usar.
  if (!podeGerenciarClientes) {
    const aAprovar = demandas.filter(aguardaAprovacaoEstimativa).length;
    return (
      <>
        <div className="client-header">
          <h1>{client.nome}</h1>
        </div>

        <div className="tabs" role="tablist" onKeyDown={navegarAbas} aria-label={`Seções de ${client.nome}`}>
          <button
            className={`tab-btn${tab === "demandas" ? " active" : ""}`}
            onClick={() => setTab("demandas")}
            type="button"
            role="tab"
            id="tab-demandas"
            aria-selected={tab === "demandas"}
            tabIndex={tab === "demandas" ? 0 : -1}
            aria-controls="painel-demandas"
          >
            Demandas
          </button>
          <button
            className={`tab-btn${tab === "aprovacoes" ? " active" : ""}`}
            onClick={() => setTab("aprovacoes")}
            type="button"
            role="tab"
            id="tab-aprovacoes"
            aria-selected={tab === "aprovacoes"}
            tabIndex={tab === "aprovacoes" ? 0 : -1}
            aria-controls="painel-aprovacoes"
          >
            Aprovações
            {aAprovar > 0 && <span className="count" aria-label={`${aAprovar} esperando`}>{aAprovar}</span>}
          </button>
          <button
            className={`tab-btn${tab === "contrato" ? " active" : ""}`}
            onClick={() => setTab("contrato")}
            type="button"
            role="tab"
            id="tab-contrato"
            aria-selected={tab === "contrato"}
            tabIndex={tab === "contrato" ? 0 : -1}
            aria-controls="painel-contrato"
          >
            Contrato
          </button>
          <button
            className={`tab-btn${tab === "conhecimento" ? " active" : ""}`}
            onClick={() => setTab("conhecimento")}
            type="button"
            role="tab"
            id="tab-conhecimento"
            aria-selected={tab === "conhecimento"}
            tabIndex={tab === "conhecimento" ? 0 : -1}
            aria-controls="painel-conhecimento"
          >
            Assessment e conhecimento
          </button>
          <button
            className={`tab-btn${tab === "conexao" ? " active" : ""}`}
            onClick={() => setTab("conexao")}
            type="button"
            role="tab"
            id="tab-conexao"
            aria-selected={tab === "conexao"}
            tabIndex={tab === "conexao" ? 0 : -1}
            aria-controls="painel-conexao"
          >
            Conexão Salesforce
          </button>
        </div>

        {tab === "demandas" && (
          <div role="tabpanel" id="painel-demandas" aria-labelledby="tab-demandas">
            <DemandasTab
              client={client}
              demandas={demandas}
              openDemandId={openDemandId}
              canManage={false}
              usuarioEmail={usuario.email}
              isAdmin={false}
              visaoCliente
            />
          </div>
        )}
        {tab === "aprovacoes" && (
          <div role="tabpanel" id="painel-aprovacoes" aria-labelledby="tab-aprovacoes">
            <AprovacoesTab demandas={demandas} />
          </div>
        )}
        {tab === "contrato" && (
          <div role="tabpanel" id="painel-contrato" aria-labelledby="tab-contrato">
            <ContratoTab
              clientId={client.id}
              clientNome={client.nome}
              contrato={client.contrato}
              horas={horas}
              demandasPorEntregavel={demandasPorEntregavel}
              canManage={false}
            />
          </div>
        )}
        {tab === "conhecimento" && (
          <div role="tabpanel" id="painel-conhecimento" aria-labelledby="tab-conhecimento">
            <ConhecimentoTab client={client} canManage={false} />
          </div>
        )}
        {tab === "conexao" && (
          <div role="tabpanel" id="painel-conexao" aria-labelledby="tab-conexao">
            <ConexaoTab clientId={client.id} clientSlug={client.slug} ambientes={client.ambientes} canManage={false} />
          </div>
        )}

        {/* Ícone flutuante, não aba — fica alcançável em qualquer aba sem
            trocar de lugar (ver Copiloto.tsx). */}
        <Copiloto papel={usuario.role} clientId={client.id} clientNome={client.nome} />
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
          {client.encerradoEm && <EncerradoBadge encerradoEm={client.encerradoEm} />}
        </h1>
        {/* Encerrar é decisão do admin (lib/encerramento.ts) — a API confere de novo. */}
        {usuario.role === "admin" && !client.encerradoEm && (
          <div className="client-header-acoes">
            <EncerramentoCliente
              clientId={client.id}
              nome={client.nome}
              slug={client.slug}
              encerradoEm={null}
              encerradoPorEmail={null}
              motivoEncerramento=""
              bloqueiosExclusao={[]}
            />
          </div>
        )}
      </div>

      {usuario.role === "admin" && client.encerradoEm && (
        <EncerramentoCliente
          clientId={client.id}
          nome={client.nome}
          slug={client.slug}
          encerradoEm={client.encerradoEm}
          encerradoPorEmail={client.encerradoPorEmail}
          motivoEncerramento={client.motivoEncerramento}
          bloqueiosExclusao={bloqueiosExclusao}
        />
      )}

      <div className="tabs" role="tablist" onKeyDown={navegarAbas} aria-label={`Seções de ${client.nome}`}>
        <button
          className={`tab-btn${tab === "conhecimento" ? " active" : ""}`}
          onClick={() => setTab("conhecimento")}
          type="button"
          role="tab"
          id="tab-conhecimento"
          aria-selected={tab === "conhecimento"}
            tabIndex={tab === "conhecimento" ? 0 : -1}
          aria-controls="painel-conhecimento"
        >
          Conhecimento do Cliente
        </button>
        <button
          className={`tab-btn${tab === "contrato" ? " active" : ""}`}
          onClick={() => setTab("contrato")}
          type="button"
          role="tab"
          id="tab-contrato"
          aria-selected={tab === "contrato"}
            tabIndex={tab === "contrato" ? 0 : -1}
          aria-controls="painel-contrato"
        >
          Contrato
        </button>
        <button
          className={`tab-btn${tab === "conexao" ? " active" : ""}`}
          onClick={() => setTab("conexao")}
          type="button"
          role="tab"
          id="tab-conexao"
          aria-selected={tab === "conexao"}
            tabIndex={tab === "conexao" ? 0 : -1}
          aria-controls="painel-conexao"
        >
          Conexão Salesforce
        </button>
        <button
          className={`tab-btn${tab === "demandas" ? " active" : ""}`}
          onClick={() => setTab("demandas")}
          type="button"
          role="tab"
          id="tab-demandas"
          aria-selected={tab === "demandas"}
            tabIndex={tab === "demandas" ? 0 : -1}
          aria-controls="painel-demandas"
        >
          Demandas
        </button>
      </div>

      {tab === "conhecimento" && (
        <div role="tabpanel" id="painel-conhecimento" aria-labelledby="tab-conhecimento">
          <ConhecimentoTab client={client} canManage={podeGerenciarClientes} />
        </div>
      )}
      {tab === "contrato" && (
        <div role="tabpanel" id="painel-contrato" aria-labelledby="tab-contrato">
          <ContratoTab
            clientId={client.id}
            clientNome={client.nome}
            contrato={client.contrato}
            horas={horas}
            demandasPorEntregavel={demandasPorEntregavel}
            canManage={podeGerenciarClientes}
          />
        </div>
      )}
      {tab === "conexao" && (
        <div role="tabpanel" id="painel-conexao" aria-labelledby="tab-conexao">
          <ConexaoTab clientId={client.id} clientSlug={client.slug} ambientes={client.ambientes} />
        </div>
      )}
      {tab === "demandas" && (
        <div role="tabpanel" id="painel-demandas" aria-labelledby="tab-demandas">
          <DemandasTab
            client={client}
            demandas={demandas}
            openDemandId={openDemandId}
            canManage
            usuarioEmail={usuario.email}
            isAdmin={usuario.role === "admin"}
          />
        </div>
      )}

      {/* Admin/consultor também ganham o copiloto aqui — mesmo ícone do
          papel cliente, escopo nas demandas/contrato DESTE cliente (ver
          Copiloto.tsx). Admin ainda tem acesso ao financeiro dentro dele. */}
      <Copiloto papel={usuario.role} clientId={client.id} clientNome={client.nome} />
    </>
  );
}
