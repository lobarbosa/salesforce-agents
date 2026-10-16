"use client";

import { useState, type FormEvent } from "react";
import type { NaturezaCusto, Periodicidade } from "@/lib/generated/prisma/client";
import { lerReais } from "@/lib/contas";
import { NATUREZAS, PERIODICIDADES, ROTULO_NATUREZA, ROTULO_PERIODICIDADE } from "@/lib/recorrencias";

// Formulário do modelo de despesa recorrente — o mesmo em três lugares:
// criar (/financeiro/recorrentes), editar (idem) e "Tornar recorrente" numa
// conta avulsa (contas a pagar, com `contaId` e início fixo no mês da conta).

export interface ValoresRecorrencia {
  fornecedor: string;
  descricao: string;
  categoria: string;
  valor: string; // como digitado: "1.234,56"
  valorVariavel: boolean;
  periodicidade: Periodicidade;
  diaVencimento: string;
  inicio: string; // 'YYYY-MM'
  fim: string; // 'YYYY-MM' ou ""
  natureza: NaturezaCusto | "";
  clientId: string;
}

export function valorParaCampo(v: number): string {
  return v.toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function SeletorNatureza({
  valor,
  onChange,
  name,
  obrigatorio,
}: {
  valor: NaturezaCusto | "";
  onChange?: (v: NaturezaCusto | "") => void;
  name?: string;
  obrigatorio?: boolean;
}) {
  return (
    <label>
      Natureza{obrigatorio ? " *" : ""}
      <select
        name={name}
        value={valor}
        required={obrigatorio}
        onChange={(e) => onChange?.(e.target.value as NaturezaCusto | "")}
      >
        <option value="">{obrigatorio ? "escolha…" : "não classificada"}</option>
        {NATUREZAS.map((n) => (
          <option key={n} value={n}>
            {ROTULO_NATUREZA[n]}
          </option>
        ))}
      </select>
      <span className="sub">Custo direto = serviço prestado a cliente (consultor, terceiro). Despesa fixa = operação.</span>
    </label>
  );
}

export function SeletorCliente({
  clientes,
  valor,
  onChange,
  name,
}: {
  clientes: { id: string; nome: string }[];
  valor: string;
  onChange?: (v: string) => void;
  name?: string;
}) {
  return (
    <label>
      Cliente (opcional)
      <select name={name} value={valor} onChange={(e) => onChange?.(e.target.value)}>
        <option value="">nenhum — custo da casa</option>
        {clientes.map((c) => (
          <option key={c.id} value={c.id}>
            {c.nome}
          </option>
        ))}
      </select>
    </label>
  );
}

export function FormRecorrencia({
  inicial,
  clientes,
  categorias,
  inicioFixo,
  rotuloEnviar,
  onEnviar,
  onCancelar,
}: {
  inicial: ValoresRecorrencia;
  clientes: { id: string; nome: string }[];
  categorias: string[];
  /** Tornar recorrente: a primeira competência é o mês da conta, não se escolhe. */
  inicioFixo?: boolean;
  rotuloEnviar: string;
  /** Devolve a mensagem de erro, ou null quando deu certo. */
  onEnviar: (v: ValoresRecorrencia) => Promise<string | null>;
  onCancelar: () => void;
}) {
  const [v, setV] = useState(inicial);
  const [erro, setErro] = useState("");
  const [erroValor, setErroValor] = useState("");
  const [enviando, setEnviando] = useState(false);
  const muda = <K extends keyof ValoresRecorrencia>(k: K, x: ValoresRecorrencia[K]) => setV((a) => ({ ...a, [k]: x }));

  async function enviar(e: FormEvent) {
    e.preventDefault();
    if (lerReais(v.valor) === null) {
      setErroValor("Valor inválido — use o formato 1.234,56");
      return;
    }
    setErroValor("");
    if (!v.natureza) {
      setErro("Escolha a natureza: custo direto ou despesa fixa.");
      return;
    }
    setEnviando(true);
    setErro("");
    const r = await onEnviar(v);
    setEnviando(false);
    if (r) setErro(r);
  }

  return (
    <form className="form-conta" onSubmit={enviar}>
      {erro && (
        <p className="form-erro" role="alert">
          {erro}
        </p>
      )}
      <label>
        Fornecedor *
        <input value={v.fornecedor} onChange={(e) => muda("fornecedor", e.target.value)} required autoComplete="off" />
      </label>
      <label>
        Descrição
        <input value={v.descricao} onChange={(e) => muda("descricao", e.target.value)} autoComplete="off" />
      </label>
      <div className="form-linha">
        <label>
          Valor por ocorrência (R$) *
          <input
            value={v.valor}
            onChange={(e) => muda("valor", e.target.value)}
            required
            inputMode="decimal"
            placeholder="1.234,56"
            aria-invalid={erroValor ? true : undefined}
            aria-describedby={erroValor ? "erro-valor-rec" : undefined}
          />
          {erroValor && (
            <span id="erro-valor-rec" className="campo-erro">
              {erroValor}
            </span>
          )}
        </label>
        <label>
          Periodicidade *
          <select value={v.periodicidade} onChange={(e) => muda("periodicidade", e.target.value as Periodicidade)}>
            {PERIODICIDADES.map((p) => (
              <option key={p} value={p}>
                {ROTULO_PERIODICIDADE[p]}
              </option>
            ))}
          </select>
        </label>
      </div>
      <label className="form-check">
        <input type="checkbox" checked={v.valorVariavel} onChange={(e) => muda("valorVariavel", e.target.checked)} />
        Valor variável (conta de consumo): a conta nasce com o valor acima como estimativa e é confirmada a cada vez
      </label>
      <div className="form-linha">
        <label>
          Dia do vencimento *
          <input
            type="number"
            min={1}
            max={31}
            value={v.diaVencimento}
            onChange={(e) => muda("diaVencimento", e.target.value)}
            required
          />
          <span className="sub">Em mês mais curto, vence no último dia.</span>
        </label>
        <label>
          Categoria
          <input
            value={v.categoria}
            onChange={(e) => muda("categoria", e.target.value)}
            list="categorias-recorrencia"
            autoComplete="off"
            placeholder="ex.: software"
          />
          <datalist id="categorias-recorrencia">
            {categorias.map((c) => (
              <option key={c} value={c} />
            ))}
          </datalist>
        </label>
      </div>
      <div className="form-linha">
        <label>
          Primeira competência *
          <input
            type="month"
            value={v.inicio}
            onChange={(e) => muda("inicio", e.target.value)}
            required
            disabled={inicioFixo}
          />
          {inicioFixo && <span className="sub">O mês desta conta, que passa a ser a primeira ocorrência.</span>}
        </label>
        <label>
          Última competência
          <input type="month" value={v.fim} onChange={(e) => muda("fim", e.target.value)} />
          <span className="sub">Vazio = sem data para acabar.</span>
        </label>
      </div>
      <div className="form-linha">
        <SeletorNatureza valor={v.natureza} onChange={(x) => muda("natureza", x)} obrigatorio />
        <SeletorCliente clientes={clientes} valor={v.clientId} onChange={(x) => muda("clientId", x)} />
      </div>
      <div className="form-acoes">
        <button type="button" className="btn-ghost" onClick={onCancelar}>
          Cancelar
        </button>
        <button type="submit" className="btn-primary" disabled={enviando}>
          {enviando ? "Salvando…" : rotuloEnviar}
        </button>
      </div>
    </form>
  );
}

/** Corpo JSON para /api/financeiro/recorrentes a partir do formulário. */
export function corpoRecorrencia(v: ValoresRecorrencia): Record<string, unknown> {
  return {
    fornecedor: v.fornecedor,
    descricao: v.descricao,
    categoria: v.categoria,
    valor: v.valor,
    valorVariavel: v.valorVariavel,
    periodicidade: v.periodicidade,
    diaVencimento: Number(v.diaVencimento),
    inicio: v.inicio,
    fim: v.fim,
    natureza: v.natureza,
    clientId: v.clientId,
  };
}

/** POST/PATCH com JSON; devolve a mensagem de erro ou null. */
export async function enviarJson(url: string, metodo: "POST" | "PATCH", corpo: unknown): Promise<string | null> {
  const res = await fetch(url, {
    method: metodo,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(corpo),
  }).catch(() => null);
  if (!res) return "Sem conexão com o servidor — tente de novo.";
  if (res.ok) return null;
  const j = await res.json().catch(() => ({}));
  return j.error ?? "Não foi possível salvar — tente de novo.";
}
