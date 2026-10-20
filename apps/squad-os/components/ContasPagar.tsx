"use client";

import { useEffect, useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Modal } from "@/components/Modal";
import type { ContaVista, EventoVisto } from "@/lib/contas-data";
import { bloqueioDocumento, formatarReais, lerReais, prazo, ROTULO_STATUS, type Acao } from "@/lib/contas";
import { acceptDo, erroDeUpload, TAMANHO_MAX_ARQUIVO, TAMANHO_MAX_MB } from "@/lib/upload-regras";
import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";
import { PERIODICIDADES, ROTULO_NATUREZA, ROTULO_REPETIR, rotuloCompetencia } from "@/lib/recorrencias";
import {
  corpoRecorrencia,
  enviarJson,
  FormRecorrencia,
  textoGeracao,
  SeletorCliente,
  SeletorNatureza,
  valorParaCampo,
} from "@/components/FormRecorrencia";

// Contas a pagar e fila de aprovações (mesmo componente, dois modos).
// Padrões: lista do ClickUp + fila de aprovação do Jira Service Management.
// Regras de UX (skill ui-ux-pro-max): situação sempre por texto; ação
// bloqueada explica o porquê; ação financeira pede confirmação; erro perto
// do campo; filtros no link; nada de estado vazio mudo.

const ROTULO_EVENTO: Record<string, string> = {
  lancada: "lançou a conta",
  aprovada: "aprovou",
  recusada: "recusou",
  paga: "marcou como paga",
  cancelada: "cancelou",
  documento: "anexou o documento",
  valor_alterado: "corrigiu o valor",
  classificada: "classificou",
  recorrente: "tornou recorrente",
};

const ROTULO_ACAO: Record<Acao, string> = {
  aprovar: "Aprovar",
  recusar: "Recusar",
  pagar: "Marcar como paga",
  cancelar: "Cancelar conta",
};

// Só as ações que fazem sentido na situação atual; bloqueada aparece com o motivo.
const ACOES_DO_STATUS: Partial<Record<ContaVista["status"], Acao[]>> = {
  aguardando_aprovacao: ["aprovar", "recusar", "cancelar"],
  aprovada: ["pagar", "cancelar"],
};

function dataBr(dia: string) {
  return `${dia.slice(8, 10)}/${dia.slice(5, 7)}/${dia.slice(0, 4)}`;
}

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

