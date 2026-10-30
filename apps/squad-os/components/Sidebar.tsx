"use client";

import { useEffect, useRef, useState, type FormEvent, type ReactNode } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import type { ClienteDaSidebar } from "@/lib/visao-cliente";
import type { CurrentUsuario } from "@/lib/current-user";
import { createClient as createSupabaseClient } from "@/lib/supabase/client";
import { podeVer, ROTULO_PAPEL } from "@/lib/permissoes";
import { descreverEsteira } from "@/lib/esteira-resumo";
import { useAutoRefresh } from "@/lib/auto-refresh";

const ROLE_LABEL = ROTULO_PAPEL;

// Telas do OS por área (lib/permissoes.ts). Só aparece o que o papel pode abrir;
// o servidor recusa o resto mesmo que alguém digite a URL.
const ITENS_FINANCEIRO = [
  { href: "/financeiro", rotulo: "Painel financeiro", exato: true },
  { href: "/financeiro/saude", rotulo: "Saúde financeira" },
  { href: "/financeiro/contas", rotulo: "Contas a pagar" },
  { href: "/financeiro/recorrentes", rotulo: "Despesas recorrentes" },
  { href: "/financeiro/aprovacoes", rotulo: "Aprovações" },
  { href: "/financeiro/contabilidade", rotulo: "Contabilidade" },
  { href: "/financeiro/divergencias", rotulo: "Divergências" },
  { href: "/financeiro/horas", rotulo: "Horas por cliente" },
] as const;

// Seções que colapsam (Financeiro, Operação) lembram a escolha por navegador —
// chave curta e estável, nunca o rótulo (que pode mudar sem quebrar o que já
// foi salvo no localStorage de quem já usa o app).
const SECOES_ABERTAS_KEY = "squad-os:sidebar:secoes-abertas";

function lerSecoesAbertas(): Record<string, boolean> {
  try {
    const bruto = window.localStorage.getItem(SECOES_ABERTAS_KEY);
    return bruto ? JSON.parse(bruto) : {};
  } catch {
    // Aba anônima, storage bloqueado, JSON corrompido: sem preferência
    // salva não é erro, é só "usa o padrão" — nunca deve quebrar a sidebar.
    return {};
  }
}

function salvarSecoesAbertas(mapa: Record<string, boolean>) {
  try {
    window.localStorage.setItem(SECOES_ABERTAS_KEY, JSON.stringify(mapa));
  } catch {
    // Preferência não salva não pode impedir o clique de funcionar nesta
    // sessão — só não sobrevive ao próximo carregamento.
  }
}

function NavArea({
  chave,
  titulo,
  itens,
  basePath,
  pathname,
  preferencia,
  aoAlternar,
  aoNavegar,
}: {
  chave: string;
  titulo: string;
  itens: readonly { href: string; rotulo: string; exato?: boolean }[];
  /** Prefixo de rota da área (ex.: "/financeiro") — decide o padrão antes de
   *  qualquer preferência salva: começa aberta se é onde a pessoa já está. */
  basePath: string;
  pathname: string | null;
  /** undefined = sem preferência salva ainda, usa o padrão por rota. */
  preferencia: boolean | undefined;
  aoAlternar: (chave: string, estavaAberta: boolean) => void;
  aoNavegar: () => void;
}) {
  const aberta = preferencia ?? !!pathname?.startsWith(basePath);
  const domId = `nav-area-${chave}`;
  return (
    <div className="nav-area">
      <button
        type="button"
        className="nav-secao-toggle"
        aria-expanded={aberta}
        aria-controls={domId}
        onClick={() => aoAlternar(chave, aberta)}
      >
        <span className="nav-secao">{titulo}</span>
        <span className={`nav-secao-chevron${aberta ? " aberta" : ""}`} aria-hidden="true" />
      </button>
      <div id={domId} className={`nav-area-corpo${aberta ? " aberta" : ""}`}>
        <nav className="nav-area-corpo-interno" aria-label={titulo}>
          {itens.map((i) => {
            const ativo = i.exato ? pathname === i.href : !!pathname?.startsWith(i.href);
            return (
              <Link
                key={i.href}
                href={i.href}
                onClick={aoNavegar}
                // Fechada: fora da ordem de tab e invisível pra leitor de tela —
                // a seção continua no DOM (pra animar), mas não pode ser
                // alcançada por quem não a vê. `hidden` sozinho impediria a
                // transição de altura, por isso os dois atributos em vez dele.
                tabIndex={aberta ? undefined : -1}
                aria-hidden={aberta ? undefined : true}
                className={`nav-item${ativo ? " active" : ""}`}
                aria-current={ativo ? "page" : undefined}
              >
                <span className="icon" />
                {i.rotulo}
              </Link>
            );
          })}
        </nav>
      </div>
    </div>
  );
}

