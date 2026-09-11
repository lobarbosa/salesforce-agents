"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const ERROR_MESSAGES: Record<string, string> = {
  not_allowed:
    "Esse e-mail ainda não tem acesso ao Squad OS. Peça pra um admin te conceder acesso em Administração.",
  auth_failed: "O link expirou ou já foi usado. Peça um novo abaixo.",
};

// Sem "cadastro": o auto-cadastro foi fechado quando o app passou a viver num
// domínio próprio. Criar conta nunca concedeu acesso (a tabela `usuarios` é
// quem decide), mas deixava qualquer pessoa da internet gerar linha em
// auth.users e disparar e-mail com a marca da Acxya. O caminho de entrada é:
// admin concede acesso em /admin/usuarios, a pessoa usa "Esqueci minha senha"
// pra definir a dela. Nenhum passo a mais para quem é do time, uma porta a
// menos aberta.
type Modo = "link" | "senha" | "recuperar";

const TITULO_ACAO: Record<Modo, string> = {
  link: "Enviar link de acesso",
  senha: "Entrar",
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

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus("enviando");
    setAviso(null);
    const supabase = createClient();
    const mail = email.trim();

    if (modo === "link") {
      const { error } = await supabase.auth.signInWithOtp({
        email: mail,
        options: {
          emailRedirectTo: callbackUrl(next),
          // Sem isto, pedir um link cria a conta no Supabase Auth — ou seja, o
          // auto-cadastro continuaria existindo por outra porta, só que sem
          // tela. Quem cria usuário agora é o admin, ao conceder acesso.
          shouldCreateUser: false,
        },
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

  const pedeSenha = modo === "senha";

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
            aria-selected={modo === "senha"}
            className={modo === "senha" ? "active" : ""}
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
                autoComplete="current-password"
                placeholder="sua senha"
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
            <button type="button" onClick={() => trocarModo("recuperar")}>
              Definir ou esqueci minha senha
            </button>
          </div>
        )}

        {modo === "recuperar" && (
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
