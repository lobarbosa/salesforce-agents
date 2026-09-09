"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const ERROR_MESSAGES: Record<string, string> = {
  not_allowed:
    "Esse e-mail ainda não tem acesso ao Squad OS. Peça pra um admin te conceder acesso em Administração.",
  auth_failed: "O link expirou ou já foi usado. Peça um novo abaixo.",
};

type Modo = "link" | "senha" | "cadastro" | "recuperar";

const TITULO_ACAO: Record<Modo, string> = {
  link: "Enviar link de acesso",
  senha: "Entrar",
  cadastro: "Criar conta",
  recuperar: "Enviar link de redefinição",
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

  const [modo, setModo] = useState<Modo>("link");
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [status, setStatus] = useState<"idle" | "enviando" | "ok">("idle");
  const [aviso, setAviso] = useState<{ tipo: "ok" | "error"; texto: string } | null>(null);

  const callbackUrl = (destino: string) =>
    `${window.location.origin}/auth/callback?next=${encodeURIComponent(destino)}`;

  function trocarModo(novo: Modo) {
    setModo(novo);
    setStatus("idle");
    setAviso(null);
    setSenha("");
  }

  async function entrarComGoogle() {
    setAviso(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: callbackUrl(next) },
    });
    // Só cai aqui se o redirect nem chegou a acontecer; no caminho feliz o
    // browser já saiu da página antes desta linha rodar.
    if (error) setAviso({ tipo: "error", texto: "Não consegui abrir o login do Google." });
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus("enviando");
    setAviso(null);
    const supabase = createClient();
    const mail = email.trim();

    if (modo === "link") {
      const { error } = await supabase.auth.signInWithOtp({
        email: mail,
        options: { emailRedirectTo: callbackUrl(next) },
      });
      setStatus(error ? "idle" : "ok");
      setAviso(
        error
          ? { tipo: "error", texto: "Não consegui enviar o link. Tente de novo em instantes." }
          : { tipo: "ok", texto: `Link enviado para ${mail} — confira sua caixa de entrada.` }
      );
      return;
    }

    if (modo === "senha") {
      const { error } = await supabase.auth.signInWithPassword({ email: mail, password: senha });
      if (error) {
        setStatus("idle");
        // Mensagem única pra e-mail inexistente e senha errada — dizer qual
        // dos dois falhou entregaria quem tem conta aqui.
        setAviso({ tipo: "error", texto: "E-mail ou senha incorretos." });
        return;
      }
      // Navegação de página inteira, não router.push: a sessão acabou de ser
      // gravada nos cookies e é o proxy.ts que resolve papel e destino.
      window.location.assign(next);
      return;
    }

    if (modo === "cadastro") {
      if (senha.length < 8) {
        setStatus("idle");
        setAviso({ tipo: "error", texto: "A senha precisa ter pelo menos 8 caracteres." });
        return;
      }
      const { error } = await supabase.auth.signUp({
        email: mail,
        password: senha,
        options: { emailRedirectTo: callbackUrl(next) },
      });
      setStatus(error ? "idle" : "ok");
      // Resposta idêntica com ou sem conta existente, de novo pra não permitir
      // descobrir quem já está cadastrado.
      setAviso(
        error
          ? { tipo: "error", texto: "Não consegui concluir o cadastro. Tente de novo em instantes." }
          : {
              tipo: "ok",
              texto:
                "Se esse e-mail puder ser usado, você vai receber um link de confirmação. Criar conta não concede acesso — um admin ainda precisa liberar você em Administração.",
            }
      );
      return;
    }

    const { error } = await supabase.auth.resetPasswordForEmail(mail, {
      redirectTo: callbackUrl("/auth/nova-senha"),
    });
    setStatus(error ? "idle" : "ok");
    setAviso(
      error
        ? { tipo: "error", texto: "Não consegui enviar o link. Tente de novo em instantes." }
        : {
            tipo: "ok",
            texto: "Se esse e-mail tiver conta, o link de redefinição chega em instantes.",
          }
    );
  }

  const pedeSenha = modo === "senha" || modo === "cadastro";

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

        <button type="button" className="btn-google" onClick={entrarComGoogle}>
          <GoogleMark />
          Entrar com Google
        </button>

        <div className="auth-divider">
          <span>ou</span>
        </div>

        <div className="auth-switch" role="tablist">
          <button
            type="button"
            role="tab"
            aria-selected={modo === "link"}
            className={modo === "link" ? "active" : ""}
            onClick={() => trocarModo("link")}
          >
            Link por e-mail
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={modo === "senha" || modo === "cadastro"}
            className={modo === "senha" || modo === "cadastro" ? "active" : ""}
            onClick={() => trocarModo("senha")}
          >
            Senha
          </button>
        </div>

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

          {pedeSenha && (
            <>
              <label htmlFor="senha" style={{ marginTop: "0.5rem" }}>
                Senha
              </label>
              <input
                id="senha"
                type="password"
                required
                minLength={modo === "cadastro" ? 8 : undefined}
                autoComplete={modo === "cadastro" ? "new-password" : "current-password"}
                placeholder={modo === "cadastro" ? "mínimo 8 caracteres" : "sua senha"}
                value={senha}
                onChange={(e) => setSenha(e.target.value)}
              />
            </>
          )}

          <div style={{ marginTop: "0.6rem" }}>
            <button
              type="submit"
              className="btn-primary"
              disabled={status === "enviando"}
              style={{ width: "100%" }}
            >
              {status === "enviando" ? "Aguarde..." : TITULO_ACAO[modo]}
            </button>
          </div>

          {aviso && (
            <div className={`auth-note ${aviso.tipo}`} role="alert" style={{ marginTop: "0.6rem" }}>
              {aviso.texto}
            </div>
          )}
        </form>

        {modo === "senha" && (
          <div className="auth-links">
            <button type="button" onClick={() => trocarModo("cadastro")}>
              Criar conta
            </button>
            <button type="button" onClick={() => trocarModo("recuperar")}>
              Esqueci minha senha
            </button>
          </div>
        )}

        {(modo === "cadastro" || modo === "recuperar") && (
          <div className="auth-links">
            <button type="button" onClick={() => trocarModo("senha")}>
              Voltar para o login
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function GoogleMark() {
  return (
    <svg width="16" height="16" viewBox="0 0 18 18" aria-hidden="true">
      <path
        fill="#4285F4"
        d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.7-1.57 2.68-3.88 2.68-6.62Z"
      />
      <path
        fill="#34A853"
        d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.92-2.26c-.8.54-1.83.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18Z"
      />
      <path
        fill="#FBBC05"
        d="M3.97 10.72a5.4 5.4 0 0 1 0-3.44V4.95H.96a9 9 0 0 0 0 8.1l3.01-2.33Z"
      />
      <path
        fill="#EA4335"
        d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.9 11.43 0 9 0A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58Z"
      />
    </svg>
  );
}
