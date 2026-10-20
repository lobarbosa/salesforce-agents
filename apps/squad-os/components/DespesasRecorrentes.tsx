"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Modal } from "@/components/Modal";
import {
  corpoRecorrencia,
  enviarJson,
  FormRecorrencia,
  textoGeracao,
  valorParaCampo,
  type ValoresRecorrencia,
} from "@/components/FormRecorrencia";
import type { ModeloVisto } from "@/lib/recorrencias-data";
import { formatarReais } from "@/lib/contas";
import { ROTULO_NATUREZA, ROTULO_PERIODICIDADE, rotuloCompetencia } from "@/lib/recorrencias";

// Lista de modelos de despesa recorrente: criar, editar, pausar/retomar e
// encerrar. Situação sempre por texto; ação que muda o futuro pede confirmação.

function situacao(m: ModeloVisto): { texto: string; classe: string } {
  if (m.encerrada) return { texto: "encerrada", classe: "st-cancelada" };
  if (!m.ativa) return { texto: "pausada", classe: "st-aguardando_aprovacao" };
  return { texto: "ativa", classe: "st-paga" };
}

function dataBr(dia: string) {
  return `${dia.slice(8, 10)}/${dia.slice(5, 7)}/${dia.slice(0, 4)}`;
}

export function DespesasRecorrentes({
  modelos,
  clientes,
  categorias,
  hoje,
  modeloInicial,
}: {
  modelos: ModeloVisto[];
  clientes: { id: string; nome: string }[];
  categorias: string[];
  hoje: string;
  modeloInicial?: string;
}) {
  const router = useRouter();
  const [editando, setEditando] = useState<string | null>(modeloInicial ?? null);
  const [criando, setCriando] = useState(false);
  const [resumo, setResumo] = useState("");
  const aoGerar = (r: { geracao?: Parameters<typeof textoGeracao>[0] }) => setResumo(textoGeracao(r.geracao));
  const modelo = modelos.find((m) => m.id === editando) ?? null;

  const novo: ValoresRecorrencia = {
    fornecedor: "",
    descricao: "",
    categoria: "",
    valor: "",
    valorVariavel: false,
    periodicidade: "mensal",
    diaVencimento: "10",
    inicio: hoje.slice(0, 7),
    fim: "",
    natureza: "",
    clientId: "",
  };

  return (
    <>
      <div className="board-toolbar">
        <span className="save-note">
          a conta de cada competência aparece em contas a pagar 30 dias antes do vencimento, aguardando aprovação;
          meses passados desde o início também são gerados (ou vinculados à conta avulsa já lançada)
        </span>
        <button className="btn-primary" type="button" onClick={() => setCriando(true)}>
          Nova despesa recorrente
        </button>
      </div>

      <p className="sr-only" role="status" aria-live="polite">
        {resumo}
      </p>
      {resumo && <div className="overview-empty ok">{resumo}.</div>}

      {modelos.length === 0 ? (
        <div className="overview-empty">
          Nenhuma despesa recorrente ainda. Crie uma aqui ou, em{" "}
          <Link href="/financeiro/contas">contas a pagar</Link>, abra uma conta avulsa e use “Tornar recorrente”.
        </div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Despesas recorrentes</caption>
            <thead>
              <tr>
                <th scope="col">Fornecedor</th>
                <th scope="col">Natureza</th>
                <th scope="col">Cliente</th>
                <th scope="col">Periodicidade</th>
                <th scope="col" className="num">Valor</th>
                <th scope="col" className="num">Por mês</th>
                <th scope="col">Próxima</th>
                <th scope="col">Situação</th>
              </tr>
            </thead>
            <tbody>
              {modelos.map((m) => {
                const s = situacao(m);
                return (
                  <tr key={m.id}>
                    <th scope="row">
                      <button type="button" className="link-linha" onClick={() => setEditando(m.id)}>
                        {m.fornecedor}
                      </button>
                      <span className="sub">{[m.categoria, m.descricao].filter(Boolean).join(" · ") || "—"}</span>
                    </th>
                    <td>
                      <span className={`badge-tipo natureza-${m.natureza}`}>{ROTULO_NATUREZA[m.natureza]}</span>
                    </td>
                    <td>{m.clientNome ?? <span className="sub">—</span>}</td>
                    <td>
                      {ROTULO_PERIODICIDADE[m.periodicidade]}
                      <span className="sub">dia {m.diaVencimento}</span>
                    </td>
                    <td className="num">
                      {formatarReais(m.valor)}
                      {m.valorVariavel && <span className="sub">variável (estimado)</span>}
                    </td>
                    <td className="num">{formatarReais(m.equivalenteMensal)}</td>
                    <td>
                      {m.proxima ? (
                        <>
                          {rotuloCompetencia(m.proxima.competencia)}
                          <span className="sub">vence {dataBr(m.proxima.vencimento)}</span>
                        </>
                      ) : (
                        <span className="sub">—</span>
                      )}
                    </td>
                    <td>
                      <span className={`badge-status ${s.classe}`}>{s.texto}</span>
                      {m.fim && !m.encerrada && <span className="sub">até {rotuloCompetencia(m.fim)}</span>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {criando && (
        <Modal title="Nova despesa recorrente" onClose={() => setCriando(false)} wide>
          <FormRecorrencia
            inicial={novo}
            clientes={clientes}
            categorias={categorias}
            rotuloEnviar="Criar despesa recorrente"
            onCancelar={() => setCriando(false)}
            onEnviar={async (v) => {
              const erro = await enviarJson("/api/financeiro/recorrentes", "POST", corpoRecorrencia(v), aoGerar);
              if (!erro) {
                setCriando(false);
                router.refresh();
              }
              return erro;
            }}
          />
        </Modal>
      )}

      {modelo && (
        <EditarModelo
          modelo={modelo}
          clientes={clientes}
          categorias={categorias}
          hoje={hoje}
          onClose={() => setEditando(null)}
          onMudou={() => router.refresh()}
          onGerou={aoGerar}
        />
      )}
    </>
  );
}

function EditarModelo({
  modelo: m,
  clientes,
  categorias,
  hoje,
  onClose,
  onMudou,
  onGerou,
}: {
  modelo: ModeloVisto;
  clientes: { id: string; nome: string }[];
  categorias: string[];
  hoje: string;
  onClose: () => void;
  onMudou: () => void;
  onGerou: (r: { geracao?: Parameters<typeof textoGeracao>[0] }) => void;
}) {
  const [erro, setErro] = useState("");
  const [agindo, setAgindo] = useState(false);
  const [confirmando, setConfirmando] = useState<"pausar" | "retomar" | "encerrar" | null>(null);
  const [fimEncerrar, setFimEncerrar] = useState(hoje.slice(0, 7));
  const url = `/api/financeiro/recorrentes/${m.id}`;

  async function patch(corpo: Record<string, unknown>) {
    setAgindo(true);
    setErro("");
    const e = await enviarJson(url, "PATCH", corpo, onGerou);
    setAgindo(false);
    if (e) {
      setErro(e);
      return;
    }
    setConfirmando(null);
    onMudou();
  }

  const inicial: ValoresRecorrencia = {
    fornecedor: m.fornecedor,
    descricao: m.descricao,
    categoria: m.categoria,
    valor: valorParaCampo(m.valor),
    valorVariavel: m.valorVariavel,
    periodicidade: m.periodicidade,
    diaVencimento: String(m.diaVencimento),
    inicio: m.inicio,
    fim: m.fim ?? "",
    natureza: m.natureza,
    clientId: m.clientId ?? "",
  };

  return (
    <Modal title={`${m.fornecedor} — ${ROTULO_PERIODICIDADE[m.periodicidade]}`} onClose={onClose} wide>
      <div className="detalhe-conta">
        {erro && (
          <p className="form-erro" role="alert">
            {erro}
          </p>
        )}
        <p className="save-note">
          {m.contasGeradas} conta{m.contasGeradas === 1 ? "" : "s"} ligada{m.contasGeradas === 1 ? "" : "s"} a esta
          recorrência ·{" "}
          <Link href={`/financeiro/contas?ver=todas&tipo=recorrentes&recorrencia=${m.id}`}>ver contas</Link>. Mudanças
          valem para as próximas contas; as já geradas seguem o próprio fluxo.
        </p>

        <div className="acoes-conta">
          {!m.encerrada && (
            <div className="acao">
              <button
                type="button"
                className="btn-ghost"
                disabled={agindo}
                onClick={() => setConfirmando(m.ativa ? "pausar" : "retomar")}
              >
                {m.ativa ? "Pausar" : "Retomar"}
              </button>
              {!m.ativa && <span className="sub">Ao retomar, os meses que passaram pausados também são gerados.</span>}
            </div>
          )}
          {!m.encerrada && (
            <div className="acao">
              <button type="button" className="btn-ghost" disabled={agindo} onClick={() => setConfirmando("encerrar")}>
                Encerrar
              </button>
            </div>
          )}
        </div>

        {confirmando === "pausar" && (
          <div className="confirmar" role="group" aria-label="Confirmar pausa">
            <p>
              Pausar <strong>{m.fornecedor}</strong>? Nenhuma conta nova é gerada enquanto estiver pausada.
            </p>
            <div className="form-acoes">
              <button type="button" className="btn-ghost" onClick={() => setConfirmando(null)}>
                Voltar
              </button>
              <button type="button" className="btn-primary" disabled={agindo} onClick={() => patch({ ativa: false })}>
                {agindo ? "Salvando…" : "Confirmar: pausar"}
              </button>
            </div>
          </div>
        )}
        {/* Retomar gera as contas dos meses pausados: pede confirmação como o pausar. */}
        {confirmando === "retomar" && (
          <div className="confirmar" role="group" aria-label="Confirmar retomada">
            <p>
              Retomar <strong>{m.fornecedor}</strong>? As contas dos meses em que esteve pausada também são geradas.
            </p>
            <div className="form-acoes">
              <button type="button" className="btn-ghost" onClick={() => setConfirmando(null)}>
                Voltar
              </button>
              <button type="button" className="btn-primary" disabled={agindo} onClick={() => patch({ ativa: true })}>
                {agindo ? "Salvando…" : "Confirmar: retomar"}
              </button>
            </div>
          </div>
        )}
        {confirmando === "encerrar" && (
          <div className="confirmar" role="group" aria-label="Confirmar encerramento">
            <label>
              Última competência a gerar
              <input type="month" value={fimEncerrar} min={m.inicio} onChange={(e) => setFimEncerrar(e.target.value)} />
            </label>
            <div className="form-acoes">
              <button type="button" className="btn-ghost" onClick={() => setConfirmando(null)}>
                Voltar
              </button>
              <button
                type="button"
                className="btn-primary"
                disabled={agindo || !fimEncerrar}
                onClick={() => patch({ fim: fimEncerrar })}
              >
                {agindo ? "Salvando…" : `Confirmar: encerrar após ${fimEncerrar ? rotuloCompetencia(fimEncerrar) : "…"}`}
              </button>
            </div>
          </div>
        )}

        <h4 className="secao-titulo">Editar</h4>
        <FormRecorrencia
          key={m.id}
          inicial={inicial}
          clientes={clientes}
          categorias={categorias}
          rotuloEnviar="Salvar alterações"
          onCancelar={onClose}
          onEnviar={async (v) => {
            const e = await enviarJson(url, "PATCH", corpoRecorrencia(v), onGerou);
            if (!e) {
              onMudou();
              onClose();
            }
            return e;
          }}
        />
        <p className="save-note">Criada por {m.criadoPorEmail}.</p>
      </div>
    </Modal>
  );
}