function Rodape({
  usuario,
  aoNavegar,
  aoSair,
}: {
  usuario: CurrentUsuario;
  aoNavegar: () => void;
  aoSair: () => void;
}) {
  return (
    <div style={{ padding: "0.6rem 1.1rem", marginTop: "auto", borderTop: "1px solid var(--border)" }}>
      <div className="save-note" style={{ marginBottom: "0.35rem" }}>
        {usuario.email} <span className="mono">({ROLE_LABEL[usuario.role]})</span>
      </div>
      <div style={{ display: "flex", gap: "0.5rem" }}>
        <Link
          href="/auth/nova-senha"
          onClick={aoNavegar}
          className="btn-ghost"
          style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
        >
          Alterar senha
        </Link>
        <button
          className="btn-ghost"
          type="button"
          onClick={aoSair}
          style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
        >
          Sair
        </button>
      </div>
    </div>
  );
}

// A marca escrita não é placeholder: é a alternativa quando `public/marca.svg`
// não existe (ver lib/marca.ts e public/README.md). Quando o arquivo existe, o
// logo substitui o nome escrito (2026-10-30) e o alt carrega o nome.
function Marca({ src, sub }: { src: string | null; sub: string }) {
  return (
    <div className="brand">
      {src ? (
        // `next/image` exigiria width/height conhecidos no build, e quem sobe
        // o arquivo da marca é o time, em proporção que o build não conhece.
        // Uma imagem de ~26px de altura na sidebar não move LCP.
        // eslint-disable-next-line @next/next/no-img-element
        <img className="brand-logo" src={src} alt="Konecta" />
      ) : (
        <div className="name">Squad OS</div>
      )}
      <div className="sub">{sub}</div>
    </div>
  );
}

/** A sidebar no telefone: gaveta, com barra de topo pra abrir.
 *
 * Até aqui a sidebar era 250px fixos em qualquer largura. Num telefone de
 * 375px ela comia 67% da tela e sobrava uma faixa de ~125px pro conteúdo —
 * título cortado, botão cortado, quadro ilegível. Não era "apertado", era
 * inutilizável, e quem aprova um gate no meio da rua está exatamente nessa
 * largura.
 *
 * Fora do telefone nada muda: a barra some e a gaveta volta a ser coluna
 * fixa (ver `@media (max-width: 860px)` no globals.css).
 */
function Casca({
  aberta,
  aoAlternar,
  titulo,
  children,
}: {
  aberta: boolean;
  aoAlternar: (v: boolean) => void;
  titulo: string;
  children: ReactNode;
}) {
  // Esc fecha: a gaveta cobre a tela inteira no telefone, e sem saída pelo
  // teclado quem abre sem querer fica preso no mouse.
  useEffect(() => {
    if (!aberta) return;
    const aoTeclar = (e: KeyboardEvent) => {
      if (e.key === "Escape") aoAlternar(false);
    };
    document.addEventListener("keydown", aoTeclar);
    return () => document.removeEventListener("keydown", aoTeclar);
  }, [aberta, aoAlternar]);

  // Abriu a gaveta: o foco entra nela. Fechou: volta ao botão Menu, em vez de
  // cair no <body> (achado da revisão UI/UX). Só quando houve abertura antes.
  const botaoMenu = useRef<HTMLButtonElement>(null);
  const jaAbriu = useRef(false);
  useEffect(() => {
    if (aberta) {
      jaAbriu.current = true;
      document.querySelector<HTMLElement>("#nav-lateral a, #nav-lateral button")?.focus();
    } else if (jaAbriu.current) {
      botaoMenu.current?.focus();
    }
  }, [aberta]);

  // Recolher no desktop (2026-10-30): o quadro de 7 colunas precisa da largura.
  // Preferência por navegador — conveniência, não estado (falha em silêncio).
  const [recolhida, setRecolhida] = useState(false);
  useEffect(() => {
    // Lido depois de montar, como secoesAbertas abaixo: inicializador
    // preguiçoso daria mismatch de hidratação (o servidor não tem window).
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setRecolhida(localStorage.getItem("sidebar-recolhida") === "1");
    } catch {}
  }, []);
  function alternarRecolhida(v: boolean) {
    setRecolhida(v);
    try {
      localStorage.setItem("sidebar-recolhida", v ? "1" : "0");
    } catch {}
  }

  return (
    <>
      {recolhida && (
        <button
          className="sidebar-expandir"
          type="button"
          onClick={() => alternarRecolhida(false)}
          aria-label="Mostrar menu lateral"
          aria-controls="nav-lateral"
          aria-expanded={false}
        >
          <span className="menu-icone" aria-hidden="true" />
        </button>
      )}
      <div className="topbar">
        <button
          ref={botaoMenu}
          className="menu-btn"
          type="button"
          aria-expanded={aberta}
          aria-controls="nav-lateral"
          onClick={() => aoAlternar(!aberta)}
        >
          <span className="menu-icone" aria-hidden="true" />
          {aberta ? "Fechar" : "Menu"}
        </button>
        <span className="topbar-titulo">{titulo}</span>
      </div>
      {aberta && (
        <button
          className="menu-fundo"
          type="button"
          aria-label="Fechar menu"
          onClick={() => aoAlternar(false)}
        />
      )}
      <aside id="nav-lateral" className={`sidebar${aberta ? " aberta" : ""}${recolhida ? " recolhida" : ""}`}>
        <button
          className="sidebar-recolher"
          type="button"
          onClick={() => alternarRecolhida(true)}
          aria-label="Recolher menu lateral"
          aria-controls="nav-lateral"
          aria-expanded={true}
          title="Recolher menu"
        >
          «
        </button>
        {children}
      </aside>
    </>
  );
}

