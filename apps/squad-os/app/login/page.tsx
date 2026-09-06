"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const ERROR_MESSAGES: Record<string, string> = {
  not_allowed:
    "Esse e-mail ainda não tem acesso ao Squad OS. Peça pra um admin te conceder acesso em Administração.",
  auth_failed: "O link expirou ou já foi usado. Peça um novo abaixo.",
};

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginForm />
    </Suspense>
  );
}

function LoginForm() {
  const searchParams = useSearchParams();
  const errorParam = searchParams.get("error");
  const next = searchParams.get("next") ?? "/";

  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "sending" | "sent" | "error">("idle");

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus("sending");
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`,
      },
    });
    setStatus(error ? "error" : "sent");
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <div>
          <div className="name">Squad OS</div>
          <div className="sub">gestão de demandas Salesforce</div>
        </div>

        {errorParam && ERROR_MESSAGES[errorParam] && (
          <div className="auth-note error" role="alert">
            {ERROR_MESSAGES[errorParam]}
          </div>
        )}

        {status === "sent" ? (
          <div className="auth-note ok" role="status">
            Link enviado para <strong>{email}</strong> — confira sua caixa de entrada.
          </div>
        ) : (
          <form className="field" onSubmit={handleSubmit}>
            <label htmlFor="email">Seu e-mail</label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              placeholder="voce@empresa.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            <div style={{ marginTop: "0.6rem" }}>
              <button
                type="submit"
                className="btn-primary"
                disabled={status === "sending"}
                style={{ width: "100%" }}
              >
                {status === "sending" ? "Enviando..." : "Enviar link de acesso"}
              </button>
            </div>
            {status === "error" && (
              <div className="auth-note error" role="alert" style={{ marginTop: "0.6rem" }}>
                Não consegui enviar o link. Tente de novo em instantes.
              </div>
            )}
          </form>
        )}
      </div>
    </div>
  );
}
