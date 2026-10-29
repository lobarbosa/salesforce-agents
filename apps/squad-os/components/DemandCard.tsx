"use client";

import type { Demanda } from "@/lib/generated/prisma/client";
import type { DemandaCompleta } from "@/lib/data";
import {
  TRIAGE,
  TRIAGE_LABEL,
  STAGE_LABEL,
  formatarMinutos,
  perguntasPendentes,
  progressoDaDemanda,
  acoesPendentes,
  estadoDoClienteDemanda,
  situacaoParaCliente,
  QUEM_AGE_LABEL,
  timeAgo,
  aguardaAprovacaoEstimativa,
} from "@/lib/demandas";

// A Visão Geral monta card a partir de uma demanda sem as relações
// carregadas (getAllDemandas), a aba do cliente com elas — daí o Partial.
// Sem relação, os indicadores simplesmente não aparecem; nada quebra.
type DemandaDeCard = Demanda &
  Partial<Pick<DemandaCompleta, "comentarios" | "subtarefas" | "checklist" | "tempos" | "anexos" | "disparos">>;

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
  if (aguardaAprovacaoEstimativa(demanda)) {
    marcas.push({
      chave: "est",
      texto: `◇ ${demanda.estimativaConsultorHoras} h p/ aprovar`,
      rotulo: `estimativa de ${demanda.estimativaConsultorHoras} h esperando aprovação do cliente`,
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

// Quem age agora (lib/demandas.ts acoesPendentes). Forma + texto, nunca só cor:
// cada dono tem um marcador de forma própria (círculo pulsando, quadrado,
// losango, relógio) e o texto diz o que falta.
export function QuemAgeChips({ demanda }: { demanda: DemandaDeCard }) {
  const acoes = acoesPendentes(demanda);
  if (acoes.length === 0) return null;
  return (
    <>
      {acoes.map((a) => (
        <span key={a.quem + a.oque} className={`quem-age quem-${a.quem}`}>
          <span className="quem-marca" aria-hidden="true" />
          {a.quem === "time" || a.quem === "cliente"
            ? `${QUEM_AGE_LABEL[a.quem]}: ${a.oque}`
            : a.quem === "agente"
              ? "Agente rodando"
              : QUEM_AGE_LABEL[a.quem]}
        </span>
      ))}
    </>
  );
}

function StageChip({
  demanda,
  visaoCliente,
  faseVisivel,
}: {
  demanda: DemandaDeCard;
  visaoCliente?: boolean;
  /** O card está numa coluna que já nomeia a fase — ver DemandasTab. */
  faseVisivel?: boolean;
}) {
  const status = demanda.status;
  // Cliente: uma frase do que está acontecendo + a etapa com nome, sem jargão.
  if (visaoCliente) {
    const estado = estadoDoClienteDemanda(demanda);
    const situacao = situacaoParaCliente(demanda);
    const progresso = progressoDaDemanda(status);
    return (
      <>
        {situacao && (
          <span className={`badge ${estado === "voce" ? "gate sua-vez" : "stage"}`}>{situacao}</span>
        )}
        {progresso && estado !== "entregue" && (
          <span className="badge fase">
            {progresso.rotulo} · {progresso.nome}
          </span>
        )}
      </>
    );
  }
  // Fora das colunas de fase (Visão Geral), a etapa é a única pista de onde está.
  return (
    <>
      {!faseVisivel && <span className="badge stage">{STAGE_LABEL[status] ?? status}</span>}
      <QuemAgeChips demanda={demanda} />
    </>
  );
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
  arrastavel,
  onDragStart,
  onDragEnd,
}: {
  /** Atalhos do quadro (DemandasTab): soltar em Análise/Entregue. */
  arrastavel?: boolean;
  onDragStart?: () => void;
  onDragEnd?: () => void;
  demanda: DemandaDeCard;
  triageColumn: boolean;
  visaoCliente?: boolean;
  /** O card está numa coluna nomeada pela fase, então o chip não a repete. */
  faseVisivel?: boolean;
  canMove?: boolean;
  onOpen: () => void;
  onMove?: (status: string) => void;
}) {
  // O aria-label vira o nome inteiro do card; sem a descrição, o leitor de
  // tela não ouvia o estado (gate, perguntas pendentes) que o card mostra.
  const metaId = `card-meta-${demanda.id}`;
  return (
    <div
      className="card"
      tabIndex={0}
      role="button"
      aria-label={`Abrir demanda ${demanda.code}: ${demanda.titulo}`}
      aria-describedby={metaId}
      onClick={onOpen}
      draggable={arrastavel}
      onDragStart={
        arrastavel
          ? (e) => {
              e.dataTransfer.effectAllowed = "move";
              e.dataTransfer.setData("text/plain", demanda.id);
              onDragStart?.();
            }
          : undefined
      }
      onDragEnd={arrastavel ? onDragEnd : undefined}
      onKeyDown={(e) => {
        if (e.target !== e.currentTarget) return;
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onOpen();
        }
      }}
    >
      {/* O código (SOMOSAGILITY-18) é como a demanda é chamada em todo lugar —
          PR, branch, conversa com o cliente. Sem ele no card, achar a certa
          no quadro era ler título por título. */}
      <div className="card-codigo">{demanda.code}</div>
      <div className="titulo">{demanda.titulo}</div>
      <div className="meta" id={metaId}>
        <span className={`badge ${demanda.tipo === "projeto" ? "projeto" : "sustentacao"}`}>
          {demanda.tipo === "projeto" ? "projeto" : "sustentação"}
        </span>
        {!triageColumn && (
          <StageChip
            demanda={demanda}
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
            aria-label={`Mover "${demanda.titulo}" na triagem`}
            value={demanda.status}
            onClick={(e) => e.stopPropagation()}
            onPointerDown={(e) => e.stopPropagation()}
            onChange={(e) => {
              e.stopPropagation();
              onMove?.(e.target.value);
            }}
          >
            {TRIAGE.map((s) => (
              // Congelar pede motivo — é ação do card, não do dropdown.
              <option key={s} value={s} disabled={s === "standby" && demanda.status !== "standby"}>
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
