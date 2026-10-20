"use client";

import { navegarAbas } from "@/lib/abas";
import { BotaoRemover } from "@/components/BotaoRemover";
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type {
  Anexo,
  ChecklistItem,
  Comentario,
  RegistroTempo,
  Subtarefa,
} from "@/lib/generated/prisma/client";
import { formatarMinutos, formatarTamanho, timeAgo } from "@/lib/demandas";
import { acceptDo, TAMANHO_MAX_ARQUIVO, TAMANHO_MAX_MB } from "@/lib/upload-regras";

type Aba = "atividade" | "subtarefas" | "checklist" | "tempo" | "anexos";

export interface PainelDados {
  comentarios: Comentario[];
  subtarefas: Subtarefa[];
  checklist: ChecklistItem[];
  tempos: RegistroTempo[];
  anexos: Anexo[];
}

// Uma barra + contador por aba em vez de cinco seções empilhadas: o modal já
// carrega descrição, perguntas e gate de aprovação, e emendar mais quatro
// listas embaixo transformaria a rolagem no trabalho principal. O contador em
// cada aba é o que evita o custo clássico de esconder conteúdo — dá pra ver
// que existem 3 anexos sem abrir a aba de anexos.
const ABAS: { id: Aba; label: string }[] = [
  { id: "atividade", label: "Atividade" },
  { id: "subtarefas", label: "Subtarefas" },
  { id: "checklist", label: "Checklist" },
  { id: "tempo", label: "Tempo" },
  { id: "anexos", label: "Anexos" },
];

// O que o cliente vê do painel. Atividade e Anexos são conversa com ele —
// ele comenta, manda o print do erro, baixa o que foi entregue. Tempo entra
// porque o consumo é dele (casa com a aba Contrato), mas só o total: quem
// lançou cada hora e em que trabalhou é condução interna do time.
// Subtarefas e Checklist ficam de fora inteiras — são a quebra técnica e a
// conferência antes de entregar, não a entrega.
const ABAS_CLIENTE: Aba[] = ["atividade", "tempo", "anexos"];

function Progresso({ feitos, total }: { feitos: number; total: number }) {
  const pct = total === 0 ? 0 : Math.round((feitos / total) * 100);
  return (
    <div className="progresso">
      <div
        className="progresso-trilho"
        role="progressbar"
        aria-valuenow={feitos}
        aria-valuemin={0}
        aria-valuemax={total}
        aria-label={`${feitos} de ${total} concluídos`}
      >
        <div className="progresso-barra" style={{ width: `${pct}%` }} />
      </div>
      <span className="progresso-num mono">
        {feitos}/{total}
      </span>
    </div>
  );
}

