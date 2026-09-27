"use client";

import { useMemo, useRef, useState, type KeyboardEvent } from "react";
import Link from "next/link";
import type { DemandaDaGrade, LinhaDaGrade } from "@/lib/horas-data";
import {
  DIAS_SEMANA,
  duracaoPorExtenso,
  formatarDuracao,
  lerDuracao,
  rotuloDia,
} from "@/lib/horas";

// Grade semanal no padrão consagrado do Clockify/Tempo: linhas = demandas,
// colunas = dias, total por linha, por dia e da semana. Regras de UX (skill
// ui-ux-pro-max) aplicadas aqui:
// - não fazer redigitar: as linhas das últimas semanas já vêm na grade;
// - feedback de envio em cada célula (salvando → salvo / erro com saída);
// - erro perto do campo e com caminho de correção, não só cor;
// - teclado primeiro: Enter salva e desce, Esc desfaz, Tab segue a linha;
// - tabela rola dentro do próprio cartão no telefone, a página não.

type EstadoCelula = "salvando" | "salvo" | "erro";

interface Props {
  dias: string[];
  hoje: string;
  linhasIniciais: LinhaDaGrade[];
  opcoes: DemandaDaGrade[];
}

const chave = (demandaId: string, dia: string) => `${demandaId}|${dia}`;

function sem<T>(obj: Record<string, T>, k: string): Record<string, T> {
  const copia = { ...obj };
  delete copia[k];
  return copia;
}

