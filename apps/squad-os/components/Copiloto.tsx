"use client";

import { useEffect, useRef, useState, type KeyboardEvent } from "react";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import type { CopilotUIMessage } from "@/lib/copilot/tipos";

// Chat do copiloto do cliente. Guardrails de conteúdo (o que ele pode e não
// pode fazer) vivem no system prompt do servidor (app/api/copilot/chat/
// route.ts) — aqui é só a superfície: mandar mensagem, mostrar o que voltou,
// avisar erro perto de onde ele aconteceu (achado da própria auditoria de UX
// deste app: falha muda em formulário já causou confusão em outro lugar do
// Squad OS — não repetir aqui).
export function Copiloto({ clientNome }: { clientNome: string }) {
  const [texto, setTexto] = useState("");
  const fimDaLista = useRef<HTMLDivElement>(null);

  const { messages, sendMessage, status, error, clearError } = useChat<CopilotUIMessage>({
    transport: new DefaultChatTransport({ api: "/api/copilot/chat" }),
  });

  const carregando = status === "submitted" || status === "streaming";

  useEffect(() => {
    fimDaLista.current?.scrollIntoView({ block: "end" });
  }, [messages, carregando]);

  function enviar() {
    const valor = texto.trim();
    if (!valor || carregando) return;
    setTexto("");
    void sendMessage({ text: valor });
  }

  function aoTeclar(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      enviar();
    }
  }

  return (
    <div className="copiloto">
      <p className="copiloto-intro">
        Pergunte sobre o andamento das demandas ou do contrato de {clientNome}, ou descreva um
        pedido novo para eu ajudar a registrar.
      </p>

      <div className="copiloto-lista" role="log" aria-label="Conversa com o copiloto">
        {messages.length === 0 && !carregando && (
          <div className="copiloto-vazio">Nenhuma mensagem ainda — comece por baixo.</div>
        )}
        {messages.map((m) => (
          <div key={m.id} className={`copiloto-msg ${m.role}`}>
            <span className="copiloto-autor">{m.role === "user" ? "você" : "copiloto"}</span>
            {m.parts.map((part, i) => {
              if (part.type === "text") return <p key={i}>{part.text}</p>;
              if (part.type === "tool-criar_demanda" && part.state === "output-available" && part.output.criada) {
                return (
                  <p key={i} className="copiloto-acao">
                    ✓ Demanda <span className="mono">{part.output.code}</span> criada no backlog:{" "}
                    {part.output.titulo}
                  </p>
                );
              }
              return null;
            })}
          </div>
        ))}
        <div ref={fimDaLista} />
      </div>

      {/* Não anuncia token a token (spam pra leitor de tela) — só a transição
          de "está respondendo" pra "respondeu", igual ao padrão já usado em
          Timesheet.tsx pro aviso de autosave. */}
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
          id="copiloto-texto"
          placeholder="Escreva sua pergunta ou pedido…"
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
          onKeyDown={aoTeclar}
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
  );
}
