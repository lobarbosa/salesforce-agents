"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Modal } from "@/components/Modal";
import { formatarReais, lerReais, prazo } from "@/lib/contas";
import { diferenca, FORMAS, ROTULO_FORMA, ROTULO_SITUACAO, type Forma, type NotaVista } from "@/lib/receber";

// Contas a receber: lista das NFS-e e o detalhe de cada uma, onde o financeiro
// registra o recebimento (data, valor, forma, observação) ou desfaz um registro
// errado. Mesmas regras de UX das contas a pagar: situação por texto, erro
// perto do botão, desfazer pede o motivo, nada de estado vazio mudo.

function dataBr(dia: string) {
  return `${dia.slice(8, 10)}/${dia.slice(5, 7)}/${dia.slice(0, 4)}`;
}

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

function valorCampo(v: number) {
  return v.toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

const ROTULO_FORMA_LIVRE = (f: string) => (FORMAS as readonly string[]).includes(f) ? ROTULO_FORMA[f as Forma] : f || "—";

export function ContasReceber({
  notas,
  todas,
  hoje,
  notaInicial,
}: {
  notas: NotaVista[];
  /** A nota pedida pelo link abre mesmo fora do filtro atual. */
  todas: NotaVista[];
  hoje: string;
  notaInicial?: string;
}) {
  const router = useRouter();
  const [aberta, setAberta] = useState<string | null>(notaInicial ?? null);
  const nota = aberta ? todas.find((n) => n.chave === aberta) ?? null : null;

  const linha = (n: NotaVista) => {
    const p = n.vencimento ? prazo(n.vencimento, hoje) : null;
    const aberto = n.situacao !== "recebida";
    return (
      <tr key={n.chave} className={aberto && n.situacao === "vencida" ? "linha-vencida" : undefined}>
        <td className="data" data-rotulo="Vencimento">
          {n.vencimento ? dataBr(n.vencimento) : "—"}
          {aberto && p && <span className={`prazo${p.urgente ? " urgente" : ""}`}>{p.texto}</span>}
        </td>
        <th scope="row">
          <button type="button" className="link-linha" onClick={() => setAberta(n.chave)}>
            {n.cliente || "cliente não identificado"}
          </button>
          <span className="sub">
            NFS-e {n.numero} · emitida em {dataBr(n.emissao)}
          </span>
        </th>
        <td className="num" data-rotulo="Valor da nota">{formatarReais(n.valor)}</td>
        <td className="num" data-rotulo="A receber">{formatarReais(n.esperado)}</td>
        <td data-rotulo="Situação">
          <span className={`badge-status rc-${n.situacao}`}>{ROTULO_SITUACAO[n.situacao]}</span>
          {n.recebimento && <span className="sub">em {dataBr(n.recebimento.em)}</span>}
        </td>
      </tr>
    );
  };

  return (
    <>
      {notas.length ? (
        <div className="tabela-wrap">
          <table className="tabela tabela-cartoes">
            <caption className="sr-only">Notas fiscais emitidas e situação do recebimento</caption>
            <thead>
              <tr>
                <th scope="col">Vencimento</th>
                <th scope="col">Cliente e nota</th>
                <th scope="col" className="num">Valor da nota</th>
                <th scope="col" className="num">A receber</th>
                <th scope="col">Situação</th>
              </tr>
            </thead>
            <tbody>{notas.map(linha)}</tbody>
          </table>
        </div>
      ) : (
        <div className="overview-empty ok">Nenhuma nota neste filtro.</div>
      )}
      {nota && (
        <DetalheNota
          key={nota.chave + (nota.recebimento?.id ?? "") + nota.historico.length}
          nota={nota}
          hoje={hoje}
          onClose={() => setAberta(null)}
          onMudou={() => router.refresh()}
        />
      )}
    </>
  );
}

function DetalheNota({
  nota: n,
  hoje,
  onClose,
  onMudou,
}: {
  nota: NotaVista;
  hoje: string;
  onClose: () => void;
  onMudou: () => void;
}) {
  const [data, setData] = useState(hoje);
  const [valor, setValor] = useState(valorCampo(n.esperado));
  const [forma, setForma] = useState<Forma | "">("");
  const [observacao, setObservacao] = useState("");
  const [desfazendo, setDesfazendo] = useState(false);
  const [motivo, setMotivo] = useState("");
  const [agindo, setAgindo] = useState(false);
  const [erro, setErro] = useState("");
  const [aviso, setAviso] = useState("");

  async function enviar(url: string, corpo: unknown, feito: string) {
    setAgindo(true);
    setErro("");
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(corpo),
    }).catch(() => null);
    setAgindo(false);
    if (!res || !res.ok) {
      const j = res ? await res.json().catch(() => ({})) : {};
      setErro(j.error ?? "Não foi possível concluir — verifique a conexão e tente de novo.");
      return;
    }
    setAviso(feito);
    setDesfazendo(false);
    setMotivo("");
    onMudou();
  }

  const r = n.recebimento;
  const dif = diferenca(n);
  const valorLido = lerReais(valor);
  const p = n.vencimento ? prazo(n.vencimento, hoje) : null;

  return (
    <Modal title={`${n.cliente || "Nota"} — NFS-e ${n.numero}`} onClose={onClose} wide>
      <p className="sr-only" role="status" aria-live="polite">
        {aviso}
      </p>
      <div className="detalhe-conta">
        <dl className="dados-conta">
          <div>
            <dt>Situação</dt>
            <dd>
              <span className={`badge-status rc-${n.situacao}`}>{ROTULO_SITUACAO[n.situacao]}</span>
              {n.situacao !== "recebida" && p && <span className="sub"> · {p.texto}</span>}
            </dd>
          </div>
          <div>
            <dt>Emissão</dt>
            <dd>{dataBr(n.emissao)}</dd>
          </div>
          <div>
            <dt>Vencimento</dt>
            <dd>{n.vencimento ? dataBr(n.vencimento) : "a nota não informa"}</dd>
          </div>
          <div>
            <dt>Valor dos serviços</dt>
            <dd className="num">{formatarReais(n.valor)}</dd>
          </div>
          <div>
            <dt>A receber (líquido)</dt>
            <dd className="num">
              {formatarReais(n.esperado)}
              {n.valorLiquido === null && <span className="sub"> · nota sem valor líquido</span>}
            </dd>
          </div>
          <div>
            <dt>Retenções</dt>
            <dd className="num">{n.valorLiquido === null ? "—" : formatarReais(Math.round((n.valor - n.valorLiquido) * 100) / 100)}</dd>
          </div>
          <div>
            <dt>Documento</dt>
            <dd>
              {n.documento ? (
                <a href={`/api/financeiro/contabilidade/${n.documento}`}>{n.arquivo || "relação de notas"}</a>
              ) : (
                "—"
              )}
            </dd>
          </div>
        </dl>

        {r ? (
          <section className="recebimento-bloco" aria-label="Recebimento">
            <h3 className="secao-titulo">Recebimento</h3>
            <dl className="dados-conta">
              <div>
                <dt>Recebida em</dt>
                <dd>{dataBr(r.em)}</dd>
              </div>
              <div>
                <dt>Valor recebido</dt>
                <dd className="num">
                  {r.valor === null ? "não informado" : formatarReais(r.valor)}
                  {dif !== null && Math.abs(dif) >= 0.01 && (
                    <span className={`sub${dif < 0 ? " aviso-texto" : ""}`}>
                      {" "}
                      · {dif < 0 ? `${formatarReais(-dif)} a menos` : `${formatarReais(dif)} a mais`} que o esperado
                    </span>
                  )}
                </dd>
              </div>
              <div>
                <dt>Forma</dt>
                <dd>{ROTULO_FORMA_LIVRE(r.forma)}</dd>
              </div>
              <div>
                <dt>Registrado por</dt>
                <dd>{r.origem === "registro_antigo" ? "registro anterior a esta tela" : r.por}</dd>
              </div>
              {r.observacao && (
                <div>
                  <dt>Observação</dt>
                  <dd>{r.observacao}</dd>
                </div>
              )}
            </dl>
            {r.origem === "registro_antigo" ? (
              <p className="save-note">
                Este recebimento foi registrado antes desta tela existir, só com a data. Para corrigi-lo, peça ao time de
                tecnologia.
              </p>
            ) : desfazendo ? (
              <div className="confirmar">
                <label>
                  Por que desfazer? (fica no histórico)
                  <textarea
                    id="motivo-desfazer"
                    value={motivo}
                    onChange={(e) => setMotivo(e.target.value)}
                    rows={2}
                    maxLength={500}
                    placeholder="Ex.: registrado na nota errada; pagamento devolvido"
                  />
                </label>
                {erro && (
                  <p className="form-erro" role="alert">
                    {erro}
                  </p>
                )}
                <div className="form-acoes">
                  <button type="button" className="btn-ghost" onClick={() => setDesfazendo(false)}>
                    Voltar
                  </button>
                  <button
                    type="button"
                    className="btn-primary"
                    disabled={agindo || !motivo.trim()}
                    onClick={() => enviar(`/api/financeiro/receber/${r.id}/estornar`, { motivo }, "Recebimento desfeito.")}
                  >
                    {agindo ? "Desfazendo…" : "Desfazer recebimento"}
                  </button>
                </div>
              </div>
            ) : (
              <div className="acoes-conta">
                <button type="button" className="btn-ghost" onClick={() => setDesfazendo(true)}>
                  Desfazer recebimento
                </button>
              </div>
            )}
          </section>
        ) : (
          <form
            className="form-conta"
            aria-label="Registrar recebimento"
            onSubmit={(e) => {
              e.preventDefault();
              enviar(
                "/api/financeiro/receber",
                { chave: n.chave, recebidoEm: data, valorRecebido: valor, forma, observacao },
                "Recebimento registrado."
              );
            }}
          >
            <h3 className="secao-titulo">Registrar recebimento</h3>
            <div className="form-linha">
              <label>
                Data do recebimento
                <input id="receb-data" type="date" value={data} max={hoje} min={n.emissao} onChange={(e) => setData(e.target.value)} required />
              </label>
              <label>
                Valor recebido (R$)
                <input
                  id="receb-valor"
                  value={valor}
                  onChange={(e) => setValor(e.target.value)}
                  inputMode="decimal"
                  placeholder="1.234,56"
                  aria-invalid={valor !== "" && valorLido === null}
                  required
                />
              </label>
            </div>
            <div className="form-linha">
              <label>
                Forma
                <select id="receb-forma" value={forma} onChange={(e) => setForma(e.target.value as Forma | "")} required>
                  <option value="">escolha…</option>
                  {FORMAS.map((f) => (
                    <option key={f} value={f}>
                      {ROTULO_FORMA[f]}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Observação (opcional)
                <input
                  id="receb-obs"
                  value={observacao}
                  onChange={(e) => setObservacao(e.target.value)}
                  maxLength={500}
                  placeholder="Ex.: pago com desconto; conta Itaú"
                />
              </label>
            </div>
            {valorLido !== null && Math.abs(valorLido - n.esperado) >= 0.01 && (
              <p className="sub">
                {valorLido < n.esperado
                  ? `${formatarReais(n.esperado - valorLido)} a menos que o esperado — a nota fica como recebida mesmo assim; explique na observação.`
                  : `${formatarReais(valorLido - n.esperado)} a mais que o esperado.`}
              </p>
            )}
            {erro && (
              <p className="form-erro" role="alert">
                {erro}
              </p>
            )}
            <div className="form-acoes">
              <button type="submit" className="btn-primary" disabled={agindo || valorLido === null || !forma || !data}>
                {agindo ? "Registrando…" : "Registrar recebimento"}
              </button>
            </div>
          </form>
        )}

        {n.historico.length > 0 && (
          <section aria-label="Histórico">
            <h3 className="secao-titulo">Histórico</h3>
            <ol className="historico">
              {n.historico.map((h) => (
                <li key={h.id}>
                  <span className="sub">{quando(h.registradoEm)}</span> {h.registradoPorEmail} registrou{" "}
                  {formatarReais(h.valorRecebido)} recebidos em {dataBr(h.recebidoEm)} ({ROTULO_FORMA_LIVRE(h.forma)})
                  {h.estornadoEm && (
                    <>
                      {" "}
                      — desfeito por {h.estornadoPorEmail} em {quando(h.estornadoEm)}: {h.estornoMotivo}
                    </>
                  )}
                </li>
              ))}
            </ol>
          </section>
        )}
      </div>
    </Modal>
  );
}
