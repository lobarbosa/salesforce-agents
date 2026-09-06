"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import type { Client, Usuario, Role } from "@/lib/generated/prisma/client";

export function UsuariosAdmin({
  usuarios,
  clients,
  currentUsuarioId,
}: {
  usuarios: Usuario[];
  clients: Client[];
  currentUsuarioId: string;
}) {
  const router = useRouter();
  const clientNome = (id: string | null) => clients.find((c) => c.id === id)?.nome ?? "—";

  const [email, setEmail] = useState("");
  const [nome, setNome] = useState("");
  const [role, setRole] = useState<Role>("consultor");
  const [clientId, setClientId] = useState("");
  const [saving, setSaving] = useState(false);
  const [erro, setErro] = useState("");

  async function handleGrant(e: FormEvent) {
    e.preventDefault();
    setErro("");
    if (role === "cliente" && !clientId) {
      setErro("escolha o cliente pra esse acesso");
      return;
    }
    setSaving(true);
    const res = await fetch("/api/admin/usuarios", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email.trim(), nome: nome.trim(), role, clientId: role === "cliente" ? clientId : null }),
    });
    setSaving(false);
    if (res.ok) {
      setEmail("");
      setNome("");
      setRole("consultor");
      setClientId("");
      router.refresh();
    } else {
      const body = await res.json().catch(() => ({}));
      setErro(body.error || "falha ao conceder acesso");
    }
  }

  async function updateUsuario(id: string, data: Record<string, unknown>) {
    const res = await fetch(`/api/admin/usuarios/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (res.ok) router.refresh();
    return res;
  }

  return (
    <>
      <div className="brief-field full" style={{ maxWidth: 980, marginBottom: "1.4rem" }}>
        <label>Conceder acesso</label>
        <form onSubmit={handleGrant} style={{ display: "flex", gap: "0.6rem", flexWrap: "wrap", alignItems: "flex-end", marginTop: "0.4rem" }}>
          <div className="field" style={{ flex: "1 1 220px" }}>
            <label>E-mail</label>
            <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="pessoa@empresa.com" />
          </div>
          <div className="field" style={{ flex: "1 1 160px" }}>
            <label>Nome</label>
            <input type="text" value={nome} onChange={(e) => setNome(e.target.value)} placeholder="opcional" />
          </div>
          <div className="field" style={{ flex: "0 0 140px" }}>
            <label>Papel</label>
            <select value={role} onChange={(e) => setRole(e.target.value as Role)}>
              <option value="admin">admin</option>
              <option value="consultor">consultor</option>
              <option value="cliente">cliente</option>
            </select>
          </div>
          {role === "cliente" && (
            <div className="field" style={{ flex: "1 1 180px" }}>
              <label>Cliente</label>
              <select value={clientId} onChange={(e) => setClientId(e.target.value)} required>
                <option value="">selecione...</option>
                {clients.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nome}
                  </option>
                ))}
              </select>
            </div>
          )}
          <button className="btn-primary" type="submit" disabled={saving}>
            {saving ? "Salvando..." : "Conceder acesso"}
          </button>
        </form>
        {erro && (
          <div className="save-note error" role="alert" style={{ marginTop: "0.4rem" }}>
            {erro}
          </div>
        )}
      </div>

      <div className="overview-list" style={{ maxWidth: 980 }}>
        {usuarios.map((u) => (
          <UsuarioRow
            key={u.id}
            usuario={u}
            clients={clients}
            clientNome={clientNome}
            isSelf={u.id === currentUsuarioId}
            onUpdate={(data) => updateUsuario(u.id, data)}
            onRemoved={() => router.refresh()}
          />
        ))}
      </div>
    </>
  );
}

function UsuarioRow({
  usuario,
  clients,
  clientNome,
  isSelf,
  onUpdate,
  onRemoved,
}: {
  usuario: Usuario;
  clients: Client[];
  clientNome: (id: string | null) => string;
  isSelf: boolean;
  onUpdate: (data: Record<string, unknown>) => Promise<Response>;
  onRemoved: () => void;
}) {
  const [confirmando, setConfirmando] = useState(false);
  const [removendo, setRemovendo] = useState(false);
  const [erro, setErro] = useState("");

  async function handleRoleChange(role: Role) {
    setErro("");
    const res = await onUpdate({ role, clientId: role === "cliente" ? usuario.clientId : null });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setErro(body.error || "falha ao atualizar");
    }
  }

  async function handleClientChange(clientId: string) {
    const res = await onUpdate({ clientId });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      setErro(body.error || "falha ao atualizar");
    }
  }

  async function handleRemove() {
    setRemovendo(true);
    const res = await fetch(`/api/admin/usuarios/${usuario.id}`, { method: "DELETE" });
    setRemovendo(false);
    if (res.ok) {
      onRemoved();
    } else {
      const body = await res.json().catch(() => ({}));
      setErro(body.error || "falha ao remover");
      setConfirmando(false);
    }
  }

  return (
    <div className="overview-row" style={{ cursor: "default", flexWrap: "wrap" }}>
      <div style={{ flex: "1 1 220px" }}>
        <div style={{ fontWeight: 500 }}>{usuario.email}</div>
        {usuario.nome && <div className="save-note">{usuario.nome}</div>}
      </div>

      <select
        value={usuario.role}
        onChange={(e) => handleRoleChange(e.target.value as Role)}
        aria-label={`Papel de ${usuario.email}`}
        style={{ padding: "0.35rem 0.5rem", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-alt)", fontSize: "0.8rem" }}
      >
        <option value="admin">admin</option>
        <option value="consultor">consultor</option>
        <option value="cliente">cliente</option>
      </select>

      {usuario.role === "cliente" ? (
        <select
          value={usuario.clientId ?? ""}
          onChange={(e) => handleClientChange(e.target.value)}
          aria-label={`Cliente de ${usuario.email}`}
          style={{ padding: "0.35rem 0.5rem", borderRadius: 6, border: "1px solid var(--border)", background: "var(--surface-alt)", fontSize: "0.8rem" }}
        >
          <option value="">selecione...</option>
          {clients.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nome}
            </option>
          ))}
        </select>
      ) : (
        <span className="save-note">{clientNome(usuario.clientId)}</span>
      )}

      {erro && <span className="save-note error">{erro}</span>}

      <div style={{ marginLeft: "auto", display: "flex", gap: "0.4rem" }}>
        {confirmando ? (
          <>
            <span className="save-note">{isSelf ? "remover seu próprio acesso?" : "remover?"}</span>
            <button className="btn-ghost" type="button" onClick={handleRemove} disabled={removendo}>
              {removendo ? "Removendo..." : "Confirmar"}
            </button>
            <button className="btn-ghost" type="button" onClick={() => setConfirmando(false)}>
              Cancelar
            </button>
          </>
        ) : (
          <button className="btn-ghost" type="button" onClick={() => setConfirmando(true)}>
            Remover
          </button>
        )}
      </div>
    </div>
  );
}