export function DemandaPainel({
  demandaId,
  usuarioEmail,
  isAdmin,
  visaoCliente = false,
  dados,
}: {
  demandaId: string;
  usuarioEmail: string;
  isAdmin: boolean;
  /** Esconde o que é instrumento interno de delivery — ver ABAS_CLIENTE. */
  visaoCliente?: boolean;
  dados: PainelDados;
}) {
  const router = useRouter();
  const [aba, setAba] = useState<Aba>("atividade");
  const [erro, setErro] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);

  const [comentarios, setComentarios] = useState(dados.comentarios);
  const [subtarefas, setSubtarefas] = useState(dados.subtarefas);
  const [checklist, setChecklist] = useState(dados.checklist);
  const [tempos, setTempos] = useState(dados.tempos);
  const [anexos, setAnexos] = useState(dados.anexos);

  const [novoComentario, setNovoComentario] = useState("");
  const [novaSubtarefa, setNovaSubtarefa] = useState("");
  const [novoItem, setNovoItem] = useState("");
  const [descricaoTempo, setDescricaoTempo] = useState("");
  const [minutosManuais, setMinutosManuais] = useState("");
  const arquivoRef = useRef<HTMLInputElement>(null);

  const rodando = tempos.find((t) => t.fimEm === null && t.autorEmail === usuarioEmail) ?? null;

  // Só existe pra fazer o cronômetro em curso avançar na tela; sem isso o
  // "12min" congela no valor de quando o modal abriu e parece travado. O
  // intervalo só roda enquanto há um registro aberto.
  const [agora, setAgora] = useState(() => Date.now());
  useEffect(() => {
    if (!rodando) return;
    const t = setInterval(() => setAgora(Date.now()), 1000);
    return () => clearInterval(t);
  }, [rodando]);

  // Toda escrita passa por aqui: uma única trava de "ocupado", uma única
  // mensagem de erro e um único router.refresh(). Repetir esse trio em nove
  // handlers era onde os estados iam divergir.
  async function chamar<T>(
    url: string,
    init: RequestInit,
    aoSucesso: (corpo: T) => void
  ): Promise<boolean> {
    setOcupado(true);
    setErro(null);
    try {
      const res = await fetch(url, init);
      if (!res.ok) {
        // 413 vem da Vercel antes da rota, sem JSON.
        const corpo = res.status === 413 ? null : await res.json().catch(() => null);
        setErro(
          res.status === 413
            ? `arquivo grande demais — o limite é ${TAMANHO_MAX_MB} MB`
            : corpo?.error ?? `não consegui salvar (HTTP ${res.status}) — tente de novo`
        );
        return false;
      }
      aoSucesso(res.status === 204 ? (null as T) : ((await res.json()) as T));
      router.refresh();
      return true;
    } catch {
      setErro("sem conexão com o servidor — tente de novo");
      return false;
    } finally {
      setOcupado(false);
    }
  }

  const json = (body: unknown): RequestInit => ({
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  async function comentar() {
    const texto = novoComentario.trim();
    if (!texto) return;
    const ok = await chamar<Comentario>(
      `/api/demandas/${demandaId}/comentarios`,
      json({ texto }),
      (c) => setComentarios((atuais) => [...atuais, c])
    );
    if (ok) setNovoComentario("");
  }

  async function criarSubtarefa() {
    const titulo = novaSubtarefa.trim();
    if (!titulo) return;
    const ok = await chamar<Subtarefa>(
      `/api/demandas/${demandaId}/subtarefas`,
      json({ titulo }),
      (s) => setSubtarefas((atuais) => [...atuais, s])
    );
    if (ok) setNovaSubtarefa("");
  }

  function alternarSubtarefa(s: Subtarefa) {
    chamar<Subtarefa>(
      `/api/demandas/${demandaId}/subtarefas/${s.id}`,
      { ...json({ feita: !s.feita }), method: "PATCH" },
      (atualizada) =>
        setSubtarefas((atuais) => atuais.map((x) => (x.id === atualizada.id ? atualizada : x)))
    );
  }

  function removerSubtarefa(id: string) {
    chamar<null>(`/api/demandas/${demandaId}/subtarefas/${id}`, { method: "DELETE" }, () =>
      setSubtarefas((atuais) => atuais.filter((x) => x.id !== id))
    );
  }

  async function criarItem() {
    const texto = novoItem.trim();
    if (!texto) return;
    const ok = await chamar<ChecklistItem>(
      `/api/demandas/${demandaId}/checklist`,
      json({ texto }),
      (i) => setChecklist((atuais) => [...atuais, i])
    );
    if (ok) setNovoItem("");
  }

  function alternarItem(i: ChecklistItem) {
    chamar<ChecklistItem>(
      `/api/demandas/${demandaId}/checklist/${i.id}`,
      { ...json({ feito: !i.feito }), method: "PATCH" },
      (atualizado) =>
        setChecklist((atuais) => atuais.map((x) => (x.id === atualizado.id ? atualizado : x)))
    );
  }

  function removerItem(id: string) {
    chamar<null>(`/api/demandas/${demandaId}/checklist/${id}`, { method: "DELETE" }, () =>
      setChecklist((atuais) => atuais.filter((x) => x.id !== id))
    );
  }

  async function iniciarCronometro() {
    const ok = await chamar<RegistroTempo>(
      `/api/demandas/${demandaId}/tempo`,
      json({ descricao: descricaoTempo.trim() }),
      (r) => setTempos((atuais) => [r, ...atuais])
    );
    if (ok) setDescricaoTempo("");
  }

  function pararCronometro(id: string) {
    chamar<RegistroTempo>(
      `/api/demandas/${demandaId}/tempo/${id}`,
      { ...json({ parar: true }), method: "PATCH" },
      (r) => setTempos((atuais) => atuais.map((x) => (x.id === r.id ? r : x)))
    );
  }

  async function lancarManual() {
    const minutos = Number(minutosManuais);
    if (!Number.isFinite(minutos) || minutos <= 0) {
      setErro("informe quantos minutos lançar");
      return;
    }
    const ok = await chamar<RegistroTempo>(
      `/api/demandas/${demandaId}/tempo`,
      json({ minutos, descricao: descricaoTempo.trim() }),
      (r) => setTempos((atuais) => [r, ...atuais])
    );
    if (ok) {
      setMinutosManuais("");
      setDescricaoTempo("");
    }
  }

  function removerTempo(id: string) {
    chamar<null>(`/api/demandas/${demandaId}/tempo/${id}`, { method: "DELETE" }, () =>
      setTempos((atuais) => atuais.filter((x) => x.id !== id))
    );
  }

  async function enviarArquivo(file: File) {
    if (file.size > TAMANHO_MAX_ARQUIVO) {
      setErro(`arquivo grande demais — o limite é ${TAMANHO_MAX_MB} MB`);
      if (arquivoRef.current) arquivoRef.current.value = "";
      return;
    }
    const form = new FormData();
    form.append("arquivo", file);
    const ok = await chamar<Anexo>(
      `/api/demandas/${demandaId}/anexos`,
      { method: "POST", body: form },
      (a) => setAnexos((atuais) => [a, ...atuais])
    );
    if (ok && arquivoRef.current) arquivoRef.current.value = "";
  }

  // Liberar é declarar que o arquivo não tem dado pessoal de cliente — é o
  // que permite ele entrar na sessão do agente (guardrail #2). O confirm é a
  // declaração; a rota recusa liberar sem ela.
  function alternarLiberacao(a: Anexo) {
    const liberar = !a.liberadoEm;
    if (
      liberar &&
      !window.confirm(
        `Liberar "${a.nome}" para o agente?\n\n` +
          "Confirmo que este arquivo não mostra nome, e-mail, CPF, telefone ou valores de cliente. " +
          "Print de tela do Salesforce costuma mostrar — confira antes."
      )
    ) {
      return;
    }
    chamar<Anexo>(
      `/api/demandas/${demandaId}/anexos/${a.id}`,
      {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ liberado: liberar, semDadoPessoal: liberar }),
      },
      (atualizado) => setAnexos((atuais) => atuais.map((x) => (x.id === a.id ? atualizado : x)))
    );
  }

  function removerAnexo(id: string) {
    chamar<null>(`/api/demandas/${demandaId}/anexos/${id}`, { method: "DELETE" }, () =>
      setAnexos((atuais) => atuais.filter((x) => x.id !== id))
    );
  }

  const totalMinutos = tempos.reduce((soma, t) => soma + (t.minutos ?? 0), 0);
  const emCurso = rodando
    ? Math.max(1, Math.round((agora - new Date(rodando.inicioEm).getTime()) / 60_000))
    : 0;

  const contagem: Record<Aba, number> = {
    atividade: comentarios.length,
    subtarefas: subtarefas.length,
    checklist: checklist.length,
    // Pro cliente a aba mostra só o total de horas, então o número de
    // lançamentos ao lado do rótulo prometeria uma lista que ele não vai ver.
    tempo: visaoCliente ? 0 : tempos.length,
    anexos: anexos.length,
  };

  const abas = visaoCliente ? ABAS.filter((a) => ABAS_CLIENTE.includes(a.id)) : ABAS;

  return (
    <section className="painel">
      <div className="painel-abas" role="tablist" onKeyDown={navegarAbas} aria-label="Detalhes da demanda">
        {abas.map((a) => (
          <button
            key={a.id}
            type="button"
            role="tab"
            id={`painel-aba-${a.id}`}
            aria-selected={aba === a.id}
            tabIndex={aba === a.id ? 0 : -1}
            aria-controls={aba === a.id ? `painel-pane-${a.id}` : undefined}
            className={`painel-aba${aba === a.id ? " active" : ""}`}
            onClick={() => setAba(a.id)}
          >
            {a.label}
            {contagem[a.id] > 0 && <span className="painel-count">{contagem[a.id]}</span>}
          </button>
        ))}
      </div>

      {erro && (
        <div className="auth-note error" role="alert" style={{ marginBottom: "0.7rem" }}>
          {erro}
        </div>
      )}

      <div
        className="painel-pane"
        role="tabpanel"
        id={`painel-pane-${aba}`}
        aria-labelledby={`painel-aba-${aba}`}
        aria-busy={ocupado}
        tabIndex={0}
      >
        {aba === "atividade" && (
          <>
            {comentarios.length === 0 ? (
              <p className="painel-vazio">Nenhum comentário ainda.</p>
            ) : (
              <ol className="atividade-lista">
                {comentarios.map((c) => (
                  <li key={c.id}>
                    <div className="atividade-meta">
                      <strong>{c.autor}</strong>
                      <span className="mono">{timeAgo(c.criadoEm)}</span>
                    </div>
                    <p className="atividade-texto">{c.texto}</p>
                  </li>
                ))}
              </ol>
            )}
            <div className="field">
              <label htmlFor="novo-comentario">Escreva um comentário</label>
              <textarea
                id="novo-comentario"
                value={novoComentario}
                onChange={(e) => setNovoComentario(e.target.value)}
                placeholder="o que precisa ficar registrado nesta demanda"
              />
              <div style={{ marginTop: "0.5rem" }}>
                <button
                  className="btn-secondary"
                  type="button"
                  onClick={comentar}
                  disabled={ocupado || !novoComentario.trim()}
                >
                  {ocupado ? "Enviando..." : "Comentar"}
                </button>
              </div>
            </div>
          </>
        )}

        {aba === "subtarefas" && (
          <>
            {subtarefas.length > 0 && (
              <Progresso feitos={subtarefas.filter((s) => s.feita).length} total={subtarefas.length} />
            )}
            {subtarefas.length === 0 ? (
              <p className="painel-vazio">
                Sem subtarefas. Use para quebrar a demanda no que precisa ser construído.
              </p>
            ) : (
              <ul className="lista-marcavel">
                {subtarefas.map((s) => (
                  <li key={s.id} className={s.feita ? "feito" : undefined}>
                    <label>
                      <input
                        type="checkbox"
                        checked={s.feita}
                        disabled={ocupado}
                        onChange={() => alternarSubtarefa(s)}
                      />
                      <span>{s.titulo}</span>
                    </label>
                    <BotaoRemover nome={`subtarefa ${s.titulo}`} disabled={ocupado} onRemover={() => removerSubtarefa(s.id)} />
                  </li>
                ))}
              </ul>
            )}
            <div className="linha-nova">
              <label className="sr-only" htmlFor="nova-subtarefa">
                Nova subtarefa
              </label>
              <input
                id="nova-subtarefa"
                type="text"
                value={novaSubtarefa}
                onChange={(e) => setNovaSubtarefa(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && criarSubtarefa()}
                placeholder="o que precisa ser feito"
              />
              <button
                type="button"
                className="btn-secondary"
                onClick={criarSubtarefa}
                disabled={ocupado || !novaSubtarefa.trim()}
              >
                Adicionar
              </button>
            </div>
          </>
        )}

        {aba === "checklist" && (
          <>
            {checklist.length > 0 && (
              <Progresso feitos={checklist.filter((i) => i.feito).length} total={checklist.length} />
            )}
            {checklist.length === 0 ? (
              <p className="painel-vazio">
                Sem itens. Use para o que precisa ser conferido antes de entregar.
              </p>
            ) : (
              <ul className="lista-marcavel">
                {checklist.map((i) => (
                  <li key={i.id} className={i.feito ? "feito" : undefined}>
                    <label>
                      <input
                        type="checkbox"
                        checked={i.feito}
                        disabled={ocupado}
                        onChange={() => alternarItem(i)}
                      />
                      <span>{i.texto}</span>
                    </label>
                    <BotaoRemover nome={`item ${i.texto}`} disabled={ocupado} onRemover={() => removerItem(i.id)} />
                  </li>
                ))}
              </ul>
            )}
            <div className="linha-nova">
              <label className="sr-only" htmlFor="novo-item">
                Novo item de checklist
              </label>
              <input
                id="novo-item"
                type="text"
                value={novoItem}
                onChange={(e) => setNovoItem(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && criarItem()}
                placeholder="o que precisa ser conferido"
              />
              <button
                type="button"
                className="btn-secondary"
                onClick={criarItem}
                disabled={ocupado || !novoItem.trim()}
              >
                Adicionar
              </button>
            </div>
          </>
        )}

        {aba === "tempo" && visaoCliente && (
          <div className="tempo-total">
            <strong>{formatarMinutos(totalMinutos)}</strong> nesta demanda
            <p className="painel-vazio" style={{ marginTop: "0.4rem" }}>
              Horas já fechadas que entram no consumo do contrato. O total por mês, contra o
              contratado, fica na aba Contrato.
            </p>
          </div>
        )}

        {aba === "tempo" && !visaoCliente && (
          <>
            <div className="tempo-total">
              <strong>{formatarMinutos(totalMinutos)}</strong> lançados
              {rodando && (
                <span className="tempo-rodando" role="status">
                  ● {formatarMinutos(emCurso)} em curso
                </span>
              )}
            </div>

            {rodando ? (
              <button
                type="button"
                className="btn-primary"
                onClick={() => pararCronometro(rodando.id)}
                disabled={ocupado}
              >
                Parar cronômetro
              </button>
            ) : (
              <div className="tempo-form">
                <div className="field">
                  <label htmlFor="tempo-descricao">No que você trabalhou (opcional)</label>
                  <input
                    id="tempo-descricao"
                    type="text"
                    value={descricaoTempo}
                    onChange={(e) => setDescricaoTempo(e.target.value)}
                    placeholder="ex.: recon da org, ajuste no Flow"
                  />
                </div>
                <div className="tempo-acoes">
                  <button
                    type="button"
                    className="btn-primary"
                    onClick={iniciarCronometro}
                    disabled={ocupado}
                  >
                    Iniciar cronômetro
                  </button>
                  <span className="tempo-ou">ou lance direto</span>
                  <label className="sr-only" htmlFor="tempo-minutos">
                    Minutos a lançar
                  </label>
                  <input
                    id="tempo-minutos"
                    className="tempo-minutos"
                    type="number"
                    min={1}
                    max={1440}
                    inputMode="numeric"
                    value={minutosManuais}
                    onChange={(e) => setMinutosManuais(e.target.value)}
                    placeholder="min"
                  />
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={lancarManual}
                    disabled={ocupado || !minutosManuais.trim()}
                  >
                    Lançar
                  </button>
                </div>
              </div>
            )}

            {tempos.length === 0 ? (
              <p className="painel-vazio">Nenhum tempo lançado ainda.</p>
            ) : (
              <ul className="tempo-lista">
                {tempos.map((t) => {
                  const meu = t.autorEmail === usuarioEmail;
                  return (
                    <li key={t.id}>
                      <div>
                        <strong className="mono">
                          {t.fimEm ? formatarMinutos(t.minutos ?? 0) : "em curso"}
                        </strong>
                        <span className="tempo-quem">{t.autor}</span>
                        {t.descricao && <span className="tempo-desc">{t.descricao}</span>}
                      </div>
                      <div className="tempo-linha-acoes">
                        <span className="mono">{timeAgo(t.inicioEm)}</span>
                        {(meu || isAdmin) && (
                          <BotaoRemover nome={`lançamento de ${t.autor}`} disabled={ocupado} onRemover={() => removerTempo(t.id)} />
                        )}
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </>
        )}

        {aba === "anexos" && (
          <>
            {anexos.length === 0 ? (
              <p className="painel-vazio">Nenhum anexo. Até {TAMANHO_MAX_MB} MB por arquivo (PDF, imagem, planilha, documento ou texto).</p>
            ) : (
              <ul className="anexo-lista">
                {anexos.map((a) => (
                  <li key={a.id}>
                    {/* Link normal e não fetch: a rota devolve um redirect pra
                        URL assinada, então o download sai pelo próprio browser. */}
                    <a href={`/api/demandas/${demandaId}/anexos/${a.id}`}>{a.nome}</a>
                    <span className="anexo-meta mono">
                      {formatarTamanho(a.tamanho)} · {a.autor} · {timeAgo(a.criadoEm)}
                      {a.liberadoEm && !visaoCliente && <> · visível ao agente</>}
                    </span>
                    {!visaoCliente && (
                      <button
                        type="button"
                        className="btn-remover"
                        onClick={() => alternarLiberacao(a)}
                        disabled={ocupado}
                        aria-pressed={Boolean(a.liberadoEm)}
                        title={
                          a.liberadoEm
                            ? `Liberado por ${a.liberadoPorEmail ?? "—"}. O agente lê este arquivo na próxima etapa.`
                            : "Só gente vê este anexo. Libere para o agente ler na próxima etapa."
                        }
                      >
                        {a.liberadoEm ? "revogar do agente" : "liberar p/ agente"}
                      </button>
                    )}
                    {(a.autorEmail === usuarioEmail || isAdmin) && (
                      <BotaoRemover nome={`anexo ${a.nome}`} disabled={ocupado} onRemover={() => removerAnexo(a.id)} />
                    )}
                  </li>
                ))}
              </ul>
            )}
            <div className="field">
              <label htmlFor="novo-anexo">Anexar arquivo</label>
              <input
                id="novo-anexo"
                ref={arquivoRef}
                type="file"
                accept={acceptDo("anexo")}
                disabled={ocupado}
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) enviarArquivo(file);
                }}
              />
              {ocupado && (
                <p className="painel-vazio" role="status">
                  Enviando...
                </p>
              )}
            </div>
          </>
        )}
      </div>
    </section>
  );
}
