"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { Contrato, Entregavel, TipoContrato } from "@/lib/generated/prisma/client";
import type { MesDeHoras, LinhaSla } from "@/lib/contrato";
import { asSla, progressoDoProjeto } from "@/lib/contrato";
import { HorasChart } from "@/components/HorasChart";

type ContratoCompleto = Contrato & { entregaveis: Entregavel[] };

export function ContratoTab({
  clientId,
  clientNome,
  contrato,
  horas,
  demandasPorEntregavel,
  canManage,
}: {
  clientId: string;
  clientNome: string;
  contrato: ContratoCompleto | null;
  horas: MesDeHoras[];
  /** Quantas demandas já nasceram de cada entregável, e quantas já foram entregues. */
  demandasPorEntregavel: Record<string, { total: number; entregues: number }>;
  canManage: boolean;
}) {
  const router = useRouter();
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState("");
  const [novoEntregavel, setNovoEntregavel] = useState("");
  const [gerando, setGerando] = useState(false);
  const [gerouMsg, setGerouMsg] = useState("");

  const tipo = contrato?.tipo ?? null;
  const sla = asSla(contrato?.sla);
  const entregaveis = contrato?.entregaveis ?? [];
  const progresso = progressoDoProjeto(entregaveis);

  async function chamar(url: string, init: RequestInit): Promise<unknown | null> {
    setSalvando(true);
    setErro("");
    try {
      const res = await fetch(url, init);
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        // O status entra na mensagem quando o servidor não mandou motivo.
        // "não consegui salvar" sozinho não dá o que investigar: 401 é sessão
        // expirada, 403 é permissão, 500 é defeito nosso — e quem relata o
        // problema não abre o DevTools. Achado real: um relato desses custou
        // uma sessão inteira de diagnóstico às cegas (2026-09-11).
        setErro((b as { error?: string }).error ?? `não consegui salvar (HTTP ${res.status})`);
        return null;
      }
      router.refresh();
      return res.status === 204 ? null : await res.json();
    } catch (err) {
      setErro(`sem conexão com o servidor (${err instanceof Error ? err.name : "falha"})`);
      return null;
    } finally {
      setSalvando(false);
    }
  }

  const json = (metodo: string, body: unknown): RequestInit => ({
    method: metodo,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  function definirTipo(novo: TipoContrato) {
    chamar(`/api/clients/${clientId}/contrato`, json("PUT", { tipo: novo }));
  }

  function salvarCampo(campo: string, valor: unknown) {
    if (!contrato) return;
    chamar(
      `/api/clients/${clientId}/contrato`,
      json("PUT", {
        tipo: contrato.tipo,
        horasContratadas: contrato.horasContratadas,
        cicloHoras: contrato.cicloHoras,
        sla,
        projetoNome: contrato.projetoNome,
        projetoEscopo: contrato.projetoEscopo,
        inicioEm: contrato.inicioEm,
        fimPrevistoEm: contrato.fimPrevistoEm,
        [campo]: valor,
      })
    );
  }

  function salvarSla(linhas: LinhaSla[]) {
    if (!contrato) return;
    chamar(
      `/api/clients/${clientId}/contrato`,
      json("PUT", { tipo: contrato.tipo, horasContratadas: contrato.horasContratadas, cicloHoras: contrato.cicloHoras, sla: linhas })
    );
  }

  async function criarEntregavel() {
    const titulo = novoEntregavel.trim();
    if (!titulo) return;
    const ok = await chamar(`/api/clients/${clientId}/contrato/entregaveis`, json("POST", { titulo }));
    if (ok) setNovoEntregavel("");
  }

  async function gerarDemandas() {
    setGerando(true);
    setGerouMsg("");
    setErro("");
    const res = await fetch(`/api/clients/${clientId}/contrato/plano`, { method: "POST" });
    setGerando(false);
    if (!res.ok) {
      const b = await res.json().catch(() => ({}));
      setErro((b as { error?: string }).error ?? `não consegui disparar o planejador (HTTP ${res.status})`);
      return;
    }
    setGerouMsg(
      "Planejador disparado. Ele lê os entregáveis, propõe as demandas e elas aparecem no quadro em alguns minutos."
    );
  }

  // --- sem contrato ainda ---
  if (!tipo || !contrato) {
    return (
      <section className="contrato-vazio">
        <h3>Como esta conta é vendida?</h3>
        <p>
          A escolha muda o que o time acompanha, não só um rótulo. Dá para trocar depois — o que já
          estiver preenchido do outro tipo fica guardado.
        </p>
        {canManage ? (
          <div className="tipo-escolha">
            <button type="button" className="tipo-card" onClick={() => definirTipo("ams")} disabled={salvando}>
              <strong>AMS</strong>
              <span>Balde de horas que renova, com SLA a cumprir. Acompanha consumo.</span>
            </button>
            <button type="button" className="tipo-card" onClick={() => definirTipo("projeto")} disabled={salvando}>
              <strong>Projeto</strong>
              <span>Escopo fechado, com entregáveis e data. Acompanha progresso.</span>
            </button>
          </div>
        ) : (
          <p className="save-note">Contrato ainda não cadastrado pelo time da Acxya.</p>
        )}
        {erro && <div className="auth-note error" role="alert">{erro}</div>}
      </section>
    );
  }

  return (
    <div className="contrato">
      <div className="contrato-head">
        <span className={`badge ${tipo === "ams" ? "sustentacao" : "projeto"}`}>
          {tipo === "ams" ? "AMS" : "projeto"}
        </span>
        <span className="save-note">{clientNome}</span>
        {canManage && (
          <button
            type="button"
            className="btn-ghost trocar-tipo"
            onClick={() => definirTipo(tipo === "ams" ? "projeto" : "ams")}
            disabled={salvando}
          >
            Mudar para {tipo === "ams" ? "projeto" : "AMS"}
          </button>
        )}
      </div>

      {erro && <div className="auth-note error" role="alert">{erro}</div>}

      {tipo === "ams" ? (
        <>
          <section className="painel-bloco">
            <div className="bloco-head">
              <h3>Horas contratadas</h3>
              <span className="save-note">por ciclo {contrato.cicloHoras}</span>
            </div>
            <div className="campos-linha">
              <div className="field">
                <label htmlFor="horas">Horas do ciclo</label>
                <input
                  id="horas"
                  type="number"
                  min={0}
                  max={10000}
                  inputMode="numeric"
                  defaultValue={contrato.horasContratadas}
                  disabled={!canManage}
                  onBlur={(e) => salvarCampo("horasContratadas", Number(e.target.value))}
                />
              </div>
              <div className="field">
                <label htmlFor="ciclo">Ciclo</label>
                <select
                  id="ciclo"
                  defaultValue={contrato.cicloHoras}
                  disabled={!canManage}
                  onChange={(e) => salvarCampo("cicloHoras", e.target.value)}
                >
                  <option value="mensal">mensal</option>
                  <option value="trimestral">trimestral</option>
                </select>
              </div>
            </div>
          </section>

          <section className="painel-bloco">
            <div className="bloco-head">
              <h3>Consumo</h3>
              <span className="save-note">
                horas lançadas nas demandas deste cliente, pelo mês em que o trabalho aconteceu
              </span>
            </div>
            <HorasChart dados={horas} />
          </section>

          <section className="painel-bloco">
            <div className="bloco-head">
              <h3>SLA</h3>
              <span className="save-note">o prazo que o time consulta quando chega um chamado</span>
            </div>
            <div className="tabela-wrap">
              <table className="sla">
                <thead>
                  <tr>
                    <th>Severidade</th>
                    <th>1ª resposta</th>
                    <th>Resolução</th>
                  </tr>
                </thead>
                <tbody>
                  {sla.length === 0 ? (
                    <tr><td colSpan={3} className="save-note">Nenhuma severidade definida.</td></tr>
                  ) : (
                    sla.map((linha, i) => (
                      <tr key={`${linha.severidade}-${i}`}>
                        <td>{linha.severidade}</td>
                        <td className="mono">
                          <input
                            type="number"
                            min={0}
                            aria-label={`Primeira resposta para severidade ${linha.severidade}, em horas`}
                            defaultValue={linha.primeiraRespostaHoras}
                            disabled={!canManage}
                            onBlur={(e) => {
                              const copia = sla.map((l, j) =>
                                j === i ? { ...l, primeiraRespostaHoras: Number(e.target.value) } : l
                              );
                              salvarSla(copia);
                            }}
                          />
                          h
                        </td>
                        <td className="mono">
                          <input
                            type="number"
                            min={0}
                            aria-label={`Resolução para severidade ${linha.severidade}, em horas`}
                            defaultValue={linha.resolucaoHoras}
                            disabled={!canManage}
                            onBlur={(e) => {
                              const copia = sla.map((l, j) =>
                                j === i ? { ...l, resolucaoHoras: Number(e.target.value) } : l
                              );
                              salvarSla(copia);
                            }}
                          />
                          h
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </>
      ) : (
        <>
          <section className="painel-bloco">
            <div className="bloco-head">
              <h3>Progresso</h3>
              <span className="save-note">
                ponderado pelo peso — {progresso.concluidos} de {progresso.total} entregáveis
              </span>
            </div>
            <div className="progresso-grande">
              <div
                className="progresso-trilho"
                role="progressbar"
                aria-valuenow={progresso.pct}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label={`${progresso.pct} por cento do projeto concluído`}
              >
                <div className="progresso-barra" style={{ width: `${progresso.pct}%` }} />
              </div>
              <strong className="progresso-pct mono">{progresso.pct}%</strong>
            </div>
          </section>

          <section className="painel-bloco">
            <div className="bloco-head"><h3>Cadastro do projeto</h3></div>
            <div className="campos-linha">
              <div className="field grow">
                <label htmlFor="pnome">Nome do projeto</label>
                <input id="pnome" type="text" defaultValue={contrato.projetoNome} disabled={!canManage}
                  onBlur={(e) => salvarCampo("projetoNome", e.target.value)} />
              </div>
              <div className="field">
                <label htmlFor="pini">Início</label>
                <input id="pini" type="date" disabled={!canManage}
                  defaultValue={contrato.inicioEm ? new Date(contrato.inicioEm).toISOString().slice(0, 10) : ""}
                  onBlur={(e) => salvarCampo("inicioEm", e.target.value || null)} />
              </div>
              <div className="field">
                <label htmlFor="pfim">Fim previsto</label>
                <input id="pfim" type="date" disabled={!canManage}
                  defaultValue={contrato.fimPrevistoEm ? new Date(contrato.fimPrevistoEm).toISOString().slice(0, 10) : ""}
                  onBlur={(e) => salvarCampo("fimPrevistoEm", e.target.value || null)} />
              </div>
            </div>
            <div className="field">
              <label htmlFor="pesc">Escopo contratado</label>
              <textarea id="pesc" defaultValue={contrato.projetoEscopo} disabled={!canManage}
                placeholder="o que foi vendido, em poucas linhas — é o que o planejador lê"
                onBlur={(e) => salvarCampo("projetoEscopo", e.target.value)} />
            </div>
          </section>

          <section className="painel-bloco">
            <div className="bloco-head">
              <h3>Entregáveis contratados</h3>
              <span className="save-note">marque quando o entregável fechar</span>
            </div>

            {entregaveis.length === 0 ? (
              <p className="painel-vazio">
                Nenhum entregável ainda. É esta lista que o planejador lê para propor as demandas.
              </p>
            ) : (
              <ul className="entregaveis">
                {entregaveis.map((e) => {
                  const d = demandasPorEntregavel[e.id] ?? { total: 0, entregues: 0 };
                  return (
                    <li key={e.id} className={e.concluido ? "feito" : undefined}>
                      <label>
                        <input
                          type="checkbox"
                          checked={e.concluido}
                          disabled={!canManage || salvando}
                          onChange={() =>
                            chamar(
                              `/api/clients/${clientId}/contrato/entregaveis/${e.id}`,
                              json("PATCH", { concluido: !e.concluido })
                            )
                          }
                        />
                        <span className="ent-titulo">{e.titulo}</span>
                      </label>
                      <span className="ent-meta mono">
                        peso {e.peso}
                        {d.total > 0 && ` · ${d.entregues}/${d.total} demandas`}
                      </span>
                      {canManage && (
                        <button
                          type="button"
                          className="btn-remover"
                          disabled={salvando}
                          aria-label={`Remover entregável ${e.titulo}`}
                          onClick={() =>
                            chamar(`/api/clients/${clientId}/contrato/entregaveis/${e.id}`, { method: "DELETE" })
                          }
                        >
                          remover
                        </button>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}

            {canManage && (
              <>
                <div className="linha-nova">
                  <label className="sr-only" htmlFor="novo-entregavel">Novo entregável</label>
                  <input
                    id="novo-entregavel"
                    type="text"
                    value={novoEntregavel}
                    onChange={(ev) => setNovoEntregavel(ev.target.value)}
                    onKeyDown={(ev) => ev.key === "Enter" && criarEntregavel()}
                    placeholder="o que foi vendido"
                  />
                  <button type="button" className="btn-secondary" onClick={criarEntregavel}
                    disabled={salvando || !novoEntregavel.trim()}>
                    Adicionar
                  </button>
                </div>

                <div className="gerar-demandas">
                  <button type="button" className="btn-primary" onClick={gerarDemandas}
                    disabled={gerando || entregaveis.length === 0}>
                    {gerando ? "Disparando..." : "Gerar demandas dos entregáveis"}
                  </button>
                  <p className="save-note">
                    O agente planejador quebra cada entregável nas demandas que ele vira e põe no
                    quadro, em <code className="mono">backlog</code>. Nada é materializado nem
                    executado — quem decide o que entra na esteira continua sendo você.
                  </p>
                  {gerouMsg && <p className="auth-note ok" role="status">{gerouMsg}</p>}
                </div>
              </>
            )}
          </section>
        </>
      )}
    </div>
  );
}
