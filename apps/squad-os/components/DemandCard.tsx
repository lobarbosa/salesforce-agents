"use client";

import type { Demanda } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  TRIAGE,
  TRIAGE_LABEL,
  STAGE_LABEL,
  ESTADO_CLIENTE_LABEL,
  estaEmGate,
  estadoDoCliente,
  quemDestrava,
  formatarMinutos,
  perguntasPendentes,
  progressoDaDemanda,
  timeAgo,
} from "@/lib/demandas";

// A Visão Geral monta card a partir de uma demanda sem as relações
// carregadas (getAllDemandas), a aba do cliente com elas — daí o Partial.
// Sem relação, os indicadores simplesmente não aparecem; nada quebra.
type DemandaDeCard = Demanda &
  Partial<Pick<DemandaCompleta, "comentarios" | "subtarefas" | "checklist" | "tempos" | "anexos">>;

// O que dá pra saber do card sem abri-lo: quanto da demanda já andou, se tem
// conversa, se tem arquivo, quanto tempo já custou. Cada indicador só aparece
// quando tem o que dizer — uma fileira de zeros em todo card seria ruído com
// aparência de informação.
function Indicadores({ demanda }: { demanda: DemandaDeCard }) {
  const sub = demanda.subtarefas ?? [];
  const chk = demanda.checklist ?? [];
  const minutos = (demanda.tempos ?? []).reduce((soma, t) => soma + (t.minutos ?? 0), 0);
  const comentarios = demanda.comentarios?.length ?? 0;
  const anexos = demanda.anexos?.length ?? 0;

  const marcas: { chave: string; texto: string; rotulo: string }[] = [];
  if (sub.length > 0) {
    const feitas = sub.filter((s) => s.feita).length;
    marcas.push({
      chave: "sub",
      texto: `◫ ${feitas}/${sub.length}`,
      rotulo: `${feitas} de ${sub.length} subtarefas concluídas`,
    });
  }
  if (chk.length > 0) {
    const feitos = chk.filter((i) => i.feito).length;
    marcas.push({
      chave: "chk",
      texto: `✓ ${feitos}/${chk.length}`,
      rotulo: `${feitos} de ${chk.length} itens do checklist conferidos`,
    });
  }
  if (comentarios > 0) {
    marcas.push({
      chave: "com",
      texto: `○ ${comentarios}`,
      rotulo: `${comentarios} comentário${comentarios > 1 ? "s" : ""}`,
    });
  }
  if (anexos > 0) {
    marcas.push({
      chave: "anx",
      texto: `⌥ ${anexos}`,
      rotulo: `${anexos} anexo${anexos > 1 ? "s" : ""}`,
    });
  }
  if (minutos > 0) {
    marcas.push({
      chave: "tmp",
      texto: `◷ ${formatarMinutos(minutos)}`,
      rotulo: `${formatarMinutos(minutos)} de tempo lançado`,
    });
  }

  if (marcas.length === 0) return null;

  return (
    <div className="card-indicadores">
      {marcas.map((m) => (
        <span className="indicador" key={m.chave} title={m.rotulo}>
          <span aria-hidden="true">{m.texto}</span>
          <span className="sr-only">{m.rotulo}</span>
        </span>
      ))}
    </div>
  );
}

function StageChip({
  status,
  visaoCliente,
  faseVisivel,
}: {
  status: string;
  visaoCliente?: boolean;
  /** O card está numa coluna que já nomeia a fase — ver DemandasTab. */
  faseVisivel?: boolean;
}) {
  // Para o cliente, o chip diz o estado dele e a fase; o jargão interno some.
  if (visaoCliente) {
    const estado = estadoDoCliente(status);
    const progresso = progressoDaDemanda(status);
    return (
      <>
        <span className={`badge ${estado === "voce" ? "gate" : "stage"}`}>
          {ESTADO_CLIENTE_LABEL[estado]}
        </span>
        {progresso && estado === "andamento" && (
          <span className="badge fase">{progresso.rotulo}</span>
        )}
      </>
    );
  }
  // Dentro da coluna da fase, repetir o nome dela no chip não diz nada novo.
  // O que muda a decisão de quem olha é **se está parada e esperando quem** —
  // e `aguardando_gate_design` é o gate bloqueante da doutrina, que ganha peso
  // próprio em vez de parecer igual aos outros três.
  if (estaEmGate(status)) {
    const quem = quemDestrava(status);
    const bloqueante = status === "aguardando_gate_design";
    return (
      <span className={`badge gate${bloqueante ? " bloqueante" : ""}`}>
        {bloqueante ? `trava: ${quem}` : `aguarda ${quem}`}
      </span>
    );
  }
  // Demanda andando dentro da coluna da própria fase: o chip repetiria o
  // título da coluna. Na Visão Geral, onde não há colunas de fase, ele é a
  // única pista de onde a demanda está — por isso continua.
  if (faseVisivel) return null;
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
  onOpen,
  onMove,
  visaoCliente,
  faseVisivel,
}: {
  demanda: DemandaDeCard;
  triageColumn: boolean;
  visaoCliente?: boolean;
  /** O card está numa coluna nomeada pela fase, então o chip não a repete. */
  faseVisivel?: boolean;
  canMove?: boolean;
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
        {!triageColumn && (
          <StageChip
            status={demanda.status}
            visaoCliente={visaoCliente}
            faseVisivel={faseVisivel}
          />
        )}
        <ApprovalBadge demanda={demanda} />
        <span>{demanda.autor}</span>
        <span>{timeAgo(demanda.criadoEm)}</span>
      </div>
      <Indicadores demanda={demanda} />
      {triageColumn && canMove ? (
        <>
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
      ) : visaoCliente ? null : (
        <span className="readonly-note">avança via sfagents</span>
      )}
    </div>
  );
}
