"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  FASES,
  agenteRodando,
  estaEmGate,
  quemDestrava,
  acoesPendentes,
  estadoDoClienteDemanda,
  type QuemAge,
  motivoSemDrop,
  gateLiberadoPor,
} from "@/lib/demandas";
import { Modal } from "@/components/Modal";
import { useAutoRefresh } from "@/lib/auto-refresh";
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
  // Filtro de "quem age" (2026-10-29): responde "o que é meu agora?" sem ler
  // o quadro inteiro. Esconde os cards; as colunas ficam, para não mudar o mapa.
  const [filtroQuem, setFiltroQuem] = useState<"" | QuemAge>("");
  const [openId, setOpenId] = useState<string | null>(openDemandId ?? null);

  const byId = new Map(demandas.map((d) => [d.id, d]));
  const open = openId ? byId.get(openId) : null;

  // Enquanto um agente estiver rodando alguma etapa, o estado do quadro muda
  // por fora — quem escreve é o workflow, via /api/sync/demanda. Sem isto a
  // aba aberta congela no estágio em que estava quando carregou, e quem está
  // esperando o gate aparecer fica dando F5 (ou, pior, conclui que travou).
  // Parado em gate não recarrega: ali não vem nada, quem tem que agir é gente.
  useAutoRefresh(demandas.some((d) => agenteRodando(d.status) || gateLiberadoPor(d) !== null));

  // Arrastar (2026-10-21) é atalho com confirmação, não um jeito de mover a
  // esteira: Backlog → Análise = enviar para a esteira; qualquer card parado
  // → Entregue/cancelada = cancelar. As outras colunas só andam por gate.
  const [arrastandoId, setArrastandoId] = useState<string | null>(null);
  const [alvo, setAlvo] = useState<string | null>(null);
  const [aviso, setAviso] = useState("");
  const [pendente, setPendente] = useState<{ id: string; acao: "enviar" | "cancelar" } | null>(null);
  const arrastando = arrastandoId ? byId.get(arrastandoId) : null;

  function soltar(fase: string) {
    const d = arrastando;
    setArrastandoId(null);
    setAlvo(null);
    if (!d || fase === FASES.find((f) => f.estagios.includes(d.status))?.chave) return;
    const motivo = motivoSemDrop(d, fase);
    if (motivo) {
      setAviso(motivo);
      return;
    }
    setPendente({ id: d.id, acao: fase === "analise" ? "enviar" : "cancelar" });
  }

  async function handleMove(id: string, status: string) {
    const res = await fetch(`/api/demandas/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    }).catch(() => null);
    // 409 = a demanda saiu da triagem por baixo (o pipeline moveu): o
    // refresh mostra onde ela está de verdade.
    if (!res) {
      setAviso("sem conexão com o servidor — a demanda não foi movida");
    } else if (!res.ok) {
      const corpo = await res.json().catch(() => ({}));
      setAviso(corpo.error || "não consegui mover a demanda");
    }
    router.refresh();
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
    // Quatro colunas na ordem do trabalho; pausada e cancelada saem para a
    // faixa de baixo — eram duas colunas quase sempre vazias. "Sua vez" junta
    // homologar e aprovar horas: as duas são a mesma pergunta para ele.
    const COLUNAS_CLIENTE = ["recebida", "andamento", "voce", "entregue"] as const;
    const porEstado = COLUNAS_CLIENTE.map((estado) => ({
      estado,
      items: demandas.filter((d) => estadoDoClienteDemanda(d) === estado),
    }));
    const suas = porEstado.find((c) => c.estado === "voce")!.items;
    const homologar = suas.filter((d) => d.status === "aguardando_homologacao").length;
    const horas = suas.length - homologar;
    const paradasCliente = demandas.filter((d) => ["pausada", "cancelada"].includes(estadoDoClienteDemanda(d)));
    const TITULO_CLIENTE: Record<string, string> = {
      recebida: "Recebidas",
      andamento: "Em andamento",
      voce: "Sua vez",
      entregue: "Entregues",
    };
    const AJUDA_CLIENTE: Record<string, string> = {
      recebida: "A equipe ainda vai começar.",
      andamento: "A equipe está cuidando; nada para você fazer.",
      voce: "Precisa de você para seguir.",
      entregue: "Concluídas.",
    };

    return (
      <>
        {/* Pedir também é coisa do cliente, não só acompanhar. A demanda nasce
            em `backlog` e continua sendo o time quem decide o que entra. */}
        <div className="board-toolbar">
          <span className="save-note">suas demandas em {client.nome}</span>
          <button className="btn-primary" type="button" onClick={() => setNewOpen(true)}>
            + nova demanda
          </button>
        </div>

        {suas.length > 0 && (
          <div className="aviso-sua-vez" role="status">
            <strong>
              {suas.length === 1 ? "1 demanda precisa de você" : `${suas.length} demandas precisam de você`}
            </strong>
            <span>
              {[
                homologar > 0 && `${homologar} para conferir e homologar`,
                horas > 0 && `${horas} estimativa${horas > 1 ? "s" : ""} de horas para aprovar (aba Aprovações)`,
              ]
                .filter(Boolean)
                .join(" · ")}
            </span>
          </div>
        )}

        <div className="board board-cliente">
          {porEstado.map(({ estado, items }) => (
            <div className={`column estado-${estado}${items.length === 0 ? " vazia" : ""}`} key={estado}>
              <h3>
                {TITULO_CLIENTE[estado]}
                <span className="count">{items.length}</span>
              </h3>
              <p className="column-ajuda">{AJUDA_CLIENTE[estado]}</p>
              {items.length === 0 ? (
                <div className="empty-col">nenhuma</div>
              ) : (
                items.map((d) => (
                  <DemandCard key={d.id} demanda={d} triageColumn={false} visaoCliente onOpen={() => setOpenId(d.id)} />
                ))
              )}
            </div>
          ))}
        </div>

        {paradasCliente.length > 0 && (
          <details className="faixa-paradas">
            <summary>
              Pausadas e canceladas <span className="count">{paradasCliente.length}</span>
            </summary>
            <div className="faixa-cards">
              {paradasCliente.map((d) => (
                <DemandCard key={d.id} demanda={d} triageColumn={false} visaoCliente onOpen={() => setOpenId(d.id)} />
              ))}
            </div>
          </details>
        )}

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
        {newOpen && (
          <NewDemandModal clientId={client.id} clientNome={client.nome} onClose={() => setNewOpen(false)} />
        )}
      </>
    );
  }

  // Contagem por dono para os filtros (uma demanda pode contar em dois:
  // design esperando o arquiteto E o cliente nas horas).
  const quemDe = (d: (typeof demandas)[number]) => acoesPendentes(d).map((a) => a.quem);
  const contagem = (q: QuemAge) => demandas.filter((d) => quemDe(d).includes(q)).length;
  const passaFiltro = (d: (typeof demandas)[number]) => !filtroQuem || quemDe(d).includes(filtroQuem);
  const congeladas = demandas.filter((d) => d.status === "standby");
  const FILTROS: { q: QuemAge; rotulo: string }[] = [
    { q: "time", rotulo: "Ação do time" },
    { q: "cliente", rotulo: "Ação do cliente" },
    { q: "agente", rotulo: "Agente rodando" },
    { q: "fila", rotulo: "Na fila" },
  ];

  return (
    <>
      <div className="board-toolbar">
        <span className="save-note">demandas de {client.nome}</span>
        {/* Cliente encerrado não recebe demanda nova (a API recusa com 409);
            o quadro fica como histórico. */}
        {client.encerradoEm ? (
          <span className="save-note">cliente encerrado — sem demandas novas</span>
        ) : (
          <button className="btn-primary" type="button" onClick={() => setNewOpen(true)}>
            + nova demanda
          </button>
        )}
      </div>

      <div className="filtro-quem" role="group" aria-label="Filtrar por quem precisa agir">
        <button type="button" className="filtro-btn" aria-pressed={!filtroQuem} onClick={() => setFiltroQuem("")}>
          Tudo <span className="count">{demandas.length - congeladas.length}</span>
        </button>
        {FILTROS.map(({ q, rotulo }) => (
          <button
            key={q}
            type="button"
            className={`filtro-btn quem-${q}`}
            aria-pressed={filtroQuem === q}
            onClick={() => setFiltroQuem(filtroQuem === q ? "" : q)}
          >
            <span className="quem-marca" aria-hidden="true" />
            {rotulo} <span className="count">{contagem(q)}</span>
          </button>
        ))}
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

      {aviso && (
        <p className="auth-note error drop-aviso" role="alert">
          {aviso}
          <button type="button" className="btn-ghost" onClick={() => setAviso("")} aria-label="Fechar aviso">
            ×
          </button>
        </p>
      )}
      <div className="board board-fases">
        {FASES.map((fase) => {
          const items = demandas.filter((d) => fase.estagios.includes(d.status) && passaFiltro(d));
          const parados = items.filter((d) => estaEmGate(d.status)).length;
          const ehTriagem = fase.chave === "triagem";
          return (
            <div
              className={`column fase-${fase.chave}${items.length === 0 ? " vazia" : ""}${parados > 0 ? " tem-parada" : ""}${
                arrastando && alvo === fase.chave && !fase.estagios.includes(arrastando.status)
                  ? motivoSemDrop(arrastando, fase.chave) ? " drop-recusado" : " drop-alvo"
                  : ""
              }`}
              key={fase.chave}
              onDragOver={
                arrastando
                  ? (e) => {
                      e.preventDefault();
                      if (alvo !== fase.chave) setAlvo(fase.chave);
                    }
                  : undefined
              }
              onDragLeave={(e) => {
                if (!e.currentTarget.contains(e.relatedTarget as Node | null)) setAlvo(null);
              }}
              onDrop={
                arrastando
                  ? (e) => {
                      e.preventDefault();
                      soltar(fase.chave);
                    }
                  : undefined
              }
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
                    arrastavel={canManage}
                    onDragStart={() => {
                      setAviso("");
                      setArrastandoId(d.id);
                    }}
                    onDragEnd={() => {
                      setArrastandoId(null);
                      setAlvo(null);
                    }}
                  />
                ))
              )}
            </div>
          );
        })}
      </div>

      {congeladas.length > 0 && (
        <details className="faixa-paradas">
          <summary>
            Congeladas <span className="count">{congeladas.length}</span>
          </summary>
          <div className="faixa-cards">
            {congeladas.map((d) => (
              <DemandCard
                key={d.id}
                demanda={d}
                triageColumn={false}
                faseVisivel
                onOpen={() => setOpenId(d.id)}
              />
            ))}
          </div>
        </details>
      )}

      {open && (
        <DemandModal
          demanda={open}
          canManage={canManage}
          usuarioEmail={usuarioEmail}
          isAdmin={isAdmin}
          onClose={() => setOpenId(null)}
        />
      )}
      {pendente && byId.get(pendente.id) && (
        <ConfirmarDrop
          demanda={byId.get(pendente.id)!}
          acao={pendente.acao}
          onClose={() => setPendente(null)}
        />
      )}
      {newOpen && <NewDemandModal clientId={client.id} clientNome={client.nome} onClose={() => setNewOpen(false)} />}
    </>
  );
}

function ConfirmarDrop({
  demanda,
  acao,
  onClose,
}: {
  demanda: DemandaCompleta;
  acao: "enviar" | "cancelar";
  onClose: () => void;
}) {
  const router = useRouter();
  const [motivo, setMotivo] = useState("");
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");

  async function confirmar() {
    setEnviando(true);
    setErro("");
    const res =
      acao === "enviar"
        ? await fetch(`/api/demandas/${demanda.id}/materialize`, { method: "POST" }).catch(() => null)
        : await fetch(`/api/demandas/${demanda.id}/ciclo`, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ acao: "cancelar", motivo }),
          }).catch(() => null);
    if (!res?.ok) {
      const body = res ? await res.json().catch(() => ({})) : {};
      setErro(body.error || "não deu certo — tente de novo");
      setEnviando(false);
      return;
    }
    router.refresh();
    onClose();
  }

  return (
    <Modal title={acao === "enviar" ? "Enviar para a esteira?" : "Cancelar demanda?"} onClose={onClose}>
      <p>
        <strong>{demanda.code}</strong> — {demanda.titulo}
      </p>
      {acao === "enviar" ? (
        <p>A demanda vai para o repositório e o agente de análise começa. Depois disso ela não pode mais ser excluída, só cancelada.</p>
      ) : (
        <>
          <p>Cancelar encerra a demanda sem entregar. Não tem volta pela tela.</p>
          <label className="field">
            Motivo
            <textarea value={motivo} onChange={(e) => setMotivo(e.target.value)} rows={2} autoFocus />
          </label>
        </>
      )}
      {erro && (
        <p className="auth-note error" role="alert">
          {erro}
        </p>
      )}
      <div className="modal-actions">
        <button type="button" className="btn-ghost" onClick={onClose} disabled={enviando}>
          Voltar
        </button>
        <button
          type="button"
          className="btn-primary"
          onClick={confirmar}
          disabled={enviando || (acao === "cancelar" && !motivo.trim())}
        >
          {enviando ? "Enviando..." : acao === "enviar" ? "Enviar para a esteira" : "Cancelar demanda"}
        </button>
      </div>
    </Modal>
  );
}