export function Timesheet({ dias, hoje, linhasIniciais, opcoes }: Props) {
  const [linhas, setLinhas] = useState(linhasIniciais);
  const [rascunho, setRascunho] = useState<Record<string, string>>({});
  const [estado, setEstado] = useState<Record<string, EstadoCelula>>({});
  const [erroCelula, setErroCelula] = useState<Record<string, string>>({});
  const [aviso, setAviso] = useState("");
  const [novaDemanda, setNovaDemanda] = useState("");
  const tabela = useRef<HTMLTableElement>(null);
  // Enter salva e move o foco — o que também dispara blur na mesma célula.
  // Sem esta trava a mesma célula iria duas vezes para o servidor.
  const emVoo = useRef(new Set<string>());

  const idsNaGrade = useMemo(() => new Set(linhas.map((l) => l.demanda.id)), [linhas]);
  const disponiveis = opcoes.filter((o) => !idsNaGrade.has(o.id));
  const porCliente = useMemo(() => {
    const m = new Map<string, DemandaDaGrade[]>();
    for (const o of disponiveis) m.set(o.clientNome, [...(m.get(o.clientNome) ?? []), o]);
    return [...m.entries()];
  }, [disponiveis]);

  const totalDia = (dia: string) => linhas.reduce((s, l) => s + (l.minutos[dia] ?? 0), 0);
  const totalLinha = (l: LinhaDaGrade) => dias.reduce((s, d) => s + (l.minutos[d] ?? 0), 0);
  const totalSemana = dias.reduce((s, d) => s + totalDia(d), 0);

  function valorExibido(l: LinhaDaGrade, dia: string) {
    const k = chave(l.demanda.id, dia);
    return k in rascunho ? rascunho[k] : formatarDuracao(l.minutos[dia] ?? 0);
  }

  function focar(linhaIdx: number, diaIdx: number) {
    const alvo = tabela.current?.querySelector<HTMLInputElement>(
      `input[data-linha="${linhaIdx}"][data-dia="${diaIdx}"]`
    );
    alvo?.focus();
  }

  function descartar(k: string) {
    setRascunho((o) => sem(o, k));
  }

  async function salvar(l: LinhaDaGrade, dia: string) {
    const k = chave(l.demanda.id, dia);
    if (!(k in rascunho)) return;
    const digitado = rascunho[k];
    const atual = l.minutos[dia] ?? 0;
    const minutos = lerDuracao(digitado);

    if (minutos === null) {
      setEstado((e) => ({ ...e, [k]: "erro" }));
      setErroCelula((e) => ({ ...e, [k]: `Não entendi “${digitado}”. Use 1:30, 1,5 ou 90m.` }));
      setAviso(`Valor inválido em ${l.demanda.code}, ${rotuloDia(dia)}. Use 1:30, 1,5 ou 90m.`);
      return;
    }
    if (minutos === atual) {
      descartar(k);
      return;
    }

    if (emVoo.current.has(k)) return;
    emVoo.current.add(k);
    setEstado((e) => ({ ...e, [k]: "salvando" }));
    setErroCelula((o) => sem(o, k));
    const res = await fetch("/api/horas", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ demandaId: l.demanda.id, dia, minutos }),
    }).catch(() => null);
    emVoo.current.delete(k);

    if (!res || !res.ok) {
      const corpo = res ? await res.json().catch(() => ({})) : {};
      const msg = corpo.error ?? "Não foi possível salvar — verifique a conexão e tente de novo.";
      setEstado((e) => ({ ...e, [k]: "erro" }));
      setErroCelula((e) => ({ ...e, [k]: msg }));
      setAviso(`Não salvou ${l.demanda.code}, ${rotuloDia(dia)}: ${msg}`);
      return;
    }

    setLinhas((ls) =>
      ls.map((x) => (x.demanda.id === l.demanda.id ? { ...x, minutos: { ...x.minutos, [dia]: minutos } } : x))
    );
    descartar(k);
    setEstado((e) => ({ ...e, [k]: "salvo" }));
    setAviso(`Salvo: ${duracaoPorExtenso(minutos)} em ${l.demanda.code}, ${rotuloDia(dia)}.`);
    setTimeout(() => setEstado((o) => sem(o, k)), 1800);
  }

  function aoTeclar(e: KeyboardEvent<HTMLInputElement>, l: LinhaDaGrade, dia: string, li: number, di: number) {
    const k = chave(l.demanda.id, dia);
    if (e.key === "Escape") {
      descartar(k);
      setErroCelula((o) => sem(o, k));
      setEstado((o) => sem(o, k));
      return;
    }
    if (e.key === "Enter") {
      e.preventDefault();
      void salvar(l, dia);
      focar(e.shiftKey ? li - 1 : li + 1, di);
    }
  }

  function adicionarLinha() {
    const d = opcoes.find((o) => o.id === novaDemanda);
    if (!d) return;
    setLinhas((ls) => [...ls, { demanda: d, minutos: {}, foraDaGrade: {} }]);
    setNovaDemanda("");
    setAviso(`${d.code} adicionada à grade. Digite as horas nos dias trabalhados.`);
    // Leva o foco para o primeiro dia editável da linha nova.
    const di = Math.max(0, dias.findIndex((dia) => dia <= hoje));
    setTimeout(() => focar(linhas.length, di), 0);
  }

  return (
    <>
      <div className="grade-horas-wrap">
        <table ref={tabela} className="grade-horas">
          <caption className="sr-only">
            Horas lançadas por demanda e por dia. Digite no formato 1:30, 1,5 ou 90m; Enter salva e desce.
          </caption>
          <thead>
            <tr>
              <th scope="col" className="gh-demanda">Demanda</th>
              {dias.map((dia, i) => (
                <th
                  key={dia}
                  scope="col"
                  className={`gh-dia${i >= 5 ? " fds" : ""}${dia === hoje ? " hoje" : ""}`}
                >
                  <span>{DIAS_SEMANA[i]}</span>
                  <span className="gh-data">{dia === hoje ? "hoje" : rotuloDia(dia)}</span>
                </th>
              ))}
              <th scope="col" className="gh-total">Total</th>
            </tr>
          </thead>
          <tbody>
            {linhas.length === 0 && (
              <tr>
                <td colSpan={dias.length + 2} className="gh-vazio">
                  Nenhuma demanda na sua grade ainda. Escolha uma abaixo para começar a lançar horas.
                </td>
              </tr>
            )}
            {linhas.map((l, li) => (
              <tr key={l.demanda.id}>
                <th scope="row" className="gh-demanda">
                  <Link
                    href={`/clients/${l.demanda.clientId}?tab=demandas&demand=${l.demanda.id}`}
                    className="gh-link"
                  >
                    <span className="mono">{l.demanda.code}</span> {l.demanda.titulo}
                  </Link>
                  <span className="gh-cliente">{l.demanda.clientNome}</span>
                </th>
                {dias.map((dia, di) => {
                  const k = chave(l.demanda.id, dia);
                  const futuro = dia > hoje;
                  const st = estado[k];
                  const erro = erroCelula[k];
                  const fora = l.foraDaGrade[dia] ?? 0;
                  return (
                    <td
                      key={dia}
                      className={`gh-celula${di >= 5 ? " fds" : ""}${dia === hoje ? " hoje" : ""}${st ? ` ${st}` : ""}`}
                    >
                      <input
                        type="text"
                        inputMode="decimal"
                        autoComplete="off"
                        data-linha={li}
                        data-dia={di}
                        disabled={futuro}
                        value={valorExibido(l, dia)}
                        aria-label={`${l.demanda.code}, ${DIAS_SEMANA[di]} ${rotuloDia(dia)}`}
                        aria-invalid={st === "erro" || undefined}
                        aria-busy={st === "salvando" || undefined}
                        aria-describedby={erro ? `erro-${k}` : undefined}
                        title={
                          futuro
                            ? "Esse dia ainda não chegou"
                            : fora
                              ? `Inclui ${formatarDuracao(fora)} de cronômetro ou lançamento no card`
                              : undefined
                        }
                        onFocus={(e) => e.currentTarget.select()}
                        onChange={(e) => setRascunho((r) => ({ ...r, [k]: e.target.value }))}
                        onBlur={() => void salvar(l, dia)}
                        onKeyDown={(e) => aoTeclar(e, l, dia, li, di)}
                      />
                      {st === "salvo" && <span className="gh-ok" aria-hidden="true">✓</span>}
                      {erro && (
                        <span id={`erro-${k}`} className="gh-erro">
                          {erro}
                        </span>
                      )}
                    </td>
                  );
                })}
                <td className="gh-total num">{formatarDuracao(totalLinha(l)) || "0:00"}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr>
              <th scope="row" className="gh-demanda">Total do dia</th>
              {dias.map((dia, i) => (
                <td key={dia} className={`gh-total num${i >= 5 ? " fds" : ""}${dia === hoje ? " hoje" : ""}`}>
                  {formatarDuracao(totalDia(dia)) || "0:00"}
                </td>
              ))}
              <td className="gh-total gh-semana num">
                {formatarDuracao(totalSemana) || "0:00"}
                <span className="sr-only"> — {duracaoPorExtenso(totalSemana)} na semana</span>
              </td>
            </tr>
          </tfoot>
        </table>
      </div>

      <div className="grade-horas-add">
        <label htmlFor="nova-demanda">Adicionar demanda à grade</label>
        <select id="nova-demanda" value={novaDemanda} onChange={(e) => setNovaDemanda(e.target.value)}>
          <option value="">Escolha uma demanda…</option>
          {porCliente.map(([cliente, ds]) => (
            <optgroup key={cliente} label={cliente}>
              {ds.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.code} — {d.titulo}
                </option>
              ))}
            </optgroup>
          ))}
        </select>
        <button className="btn-primary" type="button" disabled={!novaDemanda} onClick={adicionarLinha}>
          Adicionar
        </button>
      </div>

      <p className="sr-only" role="status" aria-live="polite">
        {aviso}
      </p>
    </>
  );
}