export function ContasPagar({
  contas,
  hoje,
  modo,
  decidiveis,
  contaInicial,
  categorias,
  clientes = [],
}: {
  contas: ContaVista[];
  hoje: string;
  modo: "contas" | "aprovacoes";
  /** Aprovações: ids que a pessoa logada pode decidir (o resto aguarda outra pessoa). */
  decidiveis?: string[];
  contaInicial?: string;
  categorias: string[];
  /** Para natureza/cliente no lançamento e na classificação. */
  clientes?: { id: string; nome: string }[];
}) {
  const router = useRouter();
  const [aberta, setAberta] = useState<string | null>(contaInicial ?? null);
  const [lancando, setLancando] = useState(false);

  const linha = (c: ContaVista) => {
    const p = prazo(c.vencimento, hoje);
    const aberta = c.status === "aguardando_aprovacao" || c.status === "aprovada";
    return (
      <tr key={c.id} className={aberta && p.vencida ? "linha-vencida" : undefined}>
        <td className="data">
          {dataBr(c.vencimento)}
          {aberta && <span className={`prazo${p.urgente ? " urgente" : ""}`}>{p.texto}</span>}
        </td>
        <th scope="row">
          <button type="button" className="link-linha" onClick={() => setAberta(c.id)}>
            {c.fornecedor}
          </button>
          {c.descricao && <span className="sub">{c.descricao}</span>}
        </th>
        <td>{c.categoria || <span className="sub">—</span>}</td>
        <td>
          <TipoConta conta={c} />
        </td>
        <td className="num">{formatarReais(c.valor)}</td>
        <td>{c.temDocumento ? "anexado" : <span className="aviso-texto">sem documento</span>}</td>
        <td>
          <span className={`badge-status st-${c.status}`}>{ROTULO_STATUS[c.status]}</span>
        </td>
      </tr>
    );
  };

  const tabela = (lista: ContaVista[], legenda: string) => (
    <div className="tabela-wrap">
      <table className="tabela">
        <caption className="sr-only">{legenda}</caption>
        <thead>
          <tr>
            <th scope="col">Vencimento</th>
            <th scope="col">Fornecedor</th>
            <th scope="col">Categoria</th>
            <th scope="col">Tipo</th>
            <th scope="col" className="num">Valor</th>
            <th scope="col">Documento</th>
            <th scope="col">Situação</th>
          </tr>
        </thead>
        <tbody>{lista.map(linha)}</tbody>
      </table>
    </div>
  );

  const aoMudar = () => router.refresh();

  let corpo;
  if (modo === "aprovacoes") {
    const minhas = contas.filter((c) => decidiveis?.includes(c.id));
    const outras = contas.filter((c) => !decidiveis?.includes(c.id));
    corpo = (
      <>
        <h2 className="secao-titulo">Você pode decidir ({minhas.length})</h2>
        {minhas.length ? (
          tabela(minhas, "Contas que você pode aprovar ou recusar")
        ) : (
          <div className="overview-empty ok">Nada esperando a sua decisão.</div>
        )}
        <h2 className="secao-titulo">Aguardando outra pessoa ({outras.length})</h2>
        {outras.length ? (
          tabela(outras, "Contas que precisam de outra pessoa")
        ) : (
          <div className="overview-empty">Nenhuma conta parada em outra pessoa.</div>
        )}
        <p className="save-note">
          Quem lança uma conta não pode aprová-la, e o financeiro aprova só até a alçada configurada; acima dela, o
          admin decide.
        </p>
      </>
    );
  } else {
    corpo = contas.length ? (
      tabela(contas, "Contas a pagar")
    ) : (
      <div className="overview-empty">
        Nenhuma conta neste filtro.{" "}
        <button type="button" className="link-linha" onClick={() => setLancando(true)}>
          Lançar uma conta
        </button>
      </div>
    );
  }

  return (
    <>
      {modo === "contas" && (
        <div className="board-toolbar">
          <span className="save-note">toda conta nasce aguardando aprovação</span>
          <button className="btn-primary" type="button" onClick={() => setLancando(true)}>
            Lançar conta
          </button>
        </div>
      )}
      {corpo}
      {lancando && (
        <NovaConta
          categorias={categorias}
          clientes={clientes}
          onClose={() => setLancando(false)}
          onCriada={(id) => {
            setLancando(false);
            aoMudar();
            setAberta(id);
          }}
        />
      )}
      {aberta && (
        <DetalheConta
          id={aberta}
          clientes={clientes}
          categorias={categorias}
          onClose={() => setAberta(null)}
          onMudou={aoMudar}
        />
      )}
    </>
  );
}

/** "Recorrente" (com link para o modelo) ou "Avulsa", e a natureza embaixo. */
function TipoConta({ conta: c }: { conta: ContaVista }) {
  return (
    <>
      {c.recorrenciaId ? (
        <Link href={`/financeiro/recorrentes?modelo=${c.recorrenciaId}`} className="badge-tipo recorrente">
          Recorrente{c.competencia ? ` · ${rotuloCompetencia(c.competencia)}` : ""}
        </Link>
      ) : (
        <span className="badge-tipo avulsa">Avulsa</span>
      )}
      <span className="sub">{c.natureza ? ROTULO_NATUREZA[c.natureza] : "sem natureza"}</span>
    </>
  );
}

