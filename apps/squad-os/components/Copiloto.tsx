"use client";

import { useEffect, useId, useRef, useState, type KeyboardEvent } from "react";
import { usePathname } from "next/navigation";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import type { CopilotUIMessage } from "@/lib/copilot/tipos";
import { MAX_CHARS_MENSAGEM } from "@/lib/copilot/limites";
import type { Role } from "@/lib/generated/prisma/client";

// Ícone flutuante no canto da tela — não uma aba: fica alcançável em
// Demandas, Contrato ou qualquer tela geral sem trocar de lugar. Guardrails
// de conteúdo (o que o copiloto pode e não pode fazer, por papel) vivem no
// system prompt do servidor (app/api/copilot/chat/route.ts); aqui é só a
// superfície: abrir/fechar, mandar mensagem, mostrar o que voltou, avisar
// erro perto de onde ele aconteceu (achado da própria auditoria de UX deste
// app: falha muda em formulário já causou confusão em outro lugar do Squad
// OS — não repetir aqui).
//
// Uma instância só, montada no layout (2026-10-30). Antes havia três — a do
// layout e duas em ClientDetail.tsx — cada uma com a própria conversa: abrir
// a página de um cliente começava do zero, voltar pra Visão Geral reaparecia
// a conversa antiga, e trocar de um cliente pro outro mantinha o transporte
// com o clientId do primeiro (achado do próprio dono: "não segue o contexto
// quando muda de tela"). Agora a conversa é uma só e atravessa a navegação;
// o que muda por tela é o contexto, lido do caminho (`/clients/<id>`) e
// mandado a cada mensagem. O servidor continua decidindo o que esse
// contexto libera (canAccessClient) — o caminho é só a pergunta.
//
// A conversa sobrevive a recarregar a página (sessionStorage, por aba) e
// some ao fechar a aba ou em "Nova conversa".

// Não é um modal (`role="dialog"`): o resto da tela continua clicável por
// trás, igual todo chat flutuante — mas fecha com Escape do mesmo jeito que
// Modal.tsx, e devolve o foco pro botão que abriu, que é o essencial do
// padrão pra quem navega só por teclado.
const CHAVE_HISTORICO = "copiloto:conversa";

function lerHistorico(): CopilotUIMessage[] {
  if (typeof window === "undefined") return [];
  try {
    const bruto = window.sessionStorage.getItem(CHAVE_HISTORICO);
    const lista = bruto ? (JSON.parse(bruto) as unknown) : [];
    return Array.isArray(lista) ? (lista as CopilotUIMessage[]) : [];
  } catch {
    return [];
  }
}

