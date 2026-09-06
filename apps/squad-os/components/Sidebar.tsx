"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import { createClient as createSupabaseClient } from "@/lib/supabase/client";

function hueFor(name: string) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 360;
  return h;
}

export function Sidebar({
  clients,
  userEmail,
}: {
  clients: Client[];
  userEmail: string | null;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [nome, setNome] = useState("");
  const [segmento, setSegmento] = useState("");
  const [saving, setSaving] = useState(false);

  const filtered = clients.filter((c) => c.nome.toLowerCase().includes(query.toLowerCase()));
  const activeClientId = pathname?.startsWith("/clients/") ? pathname.split("/")[2] : null;

  async function handleCreate(e: FormEvent) {
    e.preventDefault();
    if (!nome.trim()) return;
    setSaving(true);
    const res = await fetch("/api/clients", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ nome: nome.trim(), segmento: segmento.trim() }),
    });
    setSaving(false);
    if (res.ok) {
      const created = await res.json();
      setNome("");
      setSegmento("");
      setFormOpen(false);
      router.push(`/clients/${created.id}`);
      router.refresh();
    }
  }

  async function handleSignOut() {
    const supabase = createSupabaseClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <aside className="sidebar">
      <div className="brand">
        <div className="name">Squad OS</div>
        <div className="sub">gestão de demandas Salesforce</div>
      </div>

      <Link href="/" className={`nav-item${!activeClientId ? " active" : ""}`}>
        <span className="icon" />
        Visão Geral
      </Link>
      <hr />

      <div className="search">
        <input
          type="text"
          placeholder="Buscar cliente..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Buscar cliente"
        />
      </div>

      <div className="client-list">
        {filtered.length === 0 && <div className="empty-col">nenhum cliente encontrado</div>}
        {filtered.map((c) => (
          <Link
            key={c.id}
            href={`/clients/${c.id}`}
            className={`client-item${c.id === activeClientId ? " active" : ""}`}
          >
            <span className="dot" style={{ background: `hsl(${hueFor(c.nome)}, 55%, 45%)` }} />
            <span className="cname">{c.nome}</span>
          </Link>
        ))}
      </div>

      <div className="new-client">
        {formOpen ? (
          <form className="new-client-form" onSubmit={handleCreate}>
            <input
              type="text"
              placeholder="Nome do cliente"
              required
              value={nome}
              onChange={(e) => setNome(e.target.value)}
              autoFocus
            />
            <input
              type="text"
              placeholder="Segmento (ex.: indústria)"
              value={segmento}
              onChange={(e) => setSegmento(e.target.value)}
            />
            <div className="row">
              <button type="submit" disabled={saving}>
                {saving ? "Criando..." : "Criar"}
              </button>
              <button type="button" className="cancel" onClick={() => setFormOpen(false)}>
                Cancelar
              </button>
            </div>
          </form>
        ) : (
          <button className="new-client-btn" type="button" onClick={() => setFormOpen(true)}>
            + novo cliente
          </button>
        )}
      </div>

      {userEmail && (
        <div style={{ padding: "0.6rem 1.1rem", borderTop: "1px solid var(--border)" }}>
          <div className="save-note" style={{ marginBottom: "0.35rem" }}>{userEmail}</div>
          <button className="btn-ghost" type="button" onClick={handleSignOut} style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}>
            Sair
          </button>
        </div>
      )}
    </aside>
  );
}