function NovaConta({
  categorias,
  clientes,
  onClose,
  onCriada,
}: {
  categorias: string[];
  clientes: { id: string; nome: string }[];
  onClose: () => void;
  onCriada: (id: string) => void;
}) {
  const [natureza, setNatureza] = useState<NaturezaCusto | "">("");
  const [clientId, setClientId] = useState("");
  const [repetir, setRepetir] = useState(false);
  const [periodicidade, setPeriodicidade] = useState<Periodicidade>("mensal");
  const [erro, setErro] = useState("");
  const [erroValor, setErroValor] = useState("");
  const [enviando, setEnviando] = useState(false);

  async function enviar(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    if (lerReais(String(form.get("valor") ?? "")) === null) {
      setErroValor("Valor inválido — use o formato 1.234,56");
      return;
    }
    setErroValor("");
    const doc = form.get("documento");
    if (doc instanceof File && doc.size > TAMANHO_MAX_ARQUIVO) {
      setErro(`O documento passa de ${TAMANHO_MAX_MB} MB.`);
      return;
    }
    if (repetir && !natureza) {
      setErro("Para repetir, escolha a natureza: custo direto ou despesa fixa.");
      return;
    }
    if (!repetir) {
      form.delete("repetir");
      form.delete("valorVariavel");
    }
    setEnviando(true);
    setErro("");
    const res = await fetch("/api/financeiro/contas", { method: "POST", body: form }).catch(() => null);
    setEnviando(false);
    if (!res || !res.ok) {
      setErro(
        res
          ? await erroDeUpload(res, "Não foi possível lançar — tente de novo.")
          : "Não foi possível lançar — verifique a conexão e tente de novo."
      );
      return;
    }
    onCriada((await res.json()).id);
  }

  return (
    <Modal title="Lançar conta a pagar" onClose={onClose}>
      <form className="form-conta" onSubmit={enviar}>
        {erro && (
          <p className="form-erro" role="alert">
            {erro}
          </p>
        )}
        <label>
          Fornecedor *
          <input name="fornecedor" required autoComplete="off" />
        </label>
        <label>
          Descrição
          <input name="descricao" autoComplete="off" placeholder="ex.: licenças de setembro" />
        </label>
        <div className="form-linha">
          <label>
            Valor (R$) *
            <input
              name="valor"
              required
              inputMode="decimal"
              placeholder="1.234,56"
              aria-invalid={erroValor ? true : undefined}
              aria-describedby={erroValor ? "erro-valor" : undefined}
            />
            {erroValor && (
              <span id="erro-valor" className="campo-erro">
                {erroValor}
              </span>
            )}
          </label>
          <label>
            Vencimento *
            <input name="vencimento" type="date" required />
          </label>
        </div>
        <label>
          Categoria
          <input name="categoria" list="categorias-conta" autoComplete="off" placeholder="ex.: software, impostos" />
          <datalist id="categorias-conta">
            {categorias.map((c) => (
              <option key={c} value={c} />
            ))}
          </datalist>
        </label>
        <div className="form-linha">
          <SeletorNatureza name="natureza" valor={natureza} onChange={setNatureza} obrigatorio={repetir} />
          <SeletorCliente name="clientId" clientes={clientes} valor={clientId} onChange={setClientId} />
        </div>
        <fieldset className="form-repetir">
          <legend className="sr-only">Recorrência</legend>
          <label className="form-check">
            <input type="checkbox" checked={repetir} onChange={(e) => setRepetir(e.target.checked)} />
            Repetir {ROTULO_REPETIR[periodicidade]}
          </label>
          {repetir && (
            <div className="form-linha">
              <label>
                Periodicidade
                <select
                  name="repetir"
                  value={periodicidade}
                  onChange={(e) => setPeriodicidade(e.target.value as Periodicidade)}
                >
                  {PERIODICIDADES.map((p) => (
                    <option key={p} value={p}>
                      {ROTULO_REPETIR[p]}
                    </option>
                  ))}
                </select>
              </label>
              <label className="form-check">
                <input type="checkbox" name="valorVariavel" />
                Valor variável (conta de consumo)
              </label>
            </div>
          )}
          {repetir && (
            <span className="sub">
              As próximas contas são geradas sozinhas no mesmo dia de vencimento, 30 dias antes, aguardando aprovação.
              Edite ou encerre em Despesas recorrentes.
            </span>
          )}
        </fieldset>
        <label>
          Documento fiscal (NF, boleto)
          <input name="documento" type="file" accept={acceptDo("conta")} />
          <span className="sub">Pode anexar depois, mas a conta aparece como “sem documento”.</span>
        </label>
        <div className="form-acoes">
          <button type="button" className="btn-ghost" onClick={onClose}>
            Cancelar
          </button>
          <button type="submit" className="btn-primary" disabled={enviando}>
            {enviando ? "Lançando…" : "Lançar conta"}
          </button>
        </div>
      </form>
    </Modal>
  );
}

