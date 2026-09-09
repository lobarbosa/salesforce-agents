"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import type { Client } from "@/lib/generated/prisma/client";
import type { CurrentUsuario } from "@/lib/current-user";
import { createClient as createSupabaseClient } from "@/lib/supabase/client";

function hueFor(name: string) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 360;
  return h;
}

const ROLE_LABEL: Record<CurrentUsuario["role"], string> = {
  admin: "admin",
  consultor: "consultor",
  cliente: "cliente",
};

// A marca escrita não é placeholder: é a alternativa quando `public/marca.svg`
// não existe (ver lib/marca.ts e public/README.md). Quando o arquivo existe, o
// alt fica vazio de propósito — o nome do produto aparece logo abaixo como
// texto de verdade, e repeti-lo no alt faria o leitor de tela dizer "Squad OS
// Squad OS".
function Marca({ src, sub }: { src: string | null; sub: string }) {
  return (
    <div className="brand">
      {src ? (
        // `next/image` exigiria width/height conhecidos no build, e quem sobe
        // o arquivo da marca é o time, em proporção que o build não conhece.
        // Uma imagem de ~26px de altura na sidebar não move LCP.
        // eslint-disable-next-line @next/next/no-img-element
        <img className="brand-logo" src={src} alt="" />
      ) : null}
      <div className="name">Squad OS</div>
      <div className="sub">{sub}</div>
    </div>
  );
}

export function Sidebar({
  clients,
  usuario,
  marcaSrc,
}: {
  clients: Client[];
  usuario: CurrentUsuario;
  marcaSrc: string | null;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [nome, setNome] = useState("");
  const [segmento, setSegmento] = useState("");
  const [saving, setSaving] = useState(false);

  const podeGerenciarClientes = usuario.role !== "cliente";
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

  // role=cliente: sidebar mínima — sem lista de outros clientes, sem busca,
  // sem criar cliente, sem Visão Geral (o proxy já nem deixa navegar pra lá).
  if (!podeGerenciarClientes) {
    const meuCliente = clients[0];
    return (
      <aside className="sidebar">
        <Marca src={marcaSrc} sub={meuCliente?.nome ?? "seu espaço"} />
        <div style={{ padding: "0.6rem 1.1rem", marginTop: "auto", borderTop: "1px solid var(--border)" }}>
          <div className="save-note" style={{ marginBottom: "0.35rem" }}>
            {usuario.email} <span className="mono">({ROLE_LABEL[usuario.role]})</span>
          </div>
          <button
            className="btn-ghost"
            type="button"
            onClick={handleSignOut}
            style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
          >
            Sair
          </button>
        </div>
      </aside>
    );
  }

  return (
    <aside className="sidebar">
      <Marca src={marcaSrc} sub="gestão de demandas Salesforce" />

      <Link href="/" className={`nav-item${!activeClientId && pathname === "/" ? " active" : ""}`}>
        <span className="icon" />
        Visão Geral
      </Link>
      {usuario.role === "admin" && (
        <Link href="/admin/usuarios" className={`nav-item${pathname?.startsWith("/admin") ? " active" : ""}`}>
          <span className="icon" />
          Administração
        </Link>
      )}
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

      <div style={{ padding: "0.6rem 1.1rem", borderTop: "1px solid var(--border)" }}>
        <div className="save-note" style={{ marginBottom: "0.35rem" }}>
          {usuario.email} <span className="mono">({ROLE_LABEL[usuario.role]})</span>
        </div>
        <button
          className="btn-ghost"
          type="button"
          onClick={handleSignOut}
          style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
        >
          Sair
        </button>
      </div>
    </aside>
  );
}