export function Sidebar({
  clients,
  encerrados = [],
  usuario,
  marcaSrc,
}: {
  clients: ClienteDaSidebar[];
  /** Clientes encerrados — só chegam para o admin (layout.tsx). */
  encerrados?: { id: string; nome: string }[];
  usuario: CurrentUsuario;
  marcaSrc: string | null;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [menuAberto, setMenuAberto] = useState(false);
  const [query, setQuery] = useState("");
  const [formOpen, setFormOpen] = useState(false);
  const [nome, setNome] = useState("");
  const [segmento, setSegmento] = useState("");
  const [saving, setSaving] = useState(false);
  const [erroCriar, setErroCriar] = useState("");
  // {} até o efeito rodar no cliente (SSR não tem localStorage): cada NavArea
  // cai no próprio padrão por rota enquanto isso, sem piscar — o padrão e a
  // preferência salva raramente divergem no primeiro quadro.
  // Os pontos da lista de clientes acompanham a esteira sozinhos enquanto há
  // agente rodando ou disparo na fila em algum cliente (mesmo critério do
  // quadro, lib/auto-refresh.ts: só com a aba visível).
  useAutoRefresh(clients.some((c) => c.esteira.estado === "agente" || c.esteira.estado === "fila"));

  const [secoesAbertas, setSecoesAbertas] = useState<Record<string, boolean>>({});

  useEffect(() => {
    // Não dá pra virar inicializador preguiçoso do useState: ele rodaria de
    // novo na hidratação do cliente (window já existe ali) com um valor
    // diferente do que o servidor renderizou (sem window, sempre {}) — troca
    // um lint por um mismatch de hidratação de verdade. Ler depois de montado
    // é o jeito correto de puxar algo só-do-navegador sem esse descompasso.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setSecoesAbertas(lerSecoesAbertas());
  }, []);

  // Recebe o estado atual em vez de recalcular um padrão aqui dentro: cada
  // seção já decide o próprio padrão (por rota, ou sempre aberta) no lugar
  // onde ela renderiza — repetir a heurística aqui divergiria da seção
  // "Clientes", que abre por padrão sem depender de rota nenhuma.
  function alternarSecao(chave: string, estavaAberta: boolean) {
    setSecoesAbertas((atual) => {
      const novo = { ...atual, [chave]: !estavaAberta };
      salvarSecoesAbertas(novo);
      return novo;
    });
  }

  // Fecha no clique que navega, e não num efeito que observa o `pathname`:
  // o efeito renderizaria, mudaria o estado e renderizaria de novo (render em
  // cascata — o lint pega isso). Aqui a intenção já está no evento.
  const fecharMenu = () => setMenuAberto(false);

  const podeGerenciarClientes = podeVer(usuario.role, "delivery");
  const filtered = clients.filter((c) => c.nome.toLowerCase().includes(query.toLowerCase()));
  const activeClientId = pathname?.startsWith("/clients/") ? pathname.split("/")[2] : null;
  // Sem prefixo de rota pra ancorar um padrão (fica aberta em qualquer rota
  // interna) — diferente de Financeiro/Operação, começa aberta: é a área que
  // mais se usa na sidebar, e só fecha se a pessoa fechar de propósito.
  const clientesAberta = secoesAbertas.clientes ?? true;

  async function handleCreate(e: FormEvent) {
    e.preventDefault();
    if (!nome.trim()) return;
    setSaving(true);
    setErroCriar("");
    try {
      const res = await fetch("/api/clients", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nome: nome.trim(), segmento: segmento.trim() }),
      });
      if (!res.ok) {
        const corpo = await res.json().catch(() => ({}));
        setErroCriar((corpo as { error?: string }).error ?? "Não consegui criar o cliente.");
        return;
      }
      const created = await res.json();
      setNome("");
      setSegmento("");
      setFormOpen(false);
      setMenuAberto(false);
      router.push(`/clients/${created.id}`);
      router.refresh();
    } catch {
      setErroCriar("Sem conexão com o servidor — tente de novo.");
    } finally {
      setSaving(false);
    }
  }

  async function handleSignOut() {
    const supabase = createSupabaseClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  // Financeiro: só as telas da área dele, sem clientes nem demandas.
  if (usuario.role === "financeiro") {
    return (
      <Casca aberta={menuAberto} aoAlternar={setMenuAberto} titulo="Squad OS">
        <Marca src={marcaSrc} sub="financeiro" />
        <NavArea
          chave="financeiro"
          titulo="Financeiro"
          itens={ITENS_FINANCEIRO}
          basePath="/financeiro"
          pathname={pathname}
          preferencia={secoesAbertas.financeiro}
          aoAlternar={alternarSecao}
          aoNavegar={fecharMenu}
        />
        <Rodape usuario={usuario} aoNavegar={fecharMenu} aoSair={handleSignOut} />
      </Casca>
    );
  }

  // role=cliente: sidebar mínima — sem lista de outros clientes, sem busca,
  // sem criar cliente, sem Visão Geral (o proxy já nem deixa navegar pra lá).
  if (!podeGerenciarClientes) {
    const meuCliente = clients[0];
    return (
      <Casca
        aberta={menuAberto}
        aoAlternar={setMenuAberto}
        titulo={meuCliente?.nome ?? "Squad OS"}
      >
        <Marca src={marcaSrc} sub={meuCliente?.nome ?? "seu espaço"} />
        <div style={{ padding: "0.6rem 1.1rem", marginTop: "auto", borderTop: "1px solid var(--border)" }}>
          <div className="save-note" style={{ marginBottom: "0.35rem" }}>
            {usuario.email} <span className="mono">({ROLE_LABEL[usuario.role]})</span>
          </div>
          <div style={{ display: "flex", gap: "0.5rem" }}>
            <Link
              href="/auth/nova-senha"
              onClick={fecharMenu}
              className="btn-ghost"
              style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
            >
              Alterar senha
            </Link>
            <button
              className="btn-ghost"
              type="button"
              onClick={handleSignOut}
              style={{ fontSize: "0.75rem", padding: "0.35rem 0.6rem" }}
            >
              Sair
            </button>
          </div>
        </div>
      </Casca>
    );
  }

  return (
    <Casca aberta={menuAberto} aoAlternar={setMenuAberto} titulo="Squad OS">
      <Marca src={marcaSrc} sub="gestão de demandas Salesforce" />

      <Link
        href="/"
        onClick={fecharMenu}
        className={`nav-item${!activeClientId && pathname === "/" ? " active" : ""}`}
        aria-current={!activeClientId && pathname === "/" ? "page" : undefined}
      >
        <span className="icon" />
        Visão Geral
      </Link>
      <Link
        href="/horas"
        onClick={fecharMenu}
        className={`nav-item${pathname?.startsWith("/horas") ? " active" : ""}`}
        aria-current={pathname?.startsWith("/horas") ? "page" : undefined}
      >
        <span className="icon" />
        Minhas horas
      </Link>
      <Link
        href="/esteira"
        onClick={fecharMenu}
        className={`nav-item${pathname?.startsWith("/esteira") ? " active" : ""}`}
        aria-current={pathname?.startsWith("/esteira") ? "page" : undefined}
      >
        <span className="icon" />
        Esteira ao vivo
      </Link>
      <Link
        href="/falhas"
        onClick={fecharMenu}
        className={`nav-item${pathname?.startsWith("/falhas") ? " active" : ""}`}
        aria-current={pathname?.startsWith("/falhas") ? "page" : undefined}
      >
        <span className="icon" />
        Falhas
      </Link>
      {podeVer(usuario.role, "financeiro") && (
        <NavArea
          chave="financeiro"
          titulo="Financeiro"
          itens={ITENS_FINANCEIRO}
          basePath="/financeiro"
          pathname={pathname}
          preferencia={secoesAbertas.financeiro}
          aoAlternar={alternarSecao}
          aoNavegar={fecharMenu}
        />
      )}
      {podeVer(usuario.role, "operacao") && (
        <NavArea
          chave="operacao"
          titulo="Operação"
          itens={[
            { href: "/operacao/agentes", rotulo: "Saúde dos agentes" },
            { href: "/operacao/execucoes", rotulo: "Execuções da plataforma" },
          ]}
          basePath="/operacao"
          pathname={pathname}
          preferencia={secoesAbertas.operacao}
          aoAlternar={alternarSecao}
          aoNavegar={fecharMenu}
        />
      )}
      {usuario.role === "admin" && (
        <Link
          href="/admin/usuarios"
          onClick={fecharMenu}
          className={`nav-item${pathname?.startsWith("/admin") ? " active" : ""}`}
          aria-current={pathname?.startsWith("/admin") ? "page" : undefined}
        >
          <span className="icon" />
          Administração
        </Link>
      )}
      <hr />

      <div className="nav-area nav-area--clientes">
        <button
          type="button"
          className="nav-secao-toggle"
          aria-expanded={clientesAberta}
          aria-controls="nav-area-clientes"
          onClick={() => alternarSecao("clientes", clientesAberta)}
        >
          <span className="nav-secao">Clientes</span>
          <span className={`nav-secao-chevron${clientesAberta ? " aberta" : ""}`} aria-hidden="true" />
        </button>
        <div id="nav-area-clientes" className={`nav-area-clientes-corpo${clientesAberta ? " aberta" : ""}`}>
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
            {filtered.map((c) => {
              // O ponto é o estado da esteira do cliente agora (lib/esteira-
              // sidebar.ts), com a mesma forma das etiquetas dos cards: círculo
              // pulsando = agente rodando, losango = esperando o cliente,
              // quadrado = esperando o time, círculo vazado = na fila. A saúde
              // da org (assessment) mudava a cada semanas e fica no perfil.
              const descricao = descreverEsteira(c.esteira, usuario.role === "cliente");
              return (
                <Link
                  key={c.id}
                  href={`/clients/${c.id}`}
                  onClick={fecharMenu}
                  className={`client-item${c.id === activeClientId ? " active" : ""}`}
                  title={descricao}
                >
                  <span className={`dot-esteira esteira-${c.esteira.estado}`} aria-hidden="true" />
                  <span className="cname">{c.nome}</span>
                  <span className="sr-only">{` — ${descricao}`}</span>
                </Link>
              );
            })}
          </div>

          {/* Encerrados ficam fora da lista e da busca, num filtro à parte —
              para o admin consultar o histórico, reativar ou excluir. */}
          {encerrados.length > 0 && (
            <details className="clientes-encerrados" open={encerrados.some((c) => c.id === activeClientId)}>
              <summary>Encerrados ({encerrados.length})</summary>
              <div className="client-list">
                {encerrados.map((c) => (
                  <Link
                    key={c.id}
                    href={`/clients/${c.id}`}
                    onClick={fecharMenu}
                    className={`client-item${c.id === activeClientId ? " active" : ""}`}
                  >
                    <span className="cname">{c.nome}</span>
                    <span className="sr-only"> — encerrado</span>
                  </Link>
                ))}
              </div>
            </details>
          )}

          <div className="new-client">
            {formOpen ? (
              <form className="new-client-form" onSubmit={handleCreate}>
                <label className="sr-only" htmlFor="novo-cliente-nome">Nome do cliente</label>
                <input
                  id="novo-cliente-nome"
                  type="text"
                  placeholder="Nome do cliente"
                  required
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  autoFocus
                />
                <label className="sr-only" htmlFor="novo-cliente-segmento">Segmento</label>
                <input
                  id="novo-cliente-segmento"
                  type="text"
                  placeholder="Segmento (ex.: indústria)"
                  value={segmento}
                  onChange={(e) => setSegmento(e.target.value)}
                />
                {erroCriar && (
                  <div className="save-note error" role="alert">
                    {erroCriar}
                  </div>
                )}
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
        </div>
      </div>

      <Rodape usuario={usuario} aoNavegar={fecharMenu} aoSair={handleSignOut} />
    </Casca>
  );
}