interface Detalhe {
  conta: ContaVista;
  eventos: EventoVisto[];
  bloqueios: Record<Acao, string | null>;
  bloqueioValor: string | null;
}

function DetalheConta({
  id,
  clientes,
  categorias,
  onClose,
  onMudou,
}: {
  id: string;
  clientes: { id: string; nome: string }[];
  categorias: string[];
  onClose: () => void;
  onMudou: () => void;
}) {
  const [d, setD] = useState<Detalhe | null>(null);
  const [erro, setErro] = useState("");
  const [confirmando, setConfirmando] = useState<Acao | null>(null);
  const [comentario, setComentario] = useState("");
  const [agindo, setAgindo] = useState(false);
  const [aviso, setAviso] = useState("");
  const [editando, setEditando] = useState<"valor" | "classificar" | "recorrente" | null>(null);
  const [novoValor, setNovoValor] = useState("");
  const [natureza, setNatureza] = useState<NaturezaCusto | "">("");
  const [clientId, setClientId] = useState("");
  const [resumoRecorrencia, setResumoRecorrencia] = useState("");

  useEffect(() => {
    let vivo = true;
    fetch(`/api/financeiro/contas/${id}`)
      .then((r) => (r.ok ? r.json() : Promise.reject()))
      .then((j) => vivo && setD(j))
      .catch(() => vivo && setErro("Não foi possível abrir esta conta."));
    return () => {
      vivo = false;
    };
  }, [id]);

  async function recarregar() {
    const r = await fetch(`/api/financeiro/contas/${id}`);
    if (r.ok) setD(await r.json());
    onMudou();
  }

  async function agir(acao: Acao) {
    setAgindo(true);
    setErro("");
    const res = await fetch(`/api/financeiro/contas/${id}/acao`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ acao, comentario }),
    }).catch(() => null);
    setAgindo(false);
    if (!res || !res.ok) {
      const corpo = res ? await res.json().catch(() => ({})) : {};
      setErro(corpo.error ?? "Não foi possível concluir — tente de novo.");
      return;
    }
    setConfirmando(null);
    setComentario("");
    setAviso(`Feito: ${ROTULO_ACAO[acao].toLowerCase()}.`);
    await recarregar();
  }

  function abrirEdicao(qual: "valor" | "classificar" | "recorrente") {
    if (!d) return;
    setErro("");
    setNovoValor(valorParaCampo(d.conta.valor));
    setNatureza(d.conta.natureza ?? "");
    setClientId(d.conta.clientId ?? "");
    setEditando(qual);
  }

  async function alterar(corpo: Record<string, unknown>, feito: string) {
    setAgindo(true);
    setErro("");
    const e = await enviarJson(`/api/financeiro/contas/${id}`, "PATCH", corpo);
    setAgindo(false);
    if (e) {
      setErro(e);
      return;
    }
    setEditando(null);
    setAviso(feito);
    await recarregar();
  }

  async function anexar(arquivo: File) {
    if (arquivo.size > TAMANHO_MAX_ARQUIVO) {
      setErro(`O documento passa de ${TAMANHO_MAX_MB} MB.`);
      return;
    }
    const form = new FormData();
    form.set("documento", arquivo);
    setAgindo(true);
    const res = await fetch(`/api/financeiro/contas/${id}/documento`, { method: "POST", body: form }).catch(() => null);
    setAgindo(false);
    if (!res || !res.ok) {
      setErro(res ? await erroDeUpload(res, "Não foi possível anexar o documento.") : "Não foi possível anexar o documento — verifique a conexão.");
      return;
    }
    setAviso("Documento anexado.");
    await recarregar();
  }

  const c = d?.conta;
  return (
    <Modal title={c ? `${c.fornecedor} — ${formatarReais(c.valor)}` : "Conta a pagar"} onClose={onClose} wide>
      {!d && !erro && <p className="save-note">Carregando…</p>}
      {/* Com a confirmação aberta, o erro aparece junto do botão (lá embaixo no modal), não aqui. */}
      {erro && !confirmando && (
        <p className="form-erro" role="alert">
          {erro}
        </p>
      )}
      <p className="sr-only" role="status" aria-live="polite">
        {aviso}
      </p>
      {c && d && (
        <div className="detalhe-conta">
          <dl className="dados-conta">
            <div>
              <dt>Situação</dt>
              <dd>
                <span className={`badge-status st-${c.status}`}>{ROTULO_STATUS[c.status]}</span>
              </dd>
            </div>
            <div>
              <dt>Vencimento</dt>
              <dd>{dataBr(c.vencimento)}</dd>
            </div>
            <div>
              <dt>Categoria</dt>
              <dd>{c.categoria || "—"}</dd>
            </div>
            <div>
              <dt>Descrição</dt>
              <dd>{c.descricao || "—"}</dd>
            </div>
            <div>
              <dt>Documento</dt>
              <dd>
                {c.temDocumento ? (
                  <a href={`/api/financeiro/contas/${c.id}/documento`}>{c.documentoNome || "baixar"}</a>
                ) : (
                  <span className="aviso-texto">sem documento</span>
                )}
                {bloqueioDocumento(c.status, c.temDocumento) === null && (
                  <label className="anexar">
                    {c.temDocumento ? "Trocar documento" : "Anexar documento"}
                    <input
                      type="file"
                      accept={acceptDo("conta")}
                      disabled={agindo}
                      onChange={(e) => e.target.files?.[0] && anexar(e.target.files[0])}
                    />
                  </label>
                )}
              </dd>
            </div>
            <div>
              <dt>Tipo</dt>
              <dd>
                <TipoConta conta={c} />
              </dd>
            </div>
            <div>
              <dt>Cliente</dt>
              <dd>{c.clientNome ?? "—"}</dd>
            </div>
          </dl>

          {resumoRecorrencia && <div className="overview-empty ok">Recorrência criada: {resumoRecorrencia}.</div>}

          <div className="acoes-conta">
            {d.bloqueioValor === null && (
              <div className="acao">
                <button type="button" className="btn-ghost" disabled={agindo} onClick={() => abrirEdicao("valor")}>
                  Corrigir valor
                </button>
              </div>
            )}
            <div className="acao">
              <button type="button" className="btn-ghost" disabled={agindo} onClick={() => abrirEdicao("classificar")}>
                Classificar
              </button>
            </div>
            {!c.recorrenciaId && (
              <div className="acao">
                <button type="button" className="btn-ghost" disabled={agindo} onClick={() => abrirEdicao("recorrente")}>
                  Tornar recorrente
                </button>
              </div>
            )}
          </div>

          {editando === "valor" && (
            <div className="confirmar" role="group" aria-label="Corrigir valor">
              <label>
                Valor correto (R$)
                <input
                  value={novoValor}
                  onChange={(e) => setNovoValor(e.target.value)}
                  inputMode="decimal"
                  placeholder="1.234,56"
                />
              </label>
              <p className="sub">
                Fica na trilha (de → para). Quem corrige o valor não aprova esta conta — outra pessoa decide.
              </p>
              <div className="form-acoes">
                <button type="button" className="btn-ghost" onClick={() => setEditando(null)}>
                  Voltar
                </button>
                <button
                  type="button"
                  className="btn-primary"
                  disabled={agindo || lerReais(novoValor) === null}
                  onClick={() => alterar({ valor: novoValor }, "Valor corrigido.")}
                >
                  {agindo ? "Salvando…" : "Confirmar novo valor"}
                </button>
              </div>
            </div>
          )}

          {editando === "classificar" && (
            <div className="confirmar form-conta" role="group" aria-label="Classificar conta">
              <div className="form-linha">
                <SeletorNatureza valor={natureza} onChange={setNatureza} />
                <SeletorCliente clientes={clientes} valor={clientId} onChange={setClientId} />
              </div>
              <div className="form-acoes">
                <button type="button" className="btn-ghost" onClick={() => setEditando(null)}>
                  Voltar
                </button>
                <button
                  type="button"
                  className="btn-primary"
                  disabled={agindo}
                  onClick={() => alterar({ natureza, clientId }, "Classificação salva.")}
                >
                  {agindo ? "Salvando…" : "Salvar classificação"}
                </button>
              </div>
            </div>
          )}

          {editando === "recorrente" && (
            <div className="confirmar">
              <p>
                Cria uma despesa recorrente a partir desta conta. Ela vira a ocorrência de{" "}
                <strong>{rotuloCompetencia(c.vencimento.slice(0, 7))}</strong>; as próximas são geradas sozinhas.
              </p>
              <FormRecorrencia
                inicial={{
                  fornecedor: c.fornecedor,
                  descricao: c.descricao,
                  categoria: c.categoria,
                  valor: valorParaCampo(c.valor),
                  valorVariavel: false,
                  periodicidade: "mensal",
                  diaVencimento: String(Number(c.vencimento.slice(8, 10))),
                  inicio: c.vencimento.slice(0, 7),
                  fim: "",
                  natureza: c.natureza ?? "",
                  clientId: c.clientId ?? "",
                }}
                inicioFixo
                clientes={clientes}
                categorias={categorias}
                rotuloEnviar="Tornar recorrente"
                onCancelar={() => setEditando(null)}
                onEnviar={async (v) => {
                  const e = await enviarJson("/api/financeiro/recorrentes", "POST", { ...corpoRecorrencia(v), contaId: c.id }, (r) =>
                    setResumoRecorrencia(textoGeracao(r.geracao))
                  );
                  if (!e) {
                    setEditando(null);
                    setAviso("Conta tornada recorrente.");
                    onMudou();
                    await recarregar();
                  }
                  return e;
                }}
              />
            </div>
          )}

          <div className="acoes-conta">
            {(ACOES_DO_STATUS[c.status] ?? []).map((a, i, lista) => {
              const motivo = d.bloqueios[a];
              // Aprovar e recusar costumam ter o mesmo bloqueio: o motivo aparece uma vez só.
              const repetido = i > 0 && motivo === d.bloqueios[lista[i - 1]];
              return (
                <div key={a} className="acao">
                  <button
                    type="button"
                    className={a === "aprovar" || a === "pagar" ? "btn-primary" : "btn-ghost"}
                    disabled={!!motivo || agindo}
                    aria-describedby={motivo ? `motivo-${a}` : undefined}
                    onClick={() => {
                      setConfirmando(a);
                      setErro("");
                    }}
                  >
                    {ROTULO_ACAO[a]}
                  </button>
                  {motivo && (
                    <span id={`motivo-${a}`} className={repetido ? "sr-only" : "sub"}>
                      {motivo}
                    </span>
                  )}
                </div>
              );
            })}
          </div>

          {confirmando && (
            <div className="confirmar" role="group" aria-label="Confirmar ação">
              <p>
                {ROTULO_ACAO[confirmando]}: <strong>{c.fornecedor}</strong>, {formatarReais(c.valor)}, vencimento{" "}
                {dataBr(c.vencimento)}?
              </p>
              <label>
                {confirmando === "recusar" ? "Motivo da recusa *" : "Comentário (opcional)"}
                <textarea value={comentario} onChange={(e) => setComentario(e.target.value)} rows={2} />
              </label>
              {erro && (
                <p className="form-erro" role="alert">
                  {erro}
                </p>
              )}
              <div className="form-acoes">
                <button type="button" className="btn-ghost" onClick={() => setConfirmando(null)}>
                  Voltar
                </button>
                <button
                  type="button"
                  className="btn-primary"
                  disabled={agindo || (confirmando === "recusar" && !comentario.trim())}
                  onClick={() => agir(confirmando)}
                >
                  {agindo ? "Registrando…" : `Confirmar: ${ROTULO_ACAO[confirmando].toLowerCase()}`}
                </button>
              </div>
            </div>
          )}

          <h4 className="secao-titulo">Histórico</h4>
          <ol className="historico">
            {d.eventos.map((e, i) => (
              <li key={i}>
                <span className="sub">{quando(e.em)}</span> {e.porEmail} {ROTULO_EVENTO[e.acao] ?? e.acao}
                {e.comentario && <span className="comentario">“{e.comentario}”</span>}
              </li>
            ))}
          </ol>
          <p className="save-note">
            O histórico não pode ser editado nem apagado. <Link href="/financeiro/aprovacoes">Ver fila de aprovações</Link>
          </p>
        </div>
      )}
    </Modal>
  );
}