export function Copiloto({ papel, clientes }: { papel: Role; clientes: { id: string; nome: string }[] }) {
  const pathname = usePathname();
  const clientId = pathname?.match(/^\/clients\/([^/?#]+)/)?.[1];
  const clientNome = clientes.find((c) => c.id === clientId)?.nome;
  const [aberto, setAberto] = useState(false);
  const [texto, setTexto] = useState("");
  const painelId = useId();
  const botaoRef = useRef<HTMLButtonElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fimDaLista = useRef<HTMLDivElement>(null);

  const [transport] = useState(() => new DefaultChatTransport<CopilotUIMessage>({ api: "/api/copilot/chat" }));
  const [historicoInicial] = useState(lerHistorico);
  const { messages, sendMessage, setMessages, regenerate, status, error, clearError } = useChat<CopilotUIMessage>({
    id: "copiloto",
    transport,
    messages: historicoInicial,
  });

  const carregando = status === "submitted" || status === "streaming";

  useEffect(() => {
    if (carregando) return;
    try {
      if (messages.length) window.sessionStorage.setItem(CHAVE_HISTORICO, JSON.stringify(messages.slice(-40)));
      else window.sessionStorage.removeItem(CHAVE_HISTORICO);
    } catch {}
  }, [messages, carregando]);

  useEffect(() => {
    if (!aberto) return;
    textareaRef.current?.focus();
    const aoTeclar = (e: globalThis.KeyboardEvent) => {
      if (e.key === "Escape") {
        setAberto(false);
        botaoRef.current?.focus();
      }
    };
    document.addEventListener("keydown", aoTeclar);
    return () => document.removeEventListener("keydown", aoTeclar);
  }, [aberto]);

  useEffect(() => {
    if (!aberto) return;
    fimDaLista.current?.scrollIntoView({ block: "end" });
  }, [messages, carregando, aberto]);

  function enviar() {
    const valor = texto.trim();
    if (!valor || carregando) return;
    setTexto("");
    // O contexto vai com cada mensagem, não no transporte: é o da tela em
    // que a pessoa está agora, mesmo que a conversa tenha começado em outra.
    void sendMessage({ text: valor }, { body: { clientId } });
  }

  function aoTeclarInput(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      enviar();
    }
  }

  const introducao = clientNome
    ? `Pergunte sobre o andamento das demandas ou do contrato de ${clientNome}, ou descreva um pedido novo para eu ajudar a registrar.`
    : papel === "financeiro"
      ? "Pergunte sobre contas a pagar, divergências abertas, horas por cliente ou o painel financeiro."
      : papel === "admin"
        ? "Pergunte o que está parado na esteira, sobre o financeiro, ou abra a página de um cliente para falar das demandas e do contrato dele."
        : "Pergunte o que está parado na esteira, ou abra a página de um cliente para falar das demandas e do contrato dele.";

  return (
    <>
      <button
        ref={botaoRef}
        type="button"
        className={`copiloto-fab${aberto ? " aberto" : ""}`}
        aria-expanded={aberto}
        aria-controls={painelId}
        onClick={() => setAberto((v) => !v)}
      >
        <span className="copiloto-fab-icone" aria-hidden="true" />
        Copiloto
      </button>

      {aberto && (
        <div id={painelId} className="copiloto-painel" role="region" aria-label="Copiloto">
          <div className="copiloto-cabecalho">
            <span>
              Copiloto
              <span className="copiloto-contexto"> · {clientNome ?? (clientId ? "cliente" : "geral")}</span>
            </span>
            {messages.length > 0 && !carregando && (
              <button type="button" className="btn-ghost" onClick={() => setMessages([])}>
                Nova conversa
              </button>
            )}
            <button
              type="button"
              className="copiloto-fechar"
              aria-label="Fechar copiloto"
              onClick={() => {
                setAberto(false);
                botaoRef.current?.focus();
              }}
            >
              ×
            </button>
          </div>

          <p className="copiloto-intro">{introducao}</p>

          <div className="copiloto-lista" role="log" aria-label="Conversa com o copiloto">
            {messages.length === 0 && !carregando && (
              <div className="copiloto-vazio">Nenhuma mensagem ainda — comece por baixo.</div>
            )}
            {messages.map((m) => (
              <div key={m.id} className={`copiloto-msg ${m.role}`}>
                <span className="copiloto-autor">{m.role === "user" ? "você" : "copiloto"}</span>
                {m.parts.map((part, i) => {
                  if (part.type === "text") return part.text.trim() ? <p key={i}>{part.text}</p> : null;
                  if (part.type.startsWith("tool-") && "state" in part) {
                    const nome = ROTULO_FERRAMENTA[part.type.slice(5)] ?? "os dados";
                    if (part.state === "input-streaming" || part.state === "input-available") {
                      return (
                        <p key={i} className="copiloto-acao consultando">
                          Consultando {nome}…
                        </p>
                      );
                    }
                    if (part.state === "output-error") {
                      return (
                        <p key={i} className="copiloto-acao erro">
                          Não consegui consultar {nome}.
                          {papel === "admin" && part.errorText ? ` [admin: ${part.errorText.slice(0, 200)}]` : ""}
                        </p>
                      );
                    }
                  }
                  if (
                    part.type === "tool-criar_demanda" &&
                    part.state === "output-available" &&
                    part.output.criada
                  ) {
                    return (
                      <p key={i} className="copiloto-acao">
                        ✓ Demanda <span className="mono">{part.output.code}</span> criada no
                        backlog: {part.output.titulo}
                      </p>
                    );
                  }
                  return null;
                })}
                {m.role === "assistant" && !(carregando && m.id === messages.at(-1)?.id) && respostaIncompleta(m) && (
                  <p className="copiloto-acao erro">
                    Não concluí esta resposta.{" "}
                    {papel === "admin" && m.metadata?.finishReason ? `[admin: parou por "${m.metadata.finishReason}"] ` : ""}
                    {m.id === messages.at(-1)?.id && (
                      <button type="button" className="btn-ghost" onClick={() => void regenerate({ body: { clientId } })}>
                        Tentar de novo
                      </button>
                    )}
                  </p>
                )}
              </div>
            ))}
            <div ref={fimDaLista} />
          </div>

          {/* Não anuncia token a token (spam pra leitor de tela) — só a
              transição de "está respondendo" pra "respondeu", igual ao
              padrão já usado em Timesheet.tsx pro aviso de autosave. */}
          <p className="sr-only" role="status" aria-live="polite">
            {carregando ? "Copiloto está respondendo…" : ""}
          </p>

          {error && (
            <div className="auth-note error" role="alert">
              {/* A rota já devolve texto pronto pra pessoa (genérico, ou com o
                  motivo técnico pro admin — ver onError em route.ts). Um 429/400
                  vem como JSON {error}; mostra só o campo. */}
              {mensagemDeErro(error)}{" "}
              <button type="button" className="btn-ghost" onClick={clearError}>
                Ok
              </button>
            </div>
          )}

          <div className="copiloto-input">
            <label htmlFor="copiloto-texto" className="sr-only">
              Sua mensagem
            </label>
            <textarea
              ref={textareaRef}
              id="copiloto-texto"
              placeholder="Escreva sua pergunta ou pedido…"
              value={texto}
              onChange={(e) => setTexto(e.target.value)}
              onKeyDown={aoTeclarInput}
              rows={2}
              maxLength={MAX_CHARS_MENSAGEM}
            />
            <button
              className="btn-primary"
              type="button"
              onClick={enviar}
              disabled={carregando || !texto.trim()}
            >
              {carregando ? "Enviando…" : "Enviar"}
            </button>
          </div>
        </div>
      )}
    </>
  );
}

const ROTULO_FERRAMENTA: Record<string, string> = {
  consultar_demandas: "as demandas",
  consultar_contrato: "o contrato",
  consultar_parados: "o que está parado",
  criar_demanda: "o registro da demanda",
  consultar_painel_financeiro: "o painel financeiro",
  consultar_contas_a_pagar: "as contas a pagar",
  consultar_divergencias: "as divergências",
  consultar_horas_por_cliente: "as horas por cliente",
};

/**
 * Resposta que consultou ferramenta e não escreveu nada depois — o balão
 * "Vou consultar…" seguido de silêncio (achado de 2026-10-30).
 */
function respostaIncompleta(m: CopilotUIMessage): boolean {
  let ultimaFerramenta = -1;
  let ultimoTexto = -1;
  m.parts.forEach((p, i) => {
    if (p.type.startsWith("tool-")) ultimaFerramenta = i;
    if (p.type === "text" && p.text.trim()) ultimoTexto = i;
  });
  if (ultimoTexto === -1) return true;
  return ultimaFerramenta > ultimoTexto;
}

function mensagemDeErro(error: Error): string {
  const generico = "Não consegui falar com o copiloto agora. Tente de novo em instantes.";
  const bruto = (error.message || "").trim();
  if (!bruto) return generico;
  try {
    const j = JSON.parse(bruto) as { error?: unknown };
    if (typeof j.error === "string" && j.error) return j.error;
  } catch {}
  return bruto.length > 400 ? generico : bruto;
}
