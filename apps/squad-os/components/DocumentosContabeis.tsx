"use client";

import { useRef, useState, type DragEvent } from "react";
import { useRouter } from "next/navigation";
import { ROTULO_TIPO, TIPOS_DOC, tipoPeloNome, type TipoDoc } from "@/lib/contabilidade";

// Envio e lista dos documentos do mês (substitui os anexos da task
// "Contabilidade MM/AAAA" no ClickUp). O tipo vem sugerido pelo nome do
// arquivo — a pessoa só confere. Remover pede confirmação e é lógico.

export interface DocVista {
  id: string;
  tipo: string;
  nome: string;
  tamanho: number;
  enviadoPorEmail: string;
  enviadoEm: string;
  removidoEm: string | null;
  removidoPorEmail: string | null;
}

const MAX_MB = 10;

function quando(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo", dateStyle: "short", timeStyle: "short" });
}

function tamanho(b: number) {
  return b >= 1024 * 1024 ? `${(b / 1024 / 1024).toFixed(1)} MB` : `${Math.max(1, Math.round(b / 1024))} KB`;
}

const rotulo = (t: string) => ROTULO_TIPO[t as TipoDoc] ?? t;

export function DocumentosContabeis({ competencia, documentos }: { competencia: string; documentos: DocVista[] }) {
  const router = useRouter();
  const input = useRef<HTMLInputElement>(null);
  const [fila, setFila] = useState<{ arquivo: File; tipo: TipoDoc }[]>([]);
  const [arrastando, setArrastando] = useState(false);
  const [enviando, setEnviando] = useState(false);
  const [erro, setErro] = useState("");
  const [aviso, setAviso] = useState("");
  const [removendo, setRemovendo] = useState<string | null>(null);

  const ativos = documentos.filter((d) => !d.removidoEm);
  const removidos = documentos.filter((d) => d.removidoEm);

  function adicionar(lista: FileList | null) {
    if (!lista) return;
    const novos = Array.from(lista);
    const grandes = novos.filter((f) => f.size > MAX_MB * 1024 * 1024);
    setErro(grandes.length ? `Passa de ${MAX_MB} MB: ${grandes.map((f) => f.name).join(", ")}` : "");
    setFila((f) => [
      ...f,
      ...novos.filter((a) => a.size <= MAX_MB * 1024 * 1024).map((arquivo) => ({ arquivo, tipo: tipoPeloNome(arquivo.name) })),
    ]);
    if (input.current) input.current.value = "";
  }

  function soltar(e: DragEvent) {
    e.preventDefault();
    setArrastando(false);
    adicionar(e.dataTransfer.files);
  }

  async function enviar() {
    setEnviando(true);
    setErro("");
    const form = new FormData();
    form.set("competencia", competencia);
    for (const { arquivo, tipo } of fila) {
      form.append("arquivo", arquivo);
      form.append("tipo", tipo);
    }
    const r = await fetch("/api/financeiro/contabilidade", { method: "POST", body: form });
    setEnviando(false);
    if (!r.ok) {
      const j = await r.json().catch(() => ({}));
      setErro(`Nada foi enviado: ${j.error ?? "erro ao enviar"}. Tente de novo.`);
      return;
    }
    setAviso(`${fila.length} documento${fila.length > 1 ? "s enviados" : " enviado"}.`);
    setFila([]);
    router.refresh();
  }

  async function remover(id: string) {
    const r = await fetch(`/api/financeiro/contabilidade/${id}`, { method: "DELETE" });
    setRemovendo(null);
    if (!r.ok) {
      setErro("Não foi possível remover o documento. Recarregue a página.");
      return;
    }
    setAviso("Documento removido.");
    router.refresh();
  }

  return (
    <>
      <section className="envio-docs" aria-labelledby="titulo-envio">
        <h2 id="titulo-envio" className="secao-titulo">
          Enviar documentos
        </h2>
        <div
          className={`zona-envio${arrastando ? " arrastando" : ""}`}
          onDragOver={(e) => {
            e.preventDefault();
            setArrastando(true);
          }}
          onDragLeave={() => setArrastando(false)}
          onDrop={soltar}
        >
          <p>
            Arraste os arquivos aqui ou{" "}
            <label className="link-linha">
              escolha no computador
              <input
                ref={input}
                type="file"
                multiple
                className="sr-only"
                accept=".pdf,.xlsx,.xls,.csv,image/*"
                onChange={(e) => adicionar(e.target.files)}
              />
            </label>
          </p>
          <span className="sub">PDF, planilha (XLSX/CSV) ou imagem, até {MAX_MB} MB cada.</span>
        </div>

        {erro && (
          <p className="form-erro" role="alert">
            {erro}
          </p>
        )}
        <p className="sr-only" role="status" aria-live="polite">
          {aviso}
        </p>

        {fila.length > 0 && (
          <div className="fila-envio">
            <ul>
              {fila.map((f, i) => (
                <li key={`${f.arquivo.name}-${i}`}>
                  <span className="fila-nome">
                    {f.arquivo.name} <span className="sub">{tamanho(f.arquivo.size)}</span>
                  </span>
                  <label>
                    <span className="sr-only">Tipo de {f.arquivo.name}</span>
                    <select
                      value={f.tipo}
                      onChange={(e) =>
                        setFila((l) => l.map((x, j) => (j === i ? { ...x, tipo: e.target.value as TipoDoc } : x)))
                      }
                    >
                      {TIPOS_DOC.map((t) => (
                        <option key={t} value={t}>
                          {ROTULO_TIPO[t]}
                        </option>
                      ))}
                    </select>
                  </label>
                  <button
                    type="button"
                    className="btn-ghost"
                    onClick={() => setFila((l) => l.filter((_, j) => j !== i))}
                    aria-label={`Tirar ${f.arquivo.name} da lista`}
                  >
                    Tirar
                  </button>
                </li>
              ))}
            </ul>
            <div className="form-acoes">
              <span className="save-note">confira o tipo sugerido de cada arquivo</span>
              <button type="button" className="btn-primary" disabled={enviando} onClick={enviar}>
                {enviando ? "Enviando…" : `Enviar ${fila.length} arquivo${fila.length > 1 ? "s" : ""}`}
              </button>
            </div>
          </div>
        )}
      </section>

      <h2 className="secao-titulo">Recebidos ({ativos.length})</h2>
      {ativos.length === 0 ? (
        <div className="overview-empty">Nenhum documento desta competência ainda.</div>
      ) : (
        <div className="tabela-wrap">
          <table className="tabela">
            <caption className="sr-only">Documentos recebidos</caption>
            <thead>
              <tr>
                <th scope="col">Documento</th>
                <th scope="col">Tipo</th>
                <th scope="col">Enviado</th>
                <th scope="col">
                  <span className="sr-only">Ações</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {ativos.map((d) => (
                <tr key={d.id}>
                  <th scope="row">
                    <a href={`/api/financeiro/contabilidade/${d.id}`}>{d.nome}</a>
                    <span className="sub">{tamanho(d.tamanho)}</span>
                  </th>
                  <td>{rotulo(d.tipo)}</td>
                  <td>
                    {quando(d.enviadoEm)}
                    <span className="sub">{d.enviadoPorEmail}</span>
                  </td>
                  <td className="acoes-linha">
                    {removendo === d.id ? (
                      <span className="confirmar-inline" role="group" aria-label={`Confirmar remoção de ${d.nome}`}>
                        <span className="sub">A conciliação deixa de usar este arquivo.</span>
                        <button type="button" className="btn-ghost" onClick={() => setRemovendo(null)}>
                          Manter
                        </button>
                        <button type="button" className="btn-perigo" onClick={() => remover(d.id)}>
                          Remover
                        </button>
                      </span>
                    ) : (
                      <button type="button" className="btn-ghost" onClick={() => setRemovendo(d.id)}>
                        Remover
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {removidos.length > 0 && (
        <details className="removidos">
          <summary>Removidos ({removidos.length})</summary>
          <ul>
            {removidos.map((d) => (
              <li key={d.id}>
                <a href={`/api/financeiro/contabilidade/${d.id}`}>{d.nome}</a> — {rotulo(d.tipo)}, removido por{" "}
                {d.removidoPorEmail} em {quando(d.removidoEm!)}
              </li>
            ))}
          </ul>
        </details>
      )}
    </>
  );
}
