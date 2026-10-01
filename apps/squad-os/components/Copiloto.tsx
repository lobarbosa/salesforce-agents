"use client";

import { useEffect, useId, useRef, useState, type KeyboardEvent } from "react";
import { usePathname } from "next/navigation";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import type { CopilotUIMessage } from "@/lib/copilot/tipos";
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
// Dois jeitos de montar:
// - Dentro da página de um cliente (`ClientDetail.tsx`): passa `clientId` e
//   `clientNome` — todo papel (cliente, consultor, admin) só conversa sobre
//   ESTE cliente enquanto está aqui.
// - Em qualquer outra tela (`app/(app)/layout.tsx`, montado uma vez pra todo
//   papel): sem `clientId`. Se o caminho for `/clients/...`, esta instância
//   se anula (`null`) — a de dentro da página, que já tem o nome do
//   cliente à mão, é quem aparece ali. Evita dois ícones flutuantes ao
//   mesmo tempo sem precisar de estado compartilhado entre as duas árvores.
//
// Não é um modal (`role="dialog"`): o resto da tela continua clicável por
// trás, igual todo chat flutuante — mas fecha com Escape do mesmo jeito que
// Modal.tsx, e devolve o foco pro botão que abriu, que é o essencial do
// padrão pra quem navega só por teclado.
export function Copiloto({
  papel,
  clientId,
  clientNome,
}: {
  papel: Role;
  clientId?: string;
  clientNome?: string;
}) {
  const pathname = usePathname();
  const [aberto, setAberto] = useState(false);
  const [texto, setTexto] = useState("");
  const painelId = useId();
  const botaoRef = useRef<HTMLButtonElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fimDaLista = useRef<HTMLDivElement>(null);

  const { messages, sendMessage, status, error, clearError } = useChat<CopilotUIMessage>({
    transport: new DefaultChatTransport({ api: "/api/copilot/chat", body: { clientId } }),
  });

  const carregando = status === "submitted" || status === "streaming";

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
    void sendMessage({ text: valor });
  }

  function aoTeclarInput(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      enviar();
    }
  }

  // Instância "geral" (sem clientId) numa página de cliente: a de dentro de
  // ClientDetail.tsx já cobre esta tela, com o nome do cliente à mão — dois
  // ícones flutuantes ao mesmo tempo só confundiria sobre qual conversa é
  // sobre o quê.
  if (!clientId && pathname?.startsWith("/clients/")) return null;

  const introducao = clientNome
    ? `Pergunte sobre o andamento das demandas ou do contrato de ${clientNome}, ou descreva um pedido novo para eu ajudar a registrar.`
    : papel === "financeiro"
      ? "Pergunte sobre contas a pagar, divergências abertas, horas por cliente ou o painel financeiro."
      : papel === "admin"
        ? "Pergunte sobre o financeiro, ou abra a página de um cliente para eu ajudar com demandas e contrato dele."
        : "Abra a página de um cliente para eu ajudar com demandas e contrato dele.";

  return (
    <>
      <button
        ref={botaoRef}
        type="button"
        className="copiloto-fab"
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
            <span>Copiloto</span>
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
                  if (part.type === "text") return <p key={i}>{part.text}</p>;
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
              Não consegui falar com o copiloto agora. Tente de novo em instantes.{" "}
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
