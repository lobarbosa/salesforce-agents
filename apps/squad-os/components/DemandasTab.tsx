"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  FASES,
  ESTADOS_CLIENTE,
  ESTADO_CLIENTE_LABEL,
  agenteRodando,
  estaEmGate,
  estadoDoCliente,
  quemDestrava,
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
      window.alert("sem conexão com o servidor — a demanda não foi movida");
    } else if (!res.ok) {
      const corpo = await res.json().catch(() => ({}));
      window.alert(corpo.error || "não consegui mover a demanda");
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
    const porEstado = ESTADOS_CLIENTE.map((estado) => ({
      estado,
      items: demandas.filter((d) => estadoDoCliente(d.status) === estado),
    }));
    const suas = porEstado.find((c) => c.estado === "voce")!.items;

    return (
      <>
        {/* Pedir também é coisa do cliente, não só acompanhar: numa conta de
            AMS quem sente o problema primeiro é quem usa a org. A API já
            aceitava (POST /api/demandas só exige alcançar o próprio cliente) —
            faltava a porta na tela. A demanda nasce em `backlog`, igual às
            que o consultor registra, e continua sendo o time quem decide o
            que entra na esteira. */}
        <div className="board-toolbar">
          <span className="save-note">suas demandas em {client.nome}</span>
          <button className="btn-primary" type="button" onClick={() => setNewOpen(true)}>
            + nova demanda
          </button>
        </div>

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
        {newOpen && (
          <NewDemandModal clientId={client.id} clientNome={client.nome} onClose={() => setNewOpen(false)} />
        )}
      </>
    );
  }

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
          const items = demandas.filter((d) => fase.estagios.includes(d.status));
          const parados = items.filter((d) => estaEmGate(d.status)).length;
          const ehTriagem = fase.chave === "triagem";
          return (
            <div
              className={`column fase-${fase.chave}${parados > 0 ? " tem-parada" : ""}${
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
