"use client";

import { useState, type FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";

// Destino do link de redefinição: o /auth/callback já trocou o code por
// sessão antes de mandar pra cá, então updateUser() abaixo age sobre um
// usuário autenticado. Esta rota não está em PUBLIC_PATHS de propósito —
// sem sessão válida o proxy manda pro /login.
export default function NovaSenhaPage() {
  const [senha, setSenha] = useState("");
  const [confirmacao, setConfirmacao] = useState("");
  const [salvando, setSalvando] = useState(false);
  const [erro, setErro] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setErro(null);

    if (senha.length < 8) {
      setErro("A senha precisa ter pelo menos 8 caracteres.");
      return;
    }
    if (senha !== confirmacao) {
      setErro("As duas senhas não são iguais.");
      return;
    }

    setSalvando(true);
    const supabase = createClient();
    const { error } = await supabase.auth.updateUser({ password: senha });

    if (error) {
      setSalvando(false);
      setErro("Não consegui salvar a nova senha. Peça um novo link e tente de novo.");
      return;
    }

    // Reload completo em vez de router.push: updateUser() acabou de reescrever
    // os cookies de sessão, e é o proxy.ts que decide a home de cada papel.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign("/");
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <div>
          <div className="name">Squad OS</div>
          <div className="sub">definir nova senha</div>
        </div>

        <form className="field" onSubmit={handleSubmit}>
          <label htmlFor="senha">Nova senha</label>
          <input
            id="senha"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            placeholder="mínimo 8 caracteres"
            value={senha}
            onChange={(e) => setSenha(e.target.value)}
          />

          <label htmlFor="confirmacao" style={{ marginTop: "0.5rem" }}>
            Confirme a nova senha
          </label>
          <input
            id="confirmacao"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            value={confirmacao}
            onChange={(e) => setConfirmacao(e.target.value)}
          />

          <div style={{ marginTop: "0.6rem" }}>
            <button
              type="submit"
              className="btn-primary"
              disabled={salvando}
              style={{ width: "100%" }}
            >
              {salvando ? "Salvando..." : "Salvar senha"}
            </button>
          </div>

          {erro && (
            <div className="auth-note error" role="alert" style={{ marginTop: "0.6rem" }}>
              {erro}
            </div>
          )}
        </form>
      </div>
    </div>
  );
}
